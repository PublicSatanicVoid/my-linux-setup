#!/bin/sh

source ./seccomp/bin/activate

EXTRA_CFLAGS="-fno-stack-protector -fno-function-sections -fomit-frame-pointer "
EXTRA_CFLAGS+="-finline-functions -Ofast -march=native"

"$CC" -Wall main.c $CFLAGS $EXTRA_CFLAGS -o procbox $LDFLAGS -lseccomp

