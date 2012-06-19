// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
/** compiles and read templates */
class Compiler {
  
  String _outDirectory;
  
  String _templateFile;
  
  /** 
   * As dart does not support metaprogramming 
   * we should precompile templates for now 
   */
  Compiler(Options options) {
    var argsParser = new ArgParser();
    //path to template
    argsParser.addOption("t");
    //path to output directory
    argsParser.addOption("out");
    var cmd = argsParser.parse(options.arguments);
    _templateFile = cmd["t"];
    _outDirectory = cmd["out"];    
  }
  
  /** Compile a given template to output directory */
  void compile() {
      
  }
  
  /** Reads file and returns its content */
  Future<String> _readTemplate(String templatePath) {
    return (new File(templatePath)).readAsText();    
  }
  
  
}
