// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build_integration/file_system/multi_root.dart'
    show MultiRootFileSystem;
import 'package:front_end/src/api_prototype/macros.dart' as macros
    show isMacroLibraryUri;
import 'package:front_end/src/api_prototype/standard_file_system.dart'
    show StandardFileSystem;
import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerOptions,
        CompilerResult,
        DiagnosticMessage,
        kernelForProgram,
        NnbdMode,
        Severity;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart' show writeComponentToText;
import 'package:kernel/library_index.dart';
import 'package:kernel/verifier.dart';
import 'package:vm/kernel_front_end.dart' show writeDepfile;
import 'package:vm/transformations/mixin_deduplication.dart'
    as mixin_deduplication show transformComponent;
import 'package:vm/transformations/to_string_transformer.dart'
    as to_string_transformer;
import 'package:vm/transformations/type_flow/transformer.dart' as globalTypeFlow
    show transformComponent;
import 'package:vm/transformations/unreachable_code_elimination.dart'
    as unreachable_code_elimination;
import 'package:wasm_builder/wasm_builder.dart' show Module, Serializer;

import 'compiler_options.dart' as compiler;
import 'constant_evaluator.dart';
import 'js/runtime_generator.dart' as js;
import 'record_class_generator.dart';
import 'records.dart';
import 'target.dart' as wasm show Mode;
import 'target.dart' hide Mode;
import 'translator.dart';

class CompilerOutput {
  final Module _wasmModule;
  final String jsRuntime;

  late final Uint8List wasmModule = _serializeWasmModule();

  Uint8List _serializeWasmModule() {
    final s = Serializer();
    _wasmModule.serialize(s);
    return s.data;
  }

  CompilerOutput(this._wasmModule, this.jsRuntime);
}

/// Compile a Dart file into a Wasm module.
///
/// Returns `null` if an error occurred during compilation. The
/// [handleDiagnosticMessage] callback will have received an error message
/// describing the error.
Future<CompilerOutput?> compileToModule(compiler.WasmCompilerOptions options,
    void Function(DiagnosticMessage) handleDiagnosticMessage) async {
  var succeeded = true;
  void diagnosticMessageHandler(DiagnosticMessage message) {
    if (message.severity == Severity.error) {
      succeeded = false;
    }
    handleDiagnosticMessage(message);
  }

  final wasm.Mode mode;
  if (options.translatorOptions.jsCompatibility) {
    mode = wasm.Mode.jsCompatibility;
  } else {
    mode = wasm.Mode.regular;
  }
  final WasmTarget target = WasmTarget(
      removeAsserts: !options.translatorOptions.enableAsserts, mode: mode);
  CompilerOptions compilerOptions = CompilerOptions()
    ..target = target
    ..sdkRoot = options.sdkPath
    ..librariesSpecificationUri = options.librariesSpecPath
    ..packagesFileUri = options.packagesPath
    ..environmentDefines = options.environment
    ..explicitExperimentalFlags = options.feExperimentalFlags
    ..verbose = false
    ..onDiagnostic = diagnosticMessageHandler
    ..nnbdMode = NnbdMode.Strong;
  if (options.multiRootScheme != null) {
    compilerOptions.fileSystem = MultiRootFileSystem(
        options.multiRootScheme!,
        options.multiRoots.isEmpty ? [Uri.base] : options.multiRoots,
        StandardFileSystem.instance);
  }

  if (options.platformPath != null) {
    compilerOptions.sdkSummary = options.platformPath;
  } else {
    compilerOptions.compileSdk = true;
  }

  CompilerResult? compilerResult =
      await kernelForProgram(options.mainUri, compilerOptions);
  if (compilerResult == null || !succeeded) {
    return null;
  }
  Component component = compilerResult.component!;
  CoreTypes coreTypes = compilerResult.coreTypes!;
  ClassHierarchy classHierarchy = compilerResult.classHierarchy!;
  LibraryIndex libraryIndex = LibraryIndex(component, [
    "dart:_internal",
    "dart:_js_helper",
    "dart:_js_types",
    "dart:_wasm",
    "dart:async",
    "dart:collection",
    "dart:core",
    "dart:ffi",
    "dart:typed_data",
  ]);

  if (options.dumpKernelAfterCfe != null) {
    writeComponentToText(component, path: options.dumpKernelAfterCfe!);
  }

  if (options.deleteToStringPackageUri.isNotEmpty) {
    to_string_transformer.transformComponent(
        component, options.deleteToStringPackageUri);
  }

  ConstantEvaluator constantEvaluator = ConstantEvaluator(
      options, target, component, coreTypes, classHierarchy, libraryIndex);
  unreachable_code_elimination.transformComponent(target, component,
      constantEvaluator, options.translatorOptions.enableAsserts);

  js.RuntimeFinalizer jsRuntimeFinalizer =
      js.createRuntimeFinalizer(component, coreTypes, classHierarchy);

  final Map<RecordShape, Class> recordClasses =
      generateRecordClasses(component, coreTypes);
  target.recordClasses = recordClasses;

  if (options.dumpKernelBeforeTfa != null) {
    writeComponentToText(component, path: options.dumpKernelBeforeTfa!);
  }

  mixin_deduplication.transformComponent(component);

  // Keep the flags in-sync with
  // pkg/vm/test/transformations/type_flow/transformer_test.dart
  globalTypeFlow.transformComponent(target, coreTypes, component,
      useRapidTypeAnalysis: false);

  if (options.dumpKernelAfterTfa != null) {
    writeComponentToText(component,
        path: options.dumpKernelAfterTfa!, showMetadata: true);
  }

  assert(() {
    verifyComponent(
        target, VerificationStage.afterGlobalTransformations, component);
    return true;
  }());

  var translator = Translator(component, coreTypes, libraryIndex, recordClasses,
      options.translatorOptions);

  String? depFile = options.depFile;
  if (depFile != null) {
    writeDepfile(
        compilerOptions.fileSystem,
        // TODO(https://dartbug.com/55246): track macro deps when available.
        component.uriToSource.keys
            .where((uri) => !macros.isMacroLibraryUri(uri)),
        options.outputFile,
        depFile);
  }

  final wasmModule = translator.translate();
  String jsRuntime = jsRuntimeFinalizer.generate(
      translator.functions.translatedProcedures,
      translator.internalizedStringsForJSRuntime,
      mode);
  return CompilerOutput(wasmModule, jsRuntime);
}
