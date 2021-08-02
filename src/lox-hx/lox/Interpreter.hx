package lox;

using StringTools;

class Interpreter {
    public final globals = new Environment();
    private var environment:Environment;
    public final locals:Map<Expression, Int> = new Map();

    public function new() {
        environment = globals;
        globals.define("clock", new lox.native.Clock());
    }

    public function interpret(statements:Array<Statement>) {
        try {
            for (statement in statements) {
                execute(statement);
            }
        } catch (error:RuntimeError) {
            Lox.runtimeError(error);
        } catch (e) {
            Lox.error(0, e.stack.toString());
        }
    }

    // Chapter 8 Challenge 1
    public function interpretExpression(expression:Expression) {
        try {
            var value = evaluate(expression);
            Sys.println(stringify(value));
        } catch (error:RuntimeError) {
            Lox.runtimeError(error);
        }
    }

    @:allow(lox.Resolver.resolveLocal)
    private function resolve(expression:Expression, depth:Int) {
        locals.set(expression, depth);
    }

    private function execute(stmt:Statement) {
        switch (stmt) {
            case Expr(expression):
                evaluate(expression);

            case Print(expression):
                var value = evaluate(expression);
                Sys.println(stringify(value));

            case Block(statements):
                return executeBlock(statements, new Environment(environment));

            case VarDecl(name, initializer):
                var value = null;

                if (initializer != null) {
                    value = evaluate(initializer);
                }

                environment.define(name.lexeme, value);

            case Function(name, params, body):
                var func = new Function(name, params, body, environment);
                environment.define(name.lexeme, func);

            case Class(name, superclassExpression, methods):
                var superclass = null;
                if (superclassExpression != null) {
                    switch (superclassExpression) {
                        case Variable(name):
                            superclass = evaluate(superclassExpression);
                            if (!Std.isOfType(superclass, Class)) {
                                throw new RuntimeError(name, "Superclass must be a class");
                            }
                        
                        case _:
                    }
                }

                environment.define(name.lexeme, null);

                if (superclass != null) {
                    environment = new Environment(environment);
                    environment.define("super", superclass);
                }

                var methods_ = new Map();
                for (method in methods) {
                    switch (method) {
                        case Function(name, params, body):
                            var isInit = name.lexeme == "init";
                            var func = new Function(name, params, body, environment, isInit);
                            methods_.set(name.lexeme, func);

                        case _:
                    }
                }

                if (superclass != null) {
                    environment = environment.enclosing;
                }

                var klass = new Class(name.lexeme, cast(superclass, Null<Class>), methods_);
                environment.assign(name, klass);

            case If(condition, thenBranch, elseBranch):
                if (isTruthy(evaluate(condition))) {
                    execute(thenBranch);
                } else if (elseBranch != null) {
                    execute(elseBranch);
                }

            case While(condition, body):
                while (isTruthy(evaluate(condition))) {
                    try {
                        execute(body);
                    } catch (e:BreakUnwind) {
                        break;
                    }
                }
            
            case Break(_): throw new BreakUnwind();

            case Return(_, expression):
                var value = expression != null ? evaluate(expression) : null;

                throw new ReturnUnwind(value);
        }

        return false;
    }

    @:allow(lox.Function.call)
    private function executeBlock(stmts:Array<Statement>, environment:Environment) {
        var previous = this.environment;
        var broke = false;

        try {
            this.environment = environment;

            for (stmt in stmts) {
                execute(stmt);
            }
        } catch (error) {
            this.environment = previous;
            throw error;
        }
        
        this.environment = previous;
        return broke;
    }

    private function evaluate(expr:Expression):Dynamic {
        return switch (expr) {
            case Literal(value): value;

            case Get(object, name):
                var object = evaluate(object);
                if (Std.isOfType(object, Instance)) {
                    return cast(object, Instance).get(name);
                }

                throw new RuntimeError(name, "Only instances have properties");

            case Set(object, name, value):
                var object = evaluate(object);

                if (!Std.isOfType(object, Instance)) {
                    throw new RuntimeError(name, "Only instances have fields");
                }

                var value = evaluate(value);
                cast(object, Instance).set(name, value);
                return value;

            case Call(callee, paren, arguments):
                var callee = evaluate(callee);
                var func = cast(callee, Callable);

                if (arguments.length != func.arity()) {
                    throw new RuntimeError(paren, 'Expected ${func.arity()} arguments but got ${arguments.length}');
                }

                if (!Std.isOfType(callee, Callable)) {
                    throw new RuntimeError(paren, "Can only call functions and classes");
                }

                return func.call(this, arguments.map(evaluate));

            case This(keyword):
                lookUpVariable(keyword, expr);

            case Super(keyword, methodToken):
                var distance = locals.get(expr);
                var superclass = cast(environment.getAt(distance, "super"), Class);
                var instance = cast(environment.getAt(distance - 1, "this"), Instance);
                var method = superclass.findMethod(methodToken.lexeme);

                if (method == null) {
                    throw new RuntimeError(methodToken, 'Undefined property ${methodToken.lexeme}');
                }

                return method.bind(instance);

            case Unary(op, right):
                var right = evaluate(right);
                return switch (op.type) {
                    case BANG: !isTruthy(right);
                    case MINUS:
                        checkNumberOperand(op, right);
                        return -right;
                    case _: throw 'Invalid unary operator \'${op.lexeme}\'';
                }

            case Binary(left, op, right):
                var left:Dynamic = evaluate(left);
                var right:Dynamic = evaluate(right);

                switch (op.type) {
                    case COMMA:
                        return right;

                    // equality
                    case EQUAL_EQUAL: isEqual(left, right);
                    case BANG_EQUAL: !isEqual(left, right);

                    // comparison
                    case GREATER:
                        checkNumberOperands(op, left, right);
                        return left > right;

                    case GREATER_EQUAL:
                        checkNumberOperands(op, left, right);
                        return left >= right;

                    case LESS:
                        checkNumberOperands(op, left, right);
                        return left < right;

                    case LESS_EQUAL:
                        checkNumberOperands(op, left, right);
                        return left <= right;

                    // term
                    case MINUS:
                        checkNumberOperands(op, left, right);
                        return left - right;

                    case PLUS:
                        if (Std.isOfType(left, Float) && Std.isOfType(right, Float)) {
                            return left + right;
                        }

                        // Chapter 7 Challenge 2
                        if (Std.isOfType(left, String) || Std.isOfType(right, String)) {
                            return '${Std.string(left)}${Std.string(right)}';
                        }

                        throw new RuntimeError(op, 'Operands must be two numbers or one string');

                    // factor
                    case SLASH:
                        if (right == 0)
                            throw new RuntimeError(op, 'Cannot divide by 0');

                        checkNumberOperands(op, left, right);
                        return left / right;
                    case STAR:
                        checkNumberOperands(op, left, right);
                        return left * right;

                    case _: throw new RuntimeError(op, 'Invalid binary operator ${op.lexeme}');
                }

            case Logical(left, op, right):
                var left = evaluate(left);

                switch (op.type) {
                    case OR if (isTruthy(left)): return left;
                    case AND if (!isTruthy(left)): return left;
                    case _:
                        return evaluate(right);
                }

            case Ternary(first, op1, second, op2, third):
                var first = evaluate(first);

                switch (op1.type) {
                    case QUESTION: isTruthy(first) ? evaluate(second) : evaluate(third);
                    case _: throw new RuntimeError(op1, "Invalid ternary operator");
                }

            case Grouping(expression): evaluate(expression);

            case Variable(name):
                lookUpVariable(name, expr);

            case Assignment(name, value):
                var value = evaluate(value);
                var distance = locals.get(expr);

                if (distance != null) {
                    environment.assignAt(distance, name, value);
                } else {
                    globals.assign(name, value);
                }

                return value;
        }
    }

    private function checkNumberOperand(op:Token, operand:Dynamic) {
        if (Std.isOfType(operand, Float)) return;
        throw new RuntimeError(op, "Operand must be a number");
    }

    private function checkNumberOperands(op:Token, left:Dynamic, right:Dynamic) {
        if (Std.isOfType(left, Float) && Std.isOfType(right, Float)) return;
        throw new RuntimeError(op, "Operands must be numbers");
    }

    private function isTruthy(value:Dynamic) {
        if (value == null || value == false) return false;
        return true;
    }
    
    private function isEqual(a:Dynamic, b:Dynamic) {
        if (a == null) return b == null;
        return a == b;
    }

    private function stringify(value:Dynamic) {
        if (value == null) return "nil";

        if (Std.isOfType(value, Float)) {
            var text = Std.string(value);

            if (text.endsWith(".0")) {
                text = text.substring(0, text.length - 2);
            }

            return text;
        }

        return Std.string(value);
    }

    private function lookUpVariable(name:Token, expression:Expression) {
        var distance = locals.get(expression);

        if (distance != null) {
            return environment.getAt(distance, name.lexeme);
        }

        return globals.get(name);
    }
}

class RuntimeError extends haxe.Exception {
    public final token:Token;

    public function new(token:Token, message:String) {
        super(message);

        this.token = token;
    }
}

class BreakUnwind {
    public function new() {}
}

class ReturnUnwind {
    public final value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
    }
}
