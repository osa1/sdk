// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @patch
// String _intToString(int value) {
//   throw '_intToString in JS compatbility mode (value = $value)';
// }

import 'dart:_internal';
import 'dart:_js_helper';
import 'dart:_js_types';
import 'dart:_wasm';

@patch
class _BoxedInt {
  @patch
  String toRadixString(int radix) => JSStringImpl(JS<WasmExternRef?>(
      '(n, r) => n.toString(r)', toDouble().toExternRef, radix.toDouble()));

  @patch
  String toString() => JSStringImpl(
      JS<WasmExternRef?>('(n) => n.toString()', toDouble().toExternRef));
}
