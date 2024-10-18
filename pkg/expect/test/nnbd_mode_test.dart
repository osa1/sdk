// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:expect/variations.dart" as variation;

final bool strong = () {
  try {
    int i = null as dynamic; // ignore: unused_local_variable
    return false;
  } catch (e) {
    return true;
  }
}();

void main() {
  Expect.equals(!strong, variation.unsoundNullSafety);
}
