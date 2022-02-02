#include <stdio.h>
#include <stdlib.h>
#include "tablaSimbolos.h"

extern FILE *yyin, *yyout;
extern int yyparse (void);
extern int cont_lineas;
extern int cont_column;
extern int flag_morfologico;
extern int flag_semantico;
extern TABLA_SIMBOLOS *tablaSimbolos;

void yyerror(char *s);

int main(int argc, char * argv[]){
	int resultado = 0;
	if(argc != 3){
		printf("Error con los parámetros. Pruebe con %s <archivo_entrada> <archivo_salida> \n", argv[0]);
		exit(1);
	}


	yyin = fopen(argv[1], "r");
	if(yyin == NULL){
		printf("Error al abrir el archivo %s\n", argv[1]);
		exit(1);	
	}

	yyout = fopen(argv[2], "w");

	if(yyout == NULL){
		printf("Error al abrir el archivo %s\n", argv[2]);
		fclose(yyin);
		exit(1);
	}

	if((resultado = yyparse()) != 0){
		printf("El analisis NO ha llegado a un resultado correcto\n");
	}

	return 0;
}

void yyerror(char *s){
	if(flag_morfologico == 1){
		printf("****Error morfologico en [lin %d, col %d]: %s\n", cont_lineas, cont_column, s);
	}
	else if(flag_semantico == 1){
		printf("****Error semantico en lin %d: %s\n", cont_lineas, s);
	}
	else{
		printf("****Error sintactico en [lin %d, col %d]\n", cont_lineas, cont_column);
	}
	
	destruir_tabla_simbolos(tablaSimbolos);
	tablaSimbolos = NULL;
}
