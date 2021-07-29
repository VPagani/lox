package lox;

using StringTools;

class Interpreter {
    public function new() {}

    public function interpret(expr:Expression) {
        try {
            var value = evaluate(expr);
            Sys.println(stringify(value));
        } catch (error:RuntimeError) {
            Lox.runtimeError(error);
        }
    }

    private function evaluate(expr:Expression):Dynamic {
        return switch (expr) {
            case Literal(value): value;

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
                        checkNumberOperands(op, left, right);
                        return left / right;
                    case STAR:
                        checkNumberOperands(op, left, right);
                        return left * right;

                    case _: throw new RuntimeError(op, 'Invalid binary operator ${op.lexeme}');
                }

            case Ternary(first, op1, second, op2, third):
                var first = evaluate(first);

                switch (op1.type) {
                    case QUESTION: isTruthy(first) ? evaluate(second) : evaluate(third);
                    case _: throw new RuntimeError(op1, "Invalid ternary operator");
                }

            case Grouping(expression): evaluate(expression);
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
}

class RuntimeError extends Error {
    public final token:Token;

    public function new(token:Token, message:String) {
        super(message);

        this.token = token;
    }
}