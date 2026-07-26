# Rebuild Goal 003 Runbook

## Purpose

This is guarded execution guidance for Goal 003 after explicit authorization.
It does not itself authorize implementation, staging, committing, or pushing.

## Stop Rules

- Stop on an unexpected dirty path, changed upstream, control-document hash
  mismatch, missing tool, failed command, or changed scientific requirement.
- Do not reset, clean, stash, force, amend, or modify Goal 002 history.
- Do not add dependencies, configurable time steps, food mass or quality,
  digestive loss, gut capacity, activity, or body feedback.
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
BASE=1632f60d69a78d0b704983b5323a74ad14bc09c0

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
  "$REPO/docs/goals/rebuild-003-one-pool-gut-energy-buffer/Goal.md" \
  "$AUTHORIZED_PLAN_SHA256" \
  "$REPO/docs/goals/rebuild-003-one-pool-gut-energy-buffer/Plan.md" \
  "$AUTHORIZED_RUNBOOK_SHA256" \
  "$REPO/docs/goals/rebuild-003-one-pool-gut-energy-buffer/Runbook.md" \
  | shasum -a 256 -c -

diff -u \
  <(printf '%s\n' \
    '?? docs/goals/rebuild-003-one-pool-gut-energy-buffer/Goal.md' \
    '?? docs/goals/rebuild-003-one-pool-gut-energy-buffer/Log.md' \
    '?? docs/goals/rebuild-003-one-pool-gut-energy-buffer/Plan.md' \
    '?? docs/goals/rebuild-003-one-pool-gut-energy-buffer/Runbook.md' \
    | LC_ALL=C sort) \
  <(git -C "$REPO" status --short --untracked-files=all | LC_ALL=C sort)
```

If any observation differs, stop without editing.

## 2. Test-First Record Implementation

Create and parse the record tests before production source:

```zsh
cd /Users/bwbrook/git/herbivoreTTR
Rscript --vanilla -e \
  'parse(file = "tests/testthat/test-gut-energy-records.R")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "gut-energy-records")'
```

Inspect structured failures. Accept the red phase only when every failure is
the expected absent interface or unmet declared contract, with no parse error,
package-load failure, missing dependency, unexpected warning, or skip.

Implement:

```text
new_gut_energy_state()
new_gut_energy_parameters()
new_ingested_available_energy_schedule()
```

Make the focused record test green before proceeding.

## 3. Test-First Gut Transition

Create and parse the transition tests, then reproduce the expected red phase:

```zsh
Rscript --vanilla -e \
  'parse(file = "tests/testthat/test-gut-energy-transition.R")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "gut-energy-transition")'
```

Implement `step_gut_energy()` with release from opening gut stock, then current-
hour ingestion. Require finite arithmetic, non-negative closing stock, no
mutation, and exact balance within the declared tolerance. Make the focused
transition test green.

## 4. Test-First Integrated Runner

Create and parse the integrated scenario tests, then reproduce the expected red
phase:

```zsh
Rscript --vanilla -e \
  'parse(file = "tests/testthat/test-gut-body-energy-scenarios.R")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "gut-body-energy-scenarios")'
```

Implement `run_gut_body_energy_day()` as 24 transitions. For each hour:

1. call `step_gut_energy()`;
2. translate its `assimilated_energy_kj_h` into the exact one-row input accepted
   by `step_body_energy()`;
3. call the existing body transition;
4. record both closing states and all three accounting residuals.

Do not copy body arithmetic into the new runner. Derive the daily summary from
the hourly ledger. Make the integrated tests green.

## 5. Experiment And Documentation

Add the thin experiment after all core functions are green. It must assert the
three analytical fixtures in memory and write only compact summaries to stdout.

Generate documentation only after interfaces stabilize:

```zsh
Rscript --vanilla -e \
  'stopifnot(requireNamespace("roxygen2", quietly = TRUE)); roxygen2::roxygenise()'
```

Inspect `DESCRIPTION`, `NAMESPACE`, and every changed `man/` file. Stop if
roxygen changes an undeclared path or modifies `renv.lock`.

## 6. Functional Validation

Run focused and full tests:

```zsh
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "gut-energy-records")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "gut-energy-transition")'
Rscript --vanilla -e \
  'testthat::test_local(".", filter = "gut-body-energy-scenarios")'
Rscript --vanilla -e 'testthat::test_local(".")'
```

Record the structured counts in `Log.md`. Each focused context must contain at
least one passing expectation and exactly zero failures, warnings, and skips.
The full suite must contain at least the 239 published Goal 002 expectations
plus the new Goal 003 expectations, with exactly zero failures, warnings, and
skips. A zero-test or filtered-away context is a failure, not a pass.

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
  tests/testthat/test-body-energy-records.R \
  tests/testthat/test-body-energy-transition.R \
  tests/testthat/test-body-energy-scenarios.R)" = ''
```

Run `git diff --no-index --check /dev/null -- FILE` for every untracked file,
accepting exit status 0 or 1 and requiring empty output.

## 7. External Package Validation

Build and check in a guarded temporary directory:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
REVIEW=/Users/bwbrook/work/herbivoreTTR-review/goal-003
TMP=$(mktemp -d /tmp/rebuild003-check.XXXXXX)
cleanup() {
  case "$TMP" in
    /tmp/rebuild003-check.*)
      Rscript --vanilla -e \
        'unlink(commandArgs(TRUE), recursive = TRUE)' "$TMP"
      ;;
    *) printf '%s\n' 'Unsafe temporary path; stop.' >&2; return 1 ;;
  esac
}
trap cleanup EXIT

write_source_manifest() {
  (
    cd "$REPO"
    {
      printf '%s\n' DESCRIPTION NAMESPACE
      find R -maxdepth 1 -type f -name '*.R' -print | LC_ALL=C sort
      printf '%s\n' experiments/rebuild-003-review-pack.R
    } | while IFS= read -r file; do
      shasum -a 256 "$file"
    done
  )
}

if [[ -e "$REVIEW" || -L "$REVIEW" ]]; then
  test ! -L "$REVIEW"
  test -d "$REVIEW"
fi

STATUS_BEFORE=$(
  git -C "$REPO" status --porcelain=v1 -z --untracked-files=all |
    shasum -a 256 | awk '{print $1}'
)
SOURCE_MANIFEST_BEFORE="$TMP/source-manifest-before.sha256"
write_source_manifest > "$SOURCE_MANIFEST_BEFORE"

cd "$TMP"
R CMD build "$REPO"
TARBALL=$(find "$TMP" -maxdepth 1 -type f \
  -name 'herbivoreTTR_*.tar.gz' -print -quit)
test -n "$TARBALL"
mkdir "$TMP/library"
R CMD INSTALL --library="$TMP/library" "$TARBALL"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-003-one-pool-gut-buffer.R"
R CMD check --no-manual "$TARBALL"
grep -Fx 'Status: OK' "$TMP/herbivoreTTR.Rcheck/00check.log"

SOURCE_MANIFEST_PRE_GENERATION="$TMP/source-manifest-pre-generation.sha256"
write_source_manifest > "$SOURCE_MANIFEST_PRE_GENERATION"
cmp -s "$SOURCE_MANIFEST_PRE_GENERATION" "$SOURCE_MANIFEST_BEFORE"

(
  cd "$REPO"
  R_LIBS_USER="$TMP/library" Rscript --vanilla \
    experiments/rebuild-003-review-pack.R "$REVIEW"
)

SOURCE_MANIFEST_AFTER="$TMP/source-manifest-after.sha256"
write_source_manifest > "$SOURCE_MANIFEST_AFTER"
cmp -s "$SOURCE_MANIFEST_AFTER" "$SOURCE_MANIFEST_BEFORE"
cmp -s "$REVIEW/source-manifest.sha256" "$SOURCE_MANIFEST_BEFORE"

STATUS_AFTER=$(
  git -C "$REPO" status --porcelain=v1 -z --untracked-files=all |
    shasum -a 256 | awk '{print $1}'
)
test "$STATUS_AFTER" = "$STATUS_BEFORE"

cd "$REPO"
test ! -e "$REPO/outputs"
test ! -e "$REPO/herbivoreTTR.Rcheck"
test -z "$(find "$REPO" -maxdepth 1 -type f \
  -name 'herbivoreTTR_*.tar.gz' -print -quit)"
```

Stop on any warning, note, error, retained product, or failed cleanup.

## 8. Diagnostic Review Pack

The external-validation block generates review-only artifacts under:

```text
/Users/bwbrook/work/herbivoreTTR-review/goal-003/
```

Verify the exact recursive file set:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
REVIEW=/Users/bwbrook/work/herbivoreTTR-review/goal-003
test -d "$REVIEW"
test ! -L "$REVIEW"

diff -u \
  <(printf '%s\n' \
    artifact-manifest.sha256 \
    figure-1-equilibrium-and-initialization.png \
    figure-2-pulse-response.png \
    generation-metadata.txt \
    source-manifest.sha256 \
    table-1-daily-summary.csv \
    table-2-hourly-checkpoints.csv \
    table-3-full-hourly-ledgers.csv \
    | LC_ALL=C sort) \
  <(find "$REVIEW" -mindepth 1 -maxdepth 1 -print \
    | sed "s#^$REVIEW/##" | LC_ALL=C sort)

while IFS= read -r file; do
  test -f "$REVIEW/$file"
  test ! -L "$REVIEW/$file"
done < <(find "$REVIEW" -mindepth 1 -maxdepth 1 -print \
  | sed "s#^$REVIEW/##")

(cd "$REPO" && shasum -a 256 -c "$REVIEW/source-manifest.sha256")
(cd "$REVIEW" && shasum -a 256 -c artifact-manifest.sha256)
```

The source manifest must list exactly `DESCRIPTION`, `NAMESPACE`, every
`R/*.R` file loaded into the package, and
`experiments/rebuild-003-review-pack.R`. The artifact manifest must list the
other seven review-pack files and must not list itself.

Read all three CSVs with `check.names = FALSE`. Require:

- three daily rows, one for each exact scenario identifier
  `equilibrium`, `empty_start`, and `pulse`;
- daily columns equal `scenario_id` followed by the exact daily schema in
  `Goal.md`;
- 24 checkpoint rows, with exact declared columns and hours
  `0, 1, 2, 3, 6, 12, 18, 23` for every scenario;
- 72 full-ledger rows, with 24 ordered hours per scenario; and
- full-ledger columns equal `scenario_id` followed by the exact hourly schema
  in `Goal.md`.

Recalculate the equilibrium, empty-start, and pulse checkpoints from the CSVs
and compare them with the analytical equations in `Goal.md`. Require every gut,
body, and system residual to remain within its declared tolerance.

Inspect both PNG files visually. Require nonblank rendering, readable axes and
legends, explicit units, no clipping or overlap, and a visible statement that
the fixtures are synthetic. Read `generation-metadata.txt` and require the
current repository path, branch, `HEAD`, complete short status, fixture
constants, generation time zone, and interpretation boundary.

## 9. Exact Scope Review

Construct the changed-path inventory from both tracked and untracked files.
Require exact equality to the 27-path implementation set in `Goal.md`. Every
declared source, test, experiment, decision, documentation, manual, and packet
file is required; no grouping exception or extra path is accepted.

Require:

- frozen Goal, Plan, and Runbook hashes unchanged;
- empty Git index;
- nonzero focused-test counts and a full-suite count greater than the published
  239-test Goal 002 baseline, all with zero failures, warnings, and skips;
- no changed Goal 002 packet, body source, body tests, or `renv.lock`;
- complete review of tracked diffs and untracked file contents;
- clean tracked and untracked whitespace checks;
- no repository output, package tarball, or check directory; and
- local `HEAD`, `origin/main`, and live remote `main` still at `BASE`.

Use one independent final reviewer for the scientific contract and code/diff
surface. Treat its report as an evidence lead and verify material claims
directly. Resolve only Critical or Important findings, or defects with an
equivalent effect on accounting, scope, or data integrity.

## 10. Commit And Push Boundary

Goal 003 execution and packet formulation do not authorize staging, committing,
or pushing. Present the complete uncommitted closeout to Barry.

If Barry later grants publication authority, stage exact reviewed paths only
and use a separately approved commit message. Recheck local and remote state
immediately before any Git write. Never amend, force push, tag, or publish a
release under this goal.

## 11. Stop

Report the implemented mechanism, exact assumptions, analytical fixtures,
validation evidence, changed paths, diagnostic pack, Git state, and material
limitations. Stop before any excluded biological process or formulation of the
next layer.
