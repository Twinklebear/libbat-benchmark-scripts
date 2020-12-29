#!/bin/bash

get_physical_cores() {
    echo `grep "^cpu\\scores" /proc/cpuinfo | uniq | awk '{print $4}'`
}

get_logical_cores() {
    echo `grep "^processor" /proc/cpuinfo | uniq | wc -l`
}

set_thread_vars() {
    export I_MPI_PIN_RESPECT_CPUSET=0
    export I_MPI_PIN_RESPECT_HCA=0
    export I_MPI_PIN_DOMAIN=omp

    CPU_MODEL=`cat /proc/cpuinfo | grep "model name" | uniq`
    # If we're on Xeon use all logical cores, if on Phi use only phyiscal cores
    if [ -n "`echo $CPU_MODEL | grep 'Xeon(R)'`" ]; then
        echo "CPU $CPU_MODEL is Xeon, using all logical cores"
        export OMP_NUM_THREADS=$(get_logical_cores)
        export I_MPI_PIN_PROCESSOR_LIST=all
    else
        echo "CPU $CPU_MODEL is Xeon Phi, using all physical cores"
        export OMP_NUM_THREADS=$(get_physical_cores)
        export I_MPI_PIN_PROCESSOR_LIST=allcores
    fi

    export MPICH_MAX_THREAD_SAFETY=multiple
}

set_thread_vars

