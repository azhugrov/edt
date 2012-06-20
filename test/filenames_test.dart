// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#library("desntech:filenames-test");
#import("../lib/filenames.dart");
//yes, it sucks. you need define your path in order to run this test
#import("../../side-projects/dart/dart-sdk/lib/unittest/unittest.dart");

void main() {
  test("check normalize", () {
    var result = pathNormalize("C:\\foo\\bar\\\\baz\\..\\asdf\\quux\\.\\");
    expect(result, equals(@"C:\foo\bar\asdf\quux\"));
  });
  test("check join", () {
    var result = pathJoin(['/foo', 'bar', 'baz/asdf', 'quux', '..']);
    print(result);
  });
}