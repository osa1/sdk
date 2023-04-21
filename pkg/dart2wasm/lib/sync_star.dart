// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/closures.dart';
import 'package:dart2wasm/code_generator.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Placement of a control flow graph target within a statement. This
/// distinction is necessary since some statements need to have two targets
/// associated with them.
///
/// The meanings of the variants are:
///
///  - [Inner]: Loop entry of a [DoStatement], condition of a [ForStatement] or
///             [WhileStatement], the `else` branch of an [IfStatement], or the
///             initial entry target for a function body.
///  - [After]: After a statement, the resumption point of a [YieldStatement],
///             or the final state (iterator done) of a function body.
enum _StateTargetPlacement { Inner, After }

/// Representation of target in the `sync*` control flow graph.
class _StateTarget {
  int index;
  TreeNode node;
  _StateTargetPlacement placement;

  _StateTarget(this.index, this.node, this.placement);

  String toString() {
    String place = placement == _StateTargetPlacement.Inner ? "in" : "after";
    return "$index: $place $node";
  }
}

/// Identify which statements contain `yield` or `yield*` statements, and assign
/// target indices to all control flow targets of these.
///
/// Target indices are assigned in program order.
class _YieldFinder extends StatementVisitor<void> {
  final SyncStarCodeGenerator codeGen;

  // The number of `yield` or `yield*` statements seen so far.
  int yieldCount = 0;

  _YieldFinder(this.codeGen);

  List<_StateTarget> get targets => codeGen.targets;

  void find(FunctionNode function) {
    // Initial state
    addTarget(function.body!, _StateTargetPlacement.Inner);
    assert(function.body is Block || function.body is ReturnStatement);
    recurse(function.body!);
    // Final state
    addTarget(function.body!, _StateTargetPlacement.After);
  }

  /// Recurse into a statement and then remove any targets added by the
  /// statement if it doesn't contain any `yield` or `yield*` statements.
  void recurse(Statement statement) {
    int yieldCountIn = yieldCount;
    int targetsIn = targets.length;
    statement.accept(this);
    if (statement is! TryFinally && yieldCount == yieldCountIn) {
      targets.length = targetsIn;
    }
  }

  void addTarget(TreeNode node, _StateTargetPlacement placement) {
    targets.add(_StateTarget(targets.length, node, placement));
  }

  @override
  void defaultStatement(Statement node) {
    // Statements not explicitly handled in this visitor can never contain any
    // `yield` or `yield*` statements. It is assumed that this holds for all
    // [BlockExpression]s in the function.
  }

  @override
  void visitBlock(Block node) {
    for (Statement statement in node.statements) {
      recurse(statement);
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    addTarget(node, _StateTargetPlacement.Inner);
    recurse(node.body);
  }

  @override
  void visitForStatement(ForStatement node) {
    addTarget(node, _StateTargetPlacement.Inner);
    recurse(node.body);
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitIfStatement(IfStatement node) {
    recurse(node.then);
    if (node.otherwise != null) {
      addTarget(node, _StateTargetPlacement.Inner);
      recurse(node.otherwise!);
    }
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    recurse(node.body);
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    for (SwitchCase c in node.cases) {
      addTarget(c, _StateTargetPlacement.Inner);
      recurse(c.body);
    }
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitTryCatch(TryCatch node) {
    recurse(node.body);
    for (Catch c in node.catches) {
      addTarget(c, _StateTargetPlacement.Inner);
      recurse(c.body);
    }
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitTryFinally(TryFinally node) {
    // try-finally blocks are always compiled to the CFG, even when they don't
    // have yields. This is to keep the code size small: with normal
    // compilation finalizer blocks need to be duplicated based on
    // continuations, which we don't need in the CFG implementation.
    recurse(node.body);
    addTarget(node, _StateTargetPlacement.Inner);
    recurse(node.finalizer);
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    addTarget(node, _StateTargetPlacement.Inner);
    recurse(node.body);
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    yieldCount++;
    addTarget(node, _StateTargetPlacement.After);
  }
}

class ExceptionHandlerStack {
  /// Current exception handler stack. CFG blocks generated when this is not
  /// empty should have a Wasm `try` instruction wrapped. On catching an
  /// exception the type tests should run in reverse order.
  ///
  /// Code for the Dart `catch` blocks are compiled once and will have a block
  /// in `innerTargets`.
  final List<ExceptionHandler> _handlers = [];

  /// Current number of nested Wasm `try` blocks. Each `try` block will cover
  /// one list of handlers in [_handlers].
  int _tryBlockDepth = 0;

  final Map<TreeNode, _StateTarget> _innerTargets;

  final Translator translator;

  ExceptionHandlerStack(this.translator, this._innerTargets);

  void pushTryCatch(TryCatch tryCatch) =>
      _handlers.add(ExceptionHandler(_innerTargets[tryCatch.catches.first]!,
          isFinalizer: false));

  void pushTryFinally(TryFinally tryFinally) => _handlers
      .add(ExceptionHandler(_innerTargets[tryFinally]!, isFinalizer: true));

  void pop() {
    _handlers.removeLast();
  }

  int get numFinalizers {
    int i = 0;
    for (final handler in _handlers) {
      if (handler.isFinalizer) {
        i += 1;
      }
    }
    return i;
  }

  ExceptionHandler? get nextFinalizer {
    if (_handlers.isEmpty) {
      return null;
    }
    for (int i = _handlers.length - 1; i >= 0; i -= 1) {
      final handler = _handlers[i];
      if (handler.isFinalizer) {
        return handler;
      }
    }
    return null;
  }

  /// Generates Wasm `try` blocks for Dart `try` blocks wrapping the current
  /// CFG block.
  ///
  /// Call this when generating a new CFG block.
  void generateWasmTryBlocks(w.Instructions b) {
    while (_tryBlockDepth < _handlers.length) {
      b.try_();
      _tryBlockDepth += 1;
    }
  }

  /// Terminates Wasm `try` blocks generated by [generateWasmTryBlocks].
  ///
  /// Call this right before terminating a CFG block.
  void terminateWasmTryBlocks(SyncStarCodeGenerator codeGen) {
    while (_tryBlockDepth > 0) {
      codeGen.b.catch_(translator.exceptionTag);

      final stackTraceLocal =
          codeGen.addLocal(translator.stackTraceInfo.nonNullableType);
      codeGen.b.local_set(stackTraceLocal);
      final exceptionLocal =
          codeGen.addLocal(translator.topInfo.nonNullableType);
      codeGen.b.local_set(exceptionLocal);

      codeGen._setCurrentExceptionStackTrace(
          () => codeGen.b.local_get(stackTraceLocal));
      codeGen._setCurrentException(() => codeGen.b.local_get(exceptionLocal));

      codeGen.jumpToTarget(_handlers[_tryBlockDepth - 1].target);
      codeGen.b.end();
      _tryBlockDepth -= 1;
    }
  }
}

/// A CFG block for an exception handler (a CFG block for a `catch` or
/// `finally`).
///
/// Note: for a `try-catch` with multiple `catch` blocks we jump to the first
/// `catch` block on exception, which checks the exception type and jumps to
/// the next one if necessary.
class ExceptionHandler {
  /// CFG block for the `catch` or `finally` block.
  final _StateTarget target;

  /// Whether the CFG block is for a finalizer.
  final bool isFinalizer;

  ExceptionHandler(this.target, {required bool isFinalizer})
      : this.isFinalizer = isFinalizer;
}

/// Target for a `break` statement.
abstract class LabelTarget {
  void jump(SyncStarCodeGenerator codeGen);
}

/// Target for a `break` that can be implemented with Wasm `br` instruction.
///
/// This type of [LabelTarget] is used when the labelled statement does not
/// have any `yield`s.
class DirectLabelTarget implements LabelTarget {
  final w.Label label;

  DirectLabelTarget(this.label);

  @override
  void jump(SyncStarCodeGenerator codeGen) {
    codeGen.b.br(label);
  }
}

/// Target for a `break` when the `break` needs to run finalizers or the
/// labelled statement is implemented as CFG (i.e. it has yields).
class IndirectLabelTarget implements LabelTarget {
  final int finalizerDepth;
  final _StateTarget stateTarget;

  IndirectLabelTarget(this.finalizerDepth, this.stateTarget);

  @override
  void jump(SyncStarCodeGenerator codeGen) {
    final nextFinalizer = codeGen.exceptionHandlers.nextFinalizer;
    if (nextFinalizer == null) {
      // Finalizer stack is empty at `break`, the label should also not have
      // any finalizers.
      assert(finalizerDepth == 0);
      codeGen.jumpToTarget(stateTarget);
    } else {
      final currentFinalizerDepth = codeGen.exceptionHandlers.numFinalizers;
      final finalizersToRun = currentFinalizerDepth - finalizerDepth;

      if (finalizersToRun != 0) {
        codeGen.b.local_get(codeGen.suspendStateLocal);
        codeGen.b.i32_const(finalizersToRun);
        codeGen.b.struct_set(codeGen.suspendStateInfo.struct,
            FieldIndex.suspendStateNumFinalizers);
      }

      codeGen.b.local_get(codeGen.suspendStateLocal);
      codeGen.b.i32_const(stateTarget.index);
      codeGen.b.i32_const(2);
      codeGen.b.i32_add();
      codeGen.b.struct_set(codeGen.suspendStateInfo.struct,
          FieldIndex.suspendStateFinalizerTargetIndex);
    }
  }
}

/// A specialized code generator for generating code for `sync*` functions.
///
/// This will create an "outer" function which is a small function that just
/// instantiates and returns a [_SyncStarIterable], plus an "inner" function
/// containing the body of the `sync*` function.
///
/// For the inner function, all statements containing any `yield` or `yield*`
/// statements will be translated to an explicit control flow graph implemented
/// via a switch (via the Wasm `br_table` instruction) in a loop. This enables
/// the function to suspend its execution at yield points and jump back to the
/// point of suspension when the execution is resumed.
///
/// Local state is preserved via the closure contexts, which will implicitly
/// capture all local variables in a `sync*` function even if they are not
/// captured by any lambdas.
class SyncStarCodeGenerator extends CodeGenerator {
  SyncStarCodeGenerator(super.translator, super.function, super.reference);

  /// Targets of the CFG, indexed by target index.
  final List<_StateTarget> targets = [];

  // Targets categorized by placement and indexed by node.
  final Map<TreeNode, _StateTarget> innerTargets = {};
  final Map<TreeNode, _StateTarget> afterTargets = {};

  /// The loop around the switch.
  late final w.Label masterLoop;

  /// The target labels of the switch, indexed by target index.
  late final List<w.Label> labels;

  /// The target index of the entry label for the current `sync*` CFG node.
  int currentTargetIndex = -1;

  /// Local for the `_SuspendState` of the current function.
  late final w.Local suspendStateLocal;

  /// Local for the current target index.
  late final w.Local targetIndexLocal;

  /// Exception handlers (`try` blocks) wrapping the current statement. Used to
  /// generate Wasm `try` and `catch` blocks around the CFG blocks.
  late final ExceptionHandlerStack exceptionHandlers;

  /// Maps labelled statements to their CFG targets. Used when jumping to a CFG
  /// block on `break`.
  final Map<LabeledStatement, LabelTarget> labelTargets = {};

  late final ClassInfo suspendStateInfo =
      translator.classInfo[translator.suspendStateClass]!;
  late final ClassInfo syncStarIterableInfo =
      translator.classInfo[translator.syncStarIterableClass]!;
  late final ClassInfo syncStarIteratorInfo =
      translator.classInfo[translator.syncStarIteratorClass]!;

  @override
  void generate() {
    closures = Closures(this);
    setupParametersAndContexts(member);
    generateTypeChecks(member.function!.typeParameters, member.function!,
        translator.paramInfoFor(reference));
    generateBodies(member.function!);
  }

  @override
  w.DefinedFunction generateLambda(Lambda lambda, Closures closures) {
    this.closures = closures;
    setupLambdaParametersAndContexts(lambda);
    generateBodies(lambda.functionNode);
    return function;
  }

  void generateBodies(FunctionNode functionNode) {
    // Number and categorize CFG targets.
    _YieldFinder(this).find(functionNode);
    for (final target in targets) {
      switch (target.placement) {
        case _StateTargetPlacement.Inner:
          innerTargets[target.node] = target;
          break;
        case _StateTargetPlacement.After:
          afterTargets[target.node] = target;
          break;
      }
    }

    exceptionHandlers = ExceptionHandlerStack(translator, innerTargets);

    // Wasm function containing the body of the `sync*` function.
    final w.DefinedFunction resumeFun = m.addFunction(
        m.addFunctionType([
          suspendStateInfo.nonNullableType,
          translator.topInfo.nullableType, // pending exception
          translator.stackTraceInfo.nullableType // pending exception stack
        ], const [
          w.NumType.i32
        ]),
        "${function.functionName} inner");

    Context? context = closures.contexts[functionNode];
    if (context != null && context.isEmpty) context = context.parent;

    generateOuter(functionNode, context, resumeFun);

    // Forget about the outer function locals containing the type arguments,
    // so accesses to the type arguments in the inner function will fetch them
    // from the context.
    typeLocals.clear();

    generateInner(functionNode, context, resumeFun);
  }

  void generateOuter(FunctionNode functionNode, Context? context,
      w.DefinedFunction resumeFun) {
    // Instantiate a [_SyncStarIterable] containing the context and resume
    // function for this `sync*` function.
    DartType returnType = functionNode.returnType;
    DartType elementType = returnType is InterfaceType &&
            returnType.classNode == translator.coreTypes.iterableClass
        ? returnType.typeArguments.single
        : DynamicType();
    translator.functions.allocateClass(syncStarIterableInfo.classId);
    b.i32_const(syncStarIterableInfo.classId);
    b.i32_const(initialIdentityHash);
    types.makeType(this, elementType);
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(context.currentLocal);
    } else {
      b.ref_null(w.HeapType.struct);
    }
    b.global_get(translator.makeFunctionRef(resumeFun));
    b.struct_new(syncStarIterableInfo.struct);
    b.end();
  }

  /// Clones the context pointed to by the [srcContext] local. Returns a local
  /// pointing to the cloned context.
  ///
  /// It is assumed that the context is the function-level context for the
  /// `sync*` function.
  w.Local cloneContext(
      FunctionNode functionNode, Context context, w.Local srcContext) {
    assert(context.owner == functionNode);

    final w.Local destContext = addLocal(context.currentLocal.type);
    b.struct_new_default(context.struct);
    b.local_set(destContext);

    void copyCapture(TreeNode node) {
      Capture? capture = closures.captures[node];
      if (capture != null) {
        assert(capture.context == context);
        b.local_get(destContext);
        b.local_get(srcContext);
        b.struct_get(context.struct, capture.fieldIndex);
        b.struct_set(context.struct, capture.fieldIndex);
      }
    }

    if (context.containsThis) {
      b.local_get(destContext);
      b.local_get(srcContext);
      b.struct_get(context.struct, context.thisFieldIndex);
      b.struct_set(context.struct, context.thisFieldIndex);
    }
    if (context.parent != null) {
      b.local_get(destContext);
      b.local_get(srcContext);
      b.struct_get(context.struct, context.parentFieldIndex);
      b.struct_set(context.struct, context.parentFieldIndex);
    }
    functionNode.positionalParameters.forEach(copyCapture);
    functionNode.namedParameters.forEach(copyCapture);
    functionNode.typeParameters.forEach(copyCapture);

    return destContext;
  }

  void generateInner(FunctionNode functionNode, Context? context,
      w.DefinedFunction resumeFun) {
    // Set the current Wasm function for the code generator to the inner
    // function of the `sync*`, which is to contain the body.
    function = resumeFun;

    // Parameters passed from [_SyncStarIterator.moveNext].
    suspendStateLocal = function.locals[0];
    final pendingExceptionLocal = function.locals[1];
    final pendingStackTraceLocal = function.locals[2];

    // Set up locals for contexts and `this`.
    thisLocal = null;
    Context? localContext = context;
    while (localContext != null) {
      if (!localContext.isEmpty) {
        localContext.currentLocal = function
            .addLocal(w.RefType.def(localContext.struct, nullable: true));
        if (localContext.containsThis) {
          assert(thisLocal == null);
          thisLocal = function.addLocal(localContext
              .struct.fields[localContext.thisFieldIndex].type.unpacked
              .withNullability(false));
          translator.globals.instantiateDummyValue(b, thisLocal!.type);
          b.local_set(thisLocal!);

          preciseThisLocal = thisLocal;
        }
      }
      localContext = localContext.parent;
    }

    // If a nested iterator threw, override the current exception with the
    // nested iterator exception.
    b.local_get(pendingExceptionLocal);
    b.ref_is_null();
    b.i32_eqz();
    b.if_();

    b.local_get(suspendStateLocal);
    b.local_get(pendingExceptionLocal);
    b.struct_set(
        suspendStateInfo.struct, FieldIndex.suspendStateCurrentException);

    b.local_get(suspendStateLocal);
    b.local_get(pendingStackTraceLocal);
    b.struct_set(suspendStateInfo.struct,
        FieldIndex.suspendStateCurrentExceptionStackTrace);

    _setFinalizerContinuationRethrow();

    b.end(); // end if

    // Read target index from the suspend state.
    targetIndexLocal = addLocal(w.NumType.i32);
    b.local_get(suspendStateLocal);
    b.struct_get(suspendStateInfo.struct, FieldIndex.suspendStateTargetIndex);
    b.local_set(targetIndexLocal);

    // Switch on the target index.
    masterLoop = b.loop(const [], const [w.NumType.i32]);
    labels = List.generate(targets.length, (_) => b.block()).reversed.toList();
    w.Label defaultLabel = b.block();
    b.local_get(targetIndexLocal);
    b.br_table(labels, defaultLabel);
    b.end(); // defaultLabel
    b.unreachable();

    // Initial state, executed on first [moveNext] on the iterator.
    _StateTarget initialTarget = targets.first;
    emitTargetLabel(initialTarget);

    // Clone context on first execution.
    restoreContextsAndThis(context, cloneContextFor: functionNode);

    visitStatement(functionNode.body!);

    // Final state: just keep returning.
    emitTargetLabel(targets.last);
    emitReturn();
    b.end(); // masterLoop

    b.end();
  }

  void emitTargetLabel(_StateTarget target) {
    currentTargetIndex++;
    assert(
        target.index == currentTargetIndex,
        'target.index = ${target.index}, '
        'currentTargetIndex = $currentTargetIndex, '
        'target.node.location = ${target.node.location}');
    exceptionHandlers.terminateWasmTryBlocks(this);
    b.end();
    exceptionHandlers.generateWasmTryBlocks(b);
  }

  void emitReturn() {
    // Set state target to final state.
    b.local_get(suspendStateLocal);
    b.i32_const(targets.last.index);
    b.struct_set(suspendStateInfo.struct, FieldIndex.suspendStateTargetIndex);

    // Return `false`.
    b.i32_const(0);
    b.return_();
  }

  void jumpToTarget(_StateTarget target,
      {Expression? condition, bool negated = false}) {
    if (condition == null && negated) return;
    if (target.index > currentTargetIndex) {
      // Forward jump directly to the label.
      branchIf(condition, labels[target.index], negated: negated);
    } else {
      // Backward jump via the switch.
      w.Label block = b.block();
      branchIf(condition, block, negated: !negated);
      b.i32_const(target.index);
      b.local_set(targetIndexLocal);
      b.br(masterLoop);
      b.end(); // block
    }
  }

  void restoreContextsAndThis(Context? context,
      {FunctionNode? cloneContextFor}) {
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(suspendStateLocal);
      b.struct_get(suspendStateInfo.struct, FieldIndex.suspendStateContext);
      b.ref_cast(context.currentLocal.type as w.RefType);
      b.local_set(context.currentLocal);

      if (context.owner == cloneContextFor) {
        context.currentLocal =
            cloneContext(cloneContextFor!, context, context.currentLocal);
      }

      while (context!.parent != null) {
        assert(!context.parent!.isEmpty);
        b.local_get(context.currentLocal);
        b.struct_get(context.struct, context.parentFieldIndex);
        b.ref_as_non_null();
        context = context.parent!;
        b.local_set(context.currentLocal);
      }
      if (context.containsThis) {
        b.local_get(context.currentLocal);
        b.struct_get(context.struct, context.thisFieldIndex);
        b.ref_as_non_null();
        b.local_set(thisLocal!);
      }
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    _StateTarget? inner = innerTargets[node];
    if (inner == null) return super.visitDoStatement(node);

    emitTargetLabel(inner);
    allocateContext(node);
    visitStatement(node.body);
    jumpToTarget(inner, condition: node.condition);
  }

  @override
  void visitForStatement(ForStatement node) {
    _StateTarget? inner = innerTargets[node];
    if (inner == null) return super.visitForStatement(node);
    _StateTarget after = afterTargets[node]!;

    allocateContext(node);
    for (VariableDeclaration variable in node.variables) {
      visitStatement(variable);
    }
    emitTargetLabel(inner);
    jumpToTarget(after, condition: node.condition, negated: true);
    visitStatement(node.body);

    emitForStatementUpdate(node);

    jumpToTarget(inner);
    emitTargetLabel(after);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _StateTarget? after = afterTargets[node];
    if (after == null) return super.visitIfStatement(node);
    _StateTarget? inner = innerTargets[node];

    jumpToTarget(inner ?? after, condition: node.condition, negated: true);
    visitStatement(node.then);
    if (node.otherwise != null) {
      jumpToTarget(after);
      emitTargetLabel(inner!);
      visitStatement(node.otherwise!);
    }
    emitTargetLabel(after);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _StateTarget? after = afterTargets[node];
    if (after == null) {
      final w.Label label = b.block();
      labelTargets[node] = DirectLabelTarget(label);
      visitStatement(node.body);
      labelTargets.remove(node);
      b.end();
    } else {
      labelTargets[node] =
          IndirectLabelTarget(exceptionHandlers.numFinalizers, after);
      visitStatement(node.body);
      labelTargets.remove(node);
      emitTargetLabel(after);
    }
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    labelTargets[node.target]!.jump(this);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _StateTarget? after = afterTargets[node];
    if (after == null) return super.visitSwitchStatement(node);

    // TODO(51342): Implement this.
    unimplemented(node, "switch in sync*", const []);
  }

  @override
  void visitTryCatch(TryCatch node) {
    _StateTarget? after = afterTargets[node];
    if (after == null) return super.visitTryCatch(node);

    allocateContext(node);

    for (Catch c in node.catches) {
      if (c.exception != null) {
        visitVariableDeclaration(c.exception!);
      }
      if (c.stackTrace != null) {
        visitVariableDeclaration(c.stackTrace!);
      }
    }

    exceptionHandlers.pushTryCatch(node);
    exceptionHandlers.generateWasmTryBlocks(b);
    visitStatement(node.body);
    jumpToTarget(after);
    exceptionHandlers.terminateWasmTryBlocks(this);
    exceptionHandlers.pop();

    void setVar(VariableDeclaration? var_, void Function() emitValue,
        w.ValueType valueType) {
      final Capture? capture = closures.captures[var_];
      final w.Local? local = locals[var_];

      if (capture == null && local == null) {
        // TODO: Does this mean unused?
        return;
      }

      if (capture == null) {
        emitValue();
        b.ref_as_non_null();
        b.local_set(local!);
      } else {
        b.local_get(capture.context.currentLocal);
        b.ref_as_non_null();
        emitValue();
        translator.convertType(function, valueType,
            capture.context.struct.fields[capture.fieldIndex].type.unpacked);
        b.struct_set(capture.context.struct, capture.fieldIndex);
      }
    }

    void emitCatchBlock(Catch catch_, bool emitGuard) {
      if (emitGuard) {
        final DartType guard = catch_.guard;
        _getCurrentException();
        b.ref_as_non_null();
        types.emitTypeTest(
            this, guard, translator.coreTypes.objectNonNullableRawType);
        b.if_();
      }
      setVar(catch_.exception, () => _getCurrentException(),
          translator.topInfo.nullableType);
      setVar(catch_.stackTrace, () => _getCurrentExceptionStackTrace(),
          translator.stackTraceInfo.nullableType);
      visitStatement(catch_.body);
      jumpToTarget(after);
      if (emitGuard) {
        b.end();
      }
    }

    for (Catch catch_ in node.catches) {
      emitTargetLabel(innerTargets[catch_]!);

      final bool shouldEmitGuard =
          catch_.guard != translator.coreTypes.objectNonNullableRawType;
      emitCatchBlock(catch_, shouldEmitGuard);
      if (!shouldEmitGuard) {
        break;
      }
    }

    // rethrow
    _getCurrentException();
    b.ref_as_non_null();
    _getCurrentExceptionStackTrace();
    b.ref_as_non_null();
    _setFinalizerContinuationRethrow();
    b.throw_(translator.exceptionTag);

    emitTargetLabel(after);
  }

  @override
  void visitTryFinally(TryFinally node) {
    allocateContext(node);

    final _StateTarget finalizerTarget = innerTargets[node]!;
    final _StateTarget continuationTarget = afterTargets[node]!;

    // Body
    {
      exceptionHandlers.pushTryFinally(node);
      exceptionHandlers.generateWasmTryBlocks(b);
      visitStatement(node.body);

      // Set continuation
      b.local_get(suspendStateLocal);
      b.i32_const(continuationTarget.index);
      b.i32_const(2);
      b.i32_add();
      b.struct_set(
          suspendStateInfo.struct, FieldIndex.suspendStateFinalizerTargetIndex);
      b.local_get(suspendStateLocal);
      b.i32_const(0);
      b.struct_set(
          suspendStateInfo.struct, FieldIndex.suspendStateNumFinalizers);

      jumpToTarget(finalizerTarget);
      exceptionHandlers.terminateWasmTryBlocks(this);
      exceptionHandlers.pop();
    }

    // Finalizer
    {
      emitTargetLabel(finalizerTarget);
      visitStatement(node.finalizer);

      // Check the `numFinalizer` state for how many parent finalizers to run.
      // If this is the top-most finalizer block no need for the check.
      final ExceptionHandler? nextFinalizer = exceptionHandlers.nextFinalizer;
      if (nextFinalizer != null) {
        b.local_get(suspendStateLocal);
        b.struct_get(
            suspendStateInfo.struct, FieldIndex.suspendStateNumFinalizers);
        b.if_();
        // Counter is non-zero. Decrement counter.
        b.local_get(suspendStateLocal);
        b.local_get(suspendStateLocal);
        b.struct_get(
            suspendStateInfo.struct, FieldIndex.suspendStateNumFinalizers);
        b.i32_const(1);
        b.i32_sub();
        b.struct_set(
            suspendStateInfo.struct, FieldIndex.suspendStateNumFinalizers);
        jumpToTarget(nextFinalizer.target);
        b.end();
      }

      // Counter is zero or we're at the top finalizer, check continuation.
      // 0 = return
      b.local_get(suspendStateLocal);
      b.struct_get(
          suspendStateInfo.struct, FieldIndex.suspendStateFinalizerTargetIndex);
      b.i32_eqz();
      b.if_();
      if (nextFinalizer == null) {
        b.i32_const(0); // false = done
        b.return_();
      } else {
        jumpToTarget(nextFinalizer.target);
      }
      b.end();

      // 1 = rethrow
      b.local_get(suspendStateLocal);
      b.struct_get(
          suspendStateInfo.struct, FieldIndex.suspendStateFinalizerTargetIndex);
      b.i32_const(1);
      b.i32_eq();
      b.if_();

      _getCurrentException();
      b.ref_as_non_null();
      _getCurrentExceptionStackTrace();
      b.ref_as_non_null();
      b.throw_(translator.exceptionTag);

      b.end();

      // Any other value: jump to the target.
      b.local_get(suspendStateLocal);
      b.struct_get(
          suspendStateInfo.struct, FieldIndex.suspendStateFinalizerTargetIndex);
      b.i32_const(2);
      b.i32_sub();
      b.local_set(targetIndexLocal);
      b.br(masterLoop);
    }

    emitTargetLabel(continuationTarget);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _StateTarget? inner = innerTargets[node];
    if (inner == null) return super.visitWhileStatement(node);
    _StateTarget after = afterTargets[node]!;

    emitTargetLabel(inner);
    jumpToTarget(after, condition: node.condition, negated: true);
    allocateContext(node);
    visitStatement(node.body);
    jumpToTarget(inner);
    emitTargetLabel(after);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _StateTarget after = afterTargets[node]!;

    // Evaluate operand and store it to `_current` for `yield` or
    // `_yieldStarIterable` for `yield*`.
    b.local_get(suspendStateLocal);
    b.struct_get(suspendStateInfo.struct, FieldIndex.suspendStateIterator);
    wrap(node.expression, translator.topInfo.nullableType);
    if (node.isYieldStar) {
      b.ref_cast(translator.objectInfo.nonNullableType);
      b.struct_set(syncStarIteratorInfo.struct,
          FieldIndex.syncStarIteratorYieldStarIterable);
    } else {
      b.struct_set(
          syncStarIteratorInfo.struct, FieldIndex.syncStarIteratorCurrent);
    }

    // Find the current context.
    Context? context;
    TreeNode contextOwner = node;
    do {
      contextOwner = contextOwner.parent!;
      context = closures.contexts[contextOwner];
    } while (
        contextOwner.parent != null && (context == null || context.isEmpty));

    // Store context.
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(suspendStateLocal);
      b.local_get(context.currentLocal);
      b.struct_set(suspendStateInfo.struct, FieldIndex.suspendStateContext);
    }

    // Set state target to label after yield.
    b.local_get(suspendStateLocal);
    b.i32_const(after.index);
    b.struct_set(suspendStateInfo.struct, FieldIndex.suspendStateTargetIndex);

    // Return `true`.
    b.i32_const(1);
    b.return_();

    // Resume.
    emitTargetLabel(after);

    restoreContextsAndThis(context);

    // For `yield*`, check for pending exception.
    if (node.isYieldStar) {
      w.Label exceptionCheck = b.block();
      _getCurrentException();
      b.br_on_null(exceptionCheck);
      _getCurrentExceptionStackTrace();
      b.ref_as_non_null();
      _setFinalizerContinuationRethrow();
      b.throw_(translator.exceptionTag);
      b.end(); // exceptionCheck
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    assert(node.expression == null);

    final ExceptionHandler? finalizer = exceptionHandlers.nextFinalizer;
    if (finalizer == null) {
      emitReturn();
    } else {
      b.local_get(suspendStateLocal);
      b.i32_const(0);
      b.struct_set(
          suspendStateInfo.struct, FieldIndex.suspendStateFinalizerTargetIndex);
      jumpToTarget(finalizer.target);
    }
  }

  @override
  w.ValueType visitThrow(Throw node, w.ValueType expectedType) {
    // TODO: Only override current exception if we're in try-finally

    final exceptionLocal = addLocal(translator.topInfo.nonNullableType);
    wrap(node.expression, translator.topInfo.nonNullableType);
    b.local_set(exceptionLocal);
    _setCurrentException(() => b.local_get(exceptionLocal));

    final stackTraceLocal = addLocal(translator.stackTraceInfo.nonNullableType);
    call(translator.stackTraceCurrent.reference);
    b.local_set(stackTraceLocal);
    _setCurrentExceptionStackTrace(() => b.local_get(stackTraceLocal));

    _setFinalizerContinuationRethrow();

    b.local_get(exceptionLocal);
    b.local_get(stackTraceLocal);
    call(translator.errorThrow.reference);

    b.unreachable();
    return expectedType;
  }

  @override
  w.ValueType visitRethrow(Rethrow node, w.ValueType expectedType) {
    _getCurrentException();
    b.ref_as_non_null();
    _getCurrentExceptionStackTrace();
    b.ref_as_non_null();
    _setFinalizerContinuationRethrow();
    b.throw_(translator.exceptionTag);
    b.unreachable();
    return expectedType;
  }

  void _getCurrentException() {
    b.local_get(suspendStateLocal);
    b.struct_get(
        suspendStateInfo.struct, FieldIndex.suspendStateCurrentException);
  }

  void _setCurrentException(void Function() emitValue) {
    b.local_get(suspendStateLocal);
    emitValue();
    b.struct_set(
        suspendStateInfo.struct, FieldIndex.suspendStateCurrentException);
  }

  void _getCurrentExceptionStackTrace() {
    b.local_get(suspendStateLocal);
    b.struct_get(suspendStateInfo.struct,
        FieldIndex.suspendStateCurrentExceptionStackTrace);
  }

  void _setCurrentExceptionStackTrace(void Function() emitValue) {
    b.local_get(suspendStateLocal);
    emitValue();
    b.struct_set(suspendStateInfo.struct,
        FieldIndex.suspendStateCurrentExceptionStackTrace);
  }

  void _setFinalizerContinuationRethrow() {
    b.local_get(suspendStateLocal);
    b.i32_const(1);
    b.struct_set(
        suspendStateInfo.struct, FieldIndex.suspendStateFinalizerTargetIndex);
  }
}
