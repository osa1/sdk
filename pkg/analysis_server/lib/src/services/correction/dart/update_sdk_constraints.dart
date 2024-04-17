// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class UpdateSdkConstraints extends ResolvedCorrectionProducer {
  /// The minimum version to which the SDK constraints should be updated.
  final String _minimumVersion;

  /// Initialize a newly created instance that will update the SDK constraints
  /// to '2.14.0'.
  UpdateSdkConstraints.version_2_14_0() : _minimumVersion = '2.14.0';

  /// Initialize a newly created instance that will update the SDK constraints
  /// to '2.1.0'.
  UpdateSdkConstraints.version_2_1_0() : _minimumVersion = '2.1.0';

  /// Initialize a newly created instance that will update the SDK constraints
  /// to '2.2.0'.
  UpdateSdkConstraints.version_2_2_0() : _minimumVersion = '2.2.0';

  /// Initialize a newly created instance that will update the SDK constraints
  /// to '2.2.0'.
  UpdateSdkConstraints.version_2_2_2() : _minimumVersion = '2.2.2';

  /// Initialize a newly created instance that will update the SDK constraints
  /// to '2.2.0'.
  UpdateSdkConstraints.version_2_6_0() : _minimumVersion = '2.6.0';

  @override
  // Too nuanced to do unattended.
  bool get canBeAppliedInBulk => false;

  @override
  // Not applicable (there can only be one constraint per file).
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.UPDATE_SDK_CONSTRAINTS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var pubspecFile = _findPubspecFile();
    if (pubspecFile == null) {
      return;
    }

    var extractor = SdkConstraintExtractor(pubspecFile);
    var text = extractor.constraintText();
    var offset = extractor.constraintOffset();
    if (text == null || offset < 0) {
      return;
    }

    var length = text.length;
    var spaceOffset = text.indexOf(' ');
    if (spaceOffset >= 0) {
      length = spaceOffset;
    }

    String? newText;
    if (text == 'any') {
      newText = '^$_minimumVersion';
    } else if (text.startsWith('^')) {
      newText = '^$_minimumVersion';
    } else if (text.startsWith('>=')) {
      newText = '>=$_minimumVersion';
    } else if (text.startsWith('>')) {
      newText = '>=$_minimumVersion';
    }
    if (newText == null) {
      return;
    }

    var newText_final = newText;
    await builder.addYamlFileEdit(pubspecFile.path, (builder) {
      builder.addSimpleReplacement(SourceRange(offset, length), newText_final);
    });
  }

  File? _findPubspecFile() {
    var file = resourceProvider.getFile(this.file);
    for (var folder in file.parent.withAncestors) {
      var pubspecFile = folder.getChildAssumingFile(file_paths.pubspecYaml);
      if (pubspecFile.exists) {
        return pubspecFile;
      }
    }
    return null;
  }
}
