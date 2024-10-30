// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class ConvertIntoAsyncBody extends ResolvedCorrectionProducer {
  ConvertIntoAsyncBody({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_INTO_ASYNC_BODY;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var body = getEnclosingFunctionBody();
    if (body == null ||
        body is EmptyFunctionBody ||
        // Do not offer a correction if there is an `async`, `async*`, `sync*`,
        // or the fictional `sync` keyword.
        body.keyword != null) {
      return;
    }

    // Function bodies can be quite large, e.g. Flutter build() methods.
    // It is surprising to see this Quick Assist deep in a function body.
    if (body is BlockFunctionBody &&
        selectionOffset > body.block.beginToken.end) {
      return;
    }
    if (body is ExpressionFunctionBody &&
        selectionOffset > body.beginToken.end) {
      return;
    }

    var parent = body.parent;
    if (parent is ConstructorDeclaration) {
      return;
    }
    if (parent is FunctionExpression && parent.parent is! FunctionDeclaration) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.convertFunctionFromSyncToAsync(
        body: body,
        typeSystem: typeSystem,
        typeProvider: typeProvider,
      );
    });
  }
}
