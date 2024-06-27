/// Represents a mapping from a range of generated instructions in an
/// [InstructionsBuilder] to some source code.
class SourceMapping {
  /// Index of the first instruction generated for the compiled code (e.g. an
  /// expression or statement) in the instruction's [InstructionsBuilder].
  final int instructionStartIndex;

  /// URI of the compiled code's file.
  final Uri fileUri;

  /// 0-based line number of the compiled code.
  final int line;

  /// 0-based column number of the compiled code.
  final int col;

  /// Name of the mapping thing. This is usually the name of the function that
  /// contains the code.
  final String? name;

  SourceMapping(
      this.instructionStartIndex, this.fileUri, this.line, this.col, this.name);

  @override
  String toString() => '$instructionStartIndex -> $fileUri:$line:$col';
}
