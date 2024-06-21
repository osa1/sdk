// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._list;

import 'dart:_internal';
import 'dart:_wasm';
import 'dart:collection';

part "growable_list.dart";

const int _maxWasmArrayLength = 2147483647; // max i32

@pragma("wasm:entry-point")
abstract class WasmListBase<E> extends ListBase<E> {
  @pragma("wasm:entry-point")
  int _length;

  @pragma("wasm:entry-point")
  WasmArray<Object?> _data;

  WasmListBase(int length, int capacity)
      : _length = length,
        _data = WasmArray<Object?>(
            RangeError.checkValueInInterval(capacity, 0, _maxWasmArrayLength));

  WasmListBase._withData(this._length, this._data);

  @pragma('wasm:prefer-inline')
  E operator [](int index) {
    indexCheckWithName(index, _length, "[]");
    return unsafeCast(_data[index]);
  }

  @pragma('wasm:prefer-inline')
  int get length => _length;

  List<E> sublist(int start, [int? end]) {
    final int listLength = this.length;
    final int actualEnd = RangeError.checkValidRange(start, end, listLength);
    int length = actualEnd - start;
    if (length == 0) return <E>[];
    return GrowableList<E>(length)..setRange(0, length, this, start);
  }

  void forEach(f(E element)) {
    final initialLength = length;
    for (int i = 0; i < initialLength; i++) {
      f(unsafeCast<E>(_data[i]));
      if (length != initialLength) throw ConcurrentModificationError(this);
    }
  }

  @pragma("wasm:prefer-inline")
  List<E> toList({bool growable = true}) => List.from(this, growable: growable);
}

@pragma("wasm:entry-point")
abstract class _ModifiableList<E> extends WasmListBase<E> {
  _ModifiableList(int length, int capacity) : super(length, capacity);

  _ModifiableList._withData(int length, WasmArray<Object?> data)
      : super._withData(length, data);

  @pragma('wasm:prefer-inline')
  void operator []=(int index, E value) {
    indexCheckWithName(index, _length, "[]=");
    _data[index] = value;
  }

  // List interface.
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    RangeError.checkNotNegative(skipCount, "skipCount");
    if (identical(this, iterable)) {
      _data.copy(start, _data, skipCount, length);
    } else if (iterable is List<E>) {
      Lists.copy(iterable, skipCount, this, start, length);
    } else {
      Iterator<E> it = iterable.iterator;
      while (skipCount > 0) {
        if (!it.moveNext()) return;
        skipCount--;
      }
      for (int i = start; i < end; i++) {
        if (!it.moveNext()) return;
        _data[i] = it.current;
      }
    }
  }

  void setAll(int index, Iterable<E> iterable) {
    if (index < 0 || index > this.length) {
      throw RangeError.range(index, 0, this.length, "index");
    }
    List<E> iterableAsList;
    if (identical(this, iterable)) {
      iterableAsList = this;
    } else if (iterable is List<E>) {
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

@pragma("wasm:entry-point")
class ModifiableFixedLengthList<E> extends _ModifiableList<E>
    with FixedLengthListMixin<E> {
  ModifiableFixedLengthList._(int length) : super(length, length);

  factory ModifiableFixedLengthList(int length) =>
      ModifiableFixedLengthList._(length);

  // Specialization of List.empty constructor for growable == false.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  factory ModifiableFixedLengthList.empty() => ModifiableFixedLengthList<E>(0);

  // Specialization of List.filled constructor for growable == false.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  factory ModifiableFixedLengthList.filled(int length, E fill) {
    final result = ModifiableFixedLengthList<E>(length);
    if (fill != null) {
      result._data.fill(0, fill, length);
    }
    return result;
  }

  // Specialization of List.generate constructor for growable == false.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  factory ModifiableFixedLengthList.generate(
      int length, E generator(int index)) {
    final result = ModifiableFixedLengthList<E>(length);
    for (int i = 0; i < result.length; ++i) {
      result._data[i] = generator(i);
    }
    return result;
  }

  // Specialization of List.of constructor for growable == false.
  factory ModifiableFixedLengthList.of(Iterable<E> elements) {
    if (elements is WasmListBase) {
      return ModifiableFixedLengthList._ofListBase(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return ModifiableFixedLengthList._ofEfficientLengthIterable(
          unsafeCast(elements));
    }
    return ModifiableFixedLengthList.fromIterable(elements);
  }

  factory ModifiableFixedLengthList._ofListBase(WasmListBase<E> elements) {
    final int length = elements.length;
    final list = ModifiableFixedLengthList<E>(length);
    list._data.copy(0, elements._data, 0, length);
    return list;
  }

  factory ModifiableFixedLengthList._ofEfficientLengthIterable(
      EfficientLengthIterable<E> elements) {
    final int length = elements.length;
    final list = ModifiableFixedLengthList<E>(length);
    if (length > 0) {
      int i = 0;
      for (var element in elements) {
        list[i++] = element;
      }
      if (i != length) throw ConcurrentModificationError(elements);
    }
    return list;
  }

  factory ModifiableFixedLengthList.fromIterable(Iterable<E> elements) {
    // The static type of `makeListFixedLength` is `List<E>`, not `ModifiableFixedLengthList<E>`,
    // but we know that is what it does.  `makeListFixedLength` is too generally
    // typed since it is available on the web platform which has different
    // system List types.
    return unsafeCast(
        makeListFixedLength(GrowableList<E>.fromIterable(elements)));
  }

  Iterator<E> get iterator {
    return _FixedSizeListIterator<E>(this);
  }
}

@pragma("wasm:entry-point")
class ImmutableLIst<E> extends WasmListBase<E> with UnmodifiableListMixin<E> {
  factory ImmutableLIst._uninstantiable() {
    throw UnsupportedError(
        "ImmutableLIst can only be allocated by the runtime");
  }

  Iterator<E> get iterator {
    return _FixedSizeListIterator<E>(this);
  }
}

// Iterator for lists with fixed size.
class _FixedSizeListIterator<E> implements Iterator<E> {
  final WasmArray<Object?> _data;
  final int _length; // Cache list length for faster access.
  int _index;
  E? _current;

  _FixedSizeListIterator(WasmListBase<E> list)
      : _data = list._data,
        _length = list.length,
        _index = 0 {
    assert(list is ModifiableFixedLengthList<E> || list is ImmutableLIst<E>);
  }

  E get current => _current as E;

  bool moveNext() {
    if (_index >= _length) {
      _current = null;
      return false;
    }
    _current = unsafeCast(_data[_index]);
    _index++;
    return true;
  }
}
