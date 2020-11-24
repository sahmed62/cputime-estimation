#! /bin/bash -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ $# -lt 3 ] ; then
    echo "Usage: $0 <Output file> <CSV1> <CSV2> [<CSV3> ...]" >& 2
    exit 1
else
    OUTPUT_FILE="${1}"
    if ! rm -f ${OUTPUT_FILE} || ! touch ${OUTPUT_FILE} ; then
        echo "ERROR: failed to create new output file: \"${OUTPUT_FILE}\"" >& 2
        exit 1
    else
        shift
        for STATFILE in "$@" ; do
            if [ ! -r "${STATFILE}" ] ; then
                echo "ERROR: no readable file at path \"${STATFILE}\"" >& 2
                exit 1
            fi
        done
    fi
fi

FIRST_STATFILE="${1}"
if [ ! -r ${FIRST_STATFILE} ] ; then
    echo "ERROR: failed to find readable file \"${FIRST_STATFILE}\"" >& 2
    exit 1
else
    REFERENCE_HEADER="$(head -n 1 ${FIRST_STATFILE})"
    echo ${REFERENCE_HEADER} >> ${OUTPUT_FILE}
fi

for STATFILE in "$@" ; do
    STATFILEHEADER="$(head -n 1 ${STATFILE})"
    if [ "${STATFILEHEADER}" != "${REFERENCE_HEADER}" ] ; then
        echo "ERROR: mis-matched header for \"${STATFILE}\"" >& 2
        exit 1
    else
        tail -n +2 ${STATFILE} >> ${OUTPUT_FILE}
    fi
done

