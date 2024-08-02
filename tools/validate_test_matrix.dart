// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the test matrix in the SDK can be parsed correctly.

import 'dart:convert' show jsonDecode;
import 'dart:io' show File, Platform;

import 'package:smith/smith.dart' show TestMatrix;

void main() {
  var path = Platform.script.resolve("bots/test_matrix.json").toFilePath();
  Map<String, dynamic> json;
  try {
    json = jsonDecode(File(path).readAsStringSync());
  } catch (e) {
    print("The test matrix at $path is not valid JSON!\n\n$e");
    return;
  }
  try {
    TestMatrix.fromJson(json);
  } catch (e) {
    print("The test matrix at $path is invalid!\n\n$e");
    return;
  }
}
