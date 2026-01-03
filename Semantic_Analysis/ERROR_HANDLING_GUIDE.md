# Error Handling in Semantic Analysis Compiler

## Overview

The syntax analyzer (`syntax_analyzer.y`) implements comprehensive error handling at the semantic analysis phase. Errors are detected and logged during parsing and semantic checks.

---

## 1. **Parse Errors (yyerror function)**

### Location: Lines 37-44

```c
void yyerror(char *s)
{
    // Log parse errors to both log and error files
    outlog << "At line " << lines << " " << s << endl << endl;
    if (errlog.is_open()) {
        errlog << "At line " << lines << " " << s << endl;
        error_count++;
    }
}
```

### What it handles:

- **Syntax errors** from the parser (yacc/bison)
- **Grammar rule violations** that don't match the defined syntax
- Examples: missing semicolons, mismatched parentheses, invalid statements

### How it works:

1. Captures the error message `s` from yacc
2. Logs to both `outlog` (detailed log) and `errlog` (error file)
3. Increments global `error_count`
4. Records the current line number

---

## 2. **Variable Declaration Errors**

### Location: Lines 45-85 (insert_variables_from_declaration function)

### Errors Detected:

#### **Multiple Declaration Error**

```c
if(!st->insert(var_symbol)) {
    if(errlog.is_open()) {
        errlog<<"At line "<<lines<<" Error: Multiple declaration of '"<<var_name<<"' in the same scope"<<endl;
        error_count++;
    }
}
```

**When it occurs:**

- Variable declared twice in the same scope
- Arrays with same name declared multiple times

**Example:**

```c
int x, x;  // Error: x declared twice
int arr[10], arr[5];  // Error: arr declared twice
```

---

## 3. **Variable Usage Errors**

### Location: Lines 420-473 (variable rule)

### Errors Detected:

#### **3.1 Undeclared Variable**

```c
symbol_info* sym = st->lookup(temp);
if(sym == NULL) {
    errlog<<"At line "<<lines<<" Error: Variable '"<<$1->getname()<<"' used without declaration"<<endl;
    error_count++;
}
```

**When it occurs:**

- Variable used but never declared

**Example:**

```c
int x = y;  // Error: y is not declared
```

#### **3.2 Array Without Index**

```c
if(sym->is_array()) {
    errlog<<"At line "<<lines<<" Error: Array '"<<$1->getname()<<"' used without index"<<endl;
    error_count++;
}
```

**When it occurs:**

- Array name used without subscript operator `[]`

**Example:**

```c
int arr[10];
x = arr;  // Error: array used without index
```

#### **3.3 Non-Array Subscripted**

```c
if(!sym->is_array()) {
    errlog<<"At line "<<lines<<" Error: Subscripted value '"<<$1->getname()<<"' is not an array"<<endl;
    error_count++;
}
```

**When it occurs:**

- Subscript operator applied to non-array variable

**Example:**

```c
int x = 5;
y = x[0];  // Error: x is not an array
```

#### **3.4 Non-Integer Array Index**

```c
if($3->get_data_type() != "int") {
    errlog<<"At line "<<lines<<" Error: Array index for '"<<$1->getname()<<"' is not an integer"<<endl;
    error_count++;
}
```

**When it occurs:**

- Array index is float or non-integer type

**Example:**

```c
int arr[10];
x = arr[3.5];  // Error: float index not allowed
```

---

## 4. **Type Assignment Errors**

### Location: Lines 558-574 (expression rule)

### Errors Detected:

#### **4.1 Void Assignment**

```c
if(rtype == "void") {
    errlog<<"At line "<<lines<<" Error: Cannot assign result of void function to variable '"<<$1->getname()<<"'"<<endl;
    error_count++;
}
```

**When it occurs:**

- Assigning return value of void function

**Example:**

```c
int x = printf();  // Error: printf returns void
```

#### **4.2 Float to Int with Warning**

```c
else if(ltype == "int" && rtype == "float") {
    errlog<<"At line "<<lines<<" Warning: Assigning float to int variable '"<<$1->getname()<<"' may lose precision"<<endl;
    error_count++;
}
```

**When it occurs:**

- Assigning float to int variable (precision loss)

**Example:**

```c
int x = 3.14;  // Warning: 3.14 becomes 3
```

#### **4.3 Type Mismatch**

```c
else if(ltype != "" && rtype != "" && ltype != rtype) {
    if(!(ltype == "float" && rtype == "int")) {  // int->float is allowed
        errlog<<"At line "<<lines<<" Error: Type mismatch in assignment to '"<<$1->getname()<<"'"<<endl;
        error_count++;
    }
}
```

**When it occurs:**

- Incompatible types in assignment
- Exception: `int` can be assigned to `float`

**Example:**

```c
float x = 5;  // OK: int to float allowed
int y = 3.14; // WARNING: float to int, precision loss
char z = 5;   // Error: int to char not allowed
```

---

## 5. **Arithmetic Operation Errors**

### Location: Lines 677-710 (term rule)

### Errors Detected:

#### **5.1 Modulus on Non-Integers**

```c
if(op == "%") {
    if($1->get_data_type() != "int" || $3->get_data_type() != "int") {
        errlog<<"At line "<<lines<<" Error: Modulus operator requires integer operands"<<endl;
        error_count++;
    }
}
```

**When it occurs:**

- Modulus operator `%` used with float operands

**Example:**

```c
float x = 5.5;
int y = x % 2;  // Error: modulus needs integers
```

#### **5.2 Division by Zero**

```c
if(op == "/") {
    if($3->getname() == "0" || $3->getname() == "0.0") {
        errlog<<"At line "<<lines<<" Error: Division by zero"<<endl;
        error_count++;
    }
}
```

**When it occurs:**

- Division by constant zero (literal `0` or `0.0`)

**Example:**

```c
int x = 10 / 0;  // Error: division by zero
```

#### **5.3 Modulus by Zero**

```c
if($3->getname() == "0") {
    errlog<<"At line "<<lines<<" Error: Modulus by zero"<<endl;
    error_count++;
}
```

**When it occurs:**

- Modulus operation with divisor = 0

**Example:**

```c
int x = 10 % 0;  // Error: modulus by zero
```

---

## 6. **Function Errors**

### Location: Lines 773-821 (factor rule - function call)

### Errors Detected:

#### **6.1 Undeclared Function**

```c
if(func == NULL) {
    errlog<<"At line "<<lines<<" Error: Function '"<<$1->getname()<<"' is not declared"<<endl;
    error_count++;
}
```

**When it occurs:**

- Function called but not defined

**Example:**

```c
int x = foo();  // Error: foo is not declared
```

#### **6.2 Non-Function Call**

```c
if(!func->is_function()) {
    errlog<<"At line "<<lines<<" Error: '"<<$1->getname()<<"' is not a function"<<endl;
    error_count++;
}
```

**When it occurs:**

- Trying to call a variable like a function

**Example:**

```c
int x = 5;
y = x();  // Error: x is not a function
```

#### **6.3 Incorrect Number of Arguments**

```c
if(func->get_param_count() != (int)call_arg_types.size()) {
    errlog<<"At line "<<lines<<" Error: Function '"<<$1->getname()<<"' called with incorrect number of arguments"<<endl;
    error_count++;
}
```

**When it occurs:**

- Function called with wrong number of arguments

**Example:**

```c
int foo(int x, float y) { ... }
int z = foo(5);  // Error: expecting 2 arguments, got 1
```

#### **6.4 Parameter Type Mismatch**

```c
for(int i=0;i<ftypes.size();i++) {
    if(ftypes[i] != call_arg_types[i]) {
        errlog<<"At line "<<lines<<" Error: Type mismatch for parameter "<<i+1<<" in call to '"<<$1->getname()<<"'"<<endl;
        error_count++;
        break;
    }
}
```

**When it occurs:**

- Function argument types don't match parameter types

**Example:**

```c
int foo(int x) { ... }
int z = foo(3.14);  // Error: float passed for int parameter
```

---

## 7. **Error Logging and Reporting**

### Files Used:

1. **24241309_log.txt** - Detailed parsing log (all productions)
2. **24241309_error.txt** - Error summary file

### Location: Lines 825-838 (main function)

```c
outlog.open("24241309_log.txt", ios::trunc);
outerror.open("24241309_error.txt", ios::trunc);

// ... parsing happens ...

outlog<<endl<<"Total lines: "<<lines<<endl;
outlog<<"Total errors: "<<error_count<<endl;
outerror<<"Total errors: "<<error_count<<endl;
```

### Summary Information:

- **Total lines**: Number of lines parsed
- **Total errors**: Count of all semantic errors detected

---

## 8. **Type Propagation and Inference**

### Key Methods:

- `set_data_type(string type)` - Set variable/expression type
- `get_data_type()` - Retrieve type information

### Logic Rules:

1. **Constants**: Int literals → `int`, Float literals → `float`
2. **Variables**: Type from symbol table lookup
3. **Operations**:
   - Arithmetic: `float` if any operand is `float`, else `int`
   - Relational/Logical: Always `int` (0 or 1)
   - Modulus: Requires and produces `int`

---

## 9. **How to Use/Test**

### Compile:

```bash
flex lex_analyzer.l
bison syntax_analyzer.y
gcc -c symbol_table.h
gcc -c scope_table.h
g++ -o two_pass_compiler lex.yy.c y.tab.c -lfl
```

### Run:

```bash
./two_pass_compiler input.c
```

### Check Results:

```bash
cat 24241309_log.txt      # Detailed production log
cat 24241309_error.txt    # Error summary
```

---

## Summary Table

| Error Type            | Where Detected                        | Severity | Condition                             |
| --------------------- | ------------------------------------- | -------- | ------------------------------------- |
| Parse Error           | `yyerror()`                           | Critical | Grammar violation                     |
| Multiple Declaration  | `insert_variables_from_declaration()` | Critical | Duplicate in scope                    |
| Undeclared Variable   | `variable` rule                       | Critical | Variable used without declaration     |
| Array Without Index   | `variable` rule                       | Critical | Array name without `[]`               |
| Non-Array Subscripted | `variable` rule                       | Critical | `[]` applied to non-array             |
| Non-Integer Index     | `variable` rule                       | Critical | Array index is not `int`              |
| Void Assignment       | `expression` rule                     | Critical | Assigning void function result        |
| Type Mismatch         | `expression` rule                     | Critical | Incompatible types (except int↔float) |
| Float to Int          | `expression` rule                     | Warning  | Precision loss possibility            |
| Modulus Non-Int       | `term` rule                           | Critical | `%` with float operands               |
| Division by Zero      | `term` rule                           | Critical | `/` by constant 0                     |
| Modulus by Zero       | `term` rule                           | Critical | `%` by 0                              |
| Undeclared Function   | `factor` rule                         | Critical | Function used without definition      |
| Non-Function Call     | `factor` rule                         | Critical | Variable called like function         |
| Wrong Arg Count       | `factor` rule                         | Critical | Function call arg count mismatch      |
| Arg Type Mismatch     | `factor` rule                         | Critical | Function arg types don't match        |
