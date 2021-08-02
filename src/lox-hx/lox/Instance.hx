package lox;

import lox.Interpreter.RuntimeError;

class Instance {
    private final klass:Class;
    private final fields:Map<String, Dynamic> = new Map();

    public function new(klass:Class) {
        this.klass = klass;
    }

    public function get(name:Token) {
        if (fields.exists(name.lexeme)) {
            return fields.get(name.lexeme);
        }

        var method = klass.findMethod(name.lexeme);
        if (method != null) return method.bind(this);

        throw new RuntimeError(name, 'Undefined property ${name.lexeme}');
    }

    public function set(name:Token, value:Dynamic) {
        fields.set(name.lexeme, value);
    }

    public function toString() return '${klass.name} instance';
}