// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma("wasm:export", "\$stringAllocate1")
String _stringAllocate1(double length) {
  return allocateOneByteString(length.toInt());
}

@pragma("wasm:export", "\$stringWrite1")
void _stringWrite1(String string, double index, double codePoint) {
  writeIntoOneByteString(string, index.toInt(), codePoint.toInt());
}

@pragma("wasm:export", "\$stringAllocate2")
String _stringAllocate2(double length) {
  return allocateTwoByteString(length.toInt());
}

@pragma("wasm:export", "\$stringWrite2")
void _stringWrite2(String string, double index, double codePoint) {
  writeIntoTwoByteString(string, index.toInt(), codePoint.toInt());
}
