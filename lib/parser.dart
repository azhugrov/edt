/** Parses a edt template */
class Parser {
  static final int NEW_LINE_CODE = "/n".charCodeAt(0);
  /** numbers of symbols we need to consume in order to determine next action */
  static final int LOOK_AHEAD_SYMBOLS = 3;
  
  /** the current parser state */
  int _state = ParserStates.ANALYZING;  
  
  Parser() {}
  
  /** Parses a given template text */
  List<Fragment> parse(String src) {
    var parsed = <Fragment>[];
    var lines = _toLines(src);
        
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
    return lines;
  }
  
}

/** 
 * Any fragment of parsed template. 
 * This differs from typic parser output as usually parser produces
 * a AST, but in our case we have just a plain list of parsed elements.
*/
abstract class Fragment {
  /** A fragment content */
  String _content;
  /** A line number of this fragment */
  int _line;
  
  Fragment(this._content, this._line);
  
  abstract String toCode();
  
}

/** An include */
class IncludeFragment extends Fragment {
  
  IncludeFragment(String fragment, int line): super(fragment, line);
  
  String toCode() {
    return null;
  }
  
}

/** An plain fragment of template */
class TemplateFragment extends Fragment {
  
  TemplateFragment(String fragment, int line): super(fragment, line);
  
  String toCode() {
    return null;
  }
  
}

/** A fragment of code */
class CodeFragment extends Fragment {
  
  CodeFragment(String fragment, int line): super(fragment, line);
  
  String toCode() {
    return null;
  }
  
}

/** An expression which value is html escaped before it appended to an output */
class EscapedOutputFragment extends Fragment {
  
  EscapedOutputFragment(String fragment, int line): super(fragment, line);
  
  String toCode() {
    return null;
  }
  
}

/** An expression which value is directly appended to an output */
class UnescapedOutputFragment extends Fragment {
  
  UnescapedOutputFragment(String fragment, int line): super(fragment, line);
  
  String toCode() {
    return null;
  }
  
}

/** Any available parser states */
class ParserStates {
  /** trying to determine which action should be taken */
  static final int ANALYZING = 0;
  /** processing a template content */
  static final int TEMPLATE = 1;
  /** processing an include content */
  static final int INCLUDE = 2;
  /** processing a code fragment */
  static final int CODE = 3;
  /** processing an escaped expression */
  static final int ESCAPED_EXPRESSION = 4;
  /** processing an unescaped expression */
  static final int UNESCAPED_EXPRESSION = 5;
}

/** A set of actions that we can possibly take */
class Actions {
  
}














