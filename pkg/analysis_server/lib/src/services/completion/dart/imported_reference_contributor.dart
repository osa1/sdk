// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A contributor for calculating suggestions for imported top level members.
class ImportedReferenceContributor extends DartCompletionContributor {
  ImportedReferenceContributor(super.request, super.builder);

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    if (!request.includeIdentifiers) {
      return;
    }

    // Traverse imports including dart:core
    var imports = request.libraryElement.libraryImports;
    for (var importElement in imports) {
      var libraryElement = importElement.importedLibrary;
      if (libraryElement != null) {
        _buildSuggestions(
          libraryElement: libraryElement,
          namespace: importElement.namespace,
          prefix: importElement.prefix?.element.name,
        );
        if (libraryElement.isDartCore &&
            request.opType.includeTypeNameSuggestions) {
          builder.suggestName('Never');
        }
      }
    }
  }

  void _buildSuggestions({
    required LibraryElement libraryElement,
    required Namespace namespace,
    String? prefix,
  }) {
    builder.libraryUriStr = libraryElement.source.uri.toString();
    var visitor = LibraryElementSuggestionBuilder(request, builder, prefix);
    for (var elem in namespace.definedNames.values) {
      elem.accept(visitor);
    }
    builder.libraryUriStr = null;
  }
}
