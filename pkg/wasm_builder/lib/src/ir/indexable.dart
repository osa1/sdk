// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ir.dart';

mixin Indexable {
  FinalizableIndex get finalizableIndex;

  // Index will be valid only after finalization. If a unique id is required
  // before finalization, use `id`.
  int get index => finalizableIndex.value;
  int get id => finalizableIndex.id;
}
