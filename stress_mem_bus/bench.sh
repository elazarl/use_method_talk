#!/bin/bash

source ../demo.sh

boldecho "Let's run a simple benchmark that touches the same memory spot"
runecho perf stat ./cachemiss -c 1 -t 10,000,000 | highlight
read
boldecho "See? 4 instructions per cycle! Now with 1,000 cache lines..."
runecho perf stat ./cachemiss -c 1,000 | highlight
read
boldecho "Half... L3 is not used so much, we're waiting for memory bus"
read
boldecho "But wait! We might be innocent! let's run 1,000 threads that thrash L3"
runecho ./cachemiss -c 1,000 -t -1
read
boldecho "Now, let's run the same benchmark again, while L3 thrashes"
read
runecho perf stat ./cachemiss -c 1 | highlight
boldecho "bad!, don't believe me? Let's kill 'em"
killall cachemiss
read
runecho perf stat ./cachemiss -c 1 | highlight
boldecho "after they die - we're back in business!"
