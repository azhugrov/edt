// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("desntech:edt:cmd");
#import("Lib.dart");

void main() {
  var compiler = new Compiler(new Options());
  compiler.compile(); 
}