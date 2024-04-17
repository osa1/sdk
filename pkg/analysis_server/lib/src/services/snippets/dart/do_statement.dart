// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_producer.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Produces a [Snippet] that creates a `do while` loop.
class DoStatement extends DartSnippetProducer {
  static const prefix = 'do';
  static const label = 'do while';

  DoStatement(super.request, {required super.elementImportCache});

  @override
  String get snippetPrefix => prefix;

  @override
  Future<Snippet> compute() async {
    var builder = ChangeBuilder(session: request.analysisSession);
    var indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.writeln('do {');
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('} while (');
        builder.addSimpleLinkedEdit('condition', 'condition');
        builder.write(');');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a do-while loop.',
      builder.sourceChange,
    );
  }
}
