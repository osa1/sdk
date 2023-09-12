// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal';
import 'dart:_js_types';
import 'dart:_js_helper';

@patch
class int {
  @patch
  external const factory int.fromEnvironment(String name,
      {int defaultValue = 0});

  @patch
  static int parse(String source, {int? radix, int onError(String source)?}) {
    if (source.isEmpty) {
      return _handleFormatError(onError, source, 0, radix, null) as int;
    }

    final JSStringImpl sourceImpl = unsafeCast<JSStringImpl>(source);
    final double value;
    if (radix != null) {
      value = JS<double>(
          '(s, r) => parseInt(s, r)', source.toExternRef, radix.toDouble());
    } else {
      value = JS<double>('(s) => parseInt(s)', source.toExternRef);
    }

    if (value.isNaN) {
      return _handleFormatError(onError, source, null, radix, null) as int;
    }

    return value.toInt();
  }

  @patch
  static int? tryParse(String source, {int? radix}) {
    if (source.isEmpty) {
      return null;
    }

    final JSStringImpl sourceImpl = unsafeCast<JSStringImpl>(source);
    final double value;
    if (radix != null) {
      value = JS<double>(
          '(s, r) => parseInt(s, r)', source.toExternRef, radix.toDouble());
    } else {
      value = JS<double>('(s) => parseInt(s)', source.toExternRef);
    }

    if (value.isNaN) {
      return null;
    }

    return value.toInt();
  }

  static int? _handleFormatError(int? Function(String)? onError, String source,
      int? index, int? radix, String? message) {
    if (onError != null) return onError(source);
    if (message != null) {
      throw FormatException(message, source, index);
    }
    if (radix == null) {
      throw FormatException("Invalid number", source, index);
    }
    throw FormatException("Invalid radix-$radix number", source, index);
  }

  /// Wasm i64.div_s instruction.
  external int _div_s(int divisor);

  /// Wasm i64.le_u instruction.
  external bool _le_u(int other);

  /// Wasm i64.lt_u instruction.
  external bool _lt_u(int other);

  /// Wasm i64.shr_s instruction.
  external int _shr_s(int shift);

  /// Wasm i64.shr_u instruction.
  external int _shr_u(int shift);

  /// Wasm i64.shl instruction.
  external int _shl(int shift);
}
