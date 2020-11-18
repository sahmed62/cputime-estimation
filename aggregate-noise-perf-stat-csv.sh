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

REPETITION=6
DURATION_MIN=5
DURATION_MAX=14

FIRST_STATFILE="${STATDIR}/system-noise-${DURATION_MIN}sec-1.csv"
if [ ! -r ${FIRST_STATFILE} ] ; then
    echo "ERROR: failed to find readable file \"${FIRST_STATFILE}\"" >& 2
    exit 1
else
    REFERENCE_HEADER="$(head -n 1 ${FIRST_STATFILE})"
    echo "Workload, Target Duration (sec), Repetition, ${REFERENCE_HEADER}" >> ${AGGREGATEOUT}
fi

workload="system-noise"
# For each repetitionn
for r in $( seq 1 1 ${REPETITION} ) ; do
    # For each duration
    for d in $( seq ${DURATION_MIN} 1 ${DURATION_MAX} ) ; do
        # Check the processed perf-stat output exists and
        # it's header matches, then dump it's contents into the aggregate
        PERFSTATOUTFILE="${STATDIR}/${workload}-${d}sec-${r}.csv"
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
                echo "${workload}, ${d}, ${r}, ${STATFILEDATA}" >> ${AGGREGATEOUT}
            fi
        fi
    done
done

