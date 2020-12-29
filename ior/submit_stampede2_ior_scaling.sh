#!/bin/bash

if [ -z "$WORK_DIR" ]; then
    echo "WORK_DIR must be set"
    exit 1
fi

if [ -z "$PARTITION" ]; then
    echo "PARTITION to run the job in must be set"
    exit 1
fi

REPO_ROOT=`git rev-parse --show-toplevel`
SCRIPTS_DIR=$REPO_ROOT/scripts/ior

if [ "$1" == "fpp" ]; then
    export IOR_SCRIPT=$SCRIPTS_DIR/ior-fpp-no-fsync.txt
elif [ "$1" == "fpp-reorder" ]; then
    export IOR_SCRIPT=$SCRIPTS_DIR/ior-fpp-no-fsync-reorder.txt
elif [ "$1" == "shared" ]; then
    export IOR_SCRIPT=$SCRIPTS_DIR/ior-shared-file-no-fsync.txt
elif [ "$1" == "hdf5" ]; then
    export IOR_SCRIPT=$SCRIPTS_DIR/ior-hdf5-no-fsync.txt
else
    echo "Set the IOR benchmark type to run (fpp/shared/hdf5) as arg 1"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Set min number of nodes to run to as second arg (should be power of 2)"
    exit 1
fi

if [ -z "$3" ]; then
    echo "Set max number of nodes to run to as second arg (should be power of 2)"
    exit 1
fi

min_nodes=$2
max_nodes=$3

if [ "${PARTITION:0:3}" == "skx" ]; then
    ranks_per_node=48
else
    ranks_per_node=64
fi

start_run=`echo "x = (l($min_nodes)/l(2)); scale = 0; x / 1" | bc -l`
end_run=`echo "x = (l($max_nodes)/l(2)); scale = 0; x / 1" | bc -l`

export IOR_EXE=~/work/ior/install/bin/ior

for i in `seq $start_run $end_run`; do
    num_nodes=$((2**i))
    num_ranks=$(($ranks_per_node * $num_nodes))

    echo "Test $i on $num_nodes nodes"
    export OUTPUT=ior-$1-${num_nodes}${PARTITION}

    sbatch -N $num_nodes -n $num_ranks -t 00:20:00 -p ${PARTITION} \
        --ntasks-per-node $ranks_per_node \
        -o $OUTPUT-%j.out \
        -J $OUTPUT \
        $SCRIPTS_DIR/stampede2_ior.sh
done

