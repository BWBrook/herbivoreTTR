# Rebuild Goal 007: Routine-Activity Expenditure Runbook

## Purpose

Guard Goal 007 packet publication, implementation, validation, review, and
handoff. This runbook does not authorize implementation publication.

## Stop Rules

- Start implementation only from a clean, synchronized, published packet on
  `main`.
- Stop on a packet-hash mismatch, unexpected dirty path, changed protected
  contract, scientific ambiguity, or failed accounting assertion.
- Do not reset, clean, stash, force, amend, or delete retained review outputs.
- Do not add an activity default, wrapper, compatibility layer, ecological
  schedule, or later mechanism.
- Treat native-agent waits as polling intervals, not deadlines.
- Perform at most one focused repair pass for material findings.
- Stop when additional work is only stylistic or repeats existing evidence.

## 1. Packet Preflight

Require:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR

test "$(git -C "$REPO" branch --show-current)" = main
test -z "$(git -C "$REPO" status --short)"
test "$(git -C "$REPO" rev-parse HEAD)" = \
  "$(git -C "$REPO" rev-parse origin/main)"
test "$(git -C "$REPO" rev-parse HEAD)" = \
  "$(git -C "$REPO" ls-remote origin refs/heads/main | awk '{print $1}')"
test "$(git -C "$REPO" remote get-url origin)" = \
  git@github.com:BWBrook/herbivoreTTR.git
```

Record the Goal 007 formulation baseline and packet reviews in `Log.md`.
Freeze SHA-256 hashes for Goal, Plan, and Runbook. Commit and push exactly the
four packet files. Recheck a clean synchronized state before implementation.

## 2. Test-First Activity Record

Create the focused record test before production implementation. Require the
new exported constructor, exact two-column schema, double storage, integer
clock, strict malformed-input rejection, and no mutation.

Run the focused record context and require the initial missing-interface
failure. Implement only the record and validator needed to pass it.

## 3. Test-First Body Arithmetic

Extend body transition and daily-runner tests before implementation.

Require:

```text
step signature = state, parameters, input_row, activity_row
day-runner signature =
  initial_state, parameters, schedule, routine_activity_schedule
```

Protect:

- exact row-hour alignment;
- zero activity preserving existing numerical results;
- `50 kJ h^-1` in hours 8:11 producing four exact `-50 kJ` transitions;
- exact `200 kJ` daily activity and body loss;
- expanded schemas and summaries;
- activity-aware residual and tolerance reconstruction;
- purity and strict negative-reserve failure.

Implement only after the focused tests fail for the expected missing behavior.

## 4. Coupled And Reference Integration

Extend coupled and reference tests before production changes. Require the new
explicit argument and expanded ledgers.

Keep gut burn-in unchanged. Apply activity only in measured body transitions.
Protect exact zero/pulse equality for:

```text
gut convergence
gut boundary stocks
prescribed ingestion
assimilation
gut residuals
```

Protect pulse-control body differences of:

```text
day-1 close = -200 kJ
day-2 close = -400 kJ
each daily change difference = -200 kJ
```

## 5. Explicit Caller Migration

Update every declared Goal 002-006 caller with an explicit zero schedule.
Parse all eight accepted experiment/review scripts after migration.

Search for every call:

```zsh
rg -n \
  'step_body_energy\(|run_body_energy_day\(|run_gut_body_energy_day\(|run_gut_body_energy_reference_cycle\(' \
  R tests experiments
```

Inspect each result. No call may rely on a missing activity argument.

## 6. Roxygen Boundary

Run:

```zsh
Rscript --vanilla -e 'roxygen2::roxygenise(".")'
```

Require changed generated files to equal:

```text
NAMESPACE
man/new_routine_activity_expenditure_schedule.Rd
man/step_body_energy.Rd
man/run_body_energy_day.Rd
man/run_gut_body_energy_day.Rd
man/run_gut_body_energy_reference_cycle.Rd
man/herbivoreTTR-package.Rd
```

Stop on any DESCRIPTION, unrelated manual, or dependency change.

## 7. Functional Validation

Parse all changed R files and every experiment.

Run structured test counts:

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

focused <- run_counts("routine-activity", "^routine-activity")
full <- run_counts("full")
stopifnot(full[["PASS"]] > 949)
```

Then require:

```zsh
Rscript --vanilla -e \
  'status <- renv::status(); stopifnot(isTRUE(status$synchronized))'
git diff --check
test -z "$(git diff --cached --name-only)"
```

Run the Goal 007 experiment from source and require repository status to remain
unchanged.

## 8. Review Pack

The review script accepts exactly one non-empty output directory and stages:

```text
figure-1-routine-activity-accounting.png
table-1-routine-activity-schedules.csv
table-2-convergence.csv
table-3-daily-summary.csv
table-4-hourly-ledgers.csv
```

Before publication, require:

- exact staged file set;
- regular non-symbolic files only;
- the exact CSV columns, row counts, scenario order, day order, and hour order
  declared in `Goal.md`;
- full CSV read-back reconstruction of zero and pulse outcomes;
- exact gut invariance;
- exact activity totals and body contrasts; and
- no analytical failure.

Inspect the native figure for a visible zero gut-difference trace, correct pulse
windows, continuous 0-48 hour time, correct units, legibility, and no clipping.

## 9. External Package Validation

Use a guarded temporary directory outside the repository:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
TMP=$(mktemp -d /tmp/rebuild007-check.XXXXXX)
cleanup() {
  local cleanup_status=0
  case "$TMP" in
    /tmp/rebuild007-check.*)
      Rscript --vanilla -e \
        'status <- unlink(commandArgs(TRUE), recursive = TRUE)
         stopifnot(identical(status, 0L))' "$TMP" ||
        cleanup_status=$?
      test ! -e "$TMP" || cleanup_status=1
      ;;
    *)
      printf '%s\n' 'Unsafe temporary path; stop.' >&2
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
  "$REPO/experiments/rebuild-007-routine-activity-expenditure.R"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-007-review-pack.R" \
  "$REPO/outputs/rebuild-007-routine-activity-expenditure"
R CMD check --no-manual "$TARBALL"
grep -Fx 'Status: OK' "$TMP/herbivoreTTR.Rcheck/00check.log"
cd "$REPO"
```

Do not rerun this ladder unless a material repair invalidates its evidence.

## 10. Scope And Final Review

Require the complete status path set to equal the exact implementation surface
in `Goal.md`.

Require:

- frozen Goal, Plan, and Runbook hashes;
- empty Git index;
- unchanged protected paths;
- exact five-file ignored output;
- no repository tarball or check directory;
- no `/tmp/rebuild007-check.*` residue;
- clean whitespace;
- source, installed, test, package, and artefact receipts; and
- one independent final scientific/evidence review.

Resolve only Critical or Important findings. Record acceptance and residual
limits in `Log.md`.

## 11. Publication Boundary

Stop with Goal 007 implementation uncommitted. Retain the ignored review pack
for Barry. Stage, commit, and push only after separate publication authority.
