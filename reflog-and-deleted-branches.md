# The Reflog and Deleted Branches

**Scope:** the classic cold-sweat moment —
a branch deleted with `git branch -D`,
unique commits and all — and its recovery
through the reflog, proven by content.

## The disaster

The lab grows a branch called `bean-notes`
off the garden journal: two commits, one
adding `beans.md`, one extending it. On the
branch, the file hashes to:

```
$ sha256sum beans.md
b17c439a4a64f63f6dd55a6e3094d034dc24992d965e79212026e17581dbe373  beans.md
```

Back on main, the branch is deleted with
`-D` — the force form, the one that doesn't
ask whether the branch was merged:

```
$ git switch main
Switched to branch 'main'
$ git branch -D bean-notes
Deleted branch bean-notes (was dad64d8).
$ git branch
* main
$ ls beans.md
ls: cannot access 'beans.md': No such file or directory
```

By every surface sign, the work is gone:
no branch, no file. Note the one crumb git
left in the deletion message itself —
`(was dad64d8)` — the branch tip's short
SHA. That alone would be enough (a SHA is
a SHA at any length git accepts), but you
don't have to have been watching.

## The reflog still has it

The reflog recorded every stop HEAD made,
including both commits *on* the deleted
branch:

```
$ git reflog
79f28bb HEAD@{0}: checkout: moving from bean-notes to main
dad64d8 HEAD@{1}: commit: Record the bean germination check
ae895e7 HEAD@{2}: commit: Add the bean growing notes
79f28bb HEAD@{3}: checkout: moving from main to bean-notes
79f28bb HEAD@{4}: commit: Note the tomato support check
dab90a7 HEAD@{5}: commit (initial): Start the planting journal
```

`dad64d8` — the tip, the "Record the bean
germination check" commit — is `HEAD@{1}`.
Nothing was deleted except the label,
exactly as chapter 1 promised.

## The rescue

Recreate the branch at that SHA (the full
SHA here; the short one from the reflog
works too, and `HEAD@{1}` itself is a valid
name for it):

```
$ git branch bean-notes dad64d8e92ba58c3f406d6a568c576f496be50c7
$ git switch bean-notes
Switched to branch 'bean-notes'
$ ls
beans.md
beds.txt
planting-notes.md
tally.py
```

And the proof — not the file's existence,
its bytes:

```
$ sha256sum beans.md
b17c439a4a64f63f6dd55a6e3094d034dc24992d965e79212026e17581dbe373  beans.md
MATCH: beans.md is byte-identical to the pre-deletion copy
$ git log --oneline
dad64d8 Record the bean germination check
ae895e7 Add the bean growing notes
79f28bb Note the tomato support check
dab90a7 Start the planting journal
```

Both commits are back, the full history
intact, because the recovery didn't
reconstruct anything — it just re-labelled
objects that never left.

## What to remember

- `-d` (lowercase) refuses to delete an
  unmerged branch; `-D` is the override,
  and the one that sets up this disaster.
- The deletion message prints the tip SHA.
  The reflog prints it again, with context.
  `git log --all` does **not** find it —
  `--all` means all *refs*, and the ref is
  what you deleted.
- This works while the reflog entry and the
  objects survive: normally weeks. Chapter
  10 shows what ends it.
- Reflogs are per-ref, too:
  `git reflog show bean-notes` would have
  been the branch's own diary — but it is
  deleted with the branch. The HEAD reflog
  above is the one that saves you.
