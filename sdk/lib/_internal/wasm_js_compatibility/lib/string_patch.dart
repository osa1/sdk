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
    // TODO(joshualitt): Fast path when lists are backed by JS array in JSCM.
    if (charCodes is Uint8List) {
      return _fromJSArrayLike((charCodes as JSUint8ArrayImpl).toExternRef,
          start, end, charCodes.length);
    } else if (charCodes is EfficientLengthIterable<int>) {
      return _fromEfficientLengthIterable(
          charCodes, start, end ?? charCodes.length);
    }
    return _fromIterable(charCodes, start, end);
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

  static String _fromCharCodeApplySubarray(WasmExternRef? result,
          WasmExternRef? charCodes, double index, double end) =>
      JSStringImpl(js.JS<WasmExternRef?>(
          '(r, c, i, e) => String.fromCharCode.apply(null, c.subarray(i, e))',
          result,
          charCodes,
          index,
          end));

  static String _fromJSArrayLike(
      WasmExternRef? charCodes, int start, int? endOrNull, int len) {
    int end = RangeError.checkValidRange(start, endOrNull, len);
    const kMaxApply = 500;
    if (end <= kMaxApply && start == 0 && end == len) {
      return _fromCharCodeApply(charCodes);
    }
    String result = '';
    for (int i = start; i < end; i += kMaxApply) {
      int chunkEnd = (i + kMaxApply < end) ? i + kMaxApply : end;
      result = _fromCharCodeApplySubarray((result as JSStringImpl).toExternRef,
          charCodes, i.toDouble(), chunkEnd.toDouble());
    }
    return result;
  }

  static int _computeHigh(int code) =>
      0xd800 + ((((code - 0x10000) >> 10) & 0x3ff));

  static int _computeLow(int code) => 0xdc00 + (code & 0x3ff);

  static void _addCodeToArray(JSArrayImpl array, int code) {
    if (code <= 0xffff) {
      array.add(code.toJS);
    } else if (code <= 0x10ffff) {
      array.add(_computeHigh(code).toJS);
      array.add(_computeLow(code).toJS);
    } else {
      throw ArgumentError('Invalid code point $code');
    }
  }

  static String _fromIterable(Iterable<int> charCodes, int start, int? end) {
    if (start < 0) throw RangeError.range(start, 0, charCodes.length);
    if (end != null && end < start) {
      throw RangeError.range(end, start, charCodes.length);
    }

    final it = charCodes.iterator;
    for (int i = 0; i < start; i++) {
      if (!it.moveNext()) {
        throw RangeError.range(start, 0, i);
      }
    }

    final array = JSArrayImpl.empty();
    if (end == null) {
      while (it.moveNext()) {
        _addCodeToArray(array, it.current);
      }
    } else {
      for (int i = start; i < end; i++) {
        if (!it.moveNext()) {
          throw RangeError.range(end, start, i);
        }
        _addCodeToArray(array, it.current);
      }
    }
    return _fromJSArrayLike(
        (array as JSArrayImpl).toExternRef, start, end, charCodes.length);
  }

  static String _fromEfficientLengthIterable(
      EfficientLengthIterable<int> charCodes, int start, int end) {
    if (start < 0) throw RangeError.range(start, 0, charCodes.length);
    if (end < start) {
      throw RangeError.range(end, start, charCodes.length);
    }

    final it = charCodes.iterator;
    for (int i = 0; i < start; i++) {
      it.moveNext();
    }

    int index = 0;
    final list = Uint32List(end - start);
    while (it.moveNext()) {
      final code = it.current;
      if (code <= 0xffff) {
        list[index++] = code;
      } else if (code <= 0x10ffff) {
        list[index++] = _computeHigh(code);
        list[index++] = _computeLow(code);
      } else {
        throw ArgumentError('Invalid code point $code');
      }
    }
    return _fromJSArrayLike(
        (list as JSIntArrayImpl).toExternRef, start, end, charCodes.length);
  }
}
