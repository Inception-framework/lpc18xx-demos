#!/bin/bash

find . -name "*.ll" -exec rm -rf {} \;
find . -name "klee-*" -exec rm -rf {} \;

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SAMPLES="$(find ./Examples/* -type d -printf "%f\n")"

if [ "$#" != 1 ]; then
        echo "Illegal number of parameters"
        echo "$0 <SAMPLE_NAME>"
	echo "Supported samples names : "
	echo $SAMPLES
        exit
fi

#Check if sample name is valid
if echo "$SAMPLES" | grep -q "$1"; then
	echo "Building ...";
	cp Makefile Examples/$1/Makefile
	make -C Examples/$1
	make clean -C Examples/$1
        rm Examples/$1/Makefile
else
	echo "Sample does not exist ...";
        echo "Supported samples names : "
        echo $SAMPLES
fi
