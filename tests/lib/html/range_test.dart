// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

main() {
  group('supported', () {
    test('supports_createContextualFragment', () {
      expect(Range.supportsCreateContextualFragment, isTrue);
    });
  });

  group('functional', () {
    test('supported works', () {
      var range = new Range();
      range.selectNode(document.body!);

      var expectation =
          Range.supportsCreateContextualFragment ? returnsNormally : throws;

      expect(() {
        range.createContextualFragment('<div></div>');
      }, expectation);
    });
  });
}
