package lox;

class Resolver {
    private final interpreter:Interpreter;
    private final scopes:Scopes = new Scopes();

    public function new(interpreter:Interpreter) {
        this.interpreter = interpreter;
    }

    public function resolve(statements:Array<Statement>) {
        for (statement in statements) {
            resolveStatement(statement);
        }
    }

    private function resolveStatement(statement:Statement) {
        switch (statement) {
            case Expr(expression):
                resolveExpression(expression);

            case Print(expression):
                resolveExpression(expression);

            case Block(statements):
                beginScope();
                resolve(statements);
                endScope();

            case VarDecl(name, initializer):
                declare(name);
                if (initializer != null) {
                    resolveExpression(initializer);
                }
                define(name);

            case Function(name, params, body):
                declare(name);
                define(name);

                resolveFunction(params, body);

            case If(condition, thenBranch, elseBranch):
                resolveExpression(condition);
                resolveStatement(thenBranch);
                if (elseBranch != null)
                    resolveStatement(elseBranch);

            case While(condition, body):
                resolveExpression(condition);
                resolveStatement(body);
            
            case Break: // do nothing

            case Return(_, expression):
                if (expression != null)
                    resolveExpression(expression);
        }
    }

    private function resolveExpression(expression:Expression) {
        switch (expression) {
            case Literal(_):

            case Call(callee, _, arguments):
                resolveExpression(callee);

                for (argument in arguments)
                    resolveExpression(argument);

            case Unary(_, right):
                resolveExpression(right);

            case Binary(left, _, right) | Logical(left, _, right):
                resolveExpression(left);
                resolveExpression(right);

            case Ternary(first, _, second, _, third):
                resolveExpression(first);
                resolveExpression(second);
                resolveExpression(third);

            case Grouping(expression):
                resolveExpression(expression);

            case Variable(name):
                if (!scopes.isEmpty() && scopes.peek().get(name.lexeme) == false) {
                    Lox.errorToken(name, "Can't read local variable in its own initializer");
                }
                resolveLocal(expression, name);

            case Assignment(name, value):
                resolveExpression(value);
                resolveLocal(expression, name);
        }
    }

    private function resolveFunction(params:Array<Token>, body:Array<Statement>) {
        beginScope();
        for (param in params) {
            declare(param);
            define(param);
        }
        resolve(body);
        endScope();
    }

    private function beginScope() {
        scopes.push(new Map());
    }

    private function endScope() {
        scopes.pop();
    }

    private function declare(name:Token) {
        if (scopes.isEmpty()) return;

        var scope = scopes.peek();
        if (scope.exists(name.lexeme)) {
            Lox.errorToken(name, "Already a variable with this name in this scope");
        }

        scope.set(name.lexeme, false);
    }

    private function define(name:Token) {
        if (scopes.isEmpty()) return;
        scopes.peek().set(name.lexeme, true);
    }

    private function resolveLocal(expression:Expression, name:Token) {
        for (i => scope in scopes) {
            if (scope.exists(name.lexeme)) {
                interpreter.resolve(expression, scopes.length - 1 - i);
                return;
            }
        }
    }
}

typedef ScopesT = Array<Map<String, Bool>>;

@:forward(push, pop, length)
abstract Scopes(ScopesT) from ScopesT {
    public inline function new()
        this = [];

    public inline function peek() {
        return this[this.length - 1];
    }

    public inline function isEmpty() {
        return this.length <= 0;
    }

    public inline function keyValueIterator():KeyValueIterator<Int, Map<String, Bool>> {
        var i = this.length - 1;

        return {
            hasNext: () -> i >= 0,
            next: () -> { key: i,  value: this[i >= 0 ? i-- : i] }
        }
    }
}