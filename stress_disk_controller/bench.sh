#!/bin/bash

source ../demo.sh

highlight() {
	grep --color 'maxb=[^,]*\|$'
}
T=16

boldecho "Let's run a simple fio read of 128K"
runecho sudo fio --name=test --group_reporting --iodepth=32  --runtime=15  --filename=/dev/sdb  --rw=randread --bs=128k --ioengine=libaio --direct=1 --numjobs=$T --thread | highlight
boldecho "Now, let's run the same benchmark with 128k"
runecho sudo fio --name=test --group_reporting --iodepth=32  --runtime=15  --filename=/dev/sdb  --rw=randread --bs=4k --ioengine=libaio --direct=1 --numjobs=$T --thread | highlight
boldecho "We get less maximal bandwidth with smaller packets. The disk bandwidth is not utilized, but the controller is"
