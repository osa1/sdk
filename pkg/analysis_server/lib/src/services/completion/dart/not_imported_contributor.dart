// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/extension_member_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/file_state_filter.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A contributor of suggestions from not yet imported libraries.
class NotImportedContributor extends DartCompletionContributor {
  final CompletionBudget budget;
  final NotImportedSuggestions additionalData;

  /// When a library is imported with combinators, we cannot skip it, there
  /// might be elements that were excluded, but should be suggested. So, here
  /// we record elements that are already imported.
  final Set<Element> _importedElements = Set.identity();

  NotImportedContributor(
    super.request,
    super.builder,
    this.budget,
    this.additionalData,
  );

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    var analysisDriver = request.analysisContext.driver;

    var fsState = analysisDriver.fsState;
    var filter = FileStateFilter(
      fsState.getFileForPath(request.path),
    );

    try {
      await performance.runAsync('discoverAvailableFiles', (_) async {
        await analysisDriver.discoverAvailableFiles().timeout(budget.left);
      });
    } on TimeoutException {
      additionalData.isIncomplete = true;
      return;
    }

    var importedLibraries = Set<LibraryElement>.identity();
    for (var import in request.libraryElement.libraryImports) {
      var importedLibrary = import.importedLibrary;
      if (importedLibrary != null) {
        if (import.combinators.isEmpty) {
          importedLibraries.add(importedLibrary);
        } else {
          _importedElements.addAll(
            import.namespace.definedNames.values,
          );
        }
      }
    }

    // Use single instance to track getter / setter pairs.
    var extensionContributor = ExtensionMemberContributor(request, builder);

    var knownFiles = fsState.knownFiles.toList();
    for (var file in knownFiles) {
      if (budget.isEmpty) {
        additionalData.isIncomplete = true;
        return;
      }

      if (!filter.shouldInclude(file)) {
        continue;
      }

      var elementResult = await performance.runAsync(
        'getLibraryByUri',
        (_) async {
          return await analysisDriver.getLibraryByUri(file.uriStr);
        },
      );
      if (elementResult is! LibraryElementResult) {
        continue;
      }

      var element = elementResult.element;
      if (importedLibraries.contains(element)) {
        continue;
      }

      var exportNamespace = element.exportNamespace;
      var exportElements = exportNamespace.definedNames.values.toList();

      builder.libraryUriStr = file.uriStr;
      builder.requiredImports.add(file.uri);
      builder.isNotImportedLibrary = true;
      builder.laterReplacesEarlier = false;

      if (request.includeIdentifiers) {
        performance.run('buildSuggestions', (_) {
          _buildSuggestions(exportElements);
        });
      }

      extensionContributor.addExtensions(
        _extensions(exportElements),
      );

      builder.libraryUriStr = null;
      builder.requiredImports.clear();
      builder.isNotImportedLibrary = false;
      builder.laterReplacesEarlier = true;
    }
  }

  void _buildSuggestions(List<Element> elements) {
    var visitor = LibraryElementSuggestionBuilder(request, builder);
    for (var element in elements) {
      if (!_importedElements.contains(element)) {
        element.accept(visitor);
      }
    }
  }

  /// This function intentionally does not use `whereType` for performance.
  ///
  /// https://github.com/dart-lang/sdk/issues/47680
  static List<ExtensionElement> _extensions(List<Element> elements) {
    var extensions = <ExtensionElement>[];
    for (var element in elements) {
      if (element is ExtensionElement) {
        extensions.add(element);
      }
    }
    return extensions;
  }
}
