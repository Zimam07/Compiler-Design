%{

#include"symbol_info.h"

#define YYSTYPE symbol_info*

int yyparse(void);
int yylex(void);
void yyerror(const char *s);

extern FILE *yyin;

ofstream outlog;
int line_num = 1;

static symbol_info *make_symbol(const string &name, const string &type)
{
    return new symbol_info(name, type);
}

static string symbol_text(symbol_info *symbol)
{
    if(symbol == NULL)
    {
        return "";
    }

    return symbol->getnameofsymbol();
}

static void log_rule(const string &rule, const string &matched_text)
{
    outlog << "At line no: " << line_num << " " << rule << endl << endl;
    outlog << matched_text << endl << endl;
}

%}

%token IF FOR WHILE SWITCH DO BREAK DEFAULT INT CHAR GOTO FLOAT DOUBLE RETURN CONTINUE CASE PRINTLN VOID
%token ID CONST_INT CONST_FLOAT
%token ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA COLON SEMICOLON

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
    {
        log_rule("start : program", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "start");
    }
    ;

program : program unit
    {
        string matched_text = symbol_text($1) + "\n" + symbol_text($2);
        log_rule("program : program unit", matched_text);
        $$ = make_symbol(matched_text, "program");
    }
    | unit
    {
        log_rule("program : unit", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "program");
    }
    ;

unit : variable_decl
    {
        log_rule("unit : variable_decl", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "unit");
    }
    | func_definition
    {
        log_rule("unit : func_definition", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "unit");
    }
    ;

func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement
    {
        string matched_text = symbol_text($1) + " " + symbol_text($2) + "(" + symbol_text($4) + ")\n" + symbol_text($6);
        log_rule("func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement", matched_text);
        $$ = make_symbol(matched_text, "func_definition");
    }
    | type_specifier ID LPAREN RPAREN compound_statement
    {
        string matched_text = symbol_text($1) + " " + symbol_text($2) + "()\n" + symbol_text($5);
        log_rule("func_definition : type_specifier ID LPAREN RPAREN compound_statement", matched_text);
        $$ = make_symbol(matched_text, "func_definition");
    }
    ;

param_list : param_list COMMA type_specifier ID
    {
        string matched_text = symbol_text($1) + "," + symbol_text($3) + " " + symbol_text($4);
        log_rule("param_list : param_list COMMA type_specifier ID", matched_text);
        $$ = make_symbol(matched_text, "param_list");
    }
    | param_list COMMA type_specifier
    {
        string matched_text = symbol_text($1) + "," + symbol_text($3);
        log_rule("param_list : param_list COMMA type_specifier", matched_text);
        $$ = make_symbol(matched_text, "param_list");
    }
    | type_specifier ID
    {
        string matched_text = symbol_text($1) + " " + symbol_text($2);
        log_rule("param_list : type_specifier ID", matched_text);
        $$ = make_symbol(matched_text, "param_list");
    }
    | type_specifier
    {
        log_rule("param_list : type_specifier", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "param_list");
    }
    ;

compound_statement : LCURL statements RCURL
    {
        string matched_text = "{\n" + symbol_text($2) + "\n}";
        log_rule("compound_statement : LCURL statements RCURL", matched_text);
        $$ = make_symbol(matched_text, "compound_statement");
    }
    | LCURL RCURL
    {
        string matched_text = "{\n}";
        log_rule("compound_statement : LCURL RCURL", matched_text);
        $$ = make_symbol(matched_text, "compound_statement");
    }
    ;

variable_decl : type_specifier declaration_list SEMICOLON
    {
        string matched_text = symbol_text($1) + " " + symbol_text($2) + ";";
        log_rule("variable_decl : type_specifier declaration_list SEMICOLON", matched_text);
        $$ = make_symbol(matched_text, "variable_decl");
    }
    ;

type_specifier : INT
    {
        log_rule("type_specifier : INT", "int");
        $$ = make_symbol("int", "type_specifier");
    }
    | FLOAT
    {
        log_rule("type_specifier : FLOAT", "float");
        $$ = make_symbol("float", "type_specifier");
    }
    | VOID
    {
        log_rule("type_specifier : VOID", "void");
        $$ = make_symbol("void", "type_specifier");
    }
    | CHAR
    {
        log_rule("type_specifier : CHAR", "char");
        $$ = make_symbol("char", "type_specifier");
    }
    ;

declaration_list : declaration_list COMMA ID
    {
        string matched_text = symbol_text($1) + "," + symbol_text($3);
        log_rule("declaration_list : declaration_list COMMA ID", matched_text);
        $$ = make_symbol(matched_text, "declaration_list");
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        string matched_text = symbol_text($1) + "," + symbol_text($3) + "[" + symbol_text($5) + "]";
        log_rule("declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", matched_text);
        $$ = make_symbol(matched_text, "declaration_list");
    }
    | ID
    {
        log_rule("declaration_list : ID", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "declaration_list");
    }
    | ID LTHIRD CONST_INT RTHIRD
    {
        string matched_text = symbol_text($1) + "[" + symbol_text($3) + "]";
        log_rule("declaration_list : ID LTHIRD CONST_INT RTHIRD", matched_text);
        $$ = make_symbol(matched_text, "declaration_list");
    }
    ;

statements : statement
    {
        log_rule("statements : statement", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "statements");
    }
    | statements statement
    {
        string matched_text = symbol_text($1) + "\n" + symbol_text($2);
        log_rule("statements : statements statement", matched_text);
        $$ = make_symbol(matched_text, "statements");
    }
    ;

statement : variable_decl
    {
        log_rule("statement : variable_decl", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "statement");
    }
    | expression_statement
    {
        log_rule("statement : expression_statement", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "statement");
    }
    | compound_statement
    {
        log_rule("statement : compound_statement", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "statement");
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    {
        string matched_text = "for(" + symbol_text($3) + symbol_text($4) + symbol_text($5) + ")\n" + symbol_text($7);
        log_rule("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement", matched_text);
        $$ = make_symbol(matched_text, "statement");
    }
    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
    {
        string matched_text = "if(" + symbol_text($3) + ")\n" + symbol_text($5);
        log_rule("statement : IF LPAREN expression RPAREN statement", matched_text);
        $$ = make_symbol(matched_text, "statement");
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        string matched_text = "if(" + symbol_text($3) + ")\n" + symbol_text($5) + "\nelse\n" + symbol_text($7);
        log_rule("statement : IF LPAREN expression RPAREN statement ELSE statement", matched_text);
        $$ = make_symbol(matched_text, "statement");
    }
    | WHILE LPAREN expression RPAREN statement
    {
        string matched_text = "while(" + symbol_text($3) + ")\n" + symbol_text($5);
        log_rule("statement : WHILE LPAREN expression RPAREN statement", matched_text);
        $$ = make_symbol(matched_text, "statement");
    }
    | PRINTLN LPAREN ID RPAREN SEMICOLON
    {
        string matched_text = "printf(" + symbol_text($3) + ");";
        log_rule("statement : PRINTLN LPAREN ID RPAREN SEMICOLON", matched_text);
        $$ = make_symbol(matched_text, "statement");
    }
    | RETURN expression SEMICOLON
    {
        string matched_text = "return " + symbol_text($2) + ";";
        log_rule("statement : RETURN expression SEMICOLON", matched_text);
        $$ = make_symbol(matched_text, "statement");
    }
    ;

expression_statement : SEMICOLON
    {
        log_rule("expression_statement : SEMICOLON", ";");
        $$ = make_symbol(";", "expression_statement");
    }
    | expression SEMICOLON
    {
        string matched_text = symbol_text($1) + ";";
        log_rule("expression_statement : expression SEMICOLON", matched_text);
        $$ = make_symbol(matched_text, "expression_statement");
    }
    ;

variable : ID
    {
        log_rule("variable : ID", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "variable");
    }
    | ID LTHIRD expression RTHIRD
    {
        string matched_text = symbol_text($1) + "[" + symbol_text($3) + "]";
        log_rule("variable : ID LTHIRD expression RTHIRD", matched_text);
        $$ = make_symbol(matched_text, "variable");
    }
    ;

expression : logic_expression
    {
        log_rule("expression : logic_expression", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "expression");
    }
    | variable ASSIGNOP logic_expression
    {
        string matched_text = symbol_text($1) + "=" + symbol_text($3);
        log_rule("expression : variable ASSIGNOP logic_expression", matched_text);
        $$ = make_symbol(matched_text, "expression");
    }
    ;

logic_expression : rel_expression
    {
        log_rule("logic_expression : rel_expression", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "logic_expression");
    }
    | rel_expression LOGICOP rel_expression
    {
        string matched_text = symbol_text($1) + symbol_text($2) + symbol_text($3);
        log_rule("logic_expression : rel_expression LOGICOP rel_expression", matched_text);
        $$ = make_symbol(matched_text, "logic_expression");
    }
    ;

rel_expression : simple_expression
    {
        log_rule("rel_expression : simple_expression", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "rel_expression");
    }
    | simple_expression RELOP simple_expression
    {
        string matched_text = symbol_text($1) + symbol_text($2) + symbol_text($3);
        log_rule("rel_expression : simple_expression RELOP simple_expression", matched_text);
        $$ = make_symbol(matched_text, "rel_expression");
    }
    ;

simple_expression : term
    {
        log_rule("simple_expression : term", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "simple_expression");
    }
    | simple_expression ADDOP term
    {
        string matched_text = symbol_text($1) + symbol_text($2) + symbol_text($3);
        log_rule("simple_expression : simple_expression ADDOP term", matched_text);
        $$ = make_symbol(matched_text, "simple_expression");
    }
    ;

term : unary_expression
    {
        log_rule("term : unary_expression", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "term");
    }
    | term MULOP unary_expression
    {
        string matched_text = symbol_text($1) + symbol_text($2) + symbol_text($3);
        log_rule("term : term MULOP unary_expression", matched_text);
        $$ = make_symbol(matched_text, "term");
    }
    ;

unary_expression : ADDOP unary_expression
    {
        string matched_text = symbol_text($1) + symbol_text($2);
        log_rule("unary_expression : ADDOP unary_expression", matched_text);
        $$ = make_symbol(matched_text, "unary_expression");
    }
    | NOT unary_expression
    {
        string matched_text = symbol_text($1) + symbol_text($2);
        log_rule("unary_expression : NOT unary_expression", matched_text);
        $$ = make_symbol(matched_text, "unary_expression");
    }
    | factor_info
    {
        log_rule("unary_expression : factor_info", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "unary_expression");
    }
    ;

factor_info : factor
    {
        log_rule("factor_info : factor", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "factor_info");
    }
    ;

factor : variable
    {
        log_rule("factor : variable", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "factor");
    }
    | ID LPAREN argument_list RPAREN
    {
        string matched_text = symbol_text($1) + "(" + symbol_text($3) + ")";
        log_rule("factor : ID LPAREN argument_list RPAREN", matched_text);
        $$ = make_symbol(matched_text, "factor");
    }
    | LPAREN expression RPAREN
    {
        string matched_text = "(" + symbol_text($2) + ")";
        log_rule("factor : LPAREN expression RPAREN", matched_text);
        $$ = make_symbol(matched_text, "factor");
    }
    | CONST_INT
    {
        log_rule("factor : CONST_INT", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "factor");
    }
    | CONST_FLOAT
    {
        log_rule("factor : CONST_FLOAT", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "factor");
    }
    | variable INCOP
    {
        string matched_text = symbol_text($1) + symbol_text($2);
        log_rule("factor : variable INCOP", matched_text);
        $$ = make_symbol(matched_text, "factor");
    }
    | variable DECOP
    {
        string matched_text = symbol_text($1) + symbol_text($2);
        log_rule("factor : variable DECOP", matched_text);
        $$ = make_symbol(matched_text, "factor");
    }
    ;

argument_list : arguments
    {
        log_rule("argument_list : arguments", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "argument_list");
    }
    |
    {
        log_rule("argument_list :", "");
        $$ = make_symbol("", "argument_list");
    }
    ;

arguments : arguments COMMA logic_expression
    {
        string matched_text = symbol_text($1) + "," + symbol_text($3);
        log_rule("arguments : arguments COMMA logic_expression", matched_text);
        $$ = make_symbol(matched_text, "arguments");
    }
    | logic_expression
    {
        log_rule("arguments : logic_expression", symbol_text($1));
        $$ = make_symbol(symbol_text($1), "arguments");
    }
    ;

%%

int main(int argc, char *argv[])
{
    if(argc != 2)
    {
        cout << "Please provide input file name" << endl;
        return 0;
    }

    yyin = fopen(argv[1], "r");
    if(yyin == NULL)
    {
        cout << "Couldn't open file" << endl;
        return 0;
    }

    outlog.open("Group_09_log.txt", ios::trunc);
    line_num = 1;

    yyparse();

    outlog << "Total lines: " << line_num << endl;

    outlog.close();
    fclose(yyin);

    return 0;
}

void yyerror(const char *s)
{
    outlog << "At line no: " << line_num << " " << s << endl << endl;
}
