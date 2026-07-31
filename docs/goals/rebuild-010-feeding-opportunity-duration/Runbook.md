# Rebuild Goal 010: Feeding-Opportunity Duration Runbook

## Stop Rules

- Require clean synchronized `main` at the published Goal 009 implementation
  before packet publication.
- After packet publication, require the synchronized packet commit as
  `EXECUTION_BASE`.
- Stop if frozen Goal, Plan, or Runbook hashes change.
- Stop before changing any path outside the exact nine-path implementation
  surface.
- Stop before changing production R, tests, manuals, namespace, metadata,
  dependencies, existing experiments, or earlier goal/decision files.
- Stop if the 16-hour Goal 008 full identity or the analytical duration
  contract fails.
- Perform at most one focused repair pass.
- Leave implementation uncommitted and unstaged.

## 1. Packet Publication

Set:

```zsh
FORMULATION_PARENT=b0b05a1895b6e79ab5d1b1a3d75b4d4e19152f8d
PACKET=docs/goals/rebuild-010-feeding-opportunity-duration
```

Require clean local and remote `main` at `FORMULATION_PARENT`, an empty index,
and exactly these four untracked packet files:

```text
docs/goals/rebuild-010-feeding-opportunity-duration/Goal.md
docs/goals/rebuild-010-feeding-opportunity-duration/Log.md
docs/goals/rebuild-010-feeding-opportunity-duration/Plan.md
docs/goals/rebuild-010-feeding-opportunity-duration/Runbook.md
```

Reconstruct that packet path set before staging:

```zsh
EXPECTED_PACKET_PATHS=$(cat <<'EOF'
docs/goals/rebuild-010-feeding-opportunity-duration/Goal.md
docs/goals/rebuild-010-feeding-opportunity-duration/Log.md
docs/goals/rebuild-010-feeding-opportunity-duration/Plan.md
docs/goals/rebuild-010-feeding-opportunity-duration/Runbook.md
EOF
)
ACTUAL_PACKET_PATHS=$(
  git status --porcelain=v1 --untracked-files=all |
    cut -c4- | LC_ALL=C sort
)
test "$ACTUAL_PACKET_PATHS" = \
  "$(printf '%s\n' "$EXPECTED_PACKET_PATHS" | LC_ALL=C sort)"
```

Review the packet independently. Record hashes in `Log.md` using:

```text
Goal.md SHA-256 = <hash>
Plan.md SHA-256 = <hash>
Runbook.md SHA-256 = <hash>
```

Stage and commit only the four packet files. Require the packet commit parent
and changed paths to be exact, push `main`, verify local `origin/main` and live
remote `main`, then append:

```text
Execution baseline commit = <full packet commit hash>
```

## 2. Implementation Scope

After packet publication, allow exactly:

```text
README.md
docs/decisions/0010-feeding-opportunity-duration.md
docs/goals/rebuild-010-feeding-opportunity-duration/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-010-feeding-opportunity-duration.R
experiments/rebuild-010-review-pack.R
```

Require an empty index and no changes under:

```text
R/
tests/
man/
NAMESPACE
DESCRIPTION
renv.lock
.Rbuildignore
.gitignore
```

## 3. Evidence Clients

Create the two scripts declared in `Goal.md`. The no-write experiment must
expose one in-memory evidence object for the review client and use existing
exports for all model execution.

Parse:

```zsh
Rscript --vanilla -e \
  'files <- c(
     "experiments/rebuild-010-feeding-opportunity-duration.R",
     "experiments/rebuild-010-review-pack.R"
   )
   invisible(lapply(files, parse))'
```

Run the no-write experiment from the source-loaded package and require
unchanged Git status:

```zsh
before=$(git status --porcelain=v1 --untracked-files=all)
Rscript --vanilla -e \
  'pkgload::load_all(".", export_all = FALSE, quiet = TRUE)
   source(
     "experiments/rebuild-010-feeding-opportunity-duration.R",
     local = new.env(parent = globalenv())
   )'
after=$(git status --porcelain=v1 --untracked-files=all)
test "$before" = "$after"
```

Generate the review pack:

```zsh
before=$(git status --porcelain=v1 --untracked-files=all)
Rscript --vanilla -e \
  'pkgload::load_all(".", export_all = FALSE, quiet = TRUE)
   source(
     "experiments/rebuild-010-review-pack.R",
     local = new.env(parent = globalenv())
   )' \
  "outputs/rebuild-010-feeding-opportunity-duration"
after=$(git status --porcelain=v1 --untracked-files=all)
test "$before" = "$after"
```

Require exactly four regular non-symbolic files and exact CSV dimensions:

```text
table 1 = 96 x 7
table 2 = 4 x 18
table 3 = 8 x 13
figure = non-empty 1800 x 900 PNG
```

Inspect the figure against the three-panel contract in `Goal.md`.

## 4. Functional Validation

Run the unchanged full suite with an integer-safe count gate:

```zsh
Rscript --vanilla -e \
  'result <- testthat::test_local(".", reporter = "silent")
   data <- as.data.frame(result)
   counts <- as.integer(c(
     sum(data$passed),
     sum(data$failed) + sum(data$error),
     sum(data$warning),
     sum(data$skipped)
   ))
   print(setNames(counts, c("PASS", "FAIL", "WARN", "SKIP")))
   stopifnot(identical(counts, c(1287L, 0L, 0L, 0L)))'

Rscript --vanilla -e \
  'status <- renv::status(); stopifnot(isTRUE(status$synchronized))'

git diff --check
test -z "$(git diff --cached --name-only)"
```

Check untracked text:

```zsh
while IFS= read -r file; do
  findings=$(git diff --no-index --check /dev/null "$file" 2>&1 || true)
  test -z "$findings"
done < <(git ls-files --others --exclude-standard)
```

## 5. Installed-Package Smoke

Use one guarded directory outside the repository:

```zsh
set -euo pipefail
REPO=/Users/bwbrook/git/herbivoreTTR
TMP=$(mktemp -d /tmp/rebuild010-smoke.XXXXXX)
cleanup() {
  local cleanup_status=0
  cd /
  case "$TMP" in
    /tmp/rebuild010-smoke.*)
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
TARBALLS=$(find "$TMP" -maxdepth 1 -type f \
  -name 'herbivoreTTR_*.tar.gz' -print | LC_ALL=C sort)
test "$(printf '%s\n' "$TARBALLS" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 1
TARBALL=$TARBALLS
mkdir "$TMP/library"
R CMD INSTALL --library="$TMP/library" "$TARBALL"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-010-feeding-opportunity-duration.R"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-010-review-pack.R" \
  "$REPO/outputs/rebuild-010-feeding-opportunity-duration"
```

Do not run `R CMD check` unless a material repair changes a protected package
surface.

## 6. Final Scope And Review

Reconstruct `EXECUTION_BASE` and frozen hashes from `Log.md`:

```zsh
PACKET=docs/goals/rebuild-010-feeding-opportunity-duration
FORMULATION_PARENT=b0b05a1895b6e79ab5d1b1a3d75b4d4e19152f8d
EXECUTION_BASE=$(awk \
  '$1 == "Execution" && $2 == "baseline" && $3 == "commit" {print $5}' \
  "$PACKET/Log.md")
test "$(printf '%s' "$EXECUTION_BASE" | wc -c | tr -d ' ')" -eq 40
test "$(git rev-parse "$EXECUTION_BASE")" = "$EXECUTION_BASE"
test "$(git rev-parse "$EXECUTION_BASE^")" = "$FORMULATION_PARENT"
test "$(git rev-parse HEAD)" = "$EXECUTION_BASE"
test "$(git rev-parse origin/main)" = "$EXECUTION_BASE"
test "$(git ls-remote origin refs/heads/main | awk '{print $1}')" = \
  "$EXECUTION_BASE"

goal_hash=$(awk '$1 == "Goal.md" && $2 == "SHA-256" {print $4}' \
  "$PACKET/Log.md")
plan_hash=$(awk '$1 == "Plan.md" && $2 == "SHA-256" {print $4}' \
  "$PACKET/Log.md")
runbook_hash=$(awk '$1 == "Runbook.md" && $2 == "SHA-256" {print $4}' \
  "$PACKET/Log.md")
test "$(shasum -a 256 "$PACKET/Goal.md" | awk '{print $1}')" = "$goal_hash"
test "$(shasum -a 256 "$PACKET/Plan.md" | awk '{print $1}')" = "$plan_hash"
test "$(shasum -a 256 "$PACKET/Runbook.md" | awk '{print $1}')" = \
  "$runbook_hash"
```

Require the exact nine implementation paths:

```zsh
EXPECTED_PATHS=$(cat <<'EOF'
README.md
docs/decisions/0010-feeding-opportunity-duration.md
docs/goals/rebuild-010-feeding-opportunity-duration/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-010-feeding-opportunity-duration.R
experiments/rebuild-010-review-pack.R
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
  R/ tests/ man/ NAMESPACE DESCRIPTION renv.lock \
  .Rbuildignore .gitignore)"
test "$(git rev-parse HEAD)" = "$EXECUTION_BASE"
test "$(git rev-parse origin/main)" = "$EXECUTION_BASE"
test "$(git ls-remote origin refs/heads/main | awk '{print $1}')" = \
  "$EXECUTION_BASE"
```

Require the ignored review directory to contain exactly the four declared
regular, non-symbolic, nonempty files:

```zsh
OUTPUT=outputs/rebuild-010-feeding-opportunity-duration
EXPECTED_OUTPUTS=$(cat <<'EOF'
figure-1-feeding-opportunity-duration.png
table-1-hourly-prescribed-intake-windows.csv
table-2-duration-summary.csv
table-3-daily-accounting.csv
EOF
)
ACTUAL_OUTPUTS=$(
  find "$OUTPUT" -mindepth 1 -maxdepth 1 -print |
    sed "s#^$OUTPUT/##" | LC_ALL=C sort
)
test "$ACTUAL_OUTPUTS" = \
  "$(printf '%s\n' "$EXPECTED_OUTPUTS" | LC_ALL=C sort)"
while IFS= read -r file; do
  test -f "$OUTPUT/$file"
  test ! -L "$OUTPUT/$file"
  test -s "$OUTPUT/$file"
done < <(printf '%s\n' "$EXPECTED_OUTPUTS")
```

Require no repository build/check residue and no
`/tmp/rebuild010-smoke.*` directory.

Obtain one independent final review of:

- fixture arithmetic, hour conventions, and prescribed-intake/activity overlap;
- the daily duration relation versus placement-conditional trajectories;
- daily-total versus trajectory-identity claims;
- retained tables and figure;
- evidence-only wording;
- validation receipts; and
- final Git scope.

Resolve only Critical or Important findings. Record acceptance and material
residual limitations in `Log.md`.

## 7. Publication Boundary

Stop with Goal 010 implementation uncommitted and unstaged. Retain the ignored
review pack for Barry. Commit or push only with later explicit publication
authority.
