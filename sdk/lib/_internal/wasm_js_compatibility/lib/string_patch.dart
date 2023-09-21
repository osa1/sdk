// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show EfficientLengthIterable, patch;
import 'dart:_js_helper' as js;
import 'dart:_js_types';
import 'dart:_wasm';
import 'dart:js_interop';
import 'dart:typed_data';

@patch
class String {
  @patch
  factory String.fromCharCodes(Iterable<int> charCodes,
      [int start = 0, int? end]) {
    final length = charCodes.length;
    if (start < 0) throw RangeError.range(start, 0, length);
    if (end != null && end < start) {
      throw RangeError.range(end, start, length);
    }
    if (end != null && end > length) {
      throw RangeError.range(end, start, length);
    }

    final it = charCodes.iterator;
    for (int i = 0; i < start; i++) {
      it.moveNext();
    }

    int index = 0;
    final listLength = (end ?? length) - start;
    final list = Uint32List(listLength);
    if (end == null) {
      while (it.moveNext()) {
        list[index++] = it.current;
      }
    } else {
      for (int i = start; i < end; i++) {
        if (!it.moveNext()) {
          throw RangeError.range(end, start, i);
        }
        list[index++] = it.current;
      }
    }

    const kMaxApply = 500;
    if (listLength <= kMaxApply) {
      return _fromCharCodeApply(list.toExternRef);
    }

    String result = '';
    for (int i = 0; i < listLength; i += kMaxApply) {
      final chunkEnd =
          (i + kMaxApply < listLength) ? i + kMaxApply : listLength;
      result += _fromCharCodeApplySubarray(
          list.toExternRef, i.toDouble(), chunkEnd.toDouble());
    }
    return result;
  }

  @patch
  factory String.fromCharCode(int charCode) => _fromCharCode(charCode);

  static String _fromOneByteCharCode(int charCode) => JSStringImpl(js
      .JS<WasmExternRef?>('c => String.fromCharCode(c)', charCode.toDouble()));

  static String _fromTwoByteCharCode(int low, int high) =>
      JSStringImpl(js.JS<WasmExternRef?>('(l, h) => String.fromCharCode(h, l)',
          low.toDouble(), high.toDouble()));

  static String _fromCharCode(int charCode) {
    if (0 <= charCode) {
      if (charCode <= 0xffff) {
        return _fromOneByteCharCode(charCode);
      }
      if (charCode <= 0x10ffff) {
        var bits = charCode - 0x10000;
        var low = 0xDC00 | (bits & 0x3ff);
        var high = 0xD800 | (bits >> 10);
        return _fromTwoByteCharCode(low, high);
      }
    }
    throw RangeError.range(charCode, 0, 0x10ffff);
  }

  static String _fromCharCodeApply(WasmExternRef? charCodes) =>
      JSStringImpl(js.JS<WasmExternRef?>(
          'c => String.fromCharCode.apply(null, c)', charCodes));

  static String _fromCharCodeApplySubarray(
          WasmExternRef? charCodes, double index, double end) =>
      // TODO(omersa): We should use subarray below, but it breaks stuff
      // somehow even though the only `charCodes` passed here is a
      // `JSUint32ArrayImpl` externref (i.e. a JS typed array).
      JSStringImpl(js.JS<WasmExternRef?>(
          '(c, i, e) => String.fromCharCode.apply(null, c.slice(i, e))',
          charCodes,
          index,
          end));
}
