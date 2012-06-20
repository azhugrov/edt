// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** A scanner interface */
interface Scanner default ScannerImpl {
  /** a base contructor */
  Scanner(List<String> lines);
  /** parses into a stream of tokens */
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
      var line = _lines[lineNumber - 1];
      var buf = new Queue<String>();
      var i = 0;
      var lineEOF = false; //this flag is used to indicate that we consumed the end of line
      while (!lineEOF) {
        //this also included the condition when we approach the end of line
        if (buf.length < 3 && i < line.length) {
          //acumulate for analysis
          buf.add(line.substring(i, i + 1));
          i++;
        } else {
          //ready for analysis
          String token = _concatAll(buf);
          if (token.startsWith(Tokens.OPEN_INCLUDE)) {
            if (!textTokenBuf.isEmpty()) {
              tokens.add(new TextToken(textTokenBuf.toString(), lineNumber));
              textTokenBuf.clear();
            }
            tokens.add(new OpenIncludeToken(lineNumber));
            buf.clear();
          } 
          else if (token.startsWith(Tokens.OPEN_EXPRESSION)) {
            if (!textTokenBuf.isEmpty()) {
              tokens.add(new TextToken(textTokenBuf.toString(), lineNumber));
              textTokenBuf.clear();
            }
            tokens.add(new OpenExpressionToken(lineNumber));
            buf.clear();
          }
          else if (token.startsWith(Tokens.OPEN_UNESCAPED_EXPRESSION)) {
            if (!textTokenBuf.isEmpty()) {
              tokens.add(new TextToken(textTokenBuf.toString(), lineNumber));
              textTokenBuf.clear();
            }
            tokens.add(new OpenUnescapedExpressionToken(lineNumber));
            buf.clear();            
          }          
          else if (token.startsWith(Tokens.OPEN_CODE)) {
            if (!textTokenBuf.isEmpty()) {
              tokens.add(new TextToken(textTokenBuf.toString(), lineNumber));
              textTokenBuf.clear();
            }
            tokens.add(new OpenCodeToken(lineNumber));
            buf.removeFirst();
            buf.removeFirst();           
          }
          else if (token.startsWith(Tokens.CLOSE)) {
            if (!textTokenBuf.isEmpty()) {
              tokens.add(new TextToken(textTokenBuf.toString(), lineNumber));
              textTokenBuf.clear();
            }
            tokens.add(new CloseToken(lineNumber));
            buf.removeFirst();
            buf.removeFirst();
          }
          else {
            //the buffer input does not correspond any predefined term
            //may be empty if we parse an empty line
            if (!buf.isEmpty()) textTokenBuf.add(buf.removeFirst());              
          }
          
          if (i == line.length) {
            lineEOF = true; //processed last entry            
          }
        }          
      }
      //add remained unprocessed string
      textTokenBuf.add(_concatAll(buf));
    }
    
    if (!textTokenBuf.isEmpty()) {
      tokens.add(new TextToken(textTokenBuf.toString(), _lines.length));  
    }
    
    return tokens;
  }
  
  String _concatAll(Queue<String> buf) {
    StringBuffer result = new StringBuffer();
    buf.forEach((String char) {
      result.add(char);
    });    
    return result.toString();   
  }
  
    
}

/** A list of predefined tokens */
class Tokens {
  static final String OPEN_INCLUDE = "{{>";
  static final String OPEN_CODE = "{{";
  static final String OPEN_EXPRESSION = "{{=";
  static final String OPEN_UNESCAPED_EXPRESSION = "{{-";
  static final String CLOSE = "}}";
}

abstract class Token {
  /** Line where token is placed */
  final int _line;
  
  Token(this._line);
  
  int get line() => _line;
  
}

class OpenIncludeToken extends Token {
  
  OpenIncludeToken(int line): super(line);
  
  String toString() {
    return "OpenIncludeToken[line=${line}]";
  }
  
}

class OpenCodeToken extends Token {
  
  OpenCodeToken(int line): super(line);
  
  String toString() {
    return "OpenCodeToken[line=${line}]";
  }
  
}

class OpenExpressionToken extends Token {
  
  OpenExpressionToken(int line): super(line);
  
  String toString() {
    return "OpenExpressionToken[line=${line}]";
  }
  
}

class OpenUnescapedExpressionToken extends Token {
  
  OpenUnescapedExpressionToken(int line): super(line);
  
  String toString() {
    return "OpenUnescapedExpressionToken[line=${line}]";
  }
  
}

class CloseToken extends Token {
  
  CloseToken(int line): super(line);
  
  String toString() {
    return "CloseToken[line=${line}]";
  }
  
}

class TextToken extends Token {
  /** the content of a given token */
  String _content;
  
  TextToken(this._content, int line): super(line);
  /** gets a content of a given token */
  String get content() => _content;
  
  String toString() {
    return "TextToken[line=${line};content=${content}]";  
  }
  
}