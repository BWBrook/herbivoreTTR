# Rebuild Goal 009: Synthetic Intake-Ceiling Threshold Runbook

## Purpose

Execute the approved evidence-only ceiling threshold from clean published Goal
008 without adding a production mechanism or reinterpreting prescribed intake
as behavior, demand, or offered forage.

## Stop Rules

- Stop if the recorded formulation parent is not clean synchronized `96caf0e`.
- After packet publication, stop if the execution baseline is not the clean
  synchronized packet commit.
- Stop if frozen Goal, Plan, or Runbook hashes change.
- Stop before changing a path outside the nine-file implementation surface.
- Stop before changing production R, tests, manuals, namespace, metadata,
  dependencies, existing experiments, or existing decisions/goal packets.
- Stop if exact Goal 008 oracle identity fails; diagnose rather than widen.
- Do not reset, clean, stash, force, amend, or delete prior retained outputs.
- Perform at most one focused repair pass for a material finding.
- Stop uncommitted after acceptance.

## 1. Packet Preflight

Require:

```zsh
FORMULATION_PARENT=96caf0eaa1f542be8b529546d1aa0b999adf5eab
EXPECTED_PACKET_PATHS=$(cat <<'EOF'
docs/goals/rebuild-009-synthetic-intake-ceiling-threshold/Goal.md
docs/goals/rebuild-009-synthetic-intake-ceiling-threshold/Log.md
docs/goals/rebuild-009-synthetic-intake-ceiling-threshold/Plan.md
docs/goals/rebuild-009-synthetic-intake-ceiling-threshold/Runbook.md
EOF
)
test "$(git branch --show-current)" = main
test "$(git rev-parse HEAD)" = "$FORMULATION_PARENT"
test "$(git rev-parse origin/main)" = "$FORMULATION_PARENT"
test "$(git ls-remote origin refs/heads/main | awk '{print $1}')" = \
  "$FORMULATION_PARENT"
test -z "$(git diff --cached --name-only)"
ACTUAL_PACKET_PATHS=$(git status --porcelain=v1 --untracked-files=all |
  awk '{print $2}' | LC_ALL=C sort)
test "$ACTUAL_PACKET_PATHS" = \
  "$(printf '%s\n' "$EXPECTED_PACKET_PATHS" | LC_ALL=C sort)"
```

Review the packet scientifically and operationally. Freeze SHA-256 hashes for
`Goal.md`, `Plan.md`, and `Runbook.md` and append these exact machine-readable
lines to `Log.md`:

```text
Goal.md SHA-256 = <hash>
Plan.md SHA-256 = <hash>
Runbook.md SHA-256 = <hash>
```

Commit only the four packet files. Before pushing, require:

```zsh
PACKET_COMMIT=$(git rev-parse HEAD)
test "$(git rev-parse "$PACKET_COMMIT^")" = "$FORMULATION_PARENT"
COMMITTED_PACKET_PATHS=$(git diff-tree --no-commit-id --name-only -r \
  "$PACKET_COMMIT" | LC_ALL=C sort)
test "$COMMITTED_PACKET_PATHS" = \
  "$(printf '%s\n' "$EXPECTED_PACKET_PATHS" | LC_ALL=C sort)"
test -z "$(git status --porcelain=v1 --untracked-files=all)"
```

Push the packet commit. Record it as `EXECUTION_BASE`, require local
`origin/main` and live remote `main` to equal it, then append this exact line to
`Log.md` before any other implementation edit:

```text
Execution baseline commit = <full EXECUTION_BASE hash>
```

## 2. No-Write Experiment

Create:

```text
experiments/rebuild-009-synthetic-intake-ceiling-threshold.R
```

Use one small local function that accepts the candidate rate vector and ceiling
rate vector, verifies aligned length and finite non-negative values, and returns
`pmin(candidate, ceiling)`. It is evidence code, not a package interface.

Construct direct Goal 008 oracle schedules independently. Run the three
constrained schedules and the two accepted oracle schedules through exported
package functions. Require exact in-memory schedule and full-result identity:

```text
below threshold = ecological_activity_uncompensated
at threshold = ecological_activity_prescribed_balance
above threshold = ecological_activity_prescribed_balance
```

Assert all material contracts in `Goal.md`, print compact summaries, and write
no files.

Run from the source-loaded package while requiring unchanged Git status:

```zsh
before=$(git status --porcelain=v1 --untracked-files=all)
Rscript --vanilla -e \
  'pkgload::load_all(".", export_all = FALSE, quiet = TRUE)
   source(
     "experiments/rebuild-009-synthetic-intake-ceiling-threshold.R",
     local = new.env(parent = globalenv())
   )'
after=$(git status --porcelain=v1 --untracked-files=all)
test "$before" = "$after"
```

## 3. Review Pack

Create:

```text
experiments/rebuild-009-review-pack.R
```

The script accepts exactly one output-directory argument and writes exactly:

```text
figure-1-synthetic-intake-ceiling-threshold.png
table-1-hourly-ceiling-screen.csv
table-2-threshold-summary.csv
table-3-daily-accounting.csv
```

It must reject missing/extra arguments, existing undeclared destination
entries, and symbolic links in the destination path. It stages regular files,
validates all CSVs before and after serialization, and replaces the declared
pack only after analytical success.

Run it from the source-loaded package while requiring unchanged Git status:

```zsh
before=$(git status --porcelain=v1 --untracked-files=all)
Rscript --vanilla -e \
  'pkgload::load_all(".", export_all = FALSE, quiet = TRUE)
   source(
     "experiments/rebuild-009-review-pack.R",
     local = new.env(parent = globalenv())
   )' \
  "outputs/rebuild-009-synthetic-intake-ceiling-threshold"
after=$(git status --porcelain=v1 --untracked-files=all)
test "$before" = "$after"
```

Inspect the figure for:

- the analytical kink at `200 kJ h^-1`;
- daily constrained energy and body-change axes with explicit units;
- all three declared fixture points;
- correct `0-48 h` body-reserve trajectories;
- legible threshold and zero reference lines; and
- no empirical, behavioral, or viability wording.

## 4. Documentation

Create Decision 0009 and update only the declared documentation files plus the
mutable Goal 009 Log. Correct stale Goal-status prose in the variable
dictionary without adding a variable or schema.

## 5. Functional Validation

Parse the two new scripts:

```zsh
Rscript --vanilla -e \
  'files <- c(
     "experiments/rebuild-009-synthetic-intake-ceiling-threshold.R",
     "experiments/rebuild-009-review-pack.R"
   )
   invisible(lapply(files, parse))'
```

Run the unchanged full suite with structured counts:

```r
result <- testthat::test_local(".", reporter = "silent")
data <- as.data.frame(result)
counts <- c(
  PASS = sum(data$passed),
  FAIL = sum(data$failed) + sum(data$error),
  WARN = sum(data$warning),
  SKIP = sum(data$skipped)
)
print(counts)
stopifnot(
  identical(unname(counts), c(1287, 0, 0, 0))
)
```

Then require:

```zsh
Rscript --vanilla -e \
  'status <- renv::status(); stopifnot(isTRUE(status$synchronized))'
git diff --check
test -z "$(git diff --cached --name-only)"
```

Check untracked text deterministically. The expected nonzero exit from
`--no-index` is ignored; any printed whitespace finding is a failure:

```zsh
while IFS= read -r file; do
  findings=$(git diff --no-index --check /dev/null "$file" 2>&1 || true)
  test -z "$findings"
done < <(git ls-files --others --exclude-standard)
```

## 6. External Package Validation

Use one guarded directory outside the repository:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
TMP=$(mktemp -d /tmp/rebuild009-check.XXXXXX)
cleanup() {
  local cleanup_status=0
  cd /
  case "$TMP" in
    /tmp/rebuild009-check.*)
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
  "$REPO/experiments/rebuild-009-synthetic-intake-ceiling-threshold.R"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-009-review-pack.R" \
  "$REPO/outputs/rebuild-009-synthetic-intake-ceiling-threshold"
R CMD check --no-manual "$TARBALL"
grep -Fx 'Status: OK' "$TMP/herbivoreTTR.Rcheck/00check.log"
```

Do not repeat this ladder unless a material repair invalidates its evidence.

## 7. Final Scope And Review

Reconstruct `EXECUTION_BASE` from the exact Log line and require:

```zsh
PACKET=docs/goals/rebuild-009-synthetic-intake-ceiling-threshold
FORMULATION_PARENT=96caf0eaa1f542be8b529546d1aa0b999adf5eab
EXECUTION_BASE=$(awk \
  '$1 == "Execution" && $2 == "baseline" && $3 == "commit" {print $5}' \
  "$PACKET/Log.md")
test -n "$EXECUTION_BASE"
test "$(git rev-parse "$EXECUTION_BASE")" = "$EXECUTION_BASE"
test "$(git rev-parse "$EXECUTION_BASE^")" = "$FORMULATION_PARENT"
test "$(git rev-parse origin/main)" = "$EXECUTION_BASE"
```

Check Goal, Plan, and Runbook against their SHA-256 values recorded in Log.

```zsh
goal_hash=$(awk '$1 == "Goal.md" && $2 == "SHA-256" {print $4}' \
  "$PACKET/Log.md")
plan_hash=$(awk '$1 == "Plan.md" && $2 == "SHA-256" {print $4}' \
  "$PACKET/Log.md")
runbook_hash=$(awk '$1 == "Runbook.md" && $2 == "SHA-256" {print $4}' \
  "$PACKET/Log.md")
test -n "$goal_hash"
test -n "$plan_hash"
test -n "$runbook_hash"
test "$(shasum -a 256 "$PACKET/Goal.md" | awk '{print $1}')" = "$goal_hash"
test "$(shasum -a 256 "$PACKET/Plan.md" | awk '{print $1}')" = "$plan_hash"
test "$(shasum -a 256 "$PACKET/Runbook.md" | awk '{print $1}')" = \
  "$runbook_hash"
```

Require the exact changed-path set:

```zsh
EXPECTED_PATHS=$(cat <<'EOF'
README.md
docs/decisions/0009-synthetic-intake-ceiling-threshold.md
docs/goals/rebuild-009-synthetic-intake-ceiling-threshold/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-009-synthetic-intake-ceiling-threshold.R
experiments/rebuild-009-review-pack.R
EOF
)
ACTUAL_PATHS=$(
  {
    git diff --name-only "$EXECUTION_BASE"
    git ls-files --others --exclude-standard
  } | LC_ALL=C sort -u
)
test "$ACTUAL_PATHS" = "$(printf '%s\n' "$EXPECTED_PATHS" | LC_ALL=C sort)"
test -z "$(git diff --cached --name-only)"
test -z "$(git diff --name-only "$EXECUTION_BASE" -- \
  R/ tests/ man/ NAMESPACE DESCRIPTION renv.lock .Rbuildignore .gitignore)"
```

Also require:

- no untracked protected path, implied by exact path-set equality;
- no change to existing experiments, decisions, or goal packets;
- exact four-file ignored output with regular non-symbolic files;
- no package tarball, check directory, or guarded temporary residue;
- source, installed, test, artefact, and package-check receipts; and
- one independent final scientific/evidence review.

Resolve only Critical or Important findings. Record acceptance and residual
limits in Log.

## 8. Publication Boundary

Stop with Goal 009 implementation uncommitted. Retain the ignored review pack
for Barry. Stage, commit, and push only after separate publication authority.
