package lox;


class Resolver {
    private final interpreter:Interpreter;
    private final scopes:Scopes = new Scopes();

    private var currentLoop:LoopType = LoopType.NONE;
    private var currentClass:ClassType = ClassType.NONE;
    private var currentFunction:FunctionType = FunctionType.NONE;

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

                resolveFunction(params, body, FunctionType.FUNCTION);

            case Class(name, superclass, methods):
                var enclosingClass = currentClass;
                currentClass = ClassType.CLASS;

                declare(name);
                define(name);

                if (superclass != null) {
                    var token = null;
                    switch (superclass) {
                        case Variable(supername):
                            token = supername;
                            if (name.lexeme == supername.lexeme) {
                                Lox.errorToken(supername, "A class can't inherit from itself");
                            }
                        
                        case _:
                    }

                    currentClass = ClassType.SUBCLASS;
                    resolveExpression(superclass);

                    var scope = beginScope();
                    scope.set("super", {
                        token: token,
                        defined: true,
                        used: true
                    });
                }

                var scope = beginScope();

                scope.set("this", {
                    token: name,
                    defined: true,
                    used: true
                });

                for (method in methods) {
                    switch (method) {
                        case Function(name, params, body):
                            var declaration = name.lexeme == "init"
                                ? FunctionType.INITIALIZER
                                : FunctionType.METHOD;
                            resolveFunction(params, body, declaration);
                        case _:
                    }
                }

                endScope();
                if (superclass != null) endScope();

                currentClass = enclosingClass;

            case If(condition, thenBranch, elseBranch):
                resolveExpression(condition);
                resolveStatement(thenBranch);
                if (elseBranch != null)
                    resolveStatement(elseBranch);

            case While(condition, body):
                resolveExpression(condition);
                var enclosingLoop = currentLoop;
                currentLoop = LoopType.WHILE;
                resolveStatement(body);
                currentLoop = enclosingLoop;
            
            case Break(keyword):
                if (currentLoop != LoopType.WHILE) {
                    Lox.errorToken(keyword, "Can only break inside a loop");
                }

            case Return(keyword, expression):
                if (currentFunction == FunctionType.NONE) {
                    Lox.errorToken(keyword, "Can't return from top-level code");
                }

                if (expression != null) {
                    if (currentFunction == FunctionType.INITIALIZER) {
                        Lox.errorToken(keyword, "Can't return a value from an initializer");
                    }

                    resolveExpression(expression);
                }
        }
    }

    private function resolveExpression(expression:Expression) {
        switch (expression) {
            case Literal(_):

            case Get(object, name):
                resolveExpression(object);

            case Set(object, name, value):
                resolveExpression(object);
                resolveExpression(value);

            case Call(callee, _, arguments):
                resolveExpression(callee);

                for (argument in arguments)
                    resolveExpression(argument);
            
            case This(keyword):
                if (currentClass == ClassType.NONE) {
                    Lox.errorToken(keyword, "Can't use 'this' outside of a class");
                }

                resolveLocal(expression, keyword, true);

            case Super(keyword, method):
                switch (currentClass) {
                    case NONE:
                        Lox.errorToken(keyword, "Can't user 'super' outside of a class");
                    case CLASS:
                        Lox.errorToken(keyword, "Can't user 'super' in a class with no superclass");
                    case _:
                }

                resolveLocal(expression, keyword, true);

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
                if (!scopes.isEmpty()) {
                    var scopeVar = scopes.peek().get(name.lexeme);

                    if (scopeVar != null && scopeVar.defined == false) {
                        Lox.errorToken(name, "Can't read local variable in its own initializer");
                    }

                    
                }
                resolveLocal(expression, name, true);

            case Assignment(name, value):
                resolveExpression(value);
                resolveLocal(expression, name);
        }
    }

    private function resolveFunction(params:Array<Token>, body:Array<Statement>, type:FunctionType) {
        beginScope();
        for (param in params) {
            declare(param);
            define(param);
        }

        var enclosingLoop = currentLoop;
        var enclosingFunction = currentFunction;
        currentLoop = LoopType.NONE;
        currentFunction = type;
        resolve(body);
        currentLoop = enclosingLoop;
        currentFunction = enclosingFunction;

        endScope();
    }

    private function beginScope() {
        var scope = new Map();
        scopes.push(scope);
        return scope;
    }

    private function endScope() {
        var scope = scopes.pop();

        // Chapter 11 Challenge 3
        for (name => scopeVar in scope) {
            if (!scopeVar.used) {
                Lox.errorToken(scopeVar.token, 'Variable $name was not used');
            }
        }

        return scope;
    }

    private function declare(name:Token) {
        if (scopes.isEmpty()) return;

        var scope = scopes.peek();
        if (scope.exists(name.lexeme)) {
            Lox.errorToken(name, "Already a variable with this name in this scope");
        }

        scope.set(name.lexeme, {
            token: name,
            defined: false,
            used: false
        });
    }

    private function define(name:Token) {
        if (scopes.isEmpty()) return;
        scopes.peek().set(name.lexeme, {
            token: name,
            defined: true,
            used: false
        });
    }

    private function resolveLocal(expression:Expression, name:Token, use:Bool = false) {
        for (i => scope in scopes) {
            if (scope.exists(name.lexeme)) {
                if (use) {
                    var scopeVar = scope.get(name.lexeme);
                    scopeVar.used = true;
                }

                interpreter.resolve(expression, scopes.length - 1 - i);
                return;
            }
        }
    }
}

typedef ScopesT = Array<Map<String, { token:Token, defined:Bool, used:Bool }>>;

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

    public inline function keyValueIterator():KeyValueIterator<Int, Map<String, { defined:Bool, used:Bool }>> {
        var i = this.length - 1;

        return {
            hasNext: () -> i >= 0,
            next: () -> { key: i,  value: this[i >= 0 ? i-- : i] }
        }
    }
}

enum LoopType {
    NONE;
    WHILE;
}

enum FunctionType {
    NONE;
    FUNCTION;
    INITIALIZER;
    METHOD;
}

enum ClassType {
    NONE;
    CLASS;
    SUBCLASS;
}