# Bisect: Finding the Commit That Broke It

**Scope:** not a rescue of lost work but of
lost certainty. Something is broken, it
worked some commits ago, and reading twelve
diffs sounds grim. Bisect turns your test
into a binary search and names the exact
commit — here, by hand first, then
automated, both against the same planted
culprit.

## The setup

The bisect repo has thirteen commits: the
journal, then twelve that each add a bed to
`beds.txt`. The garden's `tally.py` counts
the beds; somewhere in the twelve, it went
wrong:

```
$ python3 tally.py
13
$ grep -c . beds.txt
14
```

Thirteen beds counted, fourteen listed. The
verdict the hunt must reach is known to the
lab (it planted the bug) and recorded for
checking at the end: commit
`6cfcc267d3bb63295fa73430b96381b3e3023d68`,
"Add the kale bed and tidy the tally" — the
sixth of the twelve, which changed
`print(len(rows))` to `print(len(rows) - 1)`
as an innocent-looking "tidy".

The test is one line, kept just outside the
repo (an untracked script would also work)
so checkouts can't disturb it — shipped as
`examples/tally-check.sh`:

```sh
[ "$(python3 tally.py)" = "$(grep -c . beds.txt)" ]
```

Exit 0: the tally agrees (good). Exit 1: it
doesn't (bad). That contract is all bisect
needs.

## The hunt by hand

```
$ git bisect start
status: waiting for both good and bad commits
$ git bisect bad
status: waiting for good commit(s), bad commit known
$ git bisect good dab90a7c97a36c3b2c04e1ab01b7ab2265e8b90d
Bisecting: 5 revisions left to test after this (roughly 3 steps)
[6cfcc267d3bb63295fa73430b96381b3e3023d68] Add the kale bed and tidy the tally
```

`bad` with no argument means HEAD — broken
now. `good` is the journal commit, known
working. Git checks out the midpoint of
the suspect range and waits for a verdict.
Run the test, report:

```
$ ../tally-check.sh
[exit 1]
$ git bisect bad
Bisecting: 2 revisions left to test after this (roughly 2 steps)
[da916177ce611190949f7ed0caca975b2650acbe] Add the herbs bed
$ ../tally-check.sh
[exit 0]
$ git bisect good
Bisecting: 0 revisions left to test after this (roughly 1 step)
[9f98ac1988fead42a944678845d4ae5313a411a6] Add the leeks bed
$ ../tally-check.sh
[exit 0]
$ git bisect good
6cfcc267d3bb63295fa73430b96381b3e3023d68 is the first bad commit
```

Three test runs for a twelve-commit range
— that's the binary search earning its
keep: each verdict halves the suspects.
Git prints the culprit's full identity and
diffstat:

```
commit 6cfcc267d3bb63295fa73430b96381b3e3023d68
Author: Sam Gardener <sam@example.org>
Date:   Mon Mar 9 09:00:00 2026 +0000

    Add the kale bed and tidy the tally

 beds.txt | 1 +
 tally.py | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
```

And the lab's receipt:

```
bisect verdict : 6cfcc267d3bb63295fa73430b96381b3e3023d68
planted bad    : 6cfcc267d3bb63295fa73430b96381b3e3023d68
MATCH: bisect named exactly the planted commit
```

Finish with `git bisect reset`, which
returns HEAD to where you started (the lab
is left clean, on main, at the branch tip).

Read the culprit's actual diff before
concluding: `git show <sha> --stat` (above)
says *where*; the "tidy" in the message and
the one-line `tally.py` change say *what*.
Bisect finds the commit; it doesn't absolve
you from reading it.

## The same hunt, automated

If the test is a script, git will drive:

```
$ git bisect start
$ git bisect bad
$ git bisect good dab90a7c97a36c3b2c04e1ab01b7ab2265e8b90d
$ git bisect run ../tally-check.sh
running '../tally-check.sh'
Bisecting: 2 revisions left to test after this (roughly 2 steps)
[da916177ce611190949f7ed0caca975b2650acbe] Add the herbs bed
running '../tally-check.sh'
Bisecting: 0 revisions left to test after this (roughly 1 step)
[9f98ac1988fead42a944678845d4ae5313a411a6] Add the leeks bed
running '../tally-check.sh'
6cfcc267d3bb63295fa73430b96381b3e3023d68 is the first bad commit
bisect found first bad commit
```

Same midpoint order, same verdict —
`6cfcc267…`, matching the planted commit
again. The script's exit code is the whole
interface: **0 good, 1 bad, 125 skip** (for
"this commit can't be tested" — an
unbuildable tree, say — which bisect then
routes around). Any other exit code aborts
the run, which is the trap to design
against: a test script that exits 2 on a
missing tool will stop the hunt, not mark
the commit bad.

## Judgement calls bisect won't make

- **The good end has to be truly good.**
  Bisect trusts your endpoints absolutely;
  a `good` that's actually bad in a
  different way points the search at the
  wrong half with total confidence. Run
  your test once at each end before
  starting.
- **First bad ≠ root cause, necessarily.**
  It is the first commit where *your test*
  fails. If the bug arrived earlier but was
  masked, bisect names the unmasking. The
  diff at the verdict is the check.
- A flaky test produces a confident, wrong
  answer. If a verdict surprises you, check
  out the culprit and its parent and run
  the test on both by hand — the lab's
  parent (`9f98ac1…`, the leeks bed) passes,
  the culprit fails, which is what a sound
  verdict looks like.
