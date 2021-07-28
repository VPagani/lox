import sys.io.File;

import lox.Scanner;

class Lox {
    static var hadError:Bool = false;

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

        for (token in tokens)
            Sys.println(token);
    }

    public static function error(line:Int, message:String) {
        report(line, "", message);
    }

    public static function report(line:Int, where:String, message:String) {
        Sys.println('[line $line] Error $where: $message');
        hadError = true;
    }
}