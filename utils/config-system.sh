#! /bin/bash -e

# Check we're running as root, or the rest won't work
CURRENT_USER="$(id -u)"
if [ "${CURRENT_USER}" != "0" ] ; then
    echo "$0 must be run as root" >&2
    exit 1
fi

# Remove any limits on CPU budget for RT tasks
if [ -f /proc/sys/kernel/sched_rt_runtime_us ] ; then
    echo "-1" > /proc/sys/kernel/sched_rt_runtime_us
fi

if [ -f /sys/fs/cgroup/cpu/cpu.rt_runtime_us ] ; then
    echo "-1" > /proc/sys/kernel/sched_rt_runtime_us
fi

if [ -f /sys/fs/cgroup/cpu/docker/cpu.rt_runtime_us ] ; then
    echo "-1" > /sys/fs/cgroup/cpu/docker/cpu.rt_runtime_us
fi

# loop over each CPU with cpufreq subsystem
ROOTDIR="/sys/devices/system/cpu"
for cpu in $(find "${ROOTDIR}" \
                    -mindepth 1 \
                    -maxdepth 1 \
                    -name "cpu*" \
                    -not -name "cpufreq" -not -name "cpuidle" \
                    | sort ) ; do

    # check if the cpufreq subsystem is available
    CPUFREQDIR="${cpu}/cpufreq/"
    if [ -d "${CPUFREQDIR}" ] ; then

        AVAILABLE_GOVERNORS_FILE="${CPUFREQDIR}/scaling_available_governors"
        CURRENT_GOVERNOR_FILE="${CPUFREQDIR}/scaling_governor"
        AVAILABLE_FREQUENCIES_FILE="${CPUFREQDIR}/scaling_available_frequencies"
        SET_FREQUENCY_FILE="${CPUFREQDIR}/scaling_setspeed"

        # check if governor is configurable and "userspace" governor available
        if [ -r "${AVAILABLE_GOVERNORS_FILE}" ] \
            && [ -w ${CURRENT_GOVERNOR_FILE} ] \
            && grep "userspace" ${AVAILABLE_GOVERNORS_FILE} > /dev/null; then

            # set "userspace" as the current governor
            if ! echo "userspace" > ${CURRENT_GOVERNOR_FILE} ; then
                echo "failed to set $(basename ${cpu} ) governor to \"userspace\"" >&2
                exit 1
            
            # check if CPU frequency is configurable
            elif [ -r "${AVAILABLE_FREQUENCIES_FILE}" ] \
                && [ -w ${SET_FREQUENCY_FILE} ] ; then
                # set curspeed to the minimum available speed
                # Add -r argument to 'sort' command below to make it max frequency.
                if ! for freq in $(cat ${AVAILABLE_FREQUENCIES_FILE} ) ; do
                        echo $freq ; done | sort | head -n 1 \
                        > ${SET_FREQUENCY_FILE} ; then
                    echo "failed to set $(basename ${cpu} ) frequency to minimum" >&2
                    exit 1
                fi
            fi
        fi
    fi
done

echo "System successfully configured!"
