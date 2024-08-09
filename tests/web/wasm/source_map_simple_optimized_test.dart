// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=-O4 --no-strip-wasm --extra-compiler-option=-DTEST_COMPILATION_DIR=$TEST_COMPILATION_DIR

import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:convert';

import 'source_map_simple_lib.dart' as Lib;

void main() {
  Lib.testMain('source_map_simple_optimized', frameDetails);
}

const List<(int?, int?)?> frameDetails = [
  (null, null), // _throwWithCurrentStackTrace
  (16, 3), // throw in g
  (null, null), // _invokeMain
];

/*
at Error._throwWithCurrentStackTrace (wasm://wasm/0008d98a:wasm-function[129]:0xbf1d)
at main (wasm://wasm/0008d98a:wasm-function[387]:0x117f1)
at _invokeMain (wasm://wasm/0008d98a:wasm-function[96]:0xb22b)
at Module.invoke (...)
at main (...)
at async action (...)
at async eventLoop (...)
*/
