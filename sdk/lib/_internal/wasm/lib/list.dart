// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._list;

import "dart:_growable_list";
import "dart:_internal";
import "dart:_wasm";
import "dart:collection";

const int _maxWasmArrayLength = 2147483647; // max i32

@pragma("wasm:entry-point")
abstract class ListImplBase<E> extends ListBase<E> {
  @pragma("wasm:entry-point")
  int internalLength;

  @pragma("wasm:entry-point")
  WasmObjectArray<Object?> internalData;

  ListImplBase(int length, int capacity)
      : internalLength = length,
        internalData = WasmObjectArray<Object?>(
            RangeError.checkValueInInterval(capacity, 0, _maxWasmArrayLength));

  ListImplBase.withData(this.internalLength, this.internalData);

  E operator [](int index) {
    IndexError.check(index, internalLength, indexable: this, name: "[]");
    return unsafeCast(internalData.read(index));
  }

  int get length => internalLength;

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
      f(unsafeCast<E>(internalData.read(i)));
      if (length != initialLength) throw ConcurrentModificationError(this);
    }
  }

  List<E> toList({bool growable = true}) {
    return List.from(this, growable: growable);
  }
}

@pragma("wasm:entry-point")
abstract class ModifiableList<E> extends ListImplBase<E> {
  ModifiableList(int length, int capacity) : super(length, capacity);

  ModifiableList.withData(int length, WasmObjectArray<Object?> data)
      : super.withData(length, data);

  void operator []=(int index, E value) {
    IndexError.check(index, internalLength, indexable: this, name: "[]=");
    internalData.write(index, value);
  }

  // List interface.
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    RangeError.checkNotNegative(skipCount, "skipCount");
    if (iterable is ListImplBase) {
      internalData.copy(start, unsafeCast<ListImplBase>(iterable).internalData,
          skipCount, length);
    } else if (iterable is List<E>) {
      // TODO: Use unchecked reads and writes.
      Lists.copy(iterable, skipCount, this, start, length);
    } else {
      Iterator<E> it = iterable.iterator;
      while (skipCount > 0) {
        if (!it.moveNext()) return;
        skipCount--;
      }
      for (int i = start; i < end; i++) {
        if (!it.moveNext()) return;
        internalData.write(i, it.current);
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
class FixedLengthList<E> extends ModifiableList<E>
    with FixedLengthListMixin<E> {
  FixedLengthList._(int length) : super(length, length);

  factory FixedLengthList(int length) => FixedLengthList._(length);

  // Specialization of List.empty constructor for growable == false.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  factory FixedLengthList.empty() => FixedLengthList<E>(0);

  // Specialization of List.filled constructor for growable == false.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  factory FixedLengthList.filled(int length, E fill) {
    final result = FixedLengthList<E>(length);
    if (fill != null) {
      result.internalData.fill(0, fill, length);
    }
    return result;
  }

  // Specialization of List.generate constructor for growable == false.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  factory FixedLengthList.generate(int length, E generator(int index)) {
    final result = FixedLengthList<E>(length);
    for (int i = 0; i < result.length; ++i) {
      result.internalData.write(i, generator(i));
    }
    return result;
  }

  // Specialization of List.of constructor for growable == false.
  factory FixedLengthList.of(Iterable<E> elements) {
    if (elements is ListImplBase) {
      return FixedLengthList._ofListBase(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return FixedLengthList._ofEfficientLengthIterable(unsafeCast(elements));
    }
    return FixedLengthList.ofOther(elements);
  }

  factory FixedLengthList._ofListBase(ListImplBase<E> elements) {
    final int length = elements.length;
    final list = FixedLengthList<E>(length);
    list.internalData.copy(0, elements.internalData, 0, length);
    return list;
  }

  factory FixedLengthList._ofEfficientLengthIterable(
      EfficientLengthIterable<E> elements) {
    final int length = elements.length;
    final list = FixedLengthList<E>(length);
    if (length > 0) {
      int i = 0;
      for (var element in elements) {
        list[i++] = element;
      }
      if (i != length) throw ConcurrentModificationError(elements);
    }
    return list;
  }

  factory FixedLengthList.ofOther(Iterable<E> elements) {
    // The static type of `makeListFixedLength` is `List<E>`, not `FixedLengthList<E>`,
    // but we know that is what it does.  `makeListFixedLength` is too generally
    // typed since it is available on the web platform which has different
    // system List types.
    return unsafeCast(makeListFixedLength(GrowableList<E>.ofOther(elements)));
  }

  Iterator<E> get iterator {
    return _FixedSizeListIterator<E>(this);
  }
}

@pragma("wasm:entry-point")
class _ImmutableList<E> extends ListImplBase<E> with UnmodifiableListMixin<E> {
  factory _ImmutableList._uninstantiable() {
    throw UnsupportedError(
        "_ImmutableList can only be allocated by the runtime");
  }

  Iterator<E> get iterator {
    return _FixedSizeListIterator<E>(this);
  }
}

// Iterator for lists with fixed size.
class _FixedSizeListIterator<E> implements Iterator<E> {
  final ListImplBase<E> _list;
  final int internalLength; // Cache list length for faster access.
  int _index;
  E? _current;

  _FixedSizeListIterator(ListImplBase<E> list)
      : _list = list,
        internalLength = list.length,
        _index = 0 {
    assert(list is FixedLengthList<E> || list is _ImmutableList<E>);
  }

  E get current => _current as E;

  bool moveNext() {
    if (_index >= internalLength) {
      _current = null;
      return false;
    }
    _current = unsafeCast(_list.internalData.read(_index));
    _index++;
    return true;
  }
}
