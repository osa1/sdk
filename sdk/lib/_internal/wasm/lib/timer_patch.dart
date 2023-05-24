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
  int _tick;
  int? _handle;

  @override
  int get tick => _tick;

  @override
  bool get isActive => _handle != null;

  _Timer(Duration duration)
      : _milliseconds = duration.inMilliseconds.toDouble(),
        _tick = 0,
        _handle = null {
    _schedule();
  }

  void _schedule();
}

class _OneShotTimer extends _Timer {
  final void Function() _callback;

  _OneShotTimer(Duration duration, this._callback) : super(duration);

  @override
  void _schedule() {
    _handle = setTimeout(_milliseconds, () {
      _tick++;
      _handle = null;
      _callback();
    });
  }

  @override
  void cancel() {
    final int? handle = _handle;
    if (handle != null) {
      clearTimeout(handle);
      _handle = null;
    }
  }
}

class _PeriodicTimer extends _Timer {
  final void Function(Timer) _callback;

  _PeriodicTimer(Duration duration, this._callback) : super(duration);

  @override
  void _schedule() {
    _handle = setInterval(_milliseconds, () {
      _tick++;
      _callback(this);
    });
  }

  @override
  void cancel() {
    final int? handle = _handle;
    if (handle != null) {
      clearInterval(handle);
      _handle = null;
    }
  }
}

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    queueMicrotask(callback);
  }
}
