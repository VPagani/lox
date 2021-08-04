# Name of the project
BIN=./bin/lox

# .c files
C_SOURCE=$(wildcard ./src/lox-c/**.c)

# .h files
H_SOURCE=$(wildcard ./src/lox-c/**.h)

# Object files
OBJ=$(C_SOURCE:.c=.o)

# Compiler
CC=zig cc

# Compiler flags
CC_FLAGS=-c -W -Wall -ansi -pedantic

all: build run

$(BIN): $(C_SOURCE)
	@ $(CC) -o $@ $^

build: $(BIN)

run:
	@ $(BIN)

clean:
	@ rm $(BIN)


.PHONY: all clean run