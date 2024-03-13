// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show ClassID, patch, POWERS_OF_TEN, unsafeCast;
import 'dart:_js_helper' as js;
import 'dart:_js_string_convert';
import 'dart:_js_types';
import 'dart:_wasm';
import 'dart:js_interop';
import 'dart:typed_data' show Uint8List, Uint16List;

@JS('JSON')
external _JSJson get _jsJsonGetter;

final _JSJson _jsJson = _jsJsonGetter;

extension type _JSJson._(JSObject _jsJSON) implements JSObject {}

extension _JSJsonParse on _JSJson {
  @JS('parse')
  external JSAny? parse(String string);
}

extension _JSObjectKeys on JSObject {
  @JS('keys')
  external JSArray<JSString> keys();
}

@patch
dynamic _parseJson(
    String source, Object? Function(Object? key, Object? value)? reviver) {
  final JSAny? parsed = _jsJson.parse(source);
  return _convertJsonToDart(parsed, reviver);
}

Object? _convertJsonToDart(
    JSAny? object, Object? Function(Object? key, Object? value)? reviver) {
  // Similar to `dartify`, but `_convertJsonToDart`:
  //
  // - Only handles `Object`, `Array`, `string`, `number`, `boolean`, and `null`
  // - Calls `reviver` on array and map elements.
  // - Assumes the objects are not aliased.

  final WasmExternRef? ref = object.toExternRef;

  if (ref.isNull) {
    return null;
  } else if (js.isJSSimpleObject(ref)) {
    final Map<String, Object?> dartMap = {};

    final jsObject = unsafeCast<JSObject>(object);
    final List<JSString> keys = jsObject.keys().toDart;
    final numKeys = keys.length;

    for (int keyIdx = 0; keyIdx < numKeys; keyIdx += 1) {
      final JSString key = keys[keyIdx];
      final String keyString = key.toDart;
      final WasmExternRef? jsValueRef = js.getPropertyRaw(ref, key.toExternRef);
      final jsValue = js.JSValue(jsValueRef);
      Object? dartValue =
          _convertJsonToDart(jsValue as JSAny, reviver) as JSAny;

      if (reviver != null) {
        dartValue = reviver(keyString, dartValue);
      }

      dartMap[keyString] = dartValue;
    }

    return dartMap;
  } else if (js.isJSArray(ref)) {
    final List<Object?> dartList = [];

    final jsArray = unsafeCast<JSArray>(object).toDart;
    final numElements = jsArray.length;

    for (int i = 0; i < numElements; i += 1) {
      final elem = jsArray[i];
      Object? dartValue = _convertJsonToDart(elem, reviver);

      if (reviver != null) {
        dartValue = reviver(i, dartValue);
      }

      dartList.add(dartValue);
    }

    return dartList;
  } else if (js.isJSString(ref)) {
    return JSStringImpl.box(ref);
  } else if (js.isJSNumber(ref)) {
    // TODO: This always returns `double`, which I think is different than the
    // native converter.
    return js.toDartNumber(ref);
  } else if (js.isJSBoolean(ref)) {
    return js.toDartBool(ref);
  } else {
    throw 'Weird JS object';
  }
}

@patch
class Utf8Decoder {
  @patch
  Converter<List<int>, T> fuse<T>(Converter<String, T> next) {
    return super.fuse(next);
  }
}

@patch
class JsonDecoder {
  @patch
  StringConversionSink startChunkedConversion(Sink<Object?> sink) {
    // return _JsonStringDecoderSink(this._reviver, sink);
    return _JsonDecoderSink(_reviver, sink);
  }
}

/// Implements the chunked conversion from a JSON string to its corresponding
/// object.
///
/// The sink only creates one object, but its input can be chunked.
// TODO(floitsch): don't accumulate everything before starting to decode.
class _JsonDecoderSink extends _StringSinkConversionSink<StringBuffer> {
  final Object? Function(Object? key, Object? value)? _reviver;
  final Sink<Object?> _sink;

  _JsonDecoderSink(this._reviver, this._sink) : super(StringBuffer(''));

  void close() {
    super.close();
    String accumulated = _stringSink.toString();
    _stringSink.clear();
    Object? decoded = _parseJson(accumulated, _reviver);
    _sink.add(decoded);
    _sink.close();
  }
}

@patch
class _Utf8Decoder {
  @patch
  _Utf8Decoder(this.allowMalformed) : _state = beforeBom;

  @patch
  String convertSingle(List<int> codeUnits, int start, int? maybeEnd) {
    final codeUnitsLength = codeUnits.length;
    final end = RangeError.checkValidRange(start, maybeEnd, codeUnitsLength);
    if (start == end) return "";

    if (codeUnits is JSUint8ArrayImpl) {
      JSStringImpl? decoded =
          decodeUtf8JS(codeUnits, start, end, allowMalformed);
      if (decoded != null) return decoded;
    }

    return convertGeneral(codeUnits, start, maybeEnd, true);
  }

  @patch
  String convertChunked(List<int> codeUnits, int start, int? maybeEnd) {
    return convertGeneral(codeUnits, start, maybeEnd, false);
  }
}

double _parseDouble(String source, int start, int end) =>
    double.parse(source.substring(start, end));
