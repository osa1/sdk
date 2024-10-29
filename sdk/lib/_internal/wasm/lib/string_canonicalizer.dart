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

// FIXME: I couldn't use a mixin for the common parts below as with a mixin
// `_nodes` becomes `WasmArray<T?>` with `T extends Node` mixin type parameter,
// which causes a crash when creating a selector info of something with
// arguments `WasmArray<_StringNode?>` and `WasmArray<_Utf8Node?>`, because
// these two types are different and they don't have a common supertype (they
// don't inherit from `Object`).

class _StringNode {
  final StringBase payload;

  _StringNode? next;

  _StringNode(this.payload, this.next);

  int get hash => _hashString(payload, /* start = */ 0, payload.length);
}

class _Utf8Node {
  final StringBase payload;

  _Utf8Node? next;

  final U8List data;
  final int start;
  final int end;

  _Utf8Node(this.data, this.start, this.end, this.payload, this.next);

  int get hash => _hashBytes(data, start, end);
}

class StringCanonicalizer {
  static const int INITIAL_SIZE = 8 * 1024;

  /// Linear size of a hash table.
  int _size = INITIAL_SIZE;

  /// Items in a hash table.
  int _count = 0;

  WasmArray<_StringNode?> _nodes = WasmArray<_StringNode?>(INITIAL_SIZE);

  void rehash() {
    int newSize = _size * 2;
    WasmArray<_StringNode?> newNodes = WasmArray<_StringNode?>(newSize);
    for (int i = 0; i < _size; i++) {
      _StringNode? t = _nodes[i];
      while (t != null) {
        _StringNode? n = t.next;
        int newIndex = t.hash & (newSize - 1);
        _StringNode? s = newNodes[newIndex];
        t.next = s;
        newNodes[newIndex] = t;
        t = n;
      }
    }
    _size = newSize;
    _nodes = newNodes;
  }

  String canonicalizeSubString(StringBase data, int start, int end) {
    final int len = end - start;
    if (start == 0 && data.length == len) {
      return canonicalizeString(data);
    }
    if (_count > _size) rehash();
    final int index = _hashString(data, start, end) & (_size - 1);
    final _StringNode? s = _nodes[index];
    _StringNode? t = s;
    while (t != null) {
      if (t is _StringNode) {
        final String tData = t.payload;
        if (tData.length == len && data.startsWith(tData, start)) {
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
    final _StringNode? s = _nodes[index];
    _StringNode? t = s;
    while (t != null) {
      final String tData = t.payload;
      if (identical(data, tData) || data == tData) {
        return tData;
      }
      t = t.next;
    }
    return _insertStringNode(index, s, data);
  }

  String _insertStringNode(int index, _StringNode? next, StringBase value) {
    final _StringNode newNode = _StringNode(value, next);
    _nodes[index] = newNode;
    _count++;
    return value;
  }

  void clear() {
    initializeWithSize(INITIAL_SIZE);
  }

  void initializeWithSize(int size) {
    _size = size;
    _nodes = WasmArray<_StringNode?>(_size);
    _count = 0;
  }
}

class Utf8StringCanonicalizer {
  static const int INITIAL_SIZE = 8 * 1024;

  /// Linear size of a hash table.
  int _size = INITIAL_SIZE;

  /// Items in a hash table.
  int _count = 0;

  WasmArray<_Utf8Node?> _nodes = WasmArray<_Utf8Node?>(INITIAL_SIZE);

  void rehash() {
    int newSize = _size * 2;
    WasmArray<_Utf8Node?> newNodes = WasmArray<_Utf8Node?>(newSize);
    for (int i = 0; i < _size; i++) {
      _Utf8Node? t = _nodes[i];
      while (t != null) {
        _Utf8Node? n = t.next;
        int newIndex = t.hash & (newSize - 1);
        _Utf8Node? s = newNodes[newIndex];
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
    _Utf8Node? s = _nodes[index];
    _Utf8Node? t = s;
    int len = end - start;
    while (t != null) {
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
      t = t.next;
    }
    return _insertUtf8Node(
        index, s, data, start, end, _decodeString(data, start, end, asciiOnly));
  }

  String _insertUtf8Node(int index, _Utf8Node? next, U8List buffer, int start,
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
    _nodes = WasmArray<_Utf8Node?>(_size);
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
