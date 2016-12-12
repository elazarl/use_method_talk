#!/bin/bash

source ../demo.sh

boldecho "Let's sample every L1 cache miss"
sudo perf record --call-graph=dwarf -e L1-dcache-load-misses:u ./false_sharing
runecho sudo perf script
boldecho "there are too much, let's sample, record every 100,000 events"
echo sudo perf record --call-graph=dwarf -e L1-dcache-load-misses:u -c 100000 ./false_sharing | grep --color -- '-c 1.* '
sudo perf record --call-graph=dwarf -e L1-dcache-load-misses:u -c 100000 ./false_sharing
read
sudo perf report
#sudo perf script | ~/FlameGraph/stackcollapse-perf.pl | ~/FlameGraph/flamegraph.pl > /tmp/false_sharing.svg
#runecho google-chrome /tmp/false_sharing.svg
read
for i in false_sharing no_false_sharing; do
	perf stat -e \
		cache-misses,\
instructions:u,\
cycles:u,\
LLC-load-misses,\
LLC-store-misses,\
L1-dcache-load-misses,\
L1-dcache-loads,\
L1-dcache-stores,\
cs \
	./$i
done
