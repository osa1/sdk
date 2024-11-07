// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analytics/percentile_calculator.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PercentileCalculatorTest);
  });
}

@reflectiveTest
class PercentileCalculatorTest {
  var calculator = PercentileCalculator();

  void test_clear() {
    for (int i = 1; i <= 100; i++) {
      calculator.addValue(i);
    }
    calculator.clear();
    expect(
      calculator.toAnalyticsString(),
      '{"count":0,"percentiles":[0,0,0,0,0]}',
    );
  }

  void test_toAnalyticsString_empty() {
    expect(
      calculator.toAnalyticsString(),
      '{"count":0,"percentiles":[0,0,0,0,0]}',
    );
  }

  void test_toAnalyticsString_evenDistribution() {
    for (int i = 1; i <= 100; i++) {
      calculator.addValue(i);
    }
    expect(
      calculator.toAnalyticsString(),
      '{"count":100,"percentiles":[50,75,90,95,100]}',
    );
  }
}
