// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
/** Compiles templates to a dart class */
class Compiler {
  /** A base emitter implementation */
  TemplateEmitter emitter;
    
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
    emitter = new TemplateEmitter();
    var argsParser = new ArgParser();
    //path to template
    //path to output directory
    argsParser.addOption("file");
    argsParser.addOption("out");
    var cmd = argsParser.parse(options.arguments);
    _outDirectory = cmd["out"];
    print("out: $_outDirectory");
    _templateFile = cmd["file"];
    print("file: $_templateFile");
    _cwd = getCurrentDirectory();
    if (_outDirectory == null) {
      throw new Exception("out dir should be provided");      
    }
    if (_templateFile == null) {
      throw new Exception("template file should be provided");      
    }
  }
  
  /** Compile a given template to output directory */
  void compile() {
    var buf = new StringBuffer();
    buf.add(emitter.emitStartClass(_toClassName(_templateFile)));
    _processTemplate(pathJoin([_cwd, _templateFile]), buf);
    buf.add(emitter.emitEndClass());
    var outputFile = pathJoin([_cwd, _outDirectory, "${pathBasename(_templateFile, ".edt")}.dart"]);
    _writeTemplate(outputFile, buf.toString());
  }
  
  void _processTemplate(String templatePath, StringBuffer buf) {
    String templateSrc = _readTemplate(templatePath);
    List<Fragment> ast;
    try {
      ast = new Parser().parse(templateSrc);
    } catch(ParseException e) {
      print("could not parse: $templatePath");
      throw e;
    }
    Iterator<Fragment> astIterator = ast.iterator();
    while (astIterator.hasNext()) {
      Fragment fragment = astIterator.next();
      if (fragment is TemplateFragment) {
        buf.add(emitter.emitTemplateFragment(fragment));        
      }
      else if (fragment is CodeFragment) {
        buf.add(emitter.emitCodeFragment(fragment));        
      }
      else if (fragment is EscapedOutputFragment) {
        buf.add(emitter.emitEscapedOutputFragment(fragment));        
      }
      else if (fragment is UnescapedOutputFragment) {
        buf.add(emitter.emitUnescapedOutputFragment(fragment));        
      }
      else if (fragment is IncludeFragment) {
        _processTemplate(pathJoin([_cwd, pathDirname(_templateFile), fragment.include.trim()]), buf);        
      }
    }        
  }
  
  /** Transform to a template class name */
  String _toClassName(String templatePath) {
    return templatePath.replaceAll(const RegExp(@"[\\/\.]+"), "_");
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