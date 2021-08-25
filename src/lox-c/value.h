#ifndef clox_value_h
#define clox_value_h

#include "common.h"

typedef enum {
    VAL_NIL,
    VAL_BOOL,
    VAL_NUMBER,
} ValueType;

typedef struct {
    ValueType type;
    union {
        bool boolean;
        double number;
    } as;
} Value;

#define IS_NIL(value)     ((value).type == VAL_NIL)
#define IS_BOOL(value)    ((value).type == VAL_BOOL)
#define IS_NUMBER(value)  ((value).type == VAL_NUMBER)

#define AS_BOOL(value)    ((value).as.boolean)
#define AS_NUMBER(value)  ((value).as.number)

#define NIL_VAL           ((Value) {VAL_NIL, {.number = 0}})
#define BOOL_VAL(value)   ((Value) {VAL_BOOL, {.boolean = value}})
#define NUMBER_VAL(value) ((Value) {VAL_NUMBER, {.number = value}})

typedef struct {
    int count;
    int capacity;
    Value* values;
} ValueArray;

bool valuesEqual(Value a, Value b);
void initValueArray(ValueArray* array);
void writeValueArray(ValueArray* array, Value value);
void freeValueArray(ValueArray* array);

void printValue(Value value);

#endif