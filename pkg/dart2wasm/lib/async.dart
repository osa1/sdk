// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'state_machine.dart';
import 'class_info.dart';
import 'closures.dart';
import 'code_generator.dart';
import 'sync_star.dart' show StateTarget, StateTargetPlacement;

class AsyncCodeGenerator extends StateMachineCodeGenerator {
  AsyncCodeGenerator(super.translator, super.function, super.reference);

  /// The local in the inner function for the async state, with type
  /// `ref _AsyncSuspendState`.
  late final w.Local suspendStateLocal;

  /// The local in the inner function for the value of the last awaited future,
  /// with type `ref null #Top`.
  late final w.Local awaitValueLocal;

  late final ClassInfo asyncSuspendStateInfo =
      translator.classInfo[translator.asyncSuspendStateClass]!;

  @override
  void generateBodies(FunctionNode functionNode) {
    // Number and categorize CFG targets.
    targets = YieldFinder(translator.options.enableAsserts).find(functionNode);
    for (final target in targets) {
      switch (target.placement) {
        case StateTargetPlacement.Inner:
          innerTargets[target.node] = target;
          break;
        case StateTargetPlacement.After:
          afterTargets[target.node] = target;
          break;
      }
    }

    _exceptionHandlers = _ExceptionHandlerStack(this);

    // Wasm function containing the body of the `async` function
    // (`_AyncResumeFun`).
    final resumeFun = m.functions.define(
        m.types.defineFunction([
          asyncSuspendStateInfo.nonNullableType, // _AsyncSuspendState
          translator.topInfo.nullableType, // Object?, await value
          translator.topInfo.nullableType, // Object?, error value
          translator.stackTraceInfo.repr
              .nullableType // StackTrace?, error stack trace
        ], [
          // Inner function does not return a value, but it's Dart type is
          // `void Function(...)` and all Dart functions return a value, so we
          // add a return type.
          translator.topInfo.nullableType
        ]),
        "${function.functionName} inner");

    Context? context = closures.contexts[functionNode];
    if (context != null && context.isEmpty) context = context.parent;

    _generateOuter(functionNode, context, resumeFun);

    // Forget about the outer function locals containing the type arguments,
    // so accesses to the type arguments in the inner function will fetch them
    // from the context.
    typeLocals.clear();

    _generateInner(functionNode, context, resumeFun);
  }

  void _generateOuter(
      FunctionNode functionNode, Context? context, w.BaseFunction resumeFun) {
    // Outer (wrapper) function creates async state, calls the inner function
    // (which runs until first suspension point, i.e. `await`), and returns the
    // completer's future.

    // (1) Create async state.

    final asyncStateLocal = function
        .addLocal(w.RefType(asyncSuspendStateInfo.struct, nullable: false));

    // AsyncResumeFun _resume
    b.global_get(translator.makeFunctionRef(resumeFun));

    // WasmStructRef? _context
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(context.currentLocal);
    } else {
      b.ref_null(w.HeapType.struct);
    }

    // _AsyncCompleter _completer
    types.makeType(this, functionNode.emittedValueType!);
    call(translator.makeAsyncCompleter.reference);

    // Allocate `_AsyncSuspendState`
    call(translator.newAsyncSuspendState.reference);
    b.local_set(asyncStateLocal);

    // (2) Call inner function.
    //
    // Note: the inner function does not throw, so we don't need a `try` block
    // here.

    b.local_get(asyncStateLocal);
    b.ref_null(translator.topInfo.struct); // await value
    b.ref_null(translator.topInfo.struct); // error value
    b.ref_null(translator.stackTraceInfo.repr.struct); // stack trace
    b.call(resumeFun);
    b.drop(); // drop null

    // (3) Return the completer's future.

    b.local_get(asyncStateLocal);
    final completerFutureGetterType = translator.functions
        .getFunctionType(translator.completerFuture.getterReference);
    b.struct_get(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateCompleter);
    translator.convertType(
        function,
        asyncSuspendStateInfo.struct.fields[5].type.unpacked,
        completerFutureGetterType.inputs[0]);
    call(translator.completerFuture.getterReference);
    b.end();
  }

  void _generateInner(FunctionNode functionNode, Context? context,
      w.FunctionBuilder resumeFun) {
    // void Function(_AsyncSuspendState, Object?)

    // Set the current Wasm function for the code generator to the inner
    // function of the `async`, which is to contain the body.
    function = resumeFun;

    suspendStateLocal = function.locals[0]; // ref _AsyncSuspendState
    awaitValueLocal = function.locals[1]; // ref null #Top

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

    // Read target index from the suspend state.
    targetIndexLocal = addLocal(w.NumType.i32);
    b.local_get(suspendStateLocal);
    b.struct_get(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateTargetIndex);
    b.local_set(targetIndexLocal);

    // The outer `try` block calls `completeOnError` on exceptions.
    b.try_();

    // Switch on the target index.
    masterLoop = b.loop(const [], const []);
    labels = List.generate(targets.length, (_) => b.block()).reversed.toList();
    w.Label defaultLabel = b.block();
    b.local_get(targetIndexLocal);
    b.br_table(labels, defaultLabel);
    b.end(); // defaultLabel
    b.unreachable();

    // Initial state
    final StateTarget initialTarget = targets.first;
    _emitTargetLabel(initialTarget);

    // Clone context on first execution.
    b.restoreSuspendStateContext(
        suspendStateLocal,
        asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateContext,
        closures,
        context,
        thisLocal,
        cloneContextFor: functionNode);

    visitStatement(functionNode.body!);

    // Final state: return.
    _emitTargetLabel(targets.last);
    b.local_get(suspendStateLocal);
    b.struct_get(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateCompleter);
    b.ref_null(translator.topInfo.struct);
    call(translator.completerComplete.reference);
    b.return_();
    b.end(); // masterLoop

    final stackTraceLocal =
        addLocal(translator.stackTraceInfo.repr.nonNullableType);

    final exceptionLocal = addLocal(translator.topInfo.nonNullableType);

    void callCompleteError() {
      b.local_get(suspendStateLocal);
      b.struct_get(
          asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateCompleter);
      b.local_get(exceptionLocal);
      b.local_get(stackTraceLocal);
      call(translator.completerCompleteError.reference);
      b.return_();
    }

    // Handle Dart exceptions.
    b.catch_(translator.exceptionTag);
    b.local_set(stackTraceLocal);
    b.local_set(exceptionLocal);
    callCompleteError();

    // Handle JS exceptions.
    b.catch_all();

    // Create a generic JavaScript error.
    call(translator.javaScriptErrorFactory.reference);
    b.local_set(exceptionLocal);

    // JS exceptions won't have a Dart stack trace, so we attach the current
    // Dart stack trace.
    call(translator.stackTraceCurrent.reference);
    b.local_set(stackTraceLocal);

    callCompleteError();

    b.end(); // end try

    b.unreachable();
    b.end();
  }

  // Handle awaits
  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;
    if (expression is VariableSet) {
      final value = expression.value;
      if (value is AwaitExpression) {
        _generateAwait(value, expression.variable);
        return;
      }
    }

    super.visitExpressionStatement(node);
  }

  void _generateAwait(AwaitExpression node, VariableDeclaration awaitValueVar) {
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
      b.struct_set(
          asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateContext);
    }

    // Set state target to label after await.
    final StateTarget after = afterTargets[node.parent]!;
    b.local_get(suspendStateLocal);
    b.i32_const(after.index);
    b.struct_set(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateTargetIndex);

    final DartType? runtimeType = node.runtimeCheckType;
    DartType? futureTypeParam;
    if (runtimeType != null) {
      final futureType = runtimeType as InterfaceType;
      assert(futureType.classNode == translator.coreTypes.futureClass);
      assert(futureType.typeArguments.length == 1);
      futureTypeParam = futureType.typeArguments[0];
    }

    if (futureTypeParam != null) {
      types.makeType(this, futureTypeParam);
    }
    b.local_get(suspendStateLocal);
    wrap(node.operand, translator.topInfo.nullableType);
    if (runtimeType != null) {
      call(translator.awaitHelperWithTypeCheck.reference);
    } else {
      call(translator.awaitHelper.reference);
    }
    b.return_();

    // Generate resume label
    _emitTargetLabel(after);

    b.restoreSuspendStateContext(
        suspendStateLocal,
        asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateContext,
        closures,
        context,
        thisLocal);

    // Handle exceptions
    final exceptionBlock = b.block();
    b.local_get(pendingExceptionLocal);
    b.br_on_null(exceptionBlock);

    _exceptionHandlers.forEachFinalizer((finalizer, last) {
      finalizer.setContinuationRethrow(() {
        b.local_get(pendingExceptionLocal);
        b.ref_as_non_null();
      }, () => b.local_get(pendingStackTraceLocal));
    });

    b.local_get(pendingStackTraceLocal);
    b.ref_as_non_null();

    b.throw_(translator.exceptionTag);
    b.end(); // exceptionBlock

    _setVariable(awaitValueVar, () {
      b.local_get(awaitValueLocal);
      translator.convertType(
          function, awaitValueLocal.type, translateType(awaitValueVar.type));
    });
  }

  @override
  void setSuspendStateCurrentException(void Function() emitValue) {
    b.local_get(suspendStateLocal);
    emitValue();
    b.struct_set(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentException);
  }

  @override
  void getSuspendStateCurrentException() {
    b.local_get(suspendStateLocal);
    b.struct_get(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentException);
  }

  @override
  void setSuspendStateCurrentStackTrace(void Function() emitValue) {
    b.local_get(suspendStateLocal);
    emitValue();
    b.struct_set(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentExceptionStackTrace);
  }

  @override
  void getSuspendStateCurrentStackTrace() {
    b.local_get(suspendStateLocal);
    b.struct_get(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentExceptionStackTrace);
  }

  @override
  void setSuspendStateCurrentReturnValue(void Function() emitValue) {
    b.local_get(suspendStateLocal);
    emitValue();
    b.struct_set(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentReturnValue);
  }

  @override
  void getSuspendStateCurrentReturnValue() {
    b.local_get(suspendStateLocal);
    b.struct_get(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentReturnValue);
  }

  @override
  void completeAsync(void Function() emitValue) {
    b.local_get(suspendStateLocal);
    b.struct_get(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateCompleter);
    emitValue();
    call(translator.completerComplete.reference);
  }
}
