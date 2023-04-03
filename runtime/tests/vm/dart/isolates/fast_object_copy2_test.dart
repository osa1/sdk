// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--no-enable-fast-object-copy
// VMOptions=--enable-fast-object-copy
// VMOptions=--no-enable-fast-object-copy --gc-on-foc-slow-path --force-evacuation
// VMOptions=--enable-fast-object-copy --gc-on-foc-slow-path --force-evacuation

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'fast_object_copy_test.dart'
    show UserObject, SendReceiveTestBase, notAllocatableInTLAB;

topLevelClosure(a, b) {}
topLevelClosureG<T>(T a, T b) {}
Type getType<T>() => T;

class A<T> {
  dynamic m<H>(T a, H b) => this;
}

// When running with isolate groups enabled, we can share all of the following
// objects.
final sharableObjects = [
  1,
  0xffffffffffffffff,
  'foobar',
  const UserObject(1, 1.2, ''),
  (() {
    final rp = ReceivePort();
    final sp = rp.sendPort;
    rp.close();
    return sp;
  })(),
  () {
    innerClosure(a, b) {}
    return innerClosure;
  }(),
  () {
    innerClosureG<T>(T a, T b) {}
    return innerClosureG;
  }(),
  () {
    innerClosureG<T>() {
      innerClosureG2<H>(T a, H b) {}
      return innerClosureG2;
    }

    return innerClosureG<int>();
  }(),
  () {
    innerClosureG<T>(T a, T b) {}
    final Function(int, int) partialInstantiatedInnerClosure = innerClosureG;
    return partialInstantiatedInnerClosure;
  }(),
  () {
    return topLevelClosureG;
  }(),
  () {
    final Function(int, int) partialInstantiatedInnerClosure = topLevelClosureG;
    return partialInstantiatedInnerClosure;
  }(),
  getType<void Function(int, double, Object)>(),
  getType<T Function<T>(int, double, T)>(),
  const [1, 2, 3],
  const {1: 1, 2: 2, 3: 2},
  const {1, 2, 3},
  RegExp('a'),
  Isolate.current.pauseCapability,
  Int32x4(1, 2, 3, 4),
  Float32x4(1.0, 2.0, 3.0, 4.0),
  Float64x2(1.0, 2.0),
  StackTrace.current,
];

final copyableClosures = <dynamic>[
  () {
    final a = A<int>();
    final Function<T>(int, T) genericMethod = a.m;
    return genericMethod;
  }(),
  () {
    final a = A<int>();
    final Function(int, double) partialInstantiatedMethod = a.m;
    return partialInstantiatedMethod;
  }(),
  () {
    final a = Object();
    dynamic inner() => a;
    return inner;
  }(),
  () {
    foo(var arg) {
      return () => arg;
    }

    return foo(1);
  }(),
];

class SendReceiveTest extends SendReceiveTestBase {
  Future runTests() async {
    await testSharable();
    await testSharable2();
    await testCopyableClosures();
    await testSharableTypedData();
  }

  Future testSharable() async {
    print('testSharable');
    final sharableObjectsCopy = await sendReceive([
      ...sharableObjects,
    ]);
    Expect.notIdentical(sharableObjects, sharableObjectsCopy);
    for (int i = 0; i < sharableObjects.length; ++i) {
      Expect.identical(sharableObjects[i], sharableObjectsCopy[i]);
    }
  }

  Future testSharable2() async {
    print('testSharable2');
    final sharableObjectsCopy = await sendReceive([
      notAllocatableInTLAB,
      ...sharableObjects,
    ]);
    Expect.notIdentical(sharableObjects, sharableObjectsCopy);
    Expect.equals(
        notAllocatableInTLAB[0], (sharableObjectsCopy[0] as Uint8List)[0]);
    for (int i = 0; i < sharableObjects.length; ++i) {
      Expect.identical(sharableObjects[i], sharableObjectsCopy[i + 1]);
    }
  }

  Future testCopyableClosures() async {
    print('testCopyableClosures');
    final copy = await sendReceive([
      notAllocatableInTLAB,
      ...copyableClosures,
    ]);
    for (int i = 0; i < copyableClosures.length; ++i) {
      Expect.notIdentical(copyableClosures[i], copy[1 + i]);
      Expect.equals(copyableClosures[i].runtimeType, copy[1 + i].runtimeType);
    }

    final copy2 = await sendReceive([
      ...copyableClosures,
      notAllocatableInTLAB,
    ]);
    for (int i = 0; i < copyableClosures.length; ++i) {
      Expect.notIdentical(copyableClosures[i], copy2[i]);
      Expect.equals(copyableClosures[i].runtimeType, copy2[i].runtimeType);
    }
  }

  Future testSharableTypedData() async {
    print('testSharableTypedData');
    const int Dart_TypedData_kUint8 = 2;
    const int count = 10;
    final bytes = malloc.allocate<Uint8>(count);
    msanUnpoison(bytes, count);
    final td = createUnmodifiableTypedData(
        Dart_TypedData_kUint8, bytes, count, nullptr, 0, nullptr);
    Expect.equals(count, td.length);

    {
      final copiedTd = await sendReceive(td);
      Expect.identical(td, copiedTd);
    }

    malloc.free(bytes);
  }
}

main() async {
  await SendReceiveTest().run();
}

@Native<
        Handle Function(
            Int, Pointer<Uint8>, IntPtr, Pointer<Void>, IntPtr, Pointer<Void>)>(
    symbol: "Dart_NewUnmodifiableExternalTypedDataWithFinalizer")
external Uint8List createUnmodifiableTypedData(int type, Pointer<Uint8> data,
    int length, Pointer<Void> peer, int externalSize, Pointer<Void> callback);

final msanUnpoisonPointer =
    DynamicLibrary.process().providesSymbol("__msan_unpoison")
        ? DynamicLibrary.process()
            .lookup<NativeFunction<Void Function(Pointer<Void>, Size)>>(
                "__msan_unpoison")
        : nullptr;

void msanUnpoison(Pointer<Uint8> pointer, int size) {
  if (msanUnpoisonPointer != nullptr) {
    msanUnpoisonPointer.asFunction<void Function(Pointer<Void>, int)>()(
        pointer.cast(), size);
  }
}
