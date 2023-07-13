// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal'
    show
        ClassID,
        doubleToIntBits,
        ExpandIterable,
        floatToIntBits,
        FollowedByIterable,
        intBitsToDouble,
        intBitsToFloat,
        IterableElementError,
        ListMapView,
        Lists,
        MappedIterable,
        patch,
        ReversedListIterable,
        SkipWhileIterable,
        Sort,
        SubListIterable,
        TakeWhileIterable,
        WhereIterable,
        WhereTypeIterable;
import 'dart:_wasm';
import 'dart:math' show Random;

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

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Byte data
//
////////////////////////////////////////////////////////////////////////////////////////////////////

/// The base class for all [ByteData] implementations. This provides slow
/// implementations for get and set methods using abstract [getUint8] and
/// [setUint8] methods. Implementations should implement [getUint8] and
/// [setUint8], and override get/set methods for elements matching the buffer
/// element type to provide fast access.
abstract class _ByteData2 implements ByteData {
  final int offsetInBytes;
  final int lengthInBytes;

  _ByteData2(this.offsetInBytes, this.lengthInBytes);

  @override
  int getInt8(int byteOffset) {
    return getUint8(byteOffset).toSigned(8);
  }

  @override
  void setInt8(int byteOffset, int value) {
    setUint8(offsetInBytes + byteOffset, value.toUnsigned(8));
  }

  @override
  int getInt16(int byteOffset, [Endian endian = Endian.big]) {
    return getUint16(offsetInBytes + byteOffset, endian).toSigned(16);
  }

  @override
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) {
    setUint16(offsetInBytes + byteOffset, value.toUnsigned(16), endian);
  }

  @override
  int getUint16(int byteOffset, [Endian endian = Endian.big]) {
    byteOffset += offsetInBytes;
    final b1 = getUint8(byteOffset);
    final b2 = getUint8(byteOffset + 1);
    if (endian == Endian.little) {
      return (b2 << 8) | b1;
    } else {
      return (b1 << 8) | b2;
    }
  }

  @override
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) {
    byteOffset += offsetInBytes;
    final b1 = value & 0xFF;
    final b2 = (value >> 8) & 0xFF;
    if (endian == Endian.little) {
      setUint8(byteOffset, b1);
      setUint8(byteOffset + 1, b2);
    } else {
      setUint8(byteOffset, b2);
      setUint8(byteOffset + 1, b1);
    }
  }

  @override
  int getInt32(int byteOffset, [Endian endian = Endian.big]) {
    return getUint32(offsetInBytes + byteOffset, endian).toSigned(32);
  }

  @override
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) {
    setUint32(offsetInBytes + byteOffset, value.toUnsigned(32), endian);
  }

  @override
  int getUint32(int byteOffset, [Endian endian = Endian.big]) {
    byteOffset += offsetInBytes;
    final b1 = getUint8(byteOffset);
    final b2 = getUint8(byteOffset + 1);
    final b3 = getUint8(byteOffset + 2);
    final b4 = getUint8(byteOffset + 3);
    if (endian == Endian.little) {
      return (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
    } else {
      return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }
  }

  @override
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) {
    byteOffset += offsetInBytes;
    final b1 = value & 0xFF;
    final b2 = (value >> 8) & 0xFF;
    final b3 = (value >> 16) & 0xFF;
    final b4 = (value >> 24) & 0xFF;
    if (endian == Endian.little) {
      setUint8(byteOffset, b1);
      setUint8(byteOffset + 1, b2);
      setUint8(byteOffset + 2, b3);
      setUint8(byteOffset + 3, b4);
    } else {
      setUint8(byteOffset, b4);
      setUint8(byteOffset + 1, b3);
      setUint8(byteOffset + 2, b2);
      setUint8(byteOffset + 3, b1);
    }
  }

  @override
  int getInt64(int byteOffset, [Endian endian = Endian.big]) {
    return getUint64(offsetInBytes + byteOffset, endian);
  }

  @override
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) {
    setUint64(offsetInBytes + byteOffset, value, endian);
  }

  @override
  int getUint64(int byteOffset, [Endian endian = Endian.big]) {
    byteOffset += offsetInBytes;
    final b1 = getUint8(byteOffset);
    final b2 = getUint8(byteOffset + 1);
    final b3 = getUint8(byteOffset + 2);
    final b4 = getUint8(byteOffset + 3);
    final b5 = getUint8(byteOffset + 4);
    final b6 = getUint8(byteOffset + 5);
    final b7 = getUint8(byteOffset + 6);
    final b8 = getUint8(byteOffset + 7);
    if (endian == Endian.little) {
      return (b1 << 56) |
          (b2 << 48) |
          (b3 << 40) |
          (b4 << 32) |
          (b5 << 24) |
          (b6 << 16) |
          (b7 << 8) |
          b8;
    } else {
      return (b8 << 56) |
          (b7 << 48) |
          (b6 << 40) |
          (b5 << 32) |
          (b4 << 24) |
          (b3 << 16) |
          (b2 << 8) |
          b1;
    }
  }

  @override
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) {
    byteOffset += offsetInBytes;
    final b1 = value & 0xFF;
    final b2 = (value >> 8) & 0xFF;
    final b3 = (value >> 16) & 0xFF;
    final b4 = (value >> 24) & 0xFF;
    final b5 = (value >> 32) & 0xFF;
    final b6 = (value >> 40) & 0xFF;
    final b7 = (value >> 48) & 0xFF;
    final b8 = (value >> 56) & 0xFF;
    if (endian == Endian.little) {
      setUint8(byteOffset, b1);
      setUint8(byteOffset + 1, b2);
      setUint8(byteOffset + 2, b3);
      setUint8(byteOffset + 3, b4);
      setUint8(byteOffset + 4, b5);
      setUint8(byteOffset + 5, b6);
      setUint8(byteOffset + 6, b7);
      setUint8(byteOffset + 7, b8);
    } else {
      setUint8(byteOffset, b8);
      setUint8(byteOffset + 1, b7);
      setUint8(byteOffset + 2, b6);
      setUint8(byteOffset + 3, b5);
      setUint8(byteOffset + 4, b4);
      setUint8(byteOffset + 5, b3);
      setUint8(byteOffset + 6, b2);
      setUint8(byteOffset + 7, b1);
    }
  }

  @override
  double getFloat32(int byteOffset, [Endian endian = Endian.big]) {
    return intBitsToFloat(getUint32(offsetInBytes + byteOffset, endian));
  }

  @override
  void setFloat32(int byteOffset, double value, [Endian endian = Endian.big]) {
    setUint32(offsetInBytes + byteOffset, floatToIntBits(value), endian);
  }

  @override
  double getFloat64(int byteOffset, [Endian endian = Endian.big]) {
    return intBitsToDouble(getUint64(offsetInBytes + byteOffset, endian));
  }

  @override
  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]) {
    setUint64(offsetInBytes + byteOffset, doubleToIntBits(value), endian);
  }
}

class _I8ByteData2 extends _ByteData2 {
  final WasmIntArray<WasmI8> _data;

  _I8ByteData2._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  _I8ByteBuffer2 get buffer =>
      _I8ByteBuffer2(_data, offsetInBytes, lengthInBytes);

  @override
  int get elementSizeInBytes => Int8List.bytesPerElement;

  @override
  int getUint8(int byteOffset) {
    return _data.readUnsigned(offsetInBytes + byteOffset);
  }

  @override
  void setUint8(int byteOffset, int value) {
    _data.write(offsetInBytes + byteOffset, value.toUnsigned(8));
  }
}

class _I16ByteData2 extends _ByteData2 {
  final WasmIntArray<WasmI16> _data;

  _I16ByteData2._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  _I16ByteBuffer2 get buffer =>
      _I16ByteBuffer2(_data, offsetInBytes, lengthInBytes);

  @override
  int get elementSizeInBytes => Int16List.bytesPerElement;

  @override
  int getUint8(int byteOffset) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    return (_data.readUnsigned(byteIndex) >>
            (8 * (byteOffset % elementSizeInBytes))) &
        0xFF;
  }

  @override
  void setUint8(int byteOffset, int value) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    final element = _data.readUnsigned(byteIndex);
    final byteElementIndex = byteOffset % elementSizeInBytes;
    final b1 = byteElementIndex == 0 ? value : (element & 0xFF);
    final b2 = byteElementIndex == 1 ? value : (element >> 8);
    final newValue = (b2 << 8) & b1;
    _data.write(byteIndex, newValue);
  }

  @override
  int getUint16(int byteOffset, [Endian endian = Endian.big]) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    final elementLittleEndian = _data.readUnsigned(byteIndex);
    if (endian == Endian.little) {
      return elementLittleEndian;
    } else {
      return (((elementLittleEndian & 0xFF) << 8) | (elementLittleEndian >> 8));
    }
  }

  @override
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    if (endian == Endian.big) {
      value = (value & 0xFF) << 8 & (value >> 8);
    }
    _data.write(byteIndex, value);
  }
}

class _I32ByteData2 extends _ByteData2 {
  final WasmIntArray<WasmI32> _data;

  _I32ByteData2._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  _I32ByteBuffer2 get buffer =>
      _I32ByteBuffer2(_data, offsetInBytes, lengthInBytes);

  @override
  int get elementSizeInBytes => Int32List.bytesPerElement;

  @override
  int getUint8(int byteOffset) {
    throw 'TODO';
  }

  @override
  void setUint8(int byteOffset, int value) {
    throw 'TODO';
  }

  @override
  int getInt32(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int getUint32(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }
}

class _I64ByteData2 extends _ByteData2 {
  final WasmIntArray<WasmI64> _data;

  _I64ByteData2._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  _I64ByteBuffer2 get buffer =>
      _I64ByteBuffer2(_data, offsetInBytes, lengthInBytes);

  @override
  int get elementSizeInBytes => Int64List.bytesPerElement;

  @override
  int getUint8(int byteOffset) {
    throw 'TODO';
  }

  @override
  void setUint8(int byteOffset, int value) {
    throw 'TODO';
  }

  @override
  int getInt64(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int getUint64(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }
}

class _F32ByteData2 extends _ByteData2 {
  final WasmFloatArray<WasmF32> _data;

  _F32ByteData2._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  _F32ByteBuffer2 get buffer =>
      _F32ByteBuffer2(_data, offsetInBytes, lengthInBytes);

  @override
  int get elementSizeInBytes => Float32List.bytesPerElement;

  @override
  int getUint8(int byteOffset) {
    throw 'TODO';
  }

  @override
  void setUint8(int byteOffset, int value) {
    throw 'TODO';
  }

  @override
  double getFloat32(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setFloat32(int byteOffset, double value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }
}

class _F64ByteData2 extends _ByteData2 {
  final WasmFloatArray<WasmF64> _data;

  _F64ByteData2._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  _F64ByteBuffer2 get buffer =>
      _F64ByteBuffer2(_data, offsetInBytes, lengthInBytes);

  @override
  int get elementSizeInBytes => Float64List.bytesPerElement;

  @override
  int getUint8(int byteOffset) {
    throw 'TODO';
  }

  @override
  void setUint8(int byteOffset, int value) {
    throw 'TODO';
  }

  @override
  double getFloat64(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Byte buffers
//
////////////////////////////////////////////////////////////////////////////////////////////////////

/// Base class for [ByteBuffer] implementations. Returns slow lists in all
/// methods. Implementations should override relevant methods to return fast
/// lists when possible and implement [asByteData].
abstract class _ByteBufferBase extends ByteBuffer {
  final int offsetInBytes;
  final int lengthInBytes;

  _ByteBufferBase(this.offsetInBytes, this.lengthInBytes);

  @override
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint8List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint8List.bytesPerElement);
    return _SlowU8List._(this, offsetInBytes, length);
  }

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Int8List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int8List.bytesPerElement);
    return _SlowI8List._(this, offsetInBytes, length);
  }

  @override
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) {
    throw 'TODO';
  }

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint16List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint16List.bytesPerElement);
    return _SlowU16List._(this, offsetInBytes, length);
  }

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Int16List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int16List.bytesPerElement);
    return _SlowI16List._(this, offsetInBytes, length);
  }

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint32List.bytesPerElement);
    return _SlowU32List._(this, offsetInBytes, length);
  }

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Int32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int32List.bytesPerElement);
    return _SlowI32List._(this, offsetInBytes, length);
  }

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint64List.bytesPerElement);
    return _SlowU64List._(this, offsetInBytes, length);
  }

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Int64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int64List.bytesPerElement);
    return _SlowI64List._(this, offsetInBytes, length);
  }

  @override
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) {
    throw 'TODO';
  }

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Float32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Float32List.bytesPerElement);
    return _SlowF32List._(this, offsetInBytes, length);
  }

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Float64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Float64List.bytesPerElement);
    return _SlowF64List._(this, offsetInBytes, length);
  }

  @override
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) {
    throw 'TODO';
  }

  @override
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) {
    throw 'TODO';
  }
}

class _I8ByteBuffer2 extends _ByteBufferBase {
  final WasmIntArray<WasmI8> _data;

  _I8ByteBuffer2(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Int8List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int8List.bytesPerElement);
    return _I8List._(_data, offsetInBytes, length);
  }

  @override
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint8List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint8List.bytesPerElement);
    return _U8List._(_data, offsetInBytes, length);
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return _I8ByteData2._(_data, offsetInBytes, length);
  }
}

class _I16ByteBuffer2 extends _ByteBufferBase {
  final WasmIntArray<WasmI16> _data;

  _I16ByteBuffer2(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Int16List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int16List.bytesPerElement);
    if (offsetInBytes % Int16List.bytesPerElement != 0) {
      return _SlowI16List._(this, offsetInBytes, length);
    } else {
      return _I16List._(
          _data, offsetInBytes ~/ Int16List.bytesPerElement, length);
    }
  }

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint16List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint16List.bytesPerElement);
    if (offsetInBytes % Uint16List.bytesPerElement != 0) {
      return _SlowU16List._(this, offsetInBytes, length);
    } else {
      return _U16List._(
          _data, offsetInBytes ~/ Uint16List.bytesPerElement, length);
    }
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return _I16ByteData2._(_data, offsetInBytes, length);
  }
}

class _I32ByteBuffer2 extends _ByteBufferBase {
  final WasmIntArray<WasmI32> _data;

  _I32ByteBuffer2(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Int32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int32List.bytesPerElement);
    if (offsetInBytes % Uint32List.bytesPerElement != 0) {
      return _SlowI32List._(this, offsetInBytes, length);
    } else {
      return _I32List._(
          _data, offsetInBytes ~/ Int32List.bytesPerElement, length);
    }
  }

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint32List.bytesPerElement);
    if (offsetInBytes % Uint32List.bytesPerElement != 0) {
      return _SlowU32List._(this, offsetInBytes, length);
    } else {
      return _U32List._(
          _data, offsetInBytes ~/ Uint32List.bytesPerElement, length);
    }
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return _I32ByteData2._(_data, offsetInBytes, length);
  }
}

class _I64ByteBuffer2 extends _ByteBufferBase {
  final WasmIntArray<WasmI64> _data;

  _I64ByteBuffer2(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Int64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int64List.bytesPerElement);
    if (offsetInBytes % Int64List.bytesPerElement != 0) {
      return _SlowI64List._(this, offsetInBytes, length);
    } else {
      return _I64List._(
          _data, offsetInBytes ~/ Int64List.bytesPerElement, length);
    }
  }

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Int64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint64List.bytesPerElement);
    if (offsetInBytes % Int64List.bytesPerElement != 0) {
      return _SlowU64List._(this, offsetInBytes, length);
    } else {
      return _U64List._(
          _data, offsetInBytes ~/ Uint64List.bytesPerElement, length);
    }
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return _I64ByteData2._(_data, offsetInBytes, length);
  }
}

class _F32ByteBuffer2 extends _ByteBufferBase {
  final WasmFloatArray<WasmF32> _data;

  _F32ByteBuffer2(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Float32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Float32List.bytesPerElement);
    if (offsetInBytes % Float32List.bytesPerElement != 0) {
      return _SlowF32List._(this, offsetInBytes, length);
    } else {
      return _F32List._(
          _data, offsetInBytes ~/ Float32List.bytesPerElement, length);
    }
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return _F32ByteData2._(_data, offsetInBytes, length);
  }
}

class _F64ByteBuffer2 extends _ByteBufferBase {
  final WasmFloatArray<WasmF64> _data;

  _F64ByteBuffer2(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= (lengthInBytes - offsetInBytes) ~/ Float64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Float64List.bytesPerElement);
    if (offsetInBytes % Float64List.bytesPerElement != 0) {
      return _SlowF64List._(this, offsetInBytes, length);
    } else {
      return _F64List._(
          _data, offsetInBytes ~/ Int64List.bytesPerElement, length);
    }
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    offsetInBytes += this.offsetInBytes;
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return _F64ByteData2._(_data, offsetInBytes, length);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Mixins
//
////////////////////////////////////////////////////////////////////////////////////////////////////

mixin _TypedListCommonOperationsMixin {
  int get length;

  int get elementSizeInBytes;

  @override
  bool get isEmpty => length != 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  int get lengthInBytes => elementSizeInBytes * length;

  @override
  String join([String separator = ""]) {
    StringBuffer buffer = StringBuffer();
    buffer.writeAll(this as Iterable, separator);
    return buffer.toString();
  }

  @override
  void clear() {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  bool remove(Object? element) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  void removeRange(int start, int end) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  void replaceRange(int start, int end, Iterable iterable) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  set length(int newLength) {
    throw UnsupportedError("Cannot resize a fixed-length list");
  }
}

mixin _IntListMixin2 implements List<int> {
  int get elementSizeInBytes;
  int get offsetInBytes;
  ByteBuffer get buffer;

  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  Iterable<int> followedBy(Iterable<int> other) =>
      FollowedByIterable<int>.firstEfficient(this, other);

  List<R> cast<R>() => List.castFrom<int, R>(this);
  void set first(int value) {
    if (this.length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    this[0] = value;
  }

  void set last(int value) {
    if (this.length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    this[this.length - 1] = value;
  }

  int indexWhere(bool test(int element), [int start = 0]) {
    if (start < 0) start = 0;
    for (int i = start; i < length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  int lastIndexWhere(bool test(int element), [int? start]) {
    int startIndex =
        (start == null || start >= this.length) ? this.length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  List<int> operator +(List<int> other) => [...this, ...other];

  bool contains(Object? element) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (this[i] == element) return true;
    }
    return false;
  }

  void shuffle([Random? random]) {
    random ??= Random();
    var i = this.length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = this[i];
      this[i] = this[pos];
      this[pos] = tmp;
    }
  }

  Iterable<int> where(bool f(int element)) => WhereIterable<int>(this, f);

  Iterable<int> take(int n) => SubListIterable<int>(this, 0, n);

  Iterable<int> takeWhile(bool test(int element)) =>
      TakeWhileIterable<int>(this, test);

  Iterable<int> skip(int n) => SubListIterable<int>(this, n, null);

  Iterable<int> skipWhile(bool test(int element)) =>
      SkipWhileIterable<int>(this, test);

  Iterable<int> get reversed => ReversedListIterable<int>(this);

  Map<int, int> asMap() => ListMapView<int>(this);

  Iterable<int> getRange(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, this.length);
    return SubListIterable<int>(this, start, endIndex);
  }

  Iterator<int> get iterator => _TypedListIterator<int>(this);

  List<int> toList({bool growable = true}) {
    return List<int>.from(this, growable: growable);
  }

  Set<int> toSet() {
    return Set<int>.from(this);
  }

  void forEach(void f(int element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  int reduce(int combine(int value, int element)) {
    var len = this.length;
    if (len == 0) throw IterableElementError.noElement();
    var value = this[0];
    for (var i = 1; i < len; ++i) {
      value = combine(value, this[i]);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T initialValue, int element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      initialValue = combine(initialValue, this[i]);
    }
    return initialValue;
  }

  Iterable<T> map<T>(T f(int element)) => MappedIterable<int, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(int element)) =>
      ExpandIterable<int, T>(this, f);

  bool every(bool f(int element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(int element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (f(this[i])) return true;
    }
    return false;
  }

  int firstWhere(bool test(int element), {int orElse()?}) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  int lastWhere(bool test(int element), {int orElse()?}) {
    var len = this.length;
    for (var i = len - 1; i >= 0; --i) {
      var element = this[i];
      if (test(element)) {
        return element;
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  int singleWhere(bool test(int element), {int orElse()?}) {
    var result = null;
    bool foundMatching = false;
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) {
        if (foundMatching) {
          throw IterableElementError.tooMany();
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  int elementAt(int index) {
    return this[index];
  }

  void add(int value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable<int> value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, int value) {
    throw UnsupportedError("Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable<int> values) {
    throw UnsupportedError("Cannot insert into a fixed-length list");
  }

  void sort([int compare(int a, int b)?]) {
    Sort.sort(this, compare ?? Comparable.compare);
  }

  int indexOf(int element, [int start = 0]) {
    if (start >= this.length) {
      return -1;
    } else if (start < 0) {
      start = 0;
    }
    for (int i = start; i < this.length; i++) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  int lastIndexOf(int element, [int? start]) {
    int startIndex =
        (start == null || start >= this.length) ? this.length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  int removeLast() {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  int removeAt(int index) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(int element)) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(int element)) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  int get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  int get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  void setAll(int index, Iterable<int> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [int? fillValue]) {
    RangeError.checkValidRange(start, end, this.length);
    if (start == end) return;
    if (fillValue == null) {
      throw ArgumentError.notNull("fillValue");
    }
    for (var i = start; i < end; ++i) {
      this[i] = fillValue;
    }
  }
}

mixin _TypedIntListMixin2<SpawnedType extends List<int>> on _IntListMixin2
    implements List<int> {
  SpawnedType _createList(int length);

  void setRange(int start, int end, Iterable<int> from, [int skipCount = 0]) {
    // Check ranges.
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
      assert(false);
    }
    if (skipCount < 0) {
      throw RangeError.range(skipCount, 0, null, "skipCount");
    }

    final count = end - start;
    if ((from.length - skipCount) < count) {
      throw IterableElementError.tooFew();
    }

    if (count == 0) return;

    List otherList;
    int otherStart;
    otherList = from.skip(skipCount).toList(growable: false);
    otherStart = 0;
    if (otherStart + count > otherList.length) {
      throw IterableElementError.tooFew();
    }
    Lists.copy(otherList, otherStart, this, start, count);
  }

  SpawnedType sublist(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, this.length);
    var length = endIndex - start;
    SpawnedType result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }
}

mixin _DoubleListMixin2 implements List<double> {
  int get elementSizeInBytes;
  int get offsetInBytes;
  ByteBuffer get buffer;

  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  Iterable<double> followedBy(Iterable<double> other) =>
      FollowedByIterable<double>.firstEfficient(this, other);

  List<R> cast<R>() => List.castFrom<double, R>(this);
  void set first(double value) {
    if (this.length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    this[0] = value;
  }

  void set last(double value) {
    if (this.length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    this[this.length - 1] = value;
  }

  int indexWhere(bool test(double element), [int start = 0]) {
    if (start < 0) start = 0;
    for (int i = start; i < length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  int lastIndexWhere(bool test(double element), [int? start]) {
    int startIndex =
        (start == null || start >= this.length) ? this.length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  List<double> operator +(List<double> other) => [...this, ...other];

  bool contains(Object? element) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (this[i] == element) return true;
    }
    return false;
  }

  void shuffle([Random? random]) {
    random ??= Random();
    var i = this.length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = this[i];
      this[i] = this[pos];
      this[pos] = tmp;
    }
  }

  Iterable<double> where(bool f(double element)) =>
      WhereIterable<double>(this, f);

  Iterable<double> take(int n) => SubListIterable<double>(this, 0, n);

  Iterable<double> takeWhile(bool test(double element)) =>
      TakeWhileIterable<double>(this, test);

  Iterable<double> skip(int n) => SubListIterable<double>(this, n, null);

  Iterable<double> skipWhile(bool test(double element)) =>
      SkipWhileIterable<double>(this, test);

  Iterable<double> get reversed => ReversedListIterable<double>(this);

  Map<int, double> asMap() => ListMapView<double>(this);

  Iterable<double> getRange(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, this.length);
    return SubListIterable<double>(this, start, endIndex);
  }

  Iterator<double> get iterator => _TypedListIterator<double>(this);

  List<double> toList({bool growable = true}) {
    return List<double>.from(this, growable: growable);
  }

  Set<double> toSet() {
    return Set<double>.from(this);
  }

  void forEach(void f(double element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  double reduce(double combine(double value, double element)) {
    var len = this.length;
    if (len == 0) throw IterableElementError.noElement();
    var value = this[0];
    for (var i = 1; i < len; ++i) {
      value = combine(value, this[i]);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T initialValue, double element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      initialValue = combine(initialValue, this[i]);
    }
    return initialValue;
  }

  Iterable<T> map<T>(T f(double element)) => MappedIterable<double, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(double element)) =>
      ExpandIterable<double, T>(this, f);

  bool every(bool f(double element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(double element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (f(this[i])) return true;
    }
    return false;
  }

  double firstWhere(bool test(double element), {double orElse()?}) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  double lastWhere(bool test(double element), {double orElse()?}) {
    var len = this.length;
    for (var i = len - 1; i >= 0; --i) {
      var element = this[i];
      if (test(element)) {
        return element;
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  double singleWhere(bool test(double element), {double orElse()?}) {
    var result = null;
    bool foundMatching = false;
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) {
        if (foundMatching) {
          throw IterableElementError.tooMany();
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  double elementAt(int index) {
    return this[index];
  }

  void add(double value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable<double> value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, double value) {
    throw UnsupportedError("Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable<double> values) {
    throw UnsupportedError("Cannot insert into a fixed-length list");
  }

  void sort([int compare(double a, double b)?]) {
    Sort.sort(this, compare ?? Comparable.compare);
  }

  int indexOf(double element, [int start = 0]) {
    if (start >= this.length) {
      return -1;
    } else if (start < 0) {
      start = 0;
    }
    for (int i = start; i < this.length; i++) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  int lastIndexOf(double element, [int? start]) {
    int startIndex =
        (start == null || start >= this.length) ? this.length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  double removeLast() {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  double removeAt(int index) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(double element)) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(double element)) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  double get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  double get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  double get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  void setAll(int index, Iterable<double> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [double? fillValue]) {
    // TODO(eernst): Could use zero as default and not throw; issue .
    RangeError.checkValidRange(start, end, this.length);
    if (start == end) return;
    if (fillValue == null) {
      throw ArgumentError.notNull("fillValue");
    }
    for (var i = start; i < end; ++i) {
      this[i] = fillValue;
    }
  }
}

mixin _TypedDoubleListMixin2<SpawnedType extends List<double>>
    on _DoubleListMixin2 implements List<double> {
  SpawnedType _createList(int length);

  void setRange(int start, int end, Iterable<double> from,
      [int skipCount = 0]) {
    // Check ranges.
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
      assert(false);
    }
    if (skipCount < 0) {
      throw RangeError.range(skipCount, 0, null, "skipCount");
    }

    final count = end - start;
    if ((from.length - skipCount) < count) {
      throw IterableElementError.tooFew();
    }

    if (count == 0) return;

    List otherList;
    int otherStart;
    if (from is List<double>) {
      otherList = from;
      otherStart = skipCount;
    } else {
      otherList = from.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + count > otherList.length) {
      throw IterableElementError.tooFew();
    }
    Lists.copy(otherList, otherStart, this, start, count);
  }

  SpawnedType sublist(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, this.length);
    var length = endIndex - start;
    SpawnedType result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Fast lists
//
////////////////////////////////////////////////////////////////////////////////////////////////////

class _I8List
    with
        _IntListMixin2,
        _TypedIntListMixin2<_I8List>,
        _TypedListCommonOperationsMixin
    implements Int8List {
  final WasmIntArray<WasmI8> _data;
  final int _offsetInElements;
  final int length;

  _I8List(this.length)
      : _data = WasmIntArray(length),
        _offsetInElements = 0;

  _I8List._(this._data, this._offsetInElements, this.length);

  @override
  _I8List _createList(int length) => _I8List(length);

  @override
  _I8ByteBuffer2 get buffer =>
      _I8ByteBuffer2(_data, offsetInBytes, length * elementSizeInBytes);

  @override
  int get elementSizeInBytes => Int8List.bytesPerElement;

  @override
  int get offsetInBytes => _offsetInElements * elementSizeInBytes;

  @override
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readSigned(_offsetInElements + index);
  }

  @override
  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _data.write(_offsetInElements + index, value);
  }
}

class _U8List
    with
        _IntListMixin2,
        _TypedIntListMixin2<_U8List>,
        _TypedListCommonOperationsMixin
    implements Uint8List {
  final WasmIntArray<WasmI8> _data;
  final int _offsetInElements;
  final int length;

  _U8List(this.length)
      : _data = WasmIntArray(length),
        _offsetInElements = 0;

  _U8List._(this._data, this._offsetInElements, this.length);

  @override
  _U8List _createList(int length) => _U8List(length);

  @override
  _I8ByteBuffer2 get buffer =>
      _I8ByteBuffer2(_data, offsetInBytes, length * elementSizeInBytes);

  @override
  int get elementSizeInBytes => Uint8List.bytesPerElement;

  @override
  int get offsetInBytes => _offsetInElements * elementSizeInBytes;

  @override
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readUnsigned(_offsetInElements + index);
  }

  @override
  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _data.write(_offsetInElements + index, value);
  }
}

class _I16List
    with
        _IntListMixin2,
        _TypedIntListMixin2<_I16List>,
        _TypedListCommonOperationsMixin
    implements Int16List {
  final WasmIntArray<WasmI16> _data;
  final int _offsetInElements;
  final int length;

  _I16List(this.length)
      : _data = WasmIntArray(length),
        _offsetInElements = 0;

  _I16List._(this._data, this._offsetInElements, this.length);

  @override
  _I16List _createList(int length) => _I16List(length);

  @override
  _I16ByteBuffer2 get buffer =>
      _I16ByteBuffer2(_data, offsetInBytes, length * elementSizeInBytes);

  @override
  int get elementSizeInBytes => Int16List.bytesPerElement;

  @override
  int get offsetInBytes => _offsetInElements * elementSizeInBytes;

  @override
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readSigned(_offsetInElements + index);
  }

  @override
  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _data.write(_offsetInElements + index, value);
  }
}

class _U16List
    with
        _IntListMixin2,
        _TypedIntListMixin2<_U16List>,
        _TypedListCommonOperationsMixin
    implements Uint16List {
  final WasmIntArray<WasmI16> _data;
  final int _offsetInElements;
  final int length;

  _U16List(this.length)
      : _data = WasmIntArray(length),
        _offsetInElements = 0;

  _U16List._(this._data, this._offsetInElements, this.length);

  @override
  _U16List _createList(int length) => _U16List(length);

  @override
  _I16ByteBuffer2 get buffer =>
      _I16ByteBuffer2(_data, offsetInBytes, length * elementSizeInBytes);

  @override
  int get elementSizeInBytes => Uint16List.bytesPerElement;

  @override
  int get offsetInBytes => _offsetInElements * elementSizeInBytes;

  @override
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readUnsigned(_offsetInElements + index);
  }

  @override
  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _data.write(_offsetInElements + index, value);
  }
}

class _I32List
    with
        _IntListMixin2,
        _TypedIntListMixin2<_I32List>,
        _TypedListCommonOperationsMixin
    implements Int32List {
  final WasmIntArray<WasmI32> _data;
  final int _offsetInElements;
  final int length;

  _I32List(this.length)
      : _data = WasmIntArray(length),
        _offsetInElements = 0;

  _I32List._(this._data, this._offsetInElements, this.length);

  @override
  _I32List _createList(int length) => _I32List(length);

  @override
  _I32ByteBuffer2 get buffer =>
      _I32ByteBuffer2(_data, offsetInBytes, length * elementSizeInBytes);

  @override
  int get elementSizeInBytes => Int32List.bytesPerElement;

  @override
  int get offsetInBytes => _offsetInElements * elementSizeInBytes;

  @override
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readSigned(_offsetInElements + index);
  }

  @override
  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _data.write(_offsetInElements + index, value);
  }
}

class _U32List
    with
        _IntListMixin2,
        _TypedIntListMixin2<_U32List>,
        _TypedListCommonOperationsMixin
    implements Uint32List {
  final WasmIntArray<WasmI32> _data;
  final int _offsetInElements;
  final int length;

  _U32List(this.length)
      : _data = WasmIntArray(length),
        _offsetInElements = 0;

  _U32List._(this._data, this._offsetInElements, this.length);

  @override
  _U32List _createList(int length) => _U32List(length);

  @override
  _I32ByteBuffer2 get buffer =>
      _I32ByteBuffer2(_data, offsetInBytes, length * elementSizeInBytes);

  @override
  int get elementSizeInBytes => Uint32List.bytesPerElement;

  @override
  int get offsetInBytes => _offsetInElements * elementSizeInBytes;

  @override
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readUnsigned(_offsetInElements + index);
  }

  @override
  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _data.write(_offsetInElements + index, value);
  }
}

class _I64List
    with
        _IntListMixin2,
        _TypedIntListMixin2<_I64List>,
        _TypedListCommonOperationsMixin
    implements Int64List {
  final WasmIntArray<WasmI64> _data;
  final int _offsetInElements;
  final int length;

  _I64List(this.length)
      : _data = WasmIntArray(length),
        _offsetInElements = 0;

  _I64List._(this._data, this._offsetInElements, this.length);

  @override
  _I64List _createList(int length) => _I64List(length);

  @override
  _I64ByteBuffer2 get buffer =>
      _I64ByteBuffer2(_data, offsetInBytes, length * elementSizeInBytes);

  @override
  int get elementSizeInBytes => Int64List.bytesPerElement;

  @override
  int get offsetInBytes => _offsetInElements * elementSizeInBytes;

  @override
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readSigned(_offsetInElements + index);
  }

  @override
  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _data.write(_offsetInElements + index, value);
  }
}

class _U64List
    with
        _IntListMixin2,
        _TypedIntListMixin2<_U64List>,
        _TypedListCommonOperationsMixin
    implements Uint64List {
  final WasmIntArray<WasmI64> _data;
  final int _offsetInElements;
  final int length;

  _U64List(this.length)
      : _data = WasmIntArray(length),
        _offsetInElements = 0;

  _U64List._(this._data, this._offsetInElements, this.length);

  @override
  _U64List _createList(int length) => _U64List(length);

  @override
  _I64ByteBuffer2 get buffer =>
      _I64ByteBuffer2(_data, offsetInBytes, length * elementSizeInBytes);

  @override
  int get elementSizeInBytes => Uint64List.bytesPerElement;

  @override
  int get offsetInBytes => _offsetInElements * elementSizeInBytes;

  @override
  int operator [](int index) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readUnsigned(_offsetInElements + index);
  }

  @override
  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _data.write(_offsetInElements + index, value);
  }
}

class _F32List
    with
        _DoubleListMixin2,
        _TypedDoubleListMixin2<Float32List>,
        _TypedListCommonOperationsMixin
    implements Float32List {
  final WasmFloatArray<WasmF32> _data;
  final int _offsetInElements;
  final int length;

  _F32List(this.length)
      : _data = WasmFloatArray(length),
        _offsetInElements = 0;

  _F32List._(this._data, this._offsetInElements, this.length);

  @override
  _F32List _createList(int length) => _F32List(length);

  @override
  _F32ByteBuffer2 get buffer =>
      _F32ByteBuffer2(_data, offsetInBytes, length * elementSizeInBytes);

  @override
  int get elementSizeInBytes => Float32List.bytesPerElement;

  @override
  int get offsetInBytes => _offsetInElements * elementSizeInBytes;

  @override
  double operator [](int index) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.read(_offsetInElements + index);
  }

  @override
  void operator []=(int index, double value) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _data.write(_offsetInElements + index, value);
  }
}

class _F64List
    with
        _DoubleListMixin2,
        _TypedDoubleListMixin2<Float64List>,
        _TypedListCommonOperationsMixin
    implements Float64List {
  final WasmFloatArray<WasmF64> _data;
  final int _offsetInElements;
  final int length;

  _F64List(this.length)
      : _data = WasmFloatArray(length),
        _offsetInElements = 0;

  _F64List._(this._data, this._offsetInElements, this.length);

  @override
  _F64List _createList(int length) => _F64List(length);

  @override
  _F64ByteBuffer2 get buffer =>
      _F64ByteBuffer2(_data, offsetInBytes, length * elementSizeInBytes);

  @override
  int get elementSizeInBytes => Float64List.bytesPerElement;

  @override
  int get offsetInBytes => _offsetInElements * elementSizeInBytes;

  @override
  double operator [](int index) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.read(_offsetInElements + index);
  }

  @override
  void operator []=(int index, double value) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    _data.write(_offsetInElements + index, value);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Slow lists
//
////////////////////////////////////////////////////////////////////////////////////////////////////

class _SlowListBase {
  final ByteBuffer buffer;
  final int offsetInBytes;
  final int length;

  final ByteData _data;

  _SlowListBase(this.buffer, this.offsetInBytes, this.length)
      : _data = buffer.asByteData();

  void _indexRangeCheck(int index) {
    if (index < 0 || index >= length) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
  }
}

class _SlowI8List extends _SlowListBase
    with
        _IntListMixin2,
        _TypedIntListMixin2<_I8List>,
        _TypedListCommonOperationsMixin
    implements Int8List {
  _SlowI8List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  @override
  _I8List _createList(int length) => _I8List(length);

  @override
  int get elementSizeInBytes => Int8List.bytesPerElement;

  @override
  int operator [](int index) {
    _indexRangeCheck(index);
    return _data.getInt8(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setInt8(offsetInBytes + (index * elementSizeInBytes), value);
  }
}

class _SlowU8List extends _SlowListBase
    with
        _IntListMixin2,
        _TypedIntListMixin2<_U8List>,
        _TypedListCommonOperationsMixin
    implements Uint8List {
  _SlowU8List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  @override
  _U8List _createList(int length) => _U8List(length);

  @override
  int get elementSizeInBytes => Int8List.bytesPerElement;

  @override
  int operator [](int index) {
    _indexRangeCheck(index);
    return _data.getUint8(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setUint8(offsetInBytes + (index * elementSizeInBytes), value);
  }
}

class _SlowI16List extends _SlowListBase
    with
        _IntListMixin2,
        _TypedIntListMixin2<_I16List>,
        _TypedListCommonOperationsMixin
    implements Int16List {
  _SlowI16List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  @override
  _I16List _createList(int length) => _I16List(length);

  @override
  int get elementSizeInBytes => Int16List.bytesPerElement;

  @override
  int operator [](int index) {
    _indexRangeCheck(index);
    return _data.getInt16(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setInt16(offsetInBytes + (index * elementSizeInBytes), value);
  }
}

class _SlowU16List extends _SlowListBase
    with
        _IntListMixin2,
        _TypedIntListMixin2<_U16List>,
        _TypedListCommonOperationsMixin
    implements Uint16List {
  _SlowU16List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  @override
  _U16List _createList(int length) => _U16List(length);

  @override
  int get elementSizeInBytes => Int16List.bytesPerElement;

  @override
  int operator [](int index) {
    _indexRangeCheck(index);
    return _data.getUint16(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setUint16(offsetInBytes + (index * elementSizeInBytes), value);
  }
}

class _SlowI32List extends _SlowListBase
    with
        _IntListMixin2,
        _TypedIntListMixin2<_I32List>,
        _TypedListCommonOperationsMixin
    implements Int32List {
  _SlowI32List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  @override
  _I32List _createList(int length) => _I32List(length);

  @override
  int get elementSizeInBytes => Int32List.bytesPerElement;

  @override
  int operator [](int index) {
    _indexRangeCheck(index);
    return _data.getInt32(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setInt32(offsetInBytes + (index * elementSizeInBytes), value);
  }
}

class _SlowU32List extends _SlowListBase
    with
        _IntListMixin2,
        _TypedIntListMixin2<_U32List>,
        _TypedListCommonOperationsMixin
    implements Uint32List {
  _SlowU32List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  @override
  _U32List _createList(int length) => _U32List(length);

  @override
  int get elementSizeInBytes => Int32List.bytesPerElement;

  @override
  int operator [](int index) {
    _indexRangeCheck(index);
    return _data.getUint32(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setUint32(offsetInBytes + (index * elementSizeInBytes), value);
  }
}

class _SlowI64List extends _SlowListBase
    with
        _IntListMixin2,
        _TypedIntListMixin2<_I64List>,
        _TypedListCommonOperationsMixin
    implements Int64List {
  _SlowI64List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  @override
  _I64List _createList(int length) => _I64List(length);

  @override
  int get elementSizeInBytes => Int64List.bytesPerElement;

  @override
  int operator [](int index) {
    _indexRangeCheck(index);
    return _data.getInt64(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setInt64(offsetInBytes + (index * elementSizeInBytes), value);
  }
}

class _SlowU64List extends _SlowListBase
    with
        _IntListMixin2,
        _TypedIntListMixin2<_U64List>,
        _TypedListCommonOperationsMixin
    implements Uint64List {
  _SlowU64List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  @override
  _U64List _createList(int length) => _U64List(length);

  @override
  int get elementSizeInBytes => Int64List.bytesPerElement;

  @override
  int operator [](int index) {
    _indexRangeCheck(index);
    return _data.getUint64(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setUint64(offsetInBytes + (index * elementSizeInBytes), value);
  }
}

class _SlowF32List extends _SlowListBase
    with
        _DoubleListMixin2,
        _TypedDoubleListMixin2<_F32List>,
        _TypedListCommonOperationsMixin
    implements Float32List {
  _SlowF32List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  @override
  _F32List _createList(int length) => _F32List(length);

  @override
  int get elementSizeInBytes => Int64List.bytesPerElement;

  @override
  double operator [](int index) {
    _indexRangeCheck(index);
    return _data.getFloat32(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, double value) {
    _indexRangeCheck(index);
    _data.setFloat32(offsetInBytes + (index * elementSizeInBytes), value);
  }
}

class _SlowF64List extends _SlowListBase
    with
        _DoubleListMixin2,
        _TypedDoubleListMixin2<_F64List>,
        _TypedListCommonOperationsMixin
    implements Float64List {
  _SlowF64List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  @override
  _F64List _createList(int length) => _F64List(length);

  @override
  int get elementSizeInBytes => Float64List.bytesPerElement;

  @override
  double operator [](int index) {
    _indexRangeCheck(index);
    return _data.getFloat64(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, double value) {
    _indexRangeCheck(index);
    _data.setFloat64(offsetInBytes + (index * elementSizeInBytes), value);
  }
}
