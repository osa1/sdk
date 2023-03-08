// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// We allow some snake_case and SCREAMING_SNAKE_CASE identifiers in generated
// code, as they match names declared in the source configuration files.
// ignore_for_file: constant_identifier_names

import "package:analyzer/error/error.dart";
import "package:analyzer/src/error/analyzer_error_code.dart";

class HintCode extends AnalyzerErrorCode {
  ///  When the target expression uses '?.' operator, it can be `null`, so all the
  ///  subsequent invocations should also use '?.' operator.
  ///
  ///  Note: This diagnostic is only generated in pre-null safe code.
  static const HintCode CAN_BE_NULL_AFTER_NULL_AWARE = HintCode(
    'CAN_BE_NULL_AFTER_NULL_AWARE',
    "The receiver uses '?.', so its value can be null.",
    correctionMessage: "Replace the '.' with a '?.' in the invocation.",
  );

  ///  Dead code is code that is never reached, this can happen for instance if a
  ///  statement follows a return statement.
  ///
  ///  No parameters.
  static const HintCode DEAD_CODE = HintCode(
    'DEAD_CODE',
    "Dead code.",
    correctionMessage:
        "Try removing the code, or fixing the code before it so that it can be "
        "reached.",
    hasPublishedDocs: true,
  );

  ///  Dead code is code that is never reached. This case covers cases where the
  ///  user has catch clauses after `catch (e)` or `on Object catch (e)`.
  ///
  ///  No parameters.
  static const HintCode DEAD_CODE_CATCH_FOLLOWING_CATCH = HintCode(
    'DEAD_CODE_CATCH_FOLLOWING_CATCH',
    "Dead code: Catch clauses after a 'catch (e)' or an 'on Object catch (e)' "
        "are never reached.",
    correctionMessage:
        "Try reordering the catch clauses so that they can be reached, or "
        "removing the unreachable catch clauses.",
    hasPublishedDocs: true,
  );

  ///  Dead code is code that is never reached. This case covers cases where the
  ///  user has an on-catch clause such as `on A catch (e)`, where a supertype of
  ///  `A` was already caught.
  ///
  ///  Parameters:
  ///  0: name of the subtype
  ///  1: name of the supertype
  static const HintCode DEAD_CODE_ON_CATCH_SUBTYPE = HintCode(
    'DEAD_CODE_ON_CATCH_SUBTYPE',
    "Dead code: This on-catch block won't be executed because '{0}' is a "
        "subtype of '{1}' and hence will have been caught already.",
    correctionMessage:
        "Try reordering the catch clauses so that this block can be reached, "
        "or removing the unreachable catch clause.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode DEPRECATED_COLON_FOR_DEFAULT_VALUE = HintCode(
    'DEPRECATED_COLON_FOR_DEFAULT_VALUE',
    "Using a colon as a separator before a default value is deprecated and "
        "will not be supported in language version 3.0 and later.",
    correctionMessage: "Try replacing the colon with an equal sign.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the element
  static const HintCode DEPRECATED_EXPORT_USE = HintCode(
    'DEPRECATED_EXPORT_USE',
    "The ability to import '{0}' indirectly is deprecated.",
    correctionMessage: "Try importing '{0}' directly.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the member
  static const HintCode DEPRECATED_MEMBER_USE = HintCode(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the member
  static const HintCode DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE = HintCode(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the member
  ///  1: message details
  static const HintCode DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE =
      HintCode(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE',
  );

  ///  Parameters:
  ///  0: the name of the member
  ///  1: message details
  static const HintCode DEPRECATED_MEMBER_USE_WITH_MESSAGE = HintCode(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_WITH_MESSAGE',
  );

  ///  No parameters.
  static const HintCode DIVISION_OPTIMIZATION = HintCode(
    'DIVISION_OPTIMIZATION',
    "The operator x ~/ y is more efficient than (x / y).toInt().",
    correctionMessage:
        "Try re-writing the expression to use the '~/' operator.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION = HintCode(
    'IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
    "The imported library defines a top-level function named 'loadLibrary' "
        "that is hidden by deferring this library.",
    correctionMessage:
        "Try changing the import to not be deferred, or rename the function in "
        "the imported library.",
    hasPublishedDocs: true,
  );

  ///  https://github.com/dart-lang/sdk/issues/44063
  ///
  ///  Parameters:
  ///  0: the name of the library
  static const HintCode IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE = HintCode(
    'IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE',
    "The library '{0}' is legacy, and shouldn't be imported into a null safe "
        "library.",
    correctionMessage: "Try migrating the imported library.",
    hasPublishedDocs: true,
  );

  ///  Generate a hint for non-const instance creation using a constructor
  ///  annotated with `@literal`.
  ///
  ///  Parameters:
  ///  0: the name of the class defining the annotated constructor
  static const HintCode NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR = HintCode(
    'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
    "This instance creation must be 'const', because the {0} constructor is "
        "marked as '@literal'.",
    correctionMessage: "Try adding a 'const' keyword.",
    hasPublishedDocs: true,
  );

  ///  Generate a hint for non-const instance creation (with the `new` keyword)
  ///  using a constructor annotated with `@literal`.
  ///
  ///  Parameters:
  ///  0: the name of the class defining the annotated constructor
  static const HintCode NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW =
      HintCode(
    'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
    "This instance creation must be 'const', because the {0} constructor is "
        "marked as '@literal'.",
    correctionMessage: "Try replacing the 'new' keyword with 'const'.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW',
  );

  ///  No parameters.
  static const HintCode NULL_CHECK_ALWAYS_FAILS = HintCode(
    'NULL_CHECK_ALWAYS_FAILS',
    "This null-check will always throw an exception because the expression "
        "will always evaluate to 'null'.",
    hasPublishedDocs: true,
  );

  ///  When "strict-raw-types" is enabled, "raw types" must have type arguments.
  ///
  ///  A "raw type" is a type name that does not use inference to fill in missing
  ///  type arguments; instead, each type argument is instantiated to its bound.
  ///
  ///  Parameters:
  ///  0: the name of the generic type
  static const HintCode STRICT_RAW_TYPE = HintCode(
    'STRICT_RAW_TYPE',
    "The generic type '{0}' should have explicit type arguments but doesn't.",
    correctionMessage: "Use explicit type arguments for '{0}'.",
  );

  ///  Parameters:
  ///  0: the name of the non-diagnostic being ignored
  static const HintCode UNIGNORABLE_IGNORE = HintCode(
    'UNIGNORABLE_IGNORE',
    "The diagnostic '{0}' can't be ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if "
        "this is the only name in the list.",
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_CAST = HintCode(
    'UNNECESSARY_CAST',
    "Unnecessary cast.",
    correctionMessage: "Try removing the cast.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_FINAL = HintCode(
    'UNNECESSARY_FINAL',
    "The keyword 'final' isn't necessary because the parameter is implicitly "
        "'final'.",
    correctionMessage: "Try removing the 'final'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the diagnostic being ignored
  static const HintCode UNNECESSARY_IGNORE = HintCode(
    'UNNECESSARY_IGNORE',
    "The diagnostic '{0}' isn't produced at this location so it doesn't need "
        "to be ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if "
        "this is the only name in the list.",
  );

  ///  Parameters:
  ///  0: the URI that is not necessary
  ///  1: the URI that makes it unnecessary
  static const HintCode UNNECESSARY_IMPORT = HintCode(
    'UNNECESSARY_IMPORT',
    "The import of '{0}' is unnecessary because all of the used elements are "
        "also provided by the import of '{1}'.",
    correctionMessage: "Try removing the import directive.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_NULL_COMPARISON_FALSE = HintCode(
    'UNNECESSARY_NULL_COMPARISON',
    "The operand can't be null, so the condition is always 'false'.",
    correctionMessage:
        "Try removing the condition, an enclosing condition, or the whole "
        "conditional statement.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_NULL_COMPARISON_FALSE',
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_NULL_COMPARISON_TRUE = HintCode(
    'UNNECESSARY_NULL_COMPARISON',
    "The operand can't be null, so the condition is always 'true'.",
    correctionMessage: "Remove the condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_NULL_COMPARISON_TRUE',
  );

  ///  Parameters:
  ///  0: the name of the type
  static const HintCode UNNECESSARY_QUESTION_MARK = HintCode(
    'UNNECESSARY_QUESTION_MARK',
    "The '?' is unnecessary because '{0}' is nullable without it.",
    hasPublishedDocs: true,
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_SET_LITERAL = HintCode(
    'UNNECESSARY_SET_LITERAL',
    "Braces unnecessarily wrap this expression in a set literal.",
    correctionMessage: "Try removing the set literal around the expression.",
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_TYPE_CHECK_FALSE = HintCode(
    'UNNECESSARY_TYPE_CHECK',
    "Unnecessary type check; the result is always 'false'.",
    correctionMessage:
        "Try correcting the type check, or removing the type check.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_TYPE_CHECK_FALSE',
  );

  ///  No parameters.
  static const HintCode UNNECESSARY_TYPE_CHECK_TRUE = HintCode(
    'UNNECESSARY_TYPE_CHECK',
    "Unnecessary type check; the result is always 'true'.",
    correctionMessage:
        "Try correcting the type check, or removing the type check.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_TYPE_CHECK_TRUE',
  );

  ///  No parameters.
  static const HintCode UNREACHABLE_SWITCH_CASE = HintCode(
    'UNREACHABLE_SWITCH_CASE',
    "This case is covered by the previous cases.",
  );

  ///  Parameters:
  ///  0: the name that is declared but not referenced
  static const HintCode UNUSED_ELEMENT = HintCode(
    'UNUSED_ELEMENT',
    "The declaration '{0}' isn't referenced.",
    correctionMessage: "Try removing the declaration of '{0}'.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the parameter that is declared but not used
  static const HintCode UNUSED_ELEMENT_PARAMETER = HintCode(
    'UNUSED_ELEMENT',
    "A value for optional parameter '{0}' isn't ever given.",
    correctionMessage: "Try removing the unused parameter.",
    hasPublishedDocs: true,
    uniqueName: 'UNUSED_ELEMENT_PARAMETER',
  );

  ///  Parameters:
  ///  0: the name of the unused field
  static const HintCode UNUSED_FIELD = HintCode(
    'UNUSED_FIELD',
    "The value of the field '{0}' isn't used.",
    correctionMessage: "Try removing the field, or using it.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the content of the unused import's URI
  static const HintCode UNUSED_IMPORT = HintCode(
    'UNUSED_IMPORT',
    "Unused import: '{0}'.",
    correctionMessage: "Try removing the import directive.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the unused variable
  static const HintCode UNUSED_LOCAL_VARIABLE = HintCode(
    'UNUSED_LOCAL_VARIABLE',
    "The value of the local variable '{0}' isn't used.",
    correctionMessage: "Try removing the variable or using it.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name that is shown but not used
  static const HintCode UNUSED_SHOWN_NAME = HintCode(
    'UNUSED_SHOWN_NAME',
    "The name {0} is shown, but isn't used.",
    correctionMessage: "Try removing the name from the list of shown members.",
    hasPublishedDocs: true,
  );

  /// Initialize a newly created error code to have the given [name].
  const HintCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'HintCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorType.HINT.severity;

  @override
  ErrorType get type => ErrorType.HINT;
}
