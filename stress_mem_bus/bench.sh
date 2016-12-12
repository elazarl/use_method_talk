#!/bin/bash

TIMES=1,00,000,000
source ../demo.sh

highlight() {
	grep --color '^.*LLC.*$\|[^ ]*\s*insns per cycle\|$'
}
PERF="perf stat -e context-switches,cycles:u,instructions:u,LLC-loads:u,LLC-load-misses:u,LLC-store-misses:u,L1-dcache-load-misses:u,L1-dcache-loads:u"
trap 'killall ./cachemiss' EXIT

boldecho "Let's run a simple benchmark that touches the same memory spot"
read
git grep -W 'cacheline\[IX.*\]'
runecho $PERF ./cachemiss -c 1 -t $TIMES |& highlight
read
boldecho "See? 4 instructions per cycle! Now with 1,000 cache lines..."
runecho $PERF ./cachemiss -c 1,000 -t $TIMES |& highlight
read
boldecho "Less... L3 is not used so much, we're waiting for memory bus"
