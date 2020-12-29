#!/bin/bash

module restore default

if [ -z "$WORK_DIR" ]; then
    echo "No WORK_DIR set!"
    exit 1
fi

if [ -z "$OUTPUT" ]; then
    echo "No OUTPUT file set!"
fi

if [ -z "$IOR_EXE" ]; then
    echo "The IOR_EXE is not set!"
fi

if [ -z "$IOR_SCRIPT" ]; then
    echo "The IOR_SCRIPT is not set!"
fi

cd $WORK_DIR

NUM_NODES=`tail -n +2 $LSB_DJOB_HOSTFILE | uniq | wc -l`

env

jsrun -n ${NUM_NODES} -c ALL_CPUS -r 1 -a 42 -b none $IOR_EXE \
    -f=$IOR_SCRIPT \
    -g \
    -o=$SCRATCH/libbat_ior_output/$OUTPUT-${LSB_JOBID}

