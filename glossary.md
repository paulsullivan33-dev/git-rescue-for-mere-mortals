# Glossary

**Bisect** — git's binary search over
history: you mark a known-good and a
known-bad commit and test the midpoints
until git names the first bad one. Exit
code 125 from a `bisect run` script means
"skip this commit." Chapter 8.

**Blob** — the object kind that holds a
file's contents, named by the hash of those
contents. Two files with identical bytes
are the same blob. Chapter 1.

**Dangling / unreachable object** — an
object no ref can reach by walking parents.
Not deleted — yet — and visible to
`git fsck --unreachable`. The state dropped
stashes and deleted branches' commits pass
through. Chapters 2, 6, 10.

**Detached HEAD** — HEAD pointing directly
at a commit instead of at a branch. Where
bisect leaves you at each step; harmless,
and `git bisect reset` (or a checkout)
leaves it. Chapter 8.

**Force-with-lease** —
`git push --force-with-lease`: a force push
that refuses if the remote branch has moved
since your last fetch. The only force push
worth using; still a rewrite of history.
Chapter 9.

**fsck** — git's object-store checker.
With `--unreachable` (or `--lost-found`),
the rescue tool for objects with no reflog
entry. Chapter 6.

**Garbage collection (gc)** — git's
housekeeping: packing reachable objects and
eventually pruning unreachable ones past
their grace period. `git gc --prune=now`
skips the wait — chapter 10's cliff edge.

**Index** — the staging area: the snapshot
being prepared for the next commit. The
middle layer that reset's three modes treat
differently. Chapter 3.

**Label (ref)** — this guide's word for
what a branch or tag really is: a name
pointing at a commit's SHA. Deleting one
deletes the name, not the commit.
Chapter 1.

**Object store** — the content-addressed
database in `.git/objects` where blobs,
trees, and commits live, each named by its
contents' hash. Chapter 1.

**ORIG_HEAD** — a single remembered SHA
that reset, merge, and rebase set to HEAD's
position just before they move it. The
one-step "take me back." Chapters 3, 5.

**Reflog** — git's local diary of where
HEAD (and each ref) has been: commits,
checkouts, resets, rebases, newest first.
Never pushed, never cloned, expires by
default (90 days for reachable entries, 30
for unreachable ones). The backbone of
chapters 2, 3, 5, and 6.

**Revert** — a new commit that applies the
inverse of an earlier commit. The
history-preserving undo; the right answer
for mistakes already shared. Chapter 9.

**Rewrite** — changing history's SHAs:
reset + force-push, rebase of published
commits, amend of a pushed commit. Every
other copy of the old history becomes a
potential resurrection. Chapter 9.

**SHA** — the 40-hex-digit hash naming an
object (`dad64d8e…`). Short forms are
accepted anywhere the short form is
unambiguous — the reflog's seven digits are
enough to rescue with. Chapter 2.

**Stash commit** — what `git stash` really
makes: a commit for the index and one for
the working tree, pointed at by
`refs/stash`. Dropping the stash deletes
the ref, not the commits. Chapter 6.
