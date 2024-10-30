// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void Callback<T>(T x);

class Foo<T> {
  final T finalField;
  final Callback<T> callbackField;

  late T mutableField;
  late Callback<T> mutableCallbackField;

  Foo(this.finalField, this.callbackField);

  void method(T x) {}

  set setter(T x) {}

  void withCallback(Callback<T> callback) {
    callback(finalField);
  }
}

main() {
  Foo<int> fooInt = new Foo<int>(1, (int x) {});

  fooInt.method(3);
  fooInt.setter = 3;
  fooInt.withCallback((int x) {});
  fooInt.withCallback((num x) {});
  fooInt.mutableField = 3;
  fooInt.mutableCallbackField = (int x) {};

  Foo<num> fooNum = fooInt;
  fooNum.method(3);
  throws(() => fooNum.method(2.5));
  fooNum.setter = 3;
  throws(() => fooNum.setter = 2.5);
  fooNum.withCallback((num x) {});
  fooNum.mutableField = 3;
  throws(() => fooNum.mutableField = 2.5);
  throws(() => fooNum.mutableCallbackField(3));
  throws(() => fooNum.mutableCallbackField(2.5));
  fooNum.mutableCallbackField = (num x) {};
}

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Missing exception';
}
