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
    if zgrep "CONFIG_RCU_NOCB_CPU=y" /proc/config.gz >& /dev/null ; then
        echo "    supports rcu_nocb. Good!"
    else
        echo "    WARNING: does not have rcu_nocb support"
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
    if grep "CONFIG_RCU_NOCB_CPU=y" "/boot/config-$(uname -r)" >& /dev/null ; then
        echo "    supports rcu_nocb. Good!"
    else
        echo "    WARNING: does not have rcu_nocb support"
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
elif ! grep ' rcu_nocb=' "/proc/cmdline"  >& /dev/null ; then
    echo "WARNING: kernel booted without \"rcu_nocb=\" command-line argument"
    echo "          Add \"rcu_nocb=\" boot arg to GRUB_CMDLINE_LINUX_DEFAULT in \"/etc/default/grub\" and run update-grub"
elif ! grep ' rcu_nocb_poll' "/proc/cmdline"  >& /dev/null ; then
    echo "WARNING: kernel booted without \"rcu_nocb_poll\" command-line argument"
    echo "          Add \"rcu_nocb_poll\" boot arg to GRUB_CMDLINE_LINUX_DEFAULT in \"/etc/default/grub\" and run update-grub"
elif ! grep ' processor.max_cstate=0' "/proc/cmdline" >& /dev/null ; then
    echo "WARNING: kernel booted without \"processor.max_cstate\" command-line argument"
    echo "          Add \"processor.max_cstate=0\" boot arg to GRUB_CMDLINE_LINUX_DEFAULT in \"/etc/default/grub\" and run update-grub"
else
    echo "Kernel booted with CPU isolation, rcu_nocb, processor.max_cstate, and rcu_nocb_poll enabled. Good!"
    grep ' isolcpus=' "/proc/cmdline"
fi

if [ -f /sys/module/rcutree/parameters/kthread_prio ] \
    && [ $(cat /sys/module/rcutree/parameters/kthread_prio) -lt 10 ]; then
    echo "WARNING: RCU kthread scheduling priority less than 10. This may cause the system to hang."
    echo "          Add \"rcutree.kthread_prio=10\" boot arg to GRUB_CMDLINE_LINUX_DEFAULT in \"/etc/default/grub\" and run update-grub"
else
    echo "RCU kthread scheduling priority not less than 10. Good!"
fi
