// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../source_map.dart';
import '../serialize/serialize.dart';
import 'ir.dart';

part 'instruction.dart';

class Instructions implements Serializable {
  /// The locals used by this group of instructions.
  final List<Local> locals;

  /// A sequence of Wasm instructions.
  final List<Instruction> instructions;

  final Map<Instruction, StackTrace>? _stackTraces;

  final List<String> _traceLines;

  /// A string trace.
  late final trace = _traceLines.join();

  /// Mappings for the instructions in [_instructions] to their source code.
  ///
  /// Since we add mappings as we generate instructions, this will be sorted
  /// based on [SourceMapping.instructionOffset].
  final List<SourceMapping> _sourceMappings;

  /// Create a new instruction sequence.
  Instructions(this.locals, this.instructions, this._stackTraces,
      this._traceLines, this._sourceMappings);

  @override
  void serialize(Serializer s) {
    int sourceMappingIdx = 0;
    int instructionIdx = 0;
    for (final i in instructions) {
      if (_stackTraces != null) s.debugTrace(_stackTraces![i]!);

      while (sourceMappingIdx < _sourceMappings.length &&
          _sourceMappings[sourceMappingIdx].instructionOffset <
              instructionIdx) {
        sourceMappingIdx += 1;
      }

      if (sourceMappingIdx < _sourceMappings.length) {
        final mapping = _sourceMappings[sourceMappingIdx];
        if (mapping.instructionOffset == instructionIdx) {
          s.sourceMapSerializer.addMapping(s.offset, mapping.sourceInfo);
        }
      }

      i.serialize(s);

      instructionIdx += 1;
    }
  }
}
