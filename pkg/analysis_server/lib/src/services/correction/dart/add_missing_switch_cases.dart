// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/exhaustiveness.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingSwitchCases extends ResolvedCorrectionProducer {
  AddMissingSwitchCases({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.ADD_MISSING_SWITCH_CASES;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;

    var diagnostic = this.diagnostic;
    if (diagnostic is! AnalysisError) {
      return;
    }

    var patternPartsList = diagnostic.data;
    if (patternPartsList is! List<List<MissingPatternPart>>) {
      return;
    }

    if (node is SwitchExpression) {
      await _switchExpression(
        builder: builder,
        node: node,
        patternPartsList: patternPartsList,
      );
    }

    if (node is SwitchStatement) {
      await _switchStatement(
        builder: builder,
        node: node,
        patternPartsList: patternPartsList,
      );
    }
  }

  Future<void> _switchExpression({
    required ChangeBuilder builder,
    required SwitchExpression node,
    required List<List<MissingPatternPart>> patternPartsList,
  }) async {
    var lineIndent = utils.getLinePrefix(node.offset);
    var singleIndent = utils.oneIndent;

    await builder.addDartFileEdit(file, (builder) {
      builder.insertCaseClauseAtEnd(
          switchKeyword: node.switchKeyword,
          rightParenthesis: node.rightParenthesis,
          leftBracket: node.leftBracket,
          rightBracket: node.rightBracket, (builder) {
        for (var patternParts in patternPartsList) {
          builder.write(lineIndent);
          builder.write(singleIndent);
          builder.writeln('// TODO: Handle this case.');
          builder.write(lineIndent);
          builder.write(singleIndent);
          _writePatternPart(builder, patternParts);
          builder.writeln(' => throw UnimplementedError(),');
        }
      });
    });
  }

  Future<void> _switchStatement({
    required ChangeBuilder builder,
    required SwitchStatement node,
    required List<List<MissingPatternPart>> patternPartsList,
  }) async {
    var lineIndent = utils.getLinePrefix(node.offset);
    var singleIndent = utils.oneIndent;

    await builder.addDartFileEdit(file, (builder) {
      builder.insertCaseClauseAtEnd(
          switchKeyword: node.switchKeyword,
          rightParenthesis: node.rightParenthesis,
          leftBracket: node.leftBracket,
          rightBracket: node.rightBracket, (builder) {
        for (var patternParts in patternPartsList) {
          builder.write(lineIndent);
          builder.write(singleIndent);
          builder.write('case ');
          _writePatternPart(builder, patternParts);
          builder.writeln(':');
          builder.write(lineIndent);
          builder.write(singleIndent);
          builder.write(singleIndent);
          builder.writeln('// TODO: Handle this case.');
        }
      });
    });
  }

  void _writePatternPart(
    DartEditBuilder builder,
    List<MissingPatternPart> parts,
  ) {
    for (var part in parts) {
      if (part is MissingPatternEnumValuePart) {
        builder.writeReference(part.enumElement);
        builder.write('.');
        builder.write(part.value.name);
      } else if (part is MissingPatternTextPart) {
        builder.write(part.text);
      } else if (part is MissingPatternTypePart) {
        builder.writeType(part.type);
      }
    }
  }
}
