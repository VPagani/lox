package lox;

interface Callable {
    function arity():Int;
    function call(interpreter:Interpreter, arguments:Array<Dynamic>):Dynamic;
}