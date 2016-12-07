#!/bin/bash

source ../demo.sh

highlight() {
	grep --color 'avgqu-sz\|%util\|$'
}


boldecho "disk-on-key resting"
runecho iostat -x 1 5 sda sdb | highlight
boldecho "Let's run a standard disk benchmark"
read
runecho sudo nohup fio --name=test --group_reporting --iodepth=32  --runtime=30  --filename=/dev/sdb  --rw=randread --bs=4k --ioengine=libaio --direct=1 --numjobs=1 --thread &
boldecho "While it's running, let's see CPU and disk"
runecho iostat -x 1 5 sda sdb | highlight
boldecho "Look that the disk has high utilization and saturation"
sudo killall fio
