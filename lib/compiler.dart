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
