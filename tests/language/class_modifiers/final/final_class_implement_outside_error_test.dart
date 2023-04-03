// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to implement a final class outside of library.

import 'final_class_implement_lib.dart';

abstract final class AOutside implements FinalClass {}
//                                       ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

final class BOutside implements FinalClass {
//                              ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.
  int foo = 1;
}

enum EnumOutside implements ClassForEnum { x }
//                          ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'ClassForEnum' can't be implemented outside of its library because it's a final class.
