#!/bin/bash

source ../demo.sh

F="$1"

if [ -z "$F" ]; then
	echo Need a file argument
	exit 1
fi

boldecho "Let's run sort on a big file $F, and record perf trace"
runecho sudo bash -c "time perf record -e cycles:u --call-graph=dwarf -F 99 sort <$F >/dev/null"
boldecho "Let's see raw stacktraces"
read
sudo perf script | head
read
boldecho "Now, let's compact them"
read
echo sudo perf script | ~/FlameGraph/stackcollapse-perf.pl > sorted_utf8.folded
sudo perf script | ~/FlameGraph/stackcollapse-perf.pl > sorted_utf8.folded
head sorted_utf8.folded
read
boldecho "Finally, let's build a flamegraph"
sudo perf script | ~/FlameGraph/stackcollapse-perf.pl | ~/FlameGraph/flamegraph.pl > /tmp/recursive.svg
runecho google-chrome /tmp/recursive.svg
read
boldecho "Whoa! Recursion? Let's look at the code"
read
google-chrome 'https://github.com/coreutils/coreutils/blob/master/src/sort.c#L3183'
read
boldecho 'Not interesting, remove recursive calls'
cat remove_identical_lines.py
runecho bash -c 'sudo perf script | ~/FlameGraph/stackcollapse-perf.pl | ./remove_identical_lines.py sequential_sort > sorted_utf8.folded'
runecho bash -c '~/FlameGraph/flamegraph.pl <sorted_utf8.folded > /tmp/utf8.svg'
runecho google-chrome /tmp/utf8.svg
read
boldecho "Run again with LC_ALL=C"
runecho sudo bash -c "LC_ALL=C time perf record -e cycles:u --call-graph=dwarf -F 99 sort <$F >/dev/null"
runecho bash -c 'sudo perf script | ~/FlameGraph/stackcollapse-perf.pl | ./remove_identical_lines.py sequential_sort > sorted_ascii.folded'
runecho bash -c '~/FlameGraph/flamegraph.pl < sorted_ascii.folded > /tmp/ascii.svg'
runecho google-chrome /tmp/ascii.svg
read
boldecho "Let's see a diff"
runecho bash -c '~/FlameGraph/difffolded.pl -n sorted_ascii.folded sorted_utf8.folded | ~/FlameGraph/flamegraph.pl > /tmp/diff.svg'
runecho google-chrome /tmp/diff.svg
boldecho "But what does strcoll do?"
read
runecho google-chrome "http://www.cplusplus.com/reference/cstring/strcoll/"

