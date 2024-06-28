// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_library_builder;

import 'dart:convert' show jsonDecode;

import 'package:kernel/ast.dart';

import '../base/combinator.dart';
import '../base/export.dart';
import '../base/loader.dart';
import '../base/problems.dart' show internalProblem, unhandled;
import '../base/scope.dart';
import '../base/uris.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/never_type_declaration_builder.dart';
import '../codes/cfe_codes.dart'
    show
        LocatedMessage,
        Message,
        Severity,
        noLength,
        templateDuplicatedDeclaration,
        templateUnspecified;
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/utils.dart';
import 'dill_class_builder.dart' show DillClassBuilder;
import 'dill_extension_builder.dart';
import 'dill_extension_type_declaration_builder.dart';
import 'dill_loader.dart' show DillLoader;
import 'dill_member_builder.dart';
import 'dill_type_alias_builder.dart' show DillTypeAliasBuilder;

class LazyLibraryScope extends LazyScope {
  DillLibraryBuilder? libraryBuilder;

  LazyLibraryScope.top({bool isModifiable = false})
      : super(<String, Builder>{}, <String, MemberBuilder>{}, null, "top",
            isModifiable: isModifiable, kind: ScopeKind.library);

  @override
  void ensureScope() {
    if (libraryBuilder == null) {
      throw new StateError("No library builder.");
    }
    libraryBuilder!.ensureLoaded();
  }
}

class DillCompilationUnitImpl extends DillCompilationUnit {
  final DillLibraryBuilder _dillLibraryBuilder;

  DillCompilationUnitImpl(this._dillLibraryBuilder);

  @override
  void addExporter(LibraryBuilder exporter,
      List<CombinatorBuilder>? combinators, int charOffset) {
    _dillLibraryBuilder.exporters
        .add(new Export(exporter, this, combinators, charOffset));
  }

  @override
  // Coverage-ignore(suite): Not run.
  void addProblem(Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false}) {
    _dillLibraryBuilder.addProblem(message, charOffset, length, fileUri,
        wasHandled: wasHandled,
        context: context,
        severity: severity,
        problemOnLibrary: problemOnLibrary);
  }

  @override
  Iterable<Uri> get dependencies => _dillLibraryBuilder.dependencies;

  @override
  Uri get fileUri => _dillLibraryBuilder.fileUri;

  @override
  Uri get importUri => _dillLibraryBuilder.importUri;

  @override
  bool get isAugmenting => _dillLibraryBuilder.isAugmenting;

  @override
  bool get isPart => _dillLibraryBuilder.isPart;

  @override
  bool get isSynthetic => _dillLibraryBuilder.isSynthetic;

  @override
  bool get isUnsupported => _dillLibraryBuilder.isUnsupported;

  @override
  LibraryBuilder get libraryBuilder => _dillLibraryBuilder;

  @override
  Loader get loader => _dillLibraryBuilder.loader;

  @override
  NameIterator<Builder> get localMembersNameIterator =>
      _dillLibraryBuilder.localMembersNameIterator;

  @override
  Null get partOfLibrary => _dillLibraryBuilder.partOfLibrary;

  @override
  void recordAccess(
      CompilationUnit accessor, int charOffset, int length, Uri fileUri) {
    _dillLibraryBuilder.recordAccess(accessor, charOffset, length, fileUri);
  }
}

class DillLibraryBuilder extends LibraryBuilderImpl {
  @override
  final Library library;

  @override
  DillLoader loader;

  late final CompilationUnit mainCompilationUnit =
      new DillCompilationUnitImpl(this);

  /// Exports that can't be serialized.
  ///
  /// The elements of this map are documented in
  /// [../kernel/kernel_library_builder.dart].
  Map<String, String>? unserializableExports;

  // TODO(jensj): These 5 booleans could potentially be merged into a single
  // state field.
  bool isReadyToBuild = false;
  bool isReadyToFinalizeExports = false;
  bool suppressFinalizationErrors = false;
  bool isBuilt = false;
  bool isBuiltAndMarked = false;

  DillLibraryBuilder(this.library, this.loader)
      : super(library.fileUri, new LazyLibraryScope.top(),
            new LazyLibraryScope.top()) {
    LazyLibraryScope lazyScope = scope as LazyLibraryScope;
    lazyScope.libraryBuilder = this;
    LazyLibraryScope lazyExportScope = exportScope as LazyLibraryScope;
    lazyExportScope.libraryBuilder = this;
  }

  @override
  LibraryBuilder get origin => this;

  @override
  Null get partOfLibrary => null;

  @override
  Iterable<Uri> get dependencies sync* {
    for (LibraryDependency dependency in library.dependencies) {
      yield dependency.targetLibrary.importUri;
    }
    for (LibraryPart part in library.parts) {
      yield getPartUri(importUri, part);
    }
  }

  void ensureLoaded() {
    if (!isReadyToBuild) {
      throw new StateError("Not ready to build.");
    }
    if (isBuilt && !isBuiltAndMarked) {
      // Coverage-ignore-block(suite): Not run.
      isBuiltAndMarked = true;
      finalizeExports();
      return;
    }
    isBuiltAndMarked = true;
    if (isBuilt) return;
    isBuilt = true;
    library.classes.forEach(_addClass);
    library.extensions.forEach(_addExtension);
    library.extensionTypeDeclarations.forEach(_addExtensionTypeDeclaration);

    Map<String, Map<Name, Procedure>> tearOffs = {};
    List<Procedure> nonTearOffs = [];
    for (Procedure procedure in library.procedures) {
      List<Object>? names = extractTypedefNameFromTearOff(procedure.name);
      if (names != null) {
        Map<Name, Procedure> map = tearOffs[names[0] as String] ??= {};
        map[names[1] as Name] = procedure;
      } else {
        nonTearOffs.add(procedure);
      }
    }
    nonTearOffs.forEach(_addMember);
    library.procedures.forEach(_addMember);
    for (Typedef typedef in library.typedefs) {
      addTypedef(typedef, tearOffs[typedef.name]);
    }
    library.fields.forEach(_addMember);

    if (isReadyToFinalizeExports) {
      finalizeExports();
    } else {
      throw new StateError("Not ready to finalize exports.");
    }
  }

  @override
  bool get isUnsupported => library.isUnsupported;

  @override
  bool get isSynthetic => library.isSynthetic;

  @override
  Uri get importUri => library.importUri;

  @override
  Uri get fileUri => library.fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  String? get name => library.name;

  @override
  LibraryBuilder get nameOriginBuilder => this;

  @override
  void becomeCoreLibrary() {
    if (scope.lookupLocalMember("dynamic", setter: false) == null) {
      _addBuilder("dynamic",
          new DynamicTypeDeclarationBuilder(const DynamicType(), this, -1));
    }
    if (scope.lookupLocalMember("Never", setter: false) == null) {
      _addBuilder(
          "Never",
          new NeverTypeDeclarationBuilder(
              const NeverType.nonNullable(), this, -1));
    }
    assert(scope.lookupLocalMember("Null", setter: false) != null,
        "No class 'Null' found in dart:core.");
  }

  void _addClass(Class cls) {
    DillClassBuilder classBuilder = new DillClassBuilder(cls, this);
    _addBuilder(cls.name, classBuilder);
    Map<String, Procedure> tearOffs = {};
    List<Procedure> nonTearOffs = [];
    for (Procedure procedure in cls.procedures) {
      String? name = extractConstructorNameFromTearOff(procedure.name);
      if (name != null) {
        tearOffs[name] = procedure;
      } else {
        nonTearOffs.add(procedure);
      }
    }
    for (Procedure procedure in nonTearOffs) {
      if (procedure.kind == ProcedureKind.Factory) {
        classBuilder.addFactory(procedure, tearOffs[procedure.name.text]);
      } else {
        classBuilder.addProcedure(procedure);
      }
    }
    for (Constructor constructor in cls.constructors) {
      classBuilder.addConstructor(constructor, tearOffs[constructor.name.text]);
    }
    for (Field field in cls.fields) {
      classBuilder.addField(field);
    }
  }

  void _addExtension(Extension extension) {
    DillExtensionBuilder extensionBuilder =
        new DillExtensionBuilder(extension, this);
    _addBuilder(extension.name, extensionBuilder);
  }

  void _addExtensionTypeDeclaration(
      ExtensionTypeDeclaration extensionTypeDeclaration) {
    DillExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
        new DillExtensionTypeDeclarationBuilder(extensionTypeDeclaration, this);
    _addBuilder(extensionTypeDeclaration.name, extensionTypeDeclarationBuilder);
  }

  void _addMember(Member member) {
    if (member.isExtensionMember || member.isExtensionTypeMember) {
      return null;
    }
    String name = member.name.text;
    if (name == unserializableExportName) {
      Field field = member as Field;
      String stringValue;
      if (field.initializer is ConstantExpression) {
        ConstantExpression constantExpression =
            field.initializer as ConstantExpression;
        StringConstant string = constantExpression.constant as StringConstant;
        stringValue = string.value;
      } else {
        // Coverage-ignore-block(suite): Not run.
        StringLiteral string = field.initializer as StringLiteral;
        stringValue = string.value;
      }
      Map<dynamic, dynamic>? json = jsonDecode(stringValue);
      unserializableExports =
          json != null ? new Map<String, String>.from(json) : null;
    } else {
      if (member is Field) {
        _addBuilder(name, new DillFieldBuilder(member, this));
      } else if (member is Procedure) {
        switch (member.kind) {
          case ProcedureKind.Setter:
            _addBuilder(name, new DillSetterBuilder(member, this));
            break;
          case ProcedureKind.Getter:
            _addBuilder(name, new DillGetterBuilder(member, this));
            break;
          case ProcedureKind.Operator:
            // Coverage-ignore(suite): Not run.
            _addBuilder(name, new DillOperatorBuilder(member, this));
            break;
          case ProcedureKind.Method:
            _addBuilder(name, new DillMethodBuilder(member, this));
            break;
          // Coverage-ignore(suite): Not run.
          case ProcedureKind.Factory:
            throw new UnsupportedError(
                "Unexpected library procedure ${member.kind} for ${member}");
        }
      } else {
        throw new UnsupportedError(
            "Unexpected library member ${member} (${member.runtimeType})");
      }
    }
  }

  Builder? _addBuilder(String? name, Builder declaration) {
    if (name == null || name.isEmpty) return null;

    bool isSetter = declaration.isSetter;
    if (isSetter) {
      scope.addLocalMember(name, declaration as MemberBuilder, setter: true);
    } else {
      scope.addLocalMember(name, declaration, setter: false);
    }
    if (declaration.isExtension) {
      scope.addExtension(declaration as ExtensionBuilder);
    }
    if (!name.startsWith("_") && !name.contains('#')) {
      if (isSetter) {
        exportScope.addLocalMember(name, declaration as MemberBuilder,
            setter: true);
      } else {
        exportScope.addLocalMember(name, declaration, setter: false);
      }
    }
    return declaration;
  }

  void addTypedef(Typedef typedef, Map<Name, Procedure>? tearOffs) {
    _addBuilder(
        typedef.name, new DillTypeAliasBuilder(typedef, tearOffs, this));
  }

  @override
  // Coverage-ignore(suite): Not run.
  Builder computeAmbiguousDeclaration(
      String name, Builder builder, Builder other, int charOffset,
      {bool isExport = false, bool isImport = false}) {
    if (builder == other) return builder;
    if (builder is InvalidTypeDeclarationBuilder) return builder;
    if (other is InvalidTypeDeclarationBuilder) return other;
    // For each entry mapping key `k` to declaration `d` in `NS` an entry
    // mapping `k` to `d` is added to the exported namespace of `L` unless a
    // top-level declaration with the name `k` exists in `L`.
    if (builder.parent == this) return builder;
    Message message = templateDuplicatedDeclaration.withArguments(name);
    addProblem(message, charOffset, name.length, fileUri);
    return new InvalidTypeDeclarationBuilder(
        name, message.withLocation(fileUri, charOffset, name.length));
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors {
    return library.name ?? "<library '${library.fileUri}'>";
  }

  void markAsReadyToBuild() {
    isReadyToBuild = true;
  }

  void markAsReadyToFinalizeExports({bool suppressFinalizationErrors = false}) {
    isReadyToFinalizeExports = true;
    this.suppressFinalizationErrors = suppressFinalizationErrors;
  }

  void finalizeExports() {
    unserializableExports?.forEach((String name, String messageText) {
      Builder declaration;
      if (messageText == exportDynamicSentinel) {
        assert(
            name == 'dynamic', // Coverage-ignore(suite): Not run.
            "Unexpected export name for 'dynamic': '$name'");
        declaration = loader.coreLibrary.exportScope
            .lookupLocalMember(name, setter: false)!;
      } else if (messageText == exportNeverSentinel) {
        assert(
            name == 'Never', // Coverage-ignore(suite): Not run.
            "Unexpected export name for 'Never': '$name'");
        declaration = loader.coreLibrary.exportScope
            .lookupLocalMember(name, setter: false)!;
      } else {
        Message message = templateUnspecified.withArguments(messageText);
        if (!suppressFinalizationErrors) {
          addProblem(message, -1, noLength, null);
        }
        declaration =
            new InvalidTypeDeclarationBuilder(name, message.withoutLocation());
      }
      exportScope.addLocalMember(name, declaration, setter: false);
    });

    Map<Reference, Builder>? sourceBuildersMap =
        loader.currentSourceLoader?.buildersCreatedWithReferences;
    for (Reference reference in library.additionalExports) {
      NamedNode node = reference.node as NamedNode;
      Builder declaration;
      String name;
      if (sourceBuildersMap?.containsKey(reference) == true) {
        // Coverage-ignore-block(suite): Not run.
        declaration = sourceBuildersMap![reference]!;
        if (declaration is TypeDeclarationBuilder) {
          name = declaration.name;
        } else if (declaration is MemberBuilder) {
          name = declaration.name;
        } else {
          throw new StateError(
              "Unexpected: $declaration (${declaration.runtimeType}");
        }

        if (declaration.isSetter) {
          exportScope.addLocalMember(name, declaration as MemberBuilder,
              setter: true);
        } else {
          exportScope.addLocalMember(name, declaration, setter: false);
        }
      } else {
        Uri libraryUri;
        bool isSetter = false;
        if (node is Class) {
          libraryUri = node.enclosingLibrary.importUri;
          name = node.name;
        } else if (node is Procedure) {
          libraryUri = node.enclosingLibrary.importUri;
          name = node.name.text;
          isSetter = node.isSetter;
        } else if (node is Member) {
          libraryUri = node.enclosingLibrary.importUri;
          name = node.name.text;
        } else if (node is Typedef) {
          libraryUri = node.enclosingLibrary.importUri;
          name = node.name;
        } else if (node is Extension) {
          libraryUri = node.enclosingLibrary.importUri;
          name = node.name;
        } else if (node is ExtensionTypeDeclaration) {
          libraryUri = node.enclosingLibrary.importUri;
          name = node.name;
        } else {
          unhandled("${node.runtimeType}", "finalizeExports", -1, fileUri);
        }
        LibraryBuilder? library = loader.lookupLibraryBuilder(libraryUri);
        if (library == null) {
          internalProblem(
              templateUnspecified
                  .withArguments("No builder for '$libraryUri'."),
              -1,
              fileUri);
        }
        if (isSetter) {
          declaration =
              library.exportScope.lookupLocalMember(name, setter: true)!;
          exportScope.addLocalMember(name, declaration as MemberBuilder,
              setter: true);
        } else {
          declaration =
              library.exportScope.lookupLocalMember(name, setter: false)!;
          exportScope.addLocalMember(name, declaration, setter: false);
        }
      }

      assert(
          (declaration is ClassBuilder && node == declaration.cls) ||
              (declaration is TypeAliasBuilder &&
                  node == declaration.typedef) ||
              (declaration is MemberBuilder && node == declaration.member) ||
              (declaration is ExtensionBuilder &&
                  node == declaration.extension) ||
              (declaration is ExtensionTypeDeclarationBuilder &&
                  node == declaration.extensionTypeDeclaration),
          // Coverage-ignore(suite): Not run.
          "Unexpected declaration ${declaration} (${declaration.runtimeType}) "
          "for node ${node} (${node.runtimeType}).");
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterator<T> fullMemberIterator<T extends Builder>() {
    return scope.filteredIterator<T>(
        includeDuplicates: false, includeAugmentations: false);
  }

  @override
  // Coverage-ignore(suite): Not run.
  NameIterator<T> fullMemberNameIterator<T extends Builder>() {
    return scope.filteredNameIterator(
        includeDuplicates: false, includeAugmentations: false);
  }
}
