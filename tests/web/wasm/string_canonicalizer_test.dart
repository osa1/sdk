// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_string_canonicalizer';
import 'dart:_typed_data';
import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  final canonicalizer = StringCanonicalizer();

  final bytes = U8List(2);
  bytes[0] = 68;
  bytes[1] = 69;

  final str1 = canonicalizer.canonicalizeBytes(bytes, 0, 2, true);
  final str2 = canonicalizer.canonicalizeBytes(bytes, 0, 2, true);
  Expect.identical(str1, str2);
}
