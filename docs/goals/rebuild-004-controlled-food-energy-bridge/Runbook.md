# Rebuild Goal 004 Runbook

## Purpose

This is guarded execution guidance for Goal 004 after explicit authorization.
It does not itself authorize implementation, staging, committing, or pushing.

## Stop Rules

- Stop on an unexpected dirty path, changed upstream, control-document hash
  mismatch, missing tool, failed command, or changed scientific requirement.
- Do not reset, clean, stash, force, amend, or modify Goal 003 history.
- Do not add a new runner, state, dependency, food type, digestive process,
  capacity, feedback, or generated figure pack.
- Do not inspect or copy from the legacy repository.
- Treat command timeouts as observation intervals, not process deadlines.
- After core checks, allow one focused review-and-repair pass. Do not repeat
  unchanged checks or polish non-material minutiae.

## 1. Authorization And Preflight

Execution requires externally approved SHA-256 values for `Goal.md`, `Plan.md`,
and `Runbook.md`.

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
BASE=e2622ca739d89124e8cb8361fb40363363686d49

: "${AUTHORIZED_GOAL_SHA256:?Use the approved Goal.md SHA-256}"
: "${AUTHORIZED_PLAN_SHA256:?Use the approved Plan.md SHA-256}"
: "${AUTHORIZED_RUNBOOK_SHA256:?Use the approved Runbook.md SHA-256}"

test -d "$REPO/.git"
test "$(git -C "$REPO" branch --show-current)" = main
test "$(git -C "$REPO" rev-parse HEAD)" = "$BASE"
test "$(git -C "$REPO" rev-parse origin/main)" = "$BASE"
test "$(git -C "$REPO" ls-remote origin refs/heads/main | awk '{print $1}')" = \
  "$BASE"
test "$(git -C "$REPO" remote get-url origin)" = \
  git@github.com:BWBrook/herbivoreTTR.git
test "$(git -C "$REPO" remote get-url --push origin)" = \
  git@github.com:BWBrook/herbivoreTTR.git
test ! -e "$REPO/outputs"

printf '%s  %s\n' \
  "$AUTHORIZED_GOAL_SHA256" \
  "$REPO/docs/goals/rebuild-004-controlled-food-energy-bridge/Goal.md" \
  "$AUTHORIZED_PLAN_SHA256" \
  "$REPO/docs/goals/rebuild-004-controlled-food-energy-bridge/Plan.md" \
  "$AUTHORIZED_RUNBOOK_SHA256" \
  "$REPO/docs/goals/rebuild-004-controlled-food-energy-bridge/Runbook.md" \
  | shasum -a 256 -c -

diff -u \
  <(printf '%s\n' \
    '?? docs/goals/rebuild-004-controlled-food-energy-bridge/Goal.md' \
    '?? docs/goals/rebuild-004-controlled-food-energy-bridge/Log.md' \
    '?? docs/goals/rebuild-004-controlled-food-energy-bridge/Plan.md' \
    '?? docs/goals/rebuild-004-controlled-food-energy-bridge/Runbook.md' \
    | LC_ALL=C sort) \
  <(git -C "$REPO" status --short --untracked-files=all | LC_ALL=C sort)
```

If any observation differs, stop without editing.

## 2. Test-First Food Records

Create and parse the record tests before production source:

```zsh
cd /Users/bwbrook/git/herbivoreTTR
Rscript --vanilla -e \
  'parse(file = "tests/testthat/test-food-energy-records.R")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "^food-energy-records$")'
```

Inspect structured failures. Accept the red phase only when every failure is
the expected absent constructor or unmet declared contract, with no parse
error, package-load failure, missing dependency, warning, or skip.

Implement:

```text
new_food_energy_parameters()
new_dry_matter_intake_schedule()
```

Make the focused record context green before proceeding.

## 3. Test-First Conversion

Create and parse the conversion tests, then reproduce the expected red phase:

```zsh
Rscript --vanilla -e \
  'parse(file = "tests/testthat/test-food-energy-conversion.R")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "^food-energy-conversion$")'
```

Implement:

```text
derive_ingested_available_energy_schedule(parameters, schedule)
```

Validate the exact parameter record and dry-matter schedule. Multiply
elementwise, reject every non-finite result, and pass the converted rate vector
through `new_ingested_available_energy_schedule()`. Do not add attributes,
columns, state advancement, or a runner call.

Make the focused conversion context green.

## 4. Fixtures, Experiment, And Documentation

Add exact tests for zero intake, the constant bridge, the pulse bridge, and
factorization equivalence. Require converted and manually created Goal 003
schedules and downstream results to be identical.

Add the thin experiment after core functions are green. It must assert every
fixture in memory, write nothing, and display energy stocks and amounts as
whole kJ while retaining meaningful rate precision.

Generate documentation only after interfaces stabilize:

```zsh
Rscript --vanilla -e \
  'stopifnot(requireNamespace("roxygen2", quietly = TRUE)); roxygen2::roxygenise()'
```

Inspect `DESCRIPTION`, `NAMESPACE`, and every changed `man/` file. Stop if
roxygen changes an undeclared path or modifies `renv.lock`.

## 5. Functional Validation

Run focused and full tests with structured counts:

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

records <- run_counts("records", "^food-energy-records$")
conversion <- run_counts("conversion", "^food-energy-conversion$")
full <- run_counts("full")
stopifnot(full[["PASS"]] > 499)
RS
```

Verify dependency and repository integrity:

```zsh
Rscript --vanilla -e \
  'status <- renv::status(); stopifnot(isTRUE(status$synchronized))'
git diff --check
test ! -e outputs
test "$(git diff -- renv.lock)" = ''
test "$(git diff --name-only -- \
  R/body-energy-records.R \
  R/body-energy-transition.R \
  R/body-energy-run.R \
  R/gut-energy-records.R \
  R/gut-energy-transition.R \
  R/gut-body-energy-run.R \
  tests/testthat/test-body-energy-records.R \
  tests/testthat/test-body-energy-transition.R \
  tests/testthat/test-body-energy-scenarios.R \
  tests/testthat/test-gut-energy-records.R \
  tests/testthat/test-gut-energy-transition.R \
  tests/testthat/test-gut-body-energy-scenarios.R)" = ''
```

Run `git diff --no-index --check /dev/null -- FILE` for every untracked file,
accepting exit status 0 or 1 and requiring empty output.

## 6. External Package Validation

Build and check in a guarded temporary directory:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
TMP=$(mktemp -d /tmp/rebuild004-check.XXXXXX)
cleanup() {
  local cleanup_status=0
  case "$TMP" in
    /tmp/rebuild004-check.*)
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
  "$REPO/experiments/rebuild-004-controlled-food-energy-bridge.R"
R CMD check --no-manual "$TARBALL"
grep -Fx 'Status: OK' "$TMP/herbivoreTTR.Rcheck/00check.log"

cd "$REPO"
test ! -e "$REPO/outputs"
test ! -e "$REPO/herbivoreTTR.Rcheck"
test -z "$(find "$REPO" -maxdepth 1 -type f \
  -name 'herbivoreTTR_*.tar.gz' -print -quit)"
```

Stop on any warning, note, error, retained product, or failed cleanup.

## 7. Exact Scope And Review

Construct the changed-path inventory from tracked and untracked files. Require
exact equality to the 22-path implementation set in `Goal.md`.

Require:

- frozen Goal, Plan, and Runbook hashes unchanged;
- empty Git index;
- both focused contexts nonzero and green;
- full suite greater than 499 with zero failures, warnings, and skips;
- unchanged Goal 001-003 packet files, body and gut source and tests, and
  `renv.lock`;
- complete review of tracked diffs and untracked contents;
- clean tracked and untracked whitespace checks;
- no repository output, package tarball, or check directory; and
- local `HEAD`, `origin/main`, and live remote `main` still at `BASE`.

Perform one focused parent review and one independent final scientific and code
review. Verify material claims directly. Resolve only Critical or Important
findings, or defects with equivalent effects on units, accounting, scope, or
data integrity.

## 8. Commit And Push Boundary

Goal 004 execution and formulation do not authorize staging, committing, or
pushing. Present the complete uncommitted closeout to Barry.

If Barry later grants publication authority, stage exact reviewed paths only
and use a separately approved commit message. Recheck local and remote state
immediately before any Git write. Never amend, force push, tag, or publish a
release under this goal.

## 9. Stop

Report the implemented conversion, prescribed assumptions, analytical
fixtures, validation evidence, changed paths, Git state, and material
limitations. Stop before any variable food quality, digestion, capacity,
feeding behavior, plant, or later physiological layer.
