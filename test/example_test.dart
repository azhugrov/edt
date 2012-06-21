// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("desntech:template-test");
#import("dart:io");
#import("../RuntimeLib.dart");
//yes, it sucks. you need define your path in order to run this test
#import("../../side-projects/dart/dart-sdk/lib/unittest/unittest.dart");


void main() {
  test("simple case", () {
    var data = {
      "one":    "one value",
      "second": "second value",
      "third":  "third value",
      "forth":  "forth value"
    };
    
  });  
}

