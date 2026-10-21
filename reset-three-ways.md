# Reset, Three Ways

**Scope:** what `--soft`, `--mixed`, and
`--hard` actually do differently — shown,
not asserted, by running all three on
identical histories — and how a hard reset
is undone.

## One history, three clones

The lab builds a repo with three commits —
the journal, the pepper bed, the herb bed —
and clones it three times. All three clones
start from exactly this state (identical log,
identical bytes):

```
$ git log --oneline
2f762d3 Plan the herb bed
1dc7192 Add the pepper bed
a57492e Start the planting journal
$ sha256sum beds.txt
c692ee434e73ab4bd1fbd330d8792cb9c1567556dbde3ef991535de9dd38a99f  beds.txt
```

Each clone now runs `git reset HEAD~2` —
rewind two commits — in one mode. Watch
three things after each: the log, the
status, and the file.

## --soft: only the label moves

```
$ git reset --soft HEAD~2
$ git log --oneline
a57492e Start the planting journal
$ git status --short
M  beds.txt
M  planting-notes.md
$ git diff --cached --stat
 beds.txt          | 2 ++
 planting-notes.md | 6 ++++++
 2 files changed, 8 insertions(+)
$ cat beds.txt
Bed 1: tomatoes
Bed 2: beans
Bed 3: peppers
Bed 4: herbs
```

The branch moved back two commits. The
**index** (the staging area) did not move
at all — so the two commits' changes show
up as *staged* modifications, ready to
re-commit as one. The working tree is
untouched: all four beds still in the file.
`--soft` is the mode for "let me redo those
commits as one better commit"; nothing is
ever lost by it.

## --mixed: the label and the index move

```
$ git reset --mixed HEAD~2
Unstaged changes after reset:
M	beds.txt
M	planting-notes.md
$ git status --short
 M beds.txt
 M planting-notes.md
$ git diff --stat
 beds.txt          | 2 ++
 planting-notes.md | 6 ++++++
 2 files changed, 8 insertions(+)
$ cat beds.txt
Bed 1: tomatoes
Bed 2: beans
Bed 3: peppers
Bed 4: herbs
```

Same log, same files on disk — but now the
changes are *unstaged* (note the space
before the `M` in the short status, and
that plain `git diff`, not `--cached`,
shows them). The index was rewound to match
the old commit; the working tree still
holds the work. `--mixed` is the default
when you name no mode, and the mode for
"uncommit this, I'll re-stage it properly."

## --hard: everything moves

```
$ git reset --hard HEAD~2
HEAD is now at a57492e Start the planting journal
$ git status --short
$ cat beds.txt
Bed 1: tomatoes
Bed 2: beans
```

Clean status, and the file itself is back
to two beds. The working tree was rewritten
to match the old commit. This is the mode
from the warning labels: uncommitted work
in those files would have been overwritten
too (chapter 10's first limit).

## Undoing the hard reset

And yet the two commits are not gone —
they're unlabelled, which chapter 1 says is
a solvable problem. Two witnesses name the
old tip, `2f762d3`. Before the reset, git
wrote it to **ORIG_HEAD**:

```
$ git rev-parse ORIG_HEAD
2f762d337edd72cb689143459c2c16d14583c734
$ git reflog
a57492e HEAD@{0}: reset: moving to HEAD~2
2f762d3 HEAD@{1}: clone: from /home/hatch/workspace/git-rescue-lab/work/reset-source
```

Reset back to it:

```
$ git reset --hard ORIG_HEAD
HEAD is now at 2f762d3 Plan the herb bed
$ git log --oneline
2f762d3 Plan the herb bed
1dc7192 Add the pepper bed
a57492e Start the planting journal
$ sha256sum beds.txt planting-notes.md
c692ee434e73ab4bd1fbd330d8792cb9c1567556dbde3ef991535de9dd38a99f  beds.txt
fbfd8c20e5d3978c6c160b5fdbb889de7afea201e70aa64caff3407246383ed8  planting-notes.md
MATCH: beds.txt restored byte-identical
MATCH: planting-notes.md restored byte-identical
```

## The three modes, in one table

| Mode | Branch | Index | Working tree | The rewound commits' changes end up… |
|---|---|---|---|---|
| `--soft` | moves | untouched | untouched | staged |
| `--mixed` | moves | rewound | untouched | unstaged, still in the files |
| `--hard` | moves | rewound | **rewritten** | gone from the files; recoverable via reflog/ORIG_HEAD |

One asymmetry to keep: `--hard`'s rescue
works because the discarded work was
*committed*. A `--hard` that overwrites
**uncommitted** edits has no reflog entry
for them — there is no object — and chapter
10 shows that loss for real.
