package lox;

enum Statement {
    Expr(expression:Expression);
    Print(expression:Expression);
    VarDecl(name:Token, ?initializer:Expression);
}