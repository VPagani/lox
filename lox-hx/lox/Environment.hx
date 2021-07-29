package lox;

import lox.Interpreter.RuntimeError;

class Environment {
    final enclosing:Null<Environment>;
    private final values:Map<String, Null<Dynamic>> = [];

    public function new(?enclosing:Environment) {
        this.enclosing = enclosing;
    }

    public function get(name:Token):Dynamic {
        if (values.exists(name.lexeme)) {
            return values.get(name.lexeme);
        }

        if (enclosing != null)
            return enclosing.get(name);

        throw new RuntimeError(name, 'Undefined variable \'${name.lexeme}\'');
    }

    public function assign(name:Token, value:Dynamic) {
        if (values.exists(name.lexeme)) {
            values.set(name.lexeme, value);
            return;
        }

        if (enclosing != null) {
            enclosing.assign(name, value);
            return;
        }

        throw new RuntimeError(name, 'Undefined variable \'${name.lexeme}\'');
    }

    public function define(name:Token, ?value:Dynamic) {
        values.set(name.lexeme, value);
    }
}