// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Parser default ParserImpl {
  
  Parser();
  
  /** Parses a given template text */
  TemplateNode parse(String src, [bool isLayout=false, bool isInclude=false]);  
  
}

/** Parses a edt template */
class ParserImpl implements Parser {
  /** The newline char code */
  static final int NEW_LINE_CODE = 10;
  
  /** the current parser state */
  int _state = ParserStates.TEMPLATE_START;
  
  Queue<ContainerNode> _stack;
  
  ParserImpl() {
    _stack = new Queue<ContainerNode>();
  }
  
  TemplateNode parse(String src, [bool isLayout=false, bool isInclude=false]) {
    var parsed = <Node>[];
    var lines = _toLines(src);
    var scanner = new Scanner(lines);
    return _processTokenStream(scanner.tokenize(), isLayout, isInclude);   
  }
  
  /** Process a token stream */
  TemplateNode _processTokenStream(List<Token> tokens, bool isLayout, bool isInclude) {
    Iterator<Token> tokenIterator = tokens.iterator();
    TemplateNode template = new TemplateNode(isLayout, isInclude);
    _stack.add(template);
    while (tokenIterator.hasNext()) {
      Token token = tokenIterator.next();
      switch (_state) {
        case ParserStates.TEMPLATE_START:
          _processTokenInTemplateStartState(token);
          break;        
        case ParserStates.WAITING_FOR_NEXT_TAG:
          _processTokenInWaitingForNextTagState(token);
          break;
        case ParserStates.TEXT:
          _processTokenInTextState(token);
          break;
        case ParserStates.LAYOUT_DECLARATION:
          _processTokenInLayoutDeclarationState(token);
          break;
        case ParserStates.SECTION_DEFINITION:
          _processTokenInSectionDefinitionState(token);
          break;
        case ParserStates.SECTION_REFERENCE:
          _processTokenInSectionReferenceState(token);
          break;          
        case ParserStates.INCLUDE:
          _processTokenInIncludeState(token);
          break;
        case ParserStates.CODE:
          _processTokenInCodeState(token);
          break;
        case ParserStates.ESCAPED_EXPRESSION:
          _processTokenInEscapedExpressionState(token);
          break;
        case ParserStates.UNESCAPED_EXPRESSION:
          _processTokenInUnescapedExpressionState(token);
          break;
        default:
          throw new Exception("Illegal state: $_state");
      }
    }
    return template;    
  }
  
  void _processTokenInTemplateStartState(Token token) {
    TemplateNode template = _stack.last();
    if (token is TextToken) {
      _state = ParserStates.TEXT; 
      template.add(new TextNode(token.content, token.line));
    }
    else if (token is OpenLayoutToken) {
      if (template.isInclude) {
        throw new ParseException(token.line, token);        
      }
      if (template.isLayout) {
        _state = ParserStates.SECTION_REFERENCE;
        template.add(new SectionReferenceNode(token.line));
      }
      else {
        _state = ParserStates.LAYOUT_DECLARATION;
        template.layout = new LayoutDeclarationNode(token.line);
      }
    }
    else if (token is OpenIncludeToken) {
      _state = ParserStates.INCLUDE;
      template.add(new IncludeNode(token.line));
    }
    else if (token is OpenCodeToken) {
      _state = ParserStates.CODE;
      template.add(new CodeNode(token.line));
    }
    else if (token is OpenExpressionToken) {
      _state = ParserStates.ESCAPED_EXPRESSION;
      template.add(new EscapedOutputNode(token.line));      
    }
    else if (token is OpenUnescapedExpressionToken) {
      _state = ParserStates.UNESCAPED_EXPRESSION;
      template.add(new UnescapedOutputNode(token.line));      
    }
    else if (token is CloseToken) {
      throw new ParseException(token.line, token);      
    }
    else {
      throw new IllegalArgumentException(token);
    }
  } 
  
  void _processTokenInWaitingForNextTagState(Token token) {
    ContainerNode container = _stack.last();
    if (token is TextToken) {
      _state = ParserStates.TEXT;
      container.add(new TextNode(token.content, token.line));
    }
    else if (token is OpenLayoutToken) {
      if (_currentTemplate.isInclude) {
        throw new ParseException(token.line, token);
      }      
      if (_currentTemplate.isLayout) {
        _state = ParserStates.SECTION_REFERENCE;
        container.add(new SectionReferenceNode(token.line));
      }
      else {
        assert(_currentTemplate.hasLayout);
        _state = ParserStates.SECTION_DEFINITION;
        if (container is SectionDefinitionNode) {
          _stack.removeLast();          
        }
        var sectionDefinition = new SectionDefinitionNode(token.line);
        _stack.last().add(sectionDefinition);
        _stack.add(sectionDefinition);
      }
    }    
    else if (token is OpenIncludeToken) {
      _state = ParserStates.INCLUDE;
      container.add(new IncludeNode(token.line));
    }
    else if (token is OpenCodeToken) {
      _state = ParserStates.CODE;
      container.add(new CodeNode(token.line));      
    }
    else if (token is OpenExpressionToken) {
      _state = ParserStates.ESCAPED_EXPRESSION;
      container.add(new EscapedOutputNode(token.line));
    }
    else if (token is OpenUnescapedExpressionToken) {
      _state = ParserStates.UNESCAPED_EXPRESSION;
      container.add(new UnescapedOutputNode(token.line));
    }
    else if (token is CloseToken) {
      throw new ParseException(token.line, token);     
    } 
    else {
      throw new IllegalArgumentException(token);
    }
  }
  
  void _processTokenInTextState(Token token) {
    ContainerNode container = _stack.last();
    if (token is TextToken) {
      throw new ParseException(token.line, token);    
    }
    else if (token is OpenLayoutToken) {
      if ((_stack.first() as TemplateNode).isLayout) {
        _state = ParserStates.SECTION_REFERENCE;
        container.add(new SectionReferenceNode(token.line));
      }
      else {
        assert(_currentTemplate.hasLayout);
        _state = ParserStates.SECTION_DEFINITION;
        if (container is SectionDefinitionNode) {
          _stack.removeLast();          
        }
        var sectionDefinition = new SectionDefinitionNode(token.line); 
        _stack.last().add(sectionDefinition);
        _stack.add(sectionDefinition);
      }
    }    
    else if (token is OpenIncludeToken) {
      _state = ParserStates.INCLUDE;
      container.add(new IncludeNode(token.line));
    }
    else if (token is OpenCodeToken) {
      _state = ParserStates.CODE;
      container.add(new CodeNode(token.line));
    }
    else if (token is OpenExpressionToken) {
      _state = ParserStates.ESCAPED_EXPRESSION;
      container.add(new EscapedOutputNode(token.line));
    }
    else if (token is OpenUnescapedExpressionToken) {
      _state = ParserStates.UNESCAPED_EXPRESSION;
      container.add(new UnescapedOutputNode(token.line));
    }
    else if (token is CloseToken) {
      throw new ParseException(token.line, token);
    }
    else {
      throw new IllegalArgumentException(token);
    }
  }
  
  /** process layout declaration step */
  void _processTokenInLayoutDeclarationState(Token token) {
    assert(!(_stack.first() as TemplateNode).isLayout);
    LayoutDeclarationNode layoutDeclaration = (_stack.last() as TemplateNode).layout;
    if (token is TextToken) {
      layoutDeclaration.layoutBase = token.content.trim();
      assert(!layoutDeclaration.layoutBase.isEmpty());
    }
    else if (token is OpenLayoutToken) {
      throw new ParseException(token.line, token);      
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
      if (layoutDeclaration.layoutBase === null) {
        throw new ParseException(token.line, token);        
      }
      _state = ParserStates.WAITING_FOR_NEXT_TAG;      
    }
    else {
      throw new IllegalArgumentException(token);  
    }
  }
  
  void _processTokenInSectionDefinitionState(Token token) {
    assert(!(_stack.first() as TemplateNode).isLayout);
    SectionDefinitionNode section = _stack.last();
    if (token is TextToken) {
      section.name = token.content.trim();
      assert(!section.name.isEmpty());
    }
    else if (token is OpenLayoutToken) {
      throw new ParseException(token.line, token);
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
      if (section.name === null) {
        throw new ParseException(token.line, token);        
      }
      _state = ParserStates.WAITING_FOR_NEXT_TAG;
    }
    else {
      throw new IllegalArgumentException(token);  
    }    
  }
  
  void _processTokenInSectionReferenceState(Token token) {
    assert((_stack.first() as TemplateNode).isLayout);
    SectionReferenceNode sectionRef = _stack.last().last();
    if (token is TextToken) {
      sectionRef.name = token.content.trim();
      assert(!sectionRef.name.isEmpty());      
    }
    else if (token is OpenLayoutToken) {
      throw new ParseException(token.line, token);
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
      if (sectionRef.name === null) {
        throw new ParseException(token.line, token);        
      }
      _state = ParserStates.WAITING_FOR_NEXT_TAG;
    }
    else {
      throw new IllegalArgumentException(token);  
    }
  }
  
  void _processTokenInIncludeState(Token token) {
    ContainerNode container = _stack.last();
    if (token is TextToken) {
      IncludeNode includeToken = container.last();
      if (includeToken.include != null) {
        throw new ParseException(token.line, token);        
      }
      includeToken.include = token.content.trim();
      assert(!includeToken.include.isEmpty());
    }
    else if (token is OpenLayoutToken) {
      throw new ParseException(token.line, token);
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
      IncludeNode includeToken = container.last();
      if (includeToken.include === null) {
        throw new ParseException(token.line, token);
      }
      _state = ParserStates.WAITING_FOR_NEXT_TAG;
    }
    else {
      throw new IllegalArgumentException(token);
    }
  }
  
  void _processTokenInCodeState(Token token) {
    ContainerNode container = _stack.last();
    if (token is TextToken) {
      CodeNode codeNode = container.last();
      if (codeNode.code != null) {
        throw new ParseException(token.line, token);        
      }
      codeNode.code = token.content;
    }
    else if (token is OpenLayoutToken) {
      throw new ParseException(token.line, token);      
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
      CodeNode codeFragment = container.last();
      if (codeFragment.code == null) {
        throw new ParseException(token.line, token);    
      }
      _state = ParserStates.WAITING_FOR_NEXT_TAG;
    }
    else {
      throw new IllegalArgumentException(token);
    }
  }
  
  void _processTokenInEscapedExpressionState(Token token) {
    ContainerNode container = _stack.last();
    if (token is TextToken) {
      EscapedOutputNode expressionFragment = container.last();
      if (expressionFragment.expression != null) {
        throw new ParseException(token.line, token);          
      }
      expressionFragment.expression = token.content;
    }
    else if (token is OpenLayoutToken) {
      throw new ParseException(token.line, token);      
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
      EscapedOutputNode expressionFragment = container.last();
      if (expressionFragment == null) {
        throw new ParseException(token.line, token);
      }
      _state = ParserStates.WAITING_FOR_NEXT_TAG;
    }
    else {
      throw new IllegalArgumentException(token);
    }
  }
  
  void _processTokenInUnescapedExpressionState(Token token) {
    ContainerNode container = _stack.last();
    if (token is TextToken) {
      UnescapedOutputNode expressionFragment = container.last();
      if (expressionFragment.expression != null) {
        throw new ParseException(token.line, token);  
      }
      expressionFragment.expression = token.content;
    }
    else if (token is OpenLayoutToken) {
      throw new ParseException(token.line, token);            
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
      UnescapedOutputNode expressionFragment = container.last();
      if (expressionFragment == null) {
        throw new ParseException(token.line, token);
      }
      _state = ParserStates.WAITING_FOR_NEXT_TAG;
    }
    else {
      throw new IllegalArgumentException(token);
    }
  }
  
  TemplateNode get _currentTemplate() => _stack.first();
  
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
abstract class Node {
  /** A line number of this fragment */
  int _line;
  
  Node(this._line);
  
}

/** For any node that may contain a children elements */
abstract class ContainerNode extends Node
                             implements Iterable<Node> {
  /** a content of template */
  List<Node> _content;
  
  ContainerNode _parent;
  
  ContainerNode(int line): super(line) {
    _content = [];
  }
  
  void add(Node node) {
    if (node is ContainerNode) {
      node.parent = this;      
    }
    _content.add(node);
  }
  
  Node last() {
    return _content.last();
  }
  
  Node operator [](int index) {
    return _content[index];
  }
  
  void operator []=(int index, Node value) {
    _content[index] = value;
  }
  
  int get length() => _content.length;
  
  void forEach(void f(Node node)) {
    _content.forEach(f);    
  }
  
  /** 
   *  [replace] a function that returns either null or a List of 
   *  nodes that should replace a processed node. Right now this is used 
   *  for a processing includes 
   */
  void expandTree(List<Node> replace(Node node)) {
    int listWalker = 0;
    while(listWalker < _content.length) {
      List<Node> toReplace = replace(_content[listWalker]);
      if (toReplace !== null) {
        //replace old node with a new one
        if (toReplace.isEmpty()) throw new Exception("replacement list should not be empty");
        _content.removeRange(listWalker, 1); //remove old node
        _content.insertRange(listWalker, toReplace.length);
        for (int i = 0; i < toReplace.length; i++) {
          _content[listWalker] = toReplace[i];
          listWalker++; //increment a list walker value
        }
      }
      else {
        //do nothing.
        listWalker++;
      }
    }    
  }
  
  /** return a list of children for a given node */
  List<Node> get children() => _content; 
  
  Iterator<Node> iterator() {
    return _content.iterator();
  }
  
  bool get hasParent() => _parent !== null;
  
  ContainerNode get parent() => _parent;
  
  void set parent(ContainerNode value) { _parent = value; }
  
}

/** A template */
class TemplateNode extends ContainerNode {
  /** whenever a parsed template is layout template */
  bool _isLayout;
  /** whenever a parsed template is include template */
  bool _isInclude;
  /** a layout that used for a given template */
  LayoutDeclarationNode _layout;
  
  TemplateNode(this._isLayout, this._isInclude): super(0);
  
  bool get isLayout() => _isLayout;
  
  bool get isInclude() => _isInclude;
  
  LayoutDeclarationNode get layout() => _layout;
  
  bool get hasLayout() => _layout !== null;
  
  void set layout(LayoutDeclarationNode value) { _layout = value; }
  
}

/** Declares which layout is used for template */
class LayoutDeclarationNode extends Node {
  
  String _layoutBase;
  
  LayoutDeclarationNode(int line): super(line);
  
  String get layoutBase() => _layoutBase;
  
  void set layoutBase(String value) { _layoutBase = value; }
  
}

/** Declares a section definition that replaces corresponding layout placeholder. */
class SectionDefinitionNode extends ContainerNode {
  /** A name of given section definition */
  String _name;
  
  SectionDefinitionNode(int line): super(line);
  
  String get name() => _name;
  
  void set name(String value) { _name = value; }
  
}

/** Refers for a given section by its name in a layout definition */
class SectionReferenceNode extends Node {
  /** a name of section we refer to */
  String _name;
  
  SectionReferenceNode(int line): super(line);
  
  String get name() => _name;
  
  void set name(String value) { _name = value; }
  
}


/** An include */
class IncludeNode extends Node {
  
  String _include;
  
  IncludeNode(int line): super(line);
  
  String get include() => _include;
  
         set include(String value) => _include = value;  
  
}

/** An plain fragment of template */
class TextNode extends Node {
  
  String _text;
  
  TextNode(this._text, int line): super(line);
  
  String get text() => _text;
    
}

/** A fragment of code */
class CodeNode extends Node {
  
  String _code;
  
  CodeNode(int line): super(line);
  
  String get code() => _code;
  
         set code(String value) => _code = value; 
    
}

/** An expression which value is html escaped before it appended to an output */
class EscapedOutputNode extends Node {
  
  String _expression;
  
  EscapedOutputNode(int line): super(line);
  
  String get expression() => _expression;
  
         set expression(String value) => _expression = value; 
    
}

/** An expression which value is directly appended to an output */
class UnescapedOutputNode extends Node {
  
  String _expression;
  
  UnescapedOutputNode(int line): super(line);
  
  String get expression() => _expression;
  
         set expression(String value) => _expression = value;
    
}

/** Any available parser states */
class ParserStates {
  static final int TEMPLATE_START = 0;
  /** an unitialized state */
  static final int WAITING_FOR_NEXT_TAG = 1;
  /** processing a template content */
  static final int TEXT = 2;
  /** processing a layout declaration content */
  static final int LAYOUT_DECLARATION = 3;
  /** processing a section definition content */
  static final int SECTION_DEFINITION = 4;
  /** processing a section reference content */
  static final int SECTION_REFERENCE = 5;  
  /** processing an include content */
  static final int INCLUDE = 6;
  /** processing a code fragment */
  static final int CODE = 7;
  /** processing an escaped expression */
  static final int ESCAPED_EXPRESSION = 8;
  /** processing an unescaped expression */
  static final int UNESCAPED_EXPRESSION = 9;
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