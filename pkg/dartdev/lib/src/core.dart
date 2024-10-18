// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as path;

import 'experiments.dart';
import 'sdk.dart';
import 'utils.dart';

// Initialize a default logger. We'll replace this with a verbose logger if
// necessary once we start parsing.
final Ansi ansi = Ansi(Ansi.terminalSupportsAnsi);
Logger log = Logger.standard(ansi: ansi);

bool isDiagnostics = false;

/// When set, this function is executed from the [DartdevCommand] constructor to
/// contribute additional flags.
void Function(ArgParser argParser, String cmdName)? flagContributor;

abstract class DartdevCommand extends Command<int> {
  static const errorExitCode = 65;

  final String _name;
  final String _description;
  final bool _verbose;

  Project? _project;

  @override
  final bool hidden;

  DartdevCommand(this._name, this._description, this._verbose,
      {this.hidden = false}) {
    flagContributor?.call(argParser, _name);
  }

  @override
  String get name => _name;

  @override
  String get description => _description;

  ArgParser? _argParser;

  @override
  ArgParser get argParser => _argParser ??= createArgParser();

  @override
  String get invocation {
    String result = super.invocation;
    if (_verbose) {
      var firstSpace = result.indexOf(' ');
      if (firstSpace < 0) firstSpace = result.length;
      result = result.replaceRange(firstSpace, firstSpace, ' [vm-options]');
    }
    return result;
  }

  /// Create the ArgParser instance for this command.
  ///
  /// Subclasses can override this in order to create a customized ArgParser.
  ArgParser createArgParser() =>
      ArgParser(usageLineLength: dartdevUsageLineLength);

  Project get project => _project ??= Project();
}

extension DartDevCommand on Command {
  /// Return whether commands should emit verbose output.
  bool get verbose => globalResults!.flag('verbose');

  /// Return whether the tool should emit diagnostic output.
  bool get diagnosticsEnabled => globalResults!.flag('diagnostics');

  /// Return whether any Dart experiments were specified by the user.
  bool get wereExperimentsSpecified =>
      globalResults?.wasParsed(experimentFlagName) ?? false;

  List<String> get specifiedExperiments =>
      globalResults!.multiOption(experimentFlagName);
}

/// A utility method to start a Dart VM instance with the given arguments and an
/// optional current working directory.
///
/// [arguments] should contain the snapshot path.
Future<Process> startDartProcess(
  Sdk sdk,
  List<String> arguments, {
  String? cwd,
}) {
  log.trace('${sdk.dart} ${arguments.join(' ')}');
  return Process.start(sdk.dart, arguments, workingDirectory: cwd);
}

Future<int> runProcess(
  List<String> command, {
  bool logToTrace = false,
  void Function(String str)? listener,
  String? cwd,
}) async {
  Future forward(Stream<List<int>> output, bool isStderr) {
    return _streamLineTransform(output, (line) {
      final trimmed = line.trimRight();
      logToTrace
          ? log.trace(trimmed)
          : (isStderr ? log.stderr(trimmed) : log.stdout(trimmed));
      if (listener != null) listener(line);
    });
  }

  log.trace(command.join(' '));
  final process = await Process.start(
    command.first,
    command.skip(1).toList(),
    workingDirectory: cwd,
  );
  final (_, _, exitCode) = await (
    forward(process.stdout, false),
    forward(process.stderr, true),
    process.exitCode
  ).wait;
  return exitCode;
}

Future<int> runProcessInheritStdio(
  List<String> command, {
  bool logToTrace = false,
  void Function(String str)? listener,
  String? cwd,
}) async {
  log.trace(command.join(' '));
  final process = await Process.start(
    command.first,
    command.skip(1).toList(),
    workingDirectory: cwd,
    mode: ProcessStartMode.inheritStdio,
  );
  return await process.exitCode;
}

Future _streamLineTransform(
  Stream<List<int>> stream,
  Function(String line) handler,
) {
  return stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(handler)
      .asFuture();
}

/// A representation of a project on disk.
class Project {
  final Directory dir;

  PackageConfig? _packageConfig;

  Project() : dir = Directory.current;

  Project.fromDirectory(this.dir);

  bool get hasPubspecFile =>
      FileSystemEntity.isFileSync(path.join(dir.path, 'pubspec.yaml'));

  File get pubspecFile => File(path.join(dir.path, 'pubspec.yaml'));

  bool get hasPackageConfigFile => packageConfig != null;

  PackageConfig? get packageConfig {
    if (_packageConfig == null) {
      File file =
          File(path.join(dir.path, '.dart_tool', 'package_config.json'));

      if (file.existsSync()) {
        try {
          dynamic contents = json.decode(file.readAsStringSync());
          _packageConfig = PackageConfig(contents);
        } catch (_) {}
      }
    }

    return _packageConfig;
  }
}

/// A simple representation of a `package_config.json` file.
class PackageConfig {
  final Map<String, dynamic> contents;

  PackageConfig(this.contents);

  List<Map<String, dynamic>?> get packages {
    List<dynamic> packages = contents['packages'];
    return packages.map<Map<String, dynamic>?>(castStringKeyedMap).toList();
  }

  bool hasDependency(String packageName) =>
      packages.any((element) => element!['name'] == packageName);
}
