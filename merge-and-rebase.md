# Merges and Rebases Gone Wrong

**Scope:** two different rescues that people
constantly confuse. While a merge or rebase
is *unfinished*, `--abort` returns you to
before it started. Once it *finishes*, abort
no longer exists — and the reflog plus
ORIG_HEAD do the job instead.

## Part 1: the merge conflict, aborted

A branch and main both rewrote the same
line of the journal — canes versus a steel
frame for the tomatoes. The merge stops:

```
$ git merge shade-plan
Auto-merging planting-notes.md
CONFLICT (content): Merge conflict in planting-notes.md
Automatic merge failed; fix conflicts and then commit the result.
$ git status --short
UU planting-notes.md
$ grep -n '<<<<<<<\|=======\|>>>>>>>' planting-notes.md
7:<<<<<<< HEAD
9:=======
11:>>>>>>> shade-plan
```

`UU` in the status: both sides updated the
same place. The file holds both versions
between the markers. You could resolve it —
but if this merge was a mistake, or the
wrong branch, or simply not today's job,
you don't have to:

```
$ git merge --abort
$ git status
On branch main
nothing to commit, working tree clean
$ sha256sum planting-notes.md
402d32727b9d8e8a015d9e31cee91b81b5fa67005316ff70242b0fbfe4dc126f  planting-notes.md
MATCH: notes byte-identical to before the merge
```

`--abort` exists **only while the merge is
unfinished** — while `.git/MERGE_HEAD`
exists, in practice while the status shows
the conflict. The moment you commit a
resolution, there is nothing to abort; the
merge is just history (and on a shared
branch, chapter 9's revert is the undo).

One catch: `--abort` restores the state
before the merge *attempt*, including
discarding any uncommitted changes that
were in the tree when you started it —
another reason chapter 1's snapshot habit
comes first.

## Part 2: the rebase conflict, aborted

Same shape, different command. A branch
(`bed1-fix`, tip `a1a72c1f…`) that changed
the same tomato line is rebased onto the
main that changed it the other way:

```
$ git rebase main
Auto-merging planting-notes.md
CONFLICT (content): Merge conflict in planting-notes.md
error: could not apply a1a72c1... Support the tomatoes with canes
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
Could not apply a1a72c1... Support the tomatoes with canes
$ git status --short
UU planting-notes.md
$ git rebase --abort
tip after abort: a1a72c1f31efb9642104632806df25165fcebec7
expected     : a1a72c1f31efb9642104632806df25165fcebec7
```

The tip SHA after the abort is the tip SHA
from before the rebase — the branch is
exactly where it was, as if the rebase had
never started.

## Part 3: the completed bad rebase

Now the harder case: a rebase that *works*.
The `signage` branch (two commits, tip
`6c635171…`) is rebased onto the advanced
main. No conflicts; git is pleased:

```
$ git rebase main
Successfully rebased and updated refs/heads/signage.
$ git log --oneline
c729bc2 Note the first sign's colour
7851128 Add the bed signs list
217deae Support the tomatoes with a steel frame
8a9e1bb Add the watering rota
b3a8332 Start the planting journal
```

Look at the first two commits: same
messages as before, **new SHAs** (`7851128`,
`c729bc2` where `482ce0c`, `6c63517` used to
be). A rebase doesn't move commits; it
copies them onto a new base. Suppose this
was wrong — the branch was supposed to stay
based on the old main, or someone else has
the old version. `--abort` is gone; the
rebase is finished history. But the *old*
commits are still objects in the repo, and
two witnesses recorded where the branch
was. ORIG_HEAD:

```
$ git rev-parse ORIG_HEAD
6c63517124de6089e5260562b1ee47d8fd579d11
```

— the exact pre-rebase tip. And the reflog
shows the whole operation, including the
`rebase (start)` line, with the old tip in
the entry just below it:

```
$ git reflog -8
c729bc2 HEAD@{0}: rebase (finish): returning to refs/heads/signage
c729bc2 HEAD@{1}: rebase (pick): Note the first sign's colour
7851128 HEAD@{2}: rebase (pick): Add the bed signs list
217deae HEAD@{3}: rebase (start): checkout main
6c63517 HEAD@{4}: checkout: moving from bed1-fix to signage
```

Reset the branch back:

```
$ git reset --hard ORIG_HEAD
HEAD is now at 6c63517 Note the first sign's colour
tip after undo: 6c63517124de6089e5260562b1ee47d8fd579d11
expected      : 6c63517124de6089e5260562b1ee47d8fd579d11
$ sha256sum signs.md
919d058e66cf897efceead980ff5b4b178e841e7b2ed752bea9e3bd939f327f9  signs.md
MATCH: signs.md byte-identical to the pre-rebase copy
```

(The rebased copies, `7851128`/`c729bc2`,
are now the unlabelled ones — they'll live
in the reflog until expiry, which is the
usual bargain.)

## Which rescue, when

| State | Rescue |
|---|---|
| Merge stopped on conflicts | `git merge --abort` |
| Rebase stopped on a conflict | `git rebase --abort` |
| Merge committed, your branch only | reset to the pre-merge SHA from the reflog |
| Rebase finished | `git reset --hard ORIG_HEAD` (or the reflog SHA) |
| Any of it already pushed and shared | Chapter 9 — don't rewrite other people's history |
