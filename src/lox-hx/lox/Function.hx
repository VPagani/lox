package lox;

import lox.Interpreter.ReturnUnwind;

class Function implements Callable {
    private final name:Token;
    private final params:Array<Token>;
    private final body:Array<Statement>;
    private final closure:Environment;
    private final isInitializer:Bool;

    public function new(name:Token, params:Array<Token>, body:Array<Statement>, closure:Environment, isInitializer:Bool = false) {
        this.name = name;
        this.params = params;
        this.body = body;
        this.closure = closure;
        this.isInitializer = isInitializer;
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
            if (isInitializer) return closure.getAt(0, "this");

            return unwind.value;
        }

        if (isInitializer) return closure.getAt(0, "this");

        return null;
    }

    public function bind(instance:Instance) {
        var environment = new Environment(closure);
        environment.define("this", instance);
        return new Function(name, params, body, environment, isInitializer);
    }

    public function toString() return '<fn ${name.lexeme}>';
}