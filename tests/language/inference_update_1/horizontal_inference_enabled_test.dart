// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when the feature is enabled, inferred types can flow
// "horizontally" from a non-closure argument of an invocation to a closure
// argument.

// @dart=2.18

import 'package:expect/static_type_helper.dart';

testLaterUnnamedParameter(void Function<T>(T, void Function(T)) f) {
  f(0, (x) {
    x.expectStaticType<Exactly<int>>();
  });
}

/// This special case verifies that the implementations correctly associate the
/// zeroth positional parameter with the corresponding argument (even if that
/// argument isn't in the zeroth position at the call site).
testLaterUnnamedParameterDependsOnNamedParameter(
    void Function<T>(void Function(T), {required T a}) f) {
  f(a: 0, (x) {
    x.expectStaticType<Exactly<int>>();
  });
}

testEarlierUnnamedParameter(void Function<T>(void Function(T), T) f) {
  f((x) {
    x.expectStaticType<Exactly<int>>();
  }, 0);
}

testLaterNamedParameter(
    void Function<T>({required T a, required void Function(T) b}) f) {
  f(
      a: 0,
      b: (x) {
        x.expectStaticType<Exactly<int>>();
      });
}

testEarlierNamedParameter(
    void Function<T>({required void Function(T) a, required T b}) f) {
  f(
      a: (x) {
        x.expectStaticType<Exactly<int>>();
      },
      b: 0);
}

/// This special case verifies that the implementations correctly associate the
/// zeroth positional parameter with the corresponding argument (even if that
/// argument isn't in the zeroth position at the call site).
testEarlierNamedParameterDependsOnUnnamedParameter(
    void Function<T>(T b, {required void Function(T) a}) f) {
  f(a: (x) {
    x.expectStaticType<Exactly<int>>();
  }, 0);
}

testPropagateToReturnType(U Function<T, U>(T, U Function(T)) f) {
  f(0, (x) => [x]).expectStaticType<Exactly<List<int>>>();
}

testFold(List<int> list) {
  var a = list.fold(
      0,
      (x, y) =>
          (x..expectStaticType<Exactly<int>>()) +
          (y..expectStaticType<Exactly<int>>()));
  a.expectStaticType<Exactly<int>>();
}

// The test cases below exercise situations where there are multiple closures in
// the invocation, and they need to be inferred in the right order.

testClosureAsParameterType(U Function<T, U>(T, U Function(T)) f) {
  f(() => 0, (h) => [h()]..expectStaticType<Exactly<List<int>>>())
      .expectStaticType<Exactly<List<int>>>();
}

testPropagateToEarlierClosure(U Function<T, U>(U Function(T), T Function()) f) {
  f((x) => [x]..expectStaticType<Exactly<List<int>>>(), () => 0)
      .expectStaticType<Exactly<List<int>>>();
}

testPropagateToLaterClosure(U Function<T, U>(T Function(), U Function(T)) f) {
  f(() => 0, (x) => [x]..expectStaticType<Exactly<List<int>>>())
      .expectStaticType<Exactly<List<int>>>();
}

testLongDependencyChain(
    V Function<T, U, V>(T Function(), U Function(T), V Function(U)) f) {
  f(() => [0], (x) => x.single..expectStaticType<Exactly<int>>(),
          (y) => {y}..expectStaticType<Exactly<Set<int>>>())
      .expectStaticType<Exactly<Set<int>>>();
}

testDependencyCycle(Map<T, U> Function<T, U>(T Function(U), U Function(T)) f) {
  f((x) => [x]..expectStaticType<Exactly<List<Object?>>>(),
          (y) => {y}..expectStaticType<Exactly<Set<Object?>>>())
      .expectStaticType<Exactly<Map<List<Object?>, Set<Object?>>>>();
}

testNecessaryDueToWrongExplicitParameterType(List<int> list) {
  var a = list.fold(
      0,
      (x, int y) =>
          (x..expectStaticType<Exactly<int>>()) +
          (y..expectStaticType<Exactly<int>>()));
  a.expectStaticType<Exactly<int>>();
}

testPropagateFromContravariantReturnType(
    U Function<T, U>(void Function(T) Function(), U Function(T)) f) {
  f(() => (int i) {}, (x) => [x]..expectStaticType<Exactly<List<int>>>())
      .expectStaticType<Exactly<List<int>>>();
}

testPropagateToContravariantParameterType(
    U Function<T, U>(T Function(), U Function(void Function(T))) f) {
  f(() => 0, (x) => [x]..expectStaticType<Exactly<List<void Function(int)>>>())
      .expectStaticType<Exactly<List<void Function(int)>>>();
}

testReturnTypeRefersToMultipleTypeVars(
    void Function<T, U>(
            Map<T, U> Function(), void Function(T), void Function(U))
        f) {
  f(() => {0: ''}, (k) {
    k.expectStaticType<Exactly<int>>();
  }, (v) {
    v.expectStaticType<Exactly<String>>();
  });
}

testUnnecessaryDueToNoDependency(T Function<T>(T Function(), T) f) {
  f(() => 0, null).expectStaticType<Exactly<int?>>();
}

testUnnecessaryDueToExplicitParameterType(List<int> list) {
  var a = list.fold(null, (int? x, y) => (x ?? 0) + y);
  a.expectStaticType<Exactly<int?>>();
}

testUnnecessaryDueToExplicitParameterTypeNamed(
    T Function<T>(T, T Function({required T x, required int y})) f) {
  var a = f(null, ({int? x, required y}) => (x ?? 0) + y);
  a.expectStaticType<Exactly<int?>>();
}

testParenthesized(void Function<T>(T, void Function(T)) f) {
  f(0, ((x) {
    x.expectStaticType<Exactly<int>>();
  }));
}

testParenthesizedNamed(
    void Function<T>({required T a, required void Function(T) b}) f) {
  f(
      a: 0,
      b: ((x) {
        x.expectStaticType<Exactly<int>>();
      }));
}

testParenthesizedTwice(void Function<T>(T, void Function(T)) f) {
  f(0, (((x) {
    x.expectStaticType<Exactly<int>>();
  })));
}

testParenthesizedTwiceNamed(
    void Function<T>({required T a, required void Function(T) b}) f) {
  f(
      a: 0,
      b: (((x) {
        x.expectStaticType<Exactly<int>>();
      })));
}

main() {}
