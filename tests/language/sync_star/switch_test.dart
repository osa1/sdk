// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests yielding in `switch` statements.

import "package:expect/expect.dart";

Iterable<int> test(int x) sync* {
  yield 0;
  switch (x) {
    a:
    case 0:
      yield 1;
      yield 2;
      continue b;
    case 1:
      yield 3;
      yield 4;
      continue a;
    b:
    default:
      yield 5;
      yield 6;
  }
  yield 7;
}

void main() {
  Expect.listEquals(test(0).toList(), [0, 1, 2, 5, 6, 7]);
  Expect.listEquals(test(1).toList(), [0, 3, 4, 1, 2, 5, 6, 7]);
  Expect.listEquals(test(2).toList(), [0, 5, 6, 7]);
}
