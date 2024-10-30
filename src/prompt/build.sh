#!/bin/sh

function CC {
    (set -x; gcc -Ofast -flto=auto -flto-partition=one -march=x86-64-v2 -mtune=generic -Wl,-O3 -static -static-libgcc -static-libstdc++ -Wl,-static -s "$@")
    return $?
}

CC -o dir_tag dir_tag.c && cp dir_tag ~/libexec/
CC -o git_tag git_tag.c && cp git_tag ~/libexec/
