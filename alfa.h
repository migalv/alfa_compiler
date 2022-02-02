#ifndef _ALFA_H
#define _ALFA_H

#define MAX_LENGTH 100
#define TAM_SIMBOLOS_MAX 100
#define MAX_TAMANIO_VECTOR 64

/* Retorno de función error/ok */
typedef enum { A_ERR = 0, A_OK = 1 } ALFASTATUS;

/* Categoría de un símbolo: variable, parámetro de función o función */
typedef enum { A_VARIABLE, A_PARAMETRO, A_FUNCION, A_NOASIG_CATEG } ALFACATEGORIA;

/* Tipo de un símbolo: sólo se trabajará con enteros y booleanos */
typedef enum { A_ENTERO, A_BOOLEANO, A_NOASIG_TIPO } ALFATIPO;

/* Clase de un símbolo: pueden ser variables atómicas (escalares) o listas/arrays (vectores) */
typedef enum { A_ESCALAR, A_VECTOR, A_NOASIG_CLASE } ALFACLASE;

typedef struct{
    char lexema[MAX_LENGTH+1];           /* identificador */
    ALFACATEGORIA categoria;    /* categoría */    
    ALFATIPO tipo;              /* tipo */
    ALFACLASE clase;            /* clase */
    int id;				/* Id del elemento */
    int valor; /* El valor en caso de ser una constante entera */
    int longitud; /* Longitud de un vector */
    int numParam; /* Numero de parametros si es una funcion */
    int posicionLlamada; /* posicion en llamada a funcion si parametro*/
    int posicionDeclaracion; /* Posicion de declaracion si variable local de funcion*/
    int numVarLocales; /* Numero de variables locales si funcion */
    int es_direccion;
    int etiqueta; /* Etiqueta de salto en las condiciones*/
}tipo_atributos;


#endif