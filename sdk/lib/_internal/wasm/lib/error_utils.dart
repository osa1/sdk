// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_wasm';

class IndexErrorUtils {
  /// Same as [IndexError.check], but assumes that [length] is positive and
  /// uses a single unsigned comparison. Always inlined.
  @pragma("wasm:prefer-inline")
  static void checkAssumePositiveLength(int index, int length) {
    if (WasmI64.fromInt(length).leU(WasmI64.fromInt(index))) {
      throw IndexError.withLength(index, length);
    }
  }
}

class RangeErrorUtils {
  /// Same as `RangeError.checkValueInInterval(value, 0, maxValue)`, but
  /// assumes that [maxValue] is positive and uses a single unsigned
  /// comparison. Always inlined.
  @pragma("wasm:prefer-inline")
  static void checkValueBetweenZeroAndPositiveMax(int value, int maxValue) {
    if (WasmI64.fromInt(maxValue).leU(WasmI64.fromInt(value))) {
      throw RangeError.range(value, 0, maxValue);
    }
  }
}
