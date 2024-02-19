#!/bin/bash

if [ -z "$1" ]; then
    echo "$0 --setup <Nfiles> <Ndirs>"
    echo "$0 --bench-st <Nfiles> <Ndirs> <Niter>"
    echo "$0 --bench-mt <Nfiles> <Ndirs> <Niter> <Nthr>"
    exit 1
fi

if [ "$1" == "--setup" ]; then
    echo "Creating $3 dirs each with $2 files..."
    for i in $(seq 1 $3); do
        mkdir bench-$i
        for j in $(seq 1 $2); do
            dd if=/dev/zero of=bench-$i/bench-$j bs=1M count=1 >/dev/null 2>/dev/null
        done
    done
elif [ "$1" == "--bench-st" ]; then
    for i in $(seq 1 $3); do
        for j in $(seq 1 $2); do
            for k in $(seq 1 $4); do
                stat bench-$i/bench-$j >/dev/null
            done
        done
    done
elif [ "$1" == "--bench-mt" ]; then
    for i in $(seq 1 $4); do
        "$0" --bench-st $2 $3 $4 &
    done
    wait
fi

