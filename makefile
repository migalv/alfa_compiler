CC = gcc -ansi -Wall -pedantic -g

all: alfa

alfa: y.tab.o main.o lex.yy.o generacion.o tablaHash.o tablaSimbolos.o
	$(CC) -o $@ main.o lex.yy.o y.tab.o generacion.o tablaHash.o tablaSimbolos.o

lex.yy.c: alfa.l
	flex alfa.l

y.tab.c: alfa.y alfa.h
	bison -dyv alfa.y

lex.yy.o: lex.yy.c y.tab.h
	$(CC) -c lex.yy.c

y.tab.o: y.tab.c y.tab.h
	$(CC) -c y.tab.c

main.o: main.c
	$(CC) -c main.c

tablaSimbolos.o: tablaSimbolos.c tablaSimbolos.h
	$(CC) -c tablaSimbolos.c
	
tablaHash.o: tablaHash.c tablaHash.h
	$(CC) -c tablaHash.c

generacion.o: generacion.c generacion.h
	$(CC) -c generacion.c
	
clean:
	rm tablaSimbolos.o tablaHash.o generacion.o lex.yy.c y.tab.c y.tab.h alfa y.output *.asm lex.yy.o main.o y.tab.o
