%{

#include"symbol_info.h"

#define YYSTYPE symbol_info*

int yyparse(void);
int yylex(void);

extern FILE *yyin;


ofstream outlog;

int lines;

void yyerror(const char *s);
// declare any other variables or functions needed here

%}

%token IF ELSE FOR WHILE DO SWITCH CASE DEFAULT BREAK CONTINUE GOTO RETURN
%token INT CHAR DOUBLE VOID FLOAT PRINTF
%token ADDOP MULOP RELOP ASSIGNOP LOGICOP NOT
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD
%token COMMA SEMICOLON COLON
%token ID CONST_INT CONST_FLOAT
%token INCOP DECOP

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->getname()+"\n"+$2->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : program : unit "<<endl<<endl;
		outlog<<$1->getname()+"\n"<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"\n","program");
	}
	;

unit : var_declaration
	{
		outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
		$$ = new symbol_info($1->getname(),"unit");
	}
	| func_definition
	{
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		$$ = new symbol_info($1->getname(),"unit");
	}
	;

func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
		{	

		}
		| type_specifier ID LPAREN RPAREN compound_statement
		{
			
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"()\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"()\n"+$5->getname(),"func_def");	
		}
 		;

parameter_list : parameter_list COMMA type_specifier ID
	{
		outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
		$$ = new symbol_info($1->getname()+","+$3->getname()+" "+$4->getname(),"param_list");
	}
	| parameter_list COMMA type_specifier
	{
		outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
		$$ = new symbol_info($1->getname()+","+$3->getname(),"param_list");
	}
	| type_specifier ID
	{
		outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
		$$ = new symbol_info($1->getname()+" "+$2->getname(),"param_list");
	}
	| type_specifier
	{
		outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
		$$ = new symbol_info($1->getname(),"param_list");
	}
	;

compound_statement : LCURL statements RCURL
	{
		outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
		$$ = new symbol_info("{\n"+$2->getname()+"\n}","compound");
	}
	| LCURL RCURL
	{
		outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
		$$ = new symbol_info("{}","compound");
	}
	;

var_declaration : type_specifier declaration_list SEMICOLON
	{
		outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
		$$ = new symbol_info($1->getname()+" "+$2->getname()+";","var_decl");
	}
	;

type_specifier : INT
	{
		$$ = new symbol_info("int","type");
	}
	| FLOAT
	{
		$$ = new symbol_info("float","type");
	}
	| VOID
	{
		$$ = new symbol_info("void","type");
	}
	;

declaration_list : declaration_list COMMA ID
	{
		$$ = new symbol_info($1->getname()+","+$3->getname(),"decl_list");
	}
	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
	{
		$$ = new symbol_info($1->getname()+","+$3->getname()+"["+$5->getname()+"]","decl_list");
	}
	| ID
	{
		$$ = new symbol_info($1->getname(),"decl_list");
	}
	| ID LTHIRD CONST_INT RTHIRD
	{
		$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","decl_list");
	}
	;

statements : statement
	{
		$$ = new symbol_info($1->getname(),"stmnts");
	}
	| statements statement
	{
		$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"stmnts");
	}
	;

statement : var_declaration
	{
		$$ = new symbol_info($1->getname(),"stmnt");
	}
	| expression_statement
	{
		$$ = new symbol_info($1->getname(),"stmnt");
	}
	| compound_statement
	{
		$$ = new symbol_info($1->getname(),"stmnt");
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement
	{
		outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
		outlog<<"for("<<$3->getname()<<$4->getname()<<$5->getname()<<")\n"<<$7->getname()<<endl<<endl;
		$$ = new symbol_info("for("+$3->getname()+$4->getname()+$5->getname()+")\n"+$7->getname(),"stmnt");
	}
	| IF LPAREN expression RPAREN statement
	{
		$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname(),"stmnt");
	}
	| IF LPAREN expression RPAREN statement ELSE statement
	{
		$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname()+"else\n"+$7->getname(),"stmnt");
	}
	| WHILE LPAREN expression RPAREN statement
	{
		$$ = new symbol_info("while("+$3->getname()+")\n"+$5->getname(),"stmnt");
	}
	| PRINTF LPAREN ID RPAREN SEMICOLON
	{
		$$ = new symbol_info("printf("+$3->getname()+");","stmnt");
	}
	| RETURN expression SEMICOLON
	{
		$$ = new symbol_info("return "+$2->getname()+";","stmnt");
	}
	;

expression_statement : SEMICOLON
	{
		$$ = new symbol_info(";","expr_stmnt");
	}
	| expression SEMICOLON
	{
		$$ = new symbol_info($1->getname()+";","expr_stmnt");
	}
	;

variable : ID
	{
		$$ = new symbol_info($1->getname(),"var");
	}
	| ID LTHIRD expression RTHIRD
	{
		$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","var");
	}
	;

expression : logic_expression
	{
		$$ = new symbol_info($1->getname(),"expr");
	}
	| variable ASSIGNOP logic_expression
	{
		$$ = new symbol_info($1->getname()+"="+$3->getname(),"expr");
	}
	;

logic_expression : rel_expression
	{
		$$ = new symbol_info($1->getname(),"logic_expr");
	}
	| rel_expression LOGICOP rel_expression
	{
		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"logic_expr");
	}
	;

rel_expression : simple_expression
	{
		$$ = new symbol_info($1->getname(),"rel_expr");
	}
	| simple_expression RELOP simple_expression
	{
		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"rel_expr");
	}
	;

simple_expression : term
	{
		$$ = new symbol_info($1->getname(),"simp_expr");
	}
	| simple_expression ADDOP term
	{
		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"simp_expr");
	}
	;

term : unary_expression
	{
		$$ = new symbol_info($1->getname(),"term");
	}
	| term MULOP unary_expression
	{
		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"term");
	}
	;

unary_expression : ADDOP unary_expression
	{
		$$ = new symbol_info($1->getname()+$2->getname(),"unary_expr");
	}
	| NOT unary_expression
	{
		$$ = new symbol_info("!"+$2->getname(),"unary_expr");
	}
	| factor
	{
		$$ = new symbol_info($1->getname(),"unary_expr");
	}
	;

factor : variable
	{
		$$ = new symbol_info($1->getname(),"factor");
	}
	| ID LPAREN argument_list RPAREN
	{
		$$ = new symbol_info($1->getname()+"("+$3->getname()+")","factor");
	}
	| LPAREN expression RPAREN
	{
		$$ = new symbol_info("("+$2->getname()+")","factor");
	}
	| CONST_INT
	{
		$$ = new symbol_info($1->getname(),"factor");
	}
	| CONST_FLOAT
	{
		$$ = new symbol_info($1->getname(),"factor");
	}
	| variable INCOP
	{
		$$ = new symbol_info($1->getname()+"++","factor");
	}
	| variable DECOP
	{
		$$ = new symbol_info($1->getname()+"--","factor");
	}
	;

argument_list : arguments
	{
		$$ = new symbol_info($1->getname(),"arg_list");
	}
	|
	{
		$$ = new symbol_info("","arg_list");
	}
	;

arguments : arguments COMMA logic_expression
	{
		$$ = new symbol_info($1->getname()+","+$3->getname(),"args");
	}
	| logic_expression
	{
		$$ = new symbol_info($1->getname(),"args");
	}
	;

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
        cout << "Please provide an input file name as argument." << endl;
        return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("my_log2.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
    
	yyparse();
	
	cout << "Total lines: " << lines << endl;
	outlog << "Total lines: " << lines << endl;
	
	outlog.close();
	
	fclose(yyin);
	
	return 0;
}