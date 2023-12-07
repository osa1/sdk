// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/protocol.dart' as macro;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/summary2/macro_declarations.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';

/// The full list of [macro.ArgumentKind]s for this dart type (includes the type
/// itself as well as type arguments, in source order with
/// [macro.ArgumentKind.nullable] modifiers preceding the nullable types).
List<macro.ArgumentKind> _dartTypeArgumentKinds(DartType dartType) => [
      if (dartType.nullabilitySuffix == NullabilitySuffix.question)
        macro.ArgumentKind.nullable,
      switch (dartType) {
        DartType(isDartCoreBool: true) => macro.ArgumentKind.bool,
        DartType(isDartCoreDouble: true) => macro.ArgumentKind.double,
        DartType(isDartCoreInt: true) => macro.ArgumentKind.int,
        DartType(isDartCoreNum: true) => macro.ArgumentKind.num,
        DartType(isDartCoreNull: true) => macro.ArgumentKind.nil,
        DartType(isDartCoreObject: true) => macro.ArgumentKind.object,
        DartType(isDartCoreString: true) => macro.ArgumentKind.string,
        // TODO(jakemac): Support nested type arguments for collections.
        DartType(isDartCoreList: true) => macro.ArgumentKind.list,
        DartType(isDartCoreMap: true) => macro.ArgumentKind.map,
        DartType(isDartCoreSet: true) => macro.ArgumentKind.set,
        DynamicType() => macro.ArgumentKind.dynamic,
        // TODO(jakemac): Support type annotations and code objects
        _ =>
          throw UnsupportedError('Unsupported macro type argument $dartType'),
      },
      if (dartType is ParameterizedType) ...[
        for (var type in dartType.typeArguments)
          ..._dartTypeArgumentKinds(type),
      ]
    ];

List<macro.ArgumentKind> _typeArgumentsForNode(ast.TypedLiteral node) {
  if (node.typeArguments == null) {
    return [
      // TODO(jakemac): Use downward inference to build these types and detect maps
      // versus sets.
      if (node is ast.ListLiteral || node is ast.SetOrMapLiteral)
        macro.ArgumentKind.dynamic,
      if (node is ast.SetOrMapLiteral &&
          node.elements.first is ast.MapLiteralEntry)
        macro.ArgumentKind.dynamic,
    ];
  }
  return [
    for (var type in node.typeArguments!.arguments.map((arg) => arg.type!))
      ..._dartTypeArgumentKinds(type),
  ];
}

class LibraryMacroApplier {
  final LinkedElementFactory elementFactory;
  final MultiMacroExecutor macroExecutor;
  final bool Function(Uri) isLibraryBeingLinked;
  final DeclarationBuilder declarationBuilder;

  /// The reversed queue of macro applications to apply.
  ///
  /// We add classes before methods, and methods in the reverse order,
  /// classes in the reverse order, annotations in the direct order.
  ///
  /// We iterate from the end looking for the next application to apply.
  /// This way we ensure two ordering rules:
  /// 1. inner before outer
  /// 2. right to left
  /// 3. source order
  final List<_MacroApplication> _applications = [];

  /// The map from [InstanceElement] to the applications associated with it.
  /// This includes applications on the class itself, and on the methods of
  /// the class.
  final Map<InstanceElement, List<_MacroApplication>> _interfaceApplications =
      {};

  late final macro.TypePhaseIntrospector _typesPhaseIntrospector =
      _TypePhaseIntrospector(elementFactory, declarationBuilder);

  LibraryMacroApplier({
    required this.elementFactory,
    required this.macroExecutor,
    required this.isLibraryBeingLinked,
    required this.declarationBuilder,
  });

  Future<void> add({
    required LibraryElementImpl libraryElement,
    required LibraryOrAugmentationElementImpl container,
    required ast.CompilationUnit unit,
  }) async {
    for (final declaration in unit.declarations.reversed) {
      switch (declaration) {
        case ast.ClassDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryElement: libraryElement,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.classType,
            classAnnotations: declaration.metadata,
            declarationsPhaseInterface: declarationElement,
            members: declaration.members,
          );
        case ast.ClassTypeAliasImpl():
          // TODO(scheglov): implement it
          break;
        case ast.EnumDeclarationImpl():
          // TODO(scheglov): implement it
          break;
        case ast.ExtensionDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryElement: libraryElement,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.extension,
            classAnnotations: declaration.metadata,
            declarationsPhaseInterface: null,
            members: declaration.members,
          );
        case ast.ExtensionTypeDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryElement: libraryElement,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.extension,
            classAnnotations: declaration.metadata,
            declarationsPhaseInterface: declarationElement,
            members: declaration.members,
          );
        case ast.FunctionDeclarationImpl():
          // TODO(scheglov): implement it
          break;
        case ast.FunctionTypeAliasImpl():
          // TODO(scheglov): implement it
          break;
        case ast.GenericTypeAliasImpl():
          // TODO(scheglov): implement it
          break;
        case ast.MixinDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryElement: libraryElement,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.mixinType,
            classAnnotations: declaration.metadata,
            declarationsPhaseInterface: declarationElement,
            members: declaration.members,
          );
        case ast.TopLevelVariableDeclarationImpl():
          // TODO(scheglov): implement it
          break;
        default:
          throw UnimplementedError('${declaration.runtimeType}');
      }
    }
  }

  /// Builds the augmentation library code for [results].
  String? buildAugmentationLibraryCode(
    List<macro.MacroExecutionResult> results,
  ) {
    if (results.isEmpty) {
      return null;
    }

    return macroExecutor
        .buildAugmentationLibrary(
          results,
          declarationBuilder.typeDeclarationOf,
          declarationBuilder.resolveIdentifier,
          _inferOmittedType,
        )
        .trim();
  }

  Future<List<macro.MacroExecutionResult>?> executeDeclarationsPhase({
    required LibraryElementImpl library,
  }) async {
    final application = _nextForDeclarationsPhase(
      library: library,
    );
    if (application == null) {
      return null;
    }

    final results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        final declaration = _buildDeclaration(application.targetNode);

        final introspector = _DeclarationPhaseIntrospector(
          elementFactory,
          declarationBuilder,
          library.typeSystem,
        );

        final result = await macroExecutor.executeDeclarationsPhase(
          application.instance,
          declaration,
          introspector,
        );

        _addDiagnostics(application, result);
        if (result.isNotEmpty) {
          results.add(result);
        }
      },
      targetElement: application.targetElement,
      annotationIndex: application.annotationIndex,
    );

    return results;
  }

  Future<List<macro.MacroExecutionResult>?> executeDefinitionsPhase() async {
    final application = _nextForDefinitionsPhase();
    if (application == null) {
      return null;
    }

    final results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        final declaration = _buildDeclaration(application.targetNode);

        final introspector = _DefinitionPhaseIntrospector(
          elementFactory,
          declarationBuilder,
          application.libraryElement.typeSystem,
        );

        final result = await macroExecutor.executeDefinitionsPhase(
          application.instance,
          declaration,
          introspector,
        );

        _addDiagnostics(application, result);
        if (result.isNotEmpty) {
          results.add(result);
        }
      },
      targetElement: application.targetElement,
      annotationIndex: application.annotationIndex,
    );

    return results;
  }

  Future<List<macro.MacroExecutionResult>?> executeTypesPhase() async {
    final application = _nextForTypesPhase();
    if (application == null) {
      return null;
    }

    final results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        final declaration = _buildDeclaration(application.targetNode);

        final result = await macroExecutor.executeTypesPhase(
          application.instance,
          declaration,
          _typesPhaseIntrospector,
        );

        _addDiagnostics(application, result);
        if (result.isNotEmpty) {
          results.add(result);
        }
      },
      targetElement: application.targetElement,
      annotationIndex: application.annotationIndex,
    );

    return results;
  }

  Future<void> _addAnnotations({
    required LibraryElementImpl libraryElement,
    required LibraryOrAugmentationElementImpl container,
    required InstanceElement? declarationsPhaseElement,
    required ast.Declaration targetNode,
    required macro.DeclarationKind targetDeclarationKind,
    required List<ast.Annotation> annotations,
  }) async {
    if (targetNode is ast.FieldDeclaration) {
      for (final field in targetNode.fields.variables) {
        await _addAnnotations(
          libraryElement: libraryElement,
          container: container,
          declarationsPhaseElement: declarationsPhaseElement,
          targetNode: field,
          targetDeclarationKind: macro.DeclarationKind.field,
          annotations: annotations,
        );
      }
      return;
    }

    final targetElement =
        targetNode.declaredElement.ifTypeOrNull<MacroTargetElement>();
    if (targetElement == null) {
      return;
    }

    for (final (annotationIndex, annotation) in annotations.indexed) {
      final importedMacro = _importedMacro(
        container: container,
        annotation: annotation,
      );
      if (importedMacro == null) {
        continue;
      }

      final arguments = await _runWithCatchingExceptions(
        () async {
          return _buildArguments(
            annotationIndex: annotationIndex,
            node: importedMacro.arguments,
          );
        },
        targetElement: targetElement,
        annotationIndex: annotationIndex,
      );
      if (arguments == null) {
        continue;
      }

      final instance = await importedMacro.bundleExecutor.instantiate(
        libraryUri: importedMacro.macroLibrary.source.uri,
        className: importedMacro.macroClass.name,
        constructorName: importedMacro.constructorName ?? '',
        arguments: arguments,
      );

      final phasesToExecute = macro.Phase.values.where((phase) {
        return instance.shouldExecute(targetDeclarationKind, phase);
      }).toSet();

      final application = _MacroApplication(
        libraryElement: libraryElement,
        declarationsPhaseElement: declarationsPhaseElement,
        targetNode: targetNode,
        targetElement: targetElement,
        annotationIndex: annotationIndex,
        annotationNode: annotation,
        instance: instance,
        phasesToExecute: phasesToExecute,
      );

      _applications.add(application);

      // Record mapping for declarations phase dependencies.
      if (declarationsPhaseElement != null) {
        (_interfaceApplications[declarationsPhaseElement] ??= [])
            .add(application);
      }
    }
  }

  Future<void> _addClassLike({
    required LibraryElementImpl libraryElement,
    required LibraryOrAugmentationElementImpl container,
    required MacroTargetElement targetElement,
    required ast.Declaration classNode,
    required macro.DeclarationKind classDeclarationKind,
    required List<ast.Annotation> classAnnotations,
    required InterfaceElement? declarationsPhaseInterface,
    required List<ast.ClassMember> members,
  }) async {
    await _addAnnotations(
      libraryElement: libraryElement,
      container: container,
      targetNode: classNode,
      targetDeclarationKind: classDeclarationKind,
      declarationsPhaseElement: declarationsPhaseInterface,
      annotations: classAnnotations,
    );

    for (final member in members.reversed) {
      final memberDeclarationKind = switch (member) {
        ast.ConstructorDeclaration() => macro.DeclarationKind.constructor,
        ast.FieldDeclaration() => macro.DeclarationKind.field,
        ast.MethodDeclaration() => macro.DeclarationKind.method,
      };

      await _addAnnotations(
        libraryElement: libraryElement,
        container: container,
        targetNode: member,
        targetDeclarationKind: memberDeclarationKind,
        declarationsPhaseElement: declarationsPhaseInterface,
        annotations: member.metadata,
      );
    }
  }

  void _addDiagnostics(
    _MacroApplication application,
    macro.MacroExecutionResult result,
  ) {
    MacroDiagnosticMessage convertMessage(
      macro.DiagnosticMessage message,
    ) {
      MacroDiagnosticTarget target;
      switch (message.target) {
        case macro.DeclarationDiagnosticTarget macroTarget:
          final element = (macroTarget.declaration as HasElement).element;
          target = ElementMacroDiagnosticTarget(element: element);
        default:
          target = ApplicationMacroDiagnosticTarget(
            annotationIndex: application.annotationIndex,
          );
      }

      return MacroDiagnosticMessage(
        target: target,
        message: message.message,
      );
    }

    for (final diagnostic in result.diagnostics) {
      application.targetElement.addMacroDiagnostic(
        MacroDiagnostic(
          severity: diagnostic.severity,
          message: convertMessage(diagnostic.message),
          contextMessages:
              diagnostic.contextMessages.map(convertMessage).toList(),
        ),
      );
    }
  }

  macro.Declaration _buildDeclaration(ast.AstNode node) {
    return declarationBuilder.buildDeclaration(node);
  }

  bool _hasInterfaceDependenciesSatisfied(_MacroApplication application) {
    final dependencyElements = _interfaceDependencies(
      application.declarationsPhaseElement,
    );
    if (dependencyElements == null) {
      return true;
    }

    for (final dependencyElement in dependencyElements) {
      final applications = _interfaceApplications[dependencyElement];
      if (applications != null) {
        for (final dependencyApplication in applications) {
          if (dependencyApplication.hasDeclarationsPhase) {
            return false;
          }
        }
      }
    }

    return true;
  }

  /// If [annotation] references a macro, invokes the right callback.
  _AnnotationMacro? _importedMacro({
    required LibraryOrAugmentationElementImpl container,
    required ast.Annotation annotation,
  }) {
    final arguments = annotation.arguments;
    if (arguments == null) {
      return null;
    }

    final String? prefix;
    final String name;
    final String? constructorName;
    final nameNode = annotation.name;
    if (nameNode is ast.SimpleIdentifier) {
      prefix = null;
      name = nameNode.name;
      constructorName = annotation.constructorName?.name;
    } else if (nameNode is ast.PrefixedIdentifier) {
      final importPrefixCandidate = nameNode.prefix.name;
      final hasImportPrefix = container.libraryImports.any(
          (import) => import.prefix?.element.name == importPrefixCandidate);
      if (hasImportPrefix) {
        prefix = importPrefixCandidate;
        name = nameNode.identifier.name;
        constructorName = annotation.constructorName?.name;
      } else {
        prefix = null;
        name = nameNode.prefix.name;
        constructorName = nameNode.identifier.name;
      }
    } else {
      throw StateError('${nameNode.runtimeType} $nameNode');
    }

    for (final import in container.libraryImports) {
      if (import.prefix?.element.name != prefix) {
        continue;
      }

      final importedLibrary = import.importedLibrary;
      if (importedLibrary == null) {
        continue;
      }

      // Skip if a library that is being linked.
      final importedUri = importedLibrary.source.uri;
      if (isLibraryBeingLinked(importedUri)) {
        continue;
      }

      final macroClass = importedLibrary.scope.lookup(name).getter;
      if (macroClass is! ClassElementImpl) {
        continue;
      }

      final macroLibrary = macroClass.library;
      final bundleExecutor = macroLibrary.bundleMacroExecutor;
      if (bundleExecutor == null) {
        continue;
      }

      if (macroClass.isMacro) {
        return _AnnotationMacro(
          macroLibrary: macroLibrary,
          bundleExecutor: bundleExecutor,
          macroClass: macroClass,
          constructorName: constructorName,
          arguments: arguments,
        );
      }
    }
    return null;
  }

  macro.TypeAnnotation _inferOmittedType(
    macro.OmittedTypeAnnotation omittedType,
  ) {
    throw UnimplementedError();
  }

  Set<InstanceElement>? _interfaceDependencies(InstanceElement? element) {
    // TODO(scheglov): other elements
    switch (element) {
      case ExtensionElement():
        // TODO(scheglov): implement
        throw UnimplementedError();
      case MixinElement():
        final augmented = element.augmented;
        switch (augmented) {
          case null:
            return const {};
          default:
            return [
              ...augmented.superclassConstraints.map((e) => e.element),
              ...augmented.interfaces.map((e) => e.element),
            ].whereNotNull().toSet();
        }
      case InterfaceElement():
        final augmented = element.augmented;
        switch (augmented) {
          case null:
            return const {};
          default:
            return [
              element.supertype?.element,
              ...augmented.mixins.map((e) => e.element),
              ...augmented.interfaces.map((e) => e.element),
            ].whereNotNull().toSet();
        }
      default:
        return null;
    }
  }

  _MacroApplication? _nextForDeclarationsPhase({
    required LibraryElementImpl library,
  }) {
    for (final application in _applications.reversed) {
      if (!application.hasDeclarationsPhase) {
        continue;
      }
      if (application.libraryElement != library) {
        continue;
      }
      if (!_hasInterfaceDependenciesSatisfied(application)) {
        continue;
      }
      // The application has no dependencies to run.
      application.removeDeclarationsPhase();
      return application;
    }

    return null;
  }

  _MacroApplication? _nextForDefinitionsPhase() {
    for (final application in _applications.reversed) {
      if (application.phasesToExecute.remove(macro.Phase.definitions)) {
        return application;
      }
    }
    return null;
  }

  _MacroApplication? _nextForTypesPhase() {
    for (final application in _applications.reversed) {
      if (application.phasesToExecute.remove(macro.Phase.types)) {
        return application;
      }
    }
    return null;
  }

  static macro.Arguments _buildArguments({
    required int annotationIndex,
    required ast.ArgumentList node,
  }) {
    final positional = <macro.Argument>[];
    final named = <String, macro.Argument>{};
    for (var i = 0; i < node.arguments.length; ++i) {
      final argument = node.arguments[i];
      final evaluation = _ArgumentEvaluation(
        annotationIndex: annotationIndex,
        argumentIndex: i,
      );
      if (argument is ast.NamedExpression) {
        final value = evaluation.evaluate(argument.expression);
        named[argument.name.label.name] = value;
      } else {
        final value = evaluation.evaluate(argument);
        positional.add(value);
      }
    }
    return macro.Arguments(positional, named);
  }

  /// Run the [body], report [AnalyzerMacroDiagnostic]s to [onDiagnostic].
  static Future<T?> _runWithCatchingExceptions<T>(
    Future<T> Function() body, {
    required MacroTargetElement targetElement,
    required int annotationIndex,
  }) async {
    try {
      return await body();
    } on AnalyzerMacroDiagnostic catch (e) {
      targetElement.addMacroDiagnostic(e);
    } on macro.RemoteException catch (e) {
      targetElement.addMacroDiagnostic(
        ExceptionMacroDiagnostic(
          annotationIndex: annotationIndex,
          message: e.error,
          stackTrace: e.stackTrace ?? '<null>',
        ),
      );
    } catch (e, stackTrace) {
      targetElement.addMacroDiagnostic(
        ExceptionMacroDiagnostic(
          annotationIndex: annotationIndex,
          message: '$e',
          stackTrace: '$stackTrace',
        ),
      );
    }
    return null;
  }
}

class _AnnotationMacro {
  final LibraryElementImpl macroLibrary;
  final BundleMacroExecutor bundleExecutor;
  final ClassElementImpl macroClass;
  final String? constructorName;
  final ast.ArgumentList arguments;

  _AnnotationMacro({
    required this.macroLibrary,
    required this.bundleExecutor,
    required this.macroClass,
    required this.constructorName,
    required this.arguments,
  });
}

/// Helper class for evaluating arguments for a single constructor based
/// macro application.
class _ArgumentEvaluation {
  final int annotationIndex;
  final int argumentIndex;

  _ArgumentEvaluation({
    required this.annotationIndex,
    required this.argumentIndex,
  });

  macro.Argument evaluate(ast.Expression node) {
    if (node is ast.AdjacentStrings) {
      return macro.StringArgument(
          node.strings.map(evaluate).map((arg) => arg.value).join(''));
    } else if (node is ast.BooleanLiteral) {
      return macro.BoolArgument(node.value);
    } else if (node is ast.DoubleLiteral) {
      return macro.DoubleArgument(node.value);
    } else if (node is ast.IntegerLiteral) {
      return macro.IntArgument(node.value!);
    } else if (node is ast.ListLiteral) {
      final typeArguments = _typeArgumentsForNode(node);
      return macro.ListArgument(
          node.elements.cast<ast.Expression>().map(evaluate).toList(),
          typeArguments);
    } else if (node is ast.NullLiteral) {
      return macro.NullArgument();
    } else if (node is ast.PrefixExpression &&
        node.operator.type == TokenType.MINUS) {
      final operandValue = evaluate(node.operand);
      if (operandValue is macro.DoubleArgument) {
        return macro.DoubleArgument(-operandValue.value);
      } else if (operandValue is macro.IntArgument) {
        return macro.IntArgument(-operandValue.value);
      }
    } else if (node is ast.SetOrMapLiteral) {
      return _setOrMapLiteral(node);
    } else if (node is ast.SimpleStringLiteral) {
      return macro.StringArgument(node.value);
    }
    _throwError(node, 'Not supported: ${node.runtimeType}');
  }

  macro.Argument _setOrMapLiteral(ast.SetOrMapLiteral node) {
    final typeArguments = _typeArgumentsForNode(node);

    if (node.elements.every((e) => e is ast.Expression)) {
      final result = <macro.Argument>[];
      for (final element in node.elements) {
        if (element is! ast.Expression) {
          _throwError(element, 'Expression expected');
        }
        final value = evaluate(element);
        result.add(value);
      }
      return macro.SetArgument(result, typeArguments);
    }

    final result = <macro.Argument, macro.Argument>{};
    for (final element in node.elements) {
      if (element is! ast.MapLiteralEntry) {
        _throwError(element, 'MapLiteralEntry expected');
      }
      final key = evaluate(element.key);
      final value = evaluate(element.value);
      result[key] = value;
    }
    return macro.MapArgument(result, typeArguments);
  }

  Never _throwError(ast.AstNode node, String message) {
    throw ArgumentMacroDiagnostic(
      annotationIndex: annotationIndex,
      argumentIndex: argumentIndex,
      message: message,
    );
  }
}

class _DeclarationPhaseIntrospector extends _TypePhaseIntrospector
    implements macro.DeclarationPhaseIntrospector {
  final TypeSystemImpl typeSystem;

  _DeclarationPhaseIntrospector(
    super.elementFactory,
    super.declarationBuilder,
    this.typeSystem,
  );

  @override
  Future<List<macro.ConstructorDeclaration>> constructorsOf(
    covariant macro.TypeDeclaration type,
  ) async {
    final element = (type as HasElement).element;
    if (element case InterfaceElement(:final augmented?)) {
      return augmented.constructors
          .map((e) => e.declaration as ConstructorElementImpl)
          .map(declarationBuilder.fromElement.constructorElement)
          .toList();
    }
    return [];
  }

  @override
  Future<List<macro.FieldDeclaration>> fieldsOf(
    macro.TypeDeclaration type,
  ) async {
    final element = (type as HasElement).element;
    if (element case InstanceElement(:final augmented?)) {
      return augmented.fields
          .whereNot((e) => e.isSynthetic)
          .map((e) => e.declaration as FieldElementImpl)
          .map(declarationBuilder.fromElement.fieldElement)
          .toList();
    }
    // TODO(scheglov): can we test this?
    throw StateError('Unexpected: ${type.runtimeType}');
  }

  @override
  Future<List<macro.MethodDeclaration>> methodsOf(
    macro.TypeDeclaration type,
  ) async {
    final element = (type as HasElement).element;
    if (element case InstanceElement(:final augmented?)) {
      return [
        ...augmented.accessors.whereNot((e) => e.isSynthetic),
        ...augmented.methods,
      ]
          .map((e) => e.declaration as ExecutableElementImpl)
          .map(declarationBuilder.fromElement.methodElement)
          .toList();
    }
    // TODO(scheglov): can we test this?
    throw StateError('Unexpected: ${type.runtimeType}');
  }

  @override
  Future<macro.StaticType> resolve(macro.TypeAnnotationCode type) async {
    var dartType = _resolve(type);
    return _StaticTypeImpl(typeSystem, dartType);
  }

  @override
  Future<macro.TypeDeclaration> typeDeclarationOf(
    macro.Identifier identifier,
  ) async {
    return declarationBuilder.typeDeclarationOf(identifier);
  }

  @override
  Future<List<macro.TypeDeclaration>> typesOf(covariant macro.Library library) {
    // TODO(jakemac): implement typesOf
    throw UnimplementedError();
  }

  @override
  Future<List<macro.EnumValueDeclaration>> valuesOf(
      covariant macro.EnumDeclaration type) {
    // TODO(jakemac): implement valuesOf
    throw UnimplementedError();
  }

  DartType _resolve(macro.TypeAnnotationCode type) {
    // TODO(scheglov): write tests
    if (type is macro.NamedTypeAnnotationCode) {
      final identifier = type.name as IdentifierImpl;
      final element = identifier.element;
      if (element is ClassElementImpl) {
        return element.instantiate(
          typeArguments: type.typeArguments.map(_resolve).toList(),
          nullabilitySuffix: type.isNullable
              ? NullabilitySuffix.question
              : NullabilitySuffix.none,
        );
      } else {
        // TODO(scheglov): Implement other elements.
        throw UnimplementedError('(${element.runtimeType}) $element');
      }
    } else {
      // TODO(scheglov): Implement other types.
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }
}

class _DefinitionPhaseIntrospector extends _DeclarationPhaseIntrospector
    implements macro.DefinitionPhaseIntrospector {
  _DefinitionPhaseIntrospector(
    super.elementFactory,
    super.declarationBuilder,
    super.typeSystem,
  );

  @override
  Future<macro.Declaration> declarationOf(
    covariant macro.Identifier identifier,
  ) {
    // TODO(scheglov): implement declarationOf
    throw UnimplementedError();
  }

  @override
  Future<macro.TypeAnnotation> inferType(
    covariant macro.OmittedTypeAnnotation omittedType,
  ) {
    // TODO(scheglov): implement inferType
    throw UnimplementedError();
  }

  @override
  Future<List<macro.Declaration>> topLevelDeclarationsOf(
    covariant macro.Library library,
  ) {
    // TODO(scheglov): implement topLevelDeclarationsOf
    throw UnimplementedError();
  }

  @override
  Future<macro.TypeDeclaration> typeDeclarationOf(
    macro.Identifier identifier,
  ) async {
    return await super.typeDeclarationOf(identifier);
  }
}

class _MacroApplication {
  final LibraryElementImpl libraryElement;
  final InstanceElement? declarationsPhaseElement;
  final ast.AstNode targetNode;
  final MacroTargetElement targetElement;
  final int annotationIndex;
  final ast.Annotation annotationNode;
  final macro.MacroInstanceIdentifier instance;
  final Set<macro.Phase> phasesToExecute;

  _MacroApplication({
    required this.libraryElement,
    required this.declarationsPhaseElement,
    required this.targetNode,
    required this.targetElement,
    required this.annotationIndex,
    required this.annotationNode,
    required this.instance,
    required this.phasesToExecute,
  });

  bool get hasDeclarationsPhase {
    return phasesToExecute.contains(macro.Phase.declarations);
  }

  void removeDeclarationsPhase() {
    phasesToExecute.remove(macro.Phase.declarations);
  }
}

class _StaticTypeImpl implements macro.StaticType {
  final TypeSystemImpl typeSystem;
  final DartType type;

  _StaticTypeImpl(this.typeSystem, this.type);

  @override
  Future<bool> isExactly(_StaticTypeImpl other) {
    // TODO(scheglov): implement isExactly
    throw UnimplementedError();
  }

  @override
  Future<bool> isSubtypeOf(_StaticTypeImpl other) {
    // TODO(scheglov): write tests
    return Future.value(
      typeSystem.isSubtypeOf(type, other.type),
    );
  }
}

class _TypePhaseIntrospector implements macro.TypePhaseIntrospector {
  final LinkedElementFactory elementFactory;
  final DeclarationBuilder declarationBuilder;

  _TypePhaseIntrospector(
    this.elementFactory,
    this.declarationBuilder,
  );

  @override
  Future<macro.Identifier> resolveIdentifier(Uri library, String name) async {
    final libraryElement = elementFactory.libraryOfUri2(library);
    final element = libraryElement.scope.lookup(name).getter!;
    return declarationBuilder.fromElement.identifier(element);
  }
}

extension on macro.MacroExecutionResult {
  bool get isNotEmpty =>
      enumValueAugmentations.isNotEmpty ||
      interfaceAugmentations.isNotEmpty ||
      libraryAugmentations.isNotEmpty ||
      mixinAugmentations.isNotEmpty ||
      typeAugmentations.isNotEmpty;
}
