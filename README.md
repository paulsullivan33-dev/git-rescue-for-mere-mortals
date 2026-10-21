# Git Rescue for Mere Mortals

The sibling guide *Git for Mere Mortals*
teaches the happy path: commit, branch,
merge, push. This guide is the companion
for the other days — the branch you deleted
with the only copy of the work on it, the
`reset --hard` you regret in the same
second, the commit that landed on the wrong
branch, the stash you dropped, the file
history swallowed three commits ago, the
bug that arrived in one of twelve commits
and you don't know which.

Almost all of those are recoverable, and
the reason is the same in every case: git
rarely throws anything away. Commits are
content-addressed objects; deleting a
branch deletes a *label*, not the objects;
and git keeps a private diary — the
**reflog** — of everywhere your HEAD has
been. Rescue is mostly learning to read
that diary and pin a label back onto what
it finds.

Almost all — not all. This guide also walks
to the edge on purpose: the two commands
that make a dangling commit genuinely
unrecoverable, run in a throwaway clone
only, and the one loss git can do nothing
about at all, work that was never staged or
committed.

The lab is one small, invented project — the
**Riverbend Community Garden** journal: a
planting-notes file, a beds list, and a tiny
Python tally script. A script in `examples/`
(`plant-disasters.sh`) builds a fresh
scratch repo per disaster, plants the
disaster, and recovers on the record, with
fixed author and commit dates so the
captures are stable. Every rescue is proven
by content: files recovered are compared
byte-for-byte (`cmp`, `sha256sum`) against
copies saved *before* the disaster. "Git
said ok" is never the evidence.

A note on how this guide was verified. Git
**2.43.0** was on the build machine, and
every command quoted was run in the lab and
captured — the rescues that worked, the exit
codes, and the two failures that mark the
boundary of rescue. `criteria.md` keeps the
full ledger, including what is
documented-only and why.

## What this guide covers

- [**What git rescue is**](what-git-rescue-is.md) —
  objects, labels, and the reflog; why
  "deleted" usually isn't; the stop-and-check
  routine before any rescue
- [**The reflog and deleted branches**](reflog-and-deleted-branches.md) —
  `git branch -D` undone: find the tip in the
  reflog, pin the branch back on, prove the
  files byte-identical
- [**Reset, three ways**](reset-three-ways.md) —
  `--soft`, `--mixed`, `--hard` run on
  identical histories so the difference is
  visible; a hard reset undone via
  `ORIG_HEAD`
- [**A commit on the wrong branch**](wrong-branch.md) —
  branch first, rewind second — the order is
  the whole lesson
- [**Merges and rebases gone wrong**](merge-and-rebase.md) —
  `--abort` while it can still save you, and
  a *completed* bad rebase undone through
  the reflog and `ORIG_HEAD`
- [**The stash graveyard**](the-stash-graveyard.md) —
  a dropped stash recovered from the dangling
  objects with `fsck`; `apply` vs `pop`,
  captured
- [**Restoring a file deleted commits ago**](restoring-a-deleted-file.md) —
  find the deletion, restore from the last
  commit where the file lived, two ways
- [**Bisect: finding the commit that broke it**](bisect.md) —
  twelve commits, one culprit; the hunt by
  hand and then under `git bisect run`, both
  ending at the same SHA
- [**Pushed mistakes**](pushed-mistakes.md) —
  revert versus rewrite on a local stand-in
  remote: what each does to shared history,
  and how a teammate's ordinary push
  resurrects a rewritten-away commit
- [**The edge of rescue**](the-edge-of-rescue.md) —
  where rescue ends: reflog expiry and
  garbage collection in a throwaway clone,
  and work git never had
- [**The rescue table**](the-rescue-table.md) —
  "I did X → do Y": the one page to open in
  the bad moment
- [**Glossary**](glossary.md) — the terms,
  collected in one place

## What it doesn't cover

The daily workflow itself — the sibling
*Git for Mere Mortals* owns committing,
branching, and the GitHub tools, and this
guide links there instead of repeating it.
Recovery through a hosting service's
website (a deleted repo restored from a
trash page, support tickets) is named where
it belongs and labelled documented-only:
it can't be captured in a local lab, and
its screens change. Filesystem-level
recovery of deleted files — undelete tools,
disk forensics — is a different trade;
chapter 10 marks where git's reach ends and
that trade begins.

## How to use this guide

In a real incident, start at [the rescue
table](the-rescue-table.md), do the
stop-and-check routine from chapter 1, then
read the one chapter for your disaster. To
learn it before you need it, read chapters
1–3 in order and run the lab
(`examples/plant-disasters.sh` rebuilds
every scenario in scratch directories,
never in a repo you care about). Keep the
habit the whole guide leans on: after any
rescue, commit the recovered work before
you do anything else.
