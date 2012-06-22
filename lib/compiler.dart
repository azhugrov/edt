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
  /** A source dir to look for templates */
  String _srcDir;
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
    argsParser.addOption("src");
    var cmd = argsParser.parse(options.arguments);
    _outDirectory = cmd["out"];
    _templateFile = cmd["file"];
    _srcDir = cmd["src"];    
    _cwd = getCurrentDirectory();
    if (_outDirectory == null) {
      throw new Exception("out dir should be provided");      
    }
    if (_templateFile == null && _srcDir == null) {
      throw new Exception("either source dir or template file should be provided");      
    }
  }
  
  /** Compile a given template to output directory */
  void compile() {
    if (_templateFile !== null) {
      _compileFile(pathJoin([_cwd, templateFile]), pathJoin([_cwd, _outDirectory]));      
    } 
    else {
      //process dir
      _compileFolder(pathJoin([_cwd, _srcDir]), pathJoin([_cwd, _outDirectory]));
    }
  }
  
  /** 
    * Compiles all files in a given folder 
    * [srcDir] source directory (absolute path)
    * [outDir] corresponding output directory (absolute path)
    */
  void _compileFolder(String srcDir, String outDir) {
    Directory subDir = new Directory(srcDir);
    DirectoryLister dirWalker = subDir.list(false);
    dirWalker.onFile = onFile(String filePath) {
       if (pathExtname(filePath) == ".edt") {
         print("found a template file: $filePath");
         _compileFile(filePath, outDir);
       }
    };
    //Handles other directories
    dirWalker.onDir = onDir(String subDirPath) {
       //check if are given dir exist for output
       String subDirName = pathBasename(subDirPath);
       print("subDirName: $subDirName");
       var outSubDirectory = new Directory(pathJoin([outDir, subDirName]));
       if (!outSubDirectory.existsSync()) {
         print("create an output subdirectory: ${outSubDirectory.path}");
         outSubDirectory.createSync();         
       }
       _compileFolder(subDirPath, outSubDirectory.path);
    }; 
  }
  
  void _compileFile(String templateFile, String outDir) {
    var buf = new StringBuffer();
    buf.add(emitter.emitStartClass(_toClassName(templateFile)));
    _processTemplate(templateFile, buf);      
    buf.add(emitter.emitEndClass());
    String outputFile = pathJoin([outDir, "${pathBasename(templateFile, ".edt")}.dart"]);
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
        String includePath = pathJoin([pathDirname(templatePath), fragment.include.trim()]);          
         _processTemplate(includePath, buf);        
      }
    }        
  }
  
  /** Transform to a template class name */
  String _toClassName(String templatePath) {
    return templatePath.replaceAll(const RegExp(@"[\\/\.:]+"), "_");
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
  
  /** We assume that srcFile is localed inside of srcDir */
  String _relativeSourcePath(String srcDir, String srcFile) {
    bool isWindows = Platform.operatingSystem == 'windows';
    if (isWindows) {
      String normalizedDir = pathNormalize(srcDir);
      String normalizedFile = pathNormalize(srcFile);
      if (!normalizedFile.startsWith(normalizedDir)) {
        throw new IllegalArgumentException("srcDir=$srcDir;srcFile=$srcFile");  
      }
      return pathDirname(normalizedFile.substring(normalizedDir.length));
    }
    else {
      throw new Exception("Not supported on this operational system: ${Platform.operatingSystem}");
    }
  }
}