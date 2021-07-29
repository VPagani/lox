package lox;

class Error {
    public final message:String;

    public function new(message:String) {
        this.message = message;
    }
}