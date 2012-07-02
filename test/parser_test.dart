// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("desntech:parser-test");
#import("../Lib.dart");
//yes, it sucks. you need define your path in order to run this test
#import("../../dart/dart-sdk/lib/unittest/unittest.dart");

void main() {
  test("simple case", () {
    var unparsedText =  'This is a simple but unparsed text \n'
                        'which we would use {{>a include content}}\n'
                        '{{code fragment}} this should not {{=expression}} affect\n'
                        'what we do here {{- do you understand me}}\n'
                        'and finally this is our last line';
    var parser = new Parser();
    TemlateNode ast = parser.parse(unparsedText, false, false);
    expect(ast.length, equals(9));    
  });  
}

void printFragments(List<Node> fragments) {
  expect(fragments, isNotNull);
  print("we here");
  for (var fragment in fragments) {
    print("fragment: $fragment");    
  }
}