# Writing Criteria

Every guide in this repo is written to the same
standard. If you're adding or editing a guide —
human or AI — hold it to these.

1. **Plain words, real ideas.** Simple language,
   never dumbed-down concepts. Explain jargon on
   first use; collect terms in the glossary.
2. **No hype.** No marketing adjectives, no
   "revolutionary," no promises about what
   something will do for the reader.
3. **Honest about limits.** Say what the thing
   *can't* do. State uncertainty instead of
   smoothing it over. Validation notes include
   what remains unverified.
4. **No invented numbers.** Benchmarks, defaults,
   and specs are either measured or qualified with
   "depends on your setup." If it wasn't tested,
   say so.
5. **Checkable.** Commands are meant to be run,
   with "Check:" blocks showing what success looks
   like. Sources are linked, not asserted.
6. **Respect the reader's setup.** Call out
   Windows/Mac/Linux differences. Don't assume a
   GPU, a budget, or prior experience.
7. **Safety isn't skipped.** Real risks get
   stated plainly, not buried.
8. **Scoped.** Each guide says what it covers and
   points elsewhere for the rest. No guide
   pretends to be the whole subject.
9. **Structure over prose.** Tables, before/after
   examples, symptom → fix. Scannable beats essay.

## Verification notes for this guide

Standard 3 and 4 applied to this guide,
specifically. The build machine ran git
**2.43.0**, and every quoted output in the
chapters is a capture from it. The one
supporting tool is Python 3.12.3, running
the lab's five-line `tally.py`. Working
transcripts are kept with the build
(`git-rescue-lab/transcripts/`, twelve
numbered captures).

**The lab.** `examples/plant-disasters.sh`
(the build harness, shipped) creates one
scratch repository per disaster under its
own `work/` directory — never in a repo
that matters — and plants and recovers each
disaster on the record. All lab commits use
a fixed author (Sam Gardener
<sam@example.org>) and fixed +0000 commit
dates, so histories are deterministic: the
harness was re-run after a fix during the
build and every fixed-date commit SHA in
the chapters reproduced exactly. The
project is one invented specimen — the
Riverbend Community Garden journal
(`planting-notes.md`, `beds.txt`,
`tally.py`, and per-scenario files). Before
each disaster the harness copies the
at-risk file outside the repo; after each
rescue it compares the recovered file
against that copy with `cmp`, and the
chapters print the MATCH lines. The
"remote" of chapter 9 is a local bare
repository on disk; no network remote was
used. The expiry experiment of chapter 10
was run only in a throwaway clone created
for the purpose.

**Verified by running, per chapter:**

- *Ch. 1:* `git --version` (2.43.0);
  `git cat-file -p HEAD` on the garden repo
  (tree `b3999a0…`, parent `9f64b06…`,
  fixed-date author line); `.git/HEAD`
  read; `git rev-parse HEAD` (`cd06bd8…`);
  sha256 of the three base files; the
  whole-repo `cp -r` snapshot.
- *Ch. 2:* branch `bean-notes` (tip
  `dad64d8…`) deleted with `branch -D`;
  `ls` failing (exit 2); the six-line HEAD
  reflog with the tip at `HEAD@{1}`;
  recreation of the branch at the full SHA;
  `beans.md` sha256 `b17c439a…` before and
  after, `cmp` MATCH.
- *Ch. 3:* three clones of one repo (tip
  `2f762d3…`, beds sha256 `c692ee43…` in all
  three); `--soft` (changes staged,
  `diff --cached --stat` 2 files/8 lines),
  `--mixed` (same changes unstaged),
  `--hard` (clean status, `beds.txt` back to
  two beds); in the hard clone, `ORIG_HEAD`
  = `2f762d33…`, reflog shown, reset back,
  both files `cmp` MATCH.
- *Ch. 4:* the compost-rota commit
  (`1470058…`, file sha256 `0dac356a…`)
  landing on main; `git branch compost-rota`
  before the rewind; main reset to `HEAD~1`;
  `ls` failing on main; on the branch, log
  and sha256 as before, `cmp` MATCH; main's
  final log clean.
- *Ch. 5:* merge of `shade-plan` into main
  conflicting on the tomato line (exit 1,
  status `UU`, markers at lines 7/9/11);
  `git merge --abort`; journal sha256
  `402d3272…` before and after, MATCH.
  Rebase of `bed1-fix` (tip `a1a72c1…`)
  conflicting and aborted, tip SHA identical
  before and after. Completed rebase of
  `signage`: tips moved `6c635171…` →
  `c729bc2…`; `ORIG_HEAD` read back as
  `6c635171…`; reflog lines `rebase (start)`
  / `(pick)` / `(finish)` captured;
  `reset --hard ORIG_HEAD`; tip and
  `signs.md` sha256 `919d058e…` restored,
  `cmp` MATCH.
- *Ch. 6:* stash push of the
  evening-watering edit (file sha256
  `380125e0…`); `stash drop` (dropped SHA
  `ef7ea4fd…` printed by git); `fsck
  --unreachable` listing exactly two
  unreachable commits plus their tree and
  blob; the two commits identified by
  `git log -1` messages ("On main: Evening
  watering notes" vs "index on main: …");
  `git stash apply <sha>`; file sha256 back
  to `380125e0…`, `cmp` MATCH; the rescued
  work committed. Apply-vs-pop: `apply`
  left `stash@{0}` listed with the change in
  the tree; `pop` applied and dropped, list
  empty, `rota.md` `cmp` MATCH against its
  pre-stash copy.
- *Ch. 7:* `seed-library.md` (sha256
  `06481570…`) created, deleted in commit
  `9c4887a…`, two commits landing after;
  `git log -- <path>` and
  `--diff-filter=D` both naming the deletion
  commit; restore from `9c4887a…~1` by
  `git restore --source` (status `??`,
  unstaged) and by `git checkout <sha> --
  <path>` (status `A`, staged,
  `diff --cached --stat` shown); sha256 and
  `cmp` MATCH by both methods.
- *Ch. 8:* the thirteen-commit bisect repo
  (tally prints 13, `grep -c` says 14);
  manual bisect in three test steps
  (kale bad, herbs good, leeks good) ending
  "6cfcc267… is the first bad commit";
  `git bisect run` with
  `examples/tally-check.sh` reaching the
  same verdict unattended. Both verdicts
  compared against the planted first-bad
  SHA recorded by the harness at build
  time: `6cfcc267d3bb63295fa73430b96381b3e3023d68`
  — MATCH in both runs. `git bisect reset`
  and a clean status close both hunts.
- *Ch. 9:* the bad commit `d168c0b…`
  pushed to the bare remote and cloned by
  the "teammate" (beds cut to one line);
  revert `89bd18e…` pushed, remote log
  showing both commits, beds sha256 back to
  the pre-mistake `a327273a…` (MATCH), the
  teammate fast-forwarding by plain pull.
  Rewrite path: `rota-draft`'s `0dbb8c5…`
  pushed, fetched, and checked out by the
  teammate; `reset --hard HEAD~1` +
  `push --force-with-lease` (forced update
  captured); remote log without the commit;
  in the teammate's clone, status "ahead of
  'origin/rota-draft' by 1 commit", pull
  "Already up to date", the removed commit
  listed by `git log origin/rota-draft..rota-draft`;
  and the teammate's ordinary `git push`
  restoring `0dbb8c5…` to the remote —
  the resurrection, captured, is the
  chapter's point.
- *Ch. 10:* the never-committed line
  present by `grep` (line 14), removed by
  `git restore`, absent by `grep` (exit 1),
  status clean. In the throwaway clone: the
  `keepsake` branch (tip `e3075492…`)
  deleted; `git cat-file -t` answering
  `commit`; then `git reflog expire
  --expire=now --expire-unreachable=now
  --all` and `git gc --prune=now`; after
  them, `cat-file` failing — "fatal: git
  cat-file: could not get object info",
  exit 128 — and `fsck --unreachable`
  printing nothing; the clone's real
  history and clean status verified after.

**Capture hygiene (declared trims):** git's
progress redraws (the `Rebasing (n/n)` and
clone counters, which use carriage returns)
are shown in their final state; in chapter
5 one rebase hint block is quoted by its
operative line. Two verbose `git status`
blocks in chapter 6 are quoted by their
load-bearing lines (the `modified:` line
and the `Dropped refs/stash@{0}` line); the
full blocks are in the transcripts. Setup
commits were made by the harness with
`git add -A; git commit -q`, so they do not
appear as echoed commands in the
transcripts — the chapters narrate them and
quote only the resulting `git log` output,
which is captured. Clone and push captures
contain the build machine's own lab paths
(`/home/hatch/workspace/git-rescue-lab/…`);
a reader's paths will differ, as with the
parent guide's specimens. Timestamps in
stash-related SHAs: quoted from the final
harness run, as captured.

**Documented-only (not run), and why:**

- *Reflog and prune horizons over real
  time* (HEAD reflog entries kept 90 days
  for reachable commits and 30 days for
  unreachable ones; unreachable objects
  pruned after two weeks by default). The
  lab cannot wait out a calendar, and these
  are defaults a reader's configuration can
  change; they are stated in chapter 10
  from git's documentation (`git-reflog`,
  `gc.reflogExpire`, `gc.pruneExpire`).
  What the lab does prove is the mechanism:
  with expiry and pruning forced to *now*,
  the object is unrecoverable (chapter 10).
- *Hosted-service recovery* — GitHub's
  restored-deleted-branch affordances,
  deleted-repository restoration window,
  and support-assisted recovery. These need
  a live hosted account and change with the
  service's UI; they are named, not
  captured, and nothing in the chapters
  quotes their output.
- *Removing a pushed secret from history*
  (history-scrubbing tools such as
  git-filter-repo or BFG, plus host-side
  cache invalidation). Chapter 9 states the
  operative fact — the secret must be
  revoked, since every clone keeps it — and
  points to the GitHub documentation.
  Scrubbing was not run: it is a rewrite of
  exactly the kind chapter 9 warns about,
  and a lab capture would add mechanics,
  not understanding.
- *Filesystem undelete and editor
  local-history recovery* (chapter 10's
  last resorts for never-committed work):
  other tools' trades, named and scoped
  out.
- *Installation* of git on a reader's
  machine is the parent Git guide's
  subject, not repeated here; platform
  differences are minimal for these
  commands, and macOS/Windows git builds
  behave the same in every case this guide
  exercises, as far as their documentation
  states.

Specimen discipline, for the record: every
name, file, and project in the lab is
invented; the garden, its crew, and its
seed library are nobody's. All deletions,
drops, resets, force-pushes, and the expiry
experiment happen inside the lab's scratch
repositories or its local bare "remote".
No command in this guide was run against a
repository with any other purpose.
