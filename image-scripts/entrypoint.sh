#! /bin/bash -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -r "${SCRIPT_DIR}/stress-ng-wrap.sh.include" ] ; then
    echo "ERROR: ${SCRIPT_DIR}/stress-ng-wrap.sh.include not found" >&2
    exit 1
else
    source ${SCRIPT_DIR}/stress-ng-wrap.sh.include
fi

#perf_4.19
perf     stat -x \; -d \
          ${SCRIPT_DIR}/indirection.sh \
          stress-ng-$@

