package lox;

enum Expression {
    Literal(?value:Dynamic);
    Get(object:Expression, name:Token);
    Set(object:Expression, name:Token, value:Expression);
    Call(callee:Expression, paren:Token, arguments:Array<Expression>);
    This(keyword:Token);
    Unary(op:Token, right:Expression);
    Binary(left:Expression, op:Token, right:Expression);
    Logical(left:Expression, op:Token, right:Expression);
    Ternary(first:Expression, op1:Token, second:Expression, op2:Token, third:Expression);
    Grouping(expression:Expression);
    Variable(name:Token);
    Assignment(name:Token, value:Expression);
}


// Chapter 5 Challenges

/*
Challenge 1:

    expr → expr ( "(" ( expr ( "," expr )* )? ")" | "." IDENTIFIER )+
        | IDENTIFIER
        | NUMBER

Answer:
    expr -> expr call
    expr -> expr prop
    expr -> IDENTIFIER
    expr -> NUMBER

    call -> "(" ")"
    call -> "(" args ")"

    args -> expr
    args -> args "," expr

    prop -> "." IDENTIFIER

    
Bonus Answer:
    this bit of grammar encodes function calls and property access

*/


// Challenge 2 (using pattern matching)
class AstPrinter {
    static function parenthesize(name:String, ...expressions:Expression) {
        return '($name ${expressions.toArray().map(print).join(" ")} )';
    }

    public static function print(expression:Expression):String {
        return switch (expression) {
            case Literal(value):
                (value == null) ? "nil" : Std.string(value);

            case Get(object, name):
                '${print(object)}.${name.lexeme}';

            case Set(object, name, value):
                '(= ${print(object)}.${name.lexeme} ${print(value)})';

            case Call(callee, paren, arguments):
                parenthesize('${print(callee)}()', ...arguments);

            case This(keyword): 'this';
            
            case Unary(op, right):
                parenthesize(op.lexeme, right);

            case Binary(left, op, right) | Logical(left, op, right):
                parenthesize(op.lexeme, left, right);

            case Ternary(first, op1, second, op2, third):
                parenthesize(op1.lexeme, first, second, third);

            case Grouping(expression):
                parenthesize("group", expression);

            case Variable(name):
                name.lexeme;

            case Assignment(name, value):
                '(= ${name.lexeme} ${print(value)})';
        }
    }
}

// Challenge 3
class RpnPrinter {
    static function stack(name:String, ...expressions:Expression) {
        var expressions = expressions.toArray();
        var exprs = expressions.map(print).join(" ");
        return '$exprs $name';
    }

    public static function print(expression:Expression):String {
        return switch (expression) {
            case Literal(value):
                (value == null) ? "nil" : Std.string(value);

            case Get(object, name):
                '${print(object)}.${name.lexeme}';

            case Set(object, name, value):
                '${print(value)} ${print(object)}.${name.lexeme} =';

            case Call(callee, paren, arguments):
                stack('${print(callee)}())', ...arguments);
            
            case This(keyword): 'this';

            case Unary(op, right):
                stack(op.lexeme, right);

            case Binary(left, op, right) | Logical(left, op, right):
                stack(op.lexeme, left, right);

            case Ternary(first, op1, second, op2, third):
                stack(op1.lexeme, first, second, third);

            case Grouping(expression):
                print(expression);

            case Variable(name):
                name.lexeme;

            case Assignment(name, value):
                '${print(value)} ${name.lexeme} =';
        }
    }
}
