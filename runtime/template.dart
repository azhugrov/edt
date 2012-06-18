/** This is a base class for a compiled templates in dart */
abstract class Template {
  /** Renders a given template */
  abstract String render(Map data);  
   
}
