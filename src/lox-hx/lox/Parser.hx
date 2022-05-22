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
     * __declaration__ → `fun` __funDeclaration__
     * 
     * __declaration__ → `class` __classDeclaration__
     * 
     * __declaration__ → __statement__
     */
    private function declaration(canBreak:Bool = false):Null<Statement> {
        try {
            if (match(VAR)) return varDeclaration();
            if (match(FUN)) return funDeclaration(function_);
            if (match(CLASS)) return classDeclaration();

            return statement(canBreak);
        } catch (error:ParseError) {
            synchronize();
            return null;
        }
    }

    /**
     * __varDeclaration__ → _IDENTIFIER_ ( `=` __expression__ )? `;`
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
     * __funDeclaration__ → _IDENTIFIER_ `(` __parameters__? `)` `{` __block__
     * 
     * __parameters__ → _IDENTIFIER_ ( `,` _IDENTIFIER_ )*
     */
    private function funDeclaration(kind:FunctionKind):Statement {
        var name = consume(IDENTIFIER, 'Expected $kind name');
        consume(LEFT_PAREN, 'Expected \'(\' after $kind name');

        var params = [];
        if (!check(RIGHT_PAREN)) {
            do {
                if (params.length > 255) {
                    error(peek(), "Can't have more than 255 parameters");
                }

                params.push(
                    consume(IDENTIFIER, "Expected parameter name")
                );
            } while (match(COMMA));
        }

        consume(RIGHT_PAREN, "Expected ')' after parameters");

        consume(LEFT_BRACE, 'Expect \'{\' before $kind body');
        var body = block();
        return Statement.Function(name, params, body);
    }

    /**
     * __classDeclaration__ -> _IDENTIFIER_ ( `<` _IDENTIFIER_ )? `{` __funDeclaration__* `}`
     */
    private function classDeclaration():Statement {
        var name = consume(IDENTIFIER, "Expected class name");

        var superclass = null;
        if (match(LESS)) {
            consume(IDENTIFIER, "Expected superclass name");
            superclass = Expression.Variable(previous());
        }

        consume(LEFT_BRACE, "Expect '{' before class body");

        var methods = [];

        while (!check(RIGHT_BRACE) && !isAtEnd()) {
            methods.push(funDeclaration(FunctionKind.method));
        }

        consume(RIGHT_BRACE, "Expected '}' after class body");

        return Statement.Class(name, superclass, methods);
    }

    /**
     * __statement__ → `if` __ifStatement__
     * 
     * __statement__ → `for` __forStatement__
     * 
     * __statement__ → `while` __whileStatement__
     * 
     * __statement__ → `print` __printStatement__
     * 
     * __statement__ → `return` __returnStatement__
     * 
     * __statement__ → `{` __block__
     * 
     * __statement__ → `break` __breakStatement__
     * 
     * __statement__ → __expressionStatement__
     */
    private function statement(canBreak:Bool = false):Statement {
        if (match(IF)) return ifStatement(canBreak);
        if (match(FOR)) return forStatement();
        if (match(WHILE)) return whileStatement();
        if (match(PRINT)) return printStatement();
        if (match(RETURN)) return returnStatement();
        if (match(LEFT_BRACE)) return Block(block(canBreak));

        // Chapter 9 Challenge 3
        if (match(BREAK)) return breakStatement(canBreak);

        return expressionStatement();
    }

    /**
     * __ifStatement__ → `(` __expression__ `)` __statement__ ( `else` __statement__ )?
     */
    private function ifStatement(canBreak:Bool = false):Statement {
        consume(LEFT_PAREN, "Expected '(' after 'if'");
        var condition = expression();
        consume(RIGHT_PAREN, "Expected ')' after if confition");

        var thenBranch = statement(canBreak);
        var elseBranch = match(ELSE) ? statement(canBreak) : null;

        return If(condition, thenBranch, elseBranch);
    }

    /**
     * __forStatement__ → `(` ( `;` | `var` __varDeclaration__ | __expressionStatement__ ) __expression__? `;` __expression__? `)` __statement__
     */
    private function forStatement():Statement {
        consume(LEFT_PAREN, "Expected '(' after 'for'");
        
        var initializer;
        if (match(SEMICOLON)) {
            initializer = null;
        } else if (match(VAR)) {
            initializer = varDeclaration();
        } else {
            initializer = expressionStatement();
        }


        var condition:Null<Expression> = null;
        if (!match(SEMICOLON)) {
            condition = expression();
            consume(SEMICOLON, "Expected ';' after loop condition");
        }

        var increment:Null<Expression> = null;
        if (!match(RIGHT_PAREN)) {
            increment = expression();
            consume(RIGHT_PAREN, "Expected ')' after loop increment");
        }

        var body = statement(true);

        if (increment != null) {
            body = Block([ body, Expr(increment) ]);
        }

        if (condition == null) {
            condition = Literal(true);
        }

        body = While(condition, body);

        if (initializer != null) {
            body = Block([ initializer, body ]);
        }

        return body;
    }

    /**
     * __ifStatement__ → `(` __expression__ `)` __statement__ 
     */
    private function whileStatement():Statement {
        consume(LEFT_PAREN, "Expected '(' after 'while'");
        var condition = expression();
        consume(RIGHT_PAREN, "Expected ')' after while confition");

        var body = statement(true);
        return While(condition, body);
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
     * __breakStatement__ → `;`
     */
    private function breakStatement(canBreak:Bool = false):Statement {
        var keyword = previous();

        // if (!canBreak) {
        //     throw error(keyword, "Can only break inside loops");
        // }

        consume(SEMICOLON, "Expected ';' after break");
        return Break(keyword);
    }

    /**
     * __returnStatement__ → __expression__? `;`
     */
    private function returnStatement():Statement {
        var keyword = previous();
        var value = null;

        if (!check(SEMICOLON)) {
            value = expression();
        }

        consume(SEMICOLON, "Expected ';' after return value");

        return Statement.Return(keyword, value);
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
    private function block(canBreak:Bool = false):Array<Statement> {
        var statements:Array<Statement> = [];

        while (!check(RIGHT_BRACE) && !isAtEnd()) {
            var statement = declaration(canBreak);
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
     * __assignment__ → ( __call__ "." )? _IDENTIFIER_ `=` __assignment__
     */
    private function assignment():Expression {
        var expr = ternary();

        if (match(EQUAL)) {
            var equals = previous();
            var value = assignment();

            switch (expr) {
                case Variable(name):
                    return Assignment(name, value);

                case Get(object, name):
                    return Expression.Set(object, name, value);
                
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

        return call();
    }

    /**
     * __call__ → __primary__ ( `(` __arguments__? `)` | `.` _IDENTIFIER_ )*
     */
    private function call() {
        var expr = primary();
    
        while (true) { 
            if (match(LEFT_PAREN)) {
                var args = arguments();
                var paren = consume(RIGHT_PAREN, "Expected ')' after arguments");
                expr = Call(expr, paren, args);
            } else if (match(DOT)) {
                var name = consume(IDENTIFIER, "Expected property name after '.'");
                expr = Get(expr, name);
            } else {
                break;
            }
        }
    
        return expr;
    }

    /**
     * __arguments__ → __assignment__ ( `,` __assignment__ )*
     * 
     * OBS:
     * 
     * Here I had to change from __expression__ to __assignment__
     * because __expression__ parses `,` as an operator and
     * conflicts with arguments' `,`
     */
    private function arguments() {
        var args = [];

        if (!check(RIGHT_PAREN)) {
            do {
                if (args.length >= 255) {
                    error(peek(), "Function call can't have more than 255 arguments");
                }
                args.push(assignment()); 
            } while(match(COMMA));
        }

        return args;
    }

    /**
     * __primary__ → `true` | `false`
     * 
     * __primary__ → `nil`
     * 
     * __primary__ → _NUMBER_ | _STRING_
     * 
     * __primary__ → `super` `.` _IDENTIFIER_
     * 
     * __primary__ → `this`
     * 
     * __primary__ → _IDENTIFIER_
     * 
     * __primary__ → `(` __expression__ `)`
     */
     private function primary():Expression {
        if (match(TRUE)) return Literal(true);
        if (match(FALSE)) return Literal(false);
        if (match(NIL)) return Literal(null);

        if (match(NUMBER, STRING)) {
            return Literal(previous().literal);
        }

        if (match(SUPER)) {
            var keyword = previous();
            consume(DOT, "Expected '.' after 'super'");
            var method = consume(IDENTIFIER, "Expected superclass method name");
            return Expression.Super(keyword, method);
        }

        if (match(THIS)) {
            return This(previous());
        }

        if (match(IDENTIFIER)) {
            return Variable(previous());
        }

        if (match(LEFT_PAREN)) {
            var expr = expression();
            consume(RIGHT_PAREN, "Expected ')' after expression");
            return Grouping(expr);
        }
        var current = peek();
        throw error(current, 'Invalid identifier \'${current.lexeme}\'');
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

enum abstract FunctionKind(String) {
    var function_ = "function";
    var method;
}