// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Parser default ParserImpl {
  
  Parser();
  
  /** Parses a given template text */
  List<Fragment> parse(String src);  
  
}

/** Parses a edt template */
class ParserImpl implements Parser {
  /** The newline char code */
  static final int NEW_LINE_CODE = 10;
  
  /** the current parser state */
  int _state = ParserStates.UNKNOWN;
  
  ParserImpl() {}
  
  List<Fragment> parse(String src) {
    var parsed = <Fragment>[];
    var lines = _toLines(src);
    var scanner = new Scanner(lines);
    return _processTokenStream(scanner.tokenize());   
  }
  
  /** Process a token stream */
  List<Fragment> _processTokenStream(List<Token> tokens) {
    Iterator<Token> tokenIterator = tokens.iterator();
    Queue<Fragment> stack = new Queue<Fragment>();
    while (tokenIterator.hasNext()) {
      Token token = tokenIterator.next();
      switch (_state) {
        case ParserStates.UNKNOWN:
          _processTokenInUnknownState(token, stack);
          break;
        case ParserStates.TEMPLATE:
          _processTokenInTemplateState(token, stack);
          break;
        case ParserStates.INCLUDE:
          _processTokenInIncludeState(token, stack);
          break;
        case ParserStates.CODE:
          _processTokenInCodeState(token, stack);
          break;
        case ParserStates.ESCAPED_EXPRESSION:
          _processTokenInEscapedExpressionState(token, stack);
          break;
        case ParserStates.UNESCAPED_EXPRESSION:
          _processTokenInUnescapedExpressionState(token, stack);
          break;
        default:
          throw new Exception("Illegal state: $_state");
      }
    }
    return _toList(stack);    
  }
  
  void _processTokenInUnknownState(Token token, Queue<Fragment> stack) {
    if (token is TextToken) {
      _state = ParserStates.TEMPLATE;
      stack.add(new TemplateFragment(token.content, token.line));
    }
    else if (token is OpenIncludeToken) {
      _state = ParserStates.INCLUDE;
      stack.add(new IncludeFragment(token.line));
    }
    else if (token is OpenCodeToken) {
      _state = ParserStates.CODE;
      stack.add(new CodeFragment(token.line));      
    }
    else if (token is OpenExpressionToken) {
      _state = ParserStates.ESCAPED_EXPRESSION;
      stack.add(new EscapedOutputFragment(token.line));
    }
    else if (token is OpenUnescapedExpressionToken) {
      _state = ParserStates.UNESCAPED_EXPRESSION;
      stack.add(new UnescapedOutputFragment(token.line));
    }
    else if (token is CloseToken) {
      throw new ParseException(token.line, token);     
    } 
    else {
      throw new IllegalArgumentException(token);
    }
  }
  
  void _processTokenInTemplateState(Token token, Queue<Fragment> stack) {
    if (token is TextToken) {
      throw new ParseException(token.line, token);    
    }
    else if (token is OpenIncludeToken) {
      _state = ParserStates.INCLUDE;
      stack.add(new IncludeFragment(token.line));
    }
    else if (token is OpenCodeToken) {
      _state = ParserStates.CODE;
      stack.add(new CodeFragment(token.line));
    }
    else if (token is OpenExpressionToken) {
      _state = ParserStates.ESCAPED_EXPRESSION;
      stack.add(new EscapedOutputFragment(token.line));
    }
    else if (token is OpenUnescapedExpressionToken) {
      _state = ParserStates.UNESCAPED_EXPRESSION;
      stack.add(new UnescapedOutputFragment(token.line));
    }
    else if (token is CloseToken) {
      throw new ParseException(token.line, token);
    }
    else {
      throw new IllegalArgumentException(token);
    }
  }
  
  void _processTokenInIncludeState(Token token, Queue<Fragment> stack) {
    if (token is TextToken) {
      IncludeFragment includeToken = stack.last();
      if (includeToken.include != null) {
        throw new ParseException(token.line, token);        
      }
      includeToken.include = token.content;      
    }
    else if (token is OpenIncludeToken) {
      throw new ParseException(token.line, token);
    }
    else if (token is OpenCodeToken) {
      throw new ParseException(token.line, token);
    }
    else if (token is OpenExpressionToken) {
      throw new ParseException(token.line, token);
    }
    else if (token is OpenUnescapedExpressionToken) {
      throw new ParseException(token.line, token);
    }
    else if (token is CloseToken) {
      IncludeFragment includeToken = stack.last();
      if (includeToken.include == null) {
        throw new ParseException(token.line, token);
      }
      _state = ParserStates.UNKNOWN;
    }
    else {
      throw new IllegalArgumentException(token);
    }
  }
  
  void _processTokenInCodeState(Token token, Queue<Fragment> stack) {
    if (token is TextToken) {
      CodeFragment codeFragment = stack.last();
      if (codeFragment.code != null) {
        throw new ParseException(token.line, token);        
      }
      codeFragment.code = token.content;
    }
    else if (token is OpenIncludeToken) {
      throw new ParseException(token.line, token);    
    }
    else if (token is OpenCodeToken) {
      throw new ParseException(token.line, token);
    }
    else if (token is OpenExpressionToken) {
      throw new ParseException(token.line, token);
    }
    else if (token is OpenUnescapedExpressionToken) {
      throw new ParseException(token.line, token);
    }
    else if (token is CloseToken) {
      CodeFragment codeFragment = stack.last();
      if (codeFragment.code == null) {
        throw new ParseException(token.line, token);    
      }
      _state = ParserStates.UNKNOWN;
    }
    else {
      throw new IllegalArgumentException(token);
    }
  }
  
  void _processTokenInEscapedExpressionState(Token token, Queue<Fragment> stack) {
    if (token is TextToken) {
      EscapedOutputFragment expressionFragment = stack.last();
      if (expressionFragment.expression != null) {
        throw new ParseException(token.line, token);          
      }
      expressionFragment.expression = token.content;
    }
    else if (token is OpenIncludeToken) {
      throw new ParseException(token.line, token);  
    }
    else if (token is OpenCodeToken) {
      throw new ParseException(token.line, token);    
    }
    else if (token is OpenExpressionToken) {
      throw new ParseException(token.line, token);    
    }
    else if (token is OpenUnescapedExpressionToken) {
      throw new ParseException(token.line, token);    
    }
    else if (token is CloseToken) {
      EscapedOutputFragment expressionFragment = stack.last();
      if (expressionFragment == null) {
        throw new ParseException(token.line, token);
      }
      _state = ParserStates.UNKNOWN;
    }
    else {
      throw new IllegalArgumentException(token);
    }
  }
  
  void _processTokenInUnescapedExpressionState(Token token, Queue<Fragment> stack) {
    if (token is TextToken) {
      UnescapedOutputFragment expressionFragment = stack.last();
      if (expressionFragment.expression != null) {
        throw new ParseException(token.line, token);  
      }
      expressionFragment.expression = token.content;
    }
    else if (token is OpenIncludeToken) {
      throw new ParseException(token.line, token);    
    }
    else if (token is OpenCodeToken) {
      throw new ParseException(token.line, token);    
    }
    else if (token is OpenExpressionToken) {
      throw new ParseException(token.line, token);    
    }
    else if (token is OpenUnescapedExpressionToken) {
      throw new ParseException(token.line, token);    
    }
    else if (token is CloseToken) {
      UnescapedOutputFragment expressionFragment = stack.last();
      if (expressionFragment == null) {
        throw new ParseException(token.line, token);
      }
      _state = ParserStates.UNKNOWN;
    }
    else {
      throw new IllegalArgumentException(token);
    }
  }  
  
  List _toList(Queue queue) {
    var result = [];
    for (var item in queue) {
      result.add(item);        
    }
    return result;
  }
  
  
  /** Transforms to lines */
  List<String> _toLines(String src) {
    var lines = <String>[];
    var buf = new StringBuffer();
    for (var i = 0; i < src.length; i++) {
      buf.addCharCode(src.charCodeAt(i));
      if (src.charCodeAt(i) == NEW_LINE_CODE) {
        lines.add(buf.toString());
        buf.clear();
      }      
    }
    if (!buf.isEmpty()) {
      lines.add(buf.toString());      
    }
    return lines;
  }
  
}

/** 
 * Any fragment of parsed template. 
 * This differs from typic parser output as usually parser produces
 * a AST, but in our case we have just a plain list of parsed elements.
*/
abstract class Fragment {
  /** A line number of this fragment */
  int _line;
  
  Fragment(this._line);
  
}

/** An include */
class IncludeFragment extends Fragment {
  
  String _include;
  
  IncludeFragment(int line): super(line);
  
  String get include() => _include;
  
         set include(String value) => _include = value;  
  
}

/** An plain fragment of template */
class TemplateFragment extends Fragment {
  
  String _text;
  
  TemplateFragment(this._text, int line): super(line);
  
  String get text() => _text;
    
}

/** A fragment of code */
class CodeFragment extends Fragment {
  
  String _code;
  
  CodeFragment(int line): super(line);
  
  String get code() => _code;
  
         set code(String value) => _code = value; 
    
}

/** An expression which value is html escaped before it appended to an output */
class EscapedOutputFragment extends Fragment {
  
  String _expression;
  
  EscapedOutputFragment(int line): super(line);
  
  String get expression() => _expression;
  
         set expression(String value) => _expression = value; 
    
}

/** An expression which value is directly appended to an output */
class UnescapedOutputFragment extends Fragment {
  
  String _expression;
  
  UnescapedOutputFragment(int line): super(line);
  
  String get expression() => _expression;
  
         set expression(String value) => _expression = value;
    
}

/** Any available parser states */
class ParserStates {
  /** an unitialized state */
  static final int UNKNOWN = -1;
  /** processing a template content */
  static final int TEMPLATE = 0;
  /** processing an include content */
  static final int INCLUDE = 1;
  /** processing a code fragment */
  static final int CODE = 2;
  /** processing an escaped expression */
  static final int ESCAPED_EXPRESSION = 3;
  /** processing an unescaped expression */
  static final int UNESCAPED_EXPRESSION = 4;
}

/** thrown when parse exception arise */
class ParseException implements Exception {
  final int _line;
  final Token _unexpectedToken;
  
  const ParseException(this._line, this._unexpectedToken);
  
  String get exceptionName() => "ParseException";  
  /** A line where parse exception occured */
  int get line() => _line;
  /** An unexpected token */
  Token unexpectedToken() => _unexpectedToken;
}