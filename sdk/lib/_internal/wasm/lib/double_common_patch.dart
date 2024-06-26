// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;

@patch
class double {
  @patch
  static double parse(String source,
      [@deprecated double onError(String source)?]) {
    double? result = tryParse(source);
    if (result == null) {
      if (onError == null) {
        throw FormatException('Invalid double $source');
      } else {
        return onError(source);
      }
    }
    return result;
  }

  /// Wasm i64.trunc_sat_f64_s instruction.
  external int _toInt();

  /// Wasm f64.copysign instruction.
  external double _copysign(double other);
}
