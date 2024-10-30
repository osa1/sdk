// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It's an error to have two initializing formals named `_`.

// SharedOptions=--enable-experiment=wildcard-variables

class C {
  var _;

  C(this._, this._);
//^
// [analyzer] unspecified
// [cfe] unspecified

  C.named(this._, this._);
//^
// [analyzer] unspecified
// [cfe] unspecified
}
