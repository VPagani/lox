package lox;

import lox.Interpreter.RuntimeError;

var undefined = {};

class Environment {
    final enclosing:Null<Environment>;
    private final values:Map<String, Null<Dynamic>> = [];

    public function new(?enclosing:Environment) {
        this.enclosing = enclosing;
    }

    public function get(name:Token):Dynamic {
        if (values.exists(name.lexeme)) {
            var value = values.get(name.lexeme);
            
            // Chapter 8 Challenge 2
            if (value != undefined)
                return value;

            throw new RuntimeError(name, 'Uninitialized variable \'${name.lexeme}\'');
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

    public function define(name:String, ?value:Dynamic) {
        values.set(name, (value != null) ? value : undefined);
    }

    public function ancestor(distance:Int) {
        var environment = this;
        for (i in 0...distance) {
            environment = environment.enclosing;
        }
        return environment;
    }

    public function getAt(distance:Int, name:String)
        return ancestor(distance).values.get(name);

    public function assignAt(distance:Int, name:Token, value:Dynamic)
        ancestor(distance).values.set(name.lexeme, value);
}