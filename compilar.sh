#!/bin/bash
nasm -g -o ejecutableNasm.o -f elf32 miSalida.asm
gcc -m32 -o ejecutableNasm ejecutableNasm.o alfalib.o