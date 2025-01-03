#!/bin/bash

SCRIPT_DIR=$(dirname $(realpath $0))
BENCH_IO_ST_MIN=$SCRIPT_DIR/bench_io_min.sh

NPROC=${1:-$(nproc)}

echo "Spawn bench processes..."
for i in $(seq 1 $NPROC); do
    mkdir tmp-$i
    cd tmp-$i
    $BENCH_IO_ST_MIN &
    cd ..
done

echo "Wait for bench processes..."
wait

echo "Cleanup..."
for i in $(seq 1 $NPROC); do
    rm -rf tmp-$i
done
