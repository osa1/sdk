// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "async_patch.dart";

// Implementation of `Timer` and `scheduleMicrotask` via the JS event loop.

@patch
class Timer {
  @patch
  static Timer _createTimer(Duration duration, void callback()) {
    return _OneShotTimer(duration, callback);
  }

  @patch
  static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer)) {
    return _PeriodicTimer(duration, callback);
  }
}

abstract class _Timer implements Timer {
  final double _milliseconds;
  bool _isActive;
  int _tick;

  @override
  int get tick => _tick;

  @override
  bool get isActive => _isActive;

  _Timer(Duration duration)
      : _milliseconds = duration.inMilliseconds.toDouble(),
        _isActive = true,
        _tick = 0 {
    _schedule();
  }

  void _schedule() {
    setTimeout(_milliseconds, () {
      if (_isActive) {
        _tick++;
        _run();
      }
    });
  }

  void _run();

  @override
  void cancel() {
    _isActive = false;
  }
}

class _OneShotTimer extends _Timer {
  final void Function() _callback;

  _OneShotTimer(Duration duration, this._callback) : super(duration);

  void _run() {
    _isActive = false;
    _callback();
  }
}

class _PeriodicTimer extends _Timer {
  final void Function(Timer) _callback;

  _PeriodicTimer(Duration duration, this._callback) : super(duration);

  void _run() {
    _schedule();
    _callback(this);
  }
}

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    queueMicrotask(callback);
  }
}
