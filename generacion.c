#include <stdio.h>
#include <stdlib.h>
#include "generacion.h"

void escribir_cabecera_compatibilidad(FILE *fpasm){
	return;
}

void escribir_subseccion_data(FILE *fpasm){
	if(fpasm == NULL) return;
	fprintf(fpasm, "segment .data\n");
	fprintf(fpasm, "\tmsg_div_cero db \"****Error de ejecucion: Division por cero.\", 0\n");
	fprintf(fpasm, "\tmsg_indice_fuera db \"****Error de ejecucion: Indice fuera de rango.\", 0\n");
	return;
}

void escribir_cabecera_bss(FILE *fpasm){
	if(fpasm == NULL) return;
	fprintf(fpasm, "segment .bss\n");
	fprintf(fpasm, "\t__esp resd 1\n");
	return;
}

void declarar_variable(FILE* fpasm, char * nombre,  int tipo,  int tamano){
	if(fpasm == NULL) return;
	if(tipo == ENTERO)
		fprintf(fpasm, "\t_%s resd %d\n", nombre, tamano);
	else
		fprintf(fpasm, "\t_%s resd %d\n", nombre, tamano);

	return;
}

void escribir_segmento_codigo(FILE *fpasm){
	if(fpasm == NULL) return;
	fprintf(fpasm, "segment .text\n");
	fprintf(fpasm, "\tglobal main\n");
	fprintf(fpasm, "\textern scan_int, print_int, scan_float, print_float, print_string, scan_boolean, print_boolean\n");
	fprintf(fpasm, "\textern print_endofline, print_blank\n");
	fprintf(fpasm, "\textern alfa_malloc, alfa_free, ld_float\n");

	return;
}

void escribir_inicio_main(FILE *fpasm){
	if(fpasm == NULL) return;
	fprintf(fpasm, "; ------------------------\n");
	fprintf(fpasm, "; PROCEDIMIENTO PRINCIPAL\n");
	fprintf(fpasm, "; ------------------------\n");

	fprintf(fpasm, "main: \n");
	fprintf(fpasm, "; GUARDA DE PUNTERO DE PILA\n");
	fprintf(fpasm, "\tmov dword [__esp] , esp\n");
	return;
}

void escribir_fin(FILE *fpasm){
	if(fpasm == NULL) return;
	fprintf(fpasm, "; RESTAURACION DE PUNTERO DE PILA\n");
	fprintf(fpasm, "\tmov dword esp, [__esp]\n");
	fprintf(fpasm, "\tret\n");
	fprintf(fpasm, "div_por_cero:\n");
	fprintf(fpasm, "\tpush dword msg_div_cero\n");
	fprintf(fpasm, "\tcall print_string\n");
	fprintf(fpasm, "\tmov dword esp, [__esp]\n");
	fprintf(fpasm, "\tret\n");
	fprintf(fpasm, "indice_fuera:\n");
	fprintf(fpasm, "\tpush dword msg_indice_fuera\n");
	fprintf(fpasm, "\tcall print_string\n");
	fprintf(fpasm, "\tmov dword esp, [__esp]\n");
	fprintf(fpasm, "\tret\n");

	return;
}

void escribir_operando(FILE* fpasm, char* nombre, int es_var){
	if(fpasm == NULL) return;
	if(es_var==0){ /* VALOR EXPLICITO */
		fprintf(fpasm, "\tpush dword %s\n", nombre);
	} else if(es_var==1){
		fprintf(fpasm, "\tpush dword _%s\n", nombre);
	} else {
		fprintf(stderr, "ERROR: VALOR DE ES_VAR INCORRECTO EN LA FUNCION ESCRIBIR_OPERANDO (VALORES VALIDOS 0 Y 1)\n");
		exit(1);
	}
	return;
}

void escribir_operando_local(FILE *fpasm, int posicionVariable){
	int valorAux = 0;
	if(fpasm == NULL) return;
	if(posicionVariable < 1){
		fprintf(stderr, "ERROR EN ESCRIBIR_OPERANDO_LOCAL: posicionVariable MENOR QUE 1 (posicionVariable = %d)\n", posicionVariable);
		exit(1);
	}
	valorAux = 4*posicionVariable; 
	/* Se pushea la direccion de memoria en la pila, con lea */
	fprintf(fpasm, "\tlea eax, [ebp-%d]\n", valorAux);
	fprintf(fpasm, "\tpush dword eax\n");
}

void escribir_operando_parametro(FILE *fpasm, int numero_parametros, int posicion_parametro){
	if(fpasm == NULL) return;
	/* Se pushea la direccion de memoria en la pila, con lea */
	fprintf(fpasm, "\tlea eax, [ebp+%d]\n", (4+(4*(numero_parametros-posicion_parametro))));
	fprintf(fpasm, "\tpush dword eax\n");
}

void escribir_operando_vector(FILE *fpasm, char *nombre, int es_dir_indice, int tamano_vector){
	if(fpasm == NULL) return;
	/* Se extrae el indice de la pila */
	fprintf(fpasm, "\tpop dword eax\n");
	if(es_dir_indice == 1){
		fprintf(fpasm, "\tmov dword eax, [eax]\n");
	}
	/* Si el indice es menor que 0, error en tiempo de ejecucion */
	fprintf(fpasm, "\tcmp eax, 0\n");
	fprintf(fpasm, "\tjl indice_fuera\n");
	/* Si el indice es mayor que el tamano del vector menos 1, tambien */
	fprintf(fpasm, "\tcmp eax, %d\n", tamano_vector-1);
	fprintf(fpasm, "\tjg indice_fuera\n");

	/* En este punto el indice es correcto y esta en eax */
	/* Ahora cargamos en edx la direccion de inicio del vector */
	fprintf(fpasm, "\tmov dword edx, _%s\n", nombre);
	fprintf(fpasm, "\tlea eax, [edx + eax*4]\n");
	fprintf(fpasm, "\tpush dword eax\n");
}

void asignar(FILE* fpasm, char* nombre, int es_referencia){
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpop dword eax\n");
	if(es_referencia == 0){ /*VALOR EXPLICITO */
		fprintf(fpasm, "\tmov [_%s], eax\n", nombre);
	} else if (es_referencia == 1){
		fprintf(fpasm, "\tmov ebx, [eax]\n");
		fprintf(fpasm, "\tmov [_%s], ebx\n", nombre);
	} else {
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION ASIGNAR (VALORES VALIDOS 0 Y 1)\n");
		exit(1);
	}
	return;
}

void asignar_local(FILE *fpasm, int posicionVariable, int es_referencia){
	int valorAux = 0;
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpop dword eax\n");
	valorAux = 4*posicionVariable;
	if(es_referencia == 0){
		fprintf(fpasm, "\tmov [ebp-%d], eax\n", valorAux);
	} else if (es_referencia == 1){
		fprintf(fpasm, "\tmov ebx, [eax]\n");
		fprintf(fpasm, "\tmov [ebp-%d], ebx\n", valorAux);
	} else {
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION ASIGNAR (VALORES VALIDOS 0 Y 1)\n");
		exit(1);
	} 
	
}

void asignar_parametro(FILE *fpasm, int numero_parametros, int posicion_parametro, int es_referencia){
	int valorAux = 0;
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpop dword eax\n");
	valorAux = 4+(4*(numero_parametros-posicion_parametro));
	if(es_referencia == 0){
		fprintf(fpasm, "\tmov [ebp+%d], eax\n", valorAux);
	} else if (es_referencia == 1){
		fprintf(fpasm, "\tmov ebx, [eax]\n");
		fprintf(fpasm, "\tmov [ebp+%d], ebx\n", valorAux);
	} else {
			fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION ASIGNAR (VALORES VALIDOS 0 Y 1)\n");
		exit(1);
	} 
	
}

void asignar_vector(FILE *fpasm, int es_referencia){
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpop dword eax\n");
	if(es_referencia == 1){
		fprintf(fpasm, "\tmov dword eax, [eax]\n"); /* Cargamos en eax el valor de la exp a asignar */
	}
	fprintf(fpasm, "\tpop dword edx\n"); /* Cargamos en edx la direccion del elemento del vector a asignar */
	fprintf(fpasm, "\tmov dword [edx], eax\n"); /* Hacemos la asignacion efectiva */
}

void sumar(FILE* fpasm, int es_referencia_1, int es_referencia_2){
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION SUMAR (VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	fprintf(fpasm, "\tadd eax, ebx\n");
	fprintf(fpasm, "\tpush dword eax\n");

	return;
}

void restar(FILE* fpasm, int es_referencia_1, int es_referencia_2){
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION RESTAR(VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	fprintf(fpasm, "\tsub eax, ebx\n");
	fprintf(fpasm, "\tpush dword eax\n");

	return;
}

void multiplicar(FILE* fpasm, int es_referencia_1, int es_referencia_2){
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION MULTIPLICAR(VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	fprintf(fpasm, "\timul ebx\n");
	fprintf(fpasm, "\tpush dword eax\n");
	return;
}

void dividir(FILE* fpasm, int es_referencia_1, int es_referencia_2){
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION DIVIDIR(VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	fprintf(fpasm, "\tcdq\n");
	fprintf(fpasm, "\tcmp ebx, 0\n");
	fprintf(fpasm, "\tje div_por_cero\n");
	fprintf(fpasm, "\tidiv ebx\n");

	fprintf(fpasm, "\tpush dword eax\n");
}

void o(FILE* fpasm, int es_referencia_1, int es_referencia_2){
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION OR(VALORES VALIDOS 0 Y 1)\n");
		exit(1);
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	fprintf(fpasm, "\tor eax, ebx\n");
	fprintf(fpasm, "\tpush dword eax\n");

	return;
}

void y(FILE* fpasm, int es_referencia_1, int es_referencia_2){
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION AND(VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	fprintf(fpasm, "\tand eax, ebx\n");
	fprintf(fpasm, "\tpush dword eax\n");

	return;
}

void cambiar_signo(FILE* fpasm, int es_referencia){
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpop dword eax\n");

	if(es_referencia !=1 && es_referencia != 0){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION CAMBIAR_SIGNO(VALORES VALIDOS 0 Y 1)\n");
		exit(1);
	}

	if(es_referencia == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	fprintf(fpasm, "\tmov ebx, eax\n");
	fprintf(fpasm, "\tsub eax, ebx\n");
	fprintf(fpasm, "\tsub eax, ebx\n");

	fprintf(fpasm, "\tpush dword eax\n");
	return;
}

void no(FILE *fpasm, int es_referencia, int cuantos_no){
	if(fpasm == NULL) return;

	fprintf(fpasm, "\tpop dword eax\n");

	if(es_referencia != 1 && es_referencia != 0){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION NO(VALORES VALIDOS 0 Y 1)\n");
		exit(1);
	}

	if(es_referencia == 1){
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}
	/* En eax esta el contenido a negar*/
	fprintf(fpasm, "\tcmp eax, 0\n");
	fprintf(fpasm, "\tje uno_%d\n", cuantos_no);
	fprintf(fpasm, "\tpush dword 0\n"); /* No es cero asi que en la pila guardamos un cero*/
	fprintf(fpasm, "\tjmp terminar_%d\n", cuantos_no);
	fprintf(fpasm, "uno_%d:\n", cuantos_no);
	fprintf(fpasm, "\tpush dword 1\n");
	fprintf(fpasm, "terminar_%d:\n", cuantos_no);
	return;
}

void igual(FILE *fpasm, int es_referencia_1, int es_referencia_2, int cuantos_iguales){
	if(!fpasm) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION SUMAR (VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	/* Comparamos y apilamos el resultado */
	fprintf(fpasm, "\tcmp eax, ebx\n");
	fprintf(fpasm, "\tje igual_%d\n", cuantos_iguales);
	fprintf(fpasm, "\tpush dword 0\n"); /* No son iguales asi que guardamos un cero */
	fprintf(fpasm, "\tjmp fin_igual_%d\n", cuantos_iguales);
	fprintf(fpasm, "igual_%d:\n", cuantos_iguales);
	fprintf(fpasm, "push dword 1\n"); /* Si ha saltado es que son iguales, pusheamos un 1 */
	fprintf(fpasm, "fin_igual_%d:\n", cuantos_iguales);
	return;
}

void distinto(FILE *fpasm, int es_referencia_1, int es_referencia_2, int cuantos_distintos){
	if(!fpasm) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION SUMAR (VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	/* Comparamos y apilamos el resultado */
	fprintf(fpasm, "\tcmp eax, ebx\n");
	fprintf(fpasm, "\tjne distinto_%d\n", cuantos_distintos);
	fprintf(fpasm, "\tpush dword 0\n"); /* No son iguales asi que guardamos un cero */
	fprintf(fpasm, "\tjmp fin_distinto_%d\n", cuantos_distintos);
	fprintf(fpasm, "distinto_%d:\n", cuantos_distintos);
	fprintf(fpasm, "push dword 1\n"); /* Si ha saltado es que son iguales, pusheamos un 1 */
	fprintf(fpasm, "fin_distinto_%d:\n", cuantos_distintos);
	return;
}

void menorigual(FILE *fpasm, int es_referencia_1, int es_referencia_2, int cuantos_menorigual){
	if(!fpasm) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION SUMAR (VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	/* Comparamos y apilamos el resultado */
	fprintf(fpasm, "\tcmp eax, ebx\n");
	fprintf(fpasm, "\tjle menorigual_%d\n", cuantos_menorigual);
	fprintf(fpasm, "\tpush dword 0\n"); /* No son iguales asi que guardamos un cero */
	fprintf(fpasm, "\tjmp fin_menorigual_%d\n", cuantos_menorigual);
	fprintf(fpasm, "menorigual_%d:\n", cuantos_menorigual);
	fprintf(fpasm, "push dword 1\n"); /* Si ha saltado es que son iguales, pusheamos un 1 */
	fprintf(fpasm, "fin_menorigual_%d:\n", cuantos_menorigual);
	return;
}

void mayorigual(FILE *fpasm, int es_referencia_1, int es_referencia_2, int cuantos_mayorigual){
	if(!fpasm) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION SUMAR (VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	/* Comparamos y apilamos el resultado */
	fprintf(fpasm, "\tcmp eax, ebx\n");
	fprintf(fpasm, "\tjge mayorigual_%d\n", cuantos_mayorigual);
	fprintf(fpasm, "\tpush dword 0\n"); /* No son iguales asi que guardamos un cero */
	fprintf(fpasm, "\tjmp fin_mayorigual_%d\n", cuantos_mayorigual);
	fprintf(fpasm, "mayorigual_%d:\n", cuantos_mayorigual);
	fprintf(fpasm, "push dword 1\n"); /* Si ha saltado es que son iguales, pusheamos un 1 */
	fprintf(fpasm, "fin_mayorigual_%d:\n", cuantos_mayorigual);
	return;
}

void menor(FILE *fpasm, int es_referencia_1, int es_referencia_2, int cuantos_menor){
	if(!fpasm) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION SUMAR (VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	/* Comparamos y apilamos el resultado */
	fprintf(fpasm, "\tcmp eax, ebx\n");
	fprintf(fpasm, "\tjl menor_%d\n", cuantos_menor);
	fprintf(fpasm, "\tpush dword 0\n"); /* No son iguales asi que guardamos un cero */
	fprintf(fpasm, "\tjmp fin_menor_%d\n", cuantos_menor);
	fprintf(fpasm, "menor_%d:\n", cuantos_menor);
	fprintf(fpasm, "push dword 1\n"); /* Si ha saltado es que son iguales, pusheamos un 1 */
	fprintf(fpasm, "fin_menor_%d:\n", cuantos_menor);
	return;	
}

void mayor(FILE *fpasm, int es_referencia_1, int es_referencia_2, int cuantos_mayor){
	if(!fpasm) return;
	fprintf(fpasm, "\tpop dword ebx\n");
	fprintf(fpasm, "\tpop dword eax\n");

	if((es_referencia_1 != 0 && es_referencia_1 !=1) || (es_referencia_2 !=0 && es_referencia_2 !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION SUMAR (VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}

	if(es_referencia_1 == 1){ /* ES UNA REFERENCIA*/
		fprintf(fpasm, "\tmov ecx, [eax]\n");
		fprintf(fpasm, "\tmov eax, ecx\n");
	}

	if(es_referencia_2 == 1){ /* ES UNA REFERENCIA */
		fprintf(fpasm, "\tmov ecx, [ebx]\n");
		fprintf(fpasm, "\tmov ebx, ecx\n");
	}

	/* Comparamos y apilamos el resultado */
	fprintf(fpasm, "\tcmp eax, ebx\n");
	fprintf(fpasm, "\tjg mayor_%d\n", cuantos_mayor);
	fprintf(fpasm, "\tpush dword 0\n"); /* No son iguales asi que guardamos un cero */
	fprintf(fpasm, "\tjmp fin_mayor_%d\n", cuantos_mayor);
	fprintf(fpasm, "mayor_%d:\n", cuantos_mayor);
	fprintf(fpasm, "push dword 1\n"); /* Si ha saltado es que son iguales, pusheamos un 1 */
	fprintf(fpasm, "fin_mayor_%d:\n", cuantos_mayor);
	return;
}

void leer(FILE* fpasm, char* nombre, int tipo){
	if(fpasm == NULL) return;
	fprintf(fpasm, "\tpush dword _%s\n", nombre);
	
	if(tipo == ENTERO)
		fprintf(fpasm, "\tcall scan_int\n");
	else
		fprintf(fpasm, "\tcall scan_boolean\n");
	
	fprintf(fpasm, "\tadd esp, 4\n");
	return;
}


void escribir(FILE* fpasm, int es_referencia, int tipo){
	if(fpasm == NULL) return;
	if(es_referencia == 1){ /* Lo que hay en la pila es la referencia a una variable*/
		fprintf(fpasm, "\tpop dword eax\n");
		fprintf(fpasm, "\tmov ebx, [eax]\n");
		fprintf(fpasm, "\tpush dword ebx\n");
	}
	/* Si no es referencia el valor esta directamente en la pila, asi que simplemente
	   debemos llamar a la funcion que nos interese*/
	if(tipo == ENTERO){
		fprintf(fpasm, "\tcall print_int\n");
		fprintf(fpasm, "\tcall print_endofline\n");
	}else{
		fprintf(fpasm, "\tcall print_boolean\n");
		fprintf(fpasm, "\tcall print_endofline\n");
	}
	
	/* Finalmente solo debemos actualizar el puntero de la pila*/
	fprintf(fpasm, "\tadd esp, 4\n");
	return;
}

void pasarArgumentoAValor(FILE* fpasm, char* nombre){
	if(fpasm == NULL || nombre == NULL){
		fprintf(stderr, "ERROR: ARCHIVO NO EXISTE O NOMBRE DE VARIABLE ES NULL AL PASAR ARGUMENTO A VALOR\n");
		exit(1);
	}
	
	fprintf(fpasm, "\tpush dword [_%s]\n", nombre);

	return;
}

void llamarFuncion(FILE* fpasm, char* nombre, int numArgumentos){
	if(fpasm == NULL || nombre == NULL){
		fprintf(stderr, "ERROR: ARCHIVO NO EXISTE O NOMBRE DE VARIABLE ES NULL AL LLAMAR A LA FUNCION\n");
		exit(1);
	}
	
	fprintf(fpasm, "\tcall _%s\n", nombre);
	
	fprintf(fpasm, "\tadd esp, %d\n", (4*numArgumentos));
	
	fprintf(fpasm, "\tpush dword eax\n");
}

void escribirInicioFuncion(FILE* fpasm, char* nombre, int numVariablesLocales){
	if(fpasm == NULL || nombre == NULL){
		fprintf(stderr, "ERROR: ARCHIVO NO EXISTE O NOMBRE DE VARIABLE ES NULL AL ESCRIBIR EL INICIO DE UNA FUNCION\n");
		exit(1);
	}
	else if(numVariablesLocales < 0){
		fprintf(stderr, "ERROR: NUMERO DE VARIABLES LOCALES ES NEGATIVO\n");
		exit(1);
	}
	
	fprintf(fpasm, "_%s:\n", nombre);
	
	fprintf(fpasm, "\tpush ebp\n");

	fprintf(fpasm, "\tmov ebp, esp\n");

	fprintf(fpasm, "\tsub esp, %d\n", (4*numVariablesLocales));
}

void escribirFinalFuncion(FILE* fpasm, int es_referencia){
	if(fpasm == NULL){
		fprintf(stderr, "ERROR: ARCHIVO NO EXISTE O NOMBRE DE VARIABLE ES NUL AL ESCRIBIR EL FINAL DE LA FUNCIONL\n");
		exit(1);
	}
	else if((es_referencia != 0 && es_referencia !=1)){
		fprintf(stderr, "ERROR: VALOR DE ES_REFERENCIA INCORRECTO EN LA FUNCION ESCRIBIR FINAL FUNCION (VALORES VALIDOS 0 Y 1)\n");
		exit(1);	
	}
	
	fprintf(fpasm, "\tpop dword eax\n");
	
	if(es_referencia == 1)
		fprintf(fpasm,"\tmov eax , [eax]\n");

	fprintf(fpasm, "mov dword esp, ebp\n");
	
	fprintf(fpasm, "\tpop dword ebp\n");

	fprintf(fpasm, "\tret\n");
}