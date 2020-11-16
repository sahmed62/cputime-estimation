#! /bin/bash -xe

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -r "${SCRIPT_DIR}/stress-ng-wrap-list.sh.include" ] ; then
    echo "ERROR: failed to find \"stress-ng-wrap-list.sh.include\"" >&2
    exit 1
else
    source "${SCRIPT_DIR}/stress-ng-wrap-list.sh.include"
    if [ -z ${STRESSNG_FUNC_ARRAY} ] ; then
        echo "ERROR: failed to find non-empty \"STRESSNG_FUNC_ARRAY\"" >&2
        exit 1
    fi
fi

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

REPETITION=6
DURATION_MIN=5
DURATION_MAX=14

# For each repetitionn
for r in $( seq 1 1 ${REPETITION} ) ; do
    # For each duration
    for d in $( seq ${DURATION_MIN} 1 ${DURATION_MAX} ) ; do
        # Run docker image for one workload
        for workload in ${STRESSNG_FUNC_ARRAY[@]} ; do
            PERFSTATOUTFILE="${INCONTAINERLOGDIR}/${workload}-${d}sec-${r}.csv"
            if ! docker run --rm                                    \
                            -it                                     \
                            --privileged                            \
                            --cpuset-cpus ${MAIN_EXECUTION_CORE}    \
                            -v ${SCRIPT_DIR}:/home/perf-stress-ng   \
                            --cidfile="${MAIN_EXECUTION_CIDFILE}"   \
                            ${CONTAINER_IMAGE_NAME}                 \
                            --perf-stat-out ${PERFSTATOUTFILE}      \
                            ${workload}                             \
                            -t ${d} -q ; then
                echo "ERROR: failed to run container for ${PERFSTATOUTFILE}" >&2
                exit 1
            elif ! rm -f ${MAIN_EXECUTION_CIDFILE} ; then
                echo "ERROR: failed to delete ${MAIN_EXECUTION_CIDFILE}" >&2
                exit 1
            fi
        done
    done
done

