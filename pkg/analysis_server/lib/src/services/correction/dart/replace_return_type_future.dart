// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ReplaceReturnTypeFuture extends ResolvedCorrectionProducer {
  /// The text for the type argument to 'Future'.
  String _typeArgument = '';

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  List<String> get fixArguments => [_typeArgument];

  @override
  FixKind get fixKind => DartFixKind.REPLACE_RETURN_TYPE_FUTURE;

  @override
  FixKind get multiFixKind => DartFixKind.REPLACE_RETURN_TYPE_FUTURE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare the existing type
    var typeAnnotation = _getTypeAnnotation(node);
    if (typeAnnotation == null) {
      return;
    }
    _typeArgument = utils.getNodeText(typeAnnotation);

    await builder.addDartFileEdit(file, (builder) {
      builder.replaceTypeWithFuture(typeAnnotation, typeProvider);
    });
  }

  static TypeAnnotation? _getTypeAnnotation(AstNode node) {
    var function = node.thisOrAncestorOfType<FunctionDeclaration>();
    if (function != null) {
      return function.returnType;
    }
    var method = node.thisOrAncestorOfType<MethodDeclaration>();
    return method?.returnType;
  }
}
