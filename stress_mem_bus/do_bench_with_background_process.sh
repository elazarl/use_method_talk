#!/bin/bash

source ../demo.sh

[ -x cachemiss ] || make

highlight() {
	grep --color '^.*LLC.*miss.*$\|[^ ]*\s*insns per cycle\|$'
}
runbackground() {
	boldecho taskset 0xfffe ./cachemiss -t -1 -T $THREADS "$@"
	taskset 0xfffe ./cachemiss -t -1 -T $THREADS "$@"
}
TIMES=1,000,000,000
THREADS=16
PERF="perf stat -e context-switches,cycles:k,instructions:k,cycles:u,instructions:u,cache-misses:u,LLC-loads:u,LLC-load-misses:u,LLC-store-misses:u,LLC-stores:u,LLC-loads:k,LLC-load-misses:k,LLC-store-misses:k,LLC-stores:k,L1-dcache-load-misses:u,L1-dcache-loads:u,branch-misses,branch-load-misses,branches,branch-loads"
if [ -n "$PERFCMD" ]; then
	PERF="$PERFCMD"
fi
trap 'killall ./cachemiss' EXIT

boldecho "But wait! We might be innocent! Let's run again the base benchmark with -c 1"
runbackground -c 1 &
sleep 1
runecho $PERF ./cachemiss -c 10 -t $TIMES |& highlight
[ -n "$PERFCMD" ] && sudo perf report
boldecho NOTE: last LLC stats are for kernel
killall ./cachemiss
read
boldecho "Now, let's run in a different CPU a process that thrashes the cache"
runbackground -c 1,000 -A &
sleep 1
boldecho "and run the exact same benchmark "
runecho taskset 0x1 $PERF ./cachemiss -c 10 -t $TIMES |& highlight
[ -n "$PERFCMD" ] && sudo perf report

sed -n '0,/^$/p' /proc/cpuinfo
sudo dmidecode -t processor
