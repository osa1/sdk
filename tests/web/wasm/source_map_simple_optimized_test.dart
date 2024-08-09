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
    (14, 3), // main
    (null, null), // _invokeMain
];

/*
at Error._throwWithCurrentStackTrace (wasm://wasm/0008d98a:wasm-function[129]:0xbf1d)
at main (wasm://wasm/0008d98a:wasm-function[387]:0x117f1)
at _invokeMain (wasm://wasm/0008d98a:wasm-function[96]:0xb22b)
at Module.invoke (/home/omer/dart/sdk/sdk/out/ReleaseX64/generated_compilations/dart2wasm-linux-d8/tests_web_wasm_source_map_simple_optimized_test/source_map_simple_optimized_test.mjs:317:26)
at main (/home/omer/dart/sdk/sdk/pkg/dart2wasm/bin/run_wasm.js:421:21)
at async action (/home/omer/dart/sdk/sdk/pkg/dart2wasm/bin/run_wasm.js:350:37)
at async eventLoop (/home/omer/dart/sdk/sdk/pkg/dart2wasm/bin/run_wasm.js:327:9)
*/
