// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library is copied from _fe_analyzer_shared.scanner.string_canonicalizer
// and modified.

import 'dart:_internal';
import 'dart:_object_helper';
import 'dart:_string';
import 'dart:_string_helper';
import 'dart:_typed_data';
import 'dart:_wasm';
import 'dart:convert';

// FIXME: I couldn't use a mixin for the common parts below as with a mixin
// `_nodes` becomes `WasmArray<T?>` with `T extends Node` mixin type parameter,
// which causes a crash when creating a selector info of something with
// arguments `WasmArray<_StringNode?>` and `WasmArray<_Utf8Node?>`, because
// these two types are different and they don't have a common supertype (they
// don't inherit from `Object`).

const int _INITIAL_SIZE = 8 * 1024;

class OneByteStringCanonicalizer {
  /// Size of the hash table.
  int _size = _INITIAL_SIZE;

  /// Items in the hash table.
  int _count = 0;

  WasmArray<OneByteString?> _nodes = WasmArray<OneByteString?>(_INITIAL_SIZE);

  void rehash() {
    final newSize = _size * 2;
    WasmArray<OneByteString?> newNodes = WasmArray<OneByteString?>(newSize);
    for (int i = 0; i < _size; i++) {
      OneByteString? t = _nodes[i];
      if (t != null) {
        // Use identity hash code as the string has already been hashed when
        // adding to the map.
        final newIndex = identityHashCode(t) & (newSize - 1);
        newNodes[newIndex] = t;
      }
    }
    _size = newSize;
    _nodes = newNodes;
  }

  OneByteString canonicalizeSubString(OneByteString data, int start, int end) {
    final len = end - start;
    if (start == 0 && data.length == len) {
      return canonicalizeString(data);
    }
    final int substringHash = data.computeHashCodeRange(start, end);
    int index = substringHash & (_size - 1);
    final OneByteString? s = _nodes[index];
    if (s != null) {
      if (s.length == len && data.startsWith(s, start)) {
        return s;
      }
    }
    if (_count >= _size / 2) {
      rehash();
      index = substringHash & (_size - 1);
    }
    final OneByteString newNode = data.substringUnchecked(start, end);
    setIdentityHashField(newNode, substringHash);
    _nodes[index] = newNode;
    return newNode;
  }

  OneByteString canonicalizeString(OneByteString data) {
    if (_count >= _size / 2) rehash();
    final int index = data.hashCode & (_size - 1);
    _nodes[index] = data;
    return data;
  }

  void clear() {
    _size = _INITIAL_SIZE;
    _nodes = WasmArray<OneByteString?>(_size);
    _count = 0;
  }
}

class TwoByteStringCanonicalizer {
  /// Size of the hash table.
  int _size = _INITIAL_SIZE;

  /// Items in the hash table.
  int _count = 0;

  WasmArray<TwoByteString?> _nodes = WasmArray<TwoByteString?>(_INITIAL_SIZE);

  void rehash() {
    final newSize = _size * 2;
    WasmArray<TwoByteString?> newNodes = WasmArray<TwoByteString?>(newSize);
    for (int i = 0; i < _size; i++) {
      TwoByteString? t = _nodes[i];
      if (t != null) {
        // Use identity hash code as the string has already been hashed when
        // adding to the map.
        final newIndex = identityHashCode(t) & (newSize - 1);
        newNodes[newIndex] = t;
      }
    }
    _size = newSize;
    _nodes = newNodes;
  }

  TwoByteString canonicalizeSubString(TwoByteString data, int start, int end) {
    final len = end - start;
    if (start == 0 && data.length == len) {
      return canonicalizeString(data);
    }
    final int substringHash = data.computeHashCodeRange(start, end);
    int index = substringHash & (_size - 1);
    final TwoByteString? s = _nodes[index];
    if (s != null) {
      if (s.length == len && data.startsWith(s, start)) {
        return s;
      }
    }
    if (_count >= _size / 2) {
      rehash();
      index = substringHash & (_size - 1);
    }
    final TwoByteString newNode = data.substringUnchecked(start, end);
    setIdentityHashField(newNode, substringHash);
    _nodes[index] = newNode;
    return newNode;
  }

  TwoByteString canonicalizeString(TwoByteString data) {
    if (_count >= _size / 2) rehash();
    final int index = data.hashCode & (_size - 1);
    _nodes[index] = data;
    return data;
  }

  void clear() {
    _size = _INITIAL_SIZE;
    _nodes = WasmArray<TwoByteString?>(_size);
    _count = 0;
  }
}

class _Utf8Node {
  final StringBase payload;

  _Utf8Node? next;

  final U8List data;
  final int start;
  final int end;

  _Utf8Node(this.data, this.start, this.end, this.payload, this.next);

  int get hash => payload.hashCode;
}

class Utf8StringCanonicalizer {
  /// Linear size of a hash table.
  int _size = _INITIAL_SIZE;

  /// Items in a hash table.
  int _count = 0;

  WasmArray<_Utf8Node?> _nodes = WasmArray<_Utf8Node?>(_INITIAL_SIZE);

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
    if (_count >= _size / 2) rehash();
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
      index,
      s,
      data,
      start,
      end,
      _decodeString(data, start, end, asciiOnly),
    );
  }

  String _insertUtf8Node(
    int index,
    _Utf8Node? next,
    U8List buffer,
    int start,
    int end,
    StringBase value,
  ) {
    final _Utf8Node newNode = _Utf8Node(buffer, start, end, value, next);
    _nodes[index] = newNode;
    _count++;
    return value;
  }

  void clear() {
    initializeWithSize(_INITIAL_SIZE);
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
        const Utf8Decoder(allowMalformed: true).convert(bytes, start, end),
      );
}

int _hashBytes(U8List data, int start, int end) {
  // Same as string hash code
  int hash = 0;
  for (int i = start; i < end; i++) {
    hash = stringCombineHashes(hash, data.getUnchecked(i));
  }
  return stringFinalizeHash(hash);
}
