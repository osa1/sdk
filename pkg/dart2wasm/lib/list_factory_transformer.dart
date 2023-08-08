// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

class ListFactorySpecializer {
  final Map<Member, TreeNode Function(StaticInvocation node)> _transformers =
      {};
  final CoreTypes _coreTypes;

  final Procedure _fixedLengthListFactory;
  final Procedure _fixedLengthListFilledFactory;
  // final Procedure _fixedLengthUnboxedIntListFactory;
  final Procedure _fixedLengthUnboxedIntListFilledFactory;
  final Procedure _growableListFactory;
  final Procedure _growableListFilledFactory;
  final Procedure _growableUnboxedIntListFilledFactory;

  ListFactorySpecializer(this._coreTypes)
      : _fixedLengthListFactory =
            _coreTypes.index.getProcedure('dart:_list', 'FixedLengthList', ''),
        _fixedLengthListFilledFactory = _coreTypes.index
            .getProcedure('dart:_list', 'FixedLengthList', 'filled'),
        // _fixedLengthUnboxedIntListFactory = _coreTypes.index
        //     .getProcedure('dart._unboxed_int_list', 'FixedLengthUnboxedIntList', ''),
        _fixedLengthUnboxedIntListFilledFactory = _coreTypes.index.getProcedure(
            'dart:_unboxed_int_list', 'FixedLengthUnboxedIntList', 'filled'),
        _growableListFactory =
            _coreTypes.index.getProcedure('dart:_list', 'GrowableList', ''),
        _growableListFilledFactory = _coreTypes.index
            .getProcedure('dart:_list', 'GrowableList', 'filled'),
        _growableUnboxedIntListFilledFactory = _coreTypes.index.getProcedure(
            'dart:_unboxed_int_list', 'GrowableUnboxedIntList', 'filled') {
    print("Initializing list factory transformer");

    _transformers[
            _coreTypes.index.getProcedure('dart:core', 'List', 'filled')] =
        _transformListFilledFactory;
  }

  TreeNode transformStaticInvocation(StaticInvocation invocation) {
    final target = invocation.target;
    final transformer = _transformers[target];
    if (transformer != null) {
      return transformer(invocation);
    }
    return invocation;
  }

  TreeNode _transformListFilledFactory(StaticInvocation node) {
    final args = node.arguments;
    assert(args.positional.length == 2);
    final type = args.types[0];
    final length = args.positional[0];
    final fill = args.positional[1];
    final fillingWithNull = _isNullConstant(fill);

    // Null when the argument is not a constant or a `bool` literal, e.g.
    // `List.filled(..., growable: f())`.
    final bool? growable =
        _getConstantOptionalArgument(args, 'growable', false);

    print(
        "Checking to transform list factory, type = $type, length = $length, fill = $fill, location = ${node.location}");

    final intList = type == _coreTypes.intNonNullableRawType;
    final unboxedIntList = intList && !fillingWithNull;

    if (growable == null) {
      // TODO: Add factories with growable argument
      return node;
    }

    if (growable) {
      if (unboxedIntList) {
        print(
            "Transforming list factory to int list factory (${node.location})");
        return StaticInvocation(
            _growableUnboxedIntListFilledFactory, Arguments([length, fill]))
          ..fileOffset = node.fileOffset;
      } else if (fillingWithNull) {
        return StaticInvocation(
            _growableListFactory, Arguments([length], types: args.types))
          ..fileOffset = node.fileOffset;
      } else {
        return StaticInvocation(_growableListFilledFactory,
            Arguments([length, fill], types: args.types))
          ..fileOffset = node.fileOffset;
      }
    } else {
      if (unboxedIntList) {
        print(
            "Transforming list factory to int list factory (${node.location})");
        return StaticInvocation(
            _fixedLengthUnboxedIntListFilledFactory, Arguments([length, fill]))
          ..fileOffset = node.fileOffset;
      } else if (fillingWithNull) {
        return StaticInvocation(
            _fixedLengthListFactory, Arguments([length], types: args.types))
          ..fileOffset = node.fileOffset;
      } else {
        return StaticInvocation(_fixedLengthListFilledFactory,
            Arguments([length, fill], types: args.types))
          ..fileOffset = node.fileOffset;
      }
    }
  }
}

/// Returns constant value of the only optional argument in [args], or null
/// if it is not a constant. Returns [defaultValue] if optional argument is
/// not passed. Argument is asserted to have the given [name].
bool? _getConstantOptionalArgument(
    Arguments args, String name, bool defaultValue) {
  if (args.named.isEmpty) {
    return defaultValue;
  }
  final namedArg = args.named.single;
  assert(namedArg.name == name);
  final value = _unwrapFinalVariableGet(namedArg.value);
  if (value is BoolLiteral) {
    return value.value;
  } else if (value is ConstantExpression) {
    final constant = value.constant;
    if (constant is BoolConstant) {
      return constant.value;
    }
  }
  return null;
}

bool _isNullConstant(Expression value) {
  value = _unwrapFinalVariableGet(value);
  return value is NullLiteral ||
      (value is ConstantExpression && value.constant is NullConstant);
}

// Front-end can create extra temporary variables ("Let v = e, call(v)") to
// hoist expressions when rearraning named parameters. Unwrap such variables
// and return their initializers.
Expression _unwrapFinalVariableGet(Expression expr) {
  if (expr is VariableGet) {
    final variable = expr.variable;
    if (variable.isFinal) {
      final initializer = variable.initializer;
      if (initializer != null) {
        return initializer;
      }
    }
  }
  return expr;
}
