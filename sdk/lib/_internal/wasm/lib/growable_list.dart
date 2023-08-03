// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._growable_list;

import "dart:_internal";
import "dart:_list";
import "dart:_wasm";

const int _maxWasmArrayLength = 2147483647; // max i32

@pragma("wasm:entry-point")
class GrowableList<E> extends ModifiableList<E> {
  void insert(int index, E element) {
    if (index == length) {
      return add(element);
    }

    if ((index < 0) || (index > length)) {
      throw RangeError.range(index, 0, length);
    }

    final WasmObjectArray<Object?> data;
    if (length == _capacity) {
      data = WasmObjectArray<Object?>(_nextCapacity(_capacity));
      if (index != 0) {
        // Copy elements before the insertion point.
        data.copy(0, internalData, 0, index - 1);
      }
    } else {
      data = internalData;
    }

    // Shift elements, or copy elements after insertion point if we allocated a
    // new array.
    data.copy(index + 1, internalData, index, length - index);

    // Insert new element.
    data.write(index, element);

    internalData = data;
    internalLength += 1;
  }

  E removeAt(int index) {
    // TODO(omersa): Check if removal will cause shrinking. If it will create a
    // new list directly, instead of first removing the element and then
    // shrinking.
    var result = this[index];
    int newLength = this.length - 1;
    if (index < newLength) {
      internalData.copy(index, internalData, index + 1, newLength - index);
    }
    this.length = newLength;
    return result;
  }

  bool remove(Object? element) {
    for (int i = 0; i < this.length; i++) {
      if (internalData.read(i) == element) {
        removeAt(i);
        return true;
      }
    }
    return false;
  }

  void insertAll(int index, Iterable<E> iterable) {
    if (index < 0 || index > length) {
      throw RangeError.range(index, 0, length);
    }
    if (iterable is! ListImplBase) {
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
    internalData.copy(start, internalData, end, length - end);
    this.length = this.length - (end - start);
  }

  GrowableList._(int length, int capacity) : super(length, capacity);

  factory GrowableList(int length) {
    return GrowableList<E>._(length, length);
  }

  factory GrowableList.withCapacity(int capacity) {
    return GrowableList<E>._(0, capacity);
  }

  // Specialization of List.empty constructor for growable == true.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  factory GrowableList.empty() => GrowableList(0);

  // Specialization of List.filled constructor for growable == true.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  factory GrowableList.filled(int length, E fill) {
    final result = GrowableList<E>(length);
    if (fill != null) {
      result.internalData.fill(0, fill, length);
    }
    return result;
  }

  // Specialization of List.generate constructor for growable == true.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  factory GrowableList.generate(int length, E generator(int index)) {
    final result = GrowableList<E>(length);
    for (int i = 0; i < result.length; ++i) {
      result.internalData.write(i, generator(i));
    }
    return result;
  }

  // Specialization of List.of constructor for growable == true.
  factory GrowableList.of(Iterable<E> elements) {
    if (elements is ListImplBase) {
      return GrowableList._ofListBase(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return GrowableList._ofEfficientLengthIterable(unsafeCast(elements));
    }
    return GrowableList.ofOther(elements);
  }

  factory GrowableList._ofListBase(ListImplBase<E> elements) {
    final int length = elements.length;
    final list = GrowableList<E>(length);
    list.internalData.copy(0, elements.internalData, 0, length);
    return list;
  }

  factory GrowableList._ofEfficientLengthIterable(
      EfficientLengthIterable<E> elements) {
    final int length = elements.length;
    final list = GrowableList<E>(length);
    if (length > 0) {
      int i = 0;
      for (var element in elements) {
        list[i++] = element;
      }
      if (i != length) throw ConcurrentModificationError(elements);
    }
    return list;
  }

  factory GrowableList.ofOther(Iterable<E> elements) {
    final list = GrowableList<E>(0);
    for (var elements in elements) {
      list.add(elements);
    }
    return list;
  }

  GrowableList.withData(WasmObjectArray<Object?> data)
      : super.withData(data.length, data);

  int get _capacity => internalData.length;

  void set length(int newLength) {
    if (newLength > length) {
      // Verify that element type is nullable.
      null as E;
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
      internalData.fill(newLength, null, length - newLength);
    }
    _setLength(newLength);
  }

  void _setLength(int newLength) {
    internalLength = newLength;
  }

  void add(E value) {
    var len = length;
    if (len == _capacity) {
      _growToNextCapacity();
    }
    _setLength(len + 1);
    internalData.write(len, value);
  }

  void addAll(Iterable<E> iterable) {
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
        internalData.write(len, it.current);
        if (!it.moveNext()) return;
        if (this.length != newLen) throw ConcurrentModificationError(this);
        len = newLen;
      }
      _growToNextCapacity();
    } while (true);
  }

  E removeLast() {
    var len = length - 1;
    var elem = this[len];
    this.length = len;
    return elem;
  }

  // Shared array used as backing for new empty growable lists.
  static final WasmObjectArray<Object?> _emptyData =
      WasmObjectArray<Object?>(0);

  static WasmObjectArray<Object?> _allocateData(int capacity) {
    if (capacity < 0) {
      throw RangeError.range(capacity, 0, _maxWasmArrayLength);
    }
    if (capacity == 0) {
      // Use shared empty list as backing.
      return _emptyData;
    }
    return WasmObjectArray<Object?>(capacity);
  }

  // Grow from 0 to 3, and then double + 1.
  int _nextCapacity(int old_capacity) => (old_capacity * 2) | 3;

  void _grow(int newCapacity) {
    var newData = WasmObjectArray<Object?>(newCapacity);
    newData.copy(0, internalData, 0, length);
    internalData = newData;
  }

  void _growToNextCapacity() {
    _grow(_nextCapacity(_capacity));
  }

  void _shrink(int newCapacity, int newinternalLength) {
    var newData = _allocateData(newCapacity);
    newData.copy(0, internalData, 0, newinternalLength);
    internalData = newData;
  }

  Iterator<E> get iterator {
    return GrowableListIterator<E>(this);
  }
}

// Iterator for growable lists.
class GrowableListIterator<E> implements Iterator<E> {
  final GrowableList<E> _list;
  final int internalLength; // Cache list length for modification check.
  int _index;
  E? _current;

  GrowableListIterator(GrowableList<E> list)
      : _list = list,
        internalLength = list.length,
        _index = 0;

  E get current => _current as E;

  bool moveNext() {
    if (_list.length != internalLength) {
      throw ConcurrentModificationError(_list);
    }
    if (_index >= internalLength) {
      _current = null;
      return false;
    }
    _current = unsafeCast(_list.internalData.read(_index));
    _index++;
    return true;
  }
}
