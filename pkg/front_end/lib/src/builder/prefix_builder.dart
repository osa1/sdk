// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.prefix_builder;

import 'package:kernel/ast.dart' show LibraryDependency;

import '../base/scope.dart';
import '../codes/cfe_codes.dart';
import '../kernel/load_library_builder.dart' show LoadLibraryBuilder;
import '../source/source_library_builder.dart';
import 'builder.dart';
import 'declaration_builders.dart';

class PrefixBuilder extends BuilderImpl {
  final String name;

  final Scope exportScope = new Scope.top(kind: ScopeKind.library);

  @override
  final SourceLibraryBuilder parent;

  final bool deferred;

  @override
  final int charOffset;

  final int importIndex;

  final LoadLibraryBuilder? loadLibraryBuilder;

  final bool isWildcard;

  PrefixBuilder(this.name, this.deferred, this.parent, this.loadLibraryBuilder,
      this.charOffset, this.importIndex)
      : isWildcard = name == '_' {
    assert(deferred == (loadLibraryBuilder != null),
        "LoadLibraryBuilder must be provided iff prefix is deferred.");
    if (loadLibraryBuilder != null) {
      addToExportScope('loadLibrary', loadLibraryBuilder!, charOffset);
    }
  }

  LibraryDependency? get dependency => loadLibraryBuilder?.importDependency;

  @override
  Uri get fileUri => parent.fileUri;

  /// Lookup a member with [name] in the export scope.
  Builder? lookup(String name, int charOffset, Uri fileUri) {
    return exportScope.lookup(name, charOffset, fileUri);
  }

  void addToExportScope(String name, Builder member, int charOffset) {
    if (deferred && member is ExtensionBuilder) {
      parent.addProblem(templateDeferredExtensionImport.withArguments(name),
          charOffset, noLength, fileUri);
    }

    Builder? existing =
        exportScope.lookupLocalMember(name, setter: member.isSetter);
    Builder result;
    if (existing != null) {
      // Coverage-ignore-block(suite): Not run.
      result = parent.computeAmbiguousDeclaration(
          name, existing, member, charOffset,
          isExport: true);
    } else {
      result = member;
    }
    exportScope.addLocalMember(name, result, setter: member.isSetter);
    if (result is ExtensionBuilder) {
      exportScope.addExtension(result);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => name;
}
