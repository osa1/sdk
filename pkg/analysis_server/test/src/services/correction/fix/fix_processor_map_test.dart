// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/correction/fix_processor.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixProcessorMapTest);
  });
}

@reflectiveTest
class FixProcessorMapTest {
  static const List<String> lintsAllowedToHaveMultipleBulkFixes = [
    'avoid_types_on_closure_parameters',
    'empty_statements',
    'prefer_collection_literals',
    'prefer_const_constructors',
    'prefer_inlined_adds',
  ];

  void setUp() {
    registerBuiltInProducers();
  }

  void test_lintProducerMap() {
    _assertMap(
        FixProcessor.lintProducerMap, lintsAllowedToHaveMultipleBulkFixes);
  }

  void test_nonLintProducerMap() {
    _assertMap(FixProcessor.nonLintProducerMap);
  }

  void test_registerFixForLint() {
    ResolvedCorrectionProducer generator(
            {required CorrectionProducerContext context}) =>
        MockCorrectionProducer();

    var lintName = 'not_a_lint';
    expect(FixProcessor.lintProducerMap[lintName], null);
    FixProcessor.registerFixForLint(lintName, generator);
    expect(FixProcessor.lintProducerMap[lintName], contains(generator));
    // Restore the map to it's original state so as to not impact other tests.
    FixProcessor.lintProducerMap.remove(lintName);
  }

  void _assertMap(Map<Object, List<ProducerGenerator>> producerMap,
      [List<String> codesAllowedToHaveMultipleBulkFixes = const []]) {
    var unexpectedBulkCodes = <String>[];
    for (var MapEntry(:key, value: generators) in producerMap.entries) {
      var bulkCount = 0;
      for (var generator in generators) {
        var producer =
            generator(context: StubCorrectionProducerContext.instance);
        _assertValidProducer(producer);
        if (producer.canBeAppliedAcrossFiles) {
          bulkCount++;
        }
      }
      if (bulkCount > 1) {
        var name = key.toString();
        if (!codesAllowedToHaveMultipleBulkFixes.contains(name)) {
          unexpectedBulkCodes.add(name);
        }
      }
    }
    if (unexpectedBulkCodes.isNotEmpty) {
      var buffer = StringBuffer();
      buffer.writeln('Unexpected multiple bulk fixes for');
      for (var code in unexpectedBulkCodes) {
        buffer.writeln('- $code');
      }
      fail(buffer.toString());
    }
  }

  void _assertValidProducer(CorrectionProducer producer) {
    var className = producer.runtimeType.toString();
    expect(producer.fixKind, isNotNull, reason: '$className.fixKind');
    if (producer.canBeAppliedAcrossSingleFile) {
      expect(producer.multiFixKind, isNotNull,
          reason: '$className.multiFixKind should be non-null');
    }
  }
}

class MockCorrectionProducer implements ResolvedCorrectionProducer {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
