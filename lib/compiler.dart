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
      _compileFile(pathJoin([_cwd, _templateFile]), pathJoin([_cwd, _outDirectory]));      
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
    TemplateNode template = _parseTemplate(templatePath, false, false);
    if (template.hasLayout) {
      var sections = _buildSectionsMap(template);
      String layoutPath = pathJoin([pathDirname(templatePath), template.layout.layoutBase]);
      TemplateNode expandedTemplate = _processLayout(layoutPath, sections);
      _emitTemplate(expandedTemplate, buf);
    }
    else {
      _emitTemplate(template, buf);        
    }        
  }
  
  TemplateNode _parseTemplate(String templatePath, bool isLayout, bool isInclude) {
    String templateSrc = _readTemplate(templatePath);
    TemplateNode template;
    try {
      template = new Parser().parse(templateSrc, isLayout, isInclude);
    } catch(ParseException e) {
      print("could not parse: $templatePath");
      throw e;
    }
    _processIncludes(templatePath, template);
    return template;
  }
  
  Map<String, SectionDefinitionNode> _buildSectionsMap(TemplateNode template) {
    var sectionsMap = <SectionDefinitionNode>{};
    template.forEach((Node node) {
      if (node is SectionDefinitionNode) {
        sectionsMap[node.name] = node;        
      }
    });
    return sectionsMap;
  }  
  
  /** process given layout and expands any reference with concrete definitions */
  TemplateNode _processLayout(String layoutPath, Map<String, SectionDefinitionNode> sections) {
    TemplateNode layout = _parseTemplate(layoutPath, true, false);
    //then we should expact any section reference 
    //with content of corresponding section definition
    layout.expandTree(List<Node> replace(Node node) {
      if (node is SectionReferenceNode) {
        SectionDefinitionNode section = sections[node.name];
        if (section !== null) {
          return section.children;
        } else {
          throw new Exception("Please provide a section definition for following reference: [${section.name}]");
        }        
      } else {
        return null;
      }     
    });
    return layout;
  }
  
  /** Resolves any includes and returns an expanded tree. */
  ContainerNode _processIncludes(String templatePath, ContainerNode container) {
    container.expandTree(List<Node> replacement(node) {
      if (node is SectionDefinitionNode) {
        //process a section definition recursively
        _processIncludes(templatePath, node);
      } 
      else if (node is IncludeNode) {
        String includePath = pathJoin([pathDirname(templatePath), node.include]);
        //Q: should it already apply a transformation recursively?
        TemplateNode include = _parseTemplate(includePath, false, true);
        //then we should replace existing include node with content
        return include.children;
      }
      return null; //return null if we simply doesn't have to expand a given node
    });
    return container;
  }
  
  /** 
   * Should be invocked after:
   * - process include phase
   * - process layout phase 
   */  
  void _emitTemplate(TemplateNode template, StringBuffer buf) {
    Iterator<Node> astIterator = template.iterator();
    while (astIterator.hasNext()) {
      Node node = astIterator.next();
      if (node is TextNode) {
        buf.add(emitter.emitTextFragment(node));        
      }
      else if (node is CodeNode) {
        buf.add(emitter.emitCodeFragment(node));        
      }
      else if (node is EscapedOutputNode) {
        buf.add(emitter.emitEscapedOutputFragment(node));        
      }
      else if (node is UnescapedOutputNode) {
        buf.add(emitter.emitUnescapedOutputFragment(node));        
      }
      else {
        throw new Exception("could not generate code for a following token: $node");
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