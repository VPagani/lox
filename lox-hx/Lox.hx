import sys.io.File;

import lox.Scanner;
import lox.Parser;
import lox.Interpreter;

using lox.Expression.AstPrinter;

class Lox {
    static final interpreter:Interpreter = new Interpreter();

    static var hadError:Bool = false;
    static var hadRuntimeError:Bool = false;

    public static function main():Void {
        var args = Sys.args();

        if (args.length > 1) {
            Sys.println("Usage: lox [script]");
            Sys.exit(64);
        } else if (args.length == 1) {
            runFile(args[0]);
        } else {
            runPrompt();
        }
    }

    private static function runFile(path:String):Void {
        var content = File.getContent(path);
        run(content);
        if (hadError) Sys.exit(65);
        if (hadRuntimeError) Sys.exit(70);
    }

    private static function runPrompt() {
        var stdin = Sys.stdin();
        
        try while (true) {
            Sys.print("> ");
            var line = stdin.readLine();
            run(line);
            hadError = false;
        } catch (e:haxe.io.Eof) {}
    }

    private static function run(source:String) {
        var scanner = new Scanner(source);
        var tokens = scanner.scanTokens();
        var parser = new Parser(tokens);
        var expression = parser.parse();
    
        if (hadError) return;

        interpreter.interpret(expression);
    }

    public static function report(line:Int, where:String, message:String) {
        Sys.println('[line $line] Error $where: $message');
        hadError = true;
    }

    public static function error(line:Int, message:String) {
        report(line, "", message);
    }

    public static function errorToken(token:lox.Token, message:String) {
        if (token.type == lox.TokenType.EOF) {
            report(token.line, " at end", message);
        } else {
            report(token.line, ' at \'${token.lexeme}\'', message);
        }
    }

    public static function runtimeError(error:lox.Interpreter.RuntimeError) {
        Sys.println('[line ${error.token.line}] ${error.message}');
        hadRuntimeError = true;
    }
}