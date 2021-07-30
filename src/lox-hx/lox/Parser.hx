package lox;

import lox.Expression;
import lox.Statement;
import lox.TokenType;

class Parser {
    private final tokens:Array<Token>;
    private var current:Int = 0;

    public function new(tokens:Array<Token>) {
        this.tokens = tokens;
    }

    public function parse() {
        return program();
    }

    // Chapter 8 Challenge 1
    public function parseExpression() {
        return expression();
    }

    /**
     * __program__ → __declaration__* EOF
     */
    private function program():Array<Statement> {
        var statements:Array<Statement> = [];

        while (!isAtEnd()) {
            var statement = declaration();
            if (statement != null) {
                statements.push(statement);
            }
        }

        return statements;

    }

    /**
     * __declaration__ → `var` __varDeclaration__
     * 
     * __declaration__ → __statement__
     */
    private function declaration():Null<Statement> {
        try {
            if (match(VAR)) return varDeclaration();

            return statement();
        } catch (error:ParseError) {
            synchronize();
            return null;
        }
    }

    /**
     * varDeclaration → _IDENTIFIER_ ( `=` __expression__ )? `;`
     */
    private function varDeclaration():Statement {
        var name = consume(IDENTIFIER, "Expected variable name");

        var initializer = null;
        if (match(EQUAL)) {
            initializer = expression();
        }

        consume(SEMICOLON, "Expected ';' after variable declaration");
        return VarDecl(name, initializer);
    }

    /**
     * __statement__ → `if` __ifStatement__
     * 
     * __statement__ → `print` __printStatement__
     * 
     * __statement__ → `{` __block__
     * 
     * __statement__ → __expressionStatement__
     */
    private function statement():Statement {
        if (match(IF)) return ifStatement();
        if (match(PRINT)) return printStatement();
        if (match(LEFT_BRACE)) return Block(block());

        return expressionStatement();
    }

    /**
     * __ifStatement__ → `(` __expression__ `)` __statement__ ( `else` __statement__ )?
     */
    private function ifStatement():Statement {
        consume(LEFT_PAREN, "Expected '(' after 'if'");
        var condition = expression();
        consume(RIGHT_PAREN, "Expected ')' after if confition");

        var thenBranch = statement();
        var elseBranch = match(ELSE) ? statement() : null;

        return If(condition, thenBranch, elseBranch);
    }

    /**
     * __printStatement__ → __expression__ `;`
     */
    private function printStatement():Statement {
        var value = expression();
        consume(SEMICOLON, "Expected ';' after value");
        return Print(value);
    }

    /**
     * __expressionStatement__ → __expression__ `;`
     */
    private function expressionStatement():Statement {
        var expr = expression();
        consume(SEMICOLON, "Expected ';' after expression");
        return Expr(expr);
    }

    /**
     * __block__ -> __declaration__* `}`
     */
    private function block():Array<Statement> {
        var statements:Array<Statement> = [];

        while (!check(RIGHT_BRACE) && !isAtEnd()) {
            var statement = declaration();
            if (statement != null)
                statements.push(statement);
        }

        consume(RIGHT_BRACE, "Expected '}' to close the block");

        return statements;
    }

    // Chapter 6 Chalenge 1 (Comma Operator)
    /**
     * __expression__ → __assignment__ ( `,` __assignment__ )*
     */
     private function expression():Expression {
        var expr = assignment();

        while(match(COMMA)) {
            var op = previous();
            var right = assignment();
            expr = Binary(expr, op, right);
        }

        return expr;
    }

    /**
     * __assignment__ → __ternary__
     * 
     * __assignment__ → _IDENTIFIER_ `=` __assignment__
     */
    private function assignment():Expression {
        var expr = ternary();

        if (match(EQUAL)) {
            var equals = previous();
            var value = assignment();

            switch (expr) {
                case Variable(name):
                    return Assignment(name, value);
                
                case _:
                    error(equals, "Invalid assignment target");
            }
        }

        return expr;
    }

    // Chapter 6 Chalenge 2 (Conditional Operator)
    /**
     * 
     * __ternary__ → ( __or__  `?` __or__ `:`)* __ternary__
     */
    private function ternary():Expression {
        var first = or();

        if (!match(QUESTION)) return first;

        var op1 = previous();
        var second = or();

        if (!match(COLON))
            throw error(peek(), "Expected ':' after expression");

        var op2 = previous();
        return Ternary(first, op1, second, op2, ternary());
    }

    /**
     * __or__ → __and__ ( `or` __and__ )*
     */
    private function or() {
        var expr = and();

        while (match(OR)) {
            var op = previous();
            var right = and();
            expr = Logical(expr, op, right);
        }

        return expr;
    }

    /**
     * __and__ → __equality__ ( `and` __equality__ )*
     */
    private function and() {
        var expr = equality();

        while (match(AND)) {
            var op = previous();
            var right = equality();
            expr = Logical(expr, op, right);
        }

        return expr;
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

        return unaryError();
    }

    // Chapter 6 Challenge 3
    /** 
     * __unaryError__ → ( `,` ) __unaryError__
     * 
     * __unaryError__ → ( `?` | `:` ) __unaryError__
     * 
     * __unaryError__ → ( `!=` | `==` ) __unaryError__
     * 
     * __unaryError__ → ( `>` | `>=` | `<` | `<=` ) __unaryError__
     * 
     * __unaryError__ → ( `+` ) __unaryError__
     * 
     * __unaryError__ → ( `/` | `*` ) __unaryError__
     * 
     * __unaryError__ → __primary__
     */
    private function unaryError():Expression {
        while (match(
            COMMA, // expression
            QUESTION, COLON, // ternary
            BANG_EQUAL, EQUAL_EQUAL, // equality
            GREATER, GREATER_EQUAL, LESS, LESS_EQUAL, // comparision
            PLUS, // term
            SLASH, STAR // factor
        )) {
            var op = previous();
            error(op, 'Expected expression before \'${op.lexeme}\'');
            return unaryError(); // discard right-hand operand
        }

        return primary();
    }

    /**
     * __primary__ → _NUMBER_
     * 
     * __primary__ → _STRING_
     * 
     * __primary__ → _IDENTIFIER_
     * 
     * __primary__ → `true` | `false`
     * 
     * __primary__ → `nil`
     * 
     * __primary__ → `(` __expression__ `)`
     */
     private function primary():Expression {
        if (match(FALSE)) return Literal(false);
        if (match(TRUE)) return Literal(true);
        if (match(NIL)) return Literal(null);

        if (match(NUMBER, STRING)) {
            return Literal(previous().literal);
        }

        if (match(IDENTIFIER)) {
            return Variable(previous());
        }

        if (match(LEFT_PAREN)) {
            var expr = expression();
            consume(RIGHT_PAREN, "Expected ')' after expression");
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
        return new ParseError(message);
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

class ParseError extends haxe.Exception {}