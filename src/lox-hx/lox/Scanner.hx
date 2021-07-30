package lox;

import lox.TokenType;

class Scanner {
    private final source:String;
    private final tokens:Array<Token> = [];
    private var start:Int = 0;
    private var current:Int = 0;
    private var line:Int = 1;

    private static final reserved = [
        "and" => AND,
        "class" => CLASS,
        "else" => ELSE,
        "false" => FALSE,
        "for" => FOR,
        "fun" => FUN,
        "if" => IF,
        "nil" => NIL,
        "or" => OR,
        "print" => PRINT,
        "return" => RETURN,
        "super" => SUPER,
        "this" => THIS,
        "true" => TRUE,
        "var" => VAR,
        "while" => WHILE,
    ];

    public function new(source:String) {
        this.source = source;
    }

    private function addToken(type:TokenType, ?literal:Dynamic) {
        var lexeme = source.substring(start, current);
        tokens.push(new Token(type, lexeme, literal, line));
    }

    public function scanTokens(): Array<Token> {
        while (!isAtEnd()) {
            start = current;
            scanToken();
        }

        tokens.push(new Token(EOF, "", null, line));
        return tokens;
    }

    public function scanToken() {
        var c = advance();
        switch (c) {
            case "(": addToken(LEFT_PAREN);
            case ")": addToken(RIGHT_PAREN);
            case "{": addToken(LEFT_BRACE);
            case "}": addToken(RIGHT_BRACE);
            case ",": addToken(COMMA);
            case ".": addToken(DOT);
            case "-": addToken(MINUS);
            case "+": addToken(PLUS);
            case ";": addToken(SEMICOLON);
            case "*": addToken(STAR);

            case "?": addToken(QUESTION);
            case ":": addToken(COLON);

            case "!": addToken(match("=") ? BANG_EQUAL : BANG);
            case "=": addToken(match("=") ? EQUAL_EQUAL : EQUAL);
            case "<": addToken(match("=") ? LESS_EQUAL : LESS);
            case ">": addToken(match("=") ? GREATER_EQUAL : GREATER);
            
            case "/": comment();
            
            case " " | "\r" | "\t": // Ignore whitespace
            case "\n": line++;

            case '"': string();
            case d if (isDigit(d)): number();
            case w if (isAlpha(w)): identifier();

            default:
                Lox.error(line, 'Unexpected character "$c"');
        }
    }

    private function isAtEnd() {
        return current >= source.length;
    }

    private function advance() {
        return source.charAt(current++);
    }

    private function match(expected:String) {
        if (isAtEnd()) return false;
        if (source.charAt(current) != expected) return false;

        current++;

        return true;
    }
    
    private function peek(pos:Int = 0):String {
        if (current + pos >= source.length) return "";
        return source.charAt(current + pos);
    }

    private function isDigit(char:String) {
        var c = char.charCodeAt(0);
        return c >= 48 && c <= 57;
    }

    private function isAlpha(char:String) {
        var c = char.charCodeAt(0);
        return (c >= 97 && c <= 122) || // Lowercase
                (c >= 65 && c <= 90) || // Uppercase
                c == 95; // Underscore
    }

    private function isAlphaNumeric(char:String) {
        return isAlpha(char) || isDigit(char);
    }

    private function number() {
        while (isDigit(peek())) advance();

        if (peek() == "." && isDigit(peek(1))) {
            advance();

            while (isDigit(peek())) advance();
        }

        addToken(NUMBER, Std.parseFloat(source.substring(start, current)));
    }

    private function string() {
        while (peek() != '"' && !isAtEnd()) {
            if (peek() == "\n") line++;
            advance();
        }

        if (isAtEnd()) {
            Lox.error(line, "Unterminated string");
            return;
        }

        // The closing "
        advance();

        var value = source.substring(start + 1, current - 1);
        addToken(STRING, value);
    }

    private function comment(depth:Int = 0) {
        if (match("/")) {
            while (peek() != "\n" && !isAtEnd()) advance();
        } else if (match("*")) {
            while (peek() != "*" || peek(1) != "/") {
                trace([peek(), peek(1)]);
                var char = advance();
                switch (char) {
                    case "\n": line++;
                    case "/": comment(depth+1);
                }
            }
            current += 2;
        } else if (depth == 0) {
            addToken(SLASH);
        }
    }

    private function identifier() {
        while (isAlphaNumeric(peek())) advance();

        var text = source.substring(start, current);
        var type = reserved.get(text);
        if (type == null) type = IDENTIFIER;
        addToken(type);
    }

    private inline function debug<T:Dynamic>(value:T):T {
        trace(value);
        return value;
    }
        
}