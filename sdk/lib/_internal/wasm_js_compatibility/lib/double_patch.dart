// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_helper' show jsStringFromDartString, JS;
import 'dart:_string' show JSStringImplExt;

@patch
class double {
  @patch
  static double? tryParse(String source) {
    // Notice that JS parseFloat accepts garbage at the end of the string.
    // Accept only:
    // - [+/-]NaN
    // - [+/-]Infinity
    // - a Dart double literal
    // We do allow leading or trailing whitespace.
    double result = JS<double>(r"""s => {
      if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
        return NaN;
      }
      return parseFloat(s);
    }""", jsStringFromDartString(source).toExternRef);
    if (result.isNaN) {
      String trimmed = source.trim();
      if (!(trimmed == 'NaN' || trimmed == '+NaN' || trimmed == '-NaN')) {
        return null;
      }
    }
    return result;
  }
}
