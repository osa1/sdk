import 'dart:io';
import 'package:source_maps/parser.dart';
import 'package:source_span/source_span.dart';
import 'dart2js_mapping.dart';

abstract class FileProvider {
  String sourcesFor(Uri uri);
  SourceFile fileFor(Uri uri);
  Dart2jsMapping? mappingFor(Uri uri);
}

class CachingFileProvider implements FileProvider {
  final Map<Uri, String> _sources = {};
  final Map<Uri, SourceFile> _files = {};
  final Map<Uri, Dart2jsMapping?> _mappings = {};
  final Logger? logger;

  CachingFileProvider({this.logger});

  @override
  String sourcesFor(Uri uri) =>
      _sources[uri] ??= File.fromUri(uri).readAsStringSync();

  @override
  SourceFile fileFor(Uri uri) =>
      _files[uri] ??= SourceFile.fromString(sourcesFor(uri));

  @override
  Dart2jsMapping? mappingFor(Uri uri) =>
      _mappings[uri] ??= parseMappingFor(uri, logger: logger);
}

/// A provider that converts `http:` URLs to a `file:` URI assuming that all
/// files were downloaded on the current working directory.
///
/// Typically used when downloading the source and source-map files and applying
/// deobfuscation locally for debugging purposes.
class DownloadedFileProvider extends CachingFileProvider {
  Uri _localize(Uri uri) {
    if (uri.isScheme('http') || uri.isScheme('https')) {
      String filename = uri.path.substring(uri.path.lastIndexOf('/') + 1);
      return Uri.base.resolve(filename);
    }
    return uri;
  }

  @override
  String sourcesFor(Uri uri) => super.sourcesFor(_localize(uri));

  @override
  SourceFile fileFor(Uri uri) => super.fileFor(_localize(uri));

  @override
  Dart2jsMapping? mappingFor(Uri uri) => super.mappingFor(_localize(uri));
}

class Logger {
  final Set<String> _seenMessages = <String>{};
  log(String message) {
    if (_seenMessages.add(message)) {
      print(message);
    }
  }
}

var logger = Logger();

SingleMapping parseSingleMapping(Map json) => parseJson(json) as SingleMapping;
