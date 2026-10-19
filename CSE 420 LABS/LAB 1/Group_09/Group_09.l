%option noyywrap

%{
#include<bits/stdc++.h>
#include"symbol_info.h"

#define YYSTYPE symbol_info*

#include "y.tab.h"

extern YYSTYPE yylval;

using namespace std;

void yyerror(const char *);

string loglist;
extern int line_num;
extern ofstream outlog;

bool last_lexeme_was_newline = false;
%}

delim       [ \t\v\r\f]
ws          {delim}+
newline     \n
letter_     [A-Za-z_]
digit       [0-9]
id          {letter_}({letter_}|{digit})*
exponent    [Ee][+-]?{digit}+
floatnum    (({digit}*"."{digit}+)|({digit}+"."{digit}*))({exponent})?|{digit}+{exponent}
integer     {digit}+

%%

{ws} {
        last_lexeme_was_newline = false;
     }

{newline} {
            line_num++;
            last_lexeme_was_newline = true;
          }

"if" {
        last_lexeme_was_newline = false;
        loglist = string("Line no ") + to_string(line_num) + ": Token <IF> Lexeme " + string(yytext) + " found\n\n";
        outlog << loglist;
        return IF;
     }

"else" {
          last_lexeme_was_newline = false;
          loglist = string("Line no ") + to_string(line_num) + ": Token <ELSE> Lexeme " + string(yytext) + " found\n\n";
          outlog << loglist;
          return ELSE;
       }

"for" {
         last_lexeme_was_newline = false;
         loglist = string("Line no ") + to_string(line_num) + ": Token <FOR> Lexeme " + string(yytext) + " found\n\n";
         outlog << loglist;
         return FOR;
      }

"while" {
           last_lexeme_was_newline = false;
           loglist = string("Line no ") + to_string(line_num) + ": Token <WHILE> Lexeme " + string(yytext) + " found\n\n";
           outlog << loglist;
           return WHILE;
        }

"switch" {
            last_lexeme_was_newline = false;
            loglist = string("Line no ") + to_string(line_num) + ": Token <SWITCH> Lexeme " + string(yytext) + " found\n\n";
            outlog << loglist;
            return SWITCH;
         }

"do" {
       last_lexeme_was_newline = false;
       loglist = string("Line no ") + to_string(line_num) + ": Token <DO> Lexeme " + string(yytext) + " found\n\n";
       outlog << loglist;
       return DO;
     }

"break" {
           last_lexeme_was_newline = false;
           loglist = string("Line no ") + to_string(line_num) + ": Token <BREAK> Lexeme " + string(yytext) + " found\n\n";
           outlog << loglist;
           return BREAK;
        }

"default" {
             last_lexeme_was_newline = false;
             loglist = string("Line no ") + to_string(line_num) + ": Token <DEFAULT> Lexeme " + string(yytext) + " found\n\n";
             outlog << loglist;
             return DEFAULT;
          }

"int" {
        last_lexeme_was_newline = false;
        loglist = string("Line no ") + to_string(line_num) + ": Token <INT> Lexeme " + string(yytext) + " found\n\n";
        outlog << loglist;
        return INT;
      }

"char" {
         last_lexeme_was_newline = false;
         loglist = string("Line no ") + to_string(line_num) + ": Token <CHAR> Lexeme " + string(yytext) + " found\n\n";
         outlog << loglist;
         return CHAR;
       }

"goto" {
         last_lexeme_was_newline = false;
         loglist = string("Line no ") + to_string(line_num) + ": Token <GOTO> Lexeme " + string(yytext) + " found\n\n";
         outlog << loglist;
         return GOTO;
       }

"float" {
          last_lexeme_was_newline = false;
          loglist = string("Line no ") + to_string(line_num) + ": Token <FLOAT> Lexeme " + string(yytext) + " found\n\n";
          outlog << loglist;
          return FLOAT;
        }

"double" {
           last_lexeme_was_newline = false;
           loglist = string("Line no ") + to_string(line_num) + ": Token <DOUBLE> Lexeme " + string(yytext) + " found\n\n";
           outlog << loglist;
           return DOUBLE;
         }

"return" {
           last_lexeme_was_newline = false;
           loglist = string("Line no ") + to_string(line_num) + ": Token <RETURN> Lexeme " + string(yytext) + " found\n\n";
           outlog << loglist;
           return RETURN;
         }

"continue" {
             last_lexeme_was_newline = false;
             loglist = string("Line no ") + to_string(line_num) + ": Token <CONTINUE> Lexeme " + string(yytext) + " found\n\n";
             outlog << loglist;
             return CONTINUE;
           }

"case" {
         last_lexeme_was_newline = false;
         loglist = string("Line no ") + to_string(line_num) + ": Token <CASE> Lexeme " + string(yytext) + " found\n\n";
         outlog << loglist;
         return CASE;
       }

"void" {
         last_lexeme_was_newline = false;
         loglist = string("Line no ") + to_string(line_num) + ": Token <VOID> Lexeme " + string(yytext) + " found\n\n";
         outlog << loglist;
         return VOID;
       }

"printf" {
           last_lexeme_was_newline = false;
           loglist = string("Line no ") + to_string(line_num) + ": Token <PRINTLN> Lexeme " + string(yytext) + " found\n\n";
           outlog << loglist;
           return PRINTLN;
         }

{floatnum} {
             symbol_info *s = new symbol_info((string)yytext, "CONST_FLOAT");
             yylval = (YYSTYPE)s;

             last_lexeme_was_newline = false;
             loglist = string("Line no ") + to_string(line_num) + ": Token <CONST_FLOAT> Lexeme " + string(yytext) + " found\n\n";
             outlog << loglist;
             return CONST_FLOAT;
           }

{integer} {
            symbol_info *s = new symbol_info((string)yytext, "CONST_INT");
            yylval = (YYSTYPE)s;

            last_lexeme_was_newline = false;
            loglist = string("Line no ") + to_string(line_num) + ": Token <CONST_INT> Lexeme " + string(yytext) + " found\n\n";
            outlog << loglist;
            return CONST_INT;
          }

{id} {
       symbol_info *s = new symbol_info((string)yytext, "ID");
       yylval = (YYSTYPE)s;

       last_lexeme_was_newline = false;
       loglist = string("Line no ") + to_string(line_num) + ": Token <ID> Lexeme " + string(yytext) + " found\n\n";
       outlog << loglist;
       return ID;
     }

"++" {
        symbol_info *s = new symbol_info((string)yytext, "INCOP");
        yylval = (YYSTYPE)s;

        last_lexeme_was_newline = false;
        loglist = string("Line no ") + to_string(line_num) + ": Token <INCOP> Lexeme " + string(yytext) + " found\n\n";
        outlog << loglist;
        return INCOP;
     }

"--" {
        symbol_info *s = new symbol_info((string)yytext, "DECOP");
        yylval = (YYSTYPE)s;

        last_lexeme_was_newline = false;
        loglist = string("Line no ") + to_string(line_num) + ": Token <DECOP> Lexeme " + string(yytext) + " found\n\n";
        outlog << loglist;
        return DECOP;
     }

"<="|">="|"=="|"!="|"<"|">" {
                                symbol_info *s = new symbol_info((string)yytext, "RELOP");
                                yylval = (YYSTYPE)s;

                                last_lexeme_was_newline = false;
                                loglist = string("Line no ") + to_string(line_num) + ": Token <RELOP> Lexeme " + string(yytext) + " found\n\n";
                                outlog << loglist;
                                return RELOP;
                              }

"&&"|"||" {
            symbol_info *s = new symbol_info((string)yytext, "LOGICOP");
            yylval = (YYSTYPE)s;

            last_lexeme_was_newline = false;
            loglist = string("Line no ") + to_string(line_num) + ": Token <LOGICOP> Lexeme " + string(yytext) + " found\n\n";
            outlog << loglist;
            return LOGICOP;
          }

"+"|"-" {
          symbol_info *s = new symbol_info((string)yytext, "ADDOP");
          yylval = (YYSTYPE)s;

          last_lexeme_was_newline = false;
          loglist = string("Line no ") + to_string(line_num) + ": Token <ADDOP> Lexeme " + string(yytext) + " found\n\n";
          outlog << loglist;
          return ADDOP;
        }

"*"|"/"|"%" {
              symbol_info *s = new symbol_info((string)yytext, "MULOP");
              yylval = (YYSTYPE)s;

              last_lexeme_was_newline = false;
              loglist = string("Line no ") + to_string(line_num) + ": Token <MULOP> Lexeme " + string(yytext) + " found\n\n";
              outlog << loglist;
              return MULOP;
            }

"=" {
      symbol_info *s = new symbol_info((string)yytext, "ASSIGNOP");
      yylval = (YYSTYPE)s;

      last_lexeme_was_newline = false;
      loglist = string("Line no ") + to_string(line_num) + ": Token <ASSIGNOP> Lexeme " + string(yytext) + " found\n\n";
      outlog << loglist;
      return ASSIGNOP;
    }

"!" {
      symbol_info *s = new symbol_info((string)yytext, "NOT");
      yylval = (YYSTYPE)s;

      last_lexeme_was_newline = false;
      loglist = string("Line no ") + to_string(line_num) + ": Token <NOT> Lexeme " + string(yytext) + " found\n\n";
      outlog << loglist;
      return NOT;
    }

"(" {
      last_lexeme_was_newline = false;
      loglist = string("Line no ") + to_string(line_num) + ": Token <LPAREN> Lexeme " + string(yytext) + " found\n\n";
      outlog << loglist;
      return LPAREN;
    }

")" {
      last_lexeme_was_newline = false;
      loglist = string("Line no ") + to_string(line_num) + ": Token <RPAREN> Lexeme " + string(yytext) + " found\n\n";
      outlog << loglist;
      return RPAREN;
    }

"{" {
      last_lexeme_was_newline = false;
      loglist = string("Line no ") + to_string(line_num) + ": Token <LCURL> Lexeme " + string(yytext) + " found\n\n";
      outlog << loglist;
      return LCURL;
    }

"}" {
      last_lexeme_was_newline = false;
      loglist = string("Line no ") + to_string(line_num) + ": Token <RCURL> Lexeme " + string(yytext) + " found\n\n";
      outlog << loglist;
      return RCURL;
    }

"[" {
      last_lexeme_was_newline = false;
      loglist = string("Line no ") + to_string(line_num) + ": Token <LTHIRD> Lexeme " + string(yytext) + " found\n\n";
      outlog << loglist;
      return LTHIRD;
    }

"]" {
      last_lexeme_was_newline = false;
      loglist = string("Line no ") + to_string(line_num) + ": Token <RTHIRD> Lexeme " + string(yytext) + " found\n\n";
      outlog << loglist;
      return RTHIRD;
    }

"," {
      last_lexeme_was_newline = false;
      loglist = string("Line no ") + to_string(line_num) + ": Token <COMMA> Lexeme " + string(yytext) + " found\n\n";
      outlog << loglist;
      return COMMA;
    }

":" {
      last_lexeme_was_newline = false;
      loglist = string("Line no ") + to_string(line_num) + ": Token <COLON> Lexeme " + string(yytext) + " found\n\n";
      outlog << loglist;
      return COLON;
    }

";" {
      last_lexeme_was_newline = false;
      loglist = string("Line no ") + to_string(line_num) + ": Token <SEMICOLON> Lexeme " + string(yytext) + " found\n\n";
      outlog << loglist;
      return SEMICOLON;
    }

<<EOF>> {
          if(last_lexeme_was_newline && line_num > 1)
          {
              line_num--;
          }

          yyterminate();
        }

. {
    last_lexeme_was_newline = false;
  }

%%
