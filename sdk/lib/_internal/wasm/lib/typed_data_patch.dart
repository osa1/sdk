// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal'
    show
        ClassID,
        ExpandIterable,
        FollowedByIterable,
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
/// implementations for get and set methods using [getUint8] and [setUint8].
/// Implementations can override the methods to provide a more efficient
/// implementation based on the actual Wasm array type used.
abstract class _ByteData2 implements ByteData {
  final int offsetInBytes;
  final int lengthInBytes;

  _ByteData2(this.offsetInBytes, this.lengthInBytes);

  @override
  int getInt8(int byteOffset) {
    throw 'TODO';
  }

  @override
  int setInt8(int byteOffset, int value) {
    throw 'TODO';
  }

  @override
  int getInt16(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int getUint16(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int getInt32(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int getUint32(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int getInt64(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int getUint64(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) {
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

  @override
  double getFloat64(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }
}

class _I8ByteData2 extends _ByteData2 {
  final WasmIntArray<WasmI8> _data;

  _I8ByteData2._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  ByteBuffer get buffer => _I8ByteBuffer2(_data, offsetInBytes, lengthInBytes);

  @override
  int get elementSizeInBytes => Int8List.bytesPerElement;

  @override
  int getUint8(int byteOffset) {
    throw 'TODO';
  }

  @override
  int setUint8(int byteOffset, int value) {
    throw 'TODO';
  }
}

class _I16ByteData2 extends _ByteData2 {
  final WasmIntArray<WasmI16> _data;

  _I16ByteData2._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  ByteBuffer get buffer => _I16ByteBuffer2(_data, offsetInBytes, lengthInBytes);

  @override
  int get elementSizeInBytes => Int16List.bytesPerElement;

  @override
  int getUint8(int byteOffset) {
    throw 'TODO';
  }

  @override
  int setUint8(int byteOffset, int value) {
    throw 'TODO';
  }

  @override
  int getInt16(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int getUint16(int byteOffset, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int setInt16(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int setUint16(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }
}

class _I32ByteData2 extends _ByteData2 {
  final WasmIntArray<WasmI32> _data;

  _I32ByteData2._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  ByteBuffer get buffer => _I32ByteBuffer2(_data, offsetInBytes, lengthInBytes);

  @override
  int get elementSizeInBytes => Int32List.bytesPerElement;

  @override
  int getUint8(int byteOffset) {
    throw 'TODO';
  }

  @override
  int setUint8(int byteOffset, int value) {
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
  int setInt32(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int setUint32(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }
}

class _I64ByteData2 extends _ByteData2 {
  final WasmIntArray<WasmI64> _data;

  _I64ByteData2._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  @override
  ByteBuffer get buffer => _I64ByteBuffer2(_data, offsetInBytes, lengthInBytes);

  @override
  int get elementSizeInBytes => Int64List.bytesPerElement;

  @override
  int getUint8(int byteOffset) {
    throw 'TODO';
  }

  @override
  int setUint8(int byteOffset, int value) {
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
  int setInt64(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw 'TODO';
  }

  @override
  int setUint64(int byteOffset, int value, [Endian endian = Endian.big]) {
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
    throw 'TODO';
  }

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) {
    // TODO: range checks
    length ??= (this.lengthInBytes - offsetInBytes) ~/ Int8List.bytesPerElement;
    return _SlowI8List._(this, this.offsetInBytes + offsetInBytes, length);
  }

  @override
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) {
    throw 'TODO';
  }

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) {
    throw 'TODO';
  }

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) {
    // TODO: range checks
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Int16List.bytesPerElement;
    return _SlowI16List._(this, this.offsetInBytes + offsetInBytes, length);
  }

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) {
    throw 'TODO';
  }

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) {
    // TODO: range checks
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Int32List.bytesPerElement;
    return _SlowI32List._(this, this.offsetInBytes + offsetInBytes, length);
  }

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) {
    throw 'TODO';
  }

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) {
    // TODO: range checks
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Int64List.bytesPerElement;
    return _SlowI64List._(this, this.offsetInBytes + offsetInBytes, length);
  }

  @override
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) {
    throw 'TODO';
  }

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) {
    throw 'TODO';
  }

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) {
    throw 'TODO';
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

  // TODO: Override asInt8List.

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    length ??= this.lengthInBytes - offsetInBytes;
    return _I8ByteData2._(_data, this.offsetInBytes + offsetInBytes, length);
  }
}

class _I16ByteBuffer2 extends _ByteBufferBase {
  final WasmIntArray<WasmI16> _data;

  _I16ByteBuffer2(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  // TODO: Override asInt16List.

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    length ??= this.lengthInBytes - offsetInBytes;
    return _I16ByteData2._(_data, this.offsetInBytes + offsetInBytes, length);
  }
}

class _I32ByteBuffer2 extends _ByteBufferBase {
  final WasmIntArray<WasmI32> _data;

  _I32ByteBuffer2(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  // TODO: Override asInt32List.

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    length ??= this.lengthInBytes - offsetInBytes;
    return _I32ByteData2._(_data, this.offsetInBytes + offsetInBytes, length);
  }
}

class _I64ByteBuffer2 extends _ByteBufferBase {
  final WasmIntArray<WasmI64> _data;

  _I64ByteBuffer2(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  // TODO: Override asUint64List.

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Int64List.bytesPerElement;
    _rangeCheck(
        this.lengthInBytes, offsetInBytes, length * Int64List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Int64List.bytesPerElement);
    return _I64List._(
        _data, offsetInBytes ~/ Int64List.bytesPerElement, length);
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    length ??=
        (this.lengthInBytes - offsetInBytes) ~/ Int64List.bytesPerElement;
    return _I64ByteData2._(_data, offsetInBytes + offsetInBytes, length);
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

mixin _IntListMixin2 implements List<int> {
  int get elementSizeInBytes;
  int get offsetInBytes;
  ByteBuffer get buffer;

  Iterable<T> whereType<T>() => new WhereTypeIterable<T>(this);

  Iterable<int> followedBy(Iterable<int> other) =>
      new FollowedByIterable<int>.firstEfficient(this, other);

  List<R> cast<R>() => List.castFrom<int, R>(this);
  void set first(int value) {
    if (this.length == 0) {
      throw new IndexError.withLength(0, length, indexable: this);
    }
    this[0] = value;
  }

  void set last(int value) {
    if (this.length == 0) {
      throw new IndexError.withLength(0, length, indexable: this);
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
    random ??= new Random();
    var i = this.length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = this[i];
      this[i] = this[pos];
      this[pos] = tmp;
    }
  }

  Iterable<int> where(bool f(int element)) => new WhereIterable<int>(this, f);

  Iterable<int> take(int n) => new SubListIterable<int>(this, 0, n);

  Iterable<int> takeWhile(bool test(int element)) =>
      new TakeWhileIterable<int>(this, test);

  Iterable<int> skip(int n) => new SubListIterable<int>(this, n, null);

  Iterable<int> skipWhile(bool test(int element)) =>
      new SkipWhileIterable<int>(this, test);

  Iterable<int> get reversed => new ReversedListIterable<int>(this);

  Map<int, int> asMap() => new ListMapView<int>(this);

  Iterable<int> getRange(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, this.length);
    return new SubListIterable<int>(this, start, endIndex);
  }

  Iterator<int> get iterator => new _TypedListIterator<int>(this);

  List<int> toList({bool growable = true}) {
    return new List<int>.from(this, growable: growable);
  }

  Set<int> toSet() {
    return new Set<int>.from(this);
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

  Iterable<T> map<T>(T f(int element)) => new MappedIterable<int, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(int element)) =>
      new ExpandIterable<int, T>(this, f);

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
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable<int> value) {
    throw new UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, int value) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable<int> values) {
    throw new UnsupportedError("Cannot insert into a fixed-length list");
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
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  int removeAt(int index) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from a fixed-length list");
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
      throw new IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readSigned(_offsetInElements + index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new IndexError.withLength(index, length,
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
      throw new IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readSigned(_offsetInElements + index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new IndexError.withLength(index, length,
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
      throw new IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readSigned(_offsetInElements + index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new IndexError.withLength(index, length,
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
      throw new IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _data.readSigned(_offsetInElements + index);
  }

  void operator []=(int index, int value) {
    if (index < 0 || index >= length) {
      throw new IndexError.withLength(index, length,
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
      throw new IndexError.withLength(index, length,
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
  int get elementSizeInBytes => Int16List.bytesPerElement;

  @override
  int operator [](int index) {
    _indexRangeCheck(index);
    return _data.getInt8(offsetInBytes + (index * elementSizeInBytes));
  }

  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setInt8(offsetInBytes + (index * elementSizeInBytes), value);
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

  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setInt16(offsetInBytes + (index * elementSizeInBytes), value);
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

  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setInt32(offsetInBytes + (index * elementSizeInBytes), value);
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

  void operator []=(int index, int value) {
    _indexRangeCheck(index);
    _data.setInt64(offsetInBytes + (index * elementSizeInBytes), value);
  }
}
