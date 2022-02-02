/* 
 * Fichero: tablaSimbolos.c
 * Autores: Miguel Álvarez Lesmes & Marcos Asenjo Gonzalez
 * Curso: 2017-18
 */

#include <stdio.h>
#include <stdlib.h>
#include "tablaSimbolos.h"

struct _TablaSimbolos{            
	TABLA_HASH *global; /* Tabla hash global */
	TABLA_HASH *local;  /* Tabla hash local */
	int tamano; /* Tamano de las tablas hash*/
};

TABLA_SIMBOLOS *crear_tabla_simbolos(int tam){

	TABLA_SIMBOLOS *ts = NULL;

	if(tam < 1) return NULL;

	ts = (TABLA_SIMBOLOS *) malloc(sizeof(TABLA_SIMBOLOS));
	if(!ts){
		return NULL;
	}

	if((ts->global = crear_tabla(tam)) == NULL){
		free(ts);
		return NULL;
	}
	
	ts->local = NULL;
	ts->tamano = tam;
	return ts;
}

void destruir_tabla_simbolos(TABLA_SIMBOLOS * ts){
	if(!ts) return;
	if(ts->local != NULL){
		liberar_tabla(ts->local);
	}

	liberar_tabla(ts->global);

	free(ts);
}

STATUS declare_variable(TABLA_SIMBOLOS * ts, char * lexema, TIPO tipo, CLASE clase, int id, int longitud_vector, int pos_declaracion){
	if(!lexema || !ts) return ERR;
	if(ts->local != NULL){
		if(insertar_simbolo(ts->local, lexema, VARIABLE, tipo, clase, id, longitud_vector, pos_declaracion) == ERR)
			return ERR;
	}
	else{
		if(insertar_simbolo(ts->global, lexema, VARIABLE, tipo, clase, id, longitud_vector, pos_declaracion) == ERR)
			return ERR;
	}

	return OK;
}

STATUS declarar_funcion(TABLA_SIMBOLOS * ts, char * lexema, TIPO tipo, CLASE clase, int id, int extra1, int extra2){
	if(!lexema || !ts) return ERR;
	if(ts->local != NULL) return ERR;

	if((ts->local = crear_tabla(ts->tamano)) == NULL)
		return ERR;

	if(insertar_simbolo(ts->global, lexema, FUNCION, tipo, clase, id, extra1, extra2) == ERR){
		liberar_tabla(ts->local);
		return ERR;
	}
	else if(insertar_simbolo(ts->local, lexema, FUNCION, tipo, clase, id, extra1, extra2) == ERR){
		liberar_tabla(ts->local);
		return ERR;
	}
	return OK;
}

STATUS declarar_parametro(TABLA_SIMBOLOS * ts, char * lexema, TIPO tipo, CLASE clase, int id, int param_extra){
	if(!lexema || !ts) return ERR;
	if(ts->local == NULL) return ERR;

	if(insertar_simbolo(ts->local, lexema, PARAMETRO, tipo, clase, id, 0, param_extra) == ERR)
		return ERR;

	return OK;
}

int buscar_identificador(TABLA_SIMBOLOS *ts, char * lexema){
	INFO_SIMBOLO *simbolo = NULL;
	if(lexema == NULL || ts == NULL) return -1;

	if((simbolo = buscar_simbolo(ts->local, lexema)) != NULL)
		return simbolo->id;
	else if((simbolo = buscar_simbolo(ts->global, lexema)) != NULL)
		return simbolo->id;
	else{

		return -1;
	}

	return -1;
}

void cerrar_ambito(TABLA_SIMBOLOS *ts){
	if(ts->local == NULL) return;

	liberar_tabla(ts->local);
	ts->local = NULL;
	return;
}

TIPO getTipo(TABLA_SIMBOLOS *ts, char *lexema){
	INFO_SIMBOLO *simbolo = NULL;
	if(!ts || !lexema) return ERROR;

	if((simbolo = buscar_simbolo(ts->local, lexema)) != NULL)
		return simbolo->tipo;
	else if((simbolo = buscar_simbolo(ts->global, lexema)) != NULL)
		return simbolo->tipo;

	return ERROR;
}

int getValor(TABLA_SIMBOLOS *ts, char *lexema){
	INFO_SIMBOLO *simbolo = NULL;
	if(!ts || !lexema) return -1;

	if((simbolo = buscar_simbolo(ts->local, lexema)) != NULL)
		return simbolo->adicional1;
	else if((simbolo = buscar_simbolo(ts->global, lexema)) != NULL)
		return simbolo->adicional1;

	return -1;
}

STATUS setValor(TABLA_SIMBOLOS *ts, char *lexema, int valorEscalar){
	INFO_SIMBOLO *simbolo = NULL;
	if(!ts || !lexema) return ERR;

	if((simbolo = buscar_simbolo(ts->local, lexema)) != NULL){
		simbolo->adicional1 = valorEscalar;
		return OK;
	}
	else if((simbolo = buscar_simbolo(ts->global, lexema)) != NULL){
		simbolo->adicional1 = valorEscalar;
		return OK;
	}

	return ERR;
}

STATUS setAdicional1(TABLA_SIMBOLOS *ts, char * lexema, int adicional1){
	INFO_SIMBOLO *simbolo = NULL;
	if(!ts || adicional1 < 0) return ERR;
	
	if((simbolo = buscar_simbolo(ts->global, lexema)) != NULL){
		simbolo->adicional1 = adicional1;
		return OK;
	}

	return ERR;
}

STATUS setAdicional2global(TABLA_SIMBOLOS *ts, char * lexema, int adicional2){
	INFO_SIMBOLO *simbolo = NULL;
	if(!ts || adicional2 < 0 || lexema == NULL) return ERR;

	if((simbolo = buscar_simbolo(ts->global, lexema)) != NULL){
		simbolo->adicional2 = adicional2;
		return OK;
	}

	return ERR;
}

STATUS setAdicional2local(TABLA_SIMBOLOS *ts, char * lexema, int adicional2){
	INFO_SIMBOLO *simbolo = NULL;
	if(!ts || adicional2 < 0 || lexema == NULL) return ERR;

	if((simbolo = buscar_simbolo(ts->local, lexema)) != NULL){
		simbolo->adicional2 = adicional2;
		return OK;
	}

	return ERR;
}

int getAdicional1(TABLA_SIMBOLOS *ts, char * lexema){
	INFO_SIMBOLO *simbolo = NULL;
	if(!ts || lexema == NULL) return ERR;
		
	if((simbolo = buscar_simbolo(ts->global, lexema)) != NULL){
		return simbolo->adicional1;
	}

	return -1;
}

int getAdicional2global(TABLA_SIMBOLOS *ts, char * lexema){
	INFO_SIMBOLO *simbolo = NULL;
	if(!ts || lexema == NULL) return ERR;
	
	if((simbolo = buscar_simbolo(ts->global, lexema)) != NULL){
		return simbolo->adicional2;
	}

	return -1;
}

int getAdicional2local(TABLA_SIMBOLOS *ts, char * lexema){
	INFO_SIMBOLO *simbolo = NULL;
	if(!ts || lexema == NULL) return ERR;
	
	if((simbolo = buscar_simbolo(ts->local, lexema)) != NULL){
		return simbolo->adicional2;
	}

	return -1;
}

CATEGORIA getCategoria(TABLA_SIMBOLOS *ts, char * lexema){
	INFO_SIMBOLO *simbolo = NULL;
	if(!ts || lexema == NULL) return ERR;
	
	if((simbolo = buscar_simbolo(ts->local, lexema)) != NULL)
		return simbolo->categoria;
		
	if((simbolo = buscar_simbolo(ts->global, lexema)) != NULL){
		return simbolo->categoria;
	}

	return -1;
}

CLASE getClase(TABLA_SIMBOLOS *ts, char * lexema){
	INFO_SIMBOLO *simbolo = NULL;
	if(!ts || lexema == NULL) return ERR;
	
	if((simbolo = buscar_simbolo(ts->local, lexema)) != NULL)
		return simbolo->clase;
		
	if((simbolo = buscar_simbolo(ts->global, lexema)) != NULL){
		return simbolo->clase;
	}

	return -1;
}

AMBITO getAmbito(TABLA_SIMBOLOS *ts, char *lexema){
	if(buscar_simbolo(ts->local, lexema) != NULL)
		return LOCAL;
	else if(buscar_simbolo(ts->global, lexema) != NULL)
		return GLOBAL;
	
	return ERRAMB;
}

