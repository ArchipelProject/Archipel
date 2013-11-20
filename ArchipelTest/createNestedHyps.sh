#!/bin/bash
set -x

TEST_HYP_LIST="1 2"
SCRIPT_LOCATION=$(pwd)


# delete previously exising test hypervisors
for i in $TEST_HYP_LIST; do
    virsh destroy archipel-hyp-$i
    virsh undefine archipel-hyp-$i
done

# generate  and start nested test hypervisors
for i in $TEST_HYP_LIST; do
    cat testfiles/hypervisor_template.xml |\
	sed -e "s,<%name%>,archipel-hyp-$i,"|\
        sed -e "s,<%uuid%>,$(uuidgen),"|\
        sed -e "s,<%hostname%>,archipel-hyp-$i.archipel.priv,"|\
        sed -e "s,<%mac%>,52:54:00:00:01:3$i," > testfiles/archipel-hyp-$i.xml
    virsh define testfiles/archipel-hyp-$i.xml
    virsh start archipel-hyp-$i
done

# Wait for nested test hypervisors to become online.

# TODO : predictable ip addresses; see how libvirt nw xml dhcp works
# and create fixed mapping
# for now, we hard-code addresses
TEST_HYP_IP="192.168.137.29 192.168.137.30"

for ip in $TEST_HYP_IP; do
    while true; do
	ping -c 1 $ip
	if [ $? -eq 0 ]; then
	    break
	fi
    done
done
    
#hypervisors are now online
