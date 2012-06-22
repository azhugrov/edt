# EDT

Embedded Dart Templates

##Features
  * Template compilation to dart code.
  * Unbuffered code for conditions and loops `{{ ..code.. }}`
  * Html escaped expressions with `{{= ..expression.. }}`
  * Unescaped expressions with `{{- ..expression.. }}`
  * Static includes support with `{{> relative_path }}` where path is relative from a base template

##Example
  <div>
	<span>Include content</span>
	<span>{{=data["third"]}}</span>
	<span>{{-data["forth"]}}</span>
  </div>
  
  Where `data` is a special variable (which is Map) that you pass into EDTemplate#render(Map data, OutputStream out) method 
    
##Notes  
  * This library is designed to work with server environment.
  * Tested for windows platform.
  * Currently templates should be UTF-8 encoded.

##Compiler options
  * --out=dir_path - path to an output directory => for example ../test
  * --file=file_path - path to the template file => for example ../test/example.edt
  * --src=dir_path - path to an source directory where lookup for template files => for example ../src
Be aware that currently we do not support absolute paths as the compiler parameter. 
All path should be relative to a worker directory.

An example of the syntax could be found in the test folder.