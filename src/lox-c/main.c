#include "common.h"
#include "chunk.h"
#include "debug.h"

int main(int argc, const char* argv[]) {
    Chunk chunk;
    initChunk(&chunk);

    writeChunk(&chunk, OP_CONSTANT, 123);
    writeChunk(&chunk, addConstant(&chunk, 1.2), 123);

    writeChunk(&chunk, OP_RETURN, 123);

    writeChunk(&chunk, OP_CONSTANT, 124);
    writeChunk(&chunk, addConstant(&chunk, 1.8), 124);

    writeChunk(&chunk, OP_RETURN, 124);

    disassembleChunk(&chunk, "test chunk");
    freeChunk(&chunk);
}