// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:status_file/canonical_status_file.dart';
import 'package:status_file/status_file.dart' as status_file;
import 'package:status_file/status_file_linter.dart';
import 'package:status_file/utils.dart';

ArgParser buildParser() {
  var parser = ArgParser();
  parser.addFlag("check-for-disjunctions",
      negatable: false,
      defaultsTo: false,
      help: "Warn if a status header expression contains '||'.");
  parser.addFlag("check-for-non-existing",
      negatable: true,
      defaultsTo: true,
      help: "Check for and error on non-existing test entries.");
  parser.addFlag("text",
      abbr: "t",
      negatable: false,
      defaultsTo: false,
      help: "Lint text passed in stdin.");
  parser.addFlag("help",
      abbr: "h",
      negatable: false,
      defaultsTo: false,
      help: "Show help and commands for this tool.");
  return parser;
}

void printHelp(ArgParser parser) {
  print("Usage: 'dart status_file/bin/lint.dart <path>' or 'dart "
      "status_file/bin/lint.dart -t <input>' for text input.");
  print(parser.usage);
}

void main(List<String> arguments) {
  var parser = buildParser();
  var results = parser.parse(arguments);
  if (results["help"]) {
    printHelp(parser);
    return;
  }
  bool checkForDisjunctions = results["check-for-disjunctions"];
  bool checkForNonExisting = results["check-for-non-existing"];
  bool usePipe = results["text"];
  if (usePipe) {
    lintStdIn(
        checkForDisjunctions: checkForDisjunctions,
        checkForNonExisting: checkForNonExisting);
  } else {
    if (results.rest.length != 1) {
      printHelp(parser);
      exit(1);
    }
    lintPath(results.rest.first,
        checkForDisjunctions: checkForDisjunctions,
        checkForNonExisting: checkForNonExisting);
  }
}

void lintStdIn(
    {bool checkForDisjunctions = false, required bool checkForNonExisting}) {
  var strings = <String>[];
  try {
    while (true) {
      var readString = stdin.readLineSync();
      if (readString == null) break;
      strings.add(readString);
    }
  } on StdinException {
    // I do not know why this happens.
  }
  if (!lintText(strings, checkForNonExisting: checkForNonExisting)) {
    exit(1);
  }
}

void lintPath(path,
    {bool checkForDisjunctions = false, required bool checkForNonExisting}) {
  var filesWithErrors = <String>[];
  if (FileSystemEntity.isFileSync(path)) {
    if (!lintFile(path,
        checkForDisjunctions: checkForDisjunctions,
        checkForNonExisting: checkForNonExisting)) {
      filesWithErrors.add(path);
    }
  } else if (FileSystemEntity.isDirectorySync(path)) {
    Directory(path).listSync(recursive: true).forEach((entry) {
      if (!canLint(entry.path)) {
        return;
      }
      if (!lintFile(entry.path,
          checkForDisjunctions: checkForDisjunctions,
          checkForNonExisting: checkForNonExisting)) {
        filesWithErrors.add(entry.path);
      }
    });
  }
  if (filesWithErrors.isNotEmpty) {
    print("File output does not match how status files should be formatted.");
    print("Fix these issues with:");
    print("dart ${Platform.script.resolve("normalize.dart").path} -w \\");
    print(filesWithErrors.join(" \\\n"));
    exit(1);
  }
}

bool lintText(List<String> text,
    {bool checkForDisjunctions = false, required bool checkForNonExisting}) {
  try {
    var statusFile = StatusFile.parse("stdin", text);
    return lintStatusFile(statusFile,
        checkForDisjunctions: checkForDisjunctions,
        checkForNonExisting: checkForNonExisting);
  } on status_file.SyntaxError {
    stderr.writeln("Could not parse stdin.");
  }
  return false;
}

bool lintFile(String path,
    {bool checkForDisjunctions = false, required bool checkForNonExisting}) {
  try {
    var statusFile = StatusFile.read(path);
    return lintStatusFile(statusFile,
        checkForDisjunctions: checkForDisjunctions,
        checkForNonExisting: checkForNonExisting);
  } on status_file.SyntaxError catch (error) {
    stderr.writeln("Could not parse $path:\n$error");
  }
  return false;
}

bool lintStatusFile(StatusFile statusFile,
    {bool checkForDisjunctions = false, required bool checkForNonExisting}) {
  var lintingErrors = lint(statusFile,
      checkForDisjunctions: checkForDisjunctions,
      checkForNonExisting: checkForNonExisting);
  if (lintingErrors.isEmpty) {
    print("${statusFile.path}\n Status file passed all tests");
    print("");
    return true;
  }
  if (statusFile.path.isNotEmpty) {
    print(statusFile.path);
  }
  var errors = lintingErrors.toList();
  errors.sort((a, b) => a.lineNumber.compareTo((b.lineNumber)));
  errors.forEach(print);
  print("");
  return false;
}
