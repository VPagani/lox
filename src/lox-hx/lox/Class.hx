package lox;

class Class implements Callable {
    public final name:String;
    public final superclass:Null<Class>;
    private final methods:Map<String, Function> = new Map();

    public function new(name:String, ?superclass: Class, methods:Map<String, Function>) {
        this.name = name;
        this.superclass = superclass;
        this.methods = methods;
    }

    public function arity() {
        var initializer = findMethod("init");
        return initializer != null ? initializer.arity() : 0;
    }

    public function call(interpreter:Interpreter, arguments:Array<Dynamic>) {
        var instance = new Instance(this);
        var initializer = findMethod("init");

        if (initializer != null) {
            initializer.bind(instance).call(interpreter, arguments);
        }

        return instance;
    }

    public function findMethod(name:String) {
        if (methods.exists(name)) {
            return methods.get(name);
        }

        if (superclass != null) {
            return superclass.findMethod(name);
        }

        return null;
    }

    public function toString() {
        return name;
    }
}