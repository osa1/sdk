// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show ClassID, patch;
import 'dart:_wasm';

@patch
abstract class _TypedListBase {
  @patch
  bool _setRange(int startInBytes, int lengthInBytes, _TypedListBase from,
      int startFromInBytes, int toCid, int fromCid) {
    // The way [_setRange] is called, both `this` and [from] are [_TypedList].
    _TypedList thisList = this as _TypedList;
    _TypedList fromList = from as _TypedList;
    bool shouldClamp = (toCid == ClassID.cidUint8ClampedList ||
            toCid == ClassID.cid_Uint8ClampedList ||
            toCid == ClassID.cidUint8ClampedArrayView) &&
        (fromCid == ClassID.cidInt8List ||
            fromCid == ClassID.cid_Int8List ||
            fromCid == ClassID.cidInt8ArrayView);
    // TODO(joshualitt): There are conditions where we can avoid the copy even
    // when the buffer is the same, i.e. if the ranges do not overlap, or we
    // could if the ranges overlap but the destination index is higher than the
    // source.
    bool needsCopy = thisList.buffer == fromList.buffer;
    if (shouldClamp) {
      if (needsCopy) {
        List<int> temp = List<int>.generate(lengthInBytes,
            (index) => fromList._getInt8(index + startFromInBytes));
        for (int i = 0; i < lengthInBytes; i++) {
          thisList._setUint8(i + startInBytes, temp[i].clamp(0, 255));
        }
      } else {
        for (int i = 0; i < lengthInBytes; i++) {
          thisList._setUint8(i + startInBytes,
              fromList._getInt8(i + startFromInBytes).clamp(0, 255));
        }
      }
    } else if (needsCopy) {
      List<int> temp = List<int>.generate(lengthInBytes,
          (index) => fromList._getInt8(index + startFromInBytes));
      for (int i = 0; i < lengthInBytes; i++) {
        thisList._setUint8(i + startInBytes, temp[i]);
      }
    } else {
      for (int i = 0; i < lengthInBytes; i++) {
        thisList._setUint8(
            i + startInBytes, fromList._getInt8(i + startFromInBytes));
      }
    }
    return true;
  }
}

@patch
abstract class _TypedList extends _TypedListBase {
  @patch
  Float32x4 _getFloat32x4(int offsetInBytes) {
    ByteData data = buffer.asByteData();
    return Float32x4(
        data.getFloat32(offsetInBytes + 0 * 4, Endian.host),
        data.getFloat32(offsetInBytes + 1 * 4, Endian.host),
        data.getFloat32(offsetInBytes + 2 * 4, Endian.host),
        data.getFloat32(offsetInBytes + 3 * 4, Endian.host));
  }

  @patch
  void _setFloat32x4(int offsetInBytes, Float32x4 value) {
    ByteData data = buffer.asByteData();
    data.setFloat32(offsetInBytes + 0 * 4, value.x, Endian.host);
    data.setFloat32(offsetInBytes + 1 * 4, value.y, Endian.host);
    data.setFloat32(offsetInBytes + 2 * 4, value.z, Endian.host);
    data.setFloat32(offsetInBytes + 3 * 4, value.w, Endian.host);
  }

  @patch
  Int32x4 _getInt32x4(int offsetInBytes) {
    ByteData data = buffer.asByteData();
    return Int32x4(
        data.getInt32(offsetInBytes + 0 * 4, Endian.host),
        data.getInt32(offsetInBytes + 1 * 4, Endian.host),
        data.getInt32(offsetInBytes + 2 * 4, Endian.host),
        data.getInt32(offsetInBytes + 3 * 4, Endian.host));
  }

  @patch
  void _setInt32x4(int offsetInBytes, Int32x4 value) {
    ByteData data = buffer.asByteData();
    data.setInt32(offsetInBytes + 0 * 4, value.x, Endian.host);
    data.setInt32(offsetInBytes + 1 * 4, value.y, Endian.host);
    data.setInt32(offsetInBytes + 2 * 4, value.z, Endian.host);
    data.setInt32(offsetInBytes + 3 * 4, value.w, Endian.host);
  }

  @patch
  Float64x2 _getFloat64x2(int offsetInBytes) {
    ByteData data = buffer.asByteData();
    return Float64x2(data.getFloat64(offsetInBytes + 0 * 8, Endian.host),
        data.getFloat64(offsetInBytes + 1 * 8, Endian.host));
  }

  @patch
  void _setFloat64x2(int offsetInBytes, Float64x2 value) {
    ByteData data = buffer.asByteData();
    data.setFloat64(offsetInBytes + 0 * 8, value.x, Endian.host);
    data.setFloat64(offsetInBytes + 1 * 8, value.y, Endian.host);
  }
}

abstract class _ByteBuffer2 extends ByteBuffer {
  int _getInt8(int offsetInBytes);

  void _setInt8(int offsetInBytes, int value);

  int _getUint8(int offsetInBytes);

  void _setUint8(int offsetInBytes, int value);

  int _getInt16(int offsetInBytes);

  void _setInt16(int offsetInBytes, int value);

  int _getUint16(int offsetInBytes);

  int _getInt32(int offsetInBytes);

  void _setInt32(int offsetInBytes, int value);

  int _getUint32(int offsetInBytes);

  void _setUint32(int offsetInBytes, int value);

  int _getInt64(int offsetInBytes);

  void _setInt64(int offsetInBytes, int value);

  int _getUint64(int offsetInBytes);

  void _setUint64(int offsetInBytes, int value);

  double _getFloat32(int offsetInBytes);

  void _setFloat32(int offsetInBytes, double value);

  double _getFloat64(int offsetInBytes);

  void _setFloat64(int offsetInBytes, double value);
}

final class _I64Buffer implements _ByteBuffer2 {
  final WasmIntArray<WasmI64> _data;

  _I64Buffer(this._data);

  _I64Buffer.newWithLength(int length) : _data = WasmIntArray(length);

  @override
  int get lengthInBytes => _data.length * 8;

  @override
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asUint8List';
  }

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asInt8List';
  }

  @override
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asUint8ClampedList';
  }

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asUint16List';
  }

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asInt16List';
  }

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asUint32List';
  }

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asInt32List';
  }

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asUint64List';
  }

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) {
    length ??= (this.lengthInBytes - offsetInBytes) ~/ 8;
    // TODO: range check
    return _Int64List2(this, offsetInBytes, length);
  }

  @override
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asInt32x4List';
  }

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asFloat32List';
  }

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asFloat64List';
  }

  @override
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asFloat32x4List';
  }

  @override
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asFloat64x2List';
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    throw '_I64Buffer.asByteData';
  }

  @override
  int _getInt8(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setInt8(int offsetInBytes, int value) {
    throw 'TODO';
  }

  @override
  int _getUint8(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setUint8(int offsetInBytes, int value) {
    throw 'TODO';
  }

  @override
  int _getInt16(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setInt16(int offsetInBytes, int value) {
    throw 'TODO';
  }

  @override
  int _getUint16(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  int _getInt32(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setInt32(int offsetInBytes, int value) {
    throw 'TODO';
  }

  @override
  int _getUint32(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setUint32(int offsetInBytes, int value) {
    throw 'TODO';
  }

  @override
  int _getInt64(int offsetInBytes) {
    if (offsetInBytes % 8 == 0) {
      return _data.readSigned(offsetInBytes ~/ 8);
    } else {
      throw 'TODO';
    }
  }

  @override
  void _setInt64(int offsetInBytes, int value) {
    if (offsetInBytes % 8 == 0) {
      return _data.write(offsetInBytes ~/ 8, value);
    } else {
      throw 'TODO';
    }
  }

  @override
  int _getUint64(int offsetInBytes) {
    if (offsetInBytes % 8 == 0) {
      return _data.readUnsigned(offsetInBytes ~/ 8);
    } else {
      throw 'TODO';
    }
  }

  @override
  void _setUint64(int offsetInBytes, int value) {
    if (offsetInBytes % 8 == 0) {
      return _data.write(offsetInBytes ~/ 8, value);
    } else {
      throw 'TODO';
    }
  }

  @override
  double _getFloat32(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setFloat32(int offsetInBytes, double value) {
    throw 'TODO';
  }

  @override
  double _getFloat64(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setFloat64(int offsetInBytes, double value) {
    throw 'TODO';
  }
}

final class _I32Buffer implements _ByteBuffer2 {
  final WasmIntArray<WasmI32> _data;

  _I32Buffer(this._data);

  _I32Buffer.newWithLength(int length) : _data = WasmIntArray(length);

  @override
  int get lengthInBytes => _data.length * 8;

  @override
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asUint8List';
  }

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asInt8List';
  }

  @override
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asUint8ClampedList';
  }

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asUint16List';
  }

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asInt16List';
  }

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asUint32List';
  }

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asInt32List';
  }

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asUint64List';
  }

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) {
    length ??= (this.lengthInBytes - offsetInBytes) ~/ 4;
    // TODO: range check
    return _Int64List2(this, offsetInBytes, length);
  }

  @override
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asInt32x4List';
  }

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asFloat32List';
  }

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asFloat64List';
  }

  @override
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asFloat32x4List';
  }

  @override
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asFloat64x2List';
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    throw '_I32Buffer.asByteData';
  }

  @override
  int _getInt8(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setInt8(int offsetInBytes, int value) {
    throw 'TODO';
  }

  @override
  int _getUint8(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setUint8(int offsetInBytes, int value) {
    throw 'TODO';
  }

  @override
  int _getInt16(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setInt16(int offsetInBytes, int value) {
    throw 'TODO';
  }

  @override
  int _getUint16(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  int _getInt32(int offsetInBytes) {
    if (offsetInBytes % 4 == 0) {
      return _data.readSigned(offsetInBytes ~/ 4);
    } else {
      throw 'TODO';
    }
  }

  @override
  void _setInt32(int offsetInBytes, int value) {
    if (offsetInBytes % 4 == 0) {
      _data.write(offsetInBytes ~/ 4, value);
    } else {
      throw 'TODO';
    }
  }

  @override
  int _getUint32(int offsetInBytes) {
    if (offsetInBytes % 4 == 0) {
      return _data.readUnsigned(offsetInBytes ~/ 4);
    } else {
      throw 'TODO';
    }
  }

  @override
  void _setUint32(int offsetInBytes, int value) {
    if (offsetInBytes % 4 == 0) {
      _data.write(offsetInBytes ~/ 4, value);
    } else {
      throw 'TODO';
    }
  }

  @override
  int _getInt64(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setInt64(int offsetInBytes, int value) {
    throw 'TODO';
  }

  @override
  int _getUint64(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setUint64(int offsetInBytes, int value) {
    throw 'TODO';
  }

  @override
  double _getFloat32(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setFloat32(int offsetInBytes, double value) {
    throw 'TODO';
  }

  @override
  double _getFloat64(int offsetInBytes) {
    throw 'TODO';
  }

  @override
  void _setFloat64(int offsetInBytes, double value) {
    throw 'TODO';
  }
}

mixin _TypedListCommonOperationsMixin {
  int get length;

  int get elementSizeInBytes;

  @override
  bool get isEmpty => length != 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  String join([String separator = ""]) {
    StringBuffer buffer = new StringBuffer();
    buffer.writeAll(this as Iterable, separator);
    return buffer.toString();
  }

  @override
  void clear() {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  bool remove(Object? element) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  void replaceRange(int start, int end, Iterable iterable) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  set length(int newLength) {
    throw new UnsupportedError("Cannot resize a fixed-length list");
  }
}

final class _Int64List2
    with
        _IntListMixin,
        _TypedIntListMixin<Int64List>,
        _TypedListCommonOperationsMixin
    implements Int64List {
  final _ByteBuffer2 _buffer;
  final int _offsetInBytes;
  final int _length;

  _Int64List2(this._buffer, this._offsetInBytes, this._length);

  @pragma("wasm:entry-point")
  factory _Int64List2._newWithLength(int length) =>
      _Int64List2(_I64Buffer.newWithLength(length), 0, length);

  @override
  int get length => _buffer.lengthInBytes ~/ elementSizeInBytes;

  @override
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _buffer._getInt64(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _buffer._setInt64(index, value);
  }

  @override
  _ByteBuffer get buffer =>
      throw 'Will be fixed when _ByteBuffer2 is renamed to _ByteBuffer';

  @override
  int get elementSizeInBytes => 8;

  @override
  int get lengthInBytes => _buffer.lengthInBytes;

  @override
  Int64List _createList(int length) {
    return _Int64List2._newWithLength(length);
  }

  @override
  int get offsetInBytes => _offsetInBytes;
}

final class _Int32List2
    with
        _IntListMixin,
        _TypedIntListMixin<Int32List>,
        _TypedListCommonOperationsMixin
    implements Int32List {
  final _ByteBuffer2 _buffer;
  final int _offsetInBytes;
  final int _length;

  _Int32List2(this._buffer, this._offsetInBytes, this._length);

  @pragma("wasm:entry-point")
  factory _Int32List2._newWithLength(int length) =>
      _Int32List2(_I32Buffer.newWithLength(length), 0, length);

  @override
  int get length => _buffer.lengthInBytes ~/ elementSizeInBytes;

  @override
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw new IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _buffer._getInt32(index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _buffer._setInt32(index, value);
  }

  @override
  _ByteBuffer get buffer =>
      throw 'Will be fixed when _ByteBuffer2 is renamed to _ByteBuffer';

  @override
  int get elementSizeInBytes => 8;

  @override
  int get lengthInBytes => _buffer.lengthInBytes;

  @override
  Int32List _createList(int length) {
    return _Int32List2._newWithLength(length);
  }

  @override
  int get offsetInBytes => _offsetInBytes;
}
