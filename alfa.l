%{
/* delimitadores de código C */
/* Esta seccion suele contener declaradores de variables y funciones que se utilizan posteriormente asi como directivas include */
#include <stdio.h>
#include "alfa.h"
#include "y.tab.h"

extern void yyerror(char *s);

int cont_lineas = 1;
int cont_column = 1;
int flag_sintactico = 0;
int flag_morfologico = 0;
char msg_error[130] = "";
%}

%option noyywrap
%option noinput
%option nounput
%option never-interactive

%%

main { fprintf(yyout, ";D:\tmain\n"); cont_column += yyleng; return TOK_MAIN; }
int { fprintf(yyout, ";D:\tint\n"); cont_column += yyleng; return TOK_INT; }
boolean { fprintf(yyout, ";D:\tboolean\n"); cont_column += yyleng; return TOK_BOOLEAN; }
array { fprintf(yyout, ";D:\tarray\n"); cont_column += yyleng; return TOK_ARRAY; }
function { fprintf(yyout, ";D:\tfunction\n"); cont_column += yyleng; return TOK_FUNCTION; }
if { fprintf(yyout, ";D:\tif\n"); cont_column += yyleng; return TOK_IF; }
else { fprintf(yyout, ";D:\telse\n"); cont_column += yyleng; return TOK_ELSE; }
while { fprintf(yyout, ";D:\twhile\n"); cont_column += yyleng; return TOK_WHILE; }
scanf { fprintf(yyout, ";D:\tscanf\n"); cont_column += yyleng; return TOK_SCANF; }
printf { fprintf(yyout, ";D:\tprintf\n"); cont_column += yyleng; return TOK_PRINTF; }
return { fprintf(yyout, ";D:\treturn\n"); cont_column += yyleng; return TOK_RETURN; }
true { fprintf(yyout, ";D:\ttrue\n"); cont_column += yyleng; return TOK_TRUE; }
false { fprintf(yyout, ";D:\tfalse\n");cont_column += yyleng; return TOK_FALSE; }

"//".* { cont_column += yyleng; }

";" { fprintf(yyout, ";D:\t;\n"); cont_column += yyleng; return TOK_PUNTOYCOMA; }
"," { fprintf(yyout, ";D:\t,\n"); cont_column += yyleng; return TOK_COMA; }
"(" { fprintf(yyout, ";D:\t(\n"); cont_column += yyleng; return TOK_PARENTESISIZQUIERDO; }
")" { fprintf(yyout, ";D:\t)\n"); cont_column += yyleng; return TOK_PARENTESISDERECHO; }
"[" { fprintf(yyout, ";D:\t[\n"); cont_column += yyleng; return TOK_CORCHETEIZQUIERDO; }
"]" { fprintf(yyout, ";D:\t]\n"); cont_column += yyleng; return TOK_CORCHETEDERECHO; }
"{" { fprintf(yyout, ";D:\t{\n"); cont_column += yyleng; return TOK_LLAVEIZQUIERDA; }
"}" { fprintf(yyout, ";D:\t}\n"); cont_column += yyleng; return TOK_LLAVEDERECHA; }
"=" { fprintf(yyout, ";D:\t=\n"); cont_column += yyleng; return TOK_ASIGNACION; }
"+" { fprintf(yyout, ";D:\t+\n"); cont_column += yyleng; return TOK_MAS; }
"-" { fprintf(yyout, ";D:\t-\n"); cont_column += yyleng; return TOK_MENOS; }
"/" { fprintf(yyout, ";D:\t/\n"); cont_column += yyleng; return TOK_DIVISION; }
"*" { fprintf(yyout, ";D:\t*\n"); cont_column += yyleng; return TOK_ASTERISCO; }
"&&" { fprintf(yyout, ";D:\t&&\n"); cont_column += yyleng; return TOK_AND; }
"||" { fprintf(yyout, ";D:\t||\n"); cont_column += yyleng; return TOK_OR; }
"!" { fprintf(yyout, ";D:\t!\n"); cont_column += yyleng; return TOK_NOT; }
"==" { fprintf(yyout, ";D:\t==\n"); cont_column += yyleng; return TOK_IGUAL; }
"!=" { fprintf(yyout, ";D:\t!=\n"); cont_column += yyleng; return TOK_DISTINTO; }
"<=" { fprintf(yyout, ";D:\t<=\n"); cont_column += yyleng; return TOK_MENORIGUAL; }
">=" { fprintf(yyout, ";D:>=\n"); cont_column += yyleng; return TOK_MAYORIGUAL; }
"<" { fprintf(yyout, ";D:<\n"); cont_column += yyleng; return TOK_MENOR; }
">" { fprintf(yyout, ";D:>\n"); cont_column += yyleng; return TOK_MAYOR; }

[a-zA-Z][0-9a-zA-Z]* { if(yyleng > 100){
						cont_column += yyleng;
						flag_morfologico = 1;
						sprintf(msg_error, "identificador demasiado largo (%s)\n", yytext);
						yyerror(msg_error);
						return TOK_ERROR;
					}
					else
						fprintf(yyout, ";D:\t%s\n", yytext); strcpy(yylval.atributos.lexema, yytext); cont_column += yyleng; return TOK_IDENTIFICADOR; 
			}

[0-9]+ { fprintf(yyout, ";D:\t%s\n", yytext); yylval.atributos.valor = atoi(yytext); cont_column += yyleng; return TOK_CONSTANTE_ENTERA; }

[ \t] { cont_column += yyleng; }

[\n] {cont_lineas++;
	  cont_column = 0;}

. {cont_column += yyleng;
	flag_morfologico = 1;
	sprintf(msg_error, "simbolo no permitido (%s)\n", yytext);
	yyerror(msg_error);
	return TOK_ERROR;}

%%
