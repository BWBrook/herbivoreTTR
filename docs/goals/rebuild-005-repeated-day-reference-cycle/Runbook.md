# Rebuild Goal 005 Runbook

## Purpose

This is guarded execution guidance for Goal 005 after explicit authorization.
It does not itself authorize implementation, staging, committing, or pushing.

## Stop Rules

- Begin only from a clean, published Goal 005 packet on `main`.
- Stop on an unexpected path, changed upstream contract, packet-hash mismatch,
  validation failure, or scientific ambiguity.
- Do not reset, clean, stash, force, amend, or modify Goal 001-004 source or
  tests.
- Do not add physiology, variable forcing, a generalized multi-day engine, or
  a new dependency.
- Treat tool wait timeouts as polling intervals, not worker deadlines.
- Allow one focused review-and-repair pass for material findings only.
- Stop rather than repeat unchanged checks or polish low-value minutiae.

## 1. Authorization And Preflight

Record the approved packet hashes and require a clean synchronized baseline:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR

: "${AUTHORIZED_GOAL_SHA256:?Set the approved Goal.md SHA-256}"
: "${AUTHORIZED_PLAN_SHA256:?Set the approved Plan.md SHA-256}"
: "${AUTHORIZED_RUNBOOK_SHA256:?Set the approved Runbook.md SHA-256}"

test -d "$REPO/.git"
test "$(git -C "$REPO" branch --show-current)" = main
test -z "$(git -C "$REPO" status --short)"
test "$(git -C "$REPO" rev-parse HEAD)" = \
  "$(git -C "$REPO" rev-parse origin/main)"
test "$(git -C "$REPO" rev-parse HEAD)" = \
  "$(git -C "$REPO" ls-remote origin refs/heads/main | awk '{print $1}')"
test "$(git -C "$REPO" remote get-url origin)" = \
  git@github.com:BWBrook/herbivoreTTR.git

printf '%s  %s\n' \
  "$AUTHORIZED_GOAL_SHA256" \
  "$REPO/docs/goals/rebuild-005-repeated-day-reference-cycle/Goal.md" \
  "$AUTHORIZED_PLAN_SHA256" \
  "$REPO/docs/goals/rebuild-005-repeated-day-reference-cycle/Plan.md" \
  "$AUTHORIZED_RUNBOOK_SHA256" \
  "$REPO/docs/goals/rebuild-005-repeated-day-reference-cycle/Runbook.md" \
  | shasum -a 256 -c -

BASE=$(git -C "$REPO" rev-parse HEAD)
printf 'Goal 005 execution baseline: %s\n' "$BASE"
```

Record `BASE` and the preflight result in `Log.md` before implementation.

## 2. Test-First Reference-Cycle Contract

Create and parse:

```text
tests/testthat/test-gut-body-energy-reference-cycle.R
```

Run the focused context:

```zsh
cd /Users/bwbrook/git/herbivoreTTR
Rscript --vanilla -e \
  'parse(file = "tests/testthat/test-gut-body-energy-reference-cycle.R")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "^gut-body-energy-reference-cycle$")'
```

Accept the red phase only when failures arise from the absent declared function
or its unimplemented contract. Stop on parse, load, dependency, warning, skip,
or unrelated regression failures.

## 3. Implement The Temporal Orchestrator

Add:

```text
R/gut-body-energy-reference-cycle.R
```

Implement the contract in `Goal.md` using the existing gut transition for
burn-in and the existing coupled daily runner for measurement. Keep private
helpers local to the new source file. Do not duplicate or alter the established
transition arithmetic.

Make the focused context green before adding documentation or review outputs.

## 4. Fixtures, Experiment, And Documentation

Add exact tests for zero, constant, and concentrated late feeding. Require:

- the declared burn-in and reset semantics;
- exact state carry-over;
- reduction to direct one-day runner calls after canonical row-name reset;
- separate gut-stability and body-energy diagnostics;
- timing-equivalent daily totals; and
- distinct within-day trajectories.

Use the exact cycle, gut-ledger, assimilation-total, body-ledger, and
body-neutrality tolerances declared in `Goal.md`. Require finite realized
convergence arithmetic and verify that the declared body reserve keeps all
measured fixture paths above the existing boundary.

Add the no-write experiment and base-R review-pack script. Update only the
declared documentation surface. Generate roxygen files after the interface is
stable:

```zsh
Rscript --vanilla -e \
  'stopifnot(requireNamespace("roxygen2", quietly = TRUE)); roxygen2::roxygenise()'
```

Stop if roxygen modifies an undeclared path or `renv.lock`.

## 5. Functional Validation

Run structured focused and full counts:

```zsh
Rscript --vanilla - <<'RS'
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
  "reference-cycle",
  "^gut-body-energy-reference-cycle$"
)
full <- run_counts("full")
stopifnot(full[["PASS"]] > 626)
RS
```

Then require:

```zsh
Rscript --vanilla -e \
  'status <- renv::status(); stopifnot(isTRUE(status$synchronized))'
git diff --check
test "$(git diff -- renv.lock)" = ''
```

Verify that no existing file under these paths changed:

```text
R/body-energy-*.R
R/gut-energy-*.R
R/gut-body-energy-run.R
R/food-energy-*.R
tests/testthat/test-body-energy-*.R
tests/testthat/test-gut-energy-*.R
tests/testthat/test-gut-body-energy-scenarios.R
tests/testthat/test-food-energy-*.R
```

Run the no-write experiment from source and later from the temporary installed
package. Require no repository write from either run.

## 6. External Package Validation

Use a guarded temporary directory outside the repository:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
TMP=$(mktemp -d /tmp/rebuild005-check.XXXXXX)
cleanup() {
  local cleanup_status=0
  case "$TMP" in
    /tmp/rebuild005-check.*)
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
  "$REPO/experiments/rebuild-005-repeated-day-reference-cycle.R"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-005-review-pack.R" \
  "$REPO/outputs/rebuild-005-repeated-day-reference-cycle"
R CMD check --no-manual "$TARBALL"
grep -Fx 'Status: OK' "$TMP/herbivoreTTR.Rcheck/00check.log"
cd "$REPO"
```

Stop on any package warning, note, error, failed install, or retained temporary
directory. Do not run duplicate external checks unless a material repair
invalidates the first result.

## 7. Review Pack

Use the pack generated from the temporary installed package in the preceding
block. Require exactly the five files declared in `Goal.md`. Read all tables
back into R and reproduce the fixture checks. Inspect both figures for nonblank
rendering, legible labels and units, correct scenario identity, no clipping or
overlap, and faithful correspondence with the tables.

Confirm the output directory is ignored and no generated file is staged:

```zsh
git check-ignore \
  outputs/rebuild-005-repeated-day-reference-cycle
test -z "$(git diff --cached --name-only)"
```

Retain the ignored review pack for Barry's discussion. Do not delete or commit
it without separate authority.

## 8. Scope And Final Review

Require all changed tracked and untracked paths to fall within the planned
surface in `Goal.md`. Inspect the complete diff and every new file. Record any
non-material deviation explicitly; stop for approval on a material expansion.

Require:

- unchanged approved Goal, Plan, and Runbook hashes;
- an empty Git index;
- clean tracked and untracked whitespace;
- unchanged Goal 001-004 source and tests;
- unchanged `renv.lock`;
- no repository tarball or check directory;
- successful focused, full, experiment, external, and review-pack checks; and
- one independent final scientific and code review.

Resolve only material findings, rerun affected checks, and perform no more than
one focused repair pass. Record the evidence and residual limitations in
`Log.md`.

## 9. Commit And Push Boundary

Goal 005 execution does not authorize staging, committing, or pushing the
implementation. Present the complete uncommitted closeout and review pack to
Barry.

If Barry later grants publication authority, stage exact reviewed paths only.
Recheck local and remote state immediately before any Git write. Never amend,
force push, tag, or publish generated review outputs.
