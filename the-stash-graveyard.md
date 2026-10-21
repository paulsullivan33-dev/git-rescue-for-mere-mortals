# The Stash Graveyard

**Scope:** the deepest rescue in this guide.
A stash that has been *dropped* has no ref
and no reflog entry you can list — but the
stash was a commit, and commits are objects.
`git fsck` can still see it.

## A stash is a commit wearing a disguise

When you stash, git doesn't file your work
away in a drawer. It makes real commits: one
for the index, one for the working tree
(with the index commit as a second parent),
and points the special ref `refs/stash` at
the result. That is why a dropped stash is
recoverable the same way a deleted branch
is — one level further down, without the
reflog's help.

The lab types an "Evening watering" section
into the journal, uncommitted
(`sha256sum …380125e0…` before anything goes
wrong), and stashes it:

```
$ git stash push -m "Evening watering notes"
Saved working directory and index state On main: Evening watering notes
$ git stash list
stash@{0}: On main: Evening watering notes
```

## The disaster: drop

```
$ git stash drop
Dropped refs/stash@{0} (ef7ea4fd1b43a5b7e2b007ac99d7293884c3b008)
$ git stash list
```

Empty. The ref is gone, and the entry with
it. (Again, notice the crumb: the drop
message prints the SHA. If your terminal
still shows it, you can skip the next step.
The lab works the harder case, where it
scrolled away.)

## Finding it: fsck and the dangling commits

`git fsck` checks the object store and
reports, among other things, objects no ref
can reach:

```
$ git fsck --unreachable
unreachable blob 02d9269e8dbb5dee0e4f8fd12cec755ebb573508
unreachable tree 0762d5fe64c1a1184848a1756b028ccb3c981d71
unreachable commit ef7ea4fd1b43a5b7e2b007ac99d7293884c3b008
unreachable commit 9f9845b80595600c1071c87c3eed21ffa77dc397
```

Four unreachable objects: a blob and a tree
(pieces of the stash), and **two commits**.
Two, because a stash is two commits. Which
is which? Read their messages — `git log -1`
on each candidate:

```
ef7ea4fd1b43a5b7e2b007ac99d7293884c3b008 On main: Evening watering notes
9f9845b80595600c1071c87c3eed21ffa77dc397 index on main: 9de1570 Add the watering rota
```

The `index on…` commit is the stash's
sibling (what was staged). The one to
rescue is the working-tree commit — the one
carrying your message.

## The rescue

`git stash apply` accepts any commit-shaped
stash, ref or no ref:

```
$ git stash apply ef7ea4fd1b43a5b7e2b007ac99d7293884c3b008
On branch main
Changes not staged for commit:
	modified:   planting-notes.md
$ git status --short
 M planting-notes.md
$ sha256sum planting-notes.md
380125e058d0a5f77f6239cd49c4becaf6474803c062f8b7bc78b10051e7dbdf  planting-notes.md
MATCH: the dropped stash's work is back, byte-identical
```

Then the habit the lab models: **commit the
rescued work immediately** (it does; the
tree is clean in the next capture). A rescue
that stays uncommitted is one `restore`
away from needing rescuing again — and next
time there may be no object to find.

## Apply vs pop, captured

Since stashes are on the table: the two
verbs differ in exactly one thing — whether
the entry survives. A second, smaller stash
("Mulch note", a line added to the rota):

```
$ git stash apply
	modified:   rota.md
$ git stash list
stash@{0}: On main: Mulch note
```

`apply` puts the change in the tree and
**keeps** the entry — safe, and the right
default when you're not sure the apply went
well. The lab then discards the tree copy,
and:

```
$ git stash pop
	modified:   rota.md
Dropped refs/stash@{0} (ae49264639dee4e4dd072eaaa52479be051e5be1)
$ git stash list
$ sha256sum rota.md
b9f0cd87eb3e0c62816d92333c44a2d3249e28fbfbc20ef4614d55a001820479  rota.md
MATCH: rota.md identical after apply/pop round trip
```

`pop` is `apply` plus `drop`, in that order
— and only drops when the apply succeeds
cleanly. If a popped stash conflicts, it is
*not* dropped, which is deliberate: git
won't throw away the only copy while its
contents are half-merged into your tree.

One footnote: stash commits are stamped
with the real time they were made, unlike
the lab's fixed-date commits — their SHAs
differ on every run of the lab. Their
messages are what you identify them by,
here as everywhere.
