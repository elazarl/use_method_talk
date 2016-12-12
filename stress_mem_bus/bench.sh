#!/bin/bash

TIMES=100,000,000
source ../demo.sh

highlight() {
	grep --color '^.*LLC.*$\|[^ ]*\s*insns per cycle\|$'
}
PERF="perf stat -e context-switches,cycles:u,instructions:u,LLC-load-misses,LLC-store-misses"
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
boldecho "But wait! We might be innocent! let's run 1,000 threads that thrash L3"
taskset 0xfffe ./cachemiss -c 1,000 -t -1 -T 7 &
read
