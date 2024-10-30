// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateMixin extends ResolvedCorrectionProducer {
  String _mixinName = '';

  CreateMixin({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_mixinName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_MIXIN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Element? prefixElement;
    var node = this.node;
    if (node is NamedType) {
      var importPrefix = node.importPrefix;
      if (importPrefix != null) {
        prefixElement = importPrefix.element;
        if (prefixElement == null) {
          return;
        }
      }
      _mixinName = node.name2.lexeme;
    } else if (node is SimpleIdentifier) {
      var parent = node.parent;
      switch (parent) {
        case PrefixedIdentifier():
          if (parent.identifier == node) {
            return;
          }
        case PropertyAccess():
          if (parent.propertyName == node) {
            return;
          }
      }
      _mixinName = node.name;
    } else if (node is PrefixedIdentifier) {
      if (node.parent is InstanceCreationExpression) {
        return;
      }
      prefixElement = node.prefix.staticElement;
      if (prefixElement == null) {
        return;
      }
      _mixinName = node.identifier.name;
    } else {
      return;
    }
    // prepare environment
    Element targetUnit;
    var prefix = '';
    var suffix = '';
    var offset = -1;
    String? filePath;
    if (prefixElement == null) {
      targetUnit = unit.declaredElement!;
      var enclosingMember = node.thisOrAncestorMatching((node) =>
          node is CompilationUnitMember && node.parent is CompilationUnit);
      if (enclosingMember == null) {
        return;
      }
      offset = enclosingMember.end;
      filePath = file;
      prefix = '$eol$eol';
    } else {
      for (var import in libraryElement.libraryImports) {
        if (prefixElement is PrefixElement &&
            import.prefix?.element == prefixElement) {
          var library = import.importedLibrary;
          if (library != null) {
            targetUnit = library.definingCompilationUnit;
            var targetSource = targetUnit.source;
            try {
              if (targetSource != null) {
                offset = targetSource.contents.data.length;
                filePath = targetSource.fullName;
              }
              prefix = eol;
              suffix = eol;
            } on FileSystemException {
              // If we can't read the file to get the offset, then we can't
              // create a fix.
            }
            break;
          }
        }
      }
    }
    if (filePath == null || offset < 0) {
      return;
    }
    await builder.addDartFileEdit(filePath, (builder) {
      builder.addInsertion(offset, (builder) {
        builder.write(prefix);
        builder.writeMixinDeclaration(_mixinName, nameGroupName: 'NAME');
        builder.write(suffix);
      });
      if (prefixElement == null) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
  }
}
