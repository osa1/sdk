// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.test.outline_suite;

import 'suite_utils.dart' show internalMain;
import 'testing/environment_keys.dart';
import 'testing/suite.dart';

Future<FastaContext> createContext(
    Chain suite, Map<String, String> environment) {
  environment[EnvironmentKeys.soundNullSafety] = "true";
  return FastaContext.create(suite, environment);
}

Future<void> main([List<String> arguments = const []]) async {
  await internalMain(
    createContext,
    arguments: arguments,
    displayName: "outline suite",
  );
}
