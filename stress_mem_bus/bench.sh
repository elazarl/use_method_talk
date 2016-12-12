#!/bin/bash

TIMES=100,000,000
source ../demo.sh

highlight() {
	grep --color '^.*LLC.*$\|[^ ]*\s*insns per cycle\|$'
}
PERF="perf stat -e context-switches,cycles:u,instructions:u,LLC-load-misses,LLC-store-misses,L1-dcache-load-misses:u,L1-dcache-loads:u"
trap 'killall ./cachemiss' EXIT

boldecho "Let's run a simple benchmark that touches the same memory spot"
read
git grep -W 'cacheline\[IX.*\]'
runecho $PERF ./cachemiss -c 1 -t $TIMES |& highlight
read
boldecho "See? 4 instructions per cycle! Now with 1,000 cache lines..."
runecho $PERF ./cachemiss -c 1,000 -t $TIMES |& highlight
read
boldecho "Half... L3 is not used so much, we're waiting for memory bus"
read
boldecho "But wait! We might be innocent! Let's run again the base benchmark with -c 1"
runecho $PERF ./cachemiss -c 10 -t $TIMES |& highlight
read
boldecho "Now, let's run in a different CPU a process that thrashes the cache"
echo taskset 0xfffe ./cachemiss -c 1,000 -t -1 &
taskset 0xfffe ./cachemiss -c 10,000 -t -1 -T 16 &
sleep 1
boldecho "and run the exact same benchmark "
runecho taskset 0x1 $PERF ./cachemiss -c 10 -t $TIMES |& highlight
read
