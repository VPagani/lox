package lox;

enum Expression {
    Literal(?value:Dynamic);
    Unary(op:Token, right:Expression);
    Binary(left:Expression, op:Token, right:Expression);
    Grouping(expression:Expression);
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
        var builder = new StringBuf();

        builder.add("(");
        builder.add(name);

        for (expression in expressions) {
            builder.add(" ");
            builder.add(print(expression));
        }

        builder.add(")");

        return builder.toString();
    }

    public static function print(expression:Expression):String {
        return switch (expression) {
            case Literal(value):
                (value == null) ? "nil" : Std.string(value);
            
            case Unary(op, right):
                parenthesize(op.lexeme, right);

            case Binary(left, op, right):
                parenthesize(op.lexeme, left, right);

            case Grouping(expression):
                parenthesize("group", expression);
        }
    }
}

// Challenge 3
class RpnPrinter {
    static function stack(name:String, ...expressions:Expression) {
        var exprs = expressions.toArray().map(print).join(" ");
        return '$exprs $name';
    }

    public static function print(expression:Expression):String {
        return switch (expression) {
            case Literal(value):
                (value == null) ? "nil" : Std.string(value);
            
            case Unary(op, right):
                stack(op.lexeme, right);

            case Binary(left, op, right):
                stack(op.lexeme, left, right);

            case Grouping(expression):
                stack("group", expression);
        }
    }
}
