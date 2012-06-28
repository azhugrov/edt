// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("desntech:scanner-test");
#import("../Lib.dart");
//yes, it sucks. you need define your path in order to run this test
#import("../../dart/dart-sdk/lib/unittest/unittest.dart");

void main() {
  test("simple case", () {
    var unparsedText = ['{{~ layout.edt }}\n',
                        'This is a simple but unparsed text \n',
                       'which we would use {{>a include content}}\n',
                       '{{code fragment}} this should not {{=expression}} affect\n',
                       'what we do here {{- do you understand me}}\n',
                       'and finally this is our last line'];
    var scanner = new Scanner(unparsedText);
    var tokens = scanner.tokenize();
    printTokens(tokens);
    expect(tokens.length, equals(20));               
  });  
}

void printTokens(List<Token> tokens) {
  expect(tokens, isNotNull);
  for (var token in tokens) {
    print("token: $token");    
  }
}
