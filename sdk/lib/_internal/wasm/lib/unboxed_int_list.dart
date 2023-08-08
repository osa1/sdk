// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._unboxed_int_list;

import "dart:_internal";
import "dart:_list";
import "dart:_wasm";
import "dart:collection";

const int _maxWasmArrayLength = 2147483647; // max i32

abstract class UnboxedIntListBase extends ListBase<int> {
  int _length;
  WasmIntArray<WasmI64> _data;

  UnboxedIntListBase(int length, int capacity)
      : _length = length,
        _data = WasmIntArray<WasmI64>(
            RangeError.checkValueInInterval(capacity, 0, _maxWasmArrayLength));

  @pragma('wasm:prefer-inline')
  int operator [](int index) {
    IndexError.check(index, _length, indexable: this, name: "[]");
    return _data.readSigned(index);
  }

  int get length => _length;

  /*
  TODO
  List<int> sublist(int start, [int? end]) {
    final int listLength = _length;
    final int actualEnd = RangeError.checkValidRange(start, end, listLength);
    int length = actualEnd - start;
    if (length == 0) return <E>[];
    return GrowableUnboxedIntList<E>(length)..setRange(0, length, this, start);
  }
  */

  void forEach(f(int element)) {
    final initialLength = _length;
    for (int i = 0; i < initialLength; i++) {
      f(_data.readSigned(i));
      if (_length != initialLength) throw ConcurrentModificationError(this);
    }
  }

  List<int> toList({bool growable = true}) {
    return List.from(this, growable: growable);
  }
}

abstract class ModifiableUnboxedIntList extends UnboxedIntListBase {
  ModifiableUnboxedIntList(int length, int capacity) : super(length, capacity);

  @pragma('wasm:prefer-inline')
  void operator []=(int index, int value) {
    IndexError.check(index, _length, indexable: this, name: "[]=");
    _data.write(index, value);
  }

  // List interface.
  void setRange(int start, int end, Iterable<int> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    RangeError.checkNotNegative(skipCount, "skipCount");
    if (iterable is UnboxedIntListBase) {
      _data.copy(start, iterable._data, skipCount, length);
    } else if (iterable is List<int>) {
      // TODO: Use unchecked reads and writes.
      Lists.copy(iterable, skipCount, this, start, length);
    } else {
      Iterator<int> it = iterable.iterator;
      while (skipCount > 0) {
        if (!it.moveNext()) return;
        skipCount--;
      }
      for (int i = start; i < end; i++) {
        if (!it.moveNext()) return;
        _data.write(i, it.current);
      }
    }
  }

  void setAll(int index, Iterable<int> iterable) {
    if (index < 0 || index > this.length) {
      throw RangeError.range(index, 0, this.length, "index");
    }
    List<int> iterableAsList;
    if (identical(this, iterable)) {
      iterableAsList = this;
    } else if (iterable is List<int>) {
      iterableAsList = iterable;
    } else {
      for (var value in iterable) {
        this[index++] = value;
      }
      return;
    }
    int length = iterableAsList.length;
    if (index + length > this.length) {
      throw RangeError.range(index + length, 0, this.length);
    }
    Lists.copy(iterableAsList, 0, this, index, length);
  }
}

class FixedLengthUnboxedIntList extends ModifiableUnboxedIntList
    with FixedLengthListMixin<int> {
  FixedLengthUnboxedIntList(int length) : super(length, length);

  factory FixedLengthUnboxedIntList.filled(int length, int fill) {
    final result = FixedLengthUnboxedIntList(length);
    if (fill != 0) {
      result._data.fill(0, fill, length);
    }
    return result;
  }

  Iterator<int> get iterator {
    return _FixedSizeUnboxedIntListIterator(this);
  }
}

class _FixedSizeUnboxedIntListIterator implements Iterator<int> {
  final UnboxedIntListBase _list;
  final int _length; // Cache list length for faster access.
  int _index;
  int? _current;

  _FixedSizeUnboxedIntListIterator(UnboxedIntListBase list)
      : _list = list,
        _length = list.length,
        _index = 0;

  int get current => _current!;

  bool moveNext() {
    if (_index >= _length) {
      _current = null;
      return false;
    }
    _current = _list._data.readSigned(_index);
    _index++;
    return true;
  }
}

@pragma("wasm:entry-point")
class _ImmutableUnboxedIntList extends UnboxedIntListBase
    with UnmodifiableListMixin<int> {
  factory _ImmutableUnboxedIntList._uninstantiable() {
    throw UnsupportedError(
        "_ImmutableUnboxedIntList can only be allocated by the runtime");
  }

  Iterator<int> get iterator {
    return _FixedSizeUnboxedIntListIterator(this);
  }
}

@pragma("wasm:entry-point")
class GrowableUnboxedIntList extends ModifiableUnboxedIntList {
  GrowableUnboxedIntList(int length) : super(length, length);

  factory GrowableUnboxedIntList.filled(int length, int fill) {
    final result = GrowableUnboxedIntList(length);
    if (fill != 0) {
      result._data.fill(0, fill, length);
    }
    return result;
  }

  void insert(int index, int element) {
    if (index == length) {
      return add(element);
    }

    if ((index < 0) || (index > length)) {
      throw RangeError.range(index, 0, length);
    }

    final WasmIntArray<WasmI64> data;
    if (length == _capacity) {
      data = WasmIntArray<WasmI64>(_nextCapacity(_capacity));
      if (index != 0) {
        // Copy elements before the insertion point.
        data.copy(0, _data, 0, index - 1);
      }
    } else {
      data = _data;
    }

    // Shift elements, or copy elements after insertion point if we allocated a
    // new array.
    data.copy(index + 1, _data, index, length - index);

    // Insert new element.
    data.write(index, element);

    _data = data;
    _length += 1;
  }

  int removeAt(int index) {
    // TODO(omersa): Check if removal will cause shrinking. If it will create a
    // new list directly, instead of first removing the element and then
    // shrinking.
    var result = this[index];
    int newLength = this.length - 1;
    if (index < newLength) {
      _data.copy(index, _data, index + 1, newLength - index);
    }
    this.length = newLength;
    return result;
  }

  bool remove(Object? element) {
    for (int i = 0; i < this.length; i++) {
      if (_data.readSigned(i) == element) {
        removeAt(i);
        return true;
      }
    }
    return false;
  }

  void insertAll(int index, Iterable<int> iterable) {
    if (index < 0 || index > length) {
      throw RangeError.range(index, 0, length);
    }
    if (iterable is! ListImplBase && iterable is! UnboxedIntListBase) {
      // Read out all elements before making room to ensure consistency of the
      // modified list in case the iterator throws.
      iterable = FixedLengthList.of(iterable);
    }
    int insertionLength = iterable.length;
    int capacity = _capacity;
    int newLength = length + insertionLength;
    if (newLength > capacity) {
      do {
        capacity = _nextCapacity(capacity);
      } while (newLength > capacity);
      _grow(capacity);
    }
    _setLength(newLength);
    setRange(index + insertionLength, this.length, this, index);
    setAll(index, iterable);
  }

  void removeRange(int start, int end) {
    RangeError.checkValidRange(start, end, this.length);
    _data.copy(start, _data, end, length - end);
    this.length = this.length - (end - start);
  }

  int get _capacity => _data.length;

  void set length(int newLength) {
    if (newLength > length) {
      if (newLength > _capacity) {
        _grow(newLength);
      }
      _setLength(newLength);
      return;
    }
    final int newCapacity = newLength;
    // We are shrinking. Pick the method which has fewer writes.
    // In the shrink-to-fit path, we write |newCapacity + newLength| words
    // (null init + copy).
    // In the non-shrink-to-fit path, we write |length - newLength| words
    // (null overwrite).
    final bool shouldShrinkToFit =
        (newCapacity + newLength) < (length - newLength);
    if (shouldShrinkToFit) {
      _shrink(newCapacity, newLength);
    } else {
      _data.fill(newLength, 0, length - newLength);
    }
    _setLength(newLength);
  }

  void _setLength(int newLength) {
    _length = newLength;
  }

  void add(int value) {
    var len = length;
    if (len == _capacity) {
      _growToNextCapacity();
    }
    _setLength(len + 1);
    _data.write(len, value);
  }

  void addAll(Iterable<int> iterable) {
    var len = length;
    if (iterable is EfficientLengthIterable) {
      // Pregrow if we know iterable.length.
      var iterLen = iterable.length;
      if (iterLen == 0) {
        return;
      }
      if (identical(iterable, this)) {
        throw ConcurrentModificationError(this);
      }
      var cap = _capacity;
      var newLen = len + iterLen;
      if (newLen > cap) {
        do {
          cap = _nextCapacity(cap);
        } while (newLen > cap);
        _grow(cap);
      }
    }
    Iterator it = iterable.iterator;
    if (!it.moveNext()) return;
    do {
      while (len < _capacity) {
        int newLen = len + 1;
        this._setLength(newLen);
        _data.write(len, it.current);
        if (!it.moveNext()) return;
        if (this.length != newLen) throw ConcurrentModificationError(this);
        len = newLen;
      }
      _growToNextCapacity();
    } while (true);
  }

  int removeLast() {
    var len = length - 1;
    var elem = this[len];
    this.length = len;
    return elem;
  }

  // Shared array used as backing for new empty growable lists.
  static final WasmIntArray<WasmI64> _emptyData = WasmIntArray<WasmI64>(0);

  static WasmIntArray<WasmI64> _allocateData(int capacity) {
    if (capacity < 0) {
      throw RangeError.range(capacity, 0, _maxWasmArrayLength);
    }
    if (capacity == 0) {
      // Use shared empty list as backing.
      return _emptyData;
    }
    return WasmIntArray<WasmI64>(capacity);
  }

  // Grow from 0 to 3, and then double + 1.
  int _nextCapacity(int old_capacity) => (old_capacity * 2) | 3;

  void _grow(int newCapacity) {
    var newData = WasmIntArray<WasmI64>(newCapacity);
    newData.copy(0, _data, 0, length);
    _data = newData;
  }

  void _growToNextCapacity() {
    _grow(_nextCapacity(_capacity));
  }

  void _shrink(int newCapacity, int new_length) {
    var newData = _allocateData(newCapacity);
    newData.copy(0, _data, 0, new_length);
    _data = newData;
  }

  Iterator<int> get iterator => GrowableUnboxedIntListIterator(this);
}

// Iterator for growable lists.
class GrowableUnboxedIntListIterator implements Iterator<int> {
  final GrowableUnboxedIntList _list;
  final int _length; // Cache list length for modification check.
  int _index;
  int? _current;

  GrowableUnboxedIntListIterator(GrowableUnboxedIntList list)
      : _list = list,
        _length = list.length,
        _index = 0;

  int get current => _current!;

  bool moveNext() {
    if (_list.length != _length) {
      throw ConcurrentModificationError(_list);
    }
    if (_index >= _length) {
      _current = null;
      return false;
    }
    _current = _list._data.readSigned(_index);
    _index++;
    return true;
  }
}
