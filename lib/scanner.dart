
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
    //note that text token could be multiline
    var textTokenBuf = new StringBuffer();
    for (var lineNumber = 1; lineNumber <= _lines.length; lineNumber++) {
      var line = _lines[lineNumber];
      var buf = new Queue<String>();
      var i = 0;
      while (i < line.length) {
        if (buf.length < 3) {
          //acumulate for analysis
          buf.add(line.substring(i, i + 1));
          i++;
        } else {
          //ready for analysis
          String token = buf.toString();
          if (token.startsWith(Tokens.OPEN_INCLUDE)) {
            tokens.add(new TextToken(textTokenBuf.toString(), lineNumber));
            textTokenBuf.clear();
            tokens.add(new OpenIncludeToken(lineNumber));
            buf.clear();
            i += 3;
          } 
          else if (token.startsWith(Tokens.OPEN_EXPRESSION)) {
            tokens.add(new TextToken(textTokenBuf.toString(), lineNumber));
            textTokenBuf.clear();
            tokens.add(new OpenExpressionToken(lineNumber));
            buf.clear();
            i += 3;
          }
          else if (token.startsWith(Tokens.OPEN_UNESCAPED_EXPRESSION)) {
            tokens.add(new TextToken(textTokenBuf.toString(), lineNumber));
            textTokenBuf.clear();
            tokens.add(new OpenUnescapedExpressionToken(lineNumber));
            buf.clear();
            i += 3;            
          }          
          else if (token.startsWith(Tokens.OPEN_CODE)) {
            tokens.add(new TextToken(textTokenBuf.toString(), lineNumber));
            textTokenBuf.clear();
            tokens.add(new OpenCodeToken(lineNumber));
            buf.removeFirst();
            buf.removeFirst();
            i += 2;           
          }
          else if (token.startsWith(Tokens.CLOSE)) {
            tokens.add(new TextToken(textTokenBuf.toString(), lineNumber));
            textTokenBuf.clear();
            tokens.add(new CloseToken(lineNumber));
            buf.removeFirst();
            buf.removeFirst();
            i += 2;
          }
          else {
            //the buffer input does not correspond any predefined term
            textTokenBuf.add(buf.removeFirst());              
          }
        }          
      }
      //add remained unprocessed string
      textTokenBuf.add(buf.toString());
    }
    
    if (!textTokenBuf.isEmpty()) {
      tokens.add(new TextToken(textTokenBuf.toString(), _lines.length));  
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
  /** Line where token is placed */
  int _line;
  
  Token(this._line);
  
  int get line() => _line;
  
}

class OpenIncludeToken extends Token {
  
  OpenIncludeToken(int line): super(line);
  
}

class OpenCodeToken extends Token {
  
  OpenCodeToken(int line): super(line);
  
}

class OpenExpressionToken extends Token {
  
  OpenExpressionToken(int line): super(line);
  
}

class OpenUnescapedExpressionToken extends Token {
  
  OpenUnescapedExpressionToken(int line): super(line);
  
}

class CloseToken extends Token {
  
  CloseToken(int line): super(line);
  
}

class TextToken extends Token {
  /** the content of a given token */
  String _content;
  
  TextToken(this._content, int line): super(line);
}