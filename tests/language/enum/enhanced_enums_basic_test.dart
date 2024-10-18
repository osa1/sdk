// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test new enhanced enum syntax.

import 'package:expect/expect.dart';

void main() {
  Expect.equals(3, EnumPlain.values.length);
  Expect.identical(EnumPlain.v1, EnumPlain.values[0]);
  Expect.identical(EnumPlain.v2, EnumPlain.values[1]);
  Expect.identical(EnumPlain.v3, EnumPlain.values[2]);

  Expect.equals(3, EnumPlainTrailingComma.values.length);
  Expect.identical(EnumPlainTrailingComma.v1, EnumPlainTrailingComma.values[0]);
  Expect.identical(EnumPlainTrailingComma.v2, EnumPlainTrailingComma.values[1]);
  Expect.identical(EnumPlainTrailingComma.v3, EnumPlainTrailingComma.values[2]);

  Expect.equals(3, EnumNoSemicolon.values.length);
  Expect.identical(EnumNoSemicolon.v1, EnumNoSemicolon.values[0]);
  Expect.identical(EnumNoSemicolon.v2, EnumNoSemicolon.values[1]);
  Expect.identical(EnumNoSemicolon.v3, EnumNoSemicolon.values[2]);
  Expect.type<EnumNoSemicolon<num>>(EnumNoSemicolon.v1);

  Expect.equals(3, EnumPlainSemicolon.values.length);
  Expect.identical(EnumPlainSemicolon.v1, EnumPlainSemicolon.values[0]);
  Expect.identical(EnumPlainSemicolon.v2, EnumPlainSemicolon.values[1]);
  Expect.identical(EnumPlainSemicolon.v3, EnumPlainSemicolon.values[2]);

  Expect.equals(3, EnumPlainTrailingCommaSemicolon.values.length);
  Expect.identical(EnumPlainTrailingCommaSemicolon.v1,
      EnumPlainTrailingCommaSemicolon.values[0]);
  Expect.identical(EnumPlainTrailingCommaSemicolon.v2,
      EnumPlainTrailingCommaSemicolon.values[1]);
  Expect.identical(EnumPlainTrailingCommaSemicolon.v3,
      EnumPlainTrailingCommaSemicolon.values[2]);

  Expect.equals(6, EnumAll.values.length);
  Expect.identical(EnumAll.v1, EnumAll.values[0]);
  Expect.identical(EnumAll.v2, EnumAll.values[1]);
  Expect.identical(EnumAll.v3, EnumAll.values[2]);
  Expect.identical(EnumAll.v4, EnumAll.values[3]);
  Expect.identical(EnumAll.v5, EnumAll.values[4]);
  Expect.identical(EnumAll.v6, EnumAll.values[5]);

  Expect.equals("unnamed", EnumAll.v1.constructor);
  Expect.equals("unnamed", EnumAll.v2.constructor);
  Expect.equals("unnamed", EnumAll.v3.constructor);
  Expect.equals("named", EnumAll.v4.constructor);
  Expect.equals("renamed", EnumAll.v5.constructor);
  Expect.equals("unnamed", EnumAll.v6.constructor);

  Expect.type<EnumAll<num, num>>(EnumAll.v1);
  Expect.type<EnumAll<num, int>>(EnumAll.v2);
  Expect.type<EnumAll<int, int>>(EnumAll.v3);
  Expect.type<EnumAll<int, int>>(EnumAll.v4);
  Expect.type<EnumAll<int, int>>(EnumAll.v5);
  Expect.type<EnumAll<num, num>>(EnumAll.v6);

  // Access static members.
  Expect.identical(EnumAll.v3, EnumAll.sConst);
  Expect.identical(EnumAll.v3, EnumAll.sFinal);

  Expect.throws(() => EnumAll.sLateFinal);
  EnumAll.sLateFinal = EnumAll.v1;
  Expect.identical(EnumAll.v1, EnumAll.sLateFinal);
  Expect.throws(() => EnumAll.sLateFinal = EnumAll.v1);

  Expect.identical(EnumAll.v3, EnumAll.sFinal);

  Expect.throws(() => EnumAll.sLateVar);
  EnumAll.sLateVar = EnumAll.v1;
  Expect.identical(EnumAll.v1, EnumAll.sLateVar);
  EnumAll.sLateVar = EnumAll.v3;
  Expect.identical(EnumAll.v3, EnumAll.sLateVar);
  Expect.identical(EnumAll.v3, EnumAll.sLateVarInit);
  Expect.isNull(EnumAll.sVar);
  Expect.identical(EnumAll.v3, EnumAll.sVarInit);

  Expect.identical(EnumAll.v3, EnumAll.staticGetSet);
  EnumAll.staticGetSet = EnumAll.v5;
  Expect.equals(42, EnumAll.staticMethod());

  Expect.identical(EnumAll.v3, EnumAll<num, num>.factory(2));
  Expect.identical(EnumAll.v3, EnumAll<num, num>.refactory(2));

  // Access static members through typedef.
  Expect.identical(EnumAll.v3, TypeDefAll.sConst);
  Expect.identical(EnumAll.v3, TypeDefAll.sFinal);
  Expect.identical(EnumAll.v1, TypeDefAll.sLateFinal);
  Expect.identical(EnumAll.v3, TypeDefAll.sLateFinalInit);

  Expect.identical(EnumAll.v3, TypeDefAll.staticGetSet);
  TypeDefAll.staticGetSet = EnumAll.v5;
  Expect.equals(42, TypeDefAll.staticMethod());

  Expect.identical(EnumAll.v3, TypeDefAll.factory(2));
  Expect.identical(EnumAll.v3, TypeDefAll.refactory(2));

  // Access instance members.
  Expect.equals(0, EnumAll.v1.instanceGetSet);
  EnumAll.v1.instanceGetSet = 0.5;
  Expect.equals(0, EnumAll.v1.instanceMethod());
  Expect.identical(EnumAll.v4, EnumAll.v3 ^ EnumAll.v2);

  Expect.equals(
      "EnumAll.v1:EnumMixin<num>:ObjectMixin:this", EnumAll.v1.thisAndSuper());

  // Which can reference type parameters.
  Expect.isTrue(EnumAll.v2.test(2)); // does `is T` with `T` being `int`.
  Expect.isFalse(EnumAll.v2.test(2.5));

  // Including `call`.
  Expect.equals(42, EnumAll.v1<int>(42));
  Expect.equals(42, EnumAll.v1(42));
  // Also as tear-off.
  Function eaf1 = EnumAll.v1;
  Expect.type<T Function<T>(T)>(eaf1);
  Function eaf2 = EnumAll.v1<String>;
  Expect.type<String Function(String)>(eaf2);

  // Instance members shadow extensions.
  Expect.equals("not extension", EnumAll.v1.notExtension);
  // But you can call extension members if there is no conflict.
  Expect.equals("extension", EnumAll.v1.extension);

  // The `index` implementation is inherited from the `Enum` implementing
  // superclass, and the `toString` implementation is overridden, but
  // available via `realToString`.
  Expect.equals(0, OverrideEnum.v1.index);
  Expect.equals(1, OverrideEnum.v2.index);
  Expect.equals(0, OverrideEnum.v1.superIndex);
  Expect.equals(1, OverrideEnum.v2.superIndex);
  Expect.equals("FakeString", OverrideEnum.v1.toString());
  Expect.equals("FakeString", OverrideEnum.v2.toString());
  Expect.equals("OverrideEnum.v1", OverrideEnum.v1.realToString());
  Expect.equals("OverrideEnum.v2", OverrideEnum.v2.realToString());

  // Enum elements are always distinct, even if their state doesn't differ.
  Expect.notIdentical(Canonical.v1, Canonical.v2, "Canonical - type only");
  Expect.notIdentical(Canonical.v2, Canonical.v3, "Canonical - no difference");

  Expect.identical(SelfRefEnum.e1, SelfRefEnum.e2.previous, "SelfRef.prev");
}

// Original syntax still works, without semicolon after values.
enum EnumPlain { v1, v2, v3 }

// Also with trailing comma.
enum EnumPlainTrailingComma {
  v1,
  v2,
  v3,
}

// Also if using type parameters, mixins or interfaces.
// It only matters whether there is something after the values.
enum EnumNoSemicolon<T extends num> with ObjectMixin implements Interface {
  v1,
  v2,
  v3
}

// Allows semicolon after values, even when not needed.
// Without trailing comma.
enum EnumPlainSemicolon {
  v1,
  v2,
  v3;
}

// With trailing comma.
enum EnumPlainTrailingCommaSemicolon {
  v1,
  v2,
  v3,
  ;
}

// Full syntax, with every possible option.
@EnumAll.v1
@EnumAll.sConst
enum EnumAll<S extends num, T extends num>
    with GenericEnumMixin<T>, ObjectMixin
    implements Interface, GenericInterface<S> {
  @v1
  @v2
  v1,
  @EnumAll.v2
  v2(y: 2),
  @sConst
  v3<int, int>(y: 2),
  v4.named(1, y: 2),
  v5<int, int>.renamed(1, y: 2),
  v6.new(),
  ;

  /// Static members.
  ///
  /// Any kind of static variable.
  static const sConst = v3;
  static final sFinal = v3;
  static late final EnumAll sLateFinal;
  static late final sLateFinalInit = v3;
  static late EnumAll sLateVar;
  static late var sLateVarInit = v3;
  static EnumAll? sVar;
  static EnumAll sVarInit = v3;

  /// Static getters, setters and methods
  static EnumAll<int, int> get staticGetSet => v3;
  static set staticGetSet(EnumAll<int, int> _) {}
  static int staticMethod() => 42;

  // Constructors.
  // Generative, non-redirecting, unnamed.
  const EnumAll({T? y})
      : constructor = "unnamed",
        this.x = 0 as S,
        y = y ?? (0 as T);
  // Generative, non-redirecting, named.
  const EnumAll.named(this.x, {T? y, String? constructor})
      : constructor = constructor ?? "named",
        y = y ?? (0 as T);
  // Generative, redirecting.
  const EnumAll.renamed(S x, {T? y})
      : this.named(x, y: y, constructor: "renamed");
  // Factory, non-redirecting.
  factory EnumAll.factory(int index) => values[index] as EnumAll<S, T>;
  // Factory, redirecting (only to other factory constructor).
  factory EnumAll.refactory(int index) = EnumAll<S, T>.factory;

  // Cannot have factory constructors redirecting to generative constructors.
  // (Nothing can refer to generative constructors except redirecting generative
  // constructors and the implicit element creation expressions.)
  // Cannot have const factory constructor, because they *must* redirect to
  // generative constructors.
  // Cannot have `super`-constructor invocations in initializer lists.

  // Instance members.

  // Instance variables must be final and non-late because of const constructor.
  final String constructor;
  final S x;
  final num y;

  // Getters, setters, methods and operators.
  S get instanceGetSet => x;
  set instanceGetSet(S _) {}
  S instanceMethod() => x;
  EnumAll<num, num> operator ^(EnumAll<num, num> other) {
    var newIndex = index ^ other.index;
    if (newIndex > 4) newIndex = 4;
    return values[newIndex]; // Can refer to `values`.
  }

  // Can access `this` and `super` in an instance method.
  String thisAndSuper() => "${super.toString()}:${this.toString()}";

  // Can be callable.
  T call<T>(T value) => value;

  // Can have an `index` setter.
  set index(int value) {}

  // Instance members shadow extensions.
  String get notExtension => "not extension";

  String toString() => "this";
}

extension EnumAllExtension on EnumAll {
  String get notExtension {
    Expect.fail("Unreachable");
    return "not";
  }

  String get extension => "extension";
}

typedef TypeDefAll = EnumAll<num, num>;

// Can have no unnamed constructor.
enum EnumNoUnnamedConstructor {
  v1.named(1),
  v2.named(2);

  final int x;
  const EnumNoUnnamedConstructor.named(this.x);
}

enum NewNamedConstructor {
  v1;

  const NewNamedConstructor.new();
}

// Can have an unnamed factory constructor.
enum EnumFactoryUnnamedConstructor {
  v1.named(1),
  v2.named(2);

  final int x;
  factory EnumFactoryUnnamedConstructor() => v1;
  const EnumFactoryUnnamedConstructor.named(this.x);
}

// Elements which do not differ in public state are still different.
// Ditto if only differing in type arguments.
enum Canonical<T> {
  v1<int>(1),
  v2<num>(1),
  v3<num>(1);

  final T value;
  const Canonical(this.value);
}

// Both `toString` and `index` are inherited from superclass.
enum OverrideEnum {
  v1,
  v2;

  // Cannot override index
  int get superIndex => super.index;
  String toString() => "FakeString";
  String realToString() => super.toString();
}

// An enum value expression *can* reference another enum value.
enum SelfRefEnum {
  e1(null),
  e2(e1);

  final SelfRefEnum? previous;
  const SelfRefEnum(this.previous);
}

// --------------------------------------------------------------------
// Helper declarations

mixin ObjectMixin on Object {
  String toString() => "${super.toString()}:ObjectMixin";
}

mixin EnumMixin on Enum {
  String toString() => "${super.toString()}:EnumMixin";
}

mixin GenericObjectMixin<T> on Object {
  bool test(Object o) => o is T;
  String toString() => "${super.toString()}:ObjectMixin<$T>";
}

mixin GenericEnumMixin<T> on Enum {
  bool test(Object o) => o is T;
  String toString() => "${super.toString()}:EnumMixin<$T>";
}

abstract class Interface {}

abstract class GenericInterface<T> {
  // Implemented by mixins.
  bool test(Object o);
}
