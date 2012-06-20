// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Emittes a dart code for a compiled template. */
class TemplateEmitter {
  
  TemplateEmitter() {
    
  }
  
  /** Emits start of class template with given name */
  String emitStartClass(String className) {
    return """
            class $className extends EDTemplate {

              String render(Map data, OutputStream out) {
           """;  
  }
  
  String emitTemplateFragment(TemplateFragment fragment) {
    return "out.writeString(\"${fragment.text}\");\n";      
  }
  
  String emitCodeFragment(CodeFragment fragment) {
    return null;
  }
  
  String emitEscapedOutputFragment(EscapedOutputFragment fragment) {
    return null;
  }
  
  String emitUnescapedOutputFragment(UnescapedOutputFragment fragment) {
    return null;
  }
  
  /** Emits end of class template */
  String emitEndClass() {
    return """
              }
            }
           """;
  }
  
}

/** todo zhugrov a - decide if we ever need this class */
class Namer {
  String className(String template) {
    
  }  
}