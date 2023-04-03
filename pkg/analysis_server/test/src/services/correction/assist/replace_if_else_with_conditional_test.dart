// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceIfElseWithConditionalTest);
  });
}

@reflectiveTest
class ReplaceIfElseWithConditionalTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL;

  Future<void> test_assignment() async {
    await resolveTestCode('''
void f() {
  int vvv;
  if (true) {
    vvv = 111;
  } else {
    vvv = 222;
  }
}
''');
    await assertHasAssistAt('if (true)', '''
void f() {
  int vvv;
  vvv = true ? 111 : 222;
}
''');
  }

  Future<void> test_expressionVsReturn() async {
    await resolveTestCode('''
void f() {
  if (true) {
    print(42);
  } else {
    return;
  }
}
''');
    await assertNoAssistAt('else');
  }

  Future<void> test_ifCasePattern() async {
    await resolveTestCode('''
f() {
  var json = [1, 2, 3];
  int vvv;
  if (json case [3, 4]) {
    vvv = 111;
  } else {
    vvv = 222;
  }
}
''');
    await assertNoAssistAt('if (json case [3, 4])');
  }

  Future<void> test_notIfStatement() async {
    await resolveTestCode('''
void f() {
  print(0);
}
''');
    await assertNoAssistAt('print');
  }

  Future<void> test_notSingleStatement() async {
    await resolveTestCode('''
void f() {
  int vvv;
  if (true) {
    print(0);
    vvv = 111;
  } else {
    print(0);
    vvv = 222;
  }
}
''');
    await assertNoAssistAt('if (true)');
  }

  Future<void> test_return_expression_expression() async {
    await resolveTestCode('''
int f() {
  if (true) {
    return 111;
  } else {
    return 222;
  }
}
''');
    await assertHasAssistAt('if (true)', '''
int f() {
  return true ? 111 : 222;
}
''');
  }

  Future<void> test_return_expression_nothing() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f(bool c) {
  if (c) {
    return 111;
  } else {
    return;
  }
}
''');
    await assertNoAssistAt('if (c)');
  }

  Future<void> test_return_nothing_expression() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f(bool c) {
  if (c) {
    return;
  } else {
    return 222;
  }
}
''');
    await assertNoAssistAt('if (c)');
  }
}
