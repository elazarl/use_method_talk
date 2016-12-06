#!/bin/bash

highlight() {
	grep --color '[^ ]*\s*insns per cycle\|$'
}
runecho() {
	echo $@
	"$@"
}

echo "Let's run a simple benchmark that touches the same memory spot"
runecho perf stat ./cachemiss -c 1 -t 10,000,000 | highlight
read
echo "See? 4 instructions per cycle! Now with 1,000 cache lines..."
runecho perf stat ./cachemiss -c 1,000 | highlight
read
echo "Half... L3 is not used so much, we're waiting for memory bus"
read
echo "But wait! We might be innocent! let's run 1,000 threads that thrash L3"
runecho ./cachemiss -c 1,000 -t -1
read
echo "Now, let's run the same benchmark again, while L3 thrashes"
read
runecho perf stat ./cachemiss -c 1 | highlight
echo "bad!, don't believe me? Let's kill 'em"
killall cachemiss
read
runecho perf stat ./cachemiss -c 1 | highlight
echo "after they die - we're back in business!"
