%{
	/* Delimitadores de codigo C */
	#include <stdio.h>
	#include <string.h>
	#include "tablaSimbolos.h"
	#include "alfa.h"
	#include "generacion.h"
	#include "tablaHash.h"
	extern int yylex();
	extern FILE *yyout;
	extern void yyerror(char *s);
	extern char msg_error[130];
	
	/* Declaracion de las variables globales */
	TABLA_SIMBOLOS *tablaSimbolos = NULL;
	ALFATIPO tipo_actual = A_NOASIG_TIPO, tipo_actual_funcion = A_NOASIG_TIPO;
	ALFACLASE clase_actual = A_NOASIG_CLASE;
	int tamanio_vector_actual = 0;
	int pos_variable_local_actual = 0;
	int pos_parametro_actual = 0;
	int num_parametros_actual = 0;
	int num_parametros_llamada_actual = 0;
	int es_parametro_funcion = 0; /* Flag para saber si se esta reduciendo un
									 parametro de funcion */
	int fn_return = 0; /* Variable global para comprobar si hay sentencia de 
					      retorno en una funcion */
	int ambito_abierto = 0; /* Flag para saber si se está en una funcion */
	int en_explist = 0;
	int flag_semantico = 0;
	int contador_no = 0;
	int contador_iguales=0, contador_distintos=0, contador_menorigual=0, contador_mayorigual=0, contador_mayor=0, contador_menor=0;
	int contador_if=0, contador_while=0;
	int num_variables_locales_actual = 0;
	
	char str_valor[130];
	
%}

%union{
	tipo_atributos atributos;
}

%token TOK_MAIN
%token TOK_INT
%token TOK_BOOLEAN
%token TOK_ARRAY
%token TOK_FUNCTION
%token TOK_IF
%token TOK_ELSE
%token TOK_WHILE
%token TOK_SCANF
%token TOK_PRINTF
%token TOK_RETURN

%token TOK_PUNTOYCOMA
%token TOK_COMA
%token TOK_PARENTESISIZQUIERDO
%token TOK_PARENTESISDERECHO
%token TOK_CORCHETEIZQUIERDO
%token TOK_CORCHETEDERECHO
%token TOK_LLAVEIZQUIERDA
%token TOK_LLAVEDERECHA
%token TOK_ASIGNACION
%token TOK_MAS
%token TOK_MENOS
%token TOK_DIVISION
%token TOK_ASTERISCO
%token TOK_AND
%token TOK_OR
%token TOK_NOT
%token TOK_IGUAL
%token TOK_DISTINTO
%token TOK_MENORIGUAL
%token TOK_MAYORIGUAL
%token TOK_MENOR
%token TOK_MAYOR

%token<atributos> TOK_IDENTIFICADOR

%token<atributos> TOK_CONSTANTE_ENTERA
%token TOK_TRUE
%token TOK_FALSE

%token TOK_IGNORED
%token TOK_SALTOLINEA

%token TOK_ERROR

%start programa

 
%left TOK_OR
%left TOK_AND
%left TOK_MAS TOK_MENOS
%left TOK_ASTERISCO TOK_DIVISION
%right contrario
%right TOK_NOT

%type<atributos> exp
%type<atributos> comparacion
%type<atributos> clase_vector
%type<atributos> constante_entera
%type<atributos> constante_logica
%type<atributos> asignacion
%type<atributos> constante
%type<atributos> elemento_vector
%type<atributos> while_exp
%type<atributos> while
%type<atributos> if_exp
%type<atributos> if_exp_sentencias
%type<atributos> fn_declaracion
%type<atributos> fn_name
%type<atributos> idpf
%type<atributos> idf_llamada_funcion


%%

programa: inicioTabla TOK_MAIN escritura_cabeceras TOK_LLAVEIZQUIERDA declaraciones escritura_seg_codigo funciones escritura_main sentencias TOK_LLAVEDERECHA escritura_fin liberar_tabla_simbolo {fprintf(yyout , ";R1:\t<programa> ::= main { <declaraciones> <funciones> <sentencias> }\n");};


inicioTabla: {
	tablaSimbolos = crear_tabla_simbolos(TAM_SIMBOLOS_MAX);	
};

liberar_tabla_simbolo: {
	destruir_tabla_simbolos(tablaSimbolos);
	tablaSimbolos = NULL;
}

escritura_cabeceras: {
	escribir_cabecera_compatibilidad(yyout);
    escribir_subseccion_data(yyout);
    escribir_cabecera_bss(yyout);
};

escritura_seg_codigo: {
	escribir_segmento_codigo(yyout);
};

escritura_main: {
	escribir_inicio_main(yyout);
};

escritura_fin: {
	escribir_fin(yyout);
};

declaraciones: 	  declaracion {fprintf(yyout , ";R2:\t<declaraciones> ::= <declaracion>\n");}
				| declaracion declaraciones {fprintf(yyout , ";R3:\t<declaraciones> ::= <declaracion> <declaraciones>\n");};

declaracion:	clase identificadores TOK_PUNTOYCOMA{fprintf(yyout , ";R4:\t<declaracion> ::= <clase> <identificadores> ;\n");};

clase:	  clase_escalar {fprintf(yyout , ";R5:\t<clase> ::= <clase_escalar>\n");
						clase_actual = A_ESCALAR;}
		| clase_vector {fprintf(yyout , ";R7:\t<clase> ::= <clase_vector>\n");
						clase_actual = A_VECTOR;};

clase_escalar:	tipo {fprintf(yyout , ";R9:\t<clase_escalar> ::= <tipo>\n");};

tipo:     TOK_INT {fprintf(yyout , ";R10:\t<tipo> ::= int\n");
					tipo_actual = A_ENTERO;}
		| TOK_BOOLEAN {fprintf(yyout , ";R11:\t<tipo> ::= boolean\n");
						tipo_actual = A_BOOLEANO;
		
};

clase_vector:	  TOK_ARRAY tipo TOK_CORCHETEIZQUIERDO TOK_CONSTANTE_ENTERA TOK_CORCHETEDERECHO {fprintf(yyout , ";R15:\t<clase_vector> ::= array <tipo> [ TOK_CONSTANTE_ENTERA ]\n");
										tamanio_vector_actual = $4.valor;};

identificadores: TOK_IDENTIFICADOR {fprintf(yyout , ";R18:\t<identificadores> ::= <identificador>\n");
	/* Tenemos que insertar el identificador en la tabla de simbolos */
	/* TODO insertar un indice adecuado con la variable */
	if(clase_actual == A_VECTOR && (tamanio_vector_actual < 1 || tamanio_vector_actual > MAX_TAMANIO_VECTOR)){
		sprintf(msg_error, "El tamanyo del vector %s excede los limites permitidos (1,64)", $1.lexema);
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;
	}
	if(declare_variable(tablaSimbolos, $1.lexema, tipo_actual, clase_actual, 5, tamanio_vector_actual, pos_variable_local_actual) == ERR){
		/* Imprimimos error semantico */
		sprintf(msg_error, "Declaracion duplicada.\n");
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;
	}
	/* Se declara variable en global y por tanto se imprime en NASM */
	if(ambito_abierto == 0){
		/* En el caso de que sea un escalar tambien le insertamos un tamano de vector, pero nos da igual porque el valor inicial es indiferente */
		
		/* Imprimimos la variable al NASM */
		if(clase_actual == A_ESCALAR){
			declarar_variable(yyout, $1.lexema, tipo_actual, 1);
		} else {
			declarar_variable(yyout, $1.lexema, tipo_actual, tamanio_vector_actual);
		}	
	}
	/* Se declara como variable local*/
	else{
		if(clase_actual == A_VECTOR){
			sprintf(msg_error, "Variable local de tipo no escalar.");
			flag_semantico = 1;
			yyerror(msg_error);
			return 1;	
		}
		pos_variable_local_actual++;
		num_variables_locales_actual++;
	}
}
										
	| TOK_IDENTIFICADOR TOK_COMA identificadores {
	/* Tenemos que insertar el identificador en la tabla de simbolos */
	/* TODO insertar un indice adecuado con la variable */
	if(clase_actual == A_VECTOR && (tamanio_vector_actual < 1 || tamanio_vector_actual > MAX_TAMANIO_VECTOR)){
		sprintf(msg_error, "El tamanyo del vector %s excede los limites permitidos (1,64)", $1.lexema);
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;
	}
	if(declare_variable(tablaSimbolos, $1.lexema, tipo_actual, clase_actual, 5, tamanio_vector_actual, pos_variable_local_actual) == ERR){
		/* Imprimimos error semantico */
		sprintf(msg_error, "Declaracion duplicada.\n");
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;
	}
	/* Se declara variable en global y por tanto se imprime en NASM */
	if(ambito_abierto == 0){
		/* En el caso de que sea un escalar tambien le insertamos un tamano de vector, pero nos da igual porque el valor inicial es indiferente */
		
		/* Imprimimos la variable al NASM */
		if(clase_actual == A_ESCALAR){
			declarar_variable(yyout, $1.lexema, tipo_actual, 1);
		} else {
			declarar_variable(yyout, $1.lexema, tipo_actual, tamanio_vector_actual);
		}	
	}
	/* Se declara como variable local*/
	else{
		pos_variable_local_actual++;
		num_variables_locales_actual++;
	}
};

funciones:	  funcion funciones{fprintf(yyout , ";R20:\t<funciones> ::= <funcion> <funciones>\n");}
			| /* vacio */ {fprintf(yyout , ";R21:\t<funciones> ::=\n");};

fn_name: 	TOK_FUNCTION tipo TOK_IDENTIFICADOR {	if(declarar_funcion(tablaSimbolos, $3.lexema, tipo_actual, ESCALAR, 5, 0, 0) == ERR){
														/* Imprimimos error semantico */
														sprintf(msg_error, "Declaracion duplicada.\n");
														flag_semantico = 1;
														yyerror(msg_error);
														return 1;
													}	
													else{
														tipo_actual_funcion = tipo_actual;
														ambito_abierto = 1; /* El ambito es el de la funcion abierta*/
														num_variables_locales_actual = 0;
														pos_variable_local_actual = 1;
														num_parametros_actual = 0;
														pos_parametro_actual = 0;
														strcpy($$.lexema, $3.lexema);
													}
};

fn_declaracion: fn_name TOK_PARENTESISIZQUIERDO parametros_funcion TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA declaraciones_funcion {
												/* Suponemos que ya existe el ambito porque se ha declarado previamente la funcion */
												/* Ya se han calculado las variables num_parametros_actual y num_variables_locales_actual*/
												setAdicional1(tablaSimbolos, $1.lexema, num_parametros_actual);
												setAdicional2global(tablaSimbolos, $1.lexema, num_variables_locales_actual);
												escribirInicioFuncion(yyout, $1.lexema, num_variables_locales_actual);
												strcpy($$.lexema, $1.lexema);
};

funcion: fn_declaracion sentencias TOK_LLAVEDERECHA {fprintf(yyout , ";R22:\t<funcion> ::= function <tipo> <identificador> ( <parametros_funcion> ) { <declaraciones_funcion> <sentencias> }  \n");
												if(fn_return < 1){
													sprintf(msg_error, "Funcion %s sin sentencia de retorno.\n", $1.lexema);
													flag_semantico = 1;
													yyerror(msg_error);
													return 1;
												}
												/* Generacion de codigo */
												cerrar_ambito(tablaSimbolos);
												pos_variable_local_actual = 1; /* Se actualiza la posicion de la variable actual */
												ambito_abierto = 0; /* Se cierra el ambito */
};

parametros_funcion: 	  parametro_funcion resto_parametros_funcion {fprintf(yyout, ";R23:\t<parametros_funcion> ::= <parametro_funcion> <resto_parametros_funcion>\n");}
						| /* vacio */ {fprintf(yyout , ";R24:\t<parametros_funcion> ::=\n");};

resto_parametros_funcion: 	TOK_PUNTOYCOMA parametro_funcion resto_parametros_funcion {fprintf(yyout , ";R25:\t<resto_parametros_funcion> ::= ; <parametro_funcion> <resto_parametros_funcion>\n");}
						| /* vacio */ {fprintf(yyout , ";R26:\t<resto_parametros_funcion ::=\n");};

parametro_funcion: 	tipo idpf {fprintf(yyout , ";R27:\t<parametro_funcion> ::= <tipo><identificador>\n");
									if(declarar_parametro(tablaSimbolos, $2.lexema, tipo_actual, ESCALAR, 5, pos_parametro_actual) == ERR){
										sprintf(msg_error, "Declaracion duplicada.\n");
										flag_semantico = 1;
										yyerror(msg_error);
										return 1;
									}
									else{
										pos_parametro_actual++;
										num_parametros_actual++;
									}
};

declaraciones_funcion: 	  declaraciones {fprintf(yyout , ";R28:\t<declaraciones_funcion> ::= <declaraciones>\n");}
						| /* vacio */ {fprintf(yyout , ";R29:\t<declaraciones_funcion> ::=\n");};

sentencias: 	  sentencia {fprintf(yyout , ";R30:\t<sentencias> ::= <sentencia>\n");}
				| sentencia sentencias {fprintf(yyout , ";R31:\t<sentencias> ::= <sentencia> <sentencias>\n");};

sentencia: 	  sentencia_simple TOK_PUNTOYCOMA {fprintf(yyout , ";R32:\t<sentencia> ::= <sentencia_simple> ;\n");}
			| bloque {fprintf(yyout , ";R33:\t<sentencia> ::= <bloque>\n");};

sentencia_simple: 	  asignacion {fprintf(yyout , ";R34:\t<sentencia_simple> ::= <asignacion>\n");}
					| lectura {fprintf(yyout , ";R35:\t<sentencia_simple> ::= <lectura>\n");}
					| escritura {fprintf(yyout , ";R36:\t<sentencia_simple> ::= <escritura>\n");}
					| retorno_funcion {fprintf(yyout , ";R38:\t<sentencia_simple> ::= <retorno_funcion>\n");};

bloque:   condicional {fprintf(yyout , ";R40:\t<bloque> ::= <condicional>\n");}
		| bucle {fprintf(yyout , ";R41:\t<bloque> ::= <bucle>\n");};

asignacion:	  TOK_IDENTIFICADOR TOK_ASIGNACION exp {	fprintf(yyout , ";R43:\t<asignacion> ::= <identificador> = <exp>\n");
	if(buscar_identificador(tablaSimbolos, $1.lexema) == -1){
		sprintf(msg_error, "Acceso a variable no declarada (%s)", $1.lexema);
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;	
	}
	if(getCategoria(tablaSimbolos, $1.lexema) == FUNCION){
		sprintf(msg_error, "Asignacion incompatible.\n");
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;
	}
	else if(getClase(tablaSimbolos, $1.lexema) == VECTOR){
		sprintf(msg_error, "Asignacion incompatible.\n");
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;
	}
	$1.tipo = getTipo(tablaSimbolos, $1.lexema);
	if($1.tipo != $3.tipo){
		sprintf(msg_error, "Asignacion incompatible.\n");
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;
	}
	/* Generacion de codigo */
	if(getAmbito(tablaSimbolos, $1.lexema) == GLOBAL){
		asignar(yyout, $1.lexema, $3.es_direccion);	
	}else{
		if(getCategoria(tablaSimbolos, $1.lexema) == PARAMETRO){
			asignar_parametro(yyout, num_parametros_actual, getAdicional2local(tablaSimbolos, $1.lexema), $3.es_direccion);
		}
		else{
			asignar_local(yyout, getAdicional2local(tablaSimbolos, $1.lexema), $3.es_direccion);
		}
		
	}
}
| elemento_vector TOK_ASIGNACION exp {	fprintf(yyout , ";R44:\t<asignacion> ::= <elemento_vector> = <exp>\n");
	if($1.tipo != $3.tipo){
		sprintf(msg_error, "Asignacion incompatible.\n");
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;
	}
	/* Generacion de codigo */
	asignar_vector(yyout, $3.es_direccion);
};

elemento_vector:    TOK_IDENTIFICADOR TOK_CORCHETEIZQUIERDO exp TOK_CORCHETEDERECHO {fprintf(yyout , ";R48:\t<elemento_vector> ::= <identificador> [ <exp> ]\n");
			
			if(buscar_identificador(tablaSimbolos, $1.lexema) == -1){
				sprintf(msg_error, "Acceso a variable no declarada (%s)", $1.lexema);
				flag_semantico = 1;
				yyerror(msg_error);
				return 1;
			}

			if(getClase(tablaSimbolos, $1.lexema) != VECTOR){
				sprintf(msg_error, "Intento de indexacion de una variable que no es de tipo vector.\n");
				flag_semantico = 1;
				yyerror(msg_error);
				return 1;
			}

			if($3.tipo != A_ENTERO){
				sprintf(msg_error, "El indice en una operacion de indexacion tiene que ser de tipo entero.\n");
				flag_semantico = 1;
				yyerror(msg_error);
				return 1;
			}

			/* Propagacion de aributos */
			$$.tipo = getTipo(tablaSimbolos, $1.lexema);
			$$.es_direccion = 1;

			/* Generacion de codigo */
			escribir_operando_vector(yyout, $1.lexema, $3.es_direccion, getAdicional1(tablaSimbolos, $1.lexema));

};

condicional:  if_exp sentencias TOK_LLAVEDERECHA {fprintf(yyout , ";R50:\t<condicional> ::= if ( <exp> ) { <sentencias> }\n");
													/* Generacion de codigo */
													fprintf(yyout, "fin_si%d:\n", $1.etiqueta);	
												}
			| if_exp_sentencias TOK_ELSE TOK_LLAVEIZQUIERDA sentencias TOK_LLAVEDERECHA {fprintf(yyout , ";R51:\t<condicional> ::= if ( <exp> ) { <sentencias> } else { <sentencias> }\n");
													/* Generacion de codigo */
													fprintf(yyout, "fin_sino%d:\n", $1.etiqueta);
												};

if_exp: TOK_IF TOK_PARENTESISIZQUIERDO exp TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA{
											if($3.tipo != A_BOOLEANO){
												sprintf(msg_error, "Condicional con condicion de tipo int.\n");
												flag_semantico = 1;
												yyerror(msg_error);
												return 1;
											}
											$$.etiqueta = contador_if++;

											/* Generacion de codigo */
											fprintf(yyout, "\tpop dword eax\n");
											if($3.es_direccion == 1){
												fprintf(yyout, "\tmov ecx, [eax]\n");
												fprintf(yyout, "\tmov eax, ecx\n");
											}
											fprintf(yyout, "\tcmp eax, 0\n");
											fprintf(yyout, "\tje fin_si%d\n", $$.etiqueta);
											};

if_exp_sentencias: if_exp sentencias TOK_LLAVEDERECHA{
														/* Se propagan los atributos */
														$$.etiqueta = $1.etiqueta;
														/* Generacion de codigo */
														fprintf(yyout, "\tjmp fin_sino%d\n", $1.etiqueta);
														fprintf(yyout, "fin_si%d:\n", $1.etiqueta);
													};

bucle: while_exp sentencias TOK_LLAVEDERECHA {fprintf(yyout , ";R52:\t<bucle> ::= while ( <exp> ) { <sentencias> }\n");
												/* Generacion de codigo */
												fprintf(yyout, "\tjmp inicio_while%d\n", $1.etiqueta);
												fprintf(yyout, "fin_while%d:\n", $1.etiqueta);
											};

while_exp: while exp TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA{
													if($2.tipo != A_BOOLEANO){
														sprintf(msg_error, "Bucle con condicion de tipo int.\n");
														flag_semantico = 1;
														yyerror(msg_error);
														return 1;
													}

													$$.etiqueta = $1.etiqueta;
													/* Generacion de codigo */
													fprintf(yyout, "\tpop dword eax\n");
													if($2.es_direccion == 1){
														fprintf(yyout, "\tmov ecx, [eax]\n");
														fprintf(yyout, "\tmov eax, ecx\n");
													}
													fprintf(yyout, "\tcmp eax, 0\n");
													fprintf(yyout, "\tje fin_while%d\n", $$.etiqueta);
												};

while: TOK_WHILE TOK_PARENTESISIZQUIERDO{
											$$.etiqueta = contador_while++;
											/* Generacion de codigo */
											fprintf(yyout, "inicio_while%d:\n", $$.etiqueta);
										};



lectura: TOK_SCANF TOK_IDENTIFICADOR {	fprintf(yyout , ";R54:\t<lectura> ::= scanf <identificador>\n");
										if(buscar_identificador(tablaSimbolos, $2.lexema) == -1){

											sprintf(msg_error, "Acceso a variable no declarada (%s)", $2.lexema);
											flag_semantico = 1;
											yyerror(msg_error);
											return 1;
										}
										if(getCategoria(tablaSimbolos, $2.lexema) == FUNCION){
											sprintf(msg_error, "Asignacion incompatible.\n");
											flag_semantico = 1;
											yyerror(msg_error);
											return 1;
										}
										else if(getClase(tablaSimbolos, $2.lexema) == VECTOR){
											sprintf(msg_error, "Variable local de tipo no escalar.\n");
											flag_semantico = 1;
											yyerror(msg_error);
											return 1;
										}

										/* Ya hemos comprobado que el identificador pertenece a una variable
										   o parametro, ahora tenemos que hacer la generacion de codigo */
										 /* Lo que hay que hacer es pushear la direccion de memoria donde
										    vamos a guardar el dato */
										if(ambito_abierto == 0 || getAmbito(tablaSimbolos, $2.lexema) == GLOBAL){
											/* Vamos a guardar la direccion de una variable global */
											escribir_operando(yyout, $2.lexema, 1); /* 1 porque es direccion */
										} else {
											/* Estamos en el ambito local y vamos a escribir una variable o un parametro */
											if(getCategoria(tablaSimbolos, $2.lexema) == PARAMETRO){/* CASO DEL PARAMETRO */
												/* Hacemos lo mismo pero llamamos a una funcion diferente porque la formula es diferente*/
												escribir_operando_parametro(yyout, num_parametros_actual, getAdicional2local(tablaSimbolos, $2.lexema));	
											} else {/* CASO DE LA VARIABLE LOCAL*/
												/* Tenemos que sacar de su lexema su posicion de declaracion,
												con eso obtener la direccion con la formula y acceder a su contenido*/
												escribir_operando_local(yyout, getAdicional2local(tablaSimbolos, $2.lexema));
											}
										}

										/* Una vez hemos pusheado la direccion, leemos */
										if(getTipo(tablaSimbolos, $2.lexema) == ENTERO){
											fprintf(yyout, "\tcall scan_int\n");
										} else {
											fprintf(yyout, "\tcall scan_boolean\n");
										}
										fprintf(yyout, "\tadd esp, 4\n");
									};
									
escritura: TOK_PRINTF exp {fprintf(yyout , ";R56:\t<escritura> ::= printf <exp>\n");
	escribir(yyout, $2.es_direccion, $2.tipo);
};

retorno_funcion: TOK_RETURN exp {fprintf(yyout , ";R61:\t<retorno_funcion> ::= return <exp>\n");
	/* Retorno de la funcion es el mismo que el de exp */
	if(tipo_actual_funcion != $2.tipo){
		sprintf(msg_error, "Se debe retornar una expresion del mismo tipo que la funcion.\n");
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;
	}
	/* Hay que comprobar que se llama dentro de una funcion */
	if(ambito_abierto == 0){
		sprintf(msg_error, "Sentencia de retorno fuera del cuerpo de una función.\n");
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;
	}
	/* Variable global para comprobar si hay sentencia de retorno en una
	   funcion */
	fn_return++;
	/* Generacion de codigo */
	escribirFinalFuncion(yyout, $2.es_direccion);
};

exp:  exp TOK_MAS exp {fprintf(yyout , ";R72:\t<exp> ::= <exp> + <exp>\n");
						if($1.tipo != A_ENTERO || $3.tipo != A_ENTERO){
							sprintf(msg_error, "Operacion aritmetica con operandos boolean.\n");
							flag_semantico = 1;
							yyerror(msg_error);
							return 1;							
						}
						$$.tipo = A_ENTERO;
						$$.es_direccion = 0;
						/* Generacion de codigo */
						sumar(yyout, $1.es_direccion, $3.es_direccion);
					}
	| exp TOK_MENOS exp {fprintf(yyout , ";R73:\t<exp> ::= <exp> - <exp>\n");
						if($1.tipo != A_ENTERO || $3.tipo != A_ENTERO){
							sprintf(msg_error, "Operacion aritmetica con operandos boolean.\n");
							flag_semantico = 1;
							yyerror(msg_error);
							return 1;							
						}
						$$.tipo = A_ENTERO;
						$$.es_direccion = 0;
						/* Generacion de codigo */
						restar(yyout, $1.es_direccion, $3.es_direccion);
					}
	| exp TOK_DIVISION exp {fprintf(yyout , ";R74:\t<exp> ::= <exp> / <exp>\n");
							if($1.tipo != A_ENTERO || $3.tipo != A_ENTERO){
								sprintf(msg_error, "Operacion aritmetica con operandos boolean.\n");
								flag_semantico = 1;
								yyerror(msg_error);
								return 1;							
							}
							$$.tipo = A_ENTERO;
							$$.es_direccion = 0;
							/* Generacion de codigo */
							dividir(yyout, $1.es_direccion, $3.es_direccion);
						}
	| exp TOK_ASTERISCO exp {fprintf(yyout , ";R75:\t<exp> ::= <exp> * <exp>\n");
								if($1.tipo != A_ENTERO || $3.tipo != A_ENTERO){
									sprintf(msg_error, "Operacion aritmetica con operandos boolean.\n");
									flag_semantico = 1;
									yyerror(msg_error);
									return 1;							
								}
								$$.tipo = A_ENTERO;
								$$.es_direccion = 0;
								/* Generacion de codigo */
								multiplicar(yyout, $1.es_direccion, $3.es_direccion);
							}
	| exp TOK_AND exp {fprintf(yyout , ";R77:\t<exp> ::= <exp> && <exp>\n");
						if($1.tipo != A_BOOLEANO || $3.tipo != A_BOOLEANO){
							sprintf(msg_error, "Operacion logica con operandos int.\n");
							flag_semantico = 1;
							yyerror(msg_error);
							return 1;
						}
						$$.tipo = A_BOOLEANO;
						$$.es_direccion=0;
						/* Generacion de codigo*/
						y(yyout, $1.es_direccion, $3.es_direccion);
						}
	| exp TOK_OR exp {fprintf(yyout , ";R78:\t<exp> ::= <exp> || <exp>\n");
						if($1.tipo != A_BOOLEANO || $3.tipo != A_BOOLEANO){
							sprintf(msg_error, "Operacion logica con operandos int.\n");
							flag_semantico = 1;
							yyerror(msg_error);
							return 1;
						}
						$$.tipo = A_BOOLEANO;
						$$.es_direccion=0;
						/* Generacion de codigo*/
						o(yyout, $1.es_direccion, $3.es_direccion);}
	| TOK_MENOS exp %prec contrario {fprintf(yyout , ";R76:\t<exp> ::= - <exp>\n");
										if($2.tipo != A_ENTERO){
											sprintf(msg_error, "Operacion aritmetica con operandos boolean.\n");
											flag_semantico = 1;
											yyerror(msg_error);
											return 1;							
										}
										$$.tipo = A_ENTERO;
										$$.es_direccion = 0;
										/* Generacion de codigo */
										cambiar_signo(yyout, $2.es_direccion);
									} 
	| TOK_NOT exp {fprintf(yyout , ";R79:\t<exp> ::= ! <exp>\n");
						if($2.tipo != A_BOOLEANO){
							sprintf(msg_error, "Operacion logica con operandos int.\n");
							flag_semantico = 1;
							yyerror(msg_error);
							return 1;
						}
						$$.tipo = A_BOOLEANO;
						$$.es_direccion=0;
						no(yyout, $2.es_direccion, contador_no);
						contador_no++;
		
	}
	| TOK_IDENTIFICADOR {fprintf(yyout, ";R80:\t<exp> ::= <identificador>\n");
						if(buscar_identificador(tablaSimbolos, $1.lexema) == -1){
							sprintf(msg_error, "Acceso a variable no declarada (%s)", $1.lexema);
							flag_semantico = 1;
							yyerror(msg_error);
							return 1;	
						}

						/* Caso si se está pasando una funcion como parametro de otra funcion */
						/* Hay que comprobar que estamos extrayendo parametros y que el identificador corresponde al de una funcion */
						if(en_explist == 1 && getCategoria(tablaSimbolos, $1.lexema) == FUNCION){
							sprintf(msg_error, "No esta permitido el uso de llamadas a funciones como parametros de otras funciones.\n");
							flag_semantico = 1;
							yyerror(msg_error);
							return 1;	
						}
						
						if(getTipo(tablaSimbolos, $1.lexema) == ENTERO)
							$$.tipo = A_ENTERO;
						else if(getTipo(tablaSimbolos, $1.lexema) == BOOLEANO)
							$$.tipo = A_BOOLEANO;
							
						if(ambito_abierto == 0 || getAmbito(tablaSimbolos, $1.lexema) == GLOBAL){ /* Para cuando nos encontramos en el ambito global */
							/* Caso si el identificador es un parametro de funcion */
							/* Se tiene que pushear el valor no su direccion */
							if(es_parametro_funcion == 1){
								$$.es_direccion = 0;
								pasarArgumentoAValor(yyout, $1.lexema);
							}
							else{
								$$.es_direccion = 1;
								escribir_operando(yyout, $1.lexema, 1); /* Uno porque es direccion */
							}
						} else { /* Para cuando nos encontramos en el ambito local */
						
							if(getCategoria(tablaSimbolos, $1.lexema) == PARAMETRO){/* CASO DEL PARAMETRO */
								/* Hacemos lo mismo pero llamamos a una funcion diferente porque la formula es diferente*/
								escribir_operando_parametro(yyout, num_parametros_actual, getAdicional2local(tablaSimbolos, $1.lexema));	
							}
							else{/* CASO DE LA VARIABLE LOCAL*/
								/* Tenemos que sacar de su lexema su posicion de declaracion,
								con eso obtener la direccion con la formula y acceder a su contenido*/
								escribir_operando_local(yyout, getAdicional2local(tablaSimbolos, $1.lexema));
							}
							$$.es_direccion = 1;
						}
					}
	| constante {	fprintf(yyout, ";R81:\t<exp> ::= <constante>\n");
					$$.tipo = $1.tipo;
					$$.es_direccion = $1.es_direccion;
					$$.valor = $1.valor;
				}
	| TOK_PARENTESISIZQUIERDO exp TOK_PARENTESISDERECHO {	fprintf(yyout, ";R82:\t<exp> ::= ( <exp> )\n");
															$$.tipo = $2.tipo;
															$$.es_direccion = $2.es_direccion;
														}
	| TOK_PARENTESISIZQUIERDO comparacion TOK_PARENTESISDERECHO {	fprintf(yyout , ";R83:\t<exp> ::= ( <comparacion> )\n");
																	$$.tipo = $2.tipo;
																	$$.es_direccion = $2.es_direccion;
																}
	| elemento_vector  {	fprintf(yyout , ";R85:\t<exp> ::= <elemento_vector>\n");
							$$.tipo = $1.tipo;
							$$.es_direccion = $1.es_direccion;
						}
	| idf_llamada_funcion TOK_PARENTESISIZQUIERDO lista_expresiones TOK_PARENTESISDERECHO {
		fprintf(yyout , ";R88:\t<exp> ::= <identificador> ( <lista_expresiones> )\n");
		/* Caso si el numero de parametros no coincide con los de la declaracion de la funcion */
		if(num_parametros_llamada_actual != getAdicional1(tablaSimbolos ,$1.lexema)){
			sprintf(msg_error, " Numero incorrecto de parametros en llamada a funcion.\n");
			flag_semantico = 1;
			yyerror(msg_error);
			return 1;
		}
		else{

			/* Generacion de código */
			llamarFuncion(yyout, $1.lexema, num_parametros_llamada_actual);
			
			$$.tipo = getTipo(tablaSimbolos, $1.lexema);
			$$.es_direccion = 0;
			
			/* Bajamos el flag que indica que las referencias a funciones ya no
			   son parametros de funcion */
			en_explist = 0;
			
			/* Bajamos el flag que indica que las variables a reducir ya no son
			   parametros de funcion */
			es_parametro_funcion = 0;
		}
	};

idf_llamada_funcion : TOK_IDENTIFICADOR {	
	/* Caso si se está llamando a una funcion que no existe */
	if(buscar_identificador(tablaSimbolos, $1.lexema) == -1){
		sprintf(msg_error, " Acceso a variable no declarada (%s).\n", $1.lexema);
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;	
	}
	/* Caso si se está haciendo una llamada a algo que no es una funcion */
	if(getCategoria(tablaSimbolos, $1.lexema) != FUNCION){
		/* FALTA ESTO */
		/* Error desconocido xdd */
	}
	/* Caso si se está pasando una funcion como parametro de otra funcion */
	if(en_explist == 1){
		sprintf(msg_error, " No esta permitido el uso de llamadas a funciones como parametros de otras funciones.\n");
		flag_semantico = 1;
		yyerror(msg_error);
		return 1;	
	}
	else{
		num_parametros_llamada_actual = 0;
		/* Activamos el flag para indicar que no se pueden pasar funciones como
		   parametros */
		en_explist = 1;
		/* Activamos el flag para indicar que las variables se pasan por valor */
		es_parametro_funcion = 1;
		strcpy($$.lexema, $1.lexema);
	}
};

lista_expresiones: 	  exp resto_lista_expresiones {
	fprintf(yyout , ";R89:\t<lista_expresiones> ::= <exp> <resto_lista_expresiones>\n");
	num_parametros_llamada_actual++;
}
					| /* vacio */ {fprintf(yyout , ";R90:\t<lista_expresiones> ::=\n");};

resto_lista_expresiones:	  TOK_COMA exp resto_lista_expresiones {
	fprintf(yyout , ";R91:\t <resto_lista_expresiones> ::= , <exp> <resto_lista_expresiones>\n");
	num_parametros_llamada_actual++;
}
							|  /* vacio */ {fprintf(yyout , ";R92:\t <resto_lista_expresiones> ::=\n");};

comparacion:	  exp TOK_IGUAL exp {fprintf(yyout , ";R93:\t<comparacion> ::= <exp> == <exp>\n");
										if($1.tipo != A_ENTERO || $3.tipo != A_ENTERO){
											sprintf(msg_error, "Comparacion con operandos boolean.\n");
											flag_semantico = 1;
											yyerror(msg_error);
											return 1;							
										}
										$$.tipo = A_BOOLEANO;
										$$.es_direccion = 0;
										/* Generacion de codigo */
										igual(yyout, $1.es_direccion, $3.es_direccion, contador_iguales);
										contador_iguales++;
									}
				| exp TOK_DISTINTO exp {fprintf(yyout , ";R94:\t<comparacion> ::= <exp> != <exp>\n");
											if($1.tipo != A_ENTERO || $3.tipo != A_ENTERO){
												sprintf(msg_error, "Comparacion con operandos boolean.\n");
												flag_semantico = 1;
												yyerror(msg_error);
												return 1;							
											}
											$$.tipo = A_BOOLEANO;
											$$.es_direccion = 0;
											/* Generacion de codigo */
											distinto(yyout, $1.es_direccion, $3.es_direccion, contador_distintos);
											contador_distintos++;
										}
				| exp TOK_MENORIGUAL exp {fprintf(yyout , ";R95:\t<comparacion> ::= <exp> <= <exp>\n");
											if($1.tipo != A_ENTERO || $3.tipo != A_ENTERO){
												sprintf(msg_error, "Comparacion con operandos boolean.\n");
												flag_semantico = 1;
												yyerror(msg_error);
												return 1;							
											}
											$$.tipo = A_BOOLEANO;
											$$.es_direccion = 0;
											/* Generacion de codigo */
											menorigual(yyout, $1.es_direccion, $3.es_direccion, contador_menorigual);
											contador_menorigual++;
										}
				| exp TOK_MAYORIGUAL exp {fprintf(yyout , ";R96:\t<comparacion> ::= <exp> >= <exp>\n");
											if($1.tipo != A_ENTERO || $3.tipo != A_ENTERO){
												sprintf(msg_error, "Comparacion con operandos boolean.\n");
												flag_semantico = 1;
												yyerror(msg_error);
												return 1;							
											}
											$$.tipo = A_BOOLEANO;
											$$.es_direccion = 0;
											/* Generacion de codigo */
											mayorigual(yyout, $1.es_direccion, $3.es_direccion, contador_mayorigual);
											contador_mayorigual++;
										}
				| exp TOK_MENOR exp {fprintf(yyout , ";R97:\t<comparacion> ::= <exp> < <exp>\n");
										if($1.tipo != A_ENTERO || $3.tipo != A_ENTERO){
											sprintf(msg_error, "Comparacion con operandos boolean.\n");
											flag_semantico = 1;
											yyerror(msg_error);
											return 1;							
										}
										$$.tipo = A_BOOLEANO;
										$$.es_direccion = 0;
										/* Generacion de codigo */
										menor(yyout, $1.es_direccion, $3.es_direccion, contador_menor);
										contador_menor++;
									}
				| exp TOK_MAYOR exp {fprintf(yyout , ";R98:\t<comparacion> ::= <exp> > <exp>\n");
										if($1.tipo != A_ENTERO || $3.tipo != A_ENTERO){
											sprintf(msg_error, "Comparacion con operandos boolean.\n");
											flag_semantico = 1;
											yyerror(msg_error);
											return 1;							
										}
										$$.tipo = A_BOOLEANO;
										$$.es_direccion = 0;
										/* Generacion de codigo */
										mayor(yyout, $1.es_direccion, $3.es_direccion, contador_mayor);
										contador_mayor++;
									};

constante:	  constante_logica {fprintf(yyout , ";R99:\t<constante> ::= <constante_logica>\n");
								$$.valor = $1.valor;
								$$.es_direccion = $1.es_direccion;
								$$.tipo = $1.tipo;
}
			| constante_entera {fprintf(yyout , ";R100:\t<constante> ::= <constante_entera>\n");
								$$.valor = $1.valor;
								$$.es_direccion = $1.es_direccion;
								$$.tipo = $1.tipo;
};

constante_logica:	  TOK_TRUE {	fprintf(yyout , ";R102:\t<constante_logica> ::= true\n");
									/* análisis semántico */
									$$.tipo = A_BOOLEANO;
									$$.es_direccion = 0;
									/* Generación de codigo */
									fprintf(yyout, "\tpush dword 1\n");
								}
					| TOK_FALSE {	fprintf(yyout , ";R103:\t<constante_logica> ::= false\n");
									/* análisis semántico */
									$$.tipo = A_BOOLEANO;
									$$.es_direccion = 0;
									/* Generacion de codigo */
									fprintf(yyout, "\tpush dword 0\n");
									};

constante_entera:	  TOK_CONSTANTE_ENTERA {	fprintf(yyout , ";R104:\t<constante_entera> ::= TOK_CONSTANTE_ENTERA\n");
												/* análisis semántico */
												$$.tipo = A_ENTERO;
												$$.es_direccion = 0;
												$$.valor = $1.valor;
												sprintf(str_valor, "%d", $1.valor);
												escribir_operando(yyout, str_valor, 0);
											};


idpf : TOK_IDENTIFICADOR {	strcpy($$.lexema, $1.lexema); };
%%
