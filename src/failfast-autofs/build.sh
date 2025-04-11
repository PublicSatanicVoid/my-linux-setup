#!/bin/sh

gcc -fPIC -shared -ldl -o statspeeder.so statspeeder.c
