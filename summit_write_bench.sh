#!/bin/bash

#BSUB -alloc_flags smt4

module restore

if [ -z "$WORK_DIR" ]; then
    echo "No WORK_DIR set!"
    exit 1
fi

if [ -z "$TARGET_FILE_SIZE" ]; then
    echo "No TARGET_FILE_SIZE set"
    exit 1
fi

if [ -z "$NUM_WRITES" ]; then
    echo "Defaulting NUM_WRITES=1"
    export NUM_WRITES=1
fi

if [ -z "$OUTPUT" ]; then
    echo "No $OUTPUT file set!"
fi

cd $WORK_DIR

REPO_ROOT=`git rev-parse --show-toplevel`
echo "Script dir = $REPO_ROOT"
SCRIPTS_DIR=$REPO_ROOT/scripts/

ARGS="-n $NUM_WRITES"
if [ -n "$USE_BEST_SPLIT" ]; then
    echo "Using best split"
    ARGS="$ARGS -best-split"
fi

if [ -n "$DUMP_RAW" ]; then
    echo "Dumping raw"
    ARGS="$ARGS -raw"
fi

NUM_NODES=`tail -n +2 $LSB_DJOB_HOSTFILE | uniq | wc -l`
export LIBBAT_SUMMIT_CORES=1

export WRITE_DIR=$SCRATCH/libbat_bench_output/$OUTPUT-${LSB_BATCH_JID}/
mkdir $WRITE_DIR

env

# Each particle is 124 bytes
jsrun -n ${NUM_NODES} -c ALL_CPUS -r 1 -a 42 -b none ./adaptive_io_test/adaptive_io_test \
    $TARGET_FILE_SIZE \
    $WRITE_DIR/$OUTPUT \
    -uniform 32768 \
    -non-spatial-attrib uniform 2 \
    -non-spatial-attrib normal 4 \
    -spatial-attrib sphere 4 \
    -spatial-attrib gradient 4 \
    -double \
    $ARGS

