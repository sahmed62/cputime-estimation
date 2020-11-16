#! /bin/bash -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -r "${SCRIPT_DIR}/stress-ng-wrap.sh.include" ] ; then
    echo "ERROR: ${SCRIPT_DIR}/stress-ng-wrap.sh.include not found" >&2
    exit 1
else
    source ${SCRIPT_DIR}/stress-ng-wrap.sh.include
fi

if [ -r "perf-events-config.sh.include" ] ; then
    source perf-events-config.sh.include
fi

if [ ! -z "${PERF_STAT_EVENT_LIST}" ] ; then
    PERF_STAT_EVENT_ARG="-e ${PERF_STAT_EVENT_LIST}"
else
    PERF_STAT_EVENT_ARG="-d"
fi

if [ $# -gt 2 ] && [ ${1} = "--perf-stat-out" ] ; then
    PERF_STAT_OUT="${2}"
    shift 2
else
    PERF_STAT_OUT=""
fi

# Check if this is the main run or a background run
if [ ! -z ${PERF_STAT_OUT} ] ; then
    perf stat   -x \;                           \
                -o ${PERF_STAT_OUT}.raw         \
                -a --per-core                   \
                ${PERF_STAT_EVENT_ARG}          \
                  ${SCRIPT_DIR}/indirection.sh  \
                  stress-ng-$@
    if [ -f "${PERF_STAT_OUT}.raw" ] ; then
        if [ ! -z "${PERF_STAT_OUTPUT_PARSE_CORELIST}" ] \
            && [ ! -z "${PERF_STAT_OUTPUT_PARSE_EVENTLIST}" ] \
            && [ ! -z "${PERF_STAT_OUTPUT_PARSE_LABELLIST}" ] ; then
            if ! rm -f ${PERF_STAT_OUT} || ! touch ${PERF_STAT_OUT} ; then
                echo "ERROR: failed to process files for parsing" >&2
                exit 1
            else
                # Array indexing begins with 0: excuse the hack
                PERF_STAT_OUTPUT_LIST_LEN="${#PERF_STAT_OUTPUT_PARSE_CORELIST[@]}"
                PERF_STAT_OUTPUT_LIST_LEN="$(expr ${PERF_STAT_OUTPUT_LIST_LEN} - 1)"
                # write the labels
                for k in $(seq 0 1 ${PERF_STAT_OUTPUT_LIST_LEN} ) ; do
                    echo -n "${PERF_STAT_OUTPUT_PARSE_LABELLIST[$k]}, " \
                                >> ${PERF_STAT_OUT}
                done
                # line break
                echo >> ${PERF_STAT_OUT}
                # write the entries
                # search for
                for k in $(seq 0 1 ${PERF_STAT_OUTPUT_LIST_LEN} ) ; do
                    PERF_STAT_OUTPUT_CORE="${PERF_STAT_OUTPUT_PARSE_CORELIST[k]}"
                    PERF_STAT_OUTPUT_EVNT="${PERF_STAT_OUTPUT_PARSE_EVENTLIST[k]}"
                    if ! VALUE=$( \
                        grep "${PERF_STAT_OUTPUT_CORE};" "${PERF_STAT_OUT}.raw" \
                        | grep ";${PERF_STAT_OUTPUT_EVNT}" \
                        | cut -d ';' -f 3 ) ; then
                        echo "ERROR: failed to parse ${PERF_STAT_OUTPUT_CORE}.${PERF_STAT_OUTPUT_EVNT}" >&2
                        exit 1
                    else
                        echo -n "${VALUE}, " >> ${PERF_STAT_OUT}
                    fi
                done
                echo >> "${PERF_STAT_OUT}"
            fi
        elif ! mv "${PERF_STAT_OUT}.raw" "${PERF_STAT_OUT}" ; then
            echo "ERROR: failed to rename 'perf stat' output to ${PERF_STAT_OUT}" >&2
            exit 1
        fi
    fi
else
    # This is a background run, just run stress-ng
    # No need to run perf
    stress-ng-$@
fi

