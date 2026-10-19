#!/bin/bash

yacc -d -y --debug --verbose Group_09.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'
flex Group_09.l
echo 'Generated the scanner C file'
g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ y.o l.o -o parser.exe
echo 'All ready, running'
./parser.exe input.txt
