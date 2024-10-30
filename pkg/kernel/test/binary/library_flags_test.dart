// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'utils.dart';

/// Test that library flags are serialized and read correctly.
void main() {
  void setSynthetic(Library lib, bool isSynthetic) {
    lib.isSynthetic = isSynthetic;
  }

  void verifySynthetic(Library lib, bool isSynthetic) {
    if (lib.isSynthetic != isSynthetic) {
      throw "Serialized and re-read library had change in synthetic flag.";
    }
  }

  void setNonNullableByDefaultCompiledMode(Library lib,
      NonNullableByDefaultCompiledMode nonNullableByDefaultCompiledMode) {
    lib.nonNullableByDefaultCompiledMode = nonNullableByDefaultCompiledMode;
  }

  void verifyNonNullableByDefaultCompiledMode(Library lib,
      NonNullableByDefaultCompiledMode nonNullableByDefaultCompiledMode) {
    if (lib.nonNullableByDefaultCompiledMode !=
        nonNullableByDefaultCompiledMode) {
      throw "Serialized and re-read library had change in "
          "nonNullableByDefaultCompiledMode flag.";
    }
  }

  int combination = 0;
  for (bool isSynthetic in [true, false]) {
    for (NonNullableByDefaultCompiledMode nonNullableByDefaultCompiledMode in [
      NonNullableByDefaultCompiledMode.Weak,
      NonNullableByDefaultCompiledMode.Strong,
    ]) {
      combination++;
      print("Checking combination #$combination ("
          "isSynthetic: $isSynthetic; "
          "nonNullableByDefaultCompiledMode:"
          " $nonNullableByDefaultCompiledMode");
      Uri uri = Uri.parse("foo://bar.dart");
      Library lib = new Library(uri, fileUri: uri);
      setSynthetic(lib, isSynthetic);
      setNonNullableByDefaultCompiledMode(
          lib, nonNullableByDefaultCompiledMode);
      Library lib2 = libRoundTrip(lib);
      verifySynthetic(lib2, isSynthetic);
      verifyNonNullableByDefaultCompiledMode(
          lib2, nonNullableByDefaultCompiledMode);
    }
  }

  print("Done: Everything looks good.");
}
