// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A contributor that produces suggestions for field formal parameters that are
/// based on the fields declared directly by the enclosing class that are not
/// already initialized. More concretely, this class produces suggestions for
/// expressions of the form `this.^` in a constructor's parameter list.
class FieldFormalContributor extends DartCompletionContributor {
  FieldFormalContributor(super.request, super.builder);

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    var node = request.target.containingNode;
    // TODO(brianwilkerson) We should suggest field formal parameters even if
    //  the user hasn't already typed the `this.` prefix, by including the
    //  prefix in the completion.
    if (node is! FieldFormalParameter) {
      return;
    }

    var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }

    // Compute the list of fields already referenced in the constructor.
    // TODO(brianwilkerson) This doesn't include fields in initializers, which
    //  shouldn't be suggested.
    var referencedFields = <String>[];
    for (var param in constructor.parameters.parameters) {
      if (param is DefaultFormalParameter) {
        param = param.parameter;
      }
      if (param is FieldFormalParameter) {
        var fieldId = param.name;
        if (fieldId != request.target.entity) {
          var fieldName = fieldId.lexeme;
          if (fieldName.isNotEmpty) {
            referencedFields.add(fieldName);
          }
        }
      }
    }

    InterfaceElement? enclosingClass;
    var constructorParent = constructor.parent;
    if (constructorParent is ClassDeclaration) {
      enclosingClass = constructorParent.declaredElement;
    } else if (constructorParent is EnumDeclaration) {
      enclosingClass = constructorParent.declaredElement;
    } else {
      return;
    }
    if (enclosingClass == null) {
      return;
    }

    // Add suggestions for fields that are not already referenced.
    for (var field in enclosingClass.fields) {
      if (!field.isSynthetic && !field.isEnumConstant && !field.isStatic) {
        var fieldName = field.name;
        if (fieldName.isNotEmpty) {
          if (!referencedFields.contains(fieldName)) {
            builder.suggestFieldFormalParameter(field);
          }
        }
      }
    }
  }
}
