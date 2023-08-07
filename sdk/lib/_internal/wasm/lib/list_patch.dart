// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_growable_list';
import 'dart:_internal';
import 'dart:_list';
import 'dart:_unboxed_int_list';

@patch
class List<E> {
  @patch
  factory List.empty({bool growable = false}) {
    if (E == int) {
      return unsafeCast<List<E>>(
          growable ? GrowableUnboxedIntList(0) : FixedLengthUnboxedIntList(0));
    } else {
      return growable ? <E>[] : FixedLengthList<E>(0);
    }
  }

  @patch
  factory List.filled(int length, E fill, {bool growable = false}) {
    if (E == int) {
      return unsafeCast<List<E>>(growable
          ? GrowableUnboxedIntList.filled(length, unsafeCast<int>(fill))
          : FixedLengthUnboxedIntList.filled(length, unsafeCast<int>(fill)));
    } else {
      return growable
          ? GrowableList<E>.filled(length, fill)
          : FixedLengthList<E>.filled(length, fill);
    }
  }

  @patch
  factory List.from(Iterable elements, {bool growable = true}) {
    // If elements is an Iterable<E>, we won't need a type-test for each
    // element.
    if (elements is Iterable<E>) {
      return List.of(elements, growable: growable);
    }

    List<E> list = GrowableList<E>(0);
    for (E e in elements) {
      list.add(e);
    }
    if (growable) return list;
    return makeListFixedLength(list);
  }

  @patch
  factory List.of(Iterable<E> elements, {bool growable = true}) {
    if (growable) {
      return GrowableList.of(elements);
    } else {
      return FixedLengthList.of(elements);
    }
  }

  @patch
  factory List.generate(int length, E generator(int index),
      {bool growable = true}) {
    if (growable) {
      return GrowableList<E>.generate(length, generator);
    } else {
      return FixedLengthList<E>.generate(length, generator);
    }
  }

  @patch
  factory List.unmodifiable(Iterable elements) {
    final result = List<E>.from(elements, growable: false);
    return makeFixedListUnmodifiable(result);
  }
}
