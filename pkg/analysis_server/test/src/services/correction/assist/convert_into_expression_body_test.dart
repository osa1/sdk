// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoExpressionBodyTest);
  });
}

@reflectiveTest
class ConvertIntoExpressionBodyTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_INTO_EXPRESSION_BODY;

  Future<void> test_already() async {
    await resolveTestCode('''
fff() => 42;
''');
    await assertNoAssistAt('fff()');
  }

  Future<void> test_async() async {
    await resolveTestCode('''
class A {
  mmm() async {
    return 42;
  }
}
''');
    await assertHasAssistAt('mmm', '''
class A {
  mmm() async => 42;
}
''');
  }

  Future<void> test_async_noAssistWithLint() async {
    createAnalysisOptionsFile(
        lints: [LintNames.prefer_expression_function_bodies]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class A {
  mmm() async {
    return 42;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_closure() async {
    await resolveTestCode('''
setup(x) {}
void f() {
  setup(() {
    return 42;
  });
}
''');
    await assertHasAssistAt('return', '''
setup(x) {}
void f() {
  setup(() => 42);
}
''');
  }

  Future<void> test_closure_hasBlockComment_afterReturnStatement() async {
    await resolveTestCode('''
setup(x) {}
void f() {
  setup(() {
    return 42;
    // Comment.
  });
}
''');
    await assertNoAssistAt('return');
  }

  Future<void> test_closure_hasBlockComment_beforeReturnKeyword() async {
    await resolveTestCode('''
setup(x) {}
void f() {
  setup(() {
    // Comment.
    return 42;
  });
}
''');
    await assertNoAssistAt('return');
  }

  Future<void> test_closure_hasBlockComment_multiple() async {
    await resolveTestCode('''
setup(x) {}
void f() {
  setup(() {
    // Comment.

    // Comment 2.
    return 42;
  });
}
''');
    await assertNoAssistAt('return');
  }

  Future<void> test_closure_hasInlineComment_beforeBodyKeyword() async {
    await resolveTestCode('''
setup(x) {}
void f() {
  setup(() /* Comment. */ async {
    return 42;
  });
}
''');
    await assertNoAssistAt('return');
  }

  Future<void> test_closure_hasInlineComment_beforeOpenBrace() async {
    await resolveTestCode('''
setup(x) {}
void f() {
  setup(() /* Comment. */ {
    return 42;
  });
}
''');
    await assertNoAssistAt('return');
  }

  Future<void> test_closure_hasInlineComment_beforeReturn() async {
    await resolveTestCode('''
setup(x) {}
void f() {
  setup(() {
    /* Comment. */
    return 42;
  });
}
''');
    await assertNoAssistAt('return');
  }

  Future<void> test_closure_hasInlineComment_beforeReturnSemicolon() async {
    await resolveTestCode('''
setup(x) {}
void f() {
  setup(() {
    return  42 /* Comment. */;
  });
}
''');
    await assertNoAssistAt('return');
  }

  Future<void> test_closure_voidExpression() async {
    await resolveTestCode('''
setup(x) {}
void f() {
  setup((_) {
    print('test');
  });
}
''');
    await assertHasAssistAt('(_) {', '''
setup(x) {}
void f() {
  setup((_) => print('test'));
}
''');
  }

  Future<void> test_constructor_factory() async {
    await resolveTestCode('''
class A {
  A.named();

  factory A() {
    return A.named();
  }
}
''');
    await assertHasAssistAt('A()', '''
class A {
  A.named();

  factory A() => A.named();
}
''');
  }

  Future<void> test_constructor_generative() async {
    await resolveTestCode('''
class A {
  int x = 0;

  A() {
    x = 3;
  }
}
''');
    await assertNoAssistAt('A()');
  }

  Future<void> test_function_onBlock() async {
    await resolveTestCode('''
fff() {
  return 42;
}
''');
    await assertHasAssistAt('{', '''
fff() => 42;
''');
  }

  Future<void> test_function_onName() async {
    await resolveTestCode('''
fff() {
  return 42;
}
''');
    await assertHasAssistAt('ff()', '''
fff() => 42;
''');
  }

  Future<void> test_inExpression() async {
    await resolveTestCode('''
int f() {
  return 42;
}
''');
    await assertNoAssistAt('42;');
  }

  Future<void> test_macroGenerated() async {
    testFilePath = join(testPackageLibPath, 'test.macro.dart');
    await resolveTestCode('''
int f() {
  return 0;
}
''');

    await assertNoAssistAt('urn');
  }

  Future<void> test_method_onBlock() async {
    await resolveTestCode('''
class A {
  m() {
    return 42;
  }
}
''');
    await assertHasAssistAt('m() {', '''
class A {
  m() => 42;
}
''');
  }

  Future<void> test_moreThanOneStatement() async {
    await resolveTestCode('''
fff() {
  var v = 42;
  return v;
}
''');
    await assertNoAssistAt('fff()');
  }

  Future<void> test_noEnclosingFunction() async {
    await resolveTestCode('''
var V = 42;
''');
    await assertNoAssistAt('V = ');
  }

  Future<void> test_noReturn() async {
    await resolveTestCode('''
fff() {
  var v = 42;
}
''');
    await assertNoAssistAt('fff()');
  }

  Future<void> test_noReturnValue() async {
    await resolveTestCode('''
fff() {
  return;
}
''');
    await assertNoAssistAt('fff()');
  }

  Future<void> test_topFunction_onReturnStatement() async {
    await resolveTestCode('''
fff() {
  return 42;
}
''');
    await assertHasAssistAt('return', '''
fff() => 42;
''');
  }
}
