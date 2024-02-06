#!/bin/bash

#########################################################################################
# SYNOPSIS: Benchmark for IO performance using a mixture of read/write/stat system calls.
#           Results are only meaningful in comparison to other results from this same
#           benchmark. **This is a single-threaded benchmark.**
# AUTHOR:   Adam Priebe
# CHANGELOG:
#           2023/10/30: Initial version, based on existing tools but simplified for
#                       demonstration purposes.
#########################################################################################


if [ "$1" == "-h" ]; then
    echo "$(basename "$0"): single-host, single-thread IO benchmark."
    echo ""
    echo "usage: $(basename "$0") [dir=cwd]"
    echo "files are created in 'dir' and cleaned up when the benchmark finishes."
    exit 1
fi

NITER=5
NFILES=100
DUMMYTEXT="The quick brown fox jumps over the lazy dog."
NLINES=50
WRITE_RATIO=1
READ_RATIO=2
STAT_RATIO=2
WORKDIR="${1:-$(pwd)}"
#echo "Work dir: $WORKDIR"

# Create the contents of the dummy files up front
contents=""
for i in $(seq 1 $NLINES); do
    contents="$contents$DUMMYTEXT\n"
done

# Start the benchmark, log the beginning
start=$(date +%s)


for i in $(seq 1 $NITER); do

    for j in $(seq 1 $WRITE_RATIO); do
        # write files
        for k in $(seq 1 $NFILES); do
            echo -e "$contents" >| "$WORKDIR/bench_${i}_${k}"
        done
    done

    for j in $(seq 1 $READ_RATIO); do
        # read files
        for k in $(seq 1 $NFILES); do
            x=$(<"$WORKDIR/bench_${i}_${k}")
        done
    done

    for j in $(seq 1 $STAT_RATIO); do
        # stat files
        for k in $(seq 1 $NFILES); do
            stat "$WORKDIR/bench_${i}_${k}" 1>/dev/null
        done
    done
done

finish=$(date +%s)

# This is how long the benchmark took
echo "$(( $finish - $start ))"

# Clean up benchmark files, but don't include this in the time.
for i in $(seq 1 $NITER); do
    for j in $(seq 1 $NFILES); do
        rm "$WORKDIR/bench_${i}_${j}"
    done
done

