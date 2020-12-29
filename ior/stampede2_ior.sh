#!/bin/bash

module restore

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

env

ibrun $IOR_EXE \
    -f=$IOR_SCRIPT \
    -g \
    -o=$SCRATCH/libbat_ior_output/$OUTPUT-${SLURM_JOBID}

