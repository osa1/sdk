// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/executable_parameters.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingParameter extends MultiCorrectionProducer {
  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    // `node` is the unmatched argument.
    var argumentList = node.parent;
    if (argumentList is! ArgumentList) {
      return const [];
    }

    var invocation = argumentList.parent;
    if (invocation == null) {
      return const [];
    }

    var context = ExecutableParameters.forInvocation(sessionHelper, invocation);
    if (context == null) {
      return const [];
    }

    var includeOptional =
        context.optionalPositional.isEmpty && context.named.isEmpty;
    return <ResolvedCorrectionProducer>[
      _AddMissingRequiredPositionalParameter(context),
      if (includeOptional) _AddMissingOptionalPositionalParameter(context),
    ];
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [AddMissingParameter] producer.
class _AddMissingOptionalPositionalParameter extends _AddMissingParameter {
  _AddMissingOptionalPositionalParameter(super.context);

  @override
  FixKind get fixKind => DartFixKind.ADD_MISSING_PARAMETER_POSITIONAL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var prefix = context.required.isNotEmpty ? ', [' : '[';
    if (context.required.isNotEmpty) {
      var prevNode = await context.getParameterNode(context.required.last);
      await _addParameter(builder, prevNode?.end, prefix, ']');
    } else {
      var parameterList = await context.getParameterList();
      var offset = parameterList?.leftParenthesis.end;
      await _addParameter(builder, offset, prefix, ']');
    }
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [AddMissingParameter] producer.
abstract class _AddMissingParameter extends ResolvedCorrectionProducer {
  ExecutableParameters context;

  _AddMissingParameter(this.context);

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  Future<void> _addParameter(
      ChangeBuilder builder, int? offset, String prefix, String suffix) async {
    // node is the unmatched argument.
    var argumentList = node.parent;
    if (argumentList is! ArgumentList) {
      return;
    }
    List<Expression> arguments = argumentList.arguments;
    var numRequired = context.required.length;
    if (numRequired >= arguments.length) {
      return;
    }
    var argument = arguments[numRequired];
    if (offset != null) {
      await builder.addDartFileEdit(context.file, (builder) {
        builder.addInsertion(offset, (builder) {
          builder.write(prefix);
          builder.writeParameterMatchingArgument(
              argument, numRequired, <String>{});
          builder.write(suffix);
        });
      });
    }
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [AddMissingParameter] producer.
class _AddMissingRequiredPositionalParameter extends _AddMissingParameter {
  _AddMissingRequiredPositionalParameter(super.context);

  @override
  FixKind get fixKind => DartFixKind.ADD_MISSING_PARAMETER_REQUIRED;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (context.required.isNotEmpty) {
      var prevNode = await context.getParameterNode(context.required.last);
      await _addParameter(builder, prevNode?.end, ', ', '');
    } else {
      var parameterList = await context.getParameterList();
      var offset = parameterList?.leftParenthesis.end;
      var suffix = context.executable.parameters.isNotEmpty ? ', ' : '';
      await _addParameter(builder, offset, '', suffix);
    }
  }
}
