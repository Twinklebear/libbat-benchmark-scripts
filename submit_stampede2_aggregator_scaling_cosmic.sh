#!/bin/bash

if [ -z "$WORK_DIR" ]; then
    echo "WORK_DIR must be set"
    exit 1
fi

if [ -z "$PARTITION" ]; then
    echo "PARTITION to run the job in must be set"
    exit 1
fi

if [ -z "$1" ]; then
    echo "Arg 1 must be the number of nodes to submit the job on"
    exit 1
fi

if [ -z "${INPUT_FILES[@]}" ]; then
    echo "One or more INPUT_FILES are required!"
    exit 1
fi

echo "Input files: ${INPUT_FILES[@]}"
for f in ${INPUT_FILES[@]}; do
    echo "would run on $f"
done

REPO_ROOT=`git rev-parse --show-toplevel`
SCRIPT_DIR=$REPO_ROOT/scripts
export NUM_WRITES=15

# Size of data on a rank in MB when using 32k uniformly
# generated particles
# Particles in the cosmic web sim are 3 float attribs + 3 float positions
particle_size=24
total_particles=51214260

num_nodes=$1
if [ "${PARTITION:0:3}" == "skx" ]; then
    ranks_per_node=48
else
    ranks_per_node=64
fi
num_ranks=$(($ranks_per_node * $num_nodes))

total_bytes=$(($particle_size * $total_particles))
fpp_size=$(($total_bytes / $num_ranks + $total_bytes % $num_ranks))

# The x/1 is to truncate num tests to an int
ranks_pow2=`echo "x = (l($num_ranks)/l(2)); scale = 0; x / 1" | bc -l`
num_tests=$(($ranks_pow2 > 5 ? 5 : $ranks_pow2))

echo "fpp size: $fpp_size"
echo "Total bytes: $total_bytes"

fpp_size_mb=$(($fpp_size / 1000000))
total_bytes_mb=$(($total_bytes / 1000000))
echo "fpp size (MB): $fpp_size_mb"
echo "Total MB: $total_bytes_mb"

echo "Running $num_tests tests"
export BENCH_SCRIPT=$SCRIPT_DIR/stampede2_write_bat_bench.sh

for i in `seq 0 $num_tests`; do
    export TARGET_FILE_SIZE=$((($fpp_size * 2**$i) / 1000000))
    echo "Test $i target file size ${TARGET_FILE_SIZE}MB"
    export OUTPUT=agg-scaling-$i-cosmic-${num_nodes}${PARTITION}
    if [ -n "$DUMP_RAW" ]; then
        export OUTPUT=${OUTPUT}-raw
        echo "Dumping raw data"
    fi
    if [ -n "$FIXED_AGGREGATION" ]; then
        export OUTPUT=${OUTPUT}-fixed
        echo "Fixed aggregation"
    fi

    sbatch -N $num_nodes -n $num_ranks -t 00:10:00 -p $PARTITION \
        --ntasks-per-node $ranks_per_node \
        -o $OUTPUT-%j.out \
        -J $OUTPUT \
        $BENCH_SCRIPT
done

