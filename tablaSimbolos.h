#ifndef TABLASIMBOLOS_H
#define TABLASIMBOLOS_H

#include "tablaHash.h"

typedef struct _TablaSimbolos TABLA_SIMBOLOS;

TABLA_SIMBOLOS *crear_tabla_simbolos(int tam);
void destruir_tabla_simbolos(TABLA_SIMBOLOS * ts);
STATUS declare_variable(TABLA_SIMBOLOS * ts, char * lexema, TIPO tipo, CLASE clase, int id, int longitud_vector, int pos_declaracion);
STATUS declarar_funcion(TABLA_SIMBOLOS * ts, char * lexema, TIPO tipo, CLASE clase, int id, int extra1, int extra2);
STATUS declarar_parametro(TABLA_SIMBOLOS * ts, char * lexema, TIPO tipo, CLASE clase, int id, int param_extra);
int buscar_identificador(TABLA_SIMBOLOS *ts, char * lexema);
void cerrar_ambito(TABLA_SIMBOLOS *ts);
TIPO getTipo(TABLA_SIMBOLOS *ts, char *lexema);
int getValor(TABLA_SIMBOLOS *ts, char *lexema);
STATUS setValor(TABLA_SIMBOLOS *ts, char *lexema, int valorEscalar);
STATUS setAdicional1(TABLA_SIMBOLOS *ts, char * lexema,int adicional1);
STATUS setAdicional2local(TABLA_SIMBOLOS *ts, char * lexema,int adicional2);
STATUS setAdicional2global(TABLA_SIMBOLOS *ts, char * lexema,int adicional2);
int getAdicional1(TABLA_SIMBOLOS *ts, char * lexema);
CATEGORIA getCategoria(TABLA_SIMBOLOS *ts, char * lexema);
CLASE getClase(TABLA_SIMBOLOS *ts, char * lexema);
AMBITO getAmbito(TABLA_SIMBOLOS *ts, char *lexema);
int getAdicional2global(TABLA_SIMBOLOS *ts, char * lexema);
int getAdicional2local(TABLA_SIMBOLOS *ts, char * lexema);

#endif