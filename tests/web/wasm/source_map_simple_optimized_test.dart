// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=-O4 --no-strip-wasm --extra-compiler-option=-DTEST_COMPILATION_DIR=$TEST_COMPILATION_DIR

import 'source_map_simple_lib.dart' as Lib;

void main() {
  Lib.testMain('source_map_simple_optimized', frameDetails);
}

const List<(int?, int?)?> frameDetails = [
  (null, null), // _throwWithCurrentStackTrace
  (16, 3), // g
  (12, 3), // f
  (44, 5), // testMain
  (null, null), // _invokeMain
];

/*
at Error._throwWithCurrentStackTrace (wasm://wasm/0011bbfa:wasm-function[130]:0x16b7a)
at g (wasm://wasm/0011bbfa:wasm-function[766]:0x1fbaf)
at f (wasm://wasm/0011bbfa:wasm-function[763]:0x1fb93)
at testMain (wasm://wasm/0011bbfa:wasm-function[762]:0x1f8c7)
at main (wasm://wasm/0011bbfa:wasm-function[759]:0x1f7f3)
at main tear-off trampoline (wasm://wasm/0011bbfa:wasm-function[761]:0x1f806)
at _invokeMain (wasm://wasm/0011bbfa:wasm-function[90]:0x156aa)
at Module.invoke (...)
*/
