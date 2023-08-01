// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Finalizable<T> {
  int id;
  T? _value;

  Finalizable(this.id);

  set value(T v) => finalize(v);

  T get value {
    final v = _value;
    if (v == null) {
      throw 'Value not yet finalized';
    }
    return v;
  }

  void finalize(T v) {
    if (_value != null) {
      throw 'Value already finalized';
    }
    _value = v;
  }

  bool get isFinal => _value == null;

  @override
  String toString() => isFinal ? '$_value' : '<$id>';
}

typedef FinalizableIndex = Finalizable<int>;
