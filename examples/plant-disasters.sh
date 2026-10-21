#!/usr/bin/env bash
# Git Rescue lab harness. Plants each disaster in a scratch repo and
# recovers on the record. Every step is echoed to a numbered transcript.
# Deterministic: fixed author, fixed +0000 commit dates, fixed content.

LAB="$(cd "$(dirname "$0")" && pwd)"
WORK="$LAB/work"
EXP="$LAB/expected"
TRANS="$LAB/transcripts"
rm -rf "$WORK" "$LAB/home"
mkdir -p "$WORK" "$EXP" "$TRANS" "$LAB/home"

export HOME="$LAB/home"
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME="Sam Gardener"
export GIT_AUTHOR_EMAIL="sam@example.org"
export GIT_COMMITTER_NAME="Sam Gardener"
export GIT_COMMITTER_EMAIL="sam@example.org"
git config --global init.defaultBranch main
git config --global advice.detachedHead false

DAY=0
stamp() { # advance the fixed clock one day and export it
  DAY=$((DAY+1))
  local d
  d=$(printf '2026-03-%02dT09:00:00+00:00' $(( (DAY-1) % 28 + 1 )))
  export GIT_AUTHOR_DATE="$d" GIT_COMMITTER_DATE="$d"
}
commit() { # commit -m handled by caller args; run inside current repo
  stamp
  git add -A
  git commit -q "$@"
}
run() { # echo a command, run it, record its exit code
  printf '$ %s\n' "$*"
  "$@"
  echo "[exit $?]"
}
new_repo() { # new_repo NAME — fresh repo with the base garden files, cd'd into
  mkdir -p "$WORK/$1"
  cd "$WORK/$1" || return 1
  git init -q -b main
  base_files
}
base_files() {
  cat > planting-notes.md <<'EOF'
# Riverbend Community Garden — Planting Journal

Kept by the Saturday crew. One section per bed.

## Bed 1 — Tomatoes
Started indoors on the first Saturday of March.
Supported with string from the tool shed.

## Bed 2 — Beans
Direct-sown in rows, thinned after germination.
EOF
  cat > beds.txt <<'EOF'
Bed 1: tomatoes
Bed 2: beans
EOF
  cat > tally.py <<'EOF'
from pathlib import Path

rows = [line for line in Path("beds.txt").read_text().splitlines() if line.strip()]
print(len(rows))
EOF
}
write_rota() {
  cat > rota.md <<'EOF'
# Watering Rota

- Monday: Sam
- Wednesday: Jo
- Friday: Priya
EOF
}

# ---------------------------------------------------------------- t01
t01() {
  run git --version
  mkdir -p "$WORK/garden"
  cd "$WORK/garden" || return 1
  run git init -b main
  base_files
  commit -m "Start the planting journal"
  cat >> planting-notes.md <<'EOF'

## Notes on the soil
The north end drains slowly after rain.
EOF
  commit -m "Note the soil at the north end"
  run git log --oneline
  run git status
  run cat .git/HEAD
  run git rev-parse HEAD
  run git cat-file -p HEAD
  run sha256sum planting-notes.md beds.txt tally.py
  cp planting-notes.md "$EXP/garden-notes-v2.md"
  echo "--- the snapshot habit: copy the whole repo before risky work ---"
  run cp -r "$WORK/garden" "$WORK/garden-backup"
  run ls "$WORK/garden-backup"
}

# ---------------------------------------------------------------- t02
t02() {
  new_repo branch-repo
  commit -m "Start the planting journal"
  echo "The tomato supports were checked on Saturday." >> planting-notes.md
  commit -m "Note the tomato support check"
  run git switch -c bean-notes
  cat > beans.md <<'EOF'
# Bean Notes

Variety: Provider bush beans.
Sow after the last frost date on the wall chart.
Rows: 45 cm apart, seeds 5 cm deep.
EOF
  commit -m "Add the bean growing notes"
  echo "Germination check: most rows up by day nine." >> beans.md
  commit -m "Record the bean germination check"
  run git log --oneline
  TIP=$(git rev-parse HEAD)
  echo "branch tip before deletion: $TIP"
  cp beans.md "$EXP/beans.md"
  run sha256sum beans.md
  run git switch main
  run git branch -D bean-notes
  run git branch
  run ls beans.md
  echo "--- the reflog remembers where HEAD has been ---"
  run git reflog
  echo "--- recover: recreate the branch at the tip SHA from the reflog ---"
  run git branch bean-notes "$TIP"
  run git switch bean-notes
  run ls
  run sha256sum beans.md
  cmp beans.md "$EXP/beans.md" && echo "MATCH: beans.md is byte-identical to the pre-deletion copy"
  run git log --oneline
}

# ---------------------------------------------------------------- t03
t03() {
  new_repo reset-source
  commit -m "Start the planting journal"
  echo "Bed 3: peppers" >> beds.txt
  cat >> planting-notes.md <<'EOF'

## Bed 3 — Peppers
Started indoors, two weeks after the tomatoes.
EOF
  commit -m "Add the pepper bed"
  echo "Bed 4: herbs" >> beds.txt
  cat >> planting-notes.md <<'EOF'

## Bed 4 — Herbs
Basil beside the tomatoes, chives along the path.
EOF
  commit -m "Plan the herb bed"
  cp beds.txt "$EXP/beds-4.txt"
  cp planting-notes.md "$EXP/notes-4beds.md"
  cd "$WORK" || return 1
  run git clone -q reset-source reset-soft
  run git clone -q reset-source reset-mixed
  run git clone -q reset-source reset-hard
  for mode in soft mixed hard; do
    echo "================ reset --$mode ================"
    cd "$WORK/reset-$mode" || return 1
    run git log --oneline
    run sha256sum beds.txt
    if [ "$mode" = soft ]; then
      run git reset --soft HEAD~2
      echo "--- log now ---"; run git log --oneline
      echo "--- status: the two commits' changes are STAGED ---"
      run git status --short
      run git diff --cached --stat
      echo "--- working tree still holds all four beds ---"
      run cat beds.txt
    elif [ "$mode" = mixed ]; then
      run git reset --mixed HEAD~2
      echo "--- log now ---"; run git log --oneline
      echo "--- status: the changes are present but UNSTAGED ---"
      run git status --short
      run git diff --stat
      echo "--- working tree still holds all four beds ---"
      run cat beds.txt
    else
      run git reset --hard HEAD~2
      echo "--- log now ---"; run git log --oneline
      echo "--- status: clean; the working tree was rewound too ---"
      run git status --short
      run cat beds.txt
      echo "--- rescue: ORIG_HEAD names where reset moved from ---"
      run git rev-parse ORIG_HEAD
      run git reflog
      run git reset --hard ORIG_HEAD
      run git log --oneline
      run sha256sum beds.txt planting-notes.md
      cmp beds.txt "$EXP/beds-4.txt" && echo "MATCH: beds.txt restored byte-identical"
      cmp planting-notes.md "$EXP/notes-4beds.md" && echo "MATCH: planting-notes.md restored byte-identical"
    fi
  done
}

# ---------------------------------------------------------------- t04
t04() {
  new_repo wrong-branch
  commit -m "Start the planting journal"
  write_rota
  commit -m "Add the watering rota"
  run git log --oneline
  echo "--- the mistake: a commit that belonged on its own branch lands on main ---"
  cat > compost-rota.md <<'EOF'
# Compost Rota — Draft

Turn pile 1 every Friday.
Add browns when the pile smells sweet.
EOF
  commit -m "Draft the compost rota"
  cp compost-rota.md "$EXP/compost-rota.md"
  run sha256sum compost-rota.md
  run git log --oneline
  echo "--- rescue, in order: branch FIRST, then rewind main ---"
  run git branch compost-rota
  run git branch -v
  run git reset --hard HEAD~1
  run git log --oneline
  run ls compost-rota.md
  echo "--- the work is safe on its branch ---"
  run git switch compost-rota
  run git log --oneline
  run ls
  run sha256sum compost-rota.md
  cmp compost-rota.md "$EXP/compost-rota.md" && echo "MATCH: compost-rota.md identical after the move"
  run git switch main
  run git log --oneline
}

# ---------------------------------------------------------------- t05
t05() {
  new_repo merge-repo
  commit -m "Start the planting journal"
  run git switch -c shade-plan
  sed -i 's/Supported with string from the tool shed./Supported with canes from the tool shed./' planting-notes.md
  commit -m "Support the tomatoes with canes"
  run git switch main
  sed -i 's/Supported with string from the tool shed./Supported with a steel frame./' planting-notes.md
  commit -m "Support the tomatoes with a steel frame"
  run sha256sum planting-notes.md
  cp planting-notes.md "$EXP/notes-main-frame.md"
  echo "--- the merge goes wrong ---"
  run git merge shade-plan
  run git status --short
  run grep -n '<<<<<<<\|=======\|>>>>>>>' planting-notes.md
  echo "--- the way out while the merge is unfinished ---"
  run git merge --abort
  run git status
  run sha256sum planting-notes.md
  cmp planting-notes.md "$EXP/notes-main-frame.md" && echo "MATCH: notes byte-identical to before the merge"
  run git log --oneline
}

# ---------------------------------------------------------------- t06
t06() {
  new_repo rebase-repo
  commit -m "Start the planting journal"
  run git switch -c signage
  cat > signs.md <<'EOF'
# Bed Signs

Painted wooden signs, one per bed.
EOF
  commit -m "Add the bed signs list"
  echo "Bed 1 sign: red lettering." >> signs.md
  commit -m "Note the first sign's colour"
  cp signs.md "$EXP/signs.md"
  SIGN_TIP=$(git rev-parse HEAD)
  echo "signage tip before any rebase: $SIGN_TIP"
  run git switch main
  write_rota
  commit -m "Add the watering rota"
  sed -i 's/Supported with string from the tool shed./Supported with a steel frame./' planting-notes.md
  commit -m "Support the tomatoes with a steel frame"
  run git log --oneline --all
  echo "=== part A: a rebase that conflicts — abort it ==="
  run git switch -c bed1-fix HEAD~2
  sed -i 's/Supported with string from the tool shed./Supported with canes from the tool shed./' planting-notes.md
  commit -m "Support the tomatoes with canes"
  FIX_TIP=$(git rev-parse HEAD)
  echo "bed1-fix tip before rebase: $FIX_TIP"
  run git rebase main
  run git status --short
  run git rebase --abort
  echo "tip after abort: $(git rev-parse HEAD)"
  echo "expected     : $FIX_TIP"
  run git log --oneline
  echo "=== part B: a rebase that COMPLETES — and is still wrong ==="
  run git switch signage
  run git rebase main
  echo "--- the commits were replayed: same messages, new SHAs ---"
  run git log --oneline
  echo "tip now: $(git rev-parse HEAD)  (before: $SIGN_TIP)"
  echo "--- undo it: ORIG_HEAD still names the pre-rebase tip ---"
  run git rev-parse ORIG_HEAD
  run git reflog -8
  run git reset --hard ORIG_HEAD
  echo "tip after undo: $(git rev-parse HEAD)"
  echo "expected      : $SIGN_TIP"
  run sha256sum signs.md
  cmp signs.md "$EXP/signs.md" && echo "MATCH: signs.md byte-identical to the pre-rebase copy"
  run git log --oneline
}

# ---------------------------------------------------------------- t07
t07() {
  new_repo stash-repo
  commit -m "Start the planting journal"
  write_rota
  commit -m "Add the watering rota"
  echo "--- uncommitted work: an evening-watering section, typed but not committed ---"
  cat >> planting-notes.md <<'EOF'

## Evening watering
In a hot week, water after 6 pm so less is lost to the sun.
Check the bean rows first; they dry out fastest.
EOF
  cp planting-notes.md "$EXP/notes-evening.md"
  run sha256sum planting-notes.md
  run git stash push -m "Evening watering notes"
  run git status --short
  run git stash list
  echo "--- the disaster: the stash is dropped ---"
  run git stash drop
  run git stash list
  echo "--- the stash commit is now dangling; fsck can still see it ---"
  run git fsck --unreachable
  echo "--- identify the dangling commits by their messages ---"
  for sha in $(git fsck --unreachable 2>/dev/null | awk '$2 == "commit" {print $3}'); do
    git log -1 --format='%H %s' "$sha"
  done
  STASH_SHA=$(for sha in $(git fsck --unreachable 2>/dev/null | awk '$2 == "commit" {print $3}'); do
    case "$(git log -1 --format=%s "$sha")" in
      *"Evening watering notes") echo "$sha" ;;
    esac
  done)
  echo "the dropped stash commit: $STASH_SHA"
  run git stash apply "$STASH_SHA"
  run git status --short
  run sha256sum planting-notes.md
  cmp planting-notes.md "$EXP/notes-evening.md" && echo "MATCH: the dropped stash's work is back, byte-identical"
  echo "--- rescue first, then commit the rescued work straight away ---"
  commit -m "Add the evening watering notes"
  run git status --short
  echo "=== apply keeps the entry; pop drops it ==="
  echo "Extra mulch for the bean rows." >> rota.md
  cp rota.md "$EXP/rota-mulch.md"
  run git stash push -m "Mulch note"
  run git stash apply
  echo "--- after apply: the change is in the tree AND still in the list ---"
  run git stash list
  run git status --short
  run git restore rota.md
  run git stash pop
  echo "--- after pop: the change is back and the list is empty ---"
  run git stash list
  run git status --short
  run sha256sum rota.md
  cmp rota.md "$EXP/rota-mulch.md" && echo "MATCH: rota.md identical after apply/pop round trip"
}

# ---------------------------------------------------------------- t08
t08() {
  new_repo restore-repo
  commit -m "Start the planting journal"
  cat > seed-library.md <<'EOF'
# Seed Library

Kept in the shed cupboard, in labelled envelopes.

- Provider beans, saved last autumn
- Sungold tomato seed, bought new
- Chive seed, saved two years running
EOF
  commit -m "Start the seed library list"
  echo "Bean trial: Provider out-yielded the other rows." >> planting-notes.md
  commit -m "Note the bean trial results"
  cp seed-library.md "$EXP/seed-library.md"
  run sha256sum seed-library.md
  echo "--- some commits later, the file is deleted and the deletion committed ---"
  run git rm -q seed-library.md
  commit -m "Tidy the journal: drop the seed list"
  echo "Bed 5: squash" >> beds.txt
  commit -m "Add the squash bed"
  echo "The shed padlock sticks; oil it." >> planting-notes.md
  commit -m "Note the shed padlock"
  run git log --oneline
  run ls seed-library.md
  echo "--- find when it died, and the last commit where it lived ---"
  run git log --oneline --all -- seed-library.md
  run git log --diff-filter=D --oneline -- seed-library.md
  DEL=$(git log --diff-filter=D --format=%H -1 -- seed-library.md)
  LAST_LIVING="$DEL~1"
  echo "deletion commit: $DEL"
  echo "last living    : $LAST_LIVING ($(git log -1 --format=%s $LAST_LIVING))"
  echo "=== method 1: git restore --source (working tree only) ==="
  run git restore --source="$LAST_LIVING" -- seed-library.md
  run git status --short
  run sha256sum seed-library.md
  cmp seed-library.md "$EXP/seed-library.md" && echo "MATCH: restored file byte-identical to its last living version"
  run rm seed-library.md
  echo "=== method 2: git checkout <sha> -- <path> (stages it) ==="
  run git checkout "$LAST_LIVING" -- seed-library.md
  run git status --short
  run git diff --cached --stat
  run sha256sum seed-library.md
  cmp seed-library.md "$EXP/seed-library.md" && echo "MATCH: same bytes by the second method too"
}

# ---------------------------------------------------------------- t09
build_bisect_repo() {
  new_repo bisect-repo
  commit -m "Start the planting journal"
  C1SHA=$(git rev-parse HEAD)
  local crops=(peppers courgettes herbs squash leeks kale carrots onions garlic potatoes sweetcorn sunflowers)
  local i crop bed
  for i in "${!crops[@]}"; do
    crop="${crops[$i]}"
    bed=$((i + 3))
    echo "Bed $bed: $crop" >> beds.txt
    if [ "$i" -eq 5 ]; then
      sed -i 's/print(len(rows))/print(len(rows) - 1)/' tally.py
      commit -m "Add the kale bed and tidy the tally"
      PLANTED=$(git rev-parse HEAD)
    else
      commit -m "Add the $crop bed"
    fi
  done
  cat > "$WORK/tally-check.sh" <<'EOF'
#!/bin/sh
# Passes when tally.py agrees with the number of beds in beds.txt.
[ "$(python3 tally.py)" = "$(grep -c . beds.txt)" ]
EOF
  chmod +x "$WORK/tally-check.sh"
}
t09() {
  build_bisect_repo
  run git log --oneline
  echo "--- the symptom: the tally disagrees with the beds list ---"
  run python3 tally.py
  run grep -c . beds.txt
  echo "planted first-bad commit (kept aside for the verdict check): $PLANTED"
  echo "=== manual bisect ==="
  run git bisect start
  run git bisect bad
  run git bisect good "$C1SHA"
  local rc out cmd verdict=""
  for _ in 1 2 3 4 5 6 7 8; do
    printf '$ ../tally-check.sh\n'
    ../tally-check.sh; rc=$?
    echo "[exit $rc]"
    if [ $rc -eq 0 ]; then cmd=good; else cmd=bad; fi
    out=$(git bisect $cmd 2>&1)
    printf '$ git bisect %s\n%s\n' "$cmd" "$out"
    case "$out" in
      *"is the first bad commit"*)
        verdict=$(printf '%s\n' "$out" | awk '/is the first bad commit/ {print $1}')
        break ;;
    esac
  done
  echo "bisect verdict : $verdict"
  echo "planted bad    : $PLANTED"
  if [ "$verdict" = "$PLANTED" ]; then echo "MATCH: bisect named exactly the planted commit"; else echo "MISMATCH!"; fi
  run git show --format=%h%x20%s --stat "$verdict"
  run git bisect reset
  run git status --short
}

# ---------------------------------------------------------------- t10
t10() {
  cd "$WORK/bisect-repo" || return 1
  echo "=== the same hunt, automated: git bisect run ==="
  run cat ../tally-check.sh
  run git bisect start
  run git bisect bad
  run git bisect good "$C1SHA"
  run git bisect run ../tally-check.sh
  echo "planted bad    : $PLANTED"
  run git bisect reset
  run git status --short
  run git log --oneline -3
}

# ---------------------------------------------------------------- t11
t11() {
  mkdir -p "$WORK/push-lab"
  cd "$WORK/push-lab" || return 1
  mkdir seed
  cd seed || return 1
  git init -q -b main
  base_files
  commit -m "Start the planting journal"
  write_rota
  commit -m "Add the watering rota"
  cp beds.txt "$EXP/beds-good.txt"
  cd "$WORK/push-lab" || return 1
  run git clone --bare -q seed remote.git
  run git clone remote.git work
  cd work || return 1
  echo "--- the mistake, pushed: the beds list is cut down to one bed ---"
  echo "Bed 1: tomatoes" > beds.txt
  commit -m "Clear the beds list for winter"
  run git push origin main
  run git --git-dir=../remote.git log --oneline main
  cd "$WORK/push-lab" || return 1
  run git clone remote.git teammate
  cd teammate || return 1
  echo "--- a teammate pulls the damage ---"
  run cat beds.txt
  echo "=== path A: revert — a new commit that undoes it, history kept ==="
  cd "$WORK/push-lab/work" || return 1
  stamp
  run git revert --no-edit HEAD
  run git push origin main
  run git --git-dir=../remote.git log --oneline main
  run sha256sum beds.txt
  cmp beds.txt "$EXP/beds-good.txt" && echo "MATCH: beds.txt back to the good bytes"
  cd "$WORK/push-lab/teammate" || return 1
  run git pull
  run cat beds.txt
  run git log --oneline
  echo "=== path B: rewrite — reset and force-push a shared branch ==="
  cd "$WORK/push-lab/work" || return 1
  run git switch -c rota-draft
  cat > rota.md <<'EOF'
# Watering Rota

- Monday: Tom
- Wednesday: Tom
- Friday: Tom
EOF
  commit -m "Rewrite the rota from memory"
  run git push -u origin rota-draft
  run git --git-dir=../remote.git log --oneline rota-draft
  cd "$WORK/push-lab/teammate" || return 1
  run git fetch origin
  run git switch rota-draft
  run git log --oneline -3
  cd "$WORK/push-lab/work" || return 1
  run git reset --hard HEAD~1
  run git push --force-with-lease origin rota-draft
  echo "--- the bad commit is gone from the remote branch ---"
  run git --git-dir=../remote.git log --oneline rota-draft
  echo "--- but the teammate's copy no longer agrees with the remote ---"
  cd "$WORK/push-lab/teammate" || return 1
  run git fetch origin
  run git status
  run git pull
  echo "--- the removed commit is still alive in the teammate's copy ---"
  run git log --oneline origin/rota-draft..rota-draft
  echo "--- and a plain push from the teammate quietly resurrects it ---"
  run git push origin rota-draft
  run git --git-dir=../remote.git log --oneline rota-draft
}

# ---------------------------------------------------------------- t12
t12() {
  cd "$WORK" || return 1
  run git clone -q garden limit-repo
  cd limit-repo || return 1
  run git log --oneline
  echo "=== limit 1: work that was never staged or committed ==="
  echo "An unsaved line about the scarecrow." >> planting-notes.md
  run grep -n scarecrow planting-notes.md
  run git restore planting-notes.md
  run grep -n scarecrow planting-notes.md
  run git status --short
  echo "=== a deleted branch, while the reflog still holds it ==="
  run git switch -c keepsake
  cat > keepsake.md <<'EOF'
# Keepsake Seeds

One envelope of bean seed from the first year, kept for luck.
EOF
  commit -m "List the keepsake seeds"
  KEEP=$(git rev-parse HEAD)
  echo "keepsake tip: $KEEP"
  run git switch main
  run git branch -D keepsake
  run git cat-file -t "$KEEP"
  echo "=== the point of no return — run in this throwaway clone only ==="
  run git reflog expire --expire=now --expire-unreachable=now --all
  run git gc --prune=now
  run git cat-file -t "$KEEP"
  run git fsck --unreachable
  echo "--- the clone's real history is untouched ---"
  run git log --oneline
  run git status --short
}

# ---------------------------------------------------------------- main
t01 > "$TRANS/01-versions-and-the-garden.txt" 2>&1
t02 > "$TRANS/02-deleted-branch.txt" 2>&1
t03 > "$TRANS/03-reset-three-ways.txt" 2>&1
t04 > "$TRANS/04-wrong-branch.txt" 2>&1
t05 > "$TRANS/05-merge-abort.txt" 2>&1
t06 > "$TRANS/06-rebase-abort-and-undo.txt" 2>&1
t07 > "$TRANS/07-dropped-stash.txt" 2>&1
t08 > "$TRANS/08-restore-a-deleted-file.txt" 2>&1
t09 > "$TRANS/09-bisect-manual.txt" 2>&1
t10 > "$TRANS/10-bisect-run.txt" 2>&1
t11 > "$TRANS/11-pushed-mistakes.txt" 2>&1
t12 > "$TRANS/12-the-edge-of-rescue.txt" 2>&1
echo "HARNESS DONE"
