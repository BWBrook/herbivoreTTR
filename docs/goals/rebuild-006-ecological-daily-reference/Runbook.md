# Rebuild Goal 006 Runbook

## Purpose

This is guarded execution guidance for Goal 006 after explicit authorization.
It does not itself authorize implementation, staging, committing, or pushing.

## Stop Rules

- Begin only from a clean, published Goal 006 packet on `main`.
- Stop on an unexpected path, changed upstream contract, packet-hash mismatch,
  validation failure, or scientific ambiguity.
- Do not reset, clean, stash, force, amend, or modify Goal 001-005 source or
  tests.
- Do not add production code, a new API, activity or feeding behavior, intake
  limits, physiology, or a dependency.
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
  "$REPO/docs/goals/rebuild-006-ecological-daily-reference/Goal.md" \
  "$AUTHORIZED_PLAN_SHA256" \
  "$REPO/docs/goals/rebuild-006-ecological-daily-reference/Plan.md" \
  "$AUTHORIZED_RUNBOOK_SHA256" \
  "$REPO/docs/goals/rebuild-006-ecological-daily-reference/Runbook.md" \
  | shasum -a 256 -c -

BASE=$(git -C "$REPO" rev-parse HEAD)
printf 'Goal 006 execution baseline: %s\n' "$BASE"
```

Record `BASE` and the preflight result in `Log.md` before implementation.

## 2. Focused Reference Regression

Create:

```text
tests/testthat/test-ecological-daily-reference.R
```

The test must construct:

```r
mathematical_dm <- rep(0.010, 24L)
ecological_dm <- c(rep(0.015, 8L), rep(0, 8L), rep(0.015, 8L))
```

Derive both energy schedules through the exported Goal 004 converter. Do not
construct the 100 and 150 kJ h^-1 schedules as substitutes for testing that
conversion. Compare each dry-matter daily total with 0.24 kg DM using an
absolute tolerance of `100 * .Machine$double.eps` kg DM; require each derived
daily energy total to equal 2400 kJ exactly.

Parse and run the focused context:

```zsh
cd /Users/bwbrook/git/herbivoreTTR
Rscript --vanilla -e \
  'parse(file = "tests/testthat/test-ecological-daily-reference.R")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "^ecological-daily-reference$")'
```

All required interfaces already exist. There is no legitimate missing-API red
phase. The first complete test file should pass against the accepted
production model. Stop and diagnose any failure before changing another path.

The test should add only fixture-level coverage. Do not repeat strict
validation, purity, overflow, failure-mode, or return-schema tests already
present in Goal 004-005.

For each measured day, require between-reference daily assimilation, observed
gut change, and observed body change to agree within the sums of the
corresponding scenario-specific tolerances in `Goal.md`.

Reconstruct both 25-boundary gut and body trajectories. Require the
between-reference gut, hourly assimilation, and body maxima to exceed the
declared summed tolerances and fall within the three whole-kJ magnitude bands.
Require the ecological gut maximum and minimum at 08:00 and 16:00, gut-release
maximum and minimum in hours 8 and 16, and body maximum and minimum at 10:00
and 20:00.

## 3. No-Write Experiment

Create and parse:

```text
experiments/rebuild-006-ecological-daily-reference.R
```

Use exported functions only. Assert the exact schedules, conversion, totals,
convergence, two-day repetition, carry-over, feasible body paths, neutrality,
daily equivalence, and distinct hourly trajectories.

The experiment must write no file. Capture repository status before and after
its source run and require no change.

## 4. Review Pack

Create and parse:

```text
experiments/rebuild-006-review-pack.R
```

The script accepts exactly one non-empty output-directory argument and writes
only:

```text
figure-1-measured-reference-comparison.png
table-1-input-schedules.csv
table-2-convergence.csv
table-3-daily-summary.csv
table-4-hourly-ledgers.csv
```

Generate every file in a temporary staging directory. Before publishing:

- assert all scientific outcomes in memory;
- read every staged CSV back and reproduce the declared checks;
- require exactly the declared staged file set;
- reject staged directories or symbolic links; and
- validate the destination under the rules in `Goal.md`.

Do not copy the entire Goal 005 review script or refactor accepted Goal 005
evidence code. Implement only the guards and displays needed by this goal.

## 5. Documentation

Add:

```text
docs/decisions/0006-ecological-daily-reference.md
```

Modify only:

```text
README.md
docs/goals/rebuild-006-ecological-daily-reference/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
```

No roxygen run is required. Stop if any file under `R/` or `man/`, or any of
these paths, changes:

```text
DESCRIPTION
NAMESPACE
renv.lock
.Rbuildignore
.gitignore
docs/variable-dictionary.md
```

## 6. Functional Validation

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
  "ecological-reference",
  "^ecological-daily-reference$"
)
full <- run_counts("full")
stopifnot(full[["PASS"]] > 812)
RS
```

Then require:

```zsh
Rscript --vanilla -e \
  'status <- renv::status(); stopifnot(isTRUE(status$synchronized))'
git diff --check
test "$(git diff -- renv.lock)" = ''
```

Require all production and previously accepted tests to remain unchanged:

```zsh
test -z "$(git diff --name-only -- \
  R DESCRIPTION NAMESPACE man renv.lock \
  tests/testthat/test-body-energy-records.R \
  tests/testthat/test-body-energy-scenarios.R \
  tests/testthat/test-body-energy-transition.R \
  tests/testthat/test-food-energy-conversion.R \
  tests/testthat/test-food-energy-records.R \
  tests/testthat/test-gut-body-energy-reference-cycle.R \
  tests/testthat/test-gut-body-energy-scenarios.R \
  tests/testthat/test-gut-energy-records.R \
  tests/testthat/test-gut-energy-transition.R \
  tests/testthat/test-scaffold.R)"
```

Run the no-write experiment from source and later from the temporary installed
package.

## 7. External Package Validation

Use a guarded temporary directory outside the repository:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
TMP=$(mktemp -d /tmp/rebuild006-check.XXXXXX)
cleanup() {
  local cleanup_status=0
  case "$TMP" in
    /tmp/rebuild006-check.*)
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
  "$REPO/experiments/rebuild-006-ecological-daily-reference.R"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-006-review-pack.R" \
  "$REPO/outputs/rebuild-006-ecological-daily-reference"
R CMD check --no-manual "$TARBALL"
grep -Fx 'Status: OK' "$TMP/herbivoreTTR.Rcheck/00check.log"
cd "$REPO"
```

Stop on any package warning, note, error, failed install, or retained temporary
directory. Do not duplicate the external ladder unless a material repair
invalidates its evidence.

## 8. Review Pack Inspection

Require exactly the five files declared in `Goal.md`. Read all tables back into
R and reproduce:

- exact interval and daily input checks;
- convergence and two-day repetition;
- body-path feasibility;
- daily neutrality;
- comparator equivalence; and
- trajectory-distinctness inequalities;
- the six phase landmarks; and
- the three trajectory-contrast magnitude bands.

Inspect the figure at native dimensions for:

- nonblank rendering;
- legible labels and units;
- correct scenario identity;
- correct rest-closed shading;
- the 24-hour day boundary;
- continuous 0-48 hour time;
- no clipping or overlap; and
- faithful correspondence with the tables.

Confirm the output directory is ignored and no generated file is staged:

```zsh
git check-ignore \
  outputs/rebuild-006-ecological-daily-reference
test -z "$(git diff --cached --name-only)"
```

Retain the ignored review pack for Barry's discussion. Do not delete or commit
it without separate authority.

## 9. Scope And Final Review

Require the changed path set to equal exactly the planned surface in
`Goal.md`. Inspect every new file and the complete diff.

Require:

- unchanged approved Goal, Plan, and Runbook hashes;
- an empty Git index;
- clean tracked and untracked whitespace;
- unchanged production, package metadata, manuals, dependencies, dictionary,
  and Goal 001-005 tests;
- no repository tarball or check directory;
- no retained guarded temporary directory;
- successful focused, full, experiment, external, and review-pack checks; and
- one independent final scientific and evidence review.

Resolve only material findings, rerun affected checks, and perform no more than
one focused repair pass. Record checkpoints, evidence, and residual
limitations in `Log.md`.

## 10. Commit And Push Boundary

Goal 006 execution does not authorize staging, committing, or pushing the
implementation. Present the complete uncommitted closeout and review pack to
Barry.

If Barry later grants publication authority, stage exact reviewed paths only.
Recheck local and remote state immediately before any Git write. Never amend,
force push, tag, or publish generated review outputs.
