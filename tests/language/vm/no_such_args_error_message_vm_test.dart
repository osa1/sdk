// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=100 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Test error message with misusing Functions and Closures: wrong args
// should result in a message that reports the missing method.

call_with_bar(x) => x("bar");

testClosureMessage() {
  try {
    call_with_bar(() {});
  } catch (e) {
    // The latter may happen if in --dwarf-stack-traces mode.
    final possibleNames = ['testClosureMessage', '<optimized out>'];
    Expect.containsAny(
        possibleNames.map((s) => s + '.<anonymous closure>("bar")').toList(),
        e.toString());
  }
}

noargs() {}

testFunctionMessage() {
  try {
    call_with_bar(noargs);
  } catch (e) {
    final expectedStrings = [
      'Tried calling: noargs("bar")',
    ];
    Expect.containsInOrder(expectedStrings, e.toString());
  }
}

main() {
  for (var i = 0; i < 120; i++) testClosureMessage();
  for (var i = 0; i < 120; i++) testFunctionMessage();
}
