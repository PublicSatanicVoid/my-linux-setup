#!/bin/bash

SCRIPT_DIR=$(dirname $(realpath $0))
BENCH_MT_EXE=$SCRIPT_DIR/bench_io_mt_min.sh

MAX_NPROC=${1:-$(nproc)}

nproc=1
while [ $nproc -le $MAX_NPROC ]; do
    
    echo "** nproc=$nproc **"

    $BENCH_MT_EXE $nproc
    sleep 10
    $BENCH_MT_EXE
    sleep 10

    nproc=$(( $nproc * 2 ))
done
