// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../summary/macros_environment.dart';
import 'context_collection_resolution.dart';
import 'resolution.dart';

main() {
  try {
    MacrosEnvironment.instance;
  } catch (_) {
    print('Cannot initialize environment. Skip macros tests.');
    return;
  }

  defineReflectiveSuite(() {
    defineReflectiveTests(MacroResolutionTest);
  });
}

@reflectiveTest
class MacroResolutionTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
    );

    newFile(
      '$testPackageLibPath/append.dart',
      getMacroCode('append.dart'),
    );

    newFile(
      '$testPackageLibPath/diagnostic.dart',
      getMacroCode('diagnostic.dart'),
    );
  }

  test_declareType_class() async {
    await assertNoErrorsInCode(r'''
import 'append.dart';

@DeclareType('B', 'class B {}')
class A {}

void f(B b) {}
''');
  }

  test_diagnostic_compilesWithError() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    unresolved;
  }
}
''');

    await assertErrorsInCode('''
import 'a.dart';

@MyMacro()
class A {}
''', [
      error(
        CompileTimeErrorCode.MACRO_ERROR,
        18,
        10,
        messageContains: [
          'Unhandled error',
          'package:test/a.dart',
          'unresolved',
          'MyMacro',
        ],
      ),
    ]);
  }

  test_diagnostic_notSupportedArgument() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTargetDeclaration()
  void foo() {}
}
''', [
      error(WarningCode.MACRO_WARNING, 75, 3),
    ]);
  }

  test_diagnostic_report_atDeclaration_class_error() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportErrorAtTargetDeclaration()
class A {}
''', [
      error(CompileTimeErrorCode.MACRO_ERROR, 67, 1),
    ]);
  }

  test_diagnostic_report_atDeclaration_class_info() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportInfoAtTargetDeclaration()
class A {}
''', [
      error(HintCode.MACRO_INFO, 66, 1),
    ]);
  }

  test_diagnostic_report_atDeclaration_class_warning() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTargetDeclaration()
class A {}
''', [
      error(WarningCode.MACRO_WARNING, 62, 1),
    ]);
  }

  test_diagnostic_report_atDeclaration_constructor() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTargetDeclaration()
  A.named();
}
''', [
      error(WarningCode.MACRO_WARNING, 72, 5),
    ]);
  }

  test_diagnostic_report_atDeclaration_field() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTargetDeclaration()
  final foo = 0;
}
''', [
      error(WarningCode.MACRO_WARNING, 76, 3),
    ]);
  }

  test_diagnostic_report_atDeclaration_method() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

class A {
  @ReportAtTargetDeclaration()
  void foo() {}
}
''', [
      error(WarningCode.MACRO_WARNING, 75, 3),
    ]);
  }

  test_diagnostic_report_atDeclaration_mixin() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtTargetDeclaration()
mixin A {}
''', [
      error(WarningCode.MACRO_WARNING, 62, 1),
    ]);
  }

  test_diagnostic_report_atTarget_method() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportAtFirstMethod()
class A {
  void foo() {}
  void bar() {}
}
''', [
      error(WarningCode.MACRO_WARNING, 67, 3),
    ]);
  }

  test_diagnostic_report_contextMessages_superClassMethods() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void foo() {}
  void bar() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';
import 'diagnostic.dart';

@ReportWithContextMessages(forSuperClass: true)
class B extends A {}
''', [
      error(WarningCode.MACRO_WARNING, 98, 1, contextMessages: [
        message('/home/test/lib/a.dart', 17, 3),
        message('/home/test/lib/a.dart', 33, 3)
      ]),
    ]);
  }

  test_diagnostic_report_contextMessages_thisClassMethods() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportWithContextMessages()
class A {
  void foo() {}
  void bar() {}
}
''', [
      error(WarningCode.MACRO_WARNING, 62, 1, contextMessages: [
        message('/home/test/lib/test.dart', 73, 3),
        message('/home/test/lib/test.dart', 89, 3)
      ]),
    ]);
  }

  test_diagnostic_report_contextMessages_thisClassMethods_noTarget() async {
    await assertErrorsInCode('''
import 'diagnostic.dart';

@ReportWithContextMessages(withDeclarationTarget: false)
class A {
  void foo() {}
  void bar() {}
}
''', [
      error(WarningCode.MACRO_WARNING, 27, 56, contextMessages: [
        message('/home/test/lib/test.dart', 101, 3),
        message('/home/test/lib/test.dart', 117, 3)
      ]),
    ]);
  }

  test_diagnostic_throwsException() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    throw 12345;
  }
}
''');

    await assertErrorsInCode('''
import 'a.dart';

@MyMacro()
class A {}
''', [
      error(
        CompileTimeErrorCode.MACRO_ERROR,
        18,
        10,
        messageContains: [
          'Unhandled error',
          'package:test/a.dart',
          '12345',
          'MyMacro',
        ],
      ),
    ]);
  }

  test_getResolvedLibrary_macroAugmentation_hasErrors() async {
    newFile(
      '$testPackageLibPath/append.dart',
      getMacroCode('append.dart'),
    );

    newFile('$testPackageLibPath/test.dart', r'''
import 'append.dart';

@DeclareInType('  NotType foo() {}')
class A {}
''');

    final session = contextFor(testFile).currentSession;
    final result = await session.getResolvedLibrary(testFile.path);

    // 1. Has the macro augmentation unit.
    // 2. It has an error reported.
    assertResolvedLibraryResultText(result, configure: (configuration) {
      configuration.unitConfiguration
        ..nodeSelector = (unitResult) {
          if (unitResult.isMacroAugmentation) {
            return unitResult.findNode.namedType('NotType');
          }
          return null;
        }
        ..withContentPredicate = (unitResult) {
          return unitResult.isAugmentation;
        };
    }, r'''
ResolvedLibraryResult
  element: package:test/test.dart
  units
    /home/test/lib/test.dart
      flags: exists isLibrary
      uri: package:test/test.dart
    /home/test/lib/test.macro.dart
      flags: exists isAugmentation isMacroAugmentation
      uri: package:test/test.macro.dart
      content
---
library augment 'test.dart';

augment class A {
  NotType foo() {}
}
---
      errors
        50 +7 UNDEFINED_CLASS
      selectedNode: NamedType
        name: NotType
        element: <null>
        type: InvalidType
''');
  }
}
