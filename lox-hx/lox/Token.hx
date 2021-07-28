package lox;

class Token {
    final type:TokenType;
    final lexeme:String;
    final literal:Dynamic;
    final line:Int;

    public function new(type:TokenType, lexeme:String, literal:Dynamic, line:Int) {
        this.type = type;
        this.lexeme = lexeme;
        this.literal = literal;
        this.line = line;
    }

    public function toString() {
        return '$type $lexeme $literal';
    }
}