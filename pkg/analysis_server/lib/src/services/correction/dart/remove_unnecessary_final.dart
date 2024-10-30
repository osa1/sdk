// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnnecessaryFinal extends ResolvedCorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_FINAL;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_UNNECESSARY_FINAL_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    Token? keyword;
    if (node is FieldFormalParameter) {
      keyword = node.keyword;
    } else if (node is SuperFormalParameter) {
      keyword = node.keyword;
    }
    if (keyword == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(keyword!, keyword.next!));
    });
  }
}
