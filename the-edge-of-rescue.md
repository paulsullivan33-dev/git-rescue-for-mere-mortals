# The Edge of Rescue

**Scope:** an honest map of where rescue
stops. Two boundaries, both demonstrated:
garbage collection can be told to take the
safety net away (shown in a throwaway clone,
never one that matters), and some work git
cannot lose because it never had it.

## Limit 1: work that was never committed

The reflog records *commits and checkouts*.
The stash works because it makes commits.
So the precondition for almost every rescue
in this guide is that the work became an
object at least once — staged counts (the
index is written to objects), committed
certainly. Work that exists only as edits
in the working tree has no object, no hash,
no reflog entry. When the lab appends a
line to the journal and then restores the
file:

```
$ grep -n scarecrow planting-notes.md
14:An unsaved line about the scarecrow.
$ git restore planting-notes.md
$ grep -n scarecrow planting-notes.md
[exit 1]
$ git status --short
```

The line is gone, the status is clean, and
there is nothing to find it *with*: no SHA
exists for it, `git fsck` has no object to
report, the reflog never saw it. The same
is true of an untracked file you delete
with the operating system — git never knew
its name. (Your editor's local history,
backups, or filesystem undelete tools are
the remaining options; they're outside git,
and outside this guide.)

This is the practical argument for two
habits the earlier chapters keep modelling:
commit early (a `wip` commit is a rescue
point), and stash rather than restore when
you're discarding work "just for now" — the
stash makes the objects that make rescue
possible.

## Limit 2: expiry and garbage collection

Rescue normally survives because git is in
no hurry to delete. Unreachable objects are
kept for a grace period, and reflog entries
have their own defaults — from git's
documentation: entries for commits reachable
from the current tip are kept **90 days**,
entries for unreachable commits **30 days**,
and unreachable objects are pruned after
**two weeks** by default. (Those horizons
are documented behaviour, quoted as such in
criteria.md; the lab proves the *mechanism*
below, not the calendar.)

Here is the mechanism. In a throwaway clone
of the garden repo — **a clone, made to be
destroyed; do not run this sequence in a
repository you care about** — a branch is
created, given a commit, and deleted, as in
chapter 2. Right after deletion, the object
is still there:

```
$ git branch -D keepsake
Deleted branch keepsake (was e307549).
$ git cat-file -t e3075492eb9ff9d004ec6f016d4699b298e15a75
commit
```

Now the safety net is removed by hand —
expire every reflog entry immediately, then
garbage-collect with pruning set to *now*
instead of the grace period:

```
$ git reflog expire --expire=now --expire-unreachable=now --all
$ git gc --prune=now
$ git cat-file -t e3075492eb9ff9d004ec6f016d4699b298e15a75
fatal: git cat-file: could not get object info
[exit 128]
$ git fsck --unreachable
```

The object is gone. `cat-file` fails with
exit 128, `fsck` reports nothing unreachable
(there is nothing left to report), and the
clone's real history is untouched:

```
$ git log --oneline
cd06bd8 Note the soil at the north end
9f64b06 Start the planting journal
$ git status --short
```

That is the true end of the line for a
deleted branch: not the `-D` (chapter 2
shrugged that off), but expiry plus pruning.
It is also why hosted copies matter —
another clone still holding the object has
its own reflogs and its own objects, and
the commit can travel back from there. What
expires in one repository expires only there.

## The boundary, summarised

| Situation | Rescuable? |
|---|---|
| Branch deleted, reflog intact | Yes — chapter 2 |
| Commits rewound by reset/rebase | Yes — chapters 3, 6 |
| Stash dropped, objects unpruned | Yes — chapter 7 |
| File deleted in a committed commit | Yes — chapter 8 |
| Reflog expired **and** objects pruned | **No** — not from this repo |
| Never staged, never committed | **No** — git never had it |
| Deleted from the working tree by the OS, untracked | **No** — not git's layer |
| Pushed secret "removed" by revert | Still in history — revoke the secret |
