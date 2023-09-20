// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show MappedIterable, ListIterable, patch;
import 'dart:_js_helper';
import 'dart:_js_types';
import 'dart:_wasm';
import 'dart:collection' show MapBase;
import 'dart:js_interop' hide JS, JSArray, JSObject, JSNumber, JSBoolean;
import 'dart:typed_data';

@patch
dynamic _parseJson(
    String source, Object? Function(Object? key, Object? value)? reviver) {
  WasmExternRef? parsed;
  try {
    parsed = JS<WasmExternRef?>('s => JSON.parse(s)', source.toExternRef);
  } catch (e) {
    throw FormatException(JS<String>('e => String(e)', e.toExternRef));
  }

  Object? parsedObject = JSValue.box(parsed);

  if (reviver == null) {
    return _convertJsonToDartLazy(parsedObject);
  } else {
    return _convertJsonToDart(parsedObject, reviver);
  }
}

/**
 * Walks the raw JavaScript value [json], replacing JavaScript Objects with
 * Maps. [json] is expected to be freshly allocated so elements can be replaced
 * in-place.
 */
Object? _convertJsonToDart(
    Object? json, Object? Function(Object? key, Object? value) reviver) {
  Object? walk(Object? o) {
    if (o is! JSValue) {
      throw 'Expected JSValue!';
    }

    final WasmExternRef? ref = o.toExternRef;

    if (ref.isNull) {
      return null;
    }

    if (isJSBoolean(ref)) {
      return (o as JSBoolean).toDart;
    }

    if (isJSNumber(ref)) {
      return (o as JSNumber).toDartDouble;
    }

    if (isJSString(ref)) {
      return JSStringImpl(ref);
    }

    // Iterate through JSArray and convert each entry.
    if (isJSArray(ref)) {
      final JSArray array = o as JSArray;
      final int arrayLength = _length(ref);
      for (int i = 0; i < arrayLength; i++) {
        final WasmExternRef? index = i.toJS.toExternRef;
        final JSValue? item = JSValue.box(_getProperty(ref, index));
        final JSValue? revivedItem = reviver(i, walk(item)) as JSValue?;
        _setProperty(ref, index, revivedItem?.toExternRef);
      }
      return array;
    }

    // Otherwise it is a plain object, so copy to a JSON map, so we process
    // and revive all entries recursively.
    final object = o as JSObject;
    final map = _JsonMap(object);
    final processed = map._processed;
    final keys = map._computeKeys();
    for (int i = 0; i < keys.length; i++) {
      final JSStringImpl key = keys[i] as JSStringImpl;
      final JSValue? item = JSValue.box(_getProperty(ref, key.toExternRef));
      final JSValue? revivedItem = reviver(key, item) as JSValue?;
      _setProperty(
          processed?.toExternRef, key.toExternRef, revivedItem?.toExternRef);
    }

    // Update the JSON map structure so future access is cheaper.
    map._original = processed; // Don't keep two objects around.
    return map;
  }

  return reviver(null, walk(json));
}

Object? _convertJsonToDartLazy(Object? o) {
  if (o is! JSValue) {
    throw 'Expected JSValue!';
  }

  WasmExternRef? ref = o.toExternRef;

  if (ref.isNull) {
    return null;
  }

  if (isJSBoolean(ref)) {
    return (o as JSBoolean).toDart;
  }

  if (isJSNumber(ref)) {
    return (o as JSNumber).toDartDouble;
  }

  if (isJSString(ref)) {
    return JSStringImpl(ref);
  }

  // Iterate through JSArray and convert each entry.
  if (isJSArray(ref)) {
    final JSArray array = o as JSArray;
    final int arrayLength = _length(ref);
    for (int i = 0; i < arrayLength; i++) {
      final WasmExternRef? index = i.toJS.toExternRef;
      final JSValue? item = JSValue.box(_getProperty(ref, index));
      final JSValue convertedItem = _convertJsonToDartLazy(item) as JSValue;
      _setProperty(ref, index, convertedItem.toExternRef);
    }
    return array;
  }

  return _JsonMap(o as JSObject);
}

class _JsonMap extends MapBase<String, Object?> {
  // The original JavaScript object remains unchanged until
  // the map is eventually upgraded, in which case we null it
  // out to reclaim the memory used by it.
  JSObject? _original;

  // We keep track of the map entries that we have already
  // processed by adding them to a separate JavaScript object.
  JSObject? _processed = JSValue.boxT<JSObject>(_newJavaScriptObject());

  List<String>? _keyData = null;
  Map<String, Object?>? _mapData = null;

  _JsonMap(this._original);

  Object? operator [](Object? key) {
    if (_isUpgraded) {
      return _upgradedMap[key];
    } else if (key is! String) {
      return null;
    } else {
      WasmExternRef? resultRef =
          _getStringProperty(_processed?.toExternRef, key);
      JSValue? result;
      if (_isUnprocessed(resultRef)) {
        result = _process(key);
      } else {
        // TODO maybe not?/
        result = JSValue.box(resultRef);
      }
      return result;
    }
  }

  int get length => _isUpgraded ? _upgradedMap.length : _computeKeys().length;

  bool get isEmpty => length == 0;
  bool get isNotEmpty => length > 0;

  Iterable<String> get keys {
    if (_isUpgraded) return _upgradedMap.keys;
    return _JsonMapKeyIterable(this);
  }

  Iterable<Object?> get values {
    if (_isUpgraded) return _upgradedMap.values;
    return MappedIterable(_computeKeys(), (each) => this[each]);
  }

  void operator []=(String key, Object? value) {
    if (_isUpgraded) {
      _upgradedMap[key] = value;
    } else if (containsKey(key)) {
      var processed = _processed;
      _setStringProperty(processed?.toExternRef, key, value?.toExternRef);
      var original = _original;
      if (!identical(original, processed)) {
        _setStringProperty(original?.toExternRef, key, null); // Reclaim memory.
      }
    } else {
      _upgrade()[key] = value;
    }
  }

  void addAll(Map<String, Object?> other) {
    other.forEach((key, value) {
      this[key] = value;
    });
  }

  bool containsValue(Object? value) {
    if (_isUpgraded) return _upgradedMap.containsValue(value);
    final keys = _computeKeys();
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      if (this[key] == value) return true;
    }
    return false;
  }

  bool containsKey(Object? key) {
    if (_isUpgraded) return _upgradedMap.containsKey(key);
    if (key is! String) return false;
    return _hasStringProperty(_original?.toExternRef, key);
  }

  Object? putIfAbsent(String key, Object? ifAbsent()) {
    if (containsKey(key)) return this[key];
    final value = ifAbsent();
    this[key] = value;
    return value;
  }

  Object? remove(Object? key) {
    if (!_isUpgraded && !containsKey(key)) return null;
    return _upgrade().remove(key);
  }

  void clear() {
    if (_isUpgraded) {
      _upgradedMap.clear();
    } else {
      if (_keyData != null) {
        // Clear the list of keys to make sure we force
        // a concurrent modification error if anyone is
        // currently iterating over it.
        _keyData!.clear();
      }
      _original = _processed = null;
      _keyData = [];
      _mapData = {};
    }
  }

  void forEach(void f(String key, Object? value)) {
    if (_isUpgraded) return _upgradedMap.forEach(f);
    final keys = _computeKeys();
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];

      // Compute the value under the assumption that the property
      // is present but potentially not processed.
      final WasmExternRef? originalValue =
          _getStringProperty(_processed?.toExternRef, key);
      Object? value;
      if (_isUnprocessed(originalValue)) {
        final valueRef = _getStringProperty(_original?.toExternRef, key);
        value = _convertJsonToDartLazy(JSValue.boxT<JSObject>(valueRef));
        _setStringProperty(_processed?.toExternRef, key, value?.toExternRef);
      }

      // Do the callback.
      f(key, value);

      // Check if invoking the callback function changed
      // the key set. If so, throw an exception.
      if (!identical(keys, _keyData)) {
        throw ConcurrentModificationError(this);
      }
    }
  }

  // ------------------------------------------
  // Private helper methods.
  // ------------------------------------------

  bool get _isUpgraded => _processed == null;

  Map<String, Object?> get _upgradedMap {
    assert(_isUpgraded);
    return _mapData!;
  }

  List<String> _computeKeys() {
    assert(!_isUpgraded);
    List<String>? keys = _keyData;
    if (keys == null) {
      keys = <String>[];
      final names =
          (JSValue.boxT<JSArray>(_getPropertyNames(_original?.toExternRef)))
              .toDart;
      for (final name in names) {
        keys.add(JSStringImpl(name?.toExternRef));
      }
      _keyData = keys;
    }
    return keys;
  }

  Map<String, Object?> _upgrade() {
    if (_isUpgraded) return _upgradedMap;

    // Copy all the (key, value) pairs to a freshly allocated
    // linked hash map thus preserving the ordering.
    final result = <String, Object?>{};
    final keys = _computeKeys();
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];
      result[key] = this[key];
    }

    // We only upgrade when we need to extend the map, so we can
    // safely force a concurrent modification error in case
    // someone is iterating over the map here.
    if (keys.isEmpty) {
      keys.add("");
    } else {
      keys.clear();
    }

    // Clear out the associated JavaScript objects and mark the
    // map as having been upgraded.
    _original = _processed = null;
    _mapData = result;
    assert(_isUpgraded);
    return result;
  }

  JSValue? _process(String key) {
    if (!_hasStringProperty(_original?.toExternRef, key)) {
      return null;
    }
    final Object? result = _convertJsonToDartLazy(
        JSValue.box(_getStringProperty(_original?.toExternRef, key)));
    return JSValue.box(
        _setStringProperty(_processed?.toExternRef, key, result?.toExternRef));
  }

  static bool _hasStringProperty(WasmExternRef? object, String key) =>
      _hasProperty(object, (key as JSStringImpl).toExternRef);

  static WasmExternRef? _getStringProperty(WasmExternRef? object, String key) =>
      _getProperty(object, (key as JSStringImpl).toExternRef);

  static WasmExternRef? _setStringProperty(
          WasmExternRef? object, String key, WasmExternRef? value) =>
      _setProperty(object, (key as JSStringImpl).toExternRef, value);
}

class _JsonMapKeyIterable extends ListIterable<String> {
  final _JsonMap _parent;

  _JsonMapKeyIterable(this._parent);

  int get length => _parent.length;

  String elementAt(int index) {
    return _parent._isUpgraded
        ? _parent.keys.elementAt(index)
        : _parent._computeKeys()[index];
  }

  /// Although [ListIterable] defines its own iterator, we return the iterator
  /// of the underlying list [_keys] in order to propagate
  /// [ConcurrentModificationError]s.
  Iterator<String> get iterator {
    return _parent._isUpgraded
        ? _parent.keys.iterator
        : _parent._computeKeys().iterator;
  }

  /// Delegate to [parent.containsKey] to ensure the performance expected
  /// from [Map.keys.containsKey].
  bool contains(Object? key) => _parent.containsKey(key);
}

@patch
class JsonDecoder {
  @patch
  StringConversionSink startChunkedConversion(Sink<Object?> sink) {
    return _JsonDecoderSink(_reviver, sink);
  }
}

/**
 * Implements the chunked conversion from a JSON string to its corresponding
 * object.
 *
 * The sink only creates one object, but its input can be chunked.
 */
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
class Utf8Decoder {
  // Always fall back to the Dart implementation for strings shorter than this
  // threshold, as there is a large, constant overhead for using TextDecoder.
  static const int _shortInputThreshold = 15;

  @patch
  Converter<List<int>, T> fuse<T>(Converter<String, T> next) {
    return super.fuse(next);
  }

  // Currently not intercepting UTF8 decoding.
  @patch
  static String? _convertIntercepted(
      bool allowMalformed, List<int> codeUnits, int start, int? end) {
    // Test `codeUnits is Uint8List`. Dart's Uint8List is
    // implemented by JavaScript's Uint8Array.
    if (codeUnits is Uint8List) {
      final casted = codeUnits as JSUint8ArrayImpl;
      // Always use Dart implementation for short strings.
      end ??= casted.length;
      if (end - start < _shortInputThreshold) {
        return null;
      }
      String? result =
          _convertInterceptedUint8List(allowMalformed, casted, start, end);
      if (result != null && allowMalformed) {
        // In principle, TextDecoder should have provided the correct result
        // here, but some browsers deviate from the standard as to how many
        // replacement characters they produce. Thus, we fall back to the Dart
        // implementation if the result contains any replacement characters.
        if (JS<bool>("s => s.indexOf('\uFFFD') >= 0",
            (result as JSStringImpl).toExternRef)) {
          return null;
        }
      }
      return result;
    }
    return null; // This call was not intercepted.
  }

  static String? _convertInterceptedUint8List(
      bool allowMalformed, JSUint8ArrayImpl codeUnits, int start, int end) {
    return null;
    /*
    final WasmExternRef? decoder;
    if (allowMalformed) {
      decoder =
          JS<WasmExternRef>('_ => new TextDecoder("utf-8", {fatal: false})');
    } else {
      decoder =
          JS<WasmExternRef>('_ => new TextDecoder("utf-8", {fatal: true})');
    }

    if (0 == start && end == codeUnits.length) {
      return JS<String>(
          '(d, c) => d.decode(c)', decoder, codeUnits.toExternRef);
    }

    final length = codeUnits.length;
    end = RangeError.checkValidRange(start, end, length);

    return JS<String>('(d, c) => d.decode(c)', decoder, codeUnits.toExternRef);
    */

    /*
    TODO(omersa): Closures returning externref aren't compiled right.

    final decoder = allowMalformed ? _decoderNonfatal : _decoder;
    if (decoder == WasmExternRef.nullRef) return null;
    if (0 == start && end == codeUnits.length) {
      return _useTextDecoder(decoder, codeUnits);
    }

    final length = codeUnits.length;
    end = RangeError.checkValidRange(start, end, length);

    return _useTextDecoder(
        decoder,
        JSUint8ArrayImpl(JS<WasmExternRef?>('(a, s, e) => a.subarray(s, e)',
            codeUnits.toExternRef, start.toDouble(), end.toDouble())));
    */
  }

  /*
  static String? _useTextDecoder(
      WasmExternRef? decoder, JSUint8ArrayImpl codeUnits) {
    // If the input is malformed, catch the exception and return `null` to fall
    // back on unintercepted decoder. The fallback will either succeed in
    // decoding, or report the problem better than TextDecoder.
    try {
      return JS<String>(
          '(d, c) => d.decode(c)', decoder, codeUnits.toExternRef);
    } catch (e) {}
    return null;
  }

  // TextDecoder is not defined on some browsers and on the stand-alone d8 and
  // jsshell engines. Use a lazy initializer to do feature detection once.
  static final WasmExternRef? _decoder = () {
    try {
      return JS<WasmExternRef?>('_ => new TextDecoder("utf-8", {fatal: true})');
    } catch (e) {}
    return WasmExternRef.nullRef;
  }();

  static final WasmExternRef? _decoderNonfatal = () {
    try {
      return JS<WasmExternRef?>(
          '_ => new TextDecoder("utf-8", {fatal: false})');
    } catch (e) {}
    return WasmExternRef.nullRef;
  }();
  */
}

@patch
class _Utf8Decoder {
  @patch
  _Utf8Decoder(this.allowMalformed) : _state = beforeBom;

  @patch
  String convertSingle(List<int> codeUnits, int start, int? maybeEnd) {
    return convertGeneral(codeUnits, start, maybeEnd, true);
  }

  @patch
  String convertChunked(List<int> codeUnits, int start, int? maybeEnd) {
    return convertGeneral(codeUnits, start, maybeEnd, false);
  }
}

// JS helper methods
// TODO use methods in JS helper
bool _hasProperty(WasmExternRef? object, WasmExternRef? key) => JS<bool>(
    '(o, k) => Object.prototype.hasOwnProperty.call(o, k)', object, key);

WasmExternRef? _getProperty(WasmExternRef? object, WasmExternRef? key) =>
    JS<WasmExternRef?>('(o, k) => o[k]', object, key);

WasmExternRef? _setProperty(
        WasmExternRef? object, WasmExternRef? key, WasmExternRef? value) =>
    JS<WasmExternRef>('(o, k, v) => o[k] = v', object, key, value);

WasmExternRef? _getPropertyNames(WasmExternRef? object) =>
    JS<WasmExternRef?>('o => Object.keys(o)', object);

bool _isUnprocessed(WasmExternRef? object) => isJSUndefined(object);

WasmExternRef? _newJavaScriptObject() =>
    JS<WasmExternRef?>('_ => Object.create(null)');

int _length(WasmExternRef? a) => JS<double>('a => a.length', a).toInt();
