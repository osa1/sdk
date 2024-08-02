// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import 'dill_member_builder.dart';

abstract class DillExtensionTypeMemberBuilder extends DillMemberBuilder {
  final ExtensionTypeMemberDescriptor _descriptor;

  DillExtensionTypeMemberBuilder(
      Member member, this._descriptor, Builder parent)
      : super(member, parent);

  @override
  bool get isStatic => _descriptor.isStatic;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExternal => member.isExternal;

  @override
  String get name => _descriptor.name.text;

  @override
  ProcedureKind? get kind {
    switch (_descriptor.kind) {
      case ExtensionTypeMemberKind.Method:
        return ProcedureKind.Method;
      case ExtensionTypeMemberKind.Getter:
        return ProcedureKind.Getter;
      case ExtensionTypeMemberKind.Operator:
        return ProcedureKind.Operator;
      case ExtensionTypeMemberKind.Setter:
        return ProcedureKind.Setter;
      case ExtensionTypeMemberKind.Field:
      // Coverage-ignore(suite): Not run.
      case ExtensionTypeMemberKind.Constructor:
      // Coverage-ignore(suite): Not run.
      case ExtensionTypeMemberKind.Factory:
      // Coverage-ignore(suite): Not run.
      case ExtensionTypeMemberKind.RedirectingFactory:
    }
    return null;
  }

  @override
  bool get isConstructor {
    switch (_descriptor.kind) {
      case ExtensionTypeMemberKind.Method:
      case ExtensionTypeMemberKind.Getter:
      case ExtensionTypeMemberKind.Operator:
      case ExtensionTypeMemberKind.Setter:
      case ExtensionTypeMemberKind.Field:
      case ExtensionTypeMemberKind.Factory:
      case ExtensionTypeMemberKind.RedirectingFactory:
        return false;
      case ExtensionTypeMemberKind.Constructor:
        return true;
    }
  }

  @override
  bool get isFactory {
    switch (_descriptor.kind) {
      case ExtensionTypeMemberKind.Method:
      case ExtensionTypeMemberKind.Getter:
      case ExtensionTypeMemberKind.Operator:
      case ExtensionTypeMemberKind.Setter:
      case ExtensionTypeMemberKind.Field:
      // Coverage-ignore(suite): Not run.
      case ExtensionTypeMemberKind.Constructor:
        return false;
      // Coverage-ignore(suite): Not run.
      case ExtensionTypeMemberKind.Factory:
      case ExtensionTypeMemberKind.RedirectingFactory:
        return true;
    }
  }

  @override
  Name get memberName => new Name(name, member.enclosingLibrary);
}

class DillExtensionTypeFieldBuilder extends DillExtensionTypeMemberBuilder {
  final Field field;

  DillExtensionTypeFieldBuilder(
      this.field, ExtensionTypeMemberDescriptor descriptor, Builder parent)
      : super(field, descriptor, parent);

  @override
  Member get member => field;

  @override
  Member get readTarget => field;

  @override
  Member? get writeTarget => isAssignable ? field : null;

  @override
  // Coverage-ignore(suite): Not run.
  Member get invokeTarget => field;

  @override
  bool get isField => true;

  @override
  bool get isAssignable => field.hasSetter;
}

class DillExtensionTypeSetterBuilder extends DillExtensionTypeMemberBuilder {
  final Procedure procedure;

  DillExtensionTypeSetterBuilder(
      this.procedure, ExtensionTypeMemberDescriptor descriptor, Builder parent)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Setter),
        super(procedure, descriptor, parent);

  @override
  Member get member => procedure;

  @override
  Member? get readTarget => null;

  @override
  Member get writeTarget => procedure;

  @override
  Member? get invokeTarget => null;
}

class DillExtensionTypeGetterBuilder extends DillExtensionTypeMemberBuilder {
  final Procedure procedure;

  DillExtensionTypeGetterBuilder(
      this.procedure, ExtensionTypeMemberDescriptor descriptor, Builder parent)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Getter),
        super(procedure, descriptor, parent);

  @override
  Member get member => procedure;

  @override
  Member get readTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillExtensionTypeOperatorBuilder extends DillExtensionTypeMemberBuilder {
  final Procedure procedure;

  DillExtensionTypeOperatorBuilder(
      this.procedure, ExtensionTypeMemberDescriptor descriptor, Builder parent)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Operator),
        super(procedure, descriptor, parent);

  @override
  Member get member => procedure;

  @override
  Member? get readTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillExtensionTypeStaticMethodBuilder
    extends DillExtensionTypeMemberBuilder {
  final Procedure procedure;

  DillExtensionTypeStaticMethodBuilder(
      this.procedure, ExtensionTypeMemberDescriptor descriptor, Builder parent)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Method),
        assert(descriptor.isStatic),
        super(procedure, descriptor, parent);

  @override
  Member get member => procedure;

  @override
  Member get readTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member get invokeTarget => procedure;
}

class DillExtensionTypeInstanceMethodBuilder
    extends DillExtensionTypeMemberBuilder {
  final Procedure procedure;

  final Procedure _extensionTearOff;

  DillExtensionTypeInstanceMethodBuilder(
      this.procedure,
      ExtensionTypeMemberDescriptor descriptor,
      Builder parent,
      this._extensionTearOff)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Method),
        assert(!descriptor.isStatic),
        super(procedure, descriptor, parent);

  @override
  Member get member => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Member> get exportedMembers => [procedure, _extensionTearOff];

  @override
  Member get readTarget => _extensionTearOff;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillExtensionTypeConstructorBuilder extends DillExtensionTypeMemberBuilder
    implements ConstructorBuilder {
  final Procedure constructor;
  final Procedure? _constructorTearOff;

  DillExtensionTypeConstructorBuilder(
      this.constructor,
      this._constructorTearOff,
      ExtensionTypeMemberDescriptor descriptor,
      Builder parent)
      : super(constructor, descriptor, parent);

  @override
  FunctionNode get function => constructor.function;

  @override
  Procedure get member => constructor;

  @override
  Member get readTarget =>
      _constructorTearOff ?? // Coverage-ignore(suite): Not run.
      constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  Procedure get invokeTarget => constructor;
}

class DillExtensionTypeFactoryBuilder extends DillExtensionTypeMemberBuilder {
  final Procedure _procedure;
  final Procedure? _factoryTearOff;

  DillExtensionTypeFactoryBuilder(this._procedure, this._factoryTearOff,
      ExtensionTypeMemberDescriptor descriptor, Builder parent)
      : super(_procedure, descriptor, parent);

  @override
  Member get member => _procedure;

  @override
  Member? get readTarget =>
      _factoryTearOff ?? // Coverage-ignore(suite): Not run.
      _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => _procedure;
}
