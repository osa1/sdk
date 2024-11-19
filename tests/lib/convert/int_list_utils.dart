// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

/// Based on the size and sign of the integers in [ints], generates a list of
/// [List<int>]s with different implementations.
///
/// The returned list includes:
///
/// 1. The original [ints]
///
/// 2. For N in 8, 16, 32, 64:
///    If the integers are unsigned and fit into N bits, a `UintNList`.
///
/// 3. Same as (2), but the `UintNList` as a sublist view of another
///    `UintNList`.
///
/// 4. Same as (1) and (2), but as `IntNList`.
///
/// The idea is that if you use the returned lists to read the elements in
/// right signed-ness, you get the same integers as [ints].
List<List<int>> makeIntLists(List<int> ints) {
  final List<List<int>> lists = [];

  lists.add(ints);
  lists.add(List.from(ints, growable: true));
  lists.add(List.from(ints, growable: false));
  lists.add(List.unmodifiable(ints));

  final elementSizeInBits = _findElementSizeInBits(ints);

  if (elementSizeInBits <= 7) {
    lists.add(Int8List.fromList(ints));
    lists.add(Int8List.sublistView(Int8List.fromList([0, ...ints]), 1));
  }

  if (elementSizeInBits <= 8) {
    lists.add(Uint8List.fromList(ints));
    lists.add(Uint8List.sublistView(Uint8List.fromList([0, ...ints]), 1));
  }

  if (elementSizeInBits <= 15) {
    lists.add(Int16List.fromList(ints));
    lists.add(Int16List.sublistView(Int16List.fromList([0, ...ints]), 1));
  }

  if (elementSizeInBits <= 16) {
    lists.add(Uint16List.fromList(ints));
    lists.add(Uint16List.sublistView(Uint16List.fromList([0, ...ints]), 1));
  }

  if (elementSizeInBits <= 31) {
    lists.add(Int32List.fromList(ints));
    lists.add(Int32List.sublistView(Int32List.fromList([0, ...ints]), 1));
  }

  if (elementSizeInBits <= 32) {
    lists.add(Uint32List.fromList(ints));
    lists.add(Uint32List.sublistView(Uint32List.fromList([0, ...ints]), 1));
  }

  if (elementSizeInBits <= 63) {
    lists.add(Int64List.fromList(ints));
    lists.add(Int64List.sublistView(Int64List.fromList([0, ...ints]), 1));
  }

  if (elementSizeInBits <= 64) {
    lists.add(Uint64List.fromList(ints));
    lists.add(Uint64List.sublistView(Uint64List.fromList([0, ...ints]), 1));
  }

  return lists;
}

int _findElementSizeInBits(List<int> ints) {
  int size = 0;

  for (int i in ints) {
    int iSize = i.bitLength;
    if (i < 0) {
      iSize += 1;
    }
    if (iSize > size) {
      size = iSize;
    }
  }

  return size;
}
