package lox;

import lox.Interpreter.ReturnUnwind;

class Function implements Callable {
    private final name:Token;
    private final params:Array<Token>;
    private final body:Array<Statement>;
    private final closure:Environment;

    public function new(name:Token, params:Array<Token>, body:Array<Statement>, closure:Environment) {
        this.name = name;
        this.params = params;
        this.body = body;
        this.closure = closure;
    }

    public function arity() return params.length;

    public function call(interpreter:Interpreter, args:Array<Dynamic>):Dynamic {
        var environment = new Environment(closure);

        for (i in 0...params.length) {
            environment.define(params[i].lexeme, args[i]);
        }

        try {
            interpreter.executeBlock(body, environment);
        } catch (unwind:ReturnUnwind) {
            return unwind.value;
        }

        return null;
    }

    public function toString() return '<fn ${name.lexeme}>';
}