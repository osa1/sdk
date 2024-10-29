// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library is copied from _fe_analyzer_shared.scanner.string_canonicalizer
// and modified.

import 'dart:_internal';
import 'dart:_string';
import 'dart:_typed_data';
import 'dart:_wasm';
import 'dart:convert';

abstract class _Node {
  final StringBase payload;
  _Node? next;

  _Node(this.payload, this.next);

  int get hash;
}

class _StringNode extends _Node {
  int usageCount = 1;

  _StringNode(super.payload, super.next);

  @override
  int get hash => _hashString(payload, /* start = */ 0, payload.length);
}

class _Utf8Node extends _Node {
  final U8List data;
  final int start;
  final int end;

  _Utf8Node(this.data, this.start, this.end, StringBase payload, _Node? next)
      : super(payload, next);

  @override
  int get hash => _hashBytes(data, start, end);
}

/// A hash table for triples:
/// (list of bytes, start, end) --> canonicalized string
/// Using triples avoids allocating string slices before checking if they
/// are canonical.
class StringCanonicalizer {
  static const int INITIAL_SIZE = 8 * 1024;

  /// Linear size of a hash table.
  int _size = INITIAL_SIZE;

  /// Items in a hash table.
  int _count = 0;

  WasmArray<_Node?> _nodes = WasmArray<_Node?>(INITIAL_SIZE);

  void rehash() {
    int newSize = _size * 2;
    WasmArray<_Node?> newNodes = WasmArray<_Node?>(newSize);
    for (int i = 0; i < _size; i++) {
      _Node? t = _nodes[i];
      while (t != null) {
        _Node? n = t.next;
        int newIndex = t.hash & (newSize - 1);
        _Node? s = newNodes[newIndex];
        t.next = s;
        newNodes[newIndex] = t;
        t = n;
      }
    }
    _size = newSize;
    _nodes = newNodes;
  }

  String canonicalizeBytes(U8List data, int start, int end, bool asciiOnly) {
    if (_count > _size) rehash();
    final int index = _hashBytes(data, start, end) & (_size - 1);
    _Node? s = _nodes[index];
    _Node? t = s;
    int len = end - start;
    while (t != null) {
      if (t is _Utf8Node) {
        final U8List tData = t.data;
        if (t.end - t.start == len) {
          int i = start, j = t.start;
          while (i < end && data.getUnchecked(i) == tData.getUnchecked(j)) {
            i++;
            j++;
          }
          if (i == end) {
            return t.payload;
          }
        }
      }
      t = t.next;
    }
    return _insertUtf8Node(
        index, s, data, start, end, _decodeString(data, start, end, asciiOnly));
  }

  String canonicalizeSubString(StringBase data, int start, int end) {
    final int len = end - start;
    if (start == 0 && data.length == len) {
      return canonicalizeString(data);
    }
    if (_count > _size) rehash();
    final int index = _hashString(data, start, end) & (_size - 1);
    final _Node? s = _nodes[index];
    _Node? t = s;
    while (t != null) {
      if (t is _StringNode) {
        final String tData = t.payload;
        if (tData.length == len && data.startsWith(tData, start)) {
          t.usageCount++;
          return tData;
        }
      }
      t = t.next;
    }
    return _insertStringNode(
        index, s, unsafeCast<StringBase>(data.substringUnchecked(start, end)));
  }

  String canonicalizeString(StringBase data) {
    if (_count > _size) rehash();
    final int index =
        _hashString(data, /* start = */ 0, data.length) & (_size - 1);
    final _Node? s = _nodes[index];
    _Node? t = s;
    while (t != null) {
      if (t is _StringNode) {
        final String tData = t.payload;
        if (identical(data, tData) || data == tData) {
          t.usageCount++;
          return tData;
        }
      }
      t = t.next;
    }
    return _insertStringNode(index, s, data);
  }

  String _insertStringNode(int index, _Node? next, StringBase value) {
    final _StringNode newNode = _StringNode(value, next);
    _nodes[index] = newNode;
    _count++;
    return value;
  }

  String _insertUtf8Node(int index, _Node? next, U8List buffer, int start,
      int end, StringBase value) {
    final _Utf8Node newNode = _Utf8Node(buffer, start, end, value, next);
    _nodes[index] = newNode;
    _count++;
    return value;
  }

  void clear() {
    initializeWithSize(INITIAL_SIZE);
  }

  void initializeWithSize(int size) {
    _size = size;
    _nodes = WasmArray<_Node?>(_size);
    _count = 0;
  }
}

/// Decode UTF-8 without canonicalizing it.
StringBase _decodeString(U8List bytes, int start, int end, bool isAscii) {
  return isAscii
      ? createOneByteStringFromCharactersArray(bytes.data, start, end)
      : unsafeCast<StringBase>(
          const Utf8Decoder(allowMalformed: true).convert(bytes, start, end));
}

int _hashBytes(U8List data, int start, int end) {
  int h = 5381;
  for (int i = start; i < end; i++) {
    h = (h << 5) + h + data.getUnchecked(i);
  }
  return h;
}

int _hashString(StringBase data, int start, int end) {
  int h = 5381;
  for (int i = start; i < end; i++) {
    h = (h << 5) + h + data.codeUnitAtUnchecked(i);
  }
  return h;
}
