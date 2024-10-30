// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

main() {
  test('EventException', () {
    final event = new Event('Event');
    // Intentionally do not initialize it!
    try {
      document.dispatchEvent(event);
    } on DomException catch (e) {
      expect(e.name, DomException.INVALID_STATE);
    }
  });
}
