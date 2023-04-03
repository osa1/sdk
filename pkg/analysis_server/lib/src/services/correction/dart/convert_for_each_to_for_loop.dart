// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertForEachToForLoop extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_FOR_EACH_TO_FOR_LOOP;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_FOR_EACH_TO_FOR_LOOP_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var invocation = node.parent;
    if (invocation is! MethodInvocation) {
      return;
    }
    var statement = invocation.parent;
    if (statement is! ExpressionStatement) {
      return;
    }
    var argument = invocation.argumentList.arguments[0];
    if (argument is! FunctionExpression) {
      return;
    }
    var parameters = argument.parameters?.parameters;
    if (parameters == null || parameters.length != 1) {
      return;
    }
    var parameter = parameters[0];
    if (parameter is! NormalFormalParameter) {
      return;
    }
    var loopVariableName = parameter.name?.lexeme;
    if (loopVariableName == null) {
      return;
    }
    var target = utils.getNodeText(invocation.target!);
    var body = argument.body;
    if (body.isAsynchronous || body.isGenerator) {
      return;
    }
    if (body is BlockFunctionBody) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.startStart(invocation, body), (builder) {
          builder.write('for (var ');
          builder.write(loopVariableName);
          builder.write(' in ');
          builder.write(target);
          builder.write(') ');
        });
        builder.addDeletion(range.endEnd(body, statement));
        body.visitChildren(_ReturnVisitor(builder));
      });
    } else if (body is ExpressionFunctionBody) {
      var expression = body.expression;
      if (expression is SetOrMapLiteral && expression.typeArguments == null) {
        return;
      }
      var prefix = utils.getPrefix(statement.offset);
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.startStart(invocation, expression),
            (builder) {
          builder.write('for (var ');
          builder.write(loopVariableName);
          builder.write(' in ');
          builder.write(target);
          builder.writeln(') {');
          builder.write(prefix);
          builder.write('  ');
        });
        builder.addReplacement(range.endEnd(expression, statement), (builder) {
          builder.writeln(';');
          builder.write(prefix);
          builder.write('}');
        });
        body.visitChildren(_ReturnVisitor(builder));
      });
    }
  }
}

class _ReturnVisitor extends RecursiveAstVisitor<void> {
  final DartFileEditBuilder builder;

  _ReturnVisitor(this.builder);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Don't visit children.
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    builder.addSimpleReplacement(range.node(node), 'continue;');
  }
}
