#!/bin/sh

gcc -o dir_tag dir_tag.c -Ofast -march=x86-64-v2 -mtune=native && cp dir_tag ~/libexec
gcc -o git_tag git_tag.c -Ofast -march=x86-64-v2 -mtune=native && cp dir_tag ~/libexec
