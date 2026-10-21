# What Git Rescue Is

**Scope:** the mental model every rescue in
this guide stands on — objects, labels, and
the reflog — plus the stop-and-check routine
to run before rescuing anything.

## A commit is an object; a branch is a label

Git stores your history as **objects**:
blobs (file contents), trees (directory
listings), and commits (a tree, a parent or
two, a message, a date). Each object is
named by the SHA-1 hash of its contents.
Here is a real commit from the lab, taken
apart:

```
$ git cat-file -p HEAD
tree b3999a0ed39c13ed9973599c7b03b99b04bbd599
parent 9f64b06c01fb78f77bc6c408f55a74a5ea0398df
author Sam Gardener <sam@example.org> 1772442000 +0000
committer Sam Gardener <sam@example.org> 1772442000 +0000

Note the soil at the north end
```

A branch, by contrast, is almost nothing: a
small file holding one commit's SHA — a
label stuck on an object. Watch how little
HEAD itself is:

```
$ cat .git/HEAD
ref: refs/heads/main
```

That is the whole mechanism behind most of
this guide. **Deleting a branch deletes the
label, not the objects.** Rewinding a branch
moves the label. The objects stay in the
repository until garbage collection
eventually prunes the unreachable ones —
and "eventually" is normally weeks (see
chapter 10 for the defaults and the edge).
A rescue is usually just: find the SHA of
the object you thought you lost, and stick
a label back on it.

## The reflog: git's private diary

Where do you find that SHA? In the
**reflog**: a per-repository log of every
position HEAD has held — commits, checkouts,
resets, merges, rebases — newest first:

```
$ git reflog
79f28bb HEAD@{0}: checkout: moving from bean-notes to main
dad64d8 HEAD@{1}: commit: Record the bean germination check
ae895e7 HEAD@{2}: commit: Add the bean growing notes
```

(That capture is from chapter 2's disaster,
minutes after the branch was deleted; the
"lost" tip is sitting in plain sight at
`HEAD@{1}`.) The reflog is local — it is
never cloned or pushed — and it expires,
which is why chapter 10 exists. While it
lasts, it is the single most useful rescue
tool git has. A second diary-keeper is
**ORIG_HEAD**: a single remembered position
that reset, merge, and rebase overwrite
just before they move HEAD — the "where I
just was" bookmark chapters 3 and 6 lean on.

## The lab, and how rescues are proven

The lab project is the Riverbend Community
Garden journal — `planting-notes.md`,
`beds.txt`, and `tally.py`, a five-line
script that counts the beds. It is built
fresh per chapter by `examples/plant-disasters.sh`
with a fixed author (Sam Gardener) and
fixed commit dates, on git 2.43.0:

```
$ git --version
git version 2.43.0
```

Before each disaster, the harness saves a
copy of the file that is about to be "lost"
outside the repo. After each rescue, the
recovered file is compared against that
copy with `cmp`, and the chapters print the
verdict line. A rescue counts when the
bytes match — not when a command exits 0.

## Stop, and check, first

Rescue commands are themselves history
operations; a panicked `reset --hard` can
bury the thing you were trying to save one
reflog layer deeper. Before touching
anything in a real incident:

1. **`git status`** — what state is the
   repo in? Mid-merge, mid-rebase, clean?
   Several rescues (chapter 6) only exist
   in one of those states.
2. **`git log --oneline -5`** and
   **`git reflog`** — where is HEAD, and
   where has it been? Read before you move.
3. **Copy the whole repo** —
   `cp -r myrepo myrepo-backup`. The `.git`
   directory travels with the copy, reflogs
   and all. It is crude, and it caps how bad
   a failed rescue can get. The lab does
   exactly this with its first repo:

```
$ cp -r /home/hatch/workspace/git-rescue-lab/work/garden /home/hatch/workspace/git-rescue-lab/work/garden-backup
$ ls /home/hatch/workspace/git-rescue-lab/work/garden-backup
beds.txt
planting-notes.md
tally.py
```

4. **Work the problem in the open.** Don't
   stack experiments; do one rescue step,
   check the content, then the next.

With that, the disasters — roughly in
order of how often they happen.
