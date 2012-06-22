// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("desntech:template-test");
#import("dart:io");
#import("../RuntimeLib.dart");
//yes, it sucks. you need define your path in order to run this test
#import("../../dart/dart-sdk/lib/unittest/unittest.dart");
#source("example.dart");

void main() {
  test("simple case", () {
    var data = {
      "one":    "one value",
      "second": "second value",
      "third":  "third value",
      "forth":  "forth value",
      "condition": true
    };
    var out = new StringOutputStream();
    var template = new test_example_edt();
    template.render(data, out);
    print(out.toString());    
  });  
}

/** Mock implementation for tests */
class StringOutputStream implements OutputStream {
  
  StringBuffer _buf;
  
  StringOutputStream() {
    _buf = new StringBuffer();
  }
  
  bool write(List<int> buffer, [bool copyBuffer]) {
    throw new UnsupportedOperationException("Not Implemented");
  }

  bool writeFrom(List<int> buffer, [int offset, int len]) {
    throw new UnsupportedOperationException("Not Implemented");
  }

  bool writeString(String string, [Encoding encoding]) {
    _buf.add(string);
  }

  void flush() {}

  void close() {}

  void destroy() {
    throw new UnsupportedOperationException("Not Implemented");
  }

  void set onNoPendingWrites(void callback()) {
    throw new UnsupportedOperationException("Not Implemented");
  }

  void set onClosed(void callback()) {
    throw new UnsupportedOperationException("Not Implemented");
  }

  void set onError(void callback(e)) {
    throw new UnsupportedOperationException("Not Implemented");
  }
  
  String toString() {
    return _buf.toString();
  }  
}