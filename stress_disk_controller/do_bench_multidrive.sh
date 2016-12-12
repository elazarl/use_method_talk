#!/bin/bash

source ../demo.sh

highlight() {
	grep --color 'maxb=[^,]*\|$'
}
T=32

boldecho "Let's run a simple fio read test"
runecho sudo fio --name=test --group_reporting --iodepth=32  --runtime=15  --filename=/dev/sdb  --rw=randread --bs=4k --ioengine=libaio --direct=1 --numjobs=$T --thread | highlight
boldecho "Now, let's run another benchmark on a different drive while running the same fio benchmark"
runecho sudo nohup fio --name=test --group_reporting --iodepth=32  --runtime=30  --filename=/dev/sdc  --rw=randread --bs=4k --ioengine=libaio --direct=1 --numjobs=128 --thread &
runecho sudo fio --name=test --group_reporting --iodepth=32  --runtime=15  --filename=/dev/sdb  --rw=randread --bs=4k --ioengine=libaio --direct=1 --numjobs=$T --thread | highlight
boldecho "See, bad results"
