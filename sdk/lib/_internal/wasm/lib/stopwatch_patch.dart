// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class Stopwatch {
  static int Function() _timerTicks = () {
    final int ticks = JS<double>("Date.now").toInt();
    print("timerTicks Date.now ticks = $ticks");
    return ticks;
  };

  @patch
  static int _initTicker() {
    if (JS<bool>("() => !!dartUseDateNowForTicks")) {
      print("Using Date.now for ticks");
      // Millisecond precision, as int.
      return 1000;
    } else {
      // Microsecond precision as double. Convert to int without losing
      // precision.
      print("Using performance.now for ticks");
      _timerTicks = () {
        final int ticks = 1000 * JS<double>("performance.now").toInt();
        print("timerTicks performance.now ticks = $ticks");
        return ticks;
      };
      return 1000000;
    }
  }

  @patch
  static int _now() => _timerTicks();

  @patch
  int get elapsedMicroseconds {
    int ticks = elapsedTicks;
    print("elapsedMicroseconds ticks = $ticks");
    if (_frequency == 1000000) return ticks;
    assert(_frequency == 1000);
    return ticks * 1000;
  }

  @patch
  int get elapsedMilliseconds {
    int ticks = elapsedTicks;
    print("elapsedMilliseconds ticks = $ticks");
    if (_frequency == 1000) return ticks;
    assert(_frequency == 1000000);
    return ticks ~/ 1000;
  }
}
