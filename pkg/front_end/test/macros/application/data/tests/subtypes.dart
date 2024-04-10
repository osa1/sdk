// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Declarations Order:
 topLevelFunction1:FunctionDeclarationsMacro2.new()
 topLevelFunction2:FunctionDeclarationsMacro2.new()
 topLevelFunction3:FunctionDeclarationsMacro2.new()
 topLevelFunction4:FunctionDeclarationsMacro2.new()
Definition Order:
 topLevelFunction1:FunctionDefinitionMacro2.new()
 topLevelFunction2:FunctionDefinitionMacro2.new()
 topLevelFunction3:FunctionDefinitionMacro2.new()
 topLevelFunction4:FunctionDefinitionMacro2.new()
Definitions:
augment library 'org-dartlang-test:///a/b/c/main.dart';

import 'org-dartlang-test:///a/b/c/main.dart' as prefix0;

augment prefix0.A topLevelFunction1(prefix0.A a, ) {
  print('isExactly=true');
  print('isSubtype=true');
  throw 42;
}
augment prefix0.B2 topLevelFunction2(prefix0.B1 a, ) {
  print('isExactly=false');
  print('isSubtype=true');
  throw 42;
}
augment prefix0.C2 topLevelFunction3(prefix0.C1 a, ) {
  print('isExactly=false');
  print('isSubtype=false');
  throw 42;
}
augment prefix0.D2 topLevelFunction4(prefix0.D1 a, ) {
  print('isExactly=false');
  print('isSubtype=false');
  throw 42;
}
*/

import 'package:macro/macro.dart';

class A {}

class B1 {}

class B2 extends B1 {}

class C1 extends C2 {}

class C2 {}

class D1 {}

class D2 {}

/*member: topLevelFunction1:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelFunction1GeneratedMethod_es() {}

definitions:
augment A topLevelFunction1(A a, ) {
  print('isExactly=true');
  print('isSubtype=true');
  throw 42;
}*/
@FunctionDeclarationsMacro2()
@FunctionDefinitionMacro2()
external A topLevelFunction1(A a);

/*member: topLevelFunction2:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelFunction2GeneratedMethod_s() {}

definitions:
augment B2 topLevelFunction2(B1 a, ) {
  print('isExactly=false');
  print('isSubtype=true');
  throw 42;
}*/
@FunctionDeclarationsMacro2()
@FunctionDefinitionMacro2()
external B2 topLevelFunction2(B1 a);

/*member: topLevelFunction3:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelFunction3GeneratedMethod_() {}

definitions:
augment C2 topLevelFunction3(C1 a, ) {
  print('isExactly=false');
  print('isSubtype=false');
  throw 42;
}*/
@FunctionDeclarationsMacro2()
@FunctionDefinitionMacro2()
external C2 topLevelFunction3(C1 a);

/*member: topLevelFunction4:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelFunction4GeneratedMethod_() {}

definitions:
augment D2 topLevelFunction4(D1 a, ) {
  print('isExactly=false');
  print('isSubtype=false');
  throw 42;
}*/
@FunctionDeclarationsMacro2()
@FunctionDefinitionMacro2()
external D2 topLevelFunction4(D1 a);
