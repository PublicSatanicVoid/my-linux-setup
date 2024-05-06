#!/bin/sh

source ./seccomp/bin/activate

#exec "$CC" main.c $CFLAGS -o main $LDFLAGS -lseccomp
#exec "$CC" -Wall test2.c $CFLAGS -o test2 $LDFLAGS -lseccomp
EXTRA_CFLAGS="-fno-stack-protector -fno-function-sections -fomit-frame-pointer -finline-functions -Ofast -march=native"
time "$CC" -Wall test3.c $CFLAGS $EXTRA_CFLAGS -o test3 $LDFLAGS -lseccomp

