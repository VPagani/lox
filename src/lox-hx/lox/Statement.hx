package lox;

enum Statement {
    Expr(expression:Expression);
    Print(expression:Expression);
    Block(statements:Array<Statement>);
    VarDecl(name:Token, ?initializer:Expression);
    If(condition:Expression, thenBranch:Statement, ?elseBranch:Statement);
    While(condition:Expression, body:Statement);
}