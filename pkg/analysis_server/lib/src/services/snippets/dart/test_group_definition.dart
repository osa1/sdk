// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_producer.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Produces a [Snippet] that creates a `group()` block.
class TestGroupDefinition extends DartSnippetProducer {
  static const prefix = 'group';
  static const label = 'group';

  TestGroupDefinition(super.request, {required super.elementImportCache});

  @override
  String get snippetPrefix => prefix;

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.write("group('");
        builder.addSimpleLinkedEdit('groupName', 'group name');
        builder.writeln("', () {");
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('});');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a test group block.',
      builder.sourceChange,
    );
  }

  @override
  Future<bool> isValid() async {
    if (!await super.isValid()) {
      return false;
    }

    return isInTestDirectory;
  }
}
