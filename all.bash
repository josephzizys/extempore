#!/bin/bash

case $(uname) in
        *NT*) EXTEMPORE_OS=windows ;;
	Linux) EXTEMPORE_OS=linux ;;
	Darwin) EXTEMPORE_OS=darwin ;;
	*) echo Unsupported OS:  $(uname) >&2 ; exit 1 ;;
esac
export EXTEMPORE_OS

if [ -z "$EXT_LLVM_DIR" ]; then 
	if [ ! -f config/llvm.bash ]; then
		echo Missing config/llvm.bash file.  See INSTALL. >&2
		exit 1	
	fi
	. config/llvm.bash
fi

EXT_LLVM_CONFIG_SCRIPT="$EXT_LLVM_DIR/bin/llvm-config --libs"
EXT_LLVM_LIBS=`$EXT_LLVM_CONFIG_SCRIPT`
export EXT_LLVM_LIBS

EXT_USER_ARGS=$@
export EXT_USER_ARGS

make -f top.make extempore
