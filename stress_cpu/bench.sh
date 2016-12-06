#!/bin/bash
source ../demo.sh

boldecho Let\'s see what\'s the utilization of this laptop\'s CPU?
read
runecho mpstat 1 1
boldecho \<10%
read
boldecho "What's the saturation?"
read
runecho vmstat 1 5
read
boldecho the first column show the runqueue, processes waiting for CPU
boldecho "Let's look at this program"
runecho cat eatcpu.py
read
boldecho "Run it once"
runecho ./eatcpu.py&
read
runecho vmstat 1 5
read
boldecho Saturation of 1, run it again
read
runecho ./eatcpu.py&
read
runecho vmstat 1 5
read
boldecho Saturation of 2, now kill all
runecho killall eatcpu.py
read
runecho vmstat 1 5
