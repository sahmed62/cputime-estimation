#! /bin/bash -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ $# != 1 ] ; then
    echo "Usage: $0 <path to results directory>" >& 2
    exit 1
else
    STATDIR="$(cd $1 > /dev/null 2>&1 && pwd)"
    AGGREGATEOUT="${STATDIR}.csv"
    if [ ! -d ${STATDIR} ] ; then
        echo "ERROR: failed to find directory \"${STATDIR}\"" >& 2
        exit 1
    elif ! rm -f ${AGGREGATEOUT} || ! touch ${AGGREGATEOUT} ; then
        echo "ERROR: failed to create new \"${AGGREGATEOUT}\"" >& 2
        exit 1
    fi
fi

# All but memrate, since memrate hangs
STRESSNG_FUNC_ARRAY=(   "ackermann"         \
                        "hamming"           \
                        "gray"              \
                        "hanoi"             \
                        "branch"            \
                        "longjmp"           \
                        "funccall"          \
                        "funcret"           \
                        "cache-l1"          \
                        "cache-l2"          \
                        "cache-l3"          \
                        "stream-mem"        \
                        "matrix-mult-l1"    \
                        "matrix-mult-l2"    \
                        "matrix-mult-l3"    \
                        "matrix-mult-mem"   \
                        "matrix-trans-l1"   \
                        "matrix-trans-l2"   \
                        "matrix-trans-l3"   \
                        "matrix-trans-mem"  \
                        "matrix-add-l1"     \
                        "matrix-add-l2"     \
                        "matrix-add-l3"     \
                        "matrix-add-mem"    \
                        "matrix-prod-l1"    \
                        "matrix-prod-l2"    \
                        "matrix-prod-l3"    \
                        "matrix-prod-mem"   \
                        "tree-rb-mem"       \
                        "tree-binary-mem"   \
                        "heapsort-mem"      \
                        "mergesort-mem"     \
                        "qsort-mem"         \
                        "radixsort-mem"     \
                        "skiplist-mem"      \
                        "lsearch-mem"   )

BACKGROUND_FUNC_ARRAY=( "gray"
                        "matrix-mult-l1"    \
                        "matrix-prod-mem"   \
                        "matrix-trans-l3"   \
                        "stream-mem"        \
                        "matrix-add-l3" )

REPETITION=1
DURATION_MIN=5
DURATION_MAX=14

FIRST_STATFILE="${STATDIR}/${STRESSNG_FUNC_ARRAY[0]}-${BACKGROUND_FUNC_ARRAY[0]}-${DURATION_MIN}sec-1.csv"
if [ ! -r ${FIRST_STATFILE} ] ; then
    echo "ERROR: failed to find readable file \"${FIRST_STATFILE}\"" >& 2
    exit 1
else
    REFERENCE_HEADER="$(head -n 1 ${FIRST_STATFILE})"
    echo "Workload, Background, TargetDuration, Repetition, ${REFERENCE_HEADER}" >> ${AGGREGATEOUT}
fi

REPETITION=1
DURATION_MIN=5
DURATION_MAX=14

# For each repetitionn
for r in $( seq 1 1 ${REPETITION} ) ; do
    # For each duration
    for d in $( seq ${DURATION_MIN} 1 ${DURATION_MAX} ) ; do
        # Run docker image for background load
        for background in ${BACKGROUND_FUNC_ARRAY[@]} ; do
            # Run docker image for foreground load
            for workload in ${STRESSNG_FUNC_ARRAY[@]} ; do
                # Check the processed perf-stat output exists and
                # it's header matches, then dump it's contents into the aggregate
                PERFSTATOUTFILE="${STATDIR}/${workload}-${background}-${d}sec-${r}.csv"
                if [ ! -r ${PERFSTATOUTFILE} ] ; then
                    echo "ERROR: failed to find readable file \"${PERFSTATOUTFILE}\"" >& 2
                    exit 1
                else
                    STATFILEHEADER="$(head -n 1 ${PERFSTATOUTFILE})"
                    if [ "${STATFILEHEADER}" != "${REFERENCE_HEADER}" ] ; then
                        echo "ERROR: mis-matched header for \"${PERFSTATOUTFILE}\"" >& 2
                        exit 1
                    else
                        STATFILEDATA="$(tail -n 1 ${PERFSTATOUTFILE})"
                        echo "${workload}, ${background}, ${d}, ${r}, ${STATFILEDATA}" >> ${AGGREGATEOUT}
                    fi
                fi                
            done
        done
    done
done

