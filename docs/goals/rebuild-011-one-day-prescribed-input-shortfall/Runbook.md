# Rebuild Goal 011: One-Day Prescribed-Input Shortfall Runbook

## Stop Rules

- Require clean synchronized `main` at the published Goal 010 commit before
  formulation.
- Require the published Goal 010 commit as `EXECUTION_BASE`.
- Stop if frozen Goal, Plan, or Runbook hashes change after packet review.
- Stop before changing any path outside the exact twelve-path scope.
- Stop before changing production R, tests, manuals, namespace, metadata,
  dependencies, existing experiments, or earlier goals and decisions.
- Stop if the shared initialization, `-800 kJ` system invariant, or
  return-to-reference gut recurrence fails.
- Perform at most one focused repair pass.
- Leave Goal 011 uncommitted and unstaged.

## 1. Formulation Baseline

Set:

```zsh
EXECUTION_BASE=468576f11cf407dc6ce6fde3e855758c6e7d0504
PACKET=docs/goals/rebuild-011-one-day-prescribed-input-shortfall
```

Require:

```zsh
set -euo pipefail
test "$(git rev-parse HEAD)" = "$EXECUTION_BASE"
test "$(git rev-parse origin/main)" = "$EXECUTION_BASE"
test "$(git ls-remote origin refs/heads/main | awk '{print $1}')" = \
  "$EXECUTION_BASE"
test -z "$(git diff --name-only)"
test -z "$(git diff --cached --name-only)"
EXPECTED_PACKET_PATHS=$(cat <<'EOF'
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Goal.md
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Log.md
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Plan.md
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Runbook.md
EOF
)
ACTUAL_PACKET_PATHS=$(
  git ls-files --others --exclude-standard | LC_ALL=C sort
)
test "$ACTUAL_PACKET_PATHS" = \
  "$(printf '%s\n' "$EXPECTED_PACKET_PATHS" | LC_ALL=C sort)"
```

After independent packet review, record:

```text
Goal.md SHA-256 = <hash>
Plan.md SHA-256 = <hash>
Runbook.md SHA-256 = <hash>
```

in `Log.md`. Keep the packet uncommitted.

## 2. Implementation Scope

Allow exactly:

```text
README.md
docs/decisions/0011-one-day-prescribed-input-shortfall.md
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Goal.md
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Log.md
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Plan.md
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Runbook.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-011-one-day-prescribed-input-shortfall.R
experiments/rebuild-011-review-pack.R
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

Parse:

```zsh
set -euo pipefail
Rscript --vanilla -e \
  'files <- c(
     "experiments/rebuild-011-one-day-prescribed-input-shortfall.R",
     "experiments/rebuild-011-review-pack.R"
   )
   invisible(lapply(files, parse))'
```

Run the no-write experiment from the source-loaded package and require
unchanged Git status:

```zsh
set -euo pipefail
before=$(git status --porcelain=v1 --untracked-files=all)
Rscript --vanilla -e \
  'pkgload::load_all(".", export_all = FALSE, quiet = TRUE)
   source(
     "experiments/rebuild-011-one-day-prescribed-input-shortfall.R",
     local = new.env(parent = globalenv())
   )'
after=$(git status --porcelain=v1 --untracked-files=all)
test "$before" = "$after"
```

Generate the review pack:

```zsh
set -euo pipefail
before=$(git status --porcelain=v1 --untracked-files=all)
Rscript --vanilla -e \
  'pkgload::load_all(".", export_all = FALSE, quiet = TRUE)
   source(
     "experiments/rebuild-011-review-pack.R",
     local = new.env(parent = globalenv())
   )' \
  "outputs/rebuild-011-one-day-prescribed-input-shortfall"
after=$(git status --porcelain=v1 --untracked-files=all)
test "$before" = "$after"
```

Require exactly four regular non-symbolic files and exact dimensions:

```text
table 1 = 73 x 7
table 2 = 6 x 16
table 3 = 4 x 10
figure = non-empty 1800 x 900 PNG
```

Inspect the figure against the three-panel contract in `Goal.md`.

## 4. Functional Validation

Run the unchanged full suite with an integer-safe count gate:

```zsh
set -euo pipefail
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
set -euo pipefail
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
TMP=$(mktemp -d /tmp/rebuild011-smoke.XXXXXX)
cleanup() {
  local cleanup_status=0
  cd /
  case "$TMP" in
    /tmp/rebuild011-smoke.*)
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
  "$REPO/experiments/rebuild-011-one-day-prescribed-input-shortfall.R"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-011-review-pack.R" \
  "$REPO/outputs/rebuild-011-one-day-prescribed-input-shortfall"
```

Do not run `R CMD check` unless a material repair changes a protected package
surface.

## 6. Final Scope And Review

Reconstruct the frozen hashes:

```zsh
set -euo pipefail
PACKET=docs/goals/rebuild-011-one-day-prescribed-input-shortfall
EXECUTION_BASE=468576f11cf407dc6ce6fde3e855758c6e7d0504

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
test "$(git rev-parse HEAD)" = "$EXECUTION_BASE"
test "$(git rev-parse origin/main)" = "$EXECUTION_BASE"
test "$(git ls-remote origin refs/heads/main | awk '{print $1}')" = \
  "$EXECUTION_BASE"
```

Require the exact twelve paths:

```zsh
set -euo pipefail
EXPECTED_PATHS=$(cat <<'EOF'
README.md
docs/decisions/0011-one-day-prescribed-input-shortfall.md
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Goal.md
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Log.md
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Plan.md
docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Runbook.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-011-one-day-prescribed-input-shortfall.R
experiments/rebuild-011-review-pack.R
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
```

Require the ignored review directory to contain exactly:

```text
figure-1-one-day-prescribed-input-shortfall.png
table-1-hourly-boundary-contrasts.csv
table-2-daily-sequences.csv
table-3-day-boundary-realignment.csv
```

Check the exact ignored output set, regularity, dimensions, and cleanup:

```zsh
set -euo pipefail
OUTPUT=outputs/rebuild-011-one-day-prescribed-input-shortfall
EXPECTED_OUTPUTS=$(cat <<'EOF'
figure-1-one-day-prescribed-input-shortfall.png
table-1-hourly-boundary-contrasts.csv
table-2-daily-sequences.csv
table-3-day-boundary-realignment.csv
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

Rscript --vanilla - "$OUTPUT" <<'RS'
output <- commandArgs(TRUE)[[1L]]
table_1 <- utils::read.csv(
  file.path(output, "table-1-hourly-boundary-contrasts.csv"),
  check.names = FALSE
)
table_2 <- utils::read.csv(
  file.path(output, "table-2-daily-sequences.csv"),
  check.names = FALSE
)
table_3 <- utils::read.csv(
  file.path(output, "table-3-day-boundary-realignment.csv"),
  check.names = FALSE
)
stopifnot(
  identical(dim(table_1), c(73L, 7L)),
  identical(dim(table_2), c(6L, 16L)),
  identical(dim(table_3), c(4L, 10L))
)
png_path <- file.path(
  output,
  "figure-1-one-day-prescribed-input-shortfall.png"
)
png_dimensions <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection))
  signature <- readBin(connection, "raw", n = 8L)
  chunk_length <- readBin(
    connection, "integer", n = 1L, size = 4L, endian = "big"
  )
  chunk_type <- rawToChar(readBin(connection, "raw", n = 4L))
  width <- readBin(
    connection, "integer", n = 1L, size = 4L, endian = "big"
  )
  height <- readBin(
    connection, "integer", n = 1L, size = 4L, endian = "big"
  )
  stopifnot(
    identical(signature, as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))),
    identical(chunk_length, 13L),
    identical(chunk_type, "IHDR")
  )
  c(width = width, height = height)
}
stopifnot(
  identical(png_dimensions(png_path), c(width = 1800L, height = 900L))
)
RS

test -z "$(find . -maxdepth 2 \
  \( -name '*.Rcheck' -o -name 'herbivoreTTR_*.tar.gz' \) -print)"
test -z "$(find /tmp -maxdepth 1 \
  -name 'rebuild011-smoke.*' -print)"
```

Obtain one independent final review of:

- shared initialization and state carry-over;
- prescribed-input and combined-system contrasts;
- hourly and daily gut recurrence;
- body complement and interpretation;
- retained tables and figure;
- evidence-only wording;
- validation receipts; and
- final Git scope.

Resolve only Critical or Important findings. Record acceptance and residual
limitations in `Log.md`.

## 7. Publication Boundary

Stop with all Goal 011 work uncommitted and unstaged. Retain the ignored review
pack for Barry. Commit or push only with later explicit publication authority.
