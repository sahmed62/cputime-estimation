#! /bin/bash -e

if ! docker info >& /dev/null ; then
    echo "ERROR: unable to execute docker command. Ensure docker is installed"
else
    echo "Can run docker command. Good!"
fi

echo "Current kernel, \"$(uname -r)\":"
if [ -r /proc/config.gz ] ; then
    if zgrep "CONFIG_CPU_ISOLATION=y" /proc/config.gz >& /dev/null ; then
        echo "    supports CPU isolation. Good!"
    else
        echo "    WARNING: does not have CPU-isolation support"
    fi
    if zgrep "CONFIG_PREEMPT=y" /proc/config.gz >& /dev/null ; then
        echo "    supports CONFIG_PREEMPT. Good!"
    else
        echo "    WARNING: does not support CONFIG_PREEMPT."
        echo "             On Ubuntu, install linux-image-lowlatency"
    fi
elif [ -r "/boot/config-$(uname -r)" ] ; then
    if grep "CONFIG_CPU_ISOLATION" "/boot/config-$(uname -r)" >& /dev/null ; then
        echo "    supports CPU isolation. Good!"
    else
        echo "    WARNING: does not have CPU-isolation support"
    fi
    if grep "CONFIG_PREEMPT=y" "/boot/config-$(uname -r)" >& /dev/null ; then
        echo "    supports CONFIG_PREEMPT. Good!"
    else
        echo "    WARNING: does not support CONFIG_PREEMPT."
        echo "             On Ubuntu, install linux-image-lowlatency"
    fi
else
    echo "    WARNING: failed to obtain kernel build configs"
fi

if [ ! -r "/proc/cmdline" ] ; then
    echo "WARNING: no way to determine kernel boot arguments"
elif ! grep ' isolcpus=' "/proc/cmdline"  >& /dev/null ; then
    echo "WARNING: kernel booted without \"isolcpus=\" command-line argument"
    echo "          Add \"isolcpus=\" boot arg to GRUB_CMDLINE_LINUX_DEFAULT in \"/etc/default/grub\" and run update-grub"
else
    echo "Kernel booted with CPU isolation enabled. Good!"
    grep ' isolcpus=' "/proc/cmdline"
fi

