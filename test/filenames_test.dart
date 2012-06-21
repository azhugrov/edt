// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#library("desntech:filenames-test");
#import("dart:io");
#import("../lib/filenames.dart");
//yes, it sucks. you need define your path in order to run this test
#import("../../dart/dart-sdk/lib/unittest/unittest.dart");

void main() {
  bool isWindows = Platform.operatingSystem == 'windows';
  if (isWindows) {
    test("check normalize", () {
      var result = pathNormalize("C:\\foo\\bar\\\\baz\\..\\asdf\\quux\\.\\");
      expect(result, equals(@"C:\foo\bar\asdf\quux\"));
    });
    test("check join", () {
      var result = pathJoin(['/foo', 'bar', 'baz/asdf', 'quux', '..']);
      expect(result, equals(@"\foo\bar\baz\asdf"));
    });
    test("check basename", () {
      var basename = pathBasename("C:\\foo\\bar\\baz\\asd\\quux.html", ".html");
      expect(basename, equals("quux"));
    });
    test("check dirname", () {
      var dirname = pathDirname("C:\\foo\\bar\\baz\\asd\\quux.html");
      expect(dirname, equals("C:\\foo\\bar\\baz\\asd"));
    });
  } 
  else {
    test("check normalize", () {
      var result = pathNormalize("/foo/bar//baz/asdf/quux/..");
      expect(result, equals(@"/foo/bar/baz/asdf"));
    });
    test("check join", () {
      var result = pathJoin(['/foo', 'bar', 'baz/asdf', 'quux', '..']);
      expect(result, equals(@"/foo/bar/baz/asdf"));
    });
    test("check basename", () {
      var basename = pathBasename("/foo/bar/baz/asdf/quux.html", ".html");
      expect(basename, equals("quux"));
    });
  }
}