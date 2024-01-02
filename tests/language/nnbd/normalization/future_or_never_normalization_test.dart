// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

import 'dart:async';

import 'package:expect/expect.dart';

import 'future_or_never_normalization_legacy_lib.dart';

// Tests to ensure normalization of various forms of FutureOr<Never> include
// or exclude null properly.

@pragma('dart2js:noInline')
bool typeTest<T>(dynamic val) => val is T;

@pragma('dart2js:noInline')
bool futureOrTypeTest<T>(dynamic val) => val is FutureOr<T>;

void main() {
  Expect.isTrue(typeTest<FutureOr<Never?>>(null));
  Expect.isTrue(futureOrTypeTest<Never?>(null));
  Expect.isTrue(legacyFutureOrTypeTest<Never?>(null));
  Expect.isFalse(typeTest<FutureOr<Never>>(null));
  Expect.isFalse(legacyTypeTest<FutureOr<Never>>(null));
  Expect.isFalse(futureOrTypeTest<Never>(null));
  Expect.isTrue(legacyFutureOrTypeTest<Never>(null));
  weakTests();
}
