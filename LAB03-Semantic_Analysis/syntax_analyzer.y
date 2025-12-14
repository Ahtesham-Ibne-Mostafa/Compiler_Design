%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

int lines = 1;

ofstream outlog;
ofstream errlog;

// Global symbol table
symbol_table* st;

// Variables to store current context information
string current_var_type = "";
vector<string> var_names;
vector<int> array_sizes;

// Function context variables
string current_func_name = "";
string current_return_type = "";
vector<string> param_types;
vector<string> param_names;

// For function call argument type collection during parsing
vector<string> call_arg_types;

// Error tracking
int error_count = 0;

void yyerror(char *s)
{
	// Log parse errors to both log and error files
	outlog << "At line " << lines << " " << s << endl << endl;
	if (errlog.is_open()) {
		errlog << "At line " << lines << " " << s << endl;
		error_count++;
	}
}
// Helper function to parse declaration list and insert variables
void insert_variables_from_declaration(string type_name, string declaration_list) {
    // Split declaration_list by commas and process each variable
    stringstream ss(declaration_list);
    string item;
    
    while(getline(ss, item, ',')) {
        // Remove leading/trailing whitespace
        size_t start = item.find_first_not_of(" \t");
        size_t end = item.find_last_not_of(" \t");
        if(start == string::npos) continue;
        item = item.substr(start, end - start + 1);
        
        // Check if it's an array
        size_t bracket_pos = item.find('[');
        if(bracket_pos != string::npos) {
            // Array variable
            string var_name = item.substr(0, bracket_pos);
            size_t close_bracket = item.find(']');
            string size_str = item.substr(bracket_pos + 1, close_bracket - bracket_pos - 1);
            int array_size = stoi(size_str);
            
			symbol_info* var_symbol = new symbol_info(var_name, "ID");
			var_symbol->set_data_type(type_name);
			var_symbol->set_array_size(array_size);
			if(!st->insert(var_symbol)) {
				if(errlog.is_open()) {
					errlog<<"At line "<<lines<<" Error: Multiple declaration of '"<<var_name<<"' in the same scope"<<endl;
					error_count++;
				}
			}
        } else {
            // Regular variable
			symbol_info* var_symbol = new symbol_info(item, "ID");
			var_symbol->set_data_type(type_name);
			if(!st->insert(var_symbol)) {
				if(errlog.is_open()) {
					errlog<<"At line "<<lines<<" Error: Multiple declaration of '"<<item<<"' in the same scope"<<endl;
					error_count++;
				}
			}
        }
    }
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		
		// Print your whole symbol table here
		st->print_all_scopes(outlog);
		
		$$= new symbol_info("","start");
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
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"program");
	}
	;

unit : var_declaration
	 {
		outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN {
		// Insert function in symbol table first
		current_func_name = $2->getname();
		current_return_type = $1->getname();
		
		symbol_info* func_symbol = new symbol_info($2->getname(), "ID");
		func_symbol->set_return_type($1->getname());
		
		// Add parameters to function symbol
		for(int i = 0; i < param_types.size(); i++) {
			func_symbol->add_parameter(param_types[i], param_names[i]);
		}
		
		st->insert(func_symbol);
		
		// Enter new scope for function body
		st->enter_scope(outlog);
		
		// Insert parameters into the new scope
		for(int i = 0; i < param_types.size(); i++) {
			if(!param_names[i].empty()) {
				symbol_info* param_symbol = new symbol_info(param_names[i], "ID");
				param_symbol->set_data_type(param_types[i]);
				st->insert(param_symbol);
			}
		}
	} compound_statement
		{	
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"("+$4->getname()+")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"("+$4->getname()+")\n"+$7->getname(),"func_def");	
			
			// Clear function context
			current_func_name = "";
			current_return_type = "";
			param_types.clear();
			param_names.clear();
		}
		| type_specifier ID LPAREN RPAREN {
			// Insert function in symbol table
			current_func_name = $2->getname();
			current_return_type = $1->getname();
			
			symbol_info* func_symbol = new symbol_info($2->getname(), "ID");
			func_symbol->set_return_type($1->getname());
			func_symbol->set_param_count(0);
			st->insert(func_symbol);
			
			// Enter new scope for function body
			st->enter_scope(outlog);
		} compound_statement
		{
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"()\n"<<$6->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"()\n"+$6->getname(),"func_def");	
			
			// Clear function context
			current_func_name = "";
			current_return_type = "";
		}
 		;

parameter_list : parameter_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<" "<<$4->getname()<<endl<<endl;
					
			$$ = new symbol_info($1->getname()+","+$3->getname()+" "+$4->getname(),"param_list");
			
            // store the necessary information about the function parameters
			param_types.push_back($3->getname());
			param_names.push_back($4->getname());
		}
		| parameter_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+","+$3->getname(),"param_list");
			
			// Store parameter information (unnamed parameter)
			param_types.push_back($3->getname());
			param_names.push_back("");
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname(),"param_list");

			// Store parameter information
			param_types.push_back($1->getname());
			param_names.push_back($2->getname());
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"param_list");
			// Store parameter information (unnamed parameter)
			param_types.push_back($1->getname());
			param_names.push_back("");
		}
 		;

compound_statement
    : LCURL statements RCURL
      {
          // Enter new scope for every compound statement (AFTER full reduction)
          st->enter_scope(outlog);

          outlog << "At line no: " << lines 
                 << " compound_statement : LCURL statements RCURL " << endl << endl;
          outlog << "{\n" << $2->getname() << "\n}" << endl << endl;

          $$ = new symbol_info("{\n" + $2->getname() + "\n}", "comp_stmnt");

          // Exit scope and print symbol table
          st->exit_scope(outlog);
      }

    | LCURL RCURL
      {
          // Enter new scope for empty compound statement (AFTER full reduction)
          st->enter_scope(outlog);

          outlog << "At line no: " << lines 
                 << " compound_statement : LCURL RCURL " << endl << endl;
          outlog << "{\n}" << endl << endl;

          $$ = new symbol_info("{\n}", "comp_stmnt");

          // Exit scope and print symbol table
          st->exit_scope(outlog);
      }
;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<";"<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+";","var_dec");
			
			// Insert necessary information about the variables in the symbol table
			insert_variables_from_declaration($1->getname(), $2->getname());
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;
			
			$$ = new symbol_info("int","type");
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;
			
			$$ = new symbol_info("float","type");
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;
			
			$$ = new symbol_info("void","type");
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	outlog<<$1->getname()+","<<$3->getname()<<endl<<endl;

			$$ = new symbol_info($1->getname()+","+$3->getname(),"decl_list");
 		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	outlog<<$1->getname()+","<<$3->getname()<<"["<<$5->getname()<<"]"<<endl<<endl;

            $$ = new symbol_info($1->getname()+","+$3->getname()+"["+$5->getname()+"]","decl_list");
			
 		  }
 		  |ID
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;

            $$ = new symbol_info($1->getname(),"decl_list");
			
 		  }
 		  | ID LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;

            $$ = new symbol_info($1->getname()+"["+$3->getname()+"]","decl_list");
            
 		  }
 		  ;
 		  

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->getname()<<"\n"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"stmnts");
	   }
	   ;
	   
statement : var_declaration
	  {
	    	outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->getname()<<endl<<endl;

            $$ = new symbol_info($1->getname(),"stmnt");
	  		
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->getname()<<$4->getname()<<$5->getname()<<")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("for("+$3->getname()+$4->getname()+$5->getname()+")\n"+$7->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<"\nelse\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname()+"\nelse\n"+$7->getname(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("while("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->getname()<<");"<<endl<<endl; 
			
			$$ = new symbol_info("printf("+$3->getname()+");","stmnt");
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->getname()<<";"<<endl<<endl;
			
			$$ = new symbol_info("return "+$2->getname()+";","stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$ = new symbol_info(";","expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->getname()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->getname()+";","expr_stmt");
	        }
			;
	  
variable : ID 	
	  {
		outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
        
		// Lookup variable in symbol table
		symbol_info* temp = new symbol_info($1->getname(), "ID");
		symbol_info* sym = st->lookup(temp);
		delete temp;

		$$ = new symbol_info($1->getname(),"varbl");
		if(sym == NULL) {
			if(errlog.is_open()) { errlog<<"At line "<<lines<<" Error: Variable '"<<$1->getname()<<"' used without declaration"<<endl; error_count++; }
		} else {
			// propagate data type
			$$->set_data_type(sym->get_data_type());
			if(sym->is_array()) {
				if(errlog.is_open()) { errlog<<"At line "<<lines<<" Error: Array '"<<$1->getname()<<"' used without index"<<endl; error_count++; }
			}
		}
	 } 	
	 | ID LTHIRD expression RTHIRD 
	 {
		outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;
    
		// Lookup variable and validate array usage
		symbol_info* temp = new symbol_info($1->getname(), "ID");
		symbol_info* sym = st->lookup(temp);
		delete temp;

		$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","varbl");
		if(sym == NULL) {
			if(errlog.is_open()) { errlog<<"At line "<<lines<<" Error: Variable '"<<$1->getname()<<"' used without declaration"<<endl; error_count++; }
		} else {
			if(!sym->is_array()) {
				if(errlog.is_open()) { errlog<<"At line "<<lines<<" Error: Subscripted value '"<<$1->getname()<<"' is not an array"<<endl; error_count++; }
			}
			// index must be integer
			if($3->get_data_type() != "int") {
				if(errlog.is_open()) { errlog<<"At line "<<lines<<" Error: Array index for '"<<$1->getname()<<"' is not an integer"<<endl; error_count++; }
			}
			// element type
			$$->set_data_type(sym->get_data_type());
		}
	}
	 ;
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"expr");
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<"="<<$3->getname()<<endl<<endl;

		// Type checking for assignment
		string ltype = $1->get_data_type();
		string rtype = $3->get_data_type();
		if(rtype == "void") {
			if(errlog.is_open()) { errlog<<"At line "<<lines<<" Error: Cannot assign result of void function to variable '"<<$1->getname()<<"'"<<endl; error_count++; }
		} else if(ltype == "int" && rtype == "float") {
			if(errlog.is_open()) { errlog<<"At line "<<lines<<" Warning: Assigning float to int variable '"<<$1->getname()<<"' may lose precision"<<endl; error_count++; }
		} else if(ltype != "" && rtype != "" && ltype != rtype) {
			// allow int->float assignment
			if(!(ltype == "float" && rtype == "int")) {
				if(errlog.is_open()) { errlog<<"At line "<<lines<<" Error: Type mismatch in assignment to '"<<$1->getname()<<"'"<<endl; error_count++; }
			}
		}

		$$ = new symbol_info($1->getname()+"="+$3->getname(),"expr");
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"lgc_expr");
		// logical expression results are integers (0 or 1)
		$$->set_data_type("int");
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"lgc_expr");
		$$->set_data_type("int");
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"rel_expr");
		$$->set_data_type($1->get_data_type());
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"rel_expr");
		// relational operators produce integer result
		$$->set_data_type("int");
	    }
		;
				
simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"simp_expr");
		$$->set_data_type($1->get_data_type());
			
	      }
		  | simple_expression ADDOP term 
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
		
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"simp_expr");
			// result type for add/sub: float if any operand is float
			if($1->get_data_type() == "float" || $3->get_data_type() == "float") {
				$$->set_data_type("float");
			} else {
				$$->set_data_type("int");
			}
	      }
		  ;
					
term :	unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"term");
	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"term");
		string op = $2->getname();
		// division or multiplication result type: float if any operand float
		if(op == "%") {
			// modulus: both operands must be integers
			if($1->get_data_type() != "int" || $3->get_data_type() != "int") {
				if(errlog.is_open()) { errlog<<"At line "<<lines<<" Error: Modulus operator requires integer operands"<<endl; error_count++; }
			}
			// check divisor zero if constant
			if($3->getname() == "0") {
				if(errlog.is_open()) { errlog<<"At line "<<lines<<" Error: Modulus by zero"<<endl; error_count++; }
			}
			$$->set_data_type("int");
		} else if(op == "/") {
			if($3->getname() == "0" || $3->getname() == "0.0") {
				if(errlog.is_open()) { errlog<<"At line "<<lines<<" Error: Division by zero"<<endl; error_count++; }
			}
			if($1->get_data_type() == "float" || $3->get_data_type() == "float") $$->set_data_type("float");
			else $$->set_data_type("int");
		} else {
			// multiplication
			if($1->get_data_type() == "float" || $3->get_data_type() == "float") $$->set_data_type("float");
			else $$->set_data_type("int");
		}
	 }
     ;

unary_expression : ADDOP unary_expression
		 {
	    outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
		outlog<<$1->getname()<<$2->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+$2->getname(),"un_expr");
		// type of unary + or - is the type of operand
		$$->set_data_type($2->get_data_type());
	     }
		 | NOT unary_expression 
		 {
	    outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
		outlog<<"!"<<$2->getname()<<endl<<endl;
		
		$$ = new symbol_info("!"+$2->getname(),"un_expr");
		// logical NOT produces integer (0 or 1)
		$$->set_data_type("int");
	     }
		 | factor 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"un_expr");
		$$->set_data_type($1->get_data_type());
	     }
		 ;
	
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"fctr");
		// propagate variable type
		$$->set_data_type($1->get_data_type());
	}
	| ID LPAREN { call_arg_types.clear(); } argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->getname()<<"("<<$4->getname()<<")"<<endl<<endl;

		// Function call checks
		symbol_info* temp = new symbol_info($1->getname(), "ID");
		symbol_info* func = st->lookup(temp);
		delete temp;
		
		if(func == NULL) {
			if(errlog.is_open()) {
				errlog<<"At line "<<lines<<" Error: Function '"<<$1->getname()<<"' is not declared"<<endl;
				error_count++;
			}
		} else {
			if(!func->is_function()) {
				if(errlog.is_open()) {
					errlog<<"At line "<<lines<<" Error: '"<<$1->getname()<<"' is not a function"<<endl;
					error_count++;
				}
			} else {
				// check number of parameters
				if(func->get_param_count() != (int)call_arg_types.size()) {
					if(errlog.is_open()) {
						errlog<<"At line "<<lines<<" Error: Function '"<<$1->getname()<<"' called with incorrect number of arguments"<<endl;
						error_count++;
					}
				} else {
					// check parameter types
					vector<string> ftypes = func->get_param_types();
					for(int i=0;i<ftypes.size();i++) {
						if(ftypes[i] != call_arg_types[i]) {
							if(errlog.is_open()) {
								errlog<<"At line "<<lines<<" Error: Type mismatch for parameter "<<i+1<<" in call to '"<<$1->getname()<<"'"<<endl;
								error_count++;
							}
							break;
						}
					}
				}
			}
		}

		$$ = new symbol_info($1->getname()+"("+$4->getname()+")","fctr");
		if(func != NULL) $$->set_data_type(func->get_return_type());
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->getname()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->getname()+")","fctr");
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_data_type("int");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_data_type("float");
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->getname()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"++","fctr");
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->getname()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"--","fctr");
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->getname()<<endl<<endl;
						
					$$ = new symbol_info($1->getname(),"arg_list");
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
						
			$$ = new symbol_info($1->getname()+","+$3->getname(),"arg");
			// collect argument types for function call checking
			call_arg_types.push_back($3->get_data_type());
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<endl<<endl;
						
			$$ = new symbol_info($1->getname(),"arg");
			call_arg_types.push_back($1->get_data_type());
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{

	if(argc != 3) 
	{
		cout<<"Usage: <program> <input_file.c> <studentID>"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	string student_id = argv[2];
	string logname = student_id + "_log.txt";
	string errname = student_id + "_error.txt";
	outlog.open(logname.c_str(), ios::trunc);
	errlog.open(errname.c_str(), ios::trunc);
    
	if(yyin == NULL)
	{
		cout<<"Couldn't open input file"<<endl;
		return 0;
	}

	st = new symbol_table(10);
	outlog << "New ScopeTable with ID 1 created" << endl << endl;

	yyparse();
    
	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<"Total Errors: "<<error_count<<endl;
	if(errlog.is_open()) {
		errlog<<"Total Errors: "<<error_count<<endl;
	}
    
	// Cleanup
	delete st;
    
	outlog.close();
	if(errlog.is_open()) errlog.close();
    
	fclose(yyin);
    
	return 0;

}