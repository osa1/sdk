// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef _ = BB;

class AA {}

class BB extends AA {}

class A<T, U extends AA> {}

class B<_, _ extends AA> extends A<_, _> {
  int foo<_ extends _>([int _ = 2]) => 1;
}

class C<T, _ extends _> extends A<T, _> {
  static const int _ = 1;
}

class D<_, _> {}

class DoesNotUseTypeVariable<_> {
  Type returnsBB() {
    return _;
  }

  Type alsoReturnsBB<_, _ extends int>() {
    return _;
  }
}
