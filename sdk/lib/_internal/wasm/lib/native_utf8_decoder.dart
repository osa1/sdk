part of 'convert_patch.dart';

// Same as VM's _Utf8Decoder, but monomorphised to only work on U8List.
class _WasmUtf8Decoder {
  /// Decode malformed UTF-8 as replacement characters (instead of throwing)?
  final bool allowMalformed;

  /// Decoder DFA state.
  int _state;

  /// Partially decoded character. Meaning depends on state. Not used when in
  /// the initial/accept state. When in an error state, contains the index into
  /// the input of the error.
  int _charOrIndex = 0;

  int _bomIndex = 0;

  // State machine for UTF-8 decoding, based on this decoder by Björn Höhrmann:
  // https://bjoern.hoehrmann.de/utf-8/decoder/dfa/
  //
  // One iteration in the state machine proceeds as:
  //
  // type = typeTable[byte];
  // char = (state != accept)
  //     ? (byte & 0x3F) | (char << 6)
  //     : byte & (shiftedByteMask >> type);
  // state = transitionTable[state + type];
  //
  // After each iteration, if state == accept, char is output as a character.

  // Mask to and on the type read from the table.
  static const int typeMask = 0x1F;
  // Mask shifted right by byte type to mask first byte of sequence.
  static const int shiftedByteMask = 0xF0FE;

  // Byte types.
  // 'A' = ASCII, 00-7F
  // 'B' = 2-byte, C2-DF
  // 'C' = 3-byte, E1-EC, EE
  // 'D' = 3-byte (possibly surrogate), ED
  // 'E' = Illegal, C0-C1, F5+
  // 'F' = Low extension, 80-8F
  // 'G' = Mid extension, 90-9F
  // 'H' = High extension, A0-BA, BC-BE
  // 'I' = Second byte of BOM, BB
  // 'J' = Third byte of BOM, BF
  // 'K' = 3-byte (possibly overlong), E0
  // 'L' = First byte of BOM, EF
  // 'M' = 4-byte (possibly out-of-range), F4
  // 'N' = 4-byte, F1-F3
  // 'O' = 4-byte (possibly overlong), F0
  static const String typeTable = ""
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 00-1F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 20-3F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 40-5F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 60-7F
      "FFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGG" // 80-9F
      "HHHHHHHHHHHHHHHHHHHHHHHHHHHIHHHJ" // A0-BF
      "EEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB" // C0-DF
      "KCCCCCCCCCCCCDCLONNNMEEEEEEEEEEE" // E0-FF
      ;

  // States (offsets into transition table).
  static const int IA = 0x00; // Initial / Accept
  static const int BB = 0x10; // Before BOM
  static const int AB = 0x20; // After BOM
  static const int X1 = 0x30; // Expecting one extension byte
  static const int X2 = 0x3A; // Expecting two extension bytes
  static const int X3 = 0x44; // Expecting three extension bytes
  static const int TO = 0x4E; // Possibly overlong 3-byte
  static const int TS = 0x58; // Possibly surrogate
  static const int QO = 0x62; // Possibly overlong 4-byte
  static const int QR = 0x6C; // Possibly out-of-range 4-byte
  static const int B1 = 0x76; // One byte into BOM
  static const int B2 = 0x80; // Two bytes into BOM
  static const int E1 = 0x41; // Error: Missing extension byte
  static const int E2 = 0x43; // Error: Unexpected extension byte
  static const int E3 = 0x45; // Error: Invalid byte
  static const int E4 = 0x47; // Error: Overlong encoding
  static const int E5 = 0x49; // Error: Out of range
  static const int E6 = 0x4B; // Error: Surrogate
  static const int E7 = 0x4D; // Error: Unfinished

  // Character equivalents for states.
  static const String _IA = '\u0000';
  static const String _BB = '\u0010';
  static const String _AB = '\u0020';
  static const String _X1 = '\u0030';
  static const String _X2 = '\u003A';
  static const String _X3 = '\u0044';
  static const String _TO = '\u004E';
  static const String _TS = '\u0058';
  static const String _QO = '\u0062';
  static const String _QR = '\u006C';
  static const String _B1 = '\u0076';
  static const String _B2 = '\u0080';
  static const String _E1 = '\u0041';
  static const String _E2 = '\u0043';
  static const String _E3 = '\u0045';
  static const String _E4 = '\u0047';
  static const String _E5 = '\u0049';
  static const String _E6 = '\u004B';
  static const String _E7 = '\u004D';

  // Transition table of the state machine. Maps state and byte type
  // to next state.
  static const String transitionTable = " "
      // A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
      "$_IA$_X1$_X2$_TS$_E3$_E2$_E2$_E2$_E2$_E2$_TO$_X2$_QR$_X3$_QO " // IA
      "$_IA$_X1$_X2$_TS$_E3$_E2$_E2$_E2$_E2$_E2$_TO$_B1$_QR$_X3$_QO " // BB
      "$_IA$_X1$_X2$_TS$_E3$_E2$_E2$_E2$_E2$_E2$_TO$_X2$_QR$_X3$_QO " // AB
      "$_E1$_E1$_E1$_E1$_E1$_IA$_IA$_IA$_IA$_IA" // Overlap 5 E1s        X1
      "$_E1$_E1$_E1$_E1$_E1$_X1$_X1$_X1$_X1$_X1" // Overlap 5 E1s        X2
      "$_E1$_E1$_E1$_E1$_E1$_X2$_X2$_X2$_X2$_X2" // Overlap 5 E1s        X3
      "$_E1$_E1$_E1$_E1$_E1$_E4$_E4$_X1$_X1$_X1" // Overlap 5 E1s        TO
      "$_E1$_E1$_E1$_E1$_E1$_X1$_X1$_E6$_E6$_E6" // Overlap 5 E1s        TS
      "$_E1$_E1$_E1$_E1$_E1$_E4$_X2$_X2$_X2$_X2" // Overlap 5 E1s        QO
      "$_E1$_E1$_E1$_E1$_E1$_X2$_E5$_E5$_E5$_E5" // Overlap 5 E1s        QR
      "$_E1$_E1$_E1$_E1$_E1$_X1$_X1$_X1$_B2$_X1" // Overlap 5 E1s        B1
      "$_E1$_E1$_E1$_E1$_E1$_IA$_IA$_IA$_IA$_AB$_E1$_E1$_E1$_E1$_E1" //  B2
      ;

  // Aliases for states.
  static const int initial = IA;
  static const int accept = IA;
  static const int beforeBom = BB;
  static const int afterBom = AB;
  static const int errorMissingExtension = E1;
  static const int errorUnexpectedExtension = E2;
  static const int errorInvalid = E3;
  static const int errorOverlong = E4;
  static const int errorOutOfRange = E5;
  static const int errorSurrogate = E6;
  static const int errorUnfinished = E7;

  @pragma("vm:prefer-inline")
  static bool isErrorState(int state) => (state & 1) != 0;

  static String errorDescription(int state) {
    switch (state) {
      case errorMissingExtension:
        return "Missing extension byte";
      case errorUnexpectedExtension:
        return "Unexpected extension byte";
      case errorInvalid:
        return "Invalid UTF-8 byte";
      case errorOverlong:
        return "Overlong encoding";
      case errorOutOfRange:
        return "Out of unicode range";
      case errorSurrogate:
        return "Encoded surrogate";
      case errorUnfinished:
        return "Unfinished UTF-8 octet sequence";
      default:
        return "";
    }
  }

  _WasmUtf8Decoder(this.allowMalformed) : _state = initial;

  String convertSingle(U8List codeUnits, int start, int? maybeEnd) {
    int end = RangeError.checkValidRange(start, maybeEnd, codeUnits.length);

    U8List bytes = codeUnits;
    int errorOffset = 0;

    // Skip initial BOM.
    start = skipBomSingle(bytes, start, end);

    // Special case empty input.
    if (start == end) return "";

    // Scan input to determine size and appropriate decoder.
    int size = scan(bytes, start, end);
    int flags = _scanFlags;

    if (flags == 0) {
      // Pure ASCII.
      assert(size == end - start);
      OneByteString result = OneByteString.withLength(size);
      _copyRangeFromU8ListToOneByteString(bytes, result, start, 0, size);
      return result;
    }

    String result;
    if (flags == (flagLatin1 | flagExtension)) {
      // Latin1.
      result = decode8(bytes, start, end, size);
    } else {
      // Arbitrary Unicode.
      result = decode16(bytes, start, end, size);
    }
    if (_state == accept) {
      return result;
    }

    if (!allowMalformed) {
      if (!isErrorState(_state)) {
        // Unfinished sequence.
        _state = errorUnfinished;
        _charOrIndex = end;
      }
      final String message = errorDescription(_state);
      throw FormatException(message, codeUnits, errorOffset + _charOrIndex);
    }

    // Start over on slow path.
    _state = initial;
    result = decodeGeneral(bytes, start, end, true);
    assert(!isErrorState(_state));
    return result;
  }

  external String convertChunked(List<int> codeUnits, int start, int? maybeEnd);

  String convertGeneral(
      U8List codeUnits, int start, int? maybeEnd, bool single) {
    int end = RangeError.checkValidRange(start, maybeEnd, codeUnits.length);

    if (start == end) return "";

    U8List bytes = codeUnits;
    int errorOffset = 0;

    String result = _convertRecursive(bytes, start, end, single);
    if (isErrorState(_state)) {
      String message = errorDescription(_state);
      _state = initial; // Ready for more input.
      throw FormatException(message, codeUnits, errorOffset + _charOrIndex);
    }
    return result;
  }

  String _convertRecursive(U8List bytes, int start, int end, bool single) {
    // Chunk long strings to avoid a pathological case of JS repeated string
    // concatenation.
    if (end - start > 1000) {
      int mid = (start + end) ~/ 2;
      String s1 = _convertRecursive(bytes, start, mid, false);
      if (isErrorState(_state)) return s1;
      String s2 = _convertRecursive(bytes, mid, end, single);
      return s1 + s2;
    }
    return decodeGeneral(bytes, start, end, single);
  }

  /// Flushes this decoder as if closed.
  ///
  /// This method throws if the input was partial and the decoder was
  /// constructed with `allowMalformed` set to `false`.
  void flush(StringSink sink) {
    final int state = _state;
    _state = initial;
    if (state <= afterBom) {
      return;
    }
    // Unfinished sequence.
    if (allowMalformed) {
      sink.writeCharCode(unicodeReplacementCharacterRune);
    } else {
      throw FormatException(errorDescription(errorUnfinished), null, null);
    }
  }

  String decodeGeneral(U8List bytes, int start, int end, bool single) {
    final String typeTable = _Utf8Decoder.typeTable;
    final String transitionTable = _Utf8Decoder.transitionTable;
    int state = _state;
    int char = _charOrIndex;
    final StringBuffer buffer = StringBuffer();
    int i = start;
    int byte = bytes[i++];
    loop:
    while (true) {
      multibyte:
      while (true) {
        int type = typeTable.codeUnitAt(byte) & typeMask;
        char = (state <= afterBom)
            ? byte & (shiftedByteMask >> type)
            : (byte & 0x3F) | (char << 6);
        state = transitionTable.codeUnitAt(state + type);
        if (state == accept) {
          buffer.writeCharCode(char);
          if (i == end) break loop;
          break multibyte;
        } else if (isErrorState(state)) {
          if (allowMalformed) {
            switch (state) {
              case errorInvalid:
              case errorUnexpectedExtension:
                // A single byte that can't start a sequence.
                buffer.writeCharCode(unicodeReplacementCharacterRune);
                break;
              case errorMissingExtension:
                // Unfinished sequence followed by a byte that can start a
                // sequence.
                buffer.writeCharCode(unicodeReplacementCharacterRune);
                // Re-parse offending byte.
                i -= 1;
                break;
              default:
                // Unfinished sequence followed by a byte that can't start a
                // sequence.
                buffer.writeCharCode(unicodeReplacementCharacterRune);
                buffer.writeCharCode(unicodeReplacementCharacterRune);
                break;
            }
            state = initial;
          } else {
            _state = state;
            _charOrIndex = i - 1;
            return "";
          }
        }
        if (i == end) break loop;
        byte = bytes[i++];
      }

      final int markStart = i;
      byte = bytes[i++];
      if (byte < 128) {
        int markEnd = end;
        while (i < end) {
          byte = bytes[i++];
          if (byte >= 128) {
            markEnd = i - 1;
            break;
          }
        }
        assert(markStart < markEnd);
        if (markEnd - markStart < 20) {
          for (int m = markStart; m < markEnd; m++) {
            buffer.writeCharCode(bytes[m]);
          }
        } else {
          buffer.write(String.fromCharCodes(bytes, markStart, markEnd));
        }
        if (markEnd == end) break loop;
      }
    }

    if (single && state > afterBom) {
      // Unfinished sequence.
      if (allowMalformed) {
        buffer.writeCharCode(unicodeReplacementCharacterRune);
      } else {
        _state = errorUnfinished;
        _charOrIndex = end;
        return "";
      }
    }
    _state = state;
    _charOrIndex = char;
    return buffer.toString();
  }

  static U8List _makeUint8List(List<int> codeUnits, int start, int end) {
    final int length = end - start;
    final U8List bytes = U8List(length);
    for (int i = 0; i < length; i++) {
      int b = codeUnits[start + i];
      if ((b & ~0xFF) != 0) {
        // Replace invalid byte values by FF, which is also invalid.
        b = 0xFF;
      }
      bytes[i] = b;
    }
    return bytes;
  }

  int skipBomSingle(U8List bytes, int start, int end) {
    if (end - start >= 3 &&
        bytes[start] == 0xEF &&
        bytes[start + 1] == 0xBB &&
        bytes[start + 2] == 0xBF) {
      return start + 3;
    }
    return start;
  }

  String decode8(U8List bytes, int start, int end, int size) {
    assert(start < end);
    String result = allocateOneByteString(size);
    int i = start;
    int j = 0;
    if (_state == X1) {
      // Half-way though 2-byte sequence
      assert(_charOrIndex == 2 || _charOrIndex == 3);
      final int e = bytes[i++] ^ 0x80;
      if (e >= 0x40) {
        _state = errorMissingExtension;
        _charOrIndex = i - 1;
        return "";
      }
      writeIntoOneByteString(result, j++, (_charOrIndex << 6) | e);
      _state = accept;
    }
    assert(_state == accept);
    while (i < end) {
      int byte = bytes[i++];
      if (byte >= 0x80) {
        if (byte < 0xC0) {
          _state = errorUnexpectedExtension;
          _charOrIndex = i - 1;
          return "";
        }
        assert(byte == 0xC2 || byte == 0xC3);
        if (i == end) {
          _state = X1;
          _charOrIndex = byte & 0x1F;
          break;
        }
        final int e = bytes[i++] ^ 0x80;
        if (e >= 0x40) {
          _state = errorMissingExtension;
          _charOrIndex = i - 1;
          return "";
        }
        byte = (byte << 6) | e;
      }
      writeIntoOneByteString(result, j++, byte);
    }
    // Output size must match, unless we are doing single conversion and are
    // inside an unfinished sequence (which will trigger an error later).
    assert(_bomIndex == 0 && _state != accept
        ? (j == size - 1 || j == size - 2)
        : (j == size));
    return result;
  }

  String decode16(U8List bytes, int start, int end, int size) {
    assert(start < end);
    final String typeTable = _WasmUtf8Decoder.typeTable;
    final String transitionTable = _WasmUtf8Decoder.transitionTable;
    String result = allocateTwoByteString(size);
    int i = start;
    int j = 0;
    int state = _state;
    int char;

    // First byte
    assert(!isErrorState(state));
    final int byte = bytes[i++];
    final int type = typeTable.codeUnitAt(byte) & typeMask;
    if (state == accept) {
      char = byte & (shiftedByteMask >> type);
      state = transitionTable.codeUnitAt(type);
    } else {
      char = (byte & 0x3F) | (_charOrIndex << 6);
      state = transitionTable.codeUnitAt(state + type);
    }

    while (i < end) {
      final int byte = bytes[i++];
      final int type = typeTable.codeUnitAt(byte) & typeMask;
      if (state == accept) {
        if (char >= 0x10000) {
          assert(char < 0x110000);
          writeIntoTwoByteString(result, j++, 0xD7C0 + (char >> 10));
          writeIntoTwoByteString(result, j++, 0xDC00 + (char & 0x3FF));
        } else {
          writeIntoTwoByteString(result, j++, char);
        }
        char = byte & (shiftedByteMask >> type);
        state = transitionTable.codeUnitAt(type);
      } else if (isErrorState(state)) {
        _state = state;
        _charOrIndex = i - 2;
        return "";
      } else {
        char = (byte & 0x3F) | (char << 6);
        state = transitionTable.codeUnitAt(state + type);
      }
    }

    // Final write?
    if (state == accept) {
      if (char >= 0x10000) {
        assert(char < 0x110000);
        writeIntoTwoByteString(result, j++, 0xD7C0 + (char >> 10));
        writeIntoTwoByteString(result, j++, 0xDC00 + (char & 0x3FF));
      } else {
        writeIntoTwoByteString(result, j++, char);
      }
    } else if (isErrorState(state)) {
      _state = state;
      _charOrIndex = end - 1;
      return "";
    }

    _state = state;
    _charOrIndex = char;
    // Output size must match, unless we are doing single conversion and are
    // inside an unfinished sequence (which will trigger an error later).
    assert(_bomIndex == 0 && _state != accept
        ? (j == size - 1 || j == size - 2)
        : (j == size));
    return result;
  }

  int _scanFlags = 0;

  static const int scanChunkSize = 65536;

  static const int flagExtension = 1 << 2;
  static const int flagLatin1 = 1 << 3;

  static const String scanTable = ""
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 00-1F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 20-3F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 40-5F
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" // 60-7F
      "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD" // 80-9F
      "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD" // A0-BF
      "aaIIQQQQQQQQQQQQQQQQQQQQQQQQQQQQ" // C0-DF
      "QQQQQQQQQQQQQQQQRRRRRbbbbbbbbbbb" // E0-FF
      ;

  int scan(U8List bytes, int start, int end) {
    // Assumes 0 <= start <= end <= bytes.length
    int size = 0;
    _scanFlags = 0;
    int localStart = start;
    while (end - localStart > scanChunkSize) {
      int localEnd = localStart + scanChunkSize;
      size += _scan(bytes, localStart, localEnd, scanTable);
      localStart = localEnd;
    }
    size += _scan(bytes, localStart, end, scanTable);
    return size;
  }

  int _scan(U8List bytes, int start, int end, String scanTable) {
    int size = 0;
    int flags = 0;
    for (int i = start; i < end; i++) {
      int t = scanTable.codeUnitAt(bytes[i]);
      size += t & sizeMask;
      flags |= t;
    }
    _scanFlags |= flags & flagsMask;
    return size;
  }

  static const int sizeMask = 0x03;
  static const int flagsMask = 0x3C;
}

void _copyRangeFromU8ListToOneByteString(
    U8List from, OneByteString to, int fromStart, int toStart, int length) {
  to.array.copy(toStart, from.data, fromStart, length);

  // for (int i = 0; i < length; i++) {
  //   writeIntoOneByteString(to, toStart + i, from[fromStart + i]);
  // }
}
