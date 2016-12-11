#!/bin/zsh

source ../demo.sh

boldecho "Who uses the memory of sort?"

rm /tmp/heapprof.0*
runecho bash -c "HEAPPROFILE=/tmp/heapprof LD_PRELOAD=~/gperftools/.libs/libtcmalloc.so sort <~/linux/tags >/dev/null"
boldecho "OK, now we sampled every malloc, and it's weight is as the size requested"
read
boldecho "Let's see some stacks"
runecho bash -c '~/gperftools/src/pprof --collapsed `which sort` /tmp/heapprof.0002.heap | head'
read
runecho bash -c "~/gperftools/src/pprof --collapsed `which sort` /tmp/heapprof.0002.heap | ~/FlameGraph/flamegraph.pl > /tmp/unicode.svg"
runecho google-chrome /tmp/unicode.svg
read
boldecho "And without unicode support"
read
rm /tmp/heapprof.0*
runecho bash -c "LC_ALL=C HEAPPROFILE=/tmp/heapprof LD_PRELOAD=~/gperftools/.libs/libtcmalloc.so sort <~/linux/tags >/dev/null"
runecho bash -c '~/gperftools/src/pprof --collapsed `which sort` /tmp/heapprof.0002.heap| ~/FlameGraph/flamegraph.pl > /tmp/ascii.svg'
runecho google-chrome /tmp/ascii.svg
