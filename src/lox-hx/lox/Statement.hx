package lox;

enum Statement {
    Expr(expression:Expression);
    Print(expression:Expression);
    Block(statements:Array<Statement>);
    VarDecl(name:Token, ?initializer:Expression);
}