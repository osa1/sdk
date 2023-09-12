// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @patch
// String _intToString(int value) {
//   throw '_intToString in JS compatbility mode (value = $value)';
// }

import 'dart:_internal';

@patch
class _BoxedInt {
  @patch
  String toRadixString(int radix) {
    throw '_BoxedInt.toRadixString in JS compat mode';
  }

  @patch
  String toString() {
    throw '_BoxedInt.toString in JS comapt mode';
  }
}
