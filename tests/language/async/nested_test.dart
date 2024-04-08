// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

Stream<String> stream() async* {
  yield 'a';
  yield 'b';
}

Stream<String> test() async* {
  final expanded = stream().asyncExpand((s) async* {
    yield 'before';
    yield s;
    yield 'after';
  });

  yield* expanded;
}

void test() async {
  Expect.listEquals(
      ['before', 'a', 'after', 'before', 'b', 'after'], await test().toList());
}

void main() {
  asyncStart();
  test().then((_) => asyncEnd());
}
