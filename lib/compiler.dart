// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
/** compiles and read templates */
class Compiler {
  /** A base template parser implementation */
  final Parser parser = new Parser();
  /** A base emitter implementation */
  final TemplateEmitter emitter = new TemplateEmitter();
    
  /** Dir for compile output */
  String _outDirectory;
  /** An template to compile */
  String _templateFile;
  /** A working directory */
  String _cwd;
  
  /** 
   * As dart does not support metaprogramming 
   * we should precompile templates for now 
   */
  Compiler(Options options) {
    var argsParser = new ArgParser();
    //path to template
    //path to output directory
    argsParser.addOption("file");
    argsParser.addOption("out");
    var cmd = argsParser.parse(options.arguments);
    _outDirectory = cmd["out"];
    _templateFile = cmd["file"];
    _cwd = getCurrentDirectory();
  }
  
  /** Compile a given template to output directory */
  void compile() {
    var buf = new StringBuffer();
    _processTemplate(pathJoin([_cwd, _templateFile]));
    _writeTemplate(uri, text);
  }
  
  void _processTemplate(String templatePath) {
    String templateSrc = _readTemplate(templatePath);
    List<Fragment> ast = parser.parse(templateSrc); //yes, this is not a tree in common sence
    
  }
  
  //TODO(zhuhrou) - decide if we need this method
  void _processInclude(String include) {
    
  }
  
  /** 
   * Reads file and returns its content. 
   * Yes we don't support async api at the moment 
   */
  String _readTemplate(String templatePath) {
    return new File(templatePath).readAsTextSync(Encoding.UTF_8);    
  }
  
  /** Writes compiled template to a file */
  void _writeTemplate(String templatePath, String text) {
    var file = new File(templatePath).openSync(FileMode.WRITE);
    file.writeStringSync(text, Encoding.UTF_8);
    file.closeSync();
  }
  
}