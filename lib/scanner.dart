
interface Scanner default ScannerImpl {
  
  Scanner(List<String> lines);
  
  List<Token> tokenize();  
  
}

class ScannerImpl implements Scanner {
  /** A list of lines to scan */
  List<String> _lines;
  
  ScannerImpl(this._lines);
  
  List<Token> tokenize() {
    List<Token> tokens = <Token>[];
    for (var lineNumber = 0; lineNumber < _lines.length; lineNumber++) {
        
    }    
    return tokens;
  }
    
}

class Tokens {
  static final String OPEN_INCLUDE = "{{<";
  static final String OPEN_CODE = "{{";
  static final String OPEN_EXPRESSION = "{{=";
  static final String OPEN_UNESCAPED_EXPRESSION = "{{-";
  static final String CLOSE = "}}";
}

abstract class Token {
  
}

class OpenIncludeToken extends Token {
  
}

class OpenCodeToken extends Token {
  
}

class OpenExpressionToken extends Token {
  
}

class OpenUnescapedExpressionToken extends Token {
  
}

class CloseToken extends Token {
  
}

class TemplateToken extends Token {
  /** the content of a given token */
  String _content;
  
  TemplateToken(this._content);
}