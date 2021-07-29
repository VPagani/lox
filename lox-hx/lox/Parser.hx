package lox;

import lox.Expression;
import lox.TokenType;

class Parser {
    private final tokens:Array<Token>;
    private var current:Int = 0;

    public function new(tokens:Array<Token>) {
        this.tokens = tokens;
    }

    public function parse() {
        try {
            return expression();
        } catch (error:ParseError) {
            return null;
        }
    }

    /**
     * __expression__ → __equality__
     */
    private function expression():Expression {
        return equality();
    }

    /**
     * __equality__ → __comparison__ ( ( `!=` | `==` ) __comparison__ )*
     */
    private function equality():Expression {
        var expr = comparison();

        while(match(BANG_EQUAL, EQUAL_EQUAL)) {
            var op = previous();
            var right = comparison();
            expr = Binary(expr, op, right);
        }

        return expr;
    }

    /**
     * __comparison__ → __term__ ( ( `>` | `>=` | `<` | `<=` ) __term__ )* ;
     */
    private function comparison():Expression {
        var expr = term();

        while (match(GREATER, GREATER_EQUAL, LESS, LESS_EQUAL)) {
            var op = previous();
            var right = term();
            expr = Binary(expr, op, right);
        }

        return expr;
    }

    /**
     * __term__ → __factor__ ( ( `-` | `+`) __factor__ )* ;
     */
     private function term():Expression {
        var expr = factor();

        while (match(MINUS, PLUS)) {
            var op = previous();
            var right = factor();
            expr = Binary(expr, op, right);
        }

        return expr;
    }

    /**
     * __factor__ → __unary__ ( ( `/` | `*`) __unary__ )* ;
     */
     private function factor():Expression {
        var expr = unary();

        while (match(SLASH, STAR)) {
            var op = previous();
            var right = unary();
            expr = Binary(expr, op, right);
        }

        return expr;
    }

    /** 
     * __unary__ → ( `!` | `-`) __unary__
     * 
     * __unary__ → __primary__
     */
     private function unary():Expression {
        while (match(BANG, STAR)) {
            var op = previous();
            var right = unary();
            return Unary(op, right);
        }

        return primary();
    }

    /**
     * __primary__ → _NUMBER_
     * 
     * __primary__ → _STRING_
     * 
     * __primary__ → "true" | "false"
     * 
     * __primary__ -> "nil"
     * 
     * __primary__ -> "(" __expression__ ")"
     */
     private function primary():Expression {
        if (match(FALSE)) return Literal(false);
        if (match(TRUE)) return Literal(true);
        if (match(NIL)) return Literal(null);

        if (match(NUMBER, STRING)) {
            return Literal(previous().literal);
        }

        if (match(LEFT_PAREN)) {
            var expr = expression();
            consume(RIGHT_PAREN, "Expected ')'  after expression");
            return Grouping(expr);
        }

        throw error(peek(), "Expected expression");
    }

    private function match(...types:TokenType) {
        for (type in types) {
            if (check(type)) {
                advance();
                return true;
            }
        }

        return false;
    }

    private function consume(type:TokenType, message:String) {
        if (check(type)) return advance();

        throw error(peek(), message);
    }

    private function check(type:TokenType) {
        if (isAtEnd()) return false;
        return peek().type == type;
    }

    private function advance() {
        if (!isAtEnd()) current++;
        return previous();
    }

    private function isAtEnd() {
        return peek().type == EOF;
    }

    private function peek() {
        return tokens[current];
    }

    private function previous() {
        return tokens[current - 1];
    }

    private function error(token: Token, message:String) {
        Lox.errorToken(token, message);
        return new ParseError();
    }

    private function synchronize() {
        advance();

        while (!isAtEnd()) {
            if (previous().type == SEMICOLON) return;

            switch (peek().type) {
                case CLASS | FUN | VAR | FOR | IF | WHILE | PRINT | RETURN:
                    return;
                case _:
                    advance();
            }
        }
    }
}

class ParseError {
    public function new() {}
}