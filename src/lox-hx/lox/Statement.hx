package lox;

enum Statement {
    Expr(expression:Expression);
    Print(expression:Expression);
    Block(statements:Array<Statement>);
    VarDecl(name:Token, ?initializer:Expression);
    Function(name:Token, params:Array<Token>, body:Array<Statement>);
    If(condition:Expression, thenBranch:Statement, ?elseBranch:Statement);
    While(condition:Expression, body:Statement);
    Break(keyword:Token);
    Return(keyword:Token, ?value:Expression);
}