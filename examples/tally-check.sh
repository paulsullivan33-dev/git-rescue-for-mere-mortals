#!/bin/sh
# Passes when tally.py agrees with the number of beds in beds.txt.
# Used by the bisect chapter, by hand and under `git bisect run`.
# Exit 0 = good commit, exit 1 = bad commit. (125 would mean "skip".)
[ "$(python3 tally.py)" = "$(grep -c . beds.txt)" ]
