// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_analysis_flags.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisGetImportedElementsIntegrationTest);
  });
}

@reflectiveTest
class AnalysisGetImportedElementsIntegrationTest
    extends AbstractAnalysisServerIntegrationTest {
  /// Pathname of the file containing Dart code.
  late String pathname;

  /// Dart code under test.
  late String text;

  /// Check that an analysis.getImportedElements request on the region starting
  /// with the first character that matches [target] and having the given
  /// [length] matches the given list of [expected] imported elements.
  Future<void> checkElements(
    String target,
    List<ImportedElements> expected,
  ) async {
    bool equals(
      ImportedElements actualElements,
      ImportedElements expectedElements,
    ) {
      if (actualElements.path.endsWith(expectedElements.path) &&
          actualElements.prefix == expectedElements.prefix) {
        var actual = actualElements.elements;
        var expected = expectedElements.elements;
        if (actual.length == expected.length) {
          for (var i = 0; i < actual.length; i++) {
            if (!expected.contains(actual[i])) {
              return false;
            }
          }
          return true;
        }
      }
      return false;
    }

    int find(List<ImportedElements> actual, ImportedElements expectedElements) {
      for (var i = 0; i < actual.length; i++) {
        var actualElements = actual[i];
        if (equals(actualElements, expectedElements)) {
          return i;
        }
      }
      return -1;
    }

    var offset = text.indexOf(target);
    var result = await sendAnalysisGetImportedElements(
      pathname,
      offset,
      target.length,
    );

    var actual = result.elements;
    expect(actual, hasLength(expected.length));
    for (var elements in expected) {
      var index = find(actual, elements);
      if (index < 0) {
        fail('Expected $elements; not found');
      }
      actual.removeAt(index);
    }
  }

  /// Check that an analysis.getImportedElements request on the region matching
  /// [target] produces an empty list of elements.
  Future<void> checkNoElements(String target) async {
    var offset = text.indexOf(target);
    var result = await sendAnalysisGetImportedElements(
      pathname,
      offset,
      target.length,
    );

    expect(result.elements, hasLength(0));
  }

  @override
  Future<void> setUp() {
    return super.setUp().then((_) {
      pathname = sourcePath('test.dart');
    });
  }

  Future<void> test_getImportedElements_none() async {
    text = r'''
void f() {}
''';
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    await checkNoElements('f() {}');
  }

  Future<void> test_getImportedElements_some() async {
    text = '''
import 'dart:math';

void f() {
  Random r = new Random();
  String s = r.nextBool().toString();
  print(s);
}
''';
    writeFile(pathname, text);
    await standardAnalysisSetup();
    await analysisFinished;

    if (disableManageImportsOnPaste) {
      await checkElements('f()', []);
    } else {
      await checkElements('f()', [
        ImportedElements(path.join('lib', 'core', 'core.dart'), '', [
          'String',
          'print',
        ]),
        ImportedElements(path.join('lib', 'math', 'math.dart'), '', ['Random']),
      ]);
    }
  }
}
