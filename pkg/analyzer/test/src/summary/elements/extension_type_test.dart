// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../element_text.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeElementTest_keepLinking);
    defineReflectiveTests(ExtensionTypeElementTest_fromBytes);
    defineReflectiveTests(ExtensionTypeElementTest_augmentation_keepLinking);
    defineReflectiveTests(ExtensionTypeElementTest_augmentation_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

mixin ExtensionTypeElementMixin on ElementsBaseTest {
  test_constructor_const() async {
    var library = await buildLibrary(r'''
extension type const A(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @21
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @27
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            const @21
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @27
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @21
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_constructor_named() async {
    var library = await buildLibrary(r'''
extension type A.named(int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          codeOffset: 0
          codeLength: 33
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::named
          typeErasure: int
          fields
            final it @27
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 23
              codeLength: 6
              type: int
          constructors
            named @17
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 16
              codeLength: 14
              periodOffset: 16
              nameEnd: 22
              parameters
                requiredPositional final this.it @27
                  type: int
                  codeOffset: 23
                  codeLength: 6
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_constructor_secondary_fieldFormalParameter() async {
    var library = await buildLibrary(r'''
extension type A(num it) {
  A.named(this.it);
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: num
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: num
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @21
                  type: num
                  field: <testLibraryFragment>::@extensionType::A::@field::it
            named @31
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@extensionType::A
              periodOffset: 30
              nameEnd: 36
              parameters
                requiredPositional final this.it @42
                  type: num
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: num
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_constructor_secondary_fieldFormalParameter_typed() async {
    var library = await buildLibrary(r'''
extension type A(num it) {
  A.named(int this.it);
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: num
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: num
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @21
                  type: num
                  field: <testLibraryFragment>::@extensionType::A::@field::it
            named @31
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@extensionType::A
              periodOffset: 30
              nameEnd: 36
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: num
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_constructor_secondary_fieldInitializer() async {
    var library = await buildLibrary(r'''
extension type A(num it) {
  const A.named(int a) : it = a;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: num
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: num
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @21
                  type: num
                  field: <testLibraryFragment>::@extensionType::A::@field::it
            const named @37
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@extensionType::A
              periodOffset: 36
              nameEnd: 42
              parameters
                requiredPositional a @47
                  type: int
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: it @52
                    staticElement: <testLibraryFragment>::@extensionType::A::@field::it
                    staticType: null
                  equals: = @55
                  expression: SimpleIdentifier
                    token: a @57
                    staticElement: <testLibraryFragment>::@extensionType::A::@constructor::named::@parameter::a
                    staticType: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: num
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_constructor_unnamed() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          codeOffset: 0
          codeLength: 27
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 17
              codeLength: 6
              type: int
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 16
              codeLength: 8
              parameters
                requiredPositional final this.it @21
                  type: int
                  codeOffset: 17
                  codeLength: 6
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_documentation() async {
    var library = await buildLibrary(r'''
/// Docs
extension type A(int it) {
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @24
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          documentationComment: /// Docs
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @30
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @24
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @30
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @24
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_field_const_typed() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static const int foo = 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
            static const foo @46
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              constantInitializer
                IntegerLiteral
                  literal: 0 @52
                  staticType: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_field_const_untyped() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static const foo = 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
            static const foo @42
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @48
                  staticType: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_field_instance_untyped() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  final foo = 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
            final foo @35
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: false
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
            synthetic get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_field_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 0;
''');

    var library = await buildLibrary(r'''
import 'a.dart';
extension type A(@foo int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      extensionTypes
        A @32
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @43
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              metadata
                Annotation
                  atSign: @ @34
                  name: SimpleIdentifier
                    token: foo @35
                    staticElement: package:test/a.dart::<fragment>::@getter::foo
                    staticType: null
                  element: package:test/a.dart::<fragment>::@getter::foo
              type: int
          constructors
            @32
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @43
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      extensionTypes
        extension type A @32
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_getter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo => 0;
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
            synthetic foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
            get foo @37
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_interfaces_class() async {
    var library = await buildLibrary(r'''
class A {}
class B {}
class C implements A, B {}
extension type X(C it) implements A, B {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
        class B @17
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
        class C @28
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          interfaces
            A
            B
      extensionTypes
        X @64
          reference: <testLibraryFragment>::@extensionType::X
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::X::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::X::@constructor::new
          typeErasure: C
          interfaces
            A
            B
          fields
            final it @68
              reference: <testLibraryFragment>::@extensionType::X::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              type: C
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::X::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              returnType: C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
        class B @17
          reference: <testLibraryFragment>::@class::B
        class C @28
          reference: <testLibraryFragment>::@class::C
      extensionTypes
        extension type X @64
          reference: <testLibraryFragment>::@extensionType::X
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
''');
  }

  test_interfaces_cycle2() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements B {}
extension type B(int it) implements A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        hasImplementsSelfReference A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            Object
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
        hasImplementsSelfReference B @56
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int
          interfaces
            Object
          fields
            final it @62
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
        extension type B @56
          reference: <testLibraryFragment>::@extensionType::B
''');
  }

  test_interfaces_cycle_self() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        hasImplementsSelfReference A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            Object
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_interfaces_extensionType() async {
    var library = await buildLibrary(r'''
extension type A(num it) {}
extension type B(int it) implements A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: num
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: num
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: num
        B @43
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int
          interfaces
            A
          fields
            final it @49
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
        extension type B @43
          reference: <testLibraryFragment>::@extensionType::B
''');
  }

  test_interfaces_futureOr() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements num, FutureOr<int> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            num
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_interfaces_implicitObjectQuestion() async {
    var library = await buildLibrary(r'''
extension type X(int? it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        X @15
          reference: <testLibraryFragment>::@extensionType::X
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::X::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::X::@constructor::new
          typeErasure: int?
          fields
            final it @22
              reference: <testLibraryFragment>::@extensionType::X::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              type: int?
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::X::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              returnType: int?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type X @15
          reference: <testLibraryFragment>::@extensionType::X
''');
  }

  test_interfaces_implicitObjectQuestion_fromTypeParameter() async {
    var library = await buildLibrary(r'''
extension type A<T>(T it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @17
              defaultType: dynamic
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: T
          fields
            final it @22
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: T
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_interfaces_void() async {
    var library = await buildLibrary(r'''
typedef A = void;
extension type X(int it) implements A, num {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        X @33
          reference: <testLibraryFragment>::@extensionType::X
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::X::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::X::@constructor::new
          typeErasure: int
          interfaces
            num
          fields
            final it @39
              reference: <testLibraryFragment>::@extensionType::X::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::X::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::X
              returnType: int
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type X @33
          reference: <testLibraryFragment>::@extensionType::X
''');
  }

  test_isPromotable_representationField_private() async {
    var library = await buildLibrary(r'''
extension type A(int? _it) {}

class B {
  int _it = 0;
}

class C {
  int get _it => 0;
}
''');

    configuration
      ..forPromotableFields(extensionTypeNames: {'A'})
      ..withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::_it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int?
          fields
            final promotable _it @22
              reference: <testLibraryFragment>::@extensionType::A::@field::_it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int?
  fieldNameNonPromotabilityInfo
    _it
      conflictingFields
        <testLibraryFragment>::@class::B::@field::_it
      conflictingGetters
        <testLibraryFragment>::@class::C::@getter::_it
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
  classes
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
  fieldNameNonPromotabilityInfo
    _it
      conflictingFields
        <testLibraryFragment>::@class::B::@field::_it
      conflictingGetters
        <testLibraryFragment>::@class::C::@getter::_it
''');
  }

  test_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 0;
''');

    var library = await buildLibrary(r'''
import 'a.dart';
@foo
extension type A(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      extensionTypes
        A @37
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: foo @18
                staticElement: package:test/a.dart::<fragment>::@getter::foo
                staticType: null
              element: package:test/a.dart::<fragment>::@getter::foo
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @43
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @37
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @43
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      extensionTypes
        extension type A @37
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_method() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo(int a) {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @34
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional a @42
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_method_defaultFormalParameter_defaultValue() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo({int a = 0}) {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @34
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                optionalNamed default a @43
                  reference: <testLibraryFragment>::@extensionType::A::@method::foo::@parameter::a
                  type: int
                  constantInitializer
                    IntegerLiteral
                      literal: 0 @47
                      staticType: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_noField() async {
    var library = await buildLibrary(r'''
extension type A() {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          codeOffset: 0
          codeLength: 21
          representation: <testLibraryFragment>::@extensionType::A::@field::<empty>
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: InvalidType
          fields
            final <empty> @17
              reference: <testLibraryFragment>::@extensionType::A::@field::<empty>
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 17
              codeLength: 0
              type: InvalidType
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              codeOffset: 16
              codeLength: 2
              parameters
                requiredPositional final this.<empty> @17
                  type: InvalidType
                  codeOffset: 17
                  codeLength: 0
                  field: <testLibraryFragment>::@extensionType::A::@field::<empty>
          accessors
            synthetic get <empty> @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::<empty>
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_notSimplyBounded_self() async {
    var library = await buildLibrary(r'''
extension type A<T extends A>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        notSimplyBounded A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @17
              bound: A<dynamic>
              defaultType: dynamic
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @34
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_setter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  set foo(double _) {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
            synthetic foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: double
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
            set foo= @33
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _ @44
                  type: double
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_typeErasure_hasExtension_cycle2_direct() async {
    var library = await buildLibrary(r'''
extension type A(B it) {}

extension type B(A it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        hasRepresentationSelfReference A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: InvalidType
          fields
            final it @19
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: InvalidType
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: InvalidType
        hasRepresentationSelfReference B @42
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: InvalidType
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: InvalidType
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
        extension type B @42
          reference: <testLibraryFragment>::@extensionType::B
''');
  }

  test_typeErasure_hasExtension_cycle2_typeArgument() async {
    var library = await buildLibrary(r'''
extension type A(B it) {}

extension type B(List<B> it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: InvalidType
          fields
            final it @19
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: B
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: B
        hasRepresentationSelfReference B @42
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: InvalidType
          fields
            final it @52
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: InvalidType
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
        extension type B @42
          reference: <testLibraryFragment>::@extensionType::B
''');
  }

  test_typeErasure_hasExtension_cycle_self() async {
    var library = await buildLibrary(r'''
extension type A(A it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        hasRepresentationSelfReference A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: InvalidType
          fields
            final it @19
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: InvalidType
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_typeErasure_hasExtension_functionType() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

extension type B(A Function(A a) it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
        B @44
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int Function(int)
          fields
            final it @62
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: A Function(A)
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: A Function(A)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
        extension type B @44
          reference: <testLibraryFragment>::@extensionType::B
''');
  }

  test_typeErasure_hasExtension_interfaceType() async {
    var library = await buildLibrary(r'''
extension type A<T>(T it) {}

extension type B(A<double> it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @17
              defaultType: dynamic
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: T
          fields
            final it @22
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: T
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: T
        B @45
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: double
          fields
            final it @57
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: A<double>
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: A<double>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
        extension type B @45
          reference: <testLibraryFragment>::@extensionType::B
''');
  }

  test_typeErasure_hasExtension_interfaceType_typeArgument() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

extension type B(List<A> it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
        B @44
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: List<int>
          fields
            final it @54
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: List<A>
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: List<A>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
        extension type B @44
          reference: <testLibraryFragment>::@extensionType::B
''');
  }

  test_typeErasure_notExtension() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }

  test_typeParameters() async {
    var library = await buildLibrary(r'''
extension type A<T extends num, U>(Map<T, U> it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @15
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @17
              bound: num
              defaultType: num
            covariant U @32
              defaultType: dynamic
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: Map<T, U>
          fields
            final it @45
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: Map<T, U>
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @45
                  type: Map<T, U>
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: Map<T, U>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type A @15
          reference: <testLibraryFragment>::@extensionType::A
''');
  }
}

abstract class ExtensionTypeElementTest_augmentation extends ElementsBaseTest {
  test_augmentationTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
augment extension type A(int it) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment extension type A(int it) {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
      augmentationImports
        package:test/b.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
          reference: <testLibrary>::@augmentation::package:test/b.dart
          definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @77
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @49
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
  exportedReferences
    declared <testLibraryFragment>::@extensionType::A
  exportNamespace
    A: <testLibraryFragment>::@extensionType::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @77
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @49
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
  exportedReferences
    declared <testLibraryFragment>::@extensionType::A
  exportNamespace
    A: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmentationTarget_no2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
augment extension type A(int it) {
  void foo1() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment extension type A(int it) {
  void foo2() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
      augmentationImports
        package:test/b.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
          reference: <testLibrary>::@augmentation::package:test/b.dart
          definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @77
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
          typeErasure: int
          fields
            final it @83
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
          constructors
            augment @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional final this.it @83
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
          methods
            foo1 @96
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: void
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it
            methods
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::foo1
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@method::foo2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @49
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          methods
            foo2 @68
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@method::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @77
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @49
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
''');
  }

  test_augmented_constructors_add_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  A.named();
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          constructors
            named @68
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              periodOffset: 67
              nameEnd: 73
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_constructors_add_named_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A<T2>(int it) {
  A.named(T2 a);
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A<T1>(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @42
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @50
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @50
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
              ConstructorMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
                augmentationSubstitution: {T2: T1}
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @54
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          constructors
            named @72
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              periodOffset: 71
              nameEnd: 77
              parameters
                requiredPositional a @81
                  type: T2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_constructors_add_unnamed_hasNamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  A();
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A.named(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::named
          typeErasure: int
          fields
            final it @52
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            named @42
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@extensionType::A
              periodOffset: 41
              nameEnd: 47
              parameters
                requiredPositional final this.it @52
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::new
              <testLibraryFragment>::@extensionType::A::@constructor::named
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          constructors
            @66
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_field_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static int foo = 1;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @65
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            augment static foo @85
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_field_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static int foo = 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @65
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @71
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @90
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @65
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @71
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @85
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @85
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @65
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static int get foo => 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @65
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @71
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @90
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @65
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @71
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment static get foo @89
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @85
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @65
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static set foo(int _) {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @65
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @71
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @90
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @65
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @71
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment static set foo= @85
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _ @93
                  type: int
              returnType: void
              id: setter_1
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@setter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @85
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @65
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static double foo = 1.2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @65
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            augment static foo @88
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: double
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static int foo = 1;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  static int get foo => 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic static foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            static get foo @69
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            augment static foo @85
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_fields_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  static int foo2 = 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  static int foo1 = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo1 @65
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo1= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo1 @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo1
              <testLibraryFragment>::@extensionType::A::@setter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            static foo2 @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              setter: setter_1
          accessors
            synthetic static get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_2
            synthetic static set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _foo2 @-1
                  type: int
              returnType: void
              id: setter_1
              variable: field_2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_getters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  int get foo2 => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  int get foo1 => 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            get foo1 @62
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              id: field_2
              getter: getter_2
          accessors
            get foo2 @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_getters_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A<T2>(int it) {
  T2 get foo2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A<T1>(int it) {
  T1 get foo1;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @42
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @50
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: T1
              id: field_1
              getter: getter_1
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @50
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            abstract get foo1 @65
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: T1
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
                augmentationSubstitution: {T2: T1}
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo1
              PropertyAccessorMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
                augmentationSubstitution: {T2: T1}
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @54
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: T2
              id: field_2
              getter: getter_2
          accessors
            abstract get foo2 @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: T2
              id: getter_2
              variable: field_2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_getters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @65
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment static get foo @89
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_getters_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @65
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @71
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @90
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @65
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @71
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@setter::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment static get foo @89
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          accessors
            augment static get foo @89
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_3
              variable: field_1
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @65
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
''');
  }

  test_augmented_getters_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment int get foo1 => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  int get foo1 => 0;
  int get foo2 => 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo2
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_2
              getter: getter_2
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            get foo1 @62
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
            get foo2 @83
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo2
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              <testLibraryFragment>::@extensionType::A::@field::foo2
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
              <testLibraryFragment>::@extensionType::A::@getter::foo2
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment get foo1 @82
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_3
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_getters_augment_getter2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
extension type A(int it) {
  int get foo => 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @65
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @71
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
          constructors
            @65
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @71
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            get foo @87
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment get foo @82
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          accessors
            augment get foo @82
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_3
              variable: field_1
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @65
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
''');
  }

  test_augmented_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) implements I2 {}
extension type I2(int it) {}
''');

    configuration.withConstructors = false;
    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) implements I1 {}
extension type I1(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            I1
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            interfaces
              I1
              I2
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
        I1 @82
          reference: <testLibraryFragment>::@extensionType::I1
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @89
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          interfaces
            I2
        I2 @94
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @101
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
        extension type I1 @82
          reference: <testLibraryFragment>::@extensionType::I1
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
        extension type I2 @94
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
''');
  }

  test_augmented_interfaces_chain() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
augment extension type A(int it) implements I2 {}
extension type I2(int it) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment extension type A(int it) implements I3 {}
extension type I3(int it) {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) implements I1 {}
extension type I1(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
      augmentationImports
        package:test/b.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
          reference: <testLibrary>::@augmentation::package:test/b.dart
          definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            I1
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            interfaces
              I1
              I2
              I3
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
        I1 @82
          reference: <testLibraryFragment>::@extensionType::I1
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @89
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              type: int
          constructors
            @82
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              parameters
                requiredPositional final this.it @89
                  type: int
                  field: <testLibraryFragment>::@extensionType::I1::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @77
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          interfaces
            I2
        I2 @119
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @126
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          constructors
            @119
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              parameters
                requiredPositional final this.it @126
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              returnType: int
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @49
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          interfaces
            I3
        I3 @91
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          representation: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new
          typeErasure: int
          fields
            final it @98
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
              type: int
          constructors
            @91
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
              parameters
                requiredPositional final this.it @98
                  type: int
                  field: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
        extension type I1 @82
          reference: <testLibraryFragment>::@extensionType::I1
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @77
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
        extension type I2 @119
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @49
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
        extension type I3 @91
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
''');
  }

  test_augmented_interfaces_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A<T2>(int it) implements I2<T2> {}
extension type I2<E>(int it) {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A<T>(int it) implements I1 {}
extension type I1(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @42
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            I1
          fields
            final it @49
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @49
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            interfaces
              I1
              I2<T>
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
        I1 @85
          reference: <testLibraryFragment>::@extensionType::I1
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @92
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              type: int
          constructors
            @85
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              parameters
                requiredPositional final this.it @92
                  type: int
                  field: <testLibraryFragment>::@extensionType::I1::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @54
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          interfaces
            I2<T2>
        I2 @102
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @105
              defaultType: dynamic
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @112
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          constructors
            @102
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              parameters
                requiredPositional final this.it @112
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
        extension type I1 @85
          reference: <testLibraryFragment>::@extensionType::I1
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
        extension type I2 @102
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
''');
  }

  test_augmented_interfaces_generic_mismatch() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A<T2, T3>(int it) implements I2<T2> {}
extension type I2<E>(int it) {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A<T>(int it) implements I1 {}
extension type I1(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @42
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            I1
          fields
            final it @49
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @49
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            interfaces
              I1
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
        I1 @85
          reference: <testLibraryFragment>::@extensionType::I1
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @92
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              type: int
          constructors
            @85
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              parameters
                requiredPositional final this.it @92
                  type: int
                  field: <testLibraryFragment>::@extensionType::I1::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @54
              defaultType: dynamic
            covariant T3 @58
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          interfaces
            I2<T2>
        I2 @106
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @109
              defaultType: dynamic
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @116
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          constructors
            @106
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              parameters
                requiredPositional final this.it @116
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
        extension type I1 @85
          reference: <testLibraryFragment>::@extensionType::I1
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
        extension type I2 @106
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
''');
  }

  test_augmented_methods() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  void bar() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @59
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              <testLibraryFragment>::@extensionType::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            bar @71
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_methods_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment void foo1() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  void foo1() {}
  void foo2() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo1 @59
              reference: <testLibraryFragment>::@extensionType::A::@method::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
            foo2 @76
              reference: <testLibraryFragment>::@extensionType::A::@method::foo2
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
              <testLibraryFragment>::@extensionType::A::@method::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            augment foo1 @79
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@method::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_methods_augment2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
augment extension type A(int it) {
  augment void foo() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment extension type A(int it) {
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
      augmentationImports
        package:test/b.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
          reference: <testLibrary>::@augmentation::package:test/b.dart
          definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @59
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @77
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          methods
            augment foo @104
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @49
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          methods
            augment foo @76
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              returnType: void
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @77
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @49
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
''');
  }

  test_augmented_methods_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A<T2>(int it) {
  T2 bar() => throw 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A<T>(int it) {
  T foo() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @42
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @49
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @49
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @59
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: T
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
                augmentationSubstitution: {T2: T}
              <testLibraryFragment>::@extensionType::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @54
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            bar @73
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: T2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_methods_generic_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A<T2>(int it) {
  augment T2 foo() => throw 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A<T>(int it) {
  T foo() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @42
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @49
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @49
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @59
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: T
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
                augmentationSubstitution: {T2: T}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @54
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            augment foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: T2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_methods_typeParameterCountMismatch() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A<T>(int it) {
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  void foo() {}
  void bar() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @59
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
            bar @75
              reference: <testLibraryFragment>::@extensionType::A::@method::bar
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: void
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
            methods
              <testLibraryFragment>::@extensionType::A::@method::bar
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
                augmentationSubstitution: {T: InvalidType}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @54
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            augment foo @82
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_setters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  set foo2(int _) {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  set foo1(int _) {}
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              setter: setter_0
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            set foo1= @58
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _ @67
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@setter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              id: field_2
              setter: setter_1
          accessors
            set foo2= @70
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _ @79
                  type: int
              returnType: void
              id: setter_1
              variable: field_2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_setters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment static set foo(int _) {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  static int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @65
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment static set foo= @85
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _ @93
                  type: int
              returnType: void
              id: setter_1
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmented_setters_augment_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment extension type A(int it) {
  augment set foo1(int _) {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
extension type A(int it) {
  set foo1(int _) {}
  set foo2(int _) {}
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @40
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @46
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              setter: setter_0
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo2
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_2
              setter: setter_1
          constructors
            @40
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final this.it @46
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            set foo1= @58
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _ @67
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
            set foo2= @79
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo2
              enclosingElement: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _ @88
                  type: int
              returnType: void
              id: setter_1
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              <testLibraryFragment>::@extensionType::A::@field::foo2
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
              <testLibraryFragment>::@extensionType::A::@setter::foo2
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment set foo1= @78
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _ @87
                  type: int
              returnType: void
              id: setter_2
              variable: field_1
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@setter::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @40
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
''');
  }

  test_augmentedBy_class2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';

augment class A {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';

extension type A(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @66
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @72
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@extensionType::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTargetAny: <testLibraryFragment>::@extensionType::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @66
          reference: <testLibraryFragment>::@extensionType::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    class A
      reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
''');
  }

  test_augmentedBy_class_extensionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';

augment extension type A(int it) {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';

extension type A(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensionTypes
        A @66
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @72
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@extensionType::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @53
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @66
          reference: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @53
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          previousFragment: <testLibraryFragment>::@extensionType::A
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
''');
  }
}

@reflectiveTest
class ExtensionTypeElementTest_augmentation_fromBytes
    extends ExtensionTypeElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class ExtensionTypeElementTest_augmentation_keepLinking
    extends ExtensionTypeElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => true;
}

@reflectiveTest
class ExtensionTypeElementTest_fromBytes extends ElementsBaseTest
    with ExtensionTypeElementMixin {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class ExtensionTypeElementTest_keepLinking extends ElementsBaseTest
    with ExtensionTypeElementMixin {
  @override
  bool get keepLinkingLibraries => true;
}

// TODO(scheglov): This is duplicate.
extension on ElementTextConfiguration {
  void forPromotableFields({
    Set<String> classNames = const {},
    Set<String> enumNames = const {},
    Set<String> extensionTypeNames = const {},
    Set<String> mixinNames = const {},
    Set<String> fieldNames = const {},
  }) {
    filter = (e) {
      if (e is ClassElement) {
        return classNames.contains(e.name);
      } else if (e is ConstructorElement) {
        return false;
      } else if (e is EnumElement) {
        return enumNames.contains(e.name);
      } else if (e is ExtensionTypeElement) {
        return extensionTypeNames.contains(e.name);
      } else if (e is FieldElement) {
        return fieldNames.isEmpty || fieldNames.contains(e.name);
      } else if (e is MixinElement) {
        return mixinNames.contains(e.name);
      } else if (e is PartElement) {
        return false;
      } else if (e is PropertyAccessorElement) {
        return false;
      }
      return true;
    };
  }
}
