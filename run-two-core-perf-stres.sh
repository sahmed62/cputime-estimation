#! /bin/bash -xe

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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

# Setup perf output directory structure
STATDIR="${SCRIPT_DIR}/perf-stat-out/single-core/"
INCONTAINERLOGDIR="/home/perf-stress-ng/perf-stat-out/single-core/"

if ! mkdir -p ${STATDIR} ; then
    echo "ERROR: failed to create output directory" >&2
    exit 1
fi

CONTAINER_IMAGE_NAME="perf-stress-ng:latest"
CONTAINER_IMAGE_HASH="$(docker images -q perf-stress-ng:latest)"

MAIN_EXECUTION_CORE="7"
BACKGROUND_CORE="5"

MAIN_EXECUTION_CIDFILE="${SCRIPT_DIR}/main.cid"
BACKGROUND_CIDFILE="${SCRIPT_DIR}/background.cid"

# Check if image does not exist
if [ -z "${CONTAINER_IMAGE_HASH}" ] ; then
    # then build it
    if ! docker build ${SCRIPT_DIR} --tag ${CONTAINER_IMAGE_NAME} ; then
        echo "ERROR: failed to build containger image" >&2
        exit 1
    fi
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
                PERFSTATOUTFILE="${INCONTAINERLOGDIR}/${workload}-${background}-${d}sec-${r}.csv"
                if ! docker run --rm                                        \
                                -d                                          \
                                --cpuset-cpus ${BACKGROUND_CORE}            \
                                -v ${SCRIPT_DIR}:/home/perf-stress-ng:ro    \
                                --cidfile="${BACKGROUND_CIDFILE}"           \
                                ${CONTAINER_IMAGE_NAME}                     \
                                ${background}                               \
                                -t $( expr ${d} + 3 ) -q ; then
                    echo "ERROR: failed to run background container for ${PERFSTATOUTFILE}" >&2
                    exit 1
                else
                    sleep 1
                    if ! docker run --rm                                    \
                                    -it                                     \
                                    --privileged                            \
                                    --cpuset-cpus ${MAIN_EXECUTION_CORE}    \
                                    -v ${SCRIPT_DIR}:/home/perf-stress-ng   \
                                    --cidfile="${MAIN_EXECUTION_CIDFILE}"   \
                                    ${CONTAINER_IMAGE_NAME}                 \
                                    --perf-stat-out ${PERFSTATOUTFILE}      \
                                    ${workload}                             \
                                    -t ${d} ; then
                        echo "ERROR: failed to run container for ${PERFSTATOUTFILE}" >&2
                    elif ! rm -f ${MAIN_EXECUTION_CIDFILE} ; then
                        echo "ERROR: failed to delete ${MAIN_EXECUTION_CIDFILE}" >&2
                    fi
                    docker rm -f $( cat ${BACKGROUND_CIDFILE} ) || true
                    if ! rm -f ${BACKGROUND_CIDFILE} ; then
                        echo "ERROR: failed to delete ${BACKGROUND_CIDFILE}" >&2
                        exit 1
                    fi
                fi
            done
        done
    done
done

