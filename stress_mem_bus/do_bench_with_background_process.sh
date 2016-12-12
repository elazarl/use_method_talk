#!/bin/bash

source ../demo.sh

highlight() {
	grep --color '^.*LLC.*miss.*$\|[^ ]*\s*insns per cycle\|$'
}
runbackground() {
	boldecho taskset 0xfffe ./cachemiss -t -1 -T 1 "$@"
	taskset 0xfffe ./cachemiss -t -1 -T 1 "$@"
}
TIMES=100,000,000
PERF="perf stat -e context-switches,cycles:k,instructions:k,cycles:u,instructions:u,cache-misses:u,LLC-loads:u,LLC-load-misses:u,LLC-store-misses:u,LLC-stores:u,L1-dcache-load-misses:u,L1-dcache-loads:u"
PERF="perf stat -e context-switches,cycles:k,instructions:k,cycles:u,instructions:u,cache-misses:u,LLC-loads,LLC-load-misses,LLC-store-misses,LLC-stores,L1-dcache-load-misses,L1-dcache-loads"
if [ "$1" = "record" ]; then
	RECORD=1
	PERF=sudo\ perf\ record\ -F9999
fi
trap 'killall ./cachemiss' EXIT

boldecho "But wait! We might be innocent! Let's run again the base benchmark with -c 1"
runbackground -c 1 -T 8 &
sleep 1
runecho $PERF ./cachemiss -c 10 -t $TIMES |& highlight
[ -n "$RECORD" ] && sudo perf report
killall ./cachemiss
read
boldecho "Now, let's run in a different CPU a process that thrashes the cache"
runbackground -c 1,000 -A -T 8 &
sleep 1
boldecho "and run the exact same benchmark "
runecho taskset 0x1 $PERF ./cachemiss -c 10 -t $TIMES |& highlight
[ -n "$RECORD" ] && sudo perf report
