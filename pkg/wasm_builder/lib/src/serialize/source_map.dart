class SourceMapSerializer {
  final List<Mapping> mappings = [];

  void addMapping(int wasmModuleOffset, Uri sourceFileUri, int sourceFileLine,
      int sourceFileColumn, String? name) {
    final mapping = Mapping(wasmModuleOffset, sourceFileUri, sourceFileLine,
        sourceFileColumn, name);
    mappings.add(mapping);
  }

  void copyMappings(SourceMapSerializer other, int offset) {
    for (final mapping in other.mappings) {
      mappings.add(Mapping(
        mapping.wasmModuleOffset + offset,
        mapping.sourceFileUri,
        mapping.sourceFileLine,
        mapping.sourceFileColumn,
        mapping.name,
      ));
    }
  }

  String serialize() => _serializeSourceMap(mappings);
}

class Mapping {
  final int wasmModuleOffset;

  final Uri sourceFileUri;

  /// Zero-based line number of the source.
  final int sourceFileLine;

  /// Zero-based column number of the source.
  final int sourceFileColumn;

  final String? name;

  Mapping(this.wasmModuleOffset, this.sourceFileUri, this.sourceFileLine,
      this.sourceFileColumn, this.name);

  @override
  String toString() =>
      '$wasmModuleOffset -> $sourceFileUri:$sourceFileLine:$sourceFileColumn';
}

String _serializeSourceMap(List<Mapping> mappings) {
  final List<Uri> sources =
      mappings.map((mapping) => mapping.sourceFileUri).toSet().toList();

  // Maps sources to their indices in the 'sources' list.
  final Map<Uri, int> sourceIndices = {};
  for (Uri source in sources) {
    sourceIndices[source] = sourceIndices.length;
  }

  final List<String> names = mappings
      .where((mapping) => mapping.name != null)
      .map((mapping) => mapping.name!)
      .toSet()
      .toList();

  // Maps names to their index in the 'names' list.
  final Map<String, int> nameIndices = {};
  for (String name in names) {
    nameIndices[name] = nameIndices.length;
  }

  // Generate the 'mappings' field.
  final StringBuffer mappingsStr = StringBuffer();

  int lastTargetColumn = 0;
  int lastSourceIndex = 0;
  int lastSourceLine = 0;
  int lastSourceColumn = 0;
  int lastNameIndex = 0;

  for (int i = 0; i < mappings.length; ++i) {
    final mapping = mappings[i];
    final isLast = i == (mappings.length - 1);
    final sourceIndex = sourceIndices[mapping.sourceFileUri]!;

    lastTargetColumn =
        _encodeVLQ(mappingsStr, mapping.wasmModuleOffset, lastTargetColumn);
    lastSourceIndex = _encodeVLQ(mappingsStr, sourceIndex, lastSourceIndex);
    lastSourceLine =
        _encodeVLQ(mappingsStr, mapping.sourceFileLine, lastSourceLine);
    lastSourceColumn =
        _encodeVLQ(mappingsStr, mapping.sourceFileColumn, lastSourceColumn);

    if (mapping.name != null) {
      final nameIndex = nameIndices[mapping.name!]!;
      lastNameIndex = _encodeVLQ(mappingsStr, nameIndex, lastNameIndex);
    }

    if (!isLast) {
      mappingsStr.write(',');
    }
  }

  return """{
      "version": 3,
      "file": "main.dart.wasm",
      "sources": [${sources.map((source) => '"$source"').join(",")}],
      "names": [${names.map((name) => '"$name"').join(",")}],
      "mappings": "$mappingsStr"
  }""";
}

/// Writes the VLQ of delta between [value] and [offset] into [output] and
/// return [value].
int _encodeVLQ(StringSink output, int value, int offset) {
  int delta = value - offset;
  int signBit = 0;
  if (delta < 0) {
    signBit = 1;
    delta = -delta;
  }
  delta = (delta << 1) | signBit;
  do {
    int digit = delta & _VLQ_BASE_MASK;
    delta >>= _VLQ_BASE_SHIFT;
    if (delta > 0) {
      digit |= _VLQ_CONTINUATION_BIT;
    }
    output.write(_BASE64_DIGITS[digit]);
  } while (delta > 0);
  return value;
}

const int _VLQ_BASE_SHIFT = 5;
const int _VLQ_BASE_MASK = (1 << 5) - 1;
const int _VLQ_CONTINUATION_BIT = 1 << 5;
const String _BASE64_DIGITS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmn'
    'opqrstuvwxyz0123456789+/';
