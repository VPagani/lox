package lox;

import lox.Interpreter.RuntimeError;

class Environment {
    private final values:Map<String, Null<Dynamic>> = [];

    public function new() {}

    public function get(name:Token):Dynamic {
        if (values.exists(name.lexeme)) {
            return values.get(name.lexeme);
        }

        throw new RuntimeError(name, 'Undefined variable \'${name.lexeme}\'');
    }

    public function assign(name:Token, value:Dynamic) {
        if (values.exists(name.lexeme)) {
            values.set(name.lexeme, value);
            return;
        }

        throw new RuntimeError(name, 'Undefined variable \'${name.lexeme}\'');
    }

    public function define(name:Token, ?value:Dynamic) {
        values.set(name.lexeme, value);
    }
}