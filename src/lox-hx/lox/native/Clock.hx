package lox.native;

class Clock implements Callable {
    public function new() {}

    public function arity() return 0;

    public function call(interpreter:Interpreter, arguments:Array<Dynamic>)
        return Sys.time();

    public function toString() return "<native fn>";
}