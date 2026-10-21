# Pushed Mistakes: Revert or Rewrite

**Scope:** every rescue so far was local.
Once a mistake is *pushed*, other clones
have it, and the question changes from
"can I undo this?" to "what does undoing
it do to everyone else?" Both answers are
demonstrated here against a local bare repo
standing in for the remote — same protocol
shape, everything captured.

## The mistake, pushed

The lab's remote is a bare clone on disk.
A commit that cuts `beds.txt` down to a
single bed ("Clear the beds list for
winter", `d168c0b`) is pushed to main:

```
$ git push origin main
To /home/hatch/workspace/git-rescue-lab/work/push-lab/remote.git
   6739007..d168c0b  main -> main
$ git --git-dir=../remote.git log --oneline main
d168c0b Clear the beds list for winter
6739007 Add the watering rota
b3a8332 Start the planting journal
```

A teammate clones and gets the damage:

```
$ cat beds.txt
Bed 1: tomatoes
```

## Path A: revert — history keeps both

A revert is a *new* commit that applies the
inverse of the bad one. Nothing is
rewritten; the bad commit stays in history,
clearly labelled, answered by its undo:

```
$ git revert --no-edit HEAD
[main 89bd18e] Revert "Clear the beds list for winter"
 1 file changed, 1 insertion(+)
$ git push origin main
   d168c0b..89bd18e  main -> main
$ git --git-dir=../remote.git log --oneline main
89bd18e Revert "Clear the beds list for winter"
d168c0b Clear the beds list for winter
6739007 Add the watering rota
b3a8332 Start the planting journal
$ sha256sum beds.txt
a327273a92313f4292117f42e36f2b84d4db0c87cba7528dfc209bdf1c2417d8  beds.txt
```

That hash is the pre-mistake hash: the
bytes are the good bytes (the lab compares
them and reports MATCH). And because the
fix is an ordinary fast-forward, the
teammate's recovery is an ordinary pull:

```
$ git pull
Updating d168c0b..89bd18e
Fast-forward
 beds.txt | 1 +
$ cat beds.txt
Bed 1: tomatoes
Bed 2: beans
$ git log --oneline
89bd18e Revert "Clear the beds list for winter"
d168c0b Clear the beds list for winter
```

**This is the default for any branch anyone
else has.** The cost is cosmetic — an ugly
commit in the log, honestly labelled — and
the benefit is that no other copy of the
repo is invalidated.

## Path B: rewrite — reset and force-push

On a second branch, `rota-draft`, the lab
does it the other way. A bad commit
(`0dbb8c5`, "Rewrite the rota from memory")
is pushed; the teammate fetches and checks
the branch out. Then the author resets it
away and force-pushes:

```
$ git reset --hard HEAD~1
HEAD is now at 89bd18e Revert "Clear the beds list for winter"
$ git push --force-with-lease origin rota-draft
 + 0dbb8c5...89bd18e rota-draft -> rota-draft (forced update)
$ git --git-dir=../remote.git log --oneline rota-draft
89bd18e Revert "Clear the beds list for winter"
d168c0b Clear the beds list for winter
6739007 Add the watering rota
b3a8332 Start the planting journal
```

On the remote, the bad commit is gone.
(`--force-with-lease` rather than `--force`:
it refuses if the remote moved since your
last fetch — the seatbelt version, and the
only form worth using.) But the remote is
not the only copy. In the teammate's clone:

```
$ git fetch origin
 + 0dbb8c5...89bd18e rota-draft -> origin/rota-draft  (forced update)
$ git status
On branch rota-draft
Your branch is ahead of 'origin/rota-draft' by 1 commit.
$ git pull
Already up to date.
$ git log --oneline origin/rota-draft..rota-draft
0dbb8c5 Rewrite the rota from memory
```

Read that carefully, because it's the part
people get wrong: the teammate's branch
still *contains* the removed commit — from
git's point of view they're simply "ahead".
Pull won't fix it (there's nothing to pull;
the remote tip is their ancestor). And the
quiet catastrophe is one command away:

```
$ git push origin rota-draft
   89bd18e..0dbb8c5  rota-draft -> rota-draft
$ git --git-dir=../remote.git log --oneline rota-draft
0dbb8c5 Rewrite the rota from memory
89bd18e Revert "Clear the beds list for winter"
```

A perfectly ordinary push — no force, no
warning — resurrects the commit everyone
thought was erased. That is why rewriting a
shared branch isn't a solo decision: it
requires every holder of the branch to
reset their copy to the new line, and
anyone who misses the memo can undo it by
accident.

## The etiquette, distilled

| The branch is… | Undo a pushed mistake by… |
|---|---|
| Shared (anyone may have pulled) | `git revert`, pushed normally |
| Yours alone, nobody else has it | reset + `git push --force-with-lease`, if you must |
| Yours, but a teammate checked it out | Treat as shared until you've coordinated the reset with them |

One more case, named plainly because guides
should: if the pushed commit contains a
*secret* (a password, a key), revert does
not help — the secret remains in history on
every clone, and the correct response is to
**revoke the secret** first and treat
history-scrubbing as the second, lesser
job. That is beyond this guide's lab; the
GitHub documentation on removing sensitive
data is the reference (see criteria.md —
documented-only, not run here).
