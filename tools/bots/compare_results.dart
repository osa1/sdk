#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Compare the old and new test results and list tests that pass the filters.
// The output contains additional details in the verbose mode. There is a human
// readable mode that explains the results and how they changed.

import '../../pkg/test_runner/bin/compare_results.dart' as compare_results;

void main(List<String> args) {
  compare_results.main(args);
}
