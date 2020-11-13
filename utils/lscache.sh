#! /bin/bash -e

#
#for each cpu
#    for each index
#        determine level
#        determine type
#        determine id
#        determine shared_cpu_list
#        determine line size
#        determine ways
#        determine sets
#        determine size
#

function check_read_file {
    if [ -z ${1} ] || [ ! -r ${1} ] ; then
        echo "unknown"
    else
        cat ${1}
    fi
}

ROOTDIR="/sys/devices/system/cpu"
echo "System {"
for cpu in $(find "${ROOTDIR}" \
                    -mindepth 1 \
                    -maxdepth 1 \
                    -name "cpu*" \
                    -not -name "cpufreq" -not -name "cpuidle" \
                    | sort ) ; do
    CPUCACHEDIR="${cpu}/cache"
    echo "    $(basename ${cpu}) {"
    for index in $(find "${CPUCACHEDIR}" \
                        -mindepth 1 \
                        -maxdepth 1 \
                        -name "index*" \
                        | sort ) ; do
        CPUCACHEINDEXDIR="${index}"
        echo "        $(basename ${index}) {"
        echo "            level:            $( check_read_file ${CPUCACHEINDEXDIR}/level)"
        echo "            type:             $( check_read_file ${CPUCACHEINDEXDIR}/type)"
        echo "            id:               $( check_read_file ${CPUCACHEINDEXDIR}/id)"
        echo "            shared w/ CPUs:   $( check_read_file ${CPUCACHEINDEXDIR}/shared_cpu_list)"
        echo "            line size:        $( check_read_file ${CPUCACHEINDEXDIR}/coherency_line_size)"
        echo "            associativity:    $( check_read_file ${CPUCACHEINDEXDIR}/ways_of_associativity)"
        echo "            sets:             $( check_read_file ${CPUCACHEINDEXDIR}/number_of_sets)"
        echo "            total size:       $( check_read_file ${CPUCACHEINDEXDIR}/size)"
        echo "        }"
    done
    echo "    }"
    echo "}"
done

