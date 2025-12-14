# CSE420 Lab 2 - Syntax Analyzer with Symbol Table

## Comprehensive Viva Guide

In case anyone needs it, here is my Lab 3 recording from previous semester :
https://youtu.be/fJLSXqBfzEs?si=nf_FQ0UAaTHw0S8W

---

## Project Overview

This project implements a **syntax analyzer (parser)** for a C-like programming language using **Yacc/Bison** and **Flex/Lex**. The parser not only checks syntactic correctness but also builds and manages a **symbol table** with proper scope handling.

### Key Components:

1. **Lexical Analyzer** (`lex_analyzer.l`) - Tokenizes input
2. **Syntax Analyzer** (`syntax_analyzer.y`) - Parses tokens and builds symbol table
3. **Symbol Table** (`symbol_table.h`) - Manages scopes and symbols
4. **Scope Table** (`scope_table.h`) - Individual scope with hash table
5. **Symbol Info** (`symbol_info.h`) - Stores symbol information

---

## 1. Architecture & Design

### 1.1 Symbol Information Structure

**File**: `symbol_info.h`

```cpp
class symbol_info {
    string name;              // Symbol name (e.g., "x", "func")
    string type;              // Data type (e.g., "int", "float", "void")
    symbol_type symbolType;   // VARIABLE, ARRAY, or FUNCTION
    list<symbol_info*> parameters;  // For functions
    int arraySize;            // For arrays
}
```

**Symbol Types**:

- **VARIABLE**: Regular variables (e.g., `int x;`)
- **ARRAY**: Array variables (e.g., `int arr[10];`)
- **FUNCTION**: Function definitions (e.g., `int func(int a);`)

### 1.2 Scope Table Structure

**File**: `scope_table.h`

```cpp
class scope_table {
    int bucket_count;              // Hash table size (10 in our case)
    int unique_id;                 // Scope identifier
    scope_table *parent_scope;     // Link to parent scope
    vector<list<symbol_info*>> table;  // Hash table (chaining)
}
```

**Hash Function**:

```cpp
int hash_function(string name) {
    int hash_val = 0;
    for (char c : name) {
        if (c >= 'a' && c <= 'z')
            hash_val += (c - 'a' + 1);
        else if (c >= 'A' && c <= 'Z')
            hash_val += (c - 'A' + 1);
        else
            hash_val += c;
    }
    return hash_val % bucket_count;
}
```

**Operations**:

- `insert_in_scope()` - Insert symbol in current scope
- `lookup_in_scope()` - Search symbol in current scope only
- `delete_from_scope()` - Remove symbol from scope
- `print_scope_table()` - Display scope contents

### 1.3 Symbol Table Structure

**File**: `symbol_table.h`

```cpp
class symbol_table {
    scope_table *current_scope;  // Active scope
    int bucket_count;            // Passed to each scope
    int current_scope_id;        // Counter for scope IDs
}
```

**Key Operations**:

- `enter_scope()` - Create new nested scope
- `exit_scope()` - Remove current scope, return to parent
- `insert()` - Add symbol to current scope
- `lookup()` - Search symbol in all scopes (current → parent)
- `print_all_scopes()` - Print all scopes in hierarchy

---

## 2. Lexical Analyzer (lex_analyzer.l)

### 2.1 Token Categories

**Keywords** (Return specific tokens):

```
if, else, for, while, do, break, continue, return
int, float, char, void, double
switch, case, default
printf → PRINTLN
```

**Operators** (Create symbol_info objects):

```c
"+", "-"              → ADDOP
"*", "/", "%"         → MULOP
"++", "--"            → INCOP, DECOP
"<", ">", "<=", etc.  → RELOP
"="                   → ASSIGNOP
"&&", "||"            → LOGICOP
"!"                   → NOT
```

**Delimiters**:

```
"(", ")"  → LPAREN, RPAREN
"{", "}"  → LCURL, RCURL
"[", "]"  → LTHIRD, RTHIRD
";", ","  → SEMICOLON, COMMA
```

**Identifiers & Constants**:

```c
{id}       → ID (letter_ followed by letter_/digit)
{integers} → CONST_INT
{floats}   → CONST_FLOAT (supports scientific notation)
```

### 2.2 Sample Lex Rules

```c
{id}  {
    symbol_info *s = new symbol_info((string)yytext, "ID", symbol_type::VARIABLE);
    yylval = (YYSTYPE)s;
    return ID;
}

"+"  {
    symbol_info *s = new symbol_info((string)yytext, "ADDOP", symbol_type::VARIABLE);
    yylval = (YYSTYPE)s;
    return ADDOP;
}
```

---

## 3. Syntax Analyzer (syntax_analyzer.y)

### 3.1 Global Variables

```cpp
symbol_table* sym_table;           // Main symbol table
int lines = 1;                     // Line counter
ofstream outlog;                   // Output log file
string current_var_type;           // Tracks current variable type
stack<symbol_info*> fn_name;       // Function info during parsing
```

### 3.2 Helper Functions

**addSymbol()**: Creates new symbol_info object

```cpp
symbol_info* addSymbol(string name, string type, symbol_type symType,
                       int arrSize = 0, list<symbol_info*> params = {});
```

**enterFn()**: Handles function definition start

```cpp
void enterFn(string name, string return_type) {
    fn_name.push(addSymbol(name, return_type, symbol_type::FUNCTION));
    sym_table->insert(fn_name.top());  // Insert in parent scope
    sym_table->enter_scope();          // Enter function body scope
}
```

**exitScopeDecl()**: Handles scope exit

```cpp
void exitScopeDecl() {
    sym_table->print_all_scopes(outlog);  // Print before exit
    sym_table->exit_scope();               // Remove current scope
}
```

### 3.3 Grammar Rules Overview

**Program Structure**:

```yacc
start → program
program → program unit | unit
unit → var_declaration | func_definition
```

**Function Definition**:

```yacc
func_definition :
    type_specifier ID LPAREN {enterFn(...)} parameter_list RPAREN
    {print scope message} compound_statement
    {
        exitScopeDecl();
        fn_name.pop();
        // Print function definition message
    }
```

**Variable Declaration**:

```yacc
var_declaration : type_specifier declaration_list SEMICOLON

declaration_list :
    declaration_list COMMA ID              // Regular variable
  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD  // Array
  | ID                                      // First variable
  | ID LTHIRD CONST_INT RTHIRD             // First array
```

**Type Specifier**:

```yacc
type_specifier : INT | FLOAT | VOID
    {
        current_var_type = "int"/"float"/"void";
    }
```

**Parameter List**:

```yacc
parameter_list :
    parameter_list COMMA type_specifier ID
    {
        fn_name.top()->add_parameter(...);
        sym_table->insert(...);  // Insert in function scope
    }
  | type_specifier ID
```

**Expressions**:

```yacc
expression → variable ASSIGNOP logic_expression | logic_expression
logic_expression → rel_expression LOGICOP rel_expression | rel_expression
rel_expression → simple_expression RELOP simple_expression | simple_expression
simple_expression → simple_expression ADDOP term | term
term → term MULOP unary_expression | unary_expression
unary_expression → ADDOP unary_expression | NOT unary_expression | factor
factor → variable | ID(arguments) | (expression) | CONST_INT | CONST_FLOAT | variable INCOP/DECOP
```

**Statements**:

```yacc
statement :
    var_declaration
  | expression_statement
  | compound_statement
  | FOR (expr_stmt expr_stmt expr) statement
  | IF (expr) statement
  | IF (expr) statement ELSE statement
  | WHILE (expr) statement
  | RETURN expression ;
  | PRINTLN (ID) ;
```

---

## 4. Symbol Table Management

### 4.1 Scope Hierarchy

```
Global Scope (ID: 1)
├── func1 (Function in global)
│   └── Scope (ID: 2) for func1 body
│       ├── param1 (Function parameter)
│       ├── param2 (Function parameter)
│       └── local_var (Local variable)
└── main (Function in global)
    └── Scope (ID: 3) for main body
        ├── var1
        └── array1[10]
```

### 4.2 Symbol Insertion Logic

**Variables**:

```cpp
// In declaration_list rule
sym_table->insert(addSymbol(name, current_var_type, symbol_type::VARIABLE));
```

**Arrays**:

```cpp
// In declaration_list with array
sym_table->insert(addSymbol(name, current_var_type, symbol_type::ARRAY, size));
```

**Functions**:

```cpp
// In enterFn() - before entering function body scope
fn_name.push(addSymbol(name, return_type, symbol_type::FUNCTION));
sym_table->insert(fn_name.top());  // Insert in current (parent) scope
sym_table->enter_scope();          // Then enter function body scope
```

**Function Parameters**:

```cpp
// In parameter_list rules
fn_name.top()->add_parameter(addSymbol(name, type, symbol_type::VARIABLE));
sym_table->insert(addSymbol(name, type, symbol_type::VARIABLE));
// Parameters are inserted in function body scope
```

### 4.3 Scope Creation & Destruction

**Creation**:

1. **Global scope**: Created in `main()` before parsing

   ```cpp
   sym_table = new symbol_table(10);  // 10 buckets
   ```

2. **Function scope**: Created in `enterFn()`
   ```cpp
   outlog << "New ScopeTable with ID " << scope_id << " created\n";
   sym_table->enter_scope();
   ```

**Destruction**:

```cpp
void exit_scope() {
    int id = current_scope->get_unique_id();
    scope_table *temp = current_scope;
    current_scope = current_scope->get_parent_scope();
    delete temp;
    outlog << "Scopetable with ID " << id << " removed\n";
}
```

---

## 5. Output Format

### 5.1 Parse Tree Output

For each grammar rule reduction:

```
At line no: X <rule_name> : <production>

<parsed_content>
```

Example:

```
At line no: 1 type_specifier : INT

int

At line no: 1 parameter_list : type_specifier ID

int a
```

### 5.2 Symbol Table Output

```
ScopeTable # <ID>
<bucket_number> -->
< <symbol_name> : ID >
<symbol_category>
Type: <data_type>
[Additional info for arrays/functions]

```

**Example for Variable**:

```
ScopeTable # 2
1 -->
< x : ID >
Variable
Type: int

```

**Example for Array**:

```
6 -->
< arr : ID >
Array
Type: int
Size: 10

```

**Example for Function**:

```
4 -->
< func : ID >
Function Definition
Return Type: int
Number of Parameters: 2
Parameter Details: int a, float b

```

### 5.3 Scope Messages

**Creation**:

```
New ScopeTable with ID 2 created
```

**Destruction**:

```
Scopetable with ID 2 removed
```

---

## 6. Compilation & Execution

### 6.1 Build Process

**Script** (`script.sh`):

```bash
#!/bin/bash

# Generate parser
yacc -d -y --debug --verbose syntax_analyzer.y
g++ -w -c -o y.o y.tab.c

# Generate scanner
flex lex_analyzer.l
g++ -fpermissive -w -c -o l.o lex.yy.c

# Link
g++ y.o l.o -o parser

# Run
./parser input.c
```

**Generated Files**:

- `y.tab.c` - Parser C code
- `y.tab.h` - Token definitions
- `y.output` - Parser state machine (for debugging)
- `lex.yy.c` - Scanner C code
- `a.out` or `parser` - Executable

### 6.2 Manual Compilation

```bash
# Step 1: Generate parser
yacc -d -y --debug --verbose syntax_analyzer.y

# Step 2: Compile parser
g++ -w -c -o y.o y.tab.c

# Step 3: Generate scanner
flex lex_analyzer.l

# Step 4: Compile scanner
g++ -fpermissive -w -c -o l.o lex.yy.c

# Step 5: Link
g++ y.o l.o

# Step 6: Run
./a.out input.c
```

### 6.3 Output Files

- `my_log.txt` - Complete parse log with symbol tables
- Console output - Summary or errors

---

## 7. Example Walkthrough

### 7.1 Input Code

```c
int func(int a, float b) {
    return a+b;
}

void main() {
    int x, y[10];
    x = 5;
}
```

### 7.2 Processing Steps

**Step 1**: Global scope created

```
New ScopeTable with ID 1 created
```

**Step 2**: Parse `int func(int a, float b)`

- Type specifier: INT → `current_var_type = "int"`
- Function name: func
- Enter function: `enterFn("func", "int")`
  - Creates symbol_info for func with return type "int"
  - Inserts func into scope 1 (global)
  - Creates scope 2 (function body)
  - Message: `New ScopeTable with ID 2 created`
- Parse parameters:
  - `int a`: Add to func's parameter list, insert in scope 2
  - `float b`: Add to func's parameter list, insert in scope 2

**Step 3**: Parse function body `{ return a+b; }`

- Parses return statement
- Prints scope 2 contents (shows parameters a, b)
- Exits scope 2: `exitScopeDecl()`
  - Prints all scopes
  - Removes scope 2
  - Message: `Scopetable with ID 2 removed`
- Prints function definition reduction

**Step 4**: Parse `void main() { ... }`

- Similar process for main function
- Creates scope 3
- Parses variable declarations inside main
- Exits scope 3

**Step 5**: End of program

- Prints final symbol table (scope 1 with func and main)
- Reports total lines

### 7.3 Key Scope Timing

**Important**: Function is inserted in **parent scope** BEFORE entering function body scope.

```
Global Scope (1)
  ↓ Insert func here
  ├─ func: Function
  │   ↓ Now enter scope 2
  │   Scope (2) - func body
  │     ├─ a: Variable (parameter)
  │     └─ b: Variable (parameter)
```

This ensures:

1. Function is visible in the correct scope
2. Parameters are local to function
3. Scope hierarchy is correct

---

## 8. Common Viva Questions & Answers

### Q1: What is the difference between syntax analysis and lexical analysis?

**Answer**:

- **Lexical Analysis** breaks input into tokens (identifiers, keywords, operators)
- **Syntax Analysis** checks if token sequence follows grammar rules and builds parse tree
- **Example**:
  - Lexer: "int x = 5;" → [INT, ID(x), ASSIGNOP, CONST_INT(5), SEMICOLON]
  - Parser: Checks if this follows variable declaration grammar

### Q2: Why use a hash table for scope tables?

**Answer**:

- **Fast lookup**: O(1) average case instead of O(n) for linear search
- **Efficient insertion**: O(1) average case
- **Suitable for symbol tables**: Symbols are accessed frequently during compilation
- We use **chaining** to handle collisions

### Q3: Explain your hash function.

**Answer**:

```cpp
hash_value = sum of (letter_position or ASCII_value) % bucket_count
```

- For letters: a/A=1, b/B=2, ..., z/Z=26
- For other characters: ASCII value
- Modulo ensures index fits in bucket range (0-9)
- **Example**: "func" → f(6)+u(21)+n(14)+c(3) = 44 % 10 = 4

### Q4: Why do we need multiple scopes?

**Answer**:

1. **Name hiding**: Local variables can have same name as global ones
2. **Lifetime management**: Local variables exist only in their scope
3. **Name resolution**: Search order (current → parent → ... → global)
4. **Avoid naming conflicts**: Different functions can use same variable names

**Example**:

```c
int x = 10;  // Global x

void func() {
    int x = 20;  // Local x (hides global)
    // Uses local x here
}
// Global x still accessible here
```

### Q5: How do you handle function parameters?

**Answer**:

1. **During parsing**: Parameters parsed in `parameter_list` rules
2. **Storage**: Added to function's parameter list
3. **Scope**: Inserted into function **body scope** (not parent scope)
4. **Timing**: Function inserted in parent BEFORE entering body scope
5. **Access**: Parameters treated as local variables in function body

### Q6: Explain the difference between lookup_in_scope and lookup.

**Answer**:

- **lookup_in_scope()**: Searches only in current scope

  - Used when checking for redeclaration in same scope
  - Returns NULL if not found

- **lookup()**: Searches current scope, then parent, then grandparent, etc.
  - Used when using a variable (need to find it anywhere accessible)
  - Implements scope hierarchy

### Q7: What happens when you exit a scope?

**Answer**:

1. Print current scope contents (for logging)
2. Remove current scope from hierarchy
3. Deallocate scope memory (and all symbols in it)
4. Set parent scope as current scope
5. Log the removal message

**Memory management**: Scope destructor deletes all symbols in that scope.

### Q8: Why are some productions epsilon (empty)?

**Answer**:

- **Flexibility**: Allows optional elements
- **Examples**:
  - `argument_list → ε` allows `func()` with no arguments
  - `parameter_list → ε` allows function with no parameters
  - `statements → ε` allows empty compound statements `{}`

### Q9: Explain shift-reduce conflicts and how you resolved them.

**Answer**:

- **Dangling else problem**:

  ```
  IF (expr) IF (expr) stmt ELSE stmt
  ```

  Does ELSE match inner or outer IF?

- **Solution**: Precedence declarations
  ```yacc
  %nonassoc LOWER_THAN_ELSE
  %nonassoc ELSE
  ```
  - ELSE has higher precedence → binds to nearest IF
  - Solves shift-reduce conflict

### Q10: How do you differentiate between arrays and variables?

**Answer**:

- **Storage**: Both stored as symbol_info objects
- **Differentiation**: `symbol_type` enum (VARIABLE vs ARRAY)
- **Array specifics**:
  - `arraySize` stores size
  - `is_array()` method checks type
- **Declaration**:
  - Variable: `int x;` → symbolType = VARIABLE
  - Array: `int x[10];` → symbolType = ARRAY, arraySize = 10

### Q11: What is YYSTYPE and why is it set to symbol_info\*?

**Answer**:

- **YYSTYPE**: Type of semantic values ($1, $2, $$, etc.)
- **Setting**: `#define YYSTYPE symbol_info*`
- **Purpose**: All grammar symbols carry symbol_info objects
- **Usage**: Allows passing symbol information through grammar rules
- **Example**:
  ```yacc
  expression : variable ASSIGNOP logic_expression
      { $$ = new symbol_info($1->get_name() + "=" + $3->get_name(), ...); }
  ```

### Q12: How does the parser know the line number?

**Answer**:

- **Global variable**: `int lines = 1;`
- **Updated in lexer**:
  ```lex
  {newline}  { lines++; }
  ```
- **Used in parser**: Error messages and logging
- **Accessible**: Declared `extern` in parser allows lexer to modify it

### Q13: Why use stack for function names?

**Answer**:

- **Nested functions**: Theoretically allows parsing nested function definitions
- **Current context**: `fn_name.top()` always refers to function being defined
- **Parameter association**: Parameters know which function they belong to
- **Cleanup**: `fn_name.pop()` after function completes
- **Note**: Current grammar doesn't allow nested functions, but stack provides flexibility

### Q14: Explain the order: insert function, enter scope, add parameters.

**Answer**:

1. **Insert function** in parent scope first

   - Makes function visible at correct level
   - Function can call itself (recursion)

2. **Enter new scope** for function body

   - Creates local namespace

3. **Add parameters** to function
   - Parameters are local to function
   - Stored in function's scope AND in function's parameter list

**Why this order?**:

- Function must exist before its body
- Parameters are part of function but local to its body

### Q15: How would you add semantic analysis to this parser?

**Answer**:
**Type Checking**:

```cpp
// In expression rule
if ($1->get_type() != $3->get_type()) {
    yyerror("Type mismatch in assignment");
}
```

**Undeclared Variable Check**:

```cpp
// When using variable
if (sym_table->lookup($1) == NULL) {
    yyerror("Undeclared variable");
}
```

**Function Call Validation**:

```cpp
// Check parameter count and types
symbol_info* func = sym_table->lookup(func_name);
if (func->get_parameters().size() != arg_count) {
    yyerror("Wrong number of arguments");
}
```

---

## 9. Error Handling

### 9.1 Yacc Error Function

```cpp
void yyerror(char *s) {
    outlog << "At line " << lines << " " << s << endl;
    // Could reinitialize variables if needed
}
```

### 9.2 Common Errors

**Syntax Errors**:

- Missing semicolons
- Unmatched braces
- Invalid expressions

**Semantic Errors** (not fully implemented):

- Undeclared variables
- Type mismatches
- Redeclaration in same scope

### 9.3 Recovery Strategy

- **Panic mode**: Skip tokens until synchronization point (;, }, etc.)
- **Phrase level**: Make local corrections
- **Error productions**: Define grammar rules for common errors

---

## 10. Testing Strategy

### 10.1 Test Cases

**Basic**:

```c
int x;
float y;
int arr[10];
```

**Functions**:

```c
int add(int a, int b) {
    return a + b;
}
```

**Nested Scopes**:

```c
void main() {
    int x;
    {
        int y;  // Nested block
    }
}
```

**Complex Expressions**:

```c
result = (a + b) * c - d / e;
```

### 10.2 Validation

1. **Parse log**: Check grammar rule reductions
2. **Symbol table**: Verify symbols in correct scopes
3. **Scope messages**: Confirm creation/destruction order
4. **Line numbers**: Ensure accurate tracking
5. **Hash distribution**: Check symbols distributed across buckets

---

## 11. Advanced Topics

### 11.1 Optimizations

**Hash Table**:

- Adjust bucket count based on expected symbol count
- Use better hash function (e.g., polynomial rolling hash)

**Memory**:

- Use smart pointers instead of raw pointers
- Implement memory pool for symbol allocation

**Performance**:

- Cache recent lookups
- Use unordered_map instead of custom hash table

### 11.2 Extensions

**Additional Features**:

1. **Structures/Classes**: New symbol type
2. **Pointers**: Track pointer types
3. **Type checking**: Full semantic analysis
4. **Forward declarations**: Separate declaration from definition
5. **Namespaces**: Additional scope level

### 11.3 Symbol Table Variations

**Alternative Data Structures**:

1. **Red-Black Tree**: O(log n) guaranteed
2. **Trie**: For identifier lookup
3. **Skip List**: Probabilistic balanced structure

---

## 12. Debugging Tips

### 12.1 Common Issues

**Segmentation Fault**:

- Check NULL pointers before dereferencing
- Ensure symbol_table initialized before use
- Verify stack not empty before `top()` or `pop()`

**Incorrect Scope**:

- Print scope ID at each insertion
- Trace enter_scope/exit_scope calls
- Verify parent pointers

**Missing Symbols**:

- Check if insert succeeds (returns true/false)
- Verify lookup searches all scopes
- Ensure hash function distributes evenly

### 12.2 Debug Output

```cpp
// Add debug prints
void symbol_table::insert(symbol_info* symbol) {
    cerr << "DEBUG: Inserting " << symbol->get_name()
         << " in scope " << current_scope->get_unique_id() << endl;
    // ... actual insertion
}
```

### 12.3 Yacc Debugging

```bash
# Generate parser with debug info
yacc -d -y --debug --verbose syntax_analyzer.y

# Enable debug output at runtime
export YYDEBUG=1
./parser input.c
```

---

## 13. Key Takeaways for Viva

### Must Know:

1. ✅ **Overall architecture**: Lexer → Parser → Symbol Table
2. ✅ **Scope hierarchy**: How scopes nest and when they're created/destroyed
3. ✅ **Symbol categories**: Variable, Array, Function
4. ✅ **Hash table**: Why used, how collision handled
5. ✅ **Function handling**: Insert in parent, parameters in child scope
6. ✅ **Grammar structure**: Major non-terminals and productions
7. ✅ **Symbol lookup**: Current scope → parent → ... → global
8. ✅ **Output format**: Parse tree and symbol table format

### Be Prepared to:

1. 🔧 **Trace execution**: Given input, show scope creation/symbols
2. 🔧 **Explain code**: Any function in your implementation
3. 🔧 **Modify grammar**: Add new rule or feature
4. 🔧 **Debug**: Identify problem from error output
5. 🔧 **Compare**: Lex vs Yacc, different parsing methods
6. 🔧 **Extend**: How to add new features

### Confidence Builders:

- Run multiple test cases and understand output
- Trace one example completely by hand
- Explain your hash function clearly
- Know why each helper function exists
- Understand scope timing (when created/destroyed)

---

## 14. Quick Reference

### File Structure:

```
lab2/
├── lex_analyzer.l          # Lexical analyzer
├── syntax_analyzer.y        # Parser with symbol table
├── symbol_info.h            # Symbol information
├── scope_table.h            # Single scope (hash table)
├── symbol_table.h           # Scope manager
├── script.sh                # Build script
├── input*.c                 # Test inputs
└── my_log.txt              # Output log
```

### Build Commands:

```bash
yacc -d -y --debug --verbose syntax_analyzer.y
g++ -w -c -o y.o y.tab.c
flex lex_analyzer.l
g++ -fpermissive -w -c -o l.o lex.yy.c
g++ y.o l.o
./a.out input.c
```

### Important Concepts:

- **LR Parsing**: Bottom-up, shift-reduce
- **LALR**: Look-Ahead LR (Yacc uses this)
- **Semantic Action**: Code in { } after grammar rule
- **Mid-rule Action**: Action in middle of production
- **Symbol Attribute**: Information attached to grammar symbol ($1, $2, etc.)
- **Synthesized Attribute**: Computed from children ($$)
- **Scope**: Visibility region for identifiers
- **Collision Resolution**: Chaining in hash table

---

## Good Luck with Your Viva! 🎓

**Remember**:

- Understand the **concepts**, not just memorize code
- Be able to **trace** execution with examples
- Know **why** design decisions were made
- Practice **explaining** to someone else

**Final Tip**: If asked something you don't know, explain your thought process. Examiners value understanding over memorization!
