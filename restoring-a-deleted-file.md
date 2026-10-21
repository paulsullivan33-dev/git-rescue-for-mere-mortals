# Restoring a File Deleted Commits Ago

**Scope:** a file was deleted, the deletion
was committed, and more commits have landed
since. `git restore` in its everyday form
only reaches into the index and HEAD — this
is the longer reach, back through history,
with two ways to do it that differ in one
detail worth knowing.

## The setup

The journal repo gains a `seed-library.md`,
then a results note is committed, then —
three commits back from today's HEAD — the
file is deleted and the deletion committed:

```
$ git log --oneline
385d610 Note the shed padlock
0e91b06 Add the squash bed
9c4887a Tidy the journal: drop the seed list
091bc6d Note the bean trial results
96928b9 Start the seed library list
e26ed6a Start the planting journal
$ ls seed-library.md
ls: cannot access 'seed-library.md': No such file or directory
```

In its last living version the file hashed
to `06481570…` — the value the rescue has to
reproduce.

## Find the deletion, then its parent

Two questions, two log filters. Everything
that ever happened to the path:

```
$ git log --oneline --all -- seed-library.md
9c4887a Tidy the journal: drop the seed list
96928b9 Start the seed library list
```

And specifically the commit that *deleted*
it (`--diff-filter=D` keeps only commits
where the file was deleted):

```
$ git log --diff-filter=D --oneline -- seed-library.md
9c4887a Tidy the journal: drop the seed list
```

The file's last living version is in that
commit's **parent** — `9c4887a~1`,
"Note the bean trial results". Restoring
*from* the deletion commit would be
restoring nothing; the parent is the trick
the whole chapter stands on.

## Method 1: restore from a source

```
$ git restore --source=9c4887acaffe730f0a6289bad417723e0d2f9826~1 -- seed-library.md
$ git status --short
?? seed-library.md
$ sha256sum seed-library.md
06481570f9da4cd165a543c3e6f370629e3545c6b1c02fff55a83d003022a070  seed-library.md
MATCH: restored file byte-identical to its last living version
```

Plain `git restore` works from the index;
`--source=<commit>` tells it to read from
any commit instead. Note the status: `??` —
the file is back in the working tree as a
new, untracked file, **not staged**. Since
HEAD doesn't contain the file, there is
nothing in the index to restore *to*; git
wrote the bytes and left tracking to you.
`git add` and commit when you're satisfied.

## Method 2: checkout the path from a commit

The older spelling does the same reach with
one difference:

```
$ git checkout 9c4887acaffe730f0a6289bad417723e0d2f9826~1 -- seed-library.md
$ git status --short
A  seed-library.md
$ git diff --cached --stat
 seed-library.md | 7 +++++++
 1 file changed, 7 insertions(+)
$ sha256sum seed-library.md
06481570f9da4cd165a543c3e6f370629e3545c6b1c02fff55a83d003022a070  seed-library.md
MATCH: same bytes by the second method too
```

Identical bytes — but `A ` in the status:
`checkout <commit> -- <path>` updates the
index as well as the tree, so the file
arrives **staged**. Neither is wrong; know
which one you did before the next commit
sweeps it in (or doesn't).

## Variations worth knowing

- **An older version, not the last one:**
  the same commands with any earlier SHA
  from the path's log — the way to recover
  the paragraph a later edit removed.
  Restore it to a *different* name
  (`git show <sha>:seed-library.md > old.md`)
  if you want to compare rather than replace.
- **Changed, not deleted:** if the file
  still exists but its content was mangled,
  the everyday `git restore --source=<sha>
  -- <path>` overwrites the tree copy with
  the chosen version (and a plain
  `git restore <path>` still does the
  HEAD-version job). Check with
  `git diff <sha> -- <path>` first if you're
  unsure the old version is the one you
  want.
- **A deletion not yet committed** isn't
  this chapter at all: `git restore <path>`
  brings it back from the index in one step.
