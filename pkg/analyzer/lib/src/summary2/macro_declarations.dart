// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart'
    as macro;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:collection/collection.dart';

class ClassDeclarationImpl extends macro.ClassDeclarationImpl
    implements HasElement {
  @override
  final ClassElementImpl element;

  ClassDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.typeParameters,
    required super.interfaces,
    required super.hasAbstract,
    required super.hasBase,
    required super.hasFinal,
    required super.hasExternal,
    required super.hasInterface,
    required super.hasMixin,
    required super.hasSealed,
    required super.mixins,
    required super.superclass,
    required this.element,
  });
}

class ConstructorDeclarationImpl extends macro.ConstructorDeclarationImpl
    implements HasElement {
  @override
  final ConstructorElementImpl element;

  ConstructorDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.hasBody,
    required super.hasExternal,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    required super.definingType,
    required super.isFactory,
    required this.element,
  });
}

class DeclarationBuilder {
  final ast.AstNode? Function(Element?) nodeOfElement;

  final Map<Element, IdentifierImpl> _identifierMap = Map.identity();

  late final DeclarationBuilderFromNode fromNode =
      DeclarationBuilderFromNode(this);

  late final DeclarationBuilderFromElement fromElement =
      DeclarationBuilderFromElement(this);

  DeclarationBuilder({
    required this.nodeOfElement,
  });

  macro.Declaration buildDeclaration(ast.AstNode node) {
    switch (node) {
      case ast.ClassDeclarationImpl():
        return fromNode.classDeclaration(node);
      case ast.ConstructorDeclarationImpl():
        return fromNode.constructorDeclaration(node);
      case ast.ExtensionDeclarationImpl():
        return fromNode.extensionDeclaration(node);
      case ast.ExtensionTypeDeclarationImpl():
        return fromNode.extensionTypeDeclaration(node);
      case ast.FunctionDeclarationImpl():
        return fromNode.functionDeclaration(node);
      case ast.MethodDeclarationImpl():
        return fromNode.methodDeclaration(node);
      case ast.MixinDeclarationImpl():
        return fromNode.mixinDeclaration(node);
      case ast.VariableDeclaration():
        return fromNode.variableDeclaration(node);
    }
    // TODO(scheglov): incomplete
    throw UnimplementedError('${node.runtimeType}');
  }

  macro.TypeAnnotation inferOmittedType(
    macro.OmittedTypeAnnotation omittedType,
  ) {
    switch (omittedType) {
      case _OmittedTypeAnnotationDynamic():
        final type = DynamicTypeImpl.instance;
        return fromElement._dartType(type);
      case _OmittedTypeAnnotationMethodReturnType():
        final type = omittedType.element.returnType;
        return fromElement._dartType(type);
      case _OmittedTypeAnnotationVariable():
        final type = omittedType.element.type;
        return fromElement._dartType(type);
      default:
        throw UnimplementedError('${omittedType.runtimeType}');
    }
  }

  macro.ResolvedIdentifier resolveIdentifier(macro.Identifier identifier) {
    if (identifier is _VoidIdentifierImpl) {
      return macro.ResolvedIdentifier(
        kind: macro.IdentifierKind.topLevelMember,
        name: 'void',
        uri: null,
        staticScope: null,
      );
    }

    identifier as IdentifierImpl;
    final element = identifier.element;
    switch (element) {
      case DynamicElementImpl():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.topLevelMember,
          name: 'dynamic',
          uri: Uri.parse('dart:core'),
          staticScope: null,
        );
      case FieldElement():
        if (element.isStatic) {
          return macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.staticInstanceMember,
            name: element.name,
            uri: element.source!.uri,
            staticScope: element.enclosingElement.name,
          );
        } else {
          return macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.instanceMember,
            name: element.name,
            uri: null,
            staticScope: null,
          );
        }
      case FunctionElement():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.topLevelMember,
          name: element.name,
          uri: element.source.uri,
          staticScope: null,
        );
      case InterfaceElement():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.topLevelMember,
          name: element.name,
          uri: element.source.uri,
          staticScope: null,
        );
      default:
        // TODO(scheglov): other elements
        throw UnimplementedError('${element.runtimeType}');
    }
  }

  DartType resolveType(macro.TypeAnnotationCode typeCode) {
    switch (typeCode) {
      case macro.NullableTypeAnnotationCode():
        final type = resolveType(typeCode.underlyingType);
        type as TypeImpl;
        return type.withNullability(NullabilitySuffix.question);
      case macro.FunctionTypeAnnotationCode():
        return _resolveTypeCodeFunction(typeCode);
      case macro.NamedTypeAnnotationCode():
        return _resolveTypeCodeNamed(typeCode);
      case macro.OmittedTypeAnnotationCode():
        // TODO(scheglov): implement
        throw UnimplementedError('(${typeCode.runtimeType}) $typeCode');
      case macro.RawTypeAnnotationCode():
        // TODO(scheglov): implement
        throw UnimplementedError('(${typeCode.runtimeType}) $typeCode');
      case macro.RecordTypeAnnotationCode():
        // TODO(scheglov): implement
        throw UnimplementedError('(${typeCode.runtimeType}) $typeCode');
    }
  }

  /// See [macro.DeclarationPhaseIntrospector.typeDeclarationOf].
  macro.TypeDeclarationImpl typeDeclarationOf(macro.Identifier identifier) {
    if (identifier is! IdentifierImpl) {
      throw ArgumentError('Not analyzer identifier.');
    }

    final element = identifier.element;
    if (element == null) {
      throw ArgumentError('Identifier without element.');
    }

    final node = nodeOfElement(element);
    if (node != null) {
      return fromNode.typeDeclarationOf(node);
    } else {
      return fromElement.typeDeclarationOf(element);
    }
  }

  List<macro.MetadataAnnotationImpl> _buildMetadata(Element element) {
    return element.withAugmentations
        .expand((current) => current.metadata)
        .map(_buildMetadataElement)
        .whereNotNull()
        .toList();
  }

  macro.MetadataAnnotationImpl? _buildMetadataElement(
    ElementAnnotation annotation,
  ) {
    annotation as ElementAnnotationImpl;
    final node = annotation.annotationAst;

    final importPrefixNames = annotation.library.libraryImports
        .map((e) => e.prefix?.element.name)
        .whereNotNull()
        .toSet();

    final identifiers = <ast.SimpleIdentifier>[];

    switch (node.name) {
      case ast.PrefixedIdentifier node:
        identifiers.add(node.prefix);
        identifiers.add(node.identifier);
      case ast.SimpleIdentifier node:
        identifiers.add(node);
      default:
        return null;
    }

    identifiers.addIfNotNull(node.constructorName);

    var nextIndex = 0;
    if (importPrefixNames.contains(identifiers.first.name)) {
      nextIndex++;
    }

    final identifierName = identifiers[nextIndex++];
    final constructorName = identifiers.elementAtOrNull(nextIndex);

    final identifierMacro = IdentifierImplFromNode(
      id: macro.RemoteInstance.uniqueId,
      name: identifierName.name,
      getElement: () => identifierName.staticElement,
    );

    final argumentList = node.arguments;
    if (argumentList != null) {
      final arguments = argumentList.arguments;
      return macro.ConstructorMetadataAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        constructor: IdentifierImplFromNode(
          id: macro.RemoteInstance.uniqueId,
          name: constructorName?.name ?? '',
          getElement: () => node.element,
        ),
        type: identifierMacro,
        positionalArguments: arguments
            .whereNotType<ast.NamedExpression>()
            .map((e) => _expressionCode(e))
            .toList(),
        namedArguments: arguments.whereType<ast.NamedExpression>().map((e) {
          return MapEntry(
            e.name.label.name,
            _expressionCode(e.expression),
          );
        }).mapFromEntries,
      );
    } else {
      return macro.IdentifierMetadataAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: identifierMacro,
      );
    }
  }

  FunctionTypeImpl _resolveTypeCodeFunction(
    macro.FunctionTypeAnnotationCode typeCode,
  ) {
    ParameterElementImpl buildFormalParameter(
      macro.ParameterCode e,
      ParameterKind Function(macro.ParameterCode) getKind,
    ) {
      final element = ParameterElementImpl(
        name: e.name,
        nameOffset: -1,
        parameterKind: getKind(e),
      );
      element.type = switch (e.type) {
        final type? => resolveType(type),
        _ => DynamicTypeImpl.instance,
      };
      return element;
    }

    return FunctionTypeImpl(
      typeFormals: typeCode.typeParameters
          .map((e) => TypeParameterElementImpl(e.name, -1))
          .toList(),
      parameters: [
        ...typeCode.positionalParameters.map((e) {
          return buildFormalParameter(e, (e) {
            // TODO(scheglov): this code does not actually work.
            return e.keywords.contains('required')
                ? ParameterKind.REQUIRED
                : ParameterKind.POSITIONAL;
          });
        }),
        ...typeCode.namedParameters.map((e) {
          return buildFormalParameter(e, (e) {
            return e.keywords.contains('required')
                ? ParameterKind.NAMED_REQUIRED
                : ParameterKind.NAMED;
          });
        }),
      ],
      returnType: switch (typeCode.returnType) {
        final returnType? => resolveType(returnType),
        _ => DynamicTypeImpl.instance,
      },
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  DartType _resolveTypeCodeNamed(macro.NamedTypeAnnotationCode typeCode) {
    final identifier = typeCode.name as IdentifierImpl;
    if (identifier is _VoidIdentifierImpl) {
      return VoidTypeImpl.instance;
    }

    final element = identifier.element;
    switch (element) {
      case DynamicElementImpl():
        return DynamicTypeImpl.instance;
      case InterfaceElementImpl():
        return element.instantiate(
          typeArguments: typeCode.typeArguments.map(resolveType).toList(),
          nullabilitySuffix: NullabilitySuffix.none,
        );
      case TypeParameterElementImpl():
        return element.instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        );
      default:
        throw UnimplementedError('(${element.runtimeType}) $element');
    }
  }

  static macro.ExpressionCode _expressionCode(ast.Expression node) {
    return macro.ExpressionCode.fromString('$node');
  }
}

class DeclarationBuilderFromElement {
  final DeclarationBuilder declarationBuilder;

  final Map<Element, LibraryImpl> _libraryMap = Map.identity();

  final Map<ClassElement, ClassDeclarationImpl> _classMap = Map.identity();

  final Map<MixinElement, MixinDeclarationImpl> _mixinMap = Map.identity();

  final Map<ConstructorElement, ConstructorDeclarationImpl> _constructorMap =
      Map.identity();

  final Map<FieldElement, FieldDeclarationImpl> _fieldMap = Map.identity();

  final Map<ExecutableElement, MethodDeclarationImpl> _methodMap =
      Map.identity();

  final Map<TypeParameterElement, macro.TypeParameterDeclarationImpl>
      _typeParameterMap = Map.identity();

  DeclarationBuilderFromElement(this.declarationBuilder);

  macro.ClassDeclarationImpl classElement(
    ClassElementImpl element,
  ) {
    return _classMap[element] ??= _classElement(element);
  }

  ConstructorDeclarationImpl constructorElement(
    ConstructorElementImpl element,
  ) {
    return _constructorMap[element] ??= _constructorElement(element);
  }

  macro.FieldDeclarationImpl fieldElement(FieldElementImpl element) {
    return _fieldMap[element] ??= _fieldElement(element);
  }

  macro.IdentifierImpl identifier(Element element) {
    final name = switch (element) {
      PropertyAccessorElement(isSetter: true) => element.displayName,
      _ => element.name!,
    };

    final map = declarationBuilder._identifierMap;
    return map[element] ??= IdentifierImplFromElement(
      id: macro.RemoteInstance.uniqueId,
      name: name,
      element: element,
    );
  }

  macro.LibraryImpl library(Element element) {
    var library = _libraryMap[element.library];
    if (library == null) {
      final version = element.library!.languageVersion.effective;
      library = LibraryImplFromElement(
          id: macro.RemoteInstance.uniqueId,
          languageVersion:
              macro.LanguageVersionImpl(version.major, version.minor),
          metadata: _buildMetadata(element),
          uri: element.library!.source.uri,
          element: element);
      _libraryMap[element.library!] = library;
    }
    return library;
  }

  MethodDeclarationImpl methodElement(ExecutableElementImpl element) {
    return _methodMap[element] ??= _methodElement(element);
  }

  macro.MixinDeclarationImpl mixinElement(
    MixinElementImpl element,
  ) {
    return _mixinMap[element] ??= _mixinElement(element);
  }

  /// See [macro.DeclarationPhaseIntrospector.typeDeclarationOf].
  macro.TypeDeclarationImpl typeDeclarationOf(Element element) {
    if (element is ClassElementImpl) {
      return classElement(element);
    } else if (element is MixinElementImpl) {
      return mixinElement(element);
    } else {
      throw ArgumentError('element: $element');
    }
  }

  macro.TypeParameterDeclarationImpl typeParameter(
    TypeParameterElement element,
  ) {
    return _typeParameterMap[element] ??= _typeParameter(element);
  }

  List<macro.MetadataAnnotationImpl> _buildMetadata(Element element) {
    return declarationBuilder._buildMetadata(element);
  }

  ClassDeclarationImpl _classElement(
    ClassElementImpl element,
  ) {
    return ClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: element.typeParameters.map(_typeParameter).toList(),
      interfaces: element.interfaces.map(_interfaceType).toList(),
      hasAbstract: element.isAbstract,
      hasBase: element.isBase,
      hasExternal: false,
      hasFinal: element.isFinal,
      hasInterface: element.isInterface,
      hasMixin: element.isMixinClass,
      hasSealed: element.isSealed,
      mixins: element.mixins.map(_interfaceType).toList(),
      superclass: element.supertype.mapOrNull(_interfaceType),
      element: element,
    );
  }

  ConstructorDeclarationImpl _constructorElement(
    ConstructorElementImpl element,
  ) {
    final enclosing = element.enclosingInstanceElement;
    return ConstructorDeclarationImpl._(
      element: element,
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: !element.isAbstract,
      hasExternal: element.isExternal,
      isFactory: element.isFactory,
      namedParameters: _namedFormalParameters(element.parameters),
      positionalParameters: _positionalFormalParameters(element.parameters),
      returnType: _dartType(element.returnType),
      typeParameters: element.typeParameters.map(_typeParameter).toList(),
      definingType: identifier(enclosing),
    );
  }

  macro.TypeAnnotationImpl _dartType(DartType type) {
    switch (type) {
      case DynamicType():
        return macro.NamedTypeAnnotationImpl(
          id: macro.RemoteInstance.uniqueId,
          isNullable: false,
          identifier: identifier(DynamicElementImpl.instance),
          typeArguments: const [],
        );
      case InterfaceType():
        return _interfaceType(type);
      case TypeParameterType():
        return macro.NamedTypeAnnotationImpl(
          id: macro.RemoteInstance.uniqueId,
          isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
          identifier: identifier(type.element),
          typeArguments: const [],
        );
      case VoidType():
        return macro.NamedTypeAnnotationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: _VoidIdentifierImpl(),
          isNullable: false,
          typeArguments: const [],
        );
      default:
        // TODO(scheglov): implement other types
        throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }

  FieldDeclarationImpl _fieldElement(FieldElementImpl element) {
    final enclosing = element.enclosingInstanceElement;
    return FieldDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasAbstract: element.isAbstract,
      hasExternal: element.isExternal,
      hasFinal: element.isFinal,
      hasLate: element.isLate,
      type: _dartType(element.type),
      definingType: identifier(enclosing),
      isStatic: element.isStatic,
      element: element,
    );
  }

  macro.ParameterDeclarationImpl _formalParameter(ParameterElement element) {
    return macro.ParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      isNamed: element.isNamed,
      isRequired: element.isRequired,
      library: library(element),
      metadata: _buildMetadata(element),
      type: _dartType(element.type),
    );
  }

  macro.NamedTypeAnnotationImpl _interfaceType(InterfaceType type) {
    return macro.NamedTypeAnnotationImpl(
      id: macro.RemoteInstance.uniqueId,
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      identifier: identifier(type.element),
      typeArguments: type.typeArguments.map(_dartType).toList(),
    );
  }

  MethodDeclarationImpl _methodElement(ExecutableElementImpl element) {
    final enclosing = element.enclosingInstanceElement;
    return MethodDeclarationImpl._(
      element: element,
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: !element.isAbstract,
      hasExternal: element.isExternal,
      isGetter: element is PropertyAccessorElementImpl && element.isGetter,
      isOperator: element.isOperator,
      isSetter: element is PropertyAccessorElementImpl && element.isSetter,
      isStatic: element.isStatic,
      namedParameters: _namedFormalParameters(element.parameters),
      positionalParameters: _positionalFormalParameters(element.parameters),
      returnType: _dartType(element.returnType),
      typeParameters: element.typeParameters.map(_typeParameter).toList(),
      definingType: identifier(enclosing),
    );
  }

  MixinDeclarationImpl _mixinElement(
    MixinElementImpl element,
  ) {
    return MixinDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: element.typeParameters.map(_typeParameter).toList(),
      hasBase: element.isBase,
      interfaces: element.interfaces.map(_interfaceType).toList(),
      superclassConstraints:
          element.superclassConstraints.map(_interfaceType).toList(),
      element: element,
    );
  }

  List<macro.ParameterDeclarationImpl> _namedFormalParameters(
    List<ParameterElement> elements,
  ) {
    return elements
        .where((element) => element.isNamed)
        .map(_formalParameter)
        .toList();
  }

  List<macro.ParameterDeclarationImpl> _positionalFormalParameters(
    List<ParameterElement> elements,
  ) {
    return elements
        .where((element) => element.isPositional)
        .map(_formalParameter)
        .toList();
  }

  macro.TypeParameterDeclarationImpl _typeParameter(
    TypeParameterElement element,
  ) {
    return macro.TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      bound: element.bound.mapOrNull(_dartType),
    );
  }
}

class DeclarationBuilderFromNode {
  final DeclarationBuilder declarationBuilder;

  final Map<ast.NamedType, IdentifierImpl> _namedTypeMap = Map.identity();

  final Map<Element, LibraryImpl> _libraryMap = Map.identity();

  DeclarationBuilderFromNode(this.declarationBuilder);

  ClassDeclarationImpl classDeclaration(
    ast.ClassDeclarationImpl node,
  ) {
    final element = node.declaredElement!;

    final interfaceNodes = <ast.NamedType>[];
    final mixinNodes = <ast.NamedType>[];
    for (var current = node;;) {
      if (current.implementsClause case final clause?) {
        interfaceNodes.addAll(clause.interfaces);
      }
      if (current.withClause case final clause?) {
        mixinNodes.addAll(clause.mixinTypes);
      }
      final nextElement = current.declaredElement?.augmentation;
      final nextNode = declarationBuilder.nodeOfElement(nextElement);
      if (nextNode is! ast.ClassDeclarationImpl) {
        break;
      }
      current = nextNode;
    }

    return ClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(node.typeParameters),
      interfaces: _namedTypes(interfaceNodes),
      hasAbstract: node.abstractKeyword != null,
      hasBase: node.baseKeyword != null,
      hasExternal: false,
      hasFinal: node.finalKeyword != null,
      hasInterface: node.interfaceKeyword != null,
      hasMixin: node.mixinKeyword != null,
      hasSealed: node.sealedKeyword != null,
      mixins: _namedTypes(mixinNodes),
      superclass: node.extendsClause?.superclass.mapOrNull(_namedType),
      element: element,
    );
  }

  macro.ConstructorDeclarationImpl constructorDeclaration(
    ast.ConstructorDeclarationImpl node,
  ) {
    final definingType = _definingType(node);
    final element = node.declaredElement!;

    return ConstructorDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      definingType: definingType,
      element: element,
      identifier: _declaredIdentifier2(node.name?.lexeme ?? '', element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: node.body is! ast.EmptyFunctionBody,
      hasExternal: node.externalKeyword != null,
      isFactory: node.factoryKeyword != null,
      namedParameters: _namedFormalParameters(node.parameters),
      positionalParameters: _positionalFormalParameters(node.parameters),
      returnType: macro.NamedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: definingType,
        typeArguments: const [],
        isNullable: false,
      ),
      typeParameters: const [],
    );
  }

  ExtensionDeclarationImpl extensionDeclaration(
    ast.ExtensionDeclarationImpl node,
  ) {
    final element = node.declaredElement!;

    return ExtensionDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier2(node.name?.lexeme ?? '', element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(node.typeParameters),
      onType: _typeAnnotation(node.extendedType),
      element: element,
    );
  }

  ExtensionTypeDeclarationImpl extensionTypeDeclaration(
    ast.ExtensionTypeDeclarationImpl node,
  ) {
    final element = node.declaredElement!;

    return ExtensionTypeDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier2(node.name.lexeme, element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(node.typeParameters),
      representationType: _typeAnnotation(node.representation.fieldType),
      element: element,
    );
  }

  macro.FunctionDeclarationImpl functionDeclaration(
    ast.FunctionDeclarationImpl node,
  ) {
    final element = node.declaredElement!;
    final function = node.functionExpression;

    return FunctionDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      element: element,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: function.body is! ast.EmptyFunctionBody,
      hasExternal: node.externalKeyword != null,
      isGetter: node.isGetter,
      isOperator: false,
      isSetter: node.isSetter,
      namedParameters: _namedFormalParameters(function.parameters),
      positionalParameters: _positionalFormalParameters(function.parameters),
      returnType: _typeAnnotationOrDynamic(node.returnType),
      typeParameters: _typeParameters(function.typeParameters),
    );
  }

  macro.LibraryImpl library(Element element) {
    final library = element.library!;

    if (_libraryMap[library] case final result?) {
      return result;
    }

    final version = library.languageVersion.effective;
    final uri = library.source.uri;

    return _libraryMap[library] = LibraryImplFromElement(
      id: macro.RemoteInstance.uniqueId,
      languageVersion: macro.LanguageVersionImpl(
        version.major,
        version.minor,
      ),
      metadata: _buildMetadata(element),
      uri: uri,
      element: library,
    );
  }

  macro.MethodDeclarationImpl methodDeclaration(
    ast.MethodDeclarationImpl node,
  ) {
    return _methodDeclaration(node);
  }

  MixinDeclarationImpl mixinDeclaration(
    ast.MixinDeclarationImpl node,
  ) {
    final element = node.declaredElement!;

    final onNodes = <ast.NamedType>[];
    final interfaceNodes = <ast.NamedType>[];
    for (var current = node;;) {
      if (current.onClause case final clause?) {
        onNodes.addAll(clause.superclassConstraints);
      }
      if (current.implementsClause case final clause?) {
        interfaceNodes.addAll(clause.interfaces);
      }
      final nextElement = current.declaredElement?.augmentation;
      final nextNode = declarationBuilder.nodeOfElement(nextElement);
      if (nextNode is! ast.MixinDeclarationImpl) {
        break;
      }
      current = nextNode;
    }

    return MixinDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(node.typeParameters),
      hasBase: node.baseKeyword != null,
      interfaces: _namedTypes(interfaceNodes),
      superclassConstraints: _namedTypes(onNodes),
      element: element,
    );
  }

  /// See [macro.DeclarationPhaseIntrospector.typeDeclarationOf].
  macro.TypeDeclarationImpl typeDeclarationOf(ast.AstNode node) {
    switch (node) {
      case ast.ClassDeclarationImpl():
        return classDeclaration(node);
      case ast.MixinDeclarationImpl():
        return mixinDeclaration(node);
      default:
        throw ArgumentError('node: $node');
    }
  }

  macro.VariableDeclarationImpl variableDeclaration(
    ast.VariableDeclaration node,
  ) {
    final variableList = node.parent as ast.VariableDeclarationList;
    final variablesDeclaration = variableList.parent;
    switch (variablesDeclaration) {
      case ast.FieldDeclarationImpl():
        final element = node.declaredElement as FieldElementImpl;
        return FieldDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: _declaredIdentifier(node.name, element),
          library: library(element),
          metadata: _buildMetadata(element),
          hasAbstract: variablesDeclaration.abstractKeyword != null,
          hasExternal: variablesDeclaration.externalKeyword != null,
          hasFinal: element.isFinal,
          hasLate: element.isLate,
          type: _typeAnnotationVariable(variableList.type, element),
          definingType: _definingType(variablesDeclaration),
          isStatic: element.isStatic,
          element: element,
        );
      default:
        // TODO(scheglov): top-level variables
        throw UnimplementedError();
    }
  }

  List<macro.MetadataAnnotationImpl> _buildMetadata(Element element) {
    return declarationBuilder._buildMetadata(element);
  }

  macro.IdentifierImpl _declaredIdentifier(Token name, Element element) {
    final map = declarationBuilder._identifierMap;
    return map[element] ??= _DeclaredIdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: name.lexeme,
      element: element,
    );
  }

  macro.IdentifierImpl _declaredIdentifier2(String name, Element element) {
    final map = declarationBuilder._identifierMap;
    return map[element] ??= _DeclaredIdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: name,
      element: element,
    );
  }

  macro.IdentifierImpl _definingType(ast.AstNode node) {
    final parentNode = node.parent;
    switch (parentNode) {
      case ast.ClassDeclaration():
        final parentElement = parentNode.declaredElement!;
        final typeElement = parentElement.augmentationTarget ?? parentElement;
        return _declaredIdentifier(parentNode.name, typeElement);
      case ast.ExtensionDeclaration():
        final parentElement = parentNode.declaredElement!;
        final typeElement = parentElement.augmentationTarget ?? parentElement;
        return _declaredIdentifier2(parentNode.name?.lexeme ?? '', typeElement);
      case ast.ExtensionTypeDeclaration():
        final parentElement = parentNode.declaredElement!;
        final typeElement = parentElement.augmentationTarget ?? parentElement;
        return _declaredIdentifier(parentNode.name, typeElement);
      case ast.MixinDeclaration():
        final parentElement = parentNode.declaredElement!;
        final typeElement = parentElement.augmentationTarget ?? parentElement;
        return _declaredIdentifier(parentNode.name, typeElement);
      default:
        // TODO(scheglov): other parents
        throw UnimplementedError('(${parentNode.runtimeType}) $parentNode');
    }
  }

  macro.ParameterDeclarationImpl _formalParameter(ast.FormalParameter node) {
    if (node is ast.DefaultFormalParameter) {
      node = node.parameter;
    }

    final element = node.declaredElement!;

    final macro.TypeAnnotationImpl typeAnnotation;
    if (node is ast.SimpleFormalParameter) {
      typeAnnotation = _typeAnnotationVariable(node.type, element);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }

    return macro.ParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name!, element),
      isNamed: node.isNamed,
      isRequired: node.isRequired,
      library: library(element),
      metadata: _buildMetadata(element),
      type: typeAnnotation,
    );
  }

  macro.FunctionTypeParameterImpl _functionTypeFormalParameter(
    ast.FormalParameter node,
  ) {
    if (node is ast.DefaultFormalParameter) {
      node = node.parameter;
    }

    final element = node.declaredElement!;

    final macro.TypeAnnotationImpl typeAnnotation;
    if (node is ast.SimpleFormalParameter) {
      typeAnnotation = _typeAnnotationOrDynamic(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }

    return macro.FunctionTypeParameterImpl(
      id: macro.RemoteInstance.uniqueId,
      isNamed: node.isNamed,
      isRequired: node.isRequired,
      metadata: _buildMetadata(element),
      name: node.name?.lexeme,
      type: typeAnnotation,
    );
  }

  MethodDeclarationImpl _methodDeclaration(
    ast.MethodDeclarationImpl node,
  ) {
    final definingType = _definingType(node);
    final element = node.declaredElement!;

    return MethodDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      definingType: definingType,
      element: element,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: node.body is! ast.EmptyFunctionBody,
      hasExternal: node.externalKeyword != null,
      isGetter: node.isGetter,
      isOperator: node.isOperator,
      isSetter: node.isSetter,
      isStatic: node.isStatic,
      namedParameters: _namedFormalParameters(node.parameters),
      positionalParameters: _positionalFormalParameters(node.parameters),
      returnType: _typeAnnotationMethodReturnType(node),
      typeParameters: _typeParameters(node.typeParameters),
    );
  }

  List<macro.ParameterDeclarationImpl> _namedFormalParameters(
    ast.FormalParameterList? node,
  ) {
    if (node != null) {
      return node.parameters
          .where((e) => e.isNamed)
          .map(_formalParameter)
          .toList();
    } else {
      return const [];
    }
  }

  macro.NamedTypeAnnotationImpl _namedType(ast.NamedType node) {
    return macro.NamedTypeAnnotationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _namedTypeIdentifier(node),
      isNullable: node.question != null,
      typeArguments: _typeAnnotations(node.typeArguments?.arguments),
    );
  }

  macro.IdentifierImpl _namedTypeIdentifier(ast.NamedType node) {
    if (node.importPrefix == null && node.name2.lexeme == 'void') {
      return _namedTypeMap[node] ??= _VoidIdentifierImpl();
    }

    return _namedTypeMap[node] ??= _NamedTypeIdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: node.name2.lexeme,
      node: node,
    );
  }

  List<macro.NamedTypeAnnotationImpl> _namedTypes(
    List<ast.NamedType>? elements,
  ) {
    if (elements != null) {
      return elements.map(_namedType).toList();
    } else {
      return const [];
    }
  }

  List<macro.ParameterDeclarationImpl> _positionalFormalParameters(
    ast.FormalParameterList? node,
  ) {
    if (node != null) {
      return node.parameters
          .where((e) => e.isPositional)
          .map(_formalParameter)
          .toList();
    } else {
      return const [];
    }
  }

  macro.TypeAnnotationImpl _typeAnnotation(ast.TypeAnnotation node) {
    switch (node) {
      case ast.GenericFunctionType():
        return macro.FunctionTypeAnnotationImpl(
          id: macro.RemoteInstance.uniqueId,
          isNullable: node.question != null,
          namedParameters: node.parameters.parameters
              .where((e) => e.isNamed)
              .map(_functionTypeFormalParameter)
              .toList(),
          positionalParameters: node.parameters.parameters
              .where((e) => e.isPositional)
              .map(_functionTypeFormalParameter)
              .toList(),
          returnType: _typeAnnotationOrDynamic(node.returnType),
          typeParameters: _typeParameters(node.typeParameters),
        );
      case ast.NamedType():
        return _namedType(node);
      default:
        throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  macro.TypeAnnotationImpl _typeAnnotationMethodReturnType(
    ast.MethodDeclaration node,
  ) {
    final returnType = node.returnType;
    if (returnType == null) {
      final element = node.declaredElement!;
      return _OmittedTypeAnnotationMethodReturnType(element);
    }
    return _typeAnnotation(returnType);
  }

  macro.TypeAnnotationImpl _typeAnnotationOrDynamic(ast.TypeAnnotation? node) {
    if (node == null) {
      return _OmittedTypeAnnotationDynamic();
    }
    return _typeAnnotation(node);
  }

  List<macro.TypeAnnotationImpl> _typeAnnotations(
    List<ast.TypeAnnotation>? elements,
  ) {
    if (elements != null) {
      return List.generate(
          elements.length, (i) => _typeAnnotation(elements[i]));
    } else {
      return const [];
    }
  }

  macro.TypeAnnotationImpl _typeAnnotationVariable(
    ast.TypeAnnotation? type,
    VariableElement element,
  ) {
    if (type == null) {
      return _OmittedTypeAnnotationVariable(element);
    }
    return _typeAnnotation(type);
  }

  macro.TypeParameterDeclarationImpl _typeParameter(
    ast.TypeParameter node,
  ) {
    final element = node.declaredElement!;
    return macro.TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      bound: node.bound.mapOrNull(_typeAnnotation),
    );
  }

  List<macro.TypeParameterDeclarationImpl> _typeParameters(
    ast.TypeParameterList? typeParameterList,
  ) {
    if (typeParameterList != null) {
      return typeParameterList.typeParameters.map(_typeParameter).toList();
    } else {
      return const [];
    }
  }
}

class ExtensionDeclarationImpl extends macro.ExtensionDeclarationImpl
    implements HasElement {
  @override
  final ExtensionElementImpl element;

  ExtensionDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.typeParameters,
    required super.onType,
    required this.element,
  });
}

class ExtensionTypeDeclarationImpl extends macro.ExtensionTypeDeclarationImpl
    implements HasElement {
  @override
  final ExtensionTypeElementImpl element;

  ExtensionTypeDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.typeParameters,
    required super.representationType,
    required this.element,
  });
}

class FieldDeclarationImpl extends macro.FieldDeclarationImpl
    implements HasElement {
  @override
  final FieldElementImpl element;

  FieldDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.hasAbstract,
    required super.hasExternal,
    required super.hasFinal,
    required super.hasLate,
    required super.type,
    required super.definingType,
    required super.isStatic,
    required this.element,
  });
}

class FunctionDeclarationImpl extends macro.FunctionDeclarationImpl
    implements HasElement {
  @override
  final ExecutableElementImpl element;

  FunctionDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.hasBody,
    required super.hasExternal,
    required super.isGetter,
    required super.isOperator,
    required super.isSetter,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    required this.element,
  });
}

/// A macro declaration that has an [Element].
abstract interface class HasElement {
  ElementImpl get element;
}

abstract class IdentifierImpl extends macro.IdentifierImpl {
  IdentifierImpl({
    required super.id,
    required super.name,
  });

  Element? get element;
}

class IdentifierImplFromElement extends IdentifierImpl {
  @override
  final Element element;

  IdentifierImplFromElement({
    required super.id,
    required super.name,
    required this.element,
  });
}

class IdentifierImplFromNode extends IdentifierImpl {
  final Element? Function() getElement;

  IdentifierImplFromNode({
    required super.id,
    required super.name,
    required this.getElement,
  });

  @override
  Element? get element => getElement();
}

abstract class LibraryImpl extends macro.LibraryImpl {
  LibraryImpl({
    required super.id,
    required super.languageVersion,
    required super.metadata,
    required super.uri,
  });

  Element? get element;
}

class LibraryImplFromElement extends LibraryImpl {
  @override
  final Element element;

  LibraryImplFromElement({
    required super.id,
    required super.languageVersion,
    required super.metadata,
    required super.uri,
    required this.element,
  });
}

class MethodDeclarationImpl extends macro.MethodDeclarationImpl
    implements HasElement {
  @override
  final ExecutableElementImpl element;

  MethodDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.hasBody,
    required super.hasExternal,
    required super.isGetter,
    required super.isOperator,
    required super.isSetter,
    required super.isStatic,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    required super.definingType,
    required this.element,
  });
}

class MixinDeclarationImpl extends macro.MixinDeclarationImpl
    implements HasElement {
  @override
  final MixinElementImpl element;

  MixinDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.typeParameters,
    required super.hasBase,
    required super.interfaces,
    required super.superclassConstraints,
    required this.element,
  });
}

class _DeclaredIdentifierImpl extends IdentifierImpl {
  @override
  final Element element;

  _DeclaredIdentifierImpl({
    required super.id,
    required super.name,
    required this.element,
  });
}

class _NamedTypeIdentifierImpl extends IdentifierImpl {
  final ast.NamedType node;

  _NamedTypeIdentifierImpl({
    required super.id,
    required super.name,
    required this.node,
  });

  @override
  Element? get element => node.element;
}

sealed class _OmittedTypeAnnotation extends macro.OmittedTypeAnnotationImpl {
  _OmittedTypeAnnotation()
      : super(
          id: macro.RemoteInstance.uniqueId,
        );
}

class _OmittedTypeAnnotationDynamic extends _OmittedTypeAnnotation {
  _OmittedTypeAnnotationDynamic();
}

class _OmittedTypeAnnotationMethodReturnType extends _OmittedTypeAnnotation {
  final ExecutableElement element;

  _OmittedTypeAnnotationMethodReturnType(this.element);
}

class _OmittedTypeAnnotationVariable extends _OmittedTypeAnnotation {
  final VariableElement element;

  _OmittedTypeAnnotationVariable(this.element);
}

class _VoidIdentifierImpl extends IdentifierImpl {
  _VoidIdentifierImpl()
      : super(
          id: macro.RemoteInstance.uniqueId,
          name: 'void',
        );

  @override
  Element? get element => null;
}

extension<T> on T? {
  R? mapOrNull<R>(R Function(T) mapper) {
    final self = this;
    return self != null ? mapper(self) : null;
  }
}

extension on Element {
  /// With the assumption that enclosing element is an [InstanceElement], and
  /// is not an invalid augmentation, return the declaration - the start of
  /// the augmentation chain.
  InstanceElement get enclosingInstanceElement {
    final enclosing = enclosingElement as InstanceElement;
    return enclosing.augmented!.declaration;
  }
}
