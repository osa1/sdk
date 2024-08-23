// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Simple script that shows the inferred types of a function.
library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart';

import 'usage_exception.dart';

class ShowInferredTypesCommand extends Command<void> with PrintUsageException {
  @override
  final String name = "show_inferred";
  @override
  final String description = "Show data inferred by dart2js global inference";

  ShowInferredTypesCommand() {
    argParser.addFlag('long-names',
        abbr: 'l', negatable: false, help: 'Show long qualified names.');
  }

  @override
  void run() async {
    final argRes = argResults!;
    var args = argRes.rest;
    if (args.length < 2) {
      usageException(
          'Missing arguments, expected: info.data <function-name-regex>');
    }
    await _showInferredTypes(args[0], args[1], argRes['long-names']);
  }
}

Future<void> _showInferredTypes(
    String infoFile, String pattern, bool showLongName) async {
  var info = await infoFromFile(infoFile);
  var nameRegExp = RegExp(pattern);
  bool matches(e) => nameRegExp.hasMatch(longName(e));

  bool noResults = true;
  void showMethods() {
    var sources = info.functions.where(matches).toList();
    if (sources.isEmpty) return;
    noResults = false;
    for (var s in sources) {
      var params = s.parameters.map((p) => '${p.name}: ${p.type}').join(', ');
      var name = showLongName ? longName(s) : s.name;
      print('$name($params): ${s.returnType}');
    }
  }

  void showFields() {
    var sources = info.fields.where(matches).toList();
    if (sources.isEmpty) return;
    noResults = false;
    for (var s in sources) {
      var name = showLongName ? longName(s) : s.name;
      print('$name: ${s.inferredType}');
    }
  }

  showMethods();
  showFields();
  if (noResults) {
    print('error: no function or field that matches $pattern was found.');
    exit(1);
  }
}
