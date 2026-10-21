# A Commit on the Wrong Branch

**Scope:** you committed good work to
`main` that belonged on its own branch. The
rescue is two commands — and doing them in
the wrong order is how a five-second fix
becomes a chapter-2 rescue.

## The disaster

The journal repo has a tidy main:

```
$ git log --oneline
d51714a Add the watering rota
37fd9da Start the planting journal
```

Then a draft of a compost rota — work that
should have been a branch of its own — is
committed straight onto main:

```
$ git log --oneline
1470058 Draft the compost rota
d51714a Add the watering rota
37fd9da Start the planting journal
$ sha256sum compost-rota.md
0dac356a83640878c1f4add58a189406d3666f96795f18284cdf13eb0f092534  compost-rota.md
```

Two things are true at once: the commit is
in the wrong place, and it is *safe* — it
exists, it's labelled (by main). It only
becomes unsafe if you rewind main before
giving the commit another label.

## The rescue: branch first, rewind second

**Step 1 — pin the commit where it sits.**
Creating a branch moves nothing; it just
adds a label at HEAD:

```
$ git branch compost-rota
$ git branch -v
  compost-rota 1470058 Draft the compost rota
* main         1470058 Draft the compost rota
```

Both labels now name the same commit. The
work cannot be lost by anything you do to
main next.

**Step 2 — rewind the wrong branch.**

```
$ git reset --hard HEAD~1
HEAD is now at d51714a Add the watering rota
$ git log --oneline
d51714a Add the watering rota
37fd9da Start the planting journal
$ ls compost-rota.md
ls: cannot access 'compost-rota.md': No such file or directory
```

Main is clean, and the file is gone *from
main* — which was the point.

**Step 3 — check the work on its branch.**

```
$ git switch compost-rota
Switched to branch 'compost-rota'
$ git log --oneline
1470058 Draft the compost rota
d51714a Add the watering rota
37fd9da Start the planting journal
$ sha256sum compost-rota.md
0dac356a83640878c1f4add58a189406d3666f96795f18284cdf13eb0f092534  compost-rota.md
MATCH: compost-rota.md identical after the move
```

Nothing was moved, in the end. A label was
added, a label was rewound, and the commit
sat still the whole time.

## The wrong order, and other variants

- If you reset main *first*, the commit is
  unlabelled and you are in chapter 2: it
  still works — the reflog has the SHA —
  but you have traded a trivial fix for a
  rescue. Order is the lesson.
- **Several commits on the wrong branch**
  is the same shape: branch at the tip,
  then `git reset --hard HEAD~N` on the
  wrong branch for the right N. Count from
  `git log --oneline`, and check twice —
  `--hard` does not ask.
- If the wrong-branch commit is **not the
  tip** (more commits landed after it), a
  reset can't lift it out cleanly; that's a
  job for `git cherry-pick` (copy the commit
  onto the right branch) plus a history
  decision on the wrong one — the daily Git
  guide's cookbook covers cherry-pick, and
  on a shared branch chapter 9's revert is
  usually the honest fix.
- Nothing here touches the remote: if the
  commit was already pushed, rewinding your
  local main diverges from it — read
  chapter 9 before force-pushing anything.
