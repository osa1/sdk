// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_helper' show jsStringFromDartString, JS;
import 'dart:_string' show JSStringImplExt;

@patch
class double {
  @patch
  @pragma('wasm:prefer-inline')
  static double? tryParse(String source) => _tryParseJS(source);
}
