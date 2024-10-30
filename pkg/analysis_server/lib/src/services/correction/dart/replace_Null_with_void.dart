// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We use 'Null' in the file name to distinguish from 'null'.
// ignore_for_file: file_names

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceNullWithVoid extends ResolvedCorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_NULL_WITH_VOID;

  @override
  FixKind? get multiFixKind => DartFixKind.REPLACE_NULL_WITH_VOID_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final diagnostic = this.diagnostic;
    if (diagnostic is AnalysisError) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.error(diagnostic), 'void');
      });
    }
  }
}
