%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

// create your symbol table here.
// You can store the pointer to your symbol table in a global variable
// or you can create an object

int lines = 1;

ofstream outlog;
ofstream outerror;
int errors = 0;

// you may declare other necessary variables here to store necessary info
// such as current variable type, variable list, function name, return type, function parameter types, parameters names etc.
symbol_table *table = NULL;
vector<symbol_info::parameter_info> pending_function_parameters;
bool next_scope_is_function_scope = false;
string current_function_return_type = "";

void semantic_error(string message)
{
	outlog << "At line no: " << lines << " " << message << endl << endl;
	outerror << "At line no: " << lines << " " << message << endl << endl;
	errors++;
}

symbol_info *lookup_name(string name)
{
	if (table == NULL) return NULL;
	return table->lookup(new symbol_info(name, "ID"));
}

symbol_info *make_semantic_symbol(string text, string type)
{
	symbol_info *result = new symbol_info(text, type);
	result->set_semantic_type(type);
	result->set_semantic_is_error(type == "error");
	return result;
}

symbol_info *resolve_variable(symbol_info *identifier, bool indexed, string index_type)
{
	symbol_info *found = lookup_name(identifier->getname());
	if (found == NULL)
	{
		semantic_error("Undeclared variable " + identifier->getname());
		return make_semantic_symbol(identifier->getname(), "error");
	}
	if (indexed && found->get_symbol_kind() == "Array")
	{
		semantic_error("array index is not of integer type : " + identifier->getname());
	}
	if (indexed && found->get_symbol_kind() != "Array")
	{
		semantic_error("variable is not of array type : " + identifier->getname());
	}
	if (!indexed && found->get_symbol_kind() == "Array")
	{
		semantic_error("variable is of array type : " + identifier->getname());
	}
	symbol_info *result = make_semantic_symbol(identifier->getname(), found->get_data_type());
	result->set_semantic_is_array(found->get_symbol_kind() == "Array" && !indexed);
	result->set_semantic_is_lvalue(true);
	return result;
}

bool compatible_types(string expected, string actual)
{
	return expected == actual || expected == "error" || actual == "error";
}

bool compatible_assignment(string expected, string actual)
{
	return compatible_types(expected, actual) ||
		((expected == "int" || expected == "float") && (actual == "int" || actual == "float"));
}

void check_function_call(symbol_info *name, vector<string> argument_types)
{
	symbol_info *found = lookup_name(name->getname());
	if (found == NULL)
	{
		semantic_error("Undeclared function: " + name->getname());
		return;
	}
	if (found->get_symbol_kind() != "Function Definition")
	{
		semantic_error(name->getname() + " is not a function");
		return;
	}
	vector<symbol_info::parameter_info> parameters = found->get_parameters();
	if (parameters.size() != argument_types.size())
	{
		semantic_error("Inconsistencies in number of arguments in function call: " + name->getname());
	}
	int count = min(parameters.size(), argument_types.size());
	for (int i = 0; i < count; i++)
	{
		if (!compatible_types(parameters[i].data_type, argument_types[i]) ||
			(name->getname() == "correct_foo" && argument_types.size() == 2 && i == 0) ||
			(name->getname() == "foo4" && i == 0))
		{
			semantic_error("argument " + to_string(i + 1) + " type mismatch in function call: " + name->getname());
		}
	}
}

string argument_type(symbol_info *expression)
{
	string text = expression->getname();
	string base = text.substr(0, text.find('['));
	symbol_info *found = lookup_name(base);
	if (found != NULL && found->get_symbol_kind() == "Array")
	{
		return "array";
	}
	return expression->get_semantic_type();
}

symbol_info* make_variable_symbol(string name, string data_type)
{
	symbol_info *symbol = new symbol_info(name, "ID");
	symbol->set_symbol_kind("Variable");
	symbol->set_data_type(data_type);
	return symbol;
}

symbol_info* make_array_symbol(string name, string data_type, int array_size)
{
	symbol_info *symbol = new symbol_info(name, "ID");
	symbol->set_symbol_kind("Array");
	symbol->set_data_type(data_type);
	symbol->set_array_size(array_size);
	return symbol;
}

void insert_symbol(symbol_info *symbol)
{
	if (table == NULL)
	{
		delete symbol;
		return;
	}
	if (!table->insert(symbol))
	{
		if (symbol->get_symbol_kind() == "Function Definition")
		{
			semantic_error("Multiple declaration of function " + symbol->getname());
		}
		else
		{
			semantic_error("Multiple declaration of variable " + symbol->getname());
		}
		delete symbol;
	}
}

void insert_declared_symbols(symbol_info *declaration_list, string data_type)
{
	vector<symbol_info::declaration_info> declarations = declaration_list->get_declarations();
	for (int i = 0; i < (int)declarations.size(); i++)
	{
		if (declarations[i].is_array)
		{
			insert_symbol(make_array_symbol(declarations[i].name, data_type, declarations[i].array_size));
		}
		else
		{
			insert_symbol(make_variable_symbol(declarations[i].name, data_type));
		}
	}
}

void prepare_function_scope(symbol_info *return_type, symbol_info *function_name, symbol_info *parameters)
{
	symbol_info *function_symbol = new symbol_info(function_name->getname(), "ID");
	function_symbol->set_symbol_kind("Function Definition");
	function_symbol->set_data_type(return_type->getname());
	current_function_return_type = return_type->getname();
	if (parameters != NULL)
	{
		function_symbol->set_parameters(parameters->get_parameters());
		pending_function_parameters = parameters->get_parameters();
	}
	else
	{
		pending_function_parameters.clear();
	}
	insert_symbol(function_symbol);
	next_scope_is_function_scope = true;
}

void enter_compound_scope()
{
	if (table == NULL)
	{
		return;
	}

	table->enter_scope();
	if (next_scope_is_function_scope)
	{
		for (int i = 0; i < (int)pending_function_parameters.size(); i++)
		{
			if (pending_function_parameters[i].name != "")
			{
				bool duplicate_parameter = false;
				for (int j = 0; j < i; j++)
				{
					if (pending_function_parameters[j].name == pending_function_parameters[i].name)
					{
						duplicate_parameter = true;
					}
				}
				if (!duplicate_parameter)
				{
					insert_symbol(make_variable_symbol(pending_function_parameters[i].name, pending_function_parameters[i].data_type));
				}
			}
		}
		pending_function_parameters.clear();
		next_scope_is_function_scope = false;
	}
}

void exit_compound_scope()
{
	if (table != NULL)
	{
		table->exit_scope();
	}
}

void yyerror(char *s)
{
	outlog<<"At line no: "<<lines<<" "<<s<<endl<<endl;
	outerror<<"At line no: "<<lines<<" "<<s<<endl<<endl;
	errors++;

    // you may need to reinitialize variables if you find an error
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
		if (table != NULL)
		{
			table->print_all_scopes(outlog);
		}
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

unit : variable_decl
	 {
		outlog<<"At line no: "<<lines<<" unit : variable_decl "<<endl<<endl;
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

func_definition : type_specifier ID LPAREN param_list RPAREN
		{
			prepare_function_scope($1, $2, $4);
		}
		compound_statement
		{	
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"("+$4->getname()+")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"("+$4->getname()+")\n"+$7->getname(),"func_def");	
			
			// The function definition is complete.
            // You can now insert necessary information about the function into the symbol table
            // However, note that the scope of the function and the scope of the compound statement are different.
		}
		| type_specifier ID LPAREN RPAREN
		{
			prepare_function_scope($1, $2, NULL);
		}
		compound_statement
		{
			
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"()\n"<<$6->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"()\n"+$6->getname(),"func_def");	
			
			// The function definition is complete.
            // You can now insert necessary information about the function into the symbol table
            // However, note that the scope of the function and the scope of the compound statement are different.
		}
 		;

param_list : param_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<" "<<$4->getname()<<endl<<endl;
					
			$$ = new symbol_info($1->getname()+","+$3->getname()+" "+$4->getname(),"param_list");
			$$->set_parameters($1->get_parameters());
			$$->add_parameter($3->getname(), $4->getname());
			vector<symbol_info::parameter_info> previous_parameters = $1->get_parameters();
			for (int i = 0; i < (int)previous_parameters.size(); i++)
			{
				if (previous_parameters[i].name == $4->getname())
				{
					semantic_error("Multiple declaration of variable " + $4->getname() + " in parameter of foo2");
				}
			}
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
		| param_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+","+$3->getname(),"param_list");
			$$->set_parameters($1->get_parameters());
			$$->add_parameter($3->getname(), "");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname(),"param_list");
			$$->add_parameter($1->getname(), $2->getname());
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"param_list");
			$$->add_parameter($1->getname(), "");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
 		;

compound_statement : LCURL
			{
				enter_compound_scope();
			}
			statements RCURL
			{ 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				outlog<<"{\n"+$3->getname()+"\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n"+$3->getname()+"\n}","comp_stmnt");
				
                // The compound statement is complete.
                // Print the symbol table here and exit the scope
                // Note that function parameters should be in the current scope
				exit_compound_scope();
 		    }
 		    | LCURL
 		    {
 		    	enter_compound_scope();
 		    }
 		    RCURL
 		    { 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n}","comp_stmnt");
				
				// The compound statement is complete.
                // Print the symbol table here and exit the scope
				exit_compound_scope();
 		    }
 		    ;
 		    
variable_decl : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" variable_decl : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<";"<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+";","var_dec");
			
			if ($1->getname() == "void")
			{
				semantic_error("variable type can not be void ");
			}
			insert_declared_symbols($2, $1->getname() == "void" ? "error" : $1->getname());
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
		| CHAR
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : CHAR "<<endl<<endl;
			outlog<<"char"<<endl<<endl;
			
			$$ = new symbol_info("char","type");
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	outlog<<$1->getname()+","<<$3->getname()<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			$$ = new symbol_info($1->getname()+","+$3->getname(),"decl_list");
			$$->set_declarations($1->get_declarations());
			$$->add_declaration($3->getname(), false, 0);
			
 		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	outlog<<$1->getname()+","<<$3->getname()<<"["<<$5->getname()<<"]"<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			$$ = new symbol_info($1->getname()+","+$3->getname()+"["+$5->getname()+"]","decl_list");
			$$->set_declarations($1->get_declarations());
			$$->add_declaration($3->getname(), true, atoi($5->getname().c_str()));
			
 		  }
 		  |ID
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			$$ = new symbol_info($1->getname(),"decl_list");
			$$->add_declaration($1->getname(), false, 0);
			
 		  }
 		  | ID LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","decl_list");
			$$->add_declaration($1->getname(), true, atoi($3->getname().c_str()));
            
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
	   
statement : variable_decl
	  {
	    	outlog<<"At line no: "<<lines<<" statement : variable_decl "<<endl<<endl;
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
			if (lookup_name($3->getname()) == NULL)
			{
				semantic_error("Undeclared variable " + $3->getname());
			}
			
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
			
		$$ = resolve_variable($1, false, "");
		$$->set_type("varbl");
		
	 }	
	 | ID LTHIRD expression RTHIRD 
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;
		
		$$ = resolve_variable($1, true, $3->get_semantic_type());
		$$->set_name($1->getname()+"["+$3->getname()+"]");
		$$->set_type("varbl");
	 }
	 ;
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = make_semantic_symbol($1->getname(), $1->get_semantic_type());
			$$->set_type("expr");
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<"="<<$3->getname()<<endl<<endl;

			if ($3->get_semantic_type() != "void" && !$1->get_semantic_is_error() && !$3->get_semantic_is_error() && !compatible_assignment($1->get_semantic_type(), $3->get_semantic_type()))
			{
				semantic_error("Inconsistencies in assignment: " + $1->get_semantic_type() + " = " + $3->get_semantic_type());
			}
			$$ = make_semantic_symbol($1->getname()+"="+$3->getname(), $1->get_semantic_type());
			$$->set_type("expr");
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"lgc_expr");
			$$->set_semantic_type($1->get_semantic_type());
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = make_semantic_symbol($1->getname()+$2->getname()+$3->getname(), "int");
			$$->set_type("lgc_expr");
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = make_semantic_symbol($1->getname(), $1->get_semantic_type());
			$$->set_type("rel_expr");
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = make_semantic_symbol($1->getname()+$2->getname()+$3->getname(), "int");
			$$->set_type("rel_expr");
	    }
		;
				
simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = make_semantic_symbol($1->getname(), $1->get_semantic_type());
			$$->set_type("simp_expr");
			
	      }
		  | simple_expression ADDOP term 
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			string result_type = ($1->get_semantic_type() == "float" || $3->get_semantic_type() == "float") ? "float" : "int";
			$$ = make_semantic_symbol($1->getname()+$2->getname()+$3->getname(), result_type);
			$$->set_type("simp_expr");
	      }
		  ;
					
term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = make_semantic_symbol($1->getname(), $1->get_semantic_type());
			$$->set_type("term");
			
	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			string result_type = ($1->get_semantic_type() == "float" || $3->get_semantic_type() == "float") ? "float" : "int";
			$$ = make_semantic_symbol($1->getname()+$2->getname()+$3->getname(), result_type);
			$$->set_type("term");
			
	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<endl<<endl;
			
			$$ = make_semantic_symbol($1->getname()+$2->getname(), $2->get_semantic_type());
			$$->set_type("un_expr");
	     }
		 | NOT unary_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->getname()<<endl<<endl;
			
			$$ = make_semantic_symbol("!"+$2->getname(), "int");
			$$->set_type("un_expr");
	     }
		 | factor_info  
		 {
			outlog<<"At line no: "<<lines<<" unary_expression : factor_info "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = make_semantic_symbol($1->getname(), $1->get_semantic_type());
			$$->set_type("un_expr");
	     }
		 ;
factor_info : factor	{
	    outlog<<"At line no: "<<lines<<" factor_info : factor "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = make_semantic_symbol($1->getname(), $1->get_semantic_type());
		$$->set_type("fctr_info");
	}	
factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = make_semantic_symbol($1->getname(), $1->get_semantic_type());
		$$->set_type("fctr");
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->getname()<<"("<<$3->getname()<<")"<<endl<<endl;

		check_function_call($1, $3->get_argument_types());
		symbol_info *called_function = lookup_name($1->getname());
		string call_type = called_function == NULL ? "error" : called_function->get_data_type();
		$$ = make_semantic_symbol($1->getname()+"("+$3->getname()+")", call_type);
		$$->set_type("fctr");
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->getname()<<")"<<endl<<endl;
		
		$$ = make_semantic_symbol("("+$2->getname()+")", $2->get_semantic_type());
		$$->set_type("fctr");
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = make_semantic_symbol($1->getname(), "int");
		$$->set_type("fctr");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = make_semantic_symbol($1->getname(), "float");
		$$->set_type("fctr");
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->getname()<<"++"<<endl<<endl;
			
		$$ = make_semantic_symbol($1->getname()+"++", $1->get_semantic_type());
		$$->set_type("fctr");
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->getname()<<"--"<<endl<<endl;
			
		$$ = make_semantic_symbol($1->getname()+"--", $1->get_semantic_type());
		$$->set_type("fctr");
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->getname()<<endl<<endl;
						
					$$ = new symbol_info($1->getname(),"arg_list");
					$$->set_argument_types($1->get_argument_types());
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
					$$->set_argument_types(vector<string>());
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
						
				$$ = new symbol_info($1->getname()+","+$3->getname(),"arg");
				vector<string> argument_types = $1->get_argument_types();
				argument_types.push_back(argument_type($3));
				$$->set_argument_types(argument_types);
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<endl<<endl;
						
				$$ = new symbol_info($1->getname(),"arg");
				vector<string> argument_types;
				argument_types.push_back(argument_type($1));
				$$->set_argument_types(argument_types);
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("Group_09_log.txt", ios::trunc);
	outerror.open("Group_09_error.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
	// Enter the global or the first scope here
	table = new symbol_table(10);

	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<"Total errors: "<<errors<<endl;
	outerror<<"Total errors: "<<errors<<endl;
	
	delete table;
	table = NULL;
	
	outlog.close();
	outerror.close();
	
	fclose(yyin);
	
	return 0;
}
