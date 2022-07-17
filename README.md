# Lox Programming Language

A dynamic toy programming language implemented twice from scratch in Haxe ([./src/lox-hx](./src/lox-hx)) and C ([./src/lox-c](./src/lox-c)) based on the book [Crafting Interpreters](https://craftinginterpreters.com/) by [Robert Nystrom](https://twitter.com/munificentbob)

## Examples

### Hello World
```lox
print "hello world";
```

### Variables and Expressions
```lox
var a = 1;
print a = 2; // Prints "2"

a = 5;
var b = 6;
print a = a + b; // Prints "11"
```

### Functions

```lox
fun factorial(n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

print factorial(8); // Prints "40320"
```

### Classes
```lox
class CoffeeMaker {
  init(coffee) {
    this.coffee = coffee;
  }

  brew() {
    print "Enjoy your cup of " + this.coffee;

    // No reusing the grounds!
    this.coffee = nil;
  }
}

var maker = CoffeeMaker("coffee and chicory");
maker.brew(); // Prints "Enjoy your cup of coffee and chicory"
```

### Inheritance

```lox
class Doughnut {
  cook() {
    print "Fry until golden brown.";
  }
}

class BostonCream < Doughnut {
  cook() {
    super.cook();
    print "Pipe full of custard and coat with chocolate.";
  }
}

BostonCream().cook();
```
