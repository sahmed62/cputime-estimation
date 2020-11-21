#! /bin/bash -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -r "${SCRIPT_DIR}/perf-events-config.sh.include" ] ; then
    source "${SCRIPT_DIR}/perf-events-config.sh.include"
fi

if [ ! -z "${PERF_STAT_EVENT_LIST}" ] ; then
    PERF_STAT_EVENT_ARG="-e ${PERF_STAT_EVENT_LIST}"
else
    PERF_STAT_EVENT_ARG="-d"
fi


# Setup perf output directory structure
STATDIR="${SCRIPT_DIR}/perf-stat-out/noise/"
INCONTAINERLOGDIR="/home/perf-stress-ng/perf-stat-out/noise/"

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

REPETITION=50
DURATION_MIN=5
DURATION_MAX=14

# For each repetitionn
for r in $( seq 1 1 ${REPETITION} ) ; do
    # For each duration
    for d in $( seq ${DURATION_MIN} 1 ${DURATION_MAX} ) ; do
        workload="system-noise"
        PERFSTATOUTFILE="${INCONTAINERLOGDIR}/${workload}-${d}sec-${r}.csv"
        if ! docker run --rm                                    \
                        -it                                     \
                        --privileged                            \
                        --cpuset-cpus ${MAIN_EXECUTION_CORE}    \
                        -v ${SCRIPT_DIR}:/home/perf-stress-ng   \
                        --cidfile="${MAIN_EXECUTION_CIDFILE}"   \
                        --entrypoint perf                       \
                        ${CONTAINER_IMAGE_NAME}                 \
                                stat                            \
                                -x \;                           \
                                -o ${PERFSTATOUTFILE}.raw       \
                                -a --per-core                   \
                                ${PERF_STAT_EVENT_ARG}          \
                                sleep ${d}  ; then
            echo "ERROR: failed to run container for ${PERFSTATOUTFILE}" >&2
            exit 1
        elif ! rm -f ${MAIN_EXECUTION_CIDFILE} ; then
            echo "ERROR: failed to delete ${MAIN_EXECUTION_CIDFILE}" >&2
            exit 1
        else
            if [ ! -z "${PERF_STAT_OUTPUT_PARSE_CORELIST}" ] \
                && [ ! -z "${PERF_STAT_OUTPUT_PARSE_EVENTLIST}" ] \
                && [ ! -z "${PERF_STAT_OUTPUT_PARSE_LABELLIST}" ] ; then
                echo "${workload}-${d}sec-${r} competed"
                PERFSTATOUTFILE="${STATDIR}/${workload}-${d}sec-${r}.csv"
                if ! rm -f ${PERFSTATOUTFILE} || ! touch ${PERFSTATOUTFILE} ; then
                    echo "ERROR: failed to process files for parsing" >&2
                    exit 1
                else
                    # Array indexing begins with 0: excuse the hack
                    PERF_STAT_OUTPUT_LIST_LEN="${#PERF_STAT_OUTPUT_PARSE_CORELIST[@]}"
                    PERF_STAT_OUTPUT_LIST_LEN="$(expr ${PERF_STAT_OUTPUT_LIST_LEN} - 1)"
                    # write the labels
                    for k in $(seq 0 1 ${PERF_STAT_OUTPUT_LIST_LEN} ) ; do
                        echo -n "${PERF_STAT_OUTPUT_PARSE_LABELLIST[$k]}, " \
                                    >> ${PERFSTATOUTFILE}
                    done
                    # line break
                    echo >> ${PERFSTATOUTFILE}
                    # write the entries
                    # search for
                    for k in $(seq 0 1 ${PERF_STAT_OUTPUT_LIST_LEN} ) ; do
                        PERF_STAT_OUTPUT_CORE="${PERF_STAT_OUTPUT_PARSE_CORELIST[k]}"
                        PERF_STAT_OUTPUT_EVNT="${PERF_STAT_OUTPUT_PARSE_EVENTLIST[k]}"
                        if ! VALUE=$( \
                            grep "${PERF_STAT_OUTPUT_CORE};" "${PERFSTATOUTFILE}.raw" \
                            | grep ";${PERF_STAT_OUTPUT_EVNT}" \
                            | cut -d ';' -f 3 ) ; then
                            echo "ERROR: failed to parse ${PERF_STAT_OUTPUT_CORE}.${PERF_STAT_OUTPUT_EVNT}" >&2
                            exit 1
                        else
                            echo -n "${VALUE}, " >> ${PERFSTATOUTFILE}
                        fi
                    done
                    echo >> "${PERFSTATOUTFILE}"
                fi
            elif ! mv "${PERFSTATOUTFILE}.raw" "${PERFSTATOUTFILE}" ; then
                echo "ERROR: failed to rename 'perf stat' output to ${PERFSTATOUTFILE}" >&2
                exit 1
            fi
        fi
    done
done

