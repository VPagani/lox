package lox;

enum Statement {
    Expr(expression:Expression);
    Print(expression:Expression);
}