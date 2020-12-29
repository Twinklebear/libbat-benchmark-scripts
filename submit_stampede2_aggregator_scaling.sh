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

if [ -z "$2" ]; then
    echo "Arg 2 must be the config to run (uniform, exp-gradient)"
    exit 1
fi

REPO_ROOT=`git rev-parse --show-toplevel`
SCRIPT_DIR=$REPO_ROOT/scripts
export NUM_WRITES=15

# Size of data on a rank in MB when using 32k uniformly
# generated particles
export PARTICLES_PER_RANK=32768
uniform_rank_size_mb=4
restrict_agg_size_mb=512
num_nodes=$1
if [ "${PARTITION:0:3}" == "skx" ]; then
    ranks_per_node=48
else
    ranks_per_node=64
fi

num_ranks=$(($ranks_per_node * $num_nodes))
min_size=$uniform_rank_size_mb
max_size=$(($num_ranks * $uniform_rank_size_mb))
echo "Max size if agg to 0 $max_size"

# Limit the max aggregation size we test to some reasonable amount
# to limit the number of tests run
if [ "$max_size" -gt "$restrict_agg_size_mb" ]; then
    echo "Max size exceeds restriction size, restricting to $restrict_agg_size_mb"
    # The x/1 is to truncate num tests to an int
    num_tests=`echo "x = (l($restrict_agg_size_mb/$uniform_rank_size_mb)/l(2)); scale = 0; x / 1" | bc -l`
else
    # The x/1 is to truncate num tests to an int
    num_tests=`echo "x = (l($num_ranks)/l(2)); scale = 0; x / 1" | bc -l`
fi

if [ "$2" == "uniform" ]; then
    export BENCH_SCRIPT=$SCRIPT_DIR/stampede2_write_bench.sh
elif [ "$2" == "exp-gradient" ]; then
    export BENCH_SCRIPT=$SCRIPT_DIR/stampede2_write_non_uniform_bench.sh
else
    echo "Unrecognized config $2"
    exit 1
fi

#export FIXED_AGGREGATION=1
echo "Running $num_tests tests"

# Note: Each rank has a bit more than 4MB, so 4MB and 8MB target file size
# produce the same result of file per-process aggregation. So we start at 8MB
for i in `seq 1 $num_tests`; do
    export TARGET_FILE_SIZE=$(($uniform_rank_size_mb * 2**$i))
    echo "Test $i target file size ${TARGET_FILE_SIZE}MB"
    export OUTPUT=agg-scaling-$i-${2}32k-${num_nodes}${PARTITION}
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

