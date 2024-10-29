// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_string_canonicalizer';
import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  final canonicalizer = StringCanonicalizer();

  final str1 =
      canonicalizer.canonicalizeBytes(Uint8List.fromList([68, 69]), 0, 2, true);

  final str2 =
      canonicalizer.canonicalizeBytes(Uint8List.fromList([68, 69]), 0, 2, true);

  Expect.identical(str1, str2);
}
