# Rebuild Goal 012: Prescribed Energy-Repayment Pulse Runbook

## Stop Rules

- Require clean synchronized `main` at the published Goal 011 commit before
  formulation.
- Stop if frozen Goal, Plan, or Runbook hashes change after packet review.
- Stop before changing any path outside the exact twelve-path scope.
- Stop before changing production R, tests, manuals, namespace, metadata,
  dependencies, existing experiments, or earlier goals and decisions.
- Stop if common initialization, the `-800 -> 0 kJ` combined-system path, or
  the post-pulse gut recurrence fails.
- Perform at most one focused material repair pass.
- Leave Goal 012 uncommitted and unstaged.

## 1. Formulation Baseline

```zsh
set -euo pipefail
EXECUTION_BASE=d8c80a9ae088ab03022868e97eb5a6b943b3cf84
PACKET=docs/goals/rebuild-012-prescribed-energy-repayment-pulse
test "$(git rev-parse HEAD)" = "$EXECUTION_BASE"
test "$(git rev-parse origin/main)" = "$EXECUTION_BASE"
test "$(git ls-remote origin refs/heads/main | awk '{print $1}')" = \
  "$EXECUTION_BASE"
test -z "$(git diff --name-only)"
test -z "$(git diff --cached --name-only)"
EXPECTED_PACKET_PATHS=$(cat <<'EOF'
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Goal.md
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Log.md
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Plan.md
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Runbook.md
EOF
)
ACTUAL_PACKET_PATHS=$(git ls-files --others --exclude-standard | LC_ALL=C sort)
test "$ACTUAL_PACKET_PATHS" = \
  "$(printf '%s\n' "$EXPECTED_PACKET_PATHS" | LC_ALL=C sort)"
```

After independent packet review, record Goal, Plan, and Runbook SHA-256 hashes
in `Log.md`. Keep those three files frozen.

## 2. Implementation Scope

Allow exactly:

```text
README.md
docs/decisions/0012-prescribed-energy-repayment-pulse.md
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Goal.md
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Log.md
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Plan.md
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Runbook.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-012-prescribed-energy-repayment-pulse.R
experiments/rebuild-012-review-pack.R
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

Parse both clients:

```zsh
set -euo pipefail
Rscript --vanilla -e \
  'files <- c(
     "experiments/rebuild-012-prescribed-energy-repayment-pulse.R",
     "experiments/rebuild-012-review-pack.R"
   )
   invisible(lapply(files, parse))'

```

Run the no-write experiment with its own status-invariance gate:

```zsh
set -euo pipefail
before=$(git status --porcelain=v1 --untracked-files=all)
Rscript --vanilla -e \
  'pkgload::load_all(".", export_all = FALSE, quiet = TRUE)
   source(
     "experiments/rebuild-012-prescribed-energy-repayment-pulse.R",
     local = new.env(parent = globalenv())
   )'
after=$(git status --porcelain=v1 --untracked-files=all)
test "$before" = "$after"
```

Run the review publisher with a separate status-invariance gate:

```zsh
set -euo pipefail
before=$(git status --porcelain=v1 --untracked-files=all)
Rscript --vanilla -e \
  'pkgload::load_all(".", export_all = FALSE, quiet = TRUE)
   source(
     "experiments/rebuild-012-review-pack.R",
     local = new.env(parent = globalenv())
   )' \
  "outputs/rebuild-012-prescribed-energy-repayment-pulse"
after=$(git status --porcelain=v1 --untracked-files=all)
test "$before" = "$after"
```

Require exactly four regular non-symbolic files:

```text
table 1 = 97 x 7
table 2 = 8 x 16
table 3 = 5 x 10
figure = non-empty 1800 x 900 PNG
```

Inspect the figure against the three-panel contract in `Goal.md`.

### Guard And Semantic-Mutation Probes

Require the review client to reject:

```text
no output argument
more than one output argument
an empty or newline-containing argument
a symbolic destination
a destination with a symbolic ancestor
an existing destination containing an undeclared entry
```

Use guarded `/tmp/rebuild012-guards.*` fixtures and delete them with checked R
`unlink()` calls. Before publication, load the review validator without calling
`main()`. Independently reconstruct all expected tables from raw sequence
results, schedules, and the analytical recurrence. Mutation-probe every column
of every in-memory table and every CSV-readback table; every mutation must
raise a validation error.

Copy one valid four-file pack to the guarded temporary destination, record its
four SHA-256 hashes, induce a staged semantic-validation failure, and require
the destination hashes and file set to remain unchanged. Static review must
also confirm that staged validation completes before any call that replaces an
existing destination.

## 4. Functional Validation

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
TMP=$(mktemp -d /tmp/rebuild012-smoke.XXXXXX)
cleanup() {
  local cleanup_status=0
  cd /
  case "$TMP" in
    /tmp/rebuild012-smoke.*)
      Rscript --vanilla -e \
        'status <- unlink(commandArgs(TRUE), recursive = TRUE)
         stopifnot(identical(status, 0L))' "$TMP" || cleanup_status=$?
      test ! -e "$TMP" || cleanup_status=1
      ;;
    *) cleanup_status=1 ;;
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
mkdir "$TMP/library"
R CMD INSTALL --library="$TMP/library" "$TARBALLS"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-012-prescribed-energy-repayment-pulse.R"
R_LIBS_USER="$TMP/library" Rscript --vanilla \
  "$REPO/experiments/rebuild-012-review-pack.R" \
  "$REPO/outputs/rebuild-012-prescribed-energy-repayment-pulse"
```

Do not run `R CMD check`. If a repair would require any protected package or
test change, stop and return for a separately authorized goal.

## 6. Final Scope And Review

Reconstruct frozen hashes and base state:

```zsh
set -euo pipefail
PACKET=docs/goals/rebuild-012-prescribed-energy-repayment-pulse
EXECUTION_BASE=d8c80a9ae088ab03022868e97eb5a6b943b3cf84
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

Require the exact twelve tracked paths and no protected changes:

```zsh
set -euo pipefail
EXECUTION_BASE=d8c80a9ae088ab03022868e97eb5a6b943b3cf84
EXPECTED_PATHS=$(cat <<'EOF'
README.md
docs/decisions/0012-prescribed-energy-repayment-pulse.md
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Goal.md
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Log.md
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Plan.md
docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Runbook.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-012-prescribed-energy-repayment-pulse.R
experiments/rebuild-012-review-pack.R
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

Require the exact output set, regularity, dimensions, and PNG geometry:

```zsh
set -euo pipefail
OUTPUT=outputs/rebuild-012-prescribed-energy-repayment-pulse
EXPECTED_OUTPUTS=$(cat <<'EOF'
figure-1-prescribed-energy-repayment-pulse.png
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
  identical(dim(table_1), c(97L, 7L)),
  identical(dim(table_2), c(8L, 16L)),
  identical(dim(table_3), c(5L, 10L)),
  identical(names(table_1), c(
    "elapsed_time_h",
    "boundary_phase",
    "cumulative_prescribed_input_contrast_kj",
    "gut_available_energy_contrast_kj",
    "body_energy_reserve_contrast_kj",
    "combined_system_energy_contrast_kj",
    "contrast_closure_residual_kj"
  )),
  identical(names(table_2), c(
    "sequence_id",
    "sequence_day",
    "forcing_phase",
    "daily_prescribed_dry_matter_intake_kg_dm",
    "total_prescribed_energy_input_kj",
    "total_assimilated_energy_kj",
    "total_maintenance_expenditure_kj",
    "total_routine_activity_expenditure_kj",
    "expected_body_energy_change_kj",
    "observed_body_energy_change_kj",
    "gut_available_energy_initial_kj",
    "gut_available_energy_final_kj",
    "body_energy_reserve_initial_kj",
    "body_energy_reserve_final_kj",
    "total_system_energy_initial_kj",
    "total_system_energy_final_kj"
  )),
  identical(names(table_3), c(
    "elapsed_time_h",
    "boundary_label",
    "cumulative_prescribed_input_contrast_kj",
    "gut_available_energy_contrast_kj",
    "expected_gut_contrast_kj",
    "gut_contraction_factor_from_previous_boundary",
    "body_energy_reserve_contrast_kj",
    "expected_body_complement_kj",
    "combined_system_energy_contrast_kj",
    "contrast_closure_residual_kj"
  )),
  identical(table_1$elapsed_time_h, 0:96),
  identical(table_2$sequence_id, c(
    rep("all_balanced_control", 4L),
    rep("shortfall_then_repayment", 4L)
  )),
  identical(table_2$sequence_day, rep(1:4, 2L)),
  identical(table_2$forcing_phase, c(
    rep("balanced", 4L),
    "shortfall",
    "prescribed_repayment_pulse",
    "return_to_reference",
    "return_to_reference"
  )),
  identical(table_3$elapsed_time_h, c(0L, 24L, 48L, 72L, 96L)),
  identical(table_3$boundary_label, c(
    "initial",
    "shortfall_day_close",
    "prescribed_repayment_pulse_day_close",
    "return_to_reference_day_1_close",
    "return_to_reference_day_2_close"
  ))
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
stopifnot(identical(
  png_dimensions(file.path(
    output,
    "figure-1-prescribed-energy-repayment-pulse.png"
  )),
  c(width = 1800L, height = 900L)
))
RS

test -z "$(find . -maxdepth 2 \
  \( -name '*.Rcheck' -o -name 'herbivoreTTR_*.tar.gz' \) -print)"
test -z "$(find /tmp -maxdepth 1 \
  -name 'rebuild012-smoke.*' -print)"
```

Independently reconstruct the retained arithmetic and recurrences. Obtain one
independent final audit of the scientific invariants, serialized evidence,
guards, figure, documentation, validation receipts, and Git scope. Resolve
only Critical or Important findings.

## 7. Publication Boundary

Stop with all Goal 012 work uncommitted and unstaged. Retain the ignored review
pack for Barry. Commit or push only with later explicit publication authority.
