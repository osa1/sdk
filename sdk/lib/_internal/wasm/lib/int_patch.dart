// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;
import "dart:_string" show StringUncheckedOperations;
import "dart:_wasm";

@patch
class int {
  @patch
  static int? tryParse(String source, {int? radix}) =>
      source.tryParseInt(radix: radix);

  @patch
  static int parse(String source, {int? radix}) =>
      source.parseInt(radix: radix);
}
