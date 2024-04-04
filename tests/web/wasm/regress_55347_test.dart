// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class MyException implements Exception {
  MyException([this.message]);

  final String? message;

  @override
  String toString() => 'MyException($message)';
}

class MyOtherException implements Exception {
  MyOtherException([this.message]);

  final String? message;

  @override
  String toString() => 'MyOtherException($message)';
}

Future<String> asynchronouslyThrowException() async {
  throw MyException('Throwing an error!');
}

Future<String?> test() async {
  try {
    await asynchronouslyThrowException();
    Expect.fail('Exception is not thrown');
  } on MyOtherException {
    Expect.fail('Wrong exception caught');
  } on MyException {
    return 'Success';
  } catch (error) {
    Expect.fail('Wrong exception caught');
  }
  return null;
}

void main() async {
  Expect.equals(await test(), 'Success');
}
