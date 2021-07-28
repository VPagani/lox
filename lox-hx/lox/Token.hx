package lox;

@:publicFields
class Token {
    final type:TokenType;
    final lexeme:String;
    final literal:Dynamic;
    final line:Int;

    function new(type:TokenType, lexeme:String, literal:Dynamic, line:Int) {
        this.type = type;
        this.lexeme = lexeme;
        this.literal = literal;
        this.line = line;
    }

    function toString() {
        return '$type $lexeme $literal';
    }
}