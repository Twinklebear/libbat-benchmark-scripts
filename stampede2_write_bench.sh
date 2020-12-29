#!/bin/bash

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
    echo "No OUTPUT file set!"
fi

cd $WORK_DIR

REPO_ROOT=`git rev-parse --show-toplevel`
SCRIPTS_DIR=$REPO_ROOT/scripts/
echo "Script dir = $SCRIPTS_DIR"
source $SCRIPTS_DIR/set_stampede2_vars.sh

ARGS="-n $NUM_WRITES"
if [ -n "$USE_BEST_SPLIT" ]; then
    echo "Using best split"
    ARGS="$ARGS -best-split"
fi

if [ -n "$DUMP_RAW" ]; then
    echo "Dumping raw"
    ARGS="$ARGS -raw"
fi

export WRITE_DIR=$SCRATCH/libbat_bench_output/$OUTPUT-${SLURM_JOBID}/
mkdir $WRITE_DIR
lfs setstripe -c 32 -S 8M $WRITE_DIR

env

# Each particle is 124 bytes
ibrun ./adaptive_io_test/adaptive_io_test \
    $TARGET_FILE_SIZE \
    $WRITE_DIR/$OUTPUT \
    -uniform 32768 \
    -non-spatial-attrib uniform 2 \
    -non-spatial-attrib normal 4 \
    -spatial-attrib sphere 4 \
    -spatial-attrib gradient 4 \
    -double \
    $ARGS

