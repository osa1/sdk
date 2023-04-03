// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:dartdev/src/utils.dart';
import 'package:dartdoc/dartdoc.dart';
import 'package:dartdoc/options.dart';
import 'package:path/path.dart' as path;

import '../core.dart';
import '../sdk.dart';

/// A command to generate documentation for a project.
class DocCommand extends DartdevCommand {
  static const String cmdName = 'doc';

  static const String cmdDescription = '''
Generate API documentation for Dart projects.

For additional documentation generation options, see the 'dartdoc_options.yaml' file documentation at https://dart.dev/go/dartdoc-options-file.''';

  DocCommand({bool verbose = false}) : super(cmdName, cmdDescription, verbose) {
    argParser.addOption(
      'output',
      abbr: 'o',
      valueHelp: 'directory',
      defaultsTo: path.join('doc', 'api'),
      aliases: [
        // The CLI option that shipped with Dart 2.16.
        'output-dir',
      ],
      help: 'Configure the output directory.',
    );
    argParser.addFlag(
      'validate-links',
      negatable: false,
      help: 'Display warnings for broken links.  Incompatible with --dry-run.',
    );
    argParser.addFlag(
      'sdk-docs',
      hide: true,
      negatable: false,
      help: 'Generate API docs for the Dart SDK.',
    );
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Try to generate the docs without saving them.',
    );
    argParser.addFlag(
      'pub',
      defaultsTo: true,
      hide: !verbose,
      help: 'Run an implicit `pub get` to resolve `pubspec.yaml` first.',
    );
  }

  @override
  String get invocation => '${super.invocation} [<directory>]';

  @override
  FutureOr<int> run() async {
    final options = <String>[];
    final args = argResults!;
    // The directory to create docs for.
    String? directory;
    if (args['sdk-docs']) {
      options.add('--sdk-docs');
    } else {
      if (args.rest.length > 1) {
        usageException("'dart doc' only supports one input directory.'");
      }

      // Determine input directory; default to the cwd if no explicit input dir
      // is passed in.
      directory =
          args.rest.isEmpty ? io.Directory.current.path : args.rest.first;
      if (!io.Directory(directory).existsSync()) {
        usageException('Input directory doesn\'t exist: $directory');
      }
      options.add('--input=$directory');
    }

    if (args['dry-run'] && args['validate-links']) {
      usageException("'dart doc' can not validate links when dry-running.");
    }

    // Specify where dartdoc resources are located.
    final resourcesPath =
        path.absolute(sdk.sdkPath, 'bin', 'resources', 'dartdoc', 'resources');

    // Build remaining options.
    options.addAll([
      '--output=${args['output']}',
      '--resources-dir=$resourcesPath',
      args['validate-links'] ? '--validate-links' : '--no-validate-links',
      if (args['dry-run']) '--no-generate-docs',
      if (verbose) ...['--verbose-warnings', '--show-stats'],
    ]);

    final config = parseOptions(pubPackageMetaProvider, options);
    if (config == null) {
      // There was an error while parsing options.
      return 2;
    }

    // Call into package:dartdoc.
    if (verbose) {
      log.stdout('Using the following options: $options');
    }
    if (args['pub'] && directory != null) {
      await findEnclosingProjectAndResolveIfNeeded(directory);
    }
    final packageConfigProvider = PhysicalPackageConfigProvider();
    final packageBuilder = PubPackageBuilder(
        config, pubPackageMetaProvider, packageConfigProvider);
    final dartdoc = config.generateDocs
        ? await Dartdoc.fromContext(config, packageBuilder)
        : Dartdoc.withEmptyGenerator(config, packageBuilder);
    dartdoc.executeGuarded();
    return 0;
  }
}
