#!/usr/bin/python

import sys

key = sys.argv[1]
prev_key = False
for line in sys.stdin.readlines():
    if key in line:
        if prev_key:
            continue
        prev_key = True
    else:
        prev_key = False
    sys.stdout.write(line)
