// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_types;

final class JSArrayBufferImpl implements ByteBuffer {
  /// `externref` of a JS `ArrayBuffer`.
  final WasmExternRef? _ref;

  JSArrayBufferImpl(this._ref);

  WasmExternRef? get toExternRef => _ref;

  WasmExternRef? view(int offsetInBytes, int? length) =>
      _newDataView(toExternRef, offsetInBytes, length);

  @override
  int get lengthInBytes => _byteLength(toExternRef);

  @override
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) =>
      JSUint8ArrayImpl.view(this, offsetInBytes, length);

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) =>
      JSInt8ArrayImpl.view(this, offsetInBytes, length);

  @override
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) =>
      JSUint8ClampedArrayImpl.view(this, offsetInBytes, length);

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) =>
      JSUint16ArrayImpl.view(this, offsetInBytes, length);

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) =>
      JSInt16ArrayImpl.view(this, offsetInBytes, length);

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) =>
      JSUint32ArrayImpl.view(this, offsetInBytes, length);

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) =>
      JSInt32ArrayImpl.view(this, offsetInBytes, length);

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) =>
      JSBigUint64ArrayImpl.view(this, offsetInBytes, length);

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) =>
      JSBigInt64ArrayImpl.view(this, offsetInBytes, length);

  @override
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Int32x4List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Int32x4List.bytesPerElement;
    final storage = JSInt32ArrayImpl.view(this, offsetInBytes, length * 4);
    return JSInt32x4ArrayImpl.externalStorage(storage);
  }

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) =>
      JSFloat32ArrayImpl.view(this, offsetInBytes, length);

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) =>
      JSFloat64ArrayImpl.view(this, offsetInBytes, length);

  @override
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Float32x4List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Float32x4List.bytesPerElement;
    final storage = JSFloat32ArrayImpl.view(this, offsetInBytes, length * 4);
    return JSFloat32x4ArrayImpl.externalStorage(storage);
  }

  @override
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Float64x2List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Float64x2List.bytesPerElement;
    final storage = JSFloat64ArrayImpl.view(this, offsetInBytes, length * 2);
    return JSFloat64x2ArrayImpl.externalStorage(storage);
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) =>
      JSDataViewImpl.view(this, offsetInBytes, length);

  @override
  bool operator ==(Object that) =>
      that is JSArrayBufferImpl && js.areEqualInJS(_ref, that._ref);
}

final class JSArrayBufferViewImpl implements TypedData {
  /// `externref` of a JS `DataView` or a typed array (in subclasses).
  final WasmExternRef? _ref;

  JSArrayBufferViewImpl(this._ref);

  WasmExternRef? get toExternRef => _ref;

  @override
  JSArrayBufferImpl get buffer =>
      JSArrayBufferImpl(js.JS<WasmExternRef?>('o => o.buffer', toExternRef));

  @override
  int get lengthInBytes => _byteLength(toExternRef);

  @override
  int get offsetInBytes =>
      js.JS<double>('o => o.byteOffset', toExternRef).toInt();

  @override
  int get elementSizeInBytes => 1;

  @override
  bool operator ==(Object that) =>
      that is JSArrayBufferViewImpl && js.areEqualInJS(_ref, that._ref);
}

final class JSDataViewImpl extends JSArrayBufferViewImpl implements ByteData {
  JSDataViewImpl(super._ref);

  factory JSDataViewImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSDataViewImpl(_newDataView(buffer.toExternRef, offsetInBytes, length));

  @override
  int get elementSizeInBytes => 1;

  @override
  double getFloat32(int byteOffset, [Endian endian = Endian.big]) =>
      _getFloat32(toExternRef, byteOffset, Endian.little == endian);

  @override
  double getFloat64(int byteOffset, [Endian endian = Endian.big]) =>
      _getFloat64(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt16(int byteOffset, [Endian endian = Endian.big]) =>
      _getInt16(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt32(int byteOffset, [Endian endian = Endian.big]) =>
      _getInt32(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt64(int byteOffset, [Endian endian = Endian.big]) =>
      _getBigInt64(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt8(int byteOffset) => _getInt8(toExternRef, byteOffset);

  @override
  int getUint16(int byteOffset, [Endian endian = Endian.big]) =>
      _getUint16(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getUint32(int byteOffset, [Endian endian = Endian.big]) =>
      _getUint32(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getUint64(int byteOffset, [Endian endian = Endian.big]) =>
      _getBigUint64(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getUint8(int byteOffset) => _getUint8(toExternRef, byteOffset);

  @override
  void setFloat32(int byteOffset, num value, [Endian endian = Endian.big]) =>
      _setFloat32(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setFloat64(int byteOffset, num value, [Endian endian = Endian.big]) =>
      _setFloat64(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setInt16(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setInt32(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setBigInt64(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setInt8(int byteOffset, int value) =>
      _setInt8(toExternRef, byteOffset, value);

  @override
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setUint16(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setUint32(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setBigUint64(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setUint8(int byteOffset, int value) =>
      _setUint8(toExternRef, byteOffset, value);
}

abstract class JSIntArrayImpl extends JSArrayBufferViewImpl
    with ListMixin<int>, FixedLengthListMixin<int> {
  JSIntArrayImpl(super._ref);
  @override
  void setAll(int index, Iterable<int> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<int> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    List<int> otherList = iterable.skip(skipCount).toList(growable: false);

    int count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    _copy(otherList, 0, this, start, count);
  }
}

void _copy(List src, int srcStart, List dst, int dstStart, int count) {
  for (int i = srcStart, j = dstStart; i < srcStart + count; i++, j++) {
    dst[j] = src[i];
  }
}

final class JSUint8ArrayImpl extends JSIntArrayImpl implements Uint8List {
  JSUint8ArrayImpl(super._ref);

  factory JSUint8ArrayImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSUint8ArrayImpl(buffer.view(offsetInBytes, length));

  @override
  int get elementSizeInBytes => 1;

  @override
  int get length => lengthInBytes;

  @override
  int operator [](int index) {
    IndexError.check(index, length);
    return _getUint8(toExternRef, index);
  }

  @override
  void operator []=(int index, int value) {
    IndexError.check(index, length);
    _setUint8(toExternRef, index, value);
  }

  @override
  Uint8List sublist(int start, [int? end]) {
    final newOffset = offsetInBytes + start;
    final newEnd = end ?? lengthInBytes;
    final newLength = newEnd - newOffset;
    return JSUint8ArrayImpl(buffer.view(newOffset, newLength));
  }
}

final class JSInt8ArrayImpl extends JSIntArrayImpl implements Int8List {
  JSInt8ArrayImpl(super._ref);

  factory JSInt8ArrayImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSInt8ArrayImpl(buffer.view(offsetInBytes, length));

  @override
  int get elementSizeInBytes => 1;

  @override
  int get length => lengthInBytes;

  @override
  int operator [](int index) {
    IndexError.check(index, length);
    return _getInt8(toExternRef, index);
  }

  @override
  void operator []=(int index, int value) {
    IndexError.check(index, length);
    _setInt8(toExternRef, index, value);
  }

  @override
  Int8List sublist(int start, [int? end]) {
    final newOffset = offsetInBytes + start;
    final newEnd = end ?? lengthInBytes;
    final newLength = newEnd - newOffset;
    return JSInt8ArrayImpl(buffer.view(newOffset, newLength));
  }
}

final class JSUint8ClampedArrayImpl extends JSIntArrayImpl
    implements Uint8ClampedList {
  JSUint8ClampedArrayImpl(super._ref);

  factory JSUint8ClampedArrayImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSUint8ClampedArrayImpl(buffer.view(offsetInBytes, length));

  @override
  int get elementSizeInBytes => 1;

  @override
  int get length => lengthInBytes;

  @override
  int operator [](int index) {
    IndexError.check(index, length);
    return _getUint8(toExternRef, index);
  }

  @override
  void operator []=(int index, int value) {
    IndexError.check(index, length);
    _setUint8(toExternRef, index, value.clamp(0, 255));
  }

  @override
  Uint8ClampedList sublist(int start, [int? end]) {
    final newOffset = offsetInBytes + start;
    final newEnd = end ?? lengthInBytes;
    final newLength = newEnd - newOffset;
    return JSUint8ClampedArrayImpl(buffer.view(newOffset, newLength));
  }
}

final class JSUint16ArrayImpl extends JSIntArrayImpl implements Uint16List {
  JSUint16ArrayImpl(super._ref);

  factory JSUint16ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint16List.bytesPerElement);
    final lengthInBytes =
        (length == null ? buffer.lengthInBytes - offsetInBytes : length * 2);
    return JSUint16ArrayImpl(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  int get elementSizeInBytes => 2;

  @override
  int get lengthInBytes => (super.lengthInBytes ~/ 2) * 2;

  @override
  int get length => lengthInBytes ~/ 2;

  @override
  int operator [](int index) {
    IndexError.check(index, length);
    return _getUint16(toExternRef, index * 2, true);
  }

  @override
  void operator []=(int index, int value) {
    IndexError.check(index, length);
    _setUint16(toExternRef, index * 2, value, true);
  }

  @override
  Uint16List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSUint16ArrayImpl.view(buffer, start * 2, stop - start);
  }
}

final class JSInt16ArrayImpl extends JSIntArrayImpl implements Int16List {
  JSInt16ArrayImpl(super._ref);

  factory JSInt16ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int16List.bytesPerElement);
    final lengthInBytes =
        (length == null ? buffer.lengthInBytes - offsetInBytes : length * 2);
    return JSInt16ArrayImpl(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  int get elementSizeInBytes => 2;

  @override
  int get lengthInBytes => (super.lengthInBytes ~/ 2) * 2;

  @override
  int get length => lengthInBytes ~/ 2;

  @override
  int operator [](int index) {
    IndexError.check(index, length);
    return _getInt16(toExternRef, index * 2, true);
  }

  @override
  void operator []=(int index, int value) {
    IndexError.check(index, length);
    _setInt16(toExternRef, index * 2, value, true);
  }

  @override
  Int16List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSInt16ArrayImpl.view(buffer, start * 2, stop - start);
  }
}

final class JSUint32ArrayImpl extends JSIntArrayImpl implements Uint32List {
  JSUint32ArrayImpl(super._ref);

  factory JSUint32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint32List.bytesPerElement);
    final lengthInBytes =
        (length == null ? buffer.lengthInBytes - offsetInBytes : length * 4);
    return JSUint32ArrayImpl(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  int get elementSizeInBytes => 4;

  @override
  int get lengthInBytes => (super.lengthInBytes ~/ 4) * 4;

  @override
  int get length => lengthInBytes ~/ 4;

  @override
  int operator [](int index) {
    IndexError.check(index, length);
    return _getUint32(toExternRef, index * 4, true);
  }

  @override
  void operator []=(int index, int value) {
    IndexError.check(index, length);
    _setUint32(toExternRef, index * 4, value, true);
  }

  @override
  Uint32List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSUint32ArrayImpl.view(buffer, start * 4, stop - start);
  }
}

final class JSInt32ArrayImpl extends JSIntArrayImpl implements Int32List {
  JSInt32ArrayImpl(super._ref);

  @override
  int get lengthInBytes => (super.lengthInBytes ~/ 4) * 4;

  @override
  int get length => lengthInBytes ~/ 4;

  factory JSInt32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int32List.bytesPerElement);
    final lengthInBytes =
        (length == null ? buffer.lengthInBytes - offsetInBytes : length * 4);
    return JSInt32ArrayImpl(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  int get elementSizeInBytes => 4;

  @override
  int operator [](int index) {
    IndexError.check(index, length);
    return _getInt32(toExternRef, index * 4, true);
  }

  @override
  void operator []=(int index, int value) {
    IndexError.check(index, length);
    _setInt32(toExternRef, index * 4, value, true);
  }

  @override
  Int32List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSInt32ArrayImpl.view(buffer, start * 4, stop - start);
  }
}

final class JSInt32x4ArrayImpl
    with ListMixin<Int32x4>, FixedLengthListMixin<Int32x4>
    implements Int32x4List {
  final JSInt32ArrayImpl _storage;

  JSInt32x4ArrayImpl.externalStorage(JSInt32ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Int32x4List.bytesPerElement;

  @override
  int get length => _storage.length ~/ 4;

  @override
  Int32x4 operator [](int index) {
    IndexError.check(index, length);
    int _x = _storage[(index * 4) + 0];
    int _y = _storage[(index * 4) + 1];
    int _z = _storage[(index * 4) + 2];
    int _w = _storage[(index * 4) + 3];
    return Int32x4(_x, _y, _z, _w);
  }

  @override
  void operator []=(int index, Int32x4 value) {
    IndexError.check(index, length);
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  @override
  Int32x4List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSInt32x4ArrayImpl.externalStorage(
        _storage.sublist(start * 4, stop * 4) as JSInt32ArrayImpl);
  }

  @override
  void setAll(int index, Iterable<Int32x4> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<Int32x4> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    List<Int32x4> otherList = iterable.skip(skipCount).toList(growable: false);

    int count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    _copy(otherList, 0, this, start, count);
  }
}

abstract class JSBigIntArrayImpl extends JSIntArrayImpl {
  JSBigIntArrayImpl(super._ref);

  @override
  int get elementSizeInBytes => 8;
}

final class JSBigUint64ArrayImpl extends JSBigIntArrayImpl
    implements Uint64List {
  JSBigUint64ArrayImpl(super._ref);

  @override
  int get lengthInBytes => (super.lengthInBytes ~/ 8) * 8;

  @override
  int get length => lengthInBytes ~/ 8;

  factory JSBigUint64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint64List.bytesPerElement);
    final lengthInBytes =
        (length == null ? buffer.lengthInBytes - offsetInBytes : length * 8);
    return JSBigUint64ArrayImpl(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  int operator [](int index) {
    IndexError.check(index, length);
    return _getBigUint64(toExternRef, index * 8, true);
  }

  @override
  void operator []=(int index, int value) {
    IndexError.check(index, length);
    return _setBigUint64(toExternRef, index * 8, value, true);
  }

  @override
  Uint64List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSBigUint64ArrayImpl.view(buffer, start * 8, stop - start);
  }
}

final class JSBigInt64ArrayImpl extends JSBigIntArrayImpl implements Int64List {
  JSBigInt64ArrayImpl(super._ref);

  @override
  int get lengthInBytes => (super.lengthInBytes ~/ 8) * 8;

  @override
  int get length => lengthInBytes ~/ 8;

  factory JSBigInt64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int64List.bytesPerElement);
    final lengthInBytes =
        (length == null ? buffer.lengthInBytes - offsetInBytes : length * 8);
    return JSBigInt64ArrayImpl(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  int operator [](int index) {
    IndexError.check(index, length);
    return _getBigInt64(toExternRef, index * 8, true);
  }

  @override
  void operator []=(int index, int value) {
    IndexError.check(index, length);
    _setBigInt64(toExternRef, index * 8, value, true);
  }

  @override
  Int64List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSBigInt64ArrayImpl.view(buffer, start * 8, stop - start);
  }
}

abstract class JSFloatArrayImpl extends JSArrayBufferViewImpl
    with ListMixin<double>, FixedLengthListMixin<double> {
  JSFloatArrayImpl(super._ref);
  @override
  void setAll(int index, Iterable<double> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<double> iterable,
      [int skipCount = 0]) {
    int count = end - start;
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    int sourceLength = iterable.length;
    if (sourceLength - skipCount < count) {
      throw IterableElementError.tooFew();
    }

    if (iterable is JSArrayBufferViewImpl) {
      _setRangeFast(this, start, end, count, iterable as JSArrayBufferViewImpl,
          sourceLength, skipCount);
    } else {
      List<double> otherList;
      int otherStart;
      if (iterable is List<double>) {
        otherList = iterable;
        otherStart = skipCount;
      } else {
        otherList = iterable.skip(skipCount).toList(growable: false);
        otherStart = 0;
      }
      Lists.copy(otherList, otherStart, this, start, count);
    }
  }
}

final class JSFloat32ArrayImpl extends JSFloatArrayImpl implements Float32List {
  JSFloat32ArrayImpl(super._ref);

  @override
  int get lengthInBytes => (super.lengthInBytes ~/ 4) * 4;

  @override
  int get length => lengthInBytes ~/ 4;

  @override
  int get elementSizeInBytes => 4;

  factory JSFloat32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Float32List.bytesPerElement);
    final lengthInBytes =
        (length == null ? buffer.lengthInBytes - offsetInBytes : length * 4);
    return JSFloat32ArrayImpl(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  double operator [](int index) {
    IndexError.check(index, length);
    return _getFloat32(toExternRef, index * 4, true);
  }

  @override
  void operator []=(int index, double value) {
    IndexError.check(index, length);
    _setFloat32(toExternRef, index * 4, value, true);
  }

  @override
  Float32List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSFloat32ArrayImpl.view(buffer, start * 4, stop - start);
  }

  @override
  void setRange(int start, int end, Iterable<double> iterable,
      [int skipCount = 0]) {
    int count = end - start;
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) throw ArgumentError(skipCount);

    List<double> otherList = iterable.skip(skipCount).toList(growable: false);
    int otherStart = 0;
    _copy(otherList, otherStart, this, start, count);
  }
}

final class JSFloat64ArrayImpl extends JSFloatArrayImpl implements Float64List {
  JSFloat64ArrayImpl(super._ref);

  @override
  int get lengthInBytes => (super.lengthInBytes ~/ 8) * 8;

  @override
  int get length => lengthInBytes ~/ 8;

  @override
  int get elementSizeInBytes => 8;

  factory JSFloat64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Float64List.bytesPerElement);
    final lengthInBytes =
        (length == null ? buffer.lengthInBytes - offsetInBytes : length * 8);
    return JSFloat64ArrayImpl(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  double operator [](int index) {
    IndexError.check(index, length);
    return _getFloat64(toExternRef, index * 8, true);
  }

  @override
  void operator []=(int index, double value) {
    IndexError.check(index, length);
    _setFloat64(toExternRef, index * 8, value, true);
  }

  @override
  Float64List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSFloat64ArrayImpl.view(buffer, start * 8, stop - start);
  }
}

final class JSFloat32x4ArrayImpl
    with ListMixin<Float32x4>, FixedLengthListMixin<Float32x4>
    implements Float32x4List {
  final JSFloat32ArrayImpl _storage;

  JSFloat32x4ArrayImpl.externalStorage(JSFloat32ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Float32x4List.bytesPerElement;

  @override
  int get length => _storage.length ~/ 4;

  @override
  Float32x4 operator [](int index) {
    IndexError.check(index, length);
    double _x = _storage[(index * 4) + 0];
    double _y = _storage[(index * 4) + 1];
    double _z = _storage[(index * 4) + 2];
    double _w = _storage[(index * 4) + 3];
    return Float32x4(_x, _y, _z, _w);
  }

  @override
  void operator []=(int index, Float32x4 value) {
    IndexError.check(index, length);
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  @override
  Float32x4List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSFloat32x4ArrayImpl.externalStorage(
        _storage.sublist(start * 4, stop * 4) as JSFloat32ArrayImpl);
  }

  @override
  void setAll(int index, Iterable<Float32x4> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<Float32x4> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    List<Float32x4> otherList =
        iterable.skip(skipCount).toList(growable: false);

    int count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    _copy(otherList, 0, this, start, count);
  }
}

final class JSFloat64x2ArrayImpl
    with ListMixin<Float64x2>, FixedLengthListMixin<Float64x2>
    implements Float64x2List {
  final JSFloat64ArrayImpl _storage;

  JSFloat64x2ArrayImpl.externalStorage(JSFloat64ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Float64x2List.bytesPerElement;

  @override
  int get length => _storage.length ~/ 2;

  @override
  Float64x2 operator [](int index) {
    IndexError.check(index, length);
    double _x = _storage[(index * 2) + 0];
    double _y = _storage[(index * 2) + 1];
    return Float64x2(_x, _y);
  }

  @override
  void operator []=(int index, Float64x2 value) {
    IndexError.check(index, length);
    _storage[(index * 2) + 0] = value.x;
    _storage[(index * 2) + 1] = value.y;
  }

  @override
  Float64x2List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSFloat64x2ArrayImpl.externalStorage(
        _storage.sublist(start * 2, stop * 2) as JSFloat64ArrayImpl);
  }

  @override
  void setAll(int index, Iterable<Float64x2> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<Float64x2> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    List<Float64x2> otherList =
        iterable.skip(skipCount).toList(growable: false);

    int count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    _copy(otherList, 0, this, start, count);
  }
}

void _setRangeFast(JSArrayBufferViewImpl target, int start, int end, int count,
    JSArrayBufferViewImpl source, int sourceLength, int skipCount) {
  WasmExternRef? jsSource;
  if (skipCount != 0 || sourceLength != count) {
    // Create a view of the exact subrange that is copied from the source.
    jsSource = js.JS<WasmExternRef?>(
        '(s, k, e) => s.subarray(k, e)',
        source.toExternRef,
        skipCount.toDouble(),
        (skipCount + count).toDouble());
  } else {
    jsSource = source.toExternRef;
  }
  js.JS<void>('(t, s, i) => t.set(s, i)', target.toExternRef, jsSource,
      start.toDouble());
}

void _offsetAlignmentCheck(int offset, int alignment) {
  if ((offset % alignment) != 0) {
    throw new RangeError('Offset ($offset) must be a multiple of '
        'bytesPerElement ($alignment)');
  }
}

int _byteLength(WasmExternRef? ref) =>
    js.JS<double>('o => o.byteLength', ref).toInt();

WasmExternRef? _newDataView(
        WasmExternRef? ref, int offsetInBytes, int? length) =>
    length == null
        ? js.JS<WasmExternRef?>(
            '(b, o) => new DataView(b, o)', ref, offsetInBytes.toDouble())
        : js.JS<WasmExternRef?>('(b, o, l) => new DataView(b, o, l)', ref,
            offsetInBytes.toDouble(), length.toDouble());

int _getUint8(WasmExternRef? ref, int byteOffset) => js
    .JS<double>('(o, i) => o.getUint8(i)', ref, byteOffset.toDouble())
    .toInt();

void _setUint8(WasmExternRef? ref, int byteOffset, int value) => js.JS<void>(
    '(o, i, v) => o.setUint8(i, v)',
    ref,
    byteOffset.toDouble(),
    value.toDouble());

int _getInt8(WasmExternRef? ref, int byteOffset) =>
    js.JS<double>('(o, i) => o.getInt8(i)', ref, byteOffset.toDouble()).toInt();

void _setInt8(WasmExternRef? ref, int byteOffset, int value) => js.JS<void>(
    '(o, i, v) => o.setInt8(i, v)',
    ref,
    byteOffset.toDouble(),
    value.toDouble());

int _getUint16(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<double>('(o, i, e) => o.getUint16(i, e)', ref, byteOffset.toDouble(),
        littleEndian)
    .toInt();

void _setUint16(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>('(o, i, v, e) => o.setUint16(i, v, e)', ref,
        byteOffset.toDouble(), value.toDouble(), littleEndian);

int _getInt16(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<double>('(o, i, e) => o.getInt16(i, e)', ref, byteOffset.toDouble(),
        littleEndian)
    .toInt();

void _setInt16(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>('(o, i, v, e) => o.setInt16(i, v, e)', ref,
        byteOffset.toDouble(), value.toDouble(), littleEndian);

int _getUint32(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<double>('(o, i, e) => o.getUint32(i, e)', ref, byteOffset.toDouble(),
        littleEndian)
    .toInt();

void _setUint32(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>('(o, i, v, e) => o.setUint32(i, v, e)', ref,
        byteOffset.toDouble(), value.toDouble(), littleEndian);

int _getInt32(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<double>('(o, i, e) => o.getInt32(i, e)', ref, byteOffset.toDouble(),
        littleEndian)
    .toInt();

void _setInt32(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>('(o, i, v, e) => o.setInt32(i, v, e)', ref,
        byteOffset.toDouble(), value.toDouble(), littleEndian);

int _getBigUint64(WasmExternRef? ref, int byteOffset, bool littleEndian) =>
    js.JS<int>('(o, i, e) => o.getBigUint64(i, e)', ref, byteOffset.toDouble(),
        littleEndian);

void _setBigUint64(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>('(o, i, v, e) => o.setBigUint64(i, v, e)', ref,
        byteOffset.toDouble(), value, littleEndian);

int _getBigInt64(WasmExternRef? ref, int byteOffset, bool littleEndian) =>
    js.JS<int>('(o, i, e) => o.getBigInt64(i, e)', ref, byteOffset.toDouble(),
        littleEndian);

void _setBigInt64(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>('(o, i, v, e) => o.setBigInt64(i, v, e)', ref,
        byteOffset.toDouble(), value, littleEndian);

double _getFloat32(WasmExternRef? ref, int byteOffset, bool littleEndian) =>
    js.JS<double>('(b, o, e) => b.getFloat32(o, e)', ref, byteOffset.toDouble(),
        littleEndian);

void _setFloat32(
        WasmExternRef? ref, int byteOffset, num value, bool littleEndian) =>
    js.JS<void>('(b, o, v, e) => b.setFloat32(o, v, e)', ref,
        byteOffset.toDouble(), value.toDouble(), littleEndian);

double _getFloat64(WasmExternRef? ref, int byteOffset, bool littleEndian) =>
    js.JS<double>('(b, o, e) => b.getFloat64(o, e)', ref, byteOffset.toDouble(),
        littleEndian);

void _setFloat64(
        WasmExternRef? ref, int byteOffset, num value, bool littleEndian) =>
    js.JS<void>('(b, o, v, e) => b.setFloat64(o, v, e)', ref,
        byteOffset.toDouble(), value.toDouble(), littleEndian);
