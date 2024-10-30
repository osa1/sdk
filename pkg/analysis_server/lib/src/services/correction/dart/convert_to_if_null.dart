// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToIfNull extends ResolvedCorrectionProducer {
  ConvertToIfNull({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_IF_NULL;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_IF_NULL_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is ConditionalExpression &&
        node.offset == errorOffset &&
        node.length == errorLength) {
      var condition = node.condition as BinaryExpression;
      Expression nullableExpression;
      Expression defaultExpression;
      if (condition.operator.type == TokenType.EQ_EQ) {
        nullableExpression = node.elseExpression;
        defaultExpression = node.thenExpression;
      } else {
        nullableExpression = node.thenExpression;
        defaultExpression = node.elseExpression;
      }

      if (defaultExpression is SimpleIdentifier &&
          defaultExpression.isSynthetic) {
        return;
      }

      var parentheses = defaultExpression.precedence <
          Precedence.forTokenType(TokenType.QUESTION_QUESTION);

      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(node), (builder) {
          builder.write(utils.getNodeText(nullableExpression));

          if (defaultExpression is NullLiteral) return;
          builder.write(' ?? ');
          if (parentheses) {
            builder.write('(');
          }
          builder.write(utils.getNodeText(defaultExpression));
          if (parentheses) {
            builder.write(')');
          }
        });
      });
    }
  }
}
