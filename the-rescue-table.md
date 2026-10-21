# The Rescue Table

**Scope:** the one page to open in the bad
moment. First the 60-second routine, then
the table. Every row points at the chapter
that proves it; if you have time, read the
chapter before running its row in anger.

## Before anything else

1. **Stop.** No more git commands "to see
   what happens." Several rescues exist only
   in the state you're in right now.
2. **`git status`** — mid-merge? mid-rebase?
   clean? Write down what it says.
3. **`git log --oneline -5`** and
   **`git reflog`** — where HEAD is, and
   where it has been. The answer to most
   disasters is already on this screen.
4. **Copy the repo**: `cp -r repo repo-backup`.
   Then experiment.
5. After a successful rescue, **commit the
   recovered work before anything else.**

## I did X → do Y

| I did this… | Do this | Chapter |
|---|---|---|
| Deleted a branch with unique work (`branch -D`) | Find the tip SHA in `git reflog`; `git branch <name> <sha>` | 2 |
| `reset --hard` past good commits | `git reset --hard ORIG_HEAD`, or the pre-reset SHA from `git reflog` | 3 |
| Reset and the changes should be staged / unstaged, not re-committed | That was `--soft` / `--mixed`; if you used the wrong one, reset to ORIG_HEAD and redo with the right mode | 3 |
| Committed to the wrong branch | `git branch <right>` **first**, then `git reset --hard HEAD~1` on the wrong branch | 4 |
| Merge is showing conflicts and I want out | `git merge --abort` (only while unfinished) | 5 |
| Rebase stopped on a conflict and I want out | `git rebase --abort` (only while stopped/unfinished) | 5 |
| Rebase *finished* and it was a mistake | `git reset --hard ORIG_HEAD` (the pre-rebase tip) | 5 |
| Merge finished, branch is mine alone | Reflog to the pre-merge SHA, reset to it | 5 |
| Dropped a stash (`stash drop` / cleared) | `git fsck --unreachable`, identify by message, `git stash apply <sha>` | 6 |
| Deleted a file, deletion committed long ago | `git log --diff-filter=D -- <path>`; restore from the deletion commit's **parent**: `git restore --source=<sha>~1 -- <path>` | 7 |
| Deleted a file, not yet committed | `git restore <path>` | 7 |
| "It worked last week, one of these commits broke it" | `git bisect` with a pass/fail test; `git bisect run` to automate | 8 |
| Pushed a bad commit to a shared branch | `git revert` it and push — never rewrite shared history | 9 |
| Pushed a bad commit to a branch only I use | Reset + `git push --force-with-lease`, after checking nobody else has the branch | 9 |
| A teammate's push brought back a commit we rewrote away | Expected: their copy still had it. Coordinate: they reset to the rewritten line; don't re-rewrite silently | 9 |
| Typed work, never staged or committed, then lost it | Git can't help — it never had the bytes. Editor history, backups, OS recovery | 10 |
| Ran reflog expiry + `gc --prune=now` (or the defaults finally elapsed) | Gone from this repo. Another clone may still hold the object — fetch it back from there | 10 |

## The three questions behind the table

Every row is one of three moves. If your
disaster isn't listed, ask which move fits:

1. **Is it still labelled somewhere?**
   (A branch, a tag, another clone, the
   remote.) Then it's not lost at all —
   check it out or fetch it.
2. **Is it unlabelled but in the reflog?**
   Then pin a label on the SHA and proceed:
   chapters 2, 3, 5, 6 are all this move
   wearing different clothes.
3. **Is it an object with no reflog entry?**
   `git fsck --unreachable` and read the
   dangling commits' messages — chapter 6's
   move. If fsck is silent and no other copy
   exists, you are at chapter 10's edge, and
   honesty beats another hour of searching.

And the row above all rows: the cheapest
rescue is the copy you made in step 4.
