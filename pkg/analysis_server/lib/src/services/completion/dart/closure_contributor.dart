// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A contributor that produces a closure matching the context type.
class ClosureContributor extends DartCompletionContributor {
  ClosureContributor(super.request, super.builder);

  bool get _isArgument {
    var node = request.target.containingNode;
    return node is ArgumentList || node is NamedExpression;
  }

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    var contextType = request.contextType;
    if (contextType is FunctionType) {
      builder.suggestClosure(
        contextType,
        includeTrailingComma: _isArgument && !request.target.isFollowedByComma,
      );
    }
  }
}
