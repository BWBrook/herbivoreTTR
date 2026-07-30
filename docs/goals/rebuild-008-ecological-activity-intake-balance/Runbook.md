# Rebuild Goal 008: Ecological Activity And Intake Balance Runbook

## Purpose

Execute the approved three-fixture evidence goal from a clean published Goal
007 baseline without changing package production code or broadening the
scientific model.

## Stop Rules

- Stop if the recorded formulation parent is not `fab7c0b`.
- After packet publication, stop if the clean synchronized execution baseline
  is not the newly published packet commit.
- Stop if packet control files change after their hashes are frozen.
- Stop before any path outside the nine-file implementation surface changes.
- Stop before changing `R/`, `man/`, NAMESPACE, metadata, dependencies,
  existing tests/experiments, or the variable dictionary.
- Stop if a result suggests a production defect or contradicts the approved
  scientific contract; diagnose and report rather than widening scope.
- Do not reset, clean, stash, force, amend, or delete retained review outputs.
- Perform at most one focused repair pass for a Critical or Important defect.
- Stop uncommitted after acceptance.

## 1. Packet Preflight

Require:

```zsh
FORMULATION_PARENT=fab7c0b9340ca4befa18fe0943dd86869c02cff8
test "$(git branch --show-current)" = main
test "$(git rev-parse HEAD)" = "$FORMULATION_PARENT"
test "$(git rev-parse origin/main)" = "$FORMULATION_PARENT"
test "$(git ls-remote origin refs/heads/main | awk '{print $1}')" = \
  "$FORMULATION_PARENT"
test -z "$(git diff --cached --name-only)"
```

Expected baseline:

```text
branch = main
HEAD = fab7c0b9340ca4befa18fe0943dd86869c02cff8
origin/main = fab7c0b9340ca4befa18fe0943dd86869c02cff8
live remote main = fab7c0b9340ca4befa18fe0943dd86869c02cff8
worktree = clean
index = empty
```

Review the packet scientifically and operationally. Freeze SHA-256 hashes for
`Goal.md`, `Plan.md`, and `Runbook.md`. Commit and push only the four packet
files. Record the resulting commit as the execution baseline, then require:

```zsh
EXECUTION_BASE=$(git rev-parse HEAD)
test "$EXECUTION_BASE" != "$FORMULATION_PARENT"
test "$(git branch --show-current)" = main
test -z "$(git status --porcelain=v1 --untracked-files=all)"
test "$(git rev-parse origin/main)" = "$EXECUTION_BASE"
test "$(git ls-remote origin refs/heads/main | awk '{print $1}')" = \
  "$EXECUTION_BASE"
test -z "$(git diff --cached --name-only)"
```

All implementation diffs and final scope checks are relative to
`EXECUTION_BASE`, not the formulation parent. Before any other implementation
edit, append this exact machine-readable line to `Log.md`:

```text
Execution baseline commit = <full EXECUTION_BASE hash>
```

## 2. Focused Scenario Evidence

Create:

```text
tests/testthat/test-ecological-activity-intake-balance.R
```

Construct all three fixtures through exported functions. Use one local fixture
builder and small accounting/tolerance helpers. Do not copy strict constructor,
schema, mutation, or failure-mode tests.

Run:

```r
testthat::test_local(
  ".",
  filter = "^ecological-activity-intake-balance"
)
```

All tests should pass against accepted production code. A failure is a
diagnostic result, not permission to edit production source.

## 3. No-Write Experiment

Create:

```text
experiments/rebuild-008-ecological-activity-intake-balance.R
```

The script accepts no arguments, uses exported functions only, writes no
files, and asserts:

- exact schedules and daily totals;
- predicted day-7 convergence;
- exact baseline/unbalanced gut invariance;
- balanced `4/3` gut and assimilation scaling;
- measured day repetition and state carry-over;
- reconstructed accounting and neutrality;
- exact activity-only and added-input contrasts; and
- finite, non-negative stock paths.

Print whole-kilojoule human summaries and retain full precision internally.

Run it from the source-loaded package while requiring unchanged Git status:

```zsh
before=$(git status --porcelain=v1)
Rscript --vanilla -e \
  'pkgload::load_all(".", export_all = FALSE, quiet = TRUE)
   source(
     "experiments/rebuild-008-ecological-activity-intake-balance.R",
     local = new.env(parent = globalenv())
   )'
after=$(git status --porcelain=v1)
test "$before" = "$after"
```

## 4. Review Pack

Create:

```text
experiments/rebuild-008-review-pack.R
```

The script accepts exactly one output-directory argument and writes exactly:

```text
figure-1-ecological-activity-intake-balance.png
table-1-prescribed-schedules.csv
table-2-convergence.csv
table-3-daily-summary.csv
table-4-hourly-ledgers.csv
```

Use one compact table validator before CSV write and after read-back. Require
the exact schemas, rows, ordering, finite values, schedule totals,
convergence, repetition, accounting, scaling, neutrality, paired contrasts,
and body-boundary landmarks declared in `Goal.md`.

Require guarded staged publication, regular non-symbolic files, rejection of
undeclared destination entries, and no analytical failure before replacement.

Inspect the native figure for:

- continuous `0-48 h` time;
- rest shading at `[8,16)` and `[32,40)`;
- a marked 24-hour boundary;
- correct scenario identities, units, and prescribed forcing;
- exact unbalanced decline and daily-neutral baseline/balanced closes;
- legibility, no clipping, and no empirical or behavioral wording.

## 5. Documentation

Create Decision 0008 and update only the five declared project documents plus
the mutable Goal 008 Log. Confirm that no new variable or schema is claimed.

## 6. Functional Validation

Parse the new test and both experiment scripts. Run structured counts:

```r
run_counts <- function(label, filter = NULL) {
  result <- if (is.null(filter)) {
    testthat::test_local(".", reporter = "silent")
  } else {
    testthat::test_local(".", filter = filter, reporter = "silent")
  }
  data <- as.data.frame(result)
  counts <- c(
    PASS = sum(data$passed),
    FAIL = sum(data$failed) + sum(data$error),
    WARN = sum(data$warning),
    SKIP = sum(data$skipped)
  )
  cat(label, paste(names(counts), counts, collapse = " "), "\n")
  stopifnot(
    counts[["PASS"]] > 0,
    all(counts[c("FAIL", "WARN", "SKIP")] == 0)
  )
  invisible(counts)
}

focused <- run_counts(
  "ecological-activity-intake-balance",
  "^ecological-activity-intake-balance"
)
full <- run_counts("full")
stopifnot(full[["PASS"]] > 1037)
```

Then require:

```zsh
Rscript --vanilla -e \
  'status <- renv::status(); stopifnot(isTRUE(status$synchronized))'
git diff --check
test -z "$(git diff --cached --name-only)"
```

## 7. External Package Validation

Use one guarded temporary directory outside the repository:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
TMP=$(mktemp -d /tmp/rebuild008-check.XXXXXX)
cleanup() {
  local cleanup_status=0
  cd /
  case "$TMP" in
    /tmp/rebuild008-check.*)
      Rscript --vanilla -e \
        'status <- unlink(commandArgs(TRUE), recursive = TRUE)
         stopifnot(identical(status, 0L))' "$TMP" ||
        cleanup_status=$?
      test ! -e "$TMP" || cleanup_status=1
      ;;
    *)
      cleanup_status=1
      ;;
  esac
  return "$cleanup_status"
}
trap 'run_status=$?; trap - EXIT
      cleanup_status=0
      cleanup || cleanup_status=$?
      if (( run_status == 0 && cleanup_status != 0 )); then
        run_status=$cleanup_status
      fi
      exit "$run_status"' EXIT

cd "$TMP"
R CMD build "$REPO"
TARBALL=$(find "$TMP" -maxdepth 1 -type f \
  -name 'herbivoreTTR_*.tar.gz' -print -quit)
test -n "$TARBALL"
mkdir "$TMP/library"
R CMD INSTALL --library="$TMP/library" "$TARBALL"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-008-ecological-activity-intake-balance.R"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-008-review-pack.R" \
  "$REPO/outputs/rebuild-008-ecological-activity-intake-balance"
R CMD check --no-manual "$TARBALL"
grep -Fx 'Status: OK' "$TMP/herbivoreTTR.Rcheck/00check.log"
cd "$REPO"
```

Do not rerun this ladder unless a material repair invalidates its evidence.

## 8. Scope And Final Review

First reconstruct and check the frozen packet hashes recorded in `Log.md`:

```zsh
PACKET=docs/goals/rebuild-008-ecological-activity-intake-balance
FORMULATION_PARENT=fab7c0b9340ca4befa18fe0943dd86869c02cff8
EXECUTION_BASE=$(awk \
  '$1 == "Execution" && $2 == "baseline" && $3 == "commit" {print $5}' \
  "$PACKET/Log.md")
goal_hash=$(awk '$1 == "Goal.md" && $2 == "SHA-256" {print $4}' \
  "$PACKET/Log.md")
plan_hash=$(awk '$1 == "Plan.md" && $2 == "SHA-256" {print $4}' \
  "$PACKET/Log.md")
runbook_hash=$(awk '$1 == "Runbook.md" && $2 == "SHA-256" {print $4}' \
  "$PACKET/Log.md")
test -n "$EXECUTION_BASE"
test "$(git rev-parse "$EXECUTION_BASE")" = "$EXECUTION_BASE"
test "$(git rev-parse "$EXECUTION_BASE^")" = "$FORMULATION_PARENT"
test "$(git rev-parse origin/main)" = "$EXECUTION_BASE"
test -n "$goal_hash"
test -n "$plan_hash"
test -n "$runbook_hash"
test "$(shasum -a 256 "$PACKET/Goal.md" | awk '{print $1}')" = "$goal_hash"
test "$(shasum -a 256 "$PACKET/Plan.md" | awk '{print $1}')" = "$plan_hash"
test "$(shasum -a 256 "$PACKET/Runbook.md" | awk '{print $1}')" = \
  "$runbook_hash"
```

Require the exact authorized implementation surface and an empty index:

```zsh
EXPECTED_PATHS=$(cat <<'EOF'
README.md
docs/decisions/0008-ecological-activity-intake-balance.md
docs/goals/rebuild-008-ecological-activity-intake-balance/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
experiments/rebuild-008-ecological-activity-intake-balance.R
experiments/rebuild-008-review-pack.R
tests/testthat/test-ecological-activity-intake-balance.R
EOF
)
ACTUAL_PATHS=$(git status --porcelain=v1 --untracked-files=all |
  awk '{print $2}' | LC_ALL=C sort)
test "$ACTUAL_PATHS" = "$(printf '%s\n' "$EXPECTED_PATHS" | LC_ALL=C sort)"
test -z "$(git diff --cached --name-only)"
test -z "$(git diff --name-only "$EXECUTION_BASE" -- R/ man/ NAMESPACE \
  DESCRIPTION renv.lock .Rbuildignore .gitignore \
  docs/variable-dictionary.md)"
```

Check tracked and untracked text for whitespace defects:

```zsh
git diff --check "$EXECUTION_BASE"
while IFS= read -r file; do
  findings=$(git diff --no-index --check /dev/null "$file" 2>&1 || true)
  test -z "$findings"
done < <(git ls-files --others --exclude-standard)
```

Then require:

- exact five-file ignored output;
- no package tarball, check directory, or guarded temporary residue;
- source, installed, test, package, and artefact receipts; and
- one independent final scientific/evidence review.

Resolve only Critical or Important findings. Record acceptance and residual
limits in `Log.md`.

## 9. Publication Boundary

Stop with Goal 008 implementation uncommitted. Retain the ignored review pack
for Barry. Stage, commit, and push only after separate publication authority.
