#!/bin/bash

set -e

input_file="${1:-input.c}"

yacc -d -y --debug --verbose Group_09.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'
flex Group_09.l
echo 'Generated the scanner C file'
g++ -fpermissive -w -c -o l.o lex.yy.c
# if the above command doesn't work try g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ y.o l.o -o a.exe
echo 'All ready, running'
./a.exe "$input_file"
echo 'logfile'
cat Group_09_log.txt
