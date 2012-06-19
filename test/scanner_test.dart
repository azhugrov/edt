#library("hypcomm:scanner-test");
#import("../Lib.dart");
//yes, it sucks. you need define your path in order to run this test
#import("../../dart/dart-sdk/lib/unittest/unittest.dart");

void main() {
  test("simple case", () {
    var unparsedText = ['This is a simple but unparsed text \n',
                       'which we would use {{>a include content}}\n',
                       '{{code fragment}} this should not {{=expression}} affect\n',
                       'what we do here {{- do you understand me}}\n',
                       'and finally this is our last line'];
    var scanner = new Scanner(unparsedText);
    var tokens = scanner.tokenize();
    printTokens(tokens);               
  });  
}

void printTokens(List<Token> tokens) {
  expect(tokens, isNotNull);
  for (var i = 0; i < tokens.length; i++) {
    Token token = tokens[i];
    print("token: $token");    
  }
}
