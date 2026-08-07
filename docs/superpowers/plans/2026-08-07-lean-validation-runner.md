# Lean Validation Runner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace representation-sensitive validation and repeated hourly wrapper work with semantic public validation and private scalar transition cores, without changing scientific behavior or outputs.

**Architecture:** Public constructors, steps, day runners, and the reference-cycle runner validate complete inputs semantically. Public steps delegate to two private scalar cores; validated runners index canonical vectors and call those cores directly while retaining the visible gut-then-body order and existing accounting.

**Tech Stack:** Base R package code, `testthat` edition 3, roxygen-style source comments, Git.

## Global Constraints

- Preserve every public function name/signature, equation, transition order, forcing convention, conservation check/tolerance, result schema, column order, row count, and canonical output type.
- Accept scientifically equivalent integer/double values and harmless names, row names, class/metadata, and attribute ordering; reject character, logical, complex, factor, fractional discrete, non-finite, negative, and other lossy values.
- Require exact scientific fields/cardinality: one-field records, 24-row schedules, one-row step inputs, ordered hours numerically equal to `0:23`, and numerically matching coupled hours.
- Keep gut release-before-ingestion, body input-minus-maintenance-minus-activity, reserve feasibility, and gut/body/system conservation unchanged; never clip invalid closing stocks.
- Add no ecology, configuration, generic engine, OO layer, compatibility path, dependency, experiment change, release machinery, or committed generated artefact.
- Perform one focused repair pass after the core gates; do not run `R CMD build` or `R CMD check`, and do not push.

---

## File And Interface Map

- Record semantics: `R/body-energy-records.R`, `R/gut-energy-records.R`, `R/food-energy-records.R`, `R/food-energy-conversion.R`, `R/routine-activity-expenditure-records.R`.
- Transition boundary/core separation: `R/body-energy-transition.R`, `R/gut-energy-transition.R`.
- Validate-once orchestration: `R/body-energy-run.R`, `R/gut-body-energy-run.R`, `R/gut-body-energy-reference-cycle.R`.
- Focused tests: `tests/testthat/test-body-energy-records.R`, `test-gut-energy-records.R`, `test-food-energy-records.R`, `test-food-energy-conversion.R`, `test-body-energy-transition.R`, `test-gut-energy-transition.R`, `test-body-energy-scenarios.R`, `test-gut-body-energy-scenarios.R`, `test-gut-body-energy-reference-cycle.R`, and `test-routine-activity-expenditure.R`.
- Documentation, only when wording is representation-specific: the matching roxygen parameter text plus `man/new_assimilated_energy_schedule.Rd`, `man/new_dry_matter_intake_schedule.Rd`, `man/new_ingested_available_energy_schedule.Rd`, `man/new_routine_activity_expenditure_schedule.Rd`, `man/derive_ingested_available_energy_schedule.Rd`, `man/step_body_energy.Rd`, `man/step_gut_energy.Rd`, `man/run_body_energy_day.Rd`, `man/run_gut_body_energy_day.Rd`, and `man/run_gut_body_energy_reference_cycle.Rd`.
- New private interfaces: `.step_gut_energy_core(gut_available_energy_start_kj, gut_release_fraction_h, prescribed_ingested_available_energy_kj_h)` and `.step_body_energy_core(body_energy_reserve_start_kj, maintenance_expenditure_kj_h, prescribed_assimilated_energy_kj_h, prescribed_routine_activity_expenditure_kj_h)` return the existing nested `state`/`fluxes` lists.
- Shared coupled interface: `.run_gut_body_energy_day_prevalidated(initial_gut_energy_kj, initial_body_energy_kj, gut_release_fraction_h, maintenance_expenditure_kj_h, hour_of_day, ingested_energy_kj_h, routine_activity_kj_h)` returns the existing `hourly`/`daily` list and is called only after public validation.

### Task 1: Semantic Validators And Record/Converter Tests

**Files:** Modify the five record/conversion R files and their five focused test files named above.

**Interfaces:** Produce `.is_semantic_numeric_vector(value)`, `.has_exact_named_fields(value, required_names)`, semantic scalar/hour/schedule predicates, and losslessly canonical constructor outputs (`hour_of_day` integer; rates double). Existing validator names remain callable by later tasks.

- [ ] **Step 1: Add failing semantic-contract tests.** Cover integer/double hours and values plus custom row names/metadata as accepted; cover missing/extra fields, wrong lengths/dimensions, unordered/fractional hours, character, logical, complex, factor, non-finite, and negative values as rejected with argument/field-specific errors and `call. = FALSE`.

```r
test_that("converter accepts equivalent numeric storage and harmless metadata", {
  parameters <- structure(list(metabolizable_energy_density_kj_kg_dm = 10L), source = "test")
  schedule <- data.frame(hour_of_day = as.double(0:23), prescribed_dry_matter_intake_kg_dm_h = rep(2L, 24L), row.names = paste0("h", 0:23))
  result <- derive_ingested_available_energy_schedule(parameters, schedule)
  expect_identical(result$hour_of_day, 0:23)
  expect_identical(result$prescribed_ingested_available_energy_kj_h, rep(20, 24L))
  schedule$prescribed_dry_matter_intake_kg_dm_h <- factor(rep("2", 24L))
  expect_error(derive_ingested_available_energy_schedule(parameters, schedule), "numeric")
})
```

- [ ] **Step 2: Run the focused tests and confirm they fail on exact storage/attribute policing.**

Run: `Rscript -e 'testthat::test_local(filter = "body-energy-records|gut-energy-records|food-energy-records|food-energy-conversion|routine-activity-expenditure")'`
Expected: FAIL only on newly accepted semantic equivalents or new semantic messages.

- [ ] **Step 3: Implement minimal shared predicates and update field/container validators.** Preserve constructor return shapes while replacing `identical(attributes())`, exact `typeof()`, and bare-vector requirements.

```r
.is_semantic_numeric_vector <- function(value) {
  typeof(value) %in% c("integer", "double") && !is.factor(value) && is.null(dim(value))
}
.has_exact_named_fields <- function(value, required_names) {
  is.list(value) && length(value) == length(required_names) &&
    !anyDuplicated(names(value)) && setequal(names(value), required_names)
}
.is_whole_number <- function(value) {
  .is_semantic_numeric_vector(value) && all(is.finite(value)) && all(value == floor(value))
}
```

- [ ] **Step 4: Re-run the focused command; expect PASS, then commit.**

Run: `git add R/body-energy-records.R R/gut-energy-records.R R/food-energy-records.R R/food-energy-conversion.R R/routine-activity-expenditure-records.R tests/testthat/test-body-energy-records.R tests/testthat/test-gut-energy-records.R tests/testthat/test-food-energy-records.R tests/testthat/test-food-energy-conversion.R tests/testthat/test-routine-activity-expenditure.R && git commit -m "refactor: validate energy records semantically"`

### Task 2: Private Scalar Cores And Public Wrappers

**Files:** Modify `R/body-energy-transition.R`, `R/gut-energy-transition.R`, `tests/testthat/test-body-energy-transition.R`, and `tests/testthat/test-gut-energy-transition.R`.

**Interfaces:** Consume Task 1 predicates. Produce the two private core signatures in the map; keep `step_body_energy(state, parameters, input_row, activity_row)` and `step_gut_energy(state, parameters, input_row)` unchanged as validating wrappers.

- [ ] **Step 1: Update transition tests first.** Retain direct equation, release-before-ingestion, schema, finite-arithmetic, negative-close, mutation, and hourly-conservation assertions; add integer/double, harmless metadata, and numeric hour equality acceptance; reject mismatched hours and every lossy type.
- [ ] **Step 2: Run `Rscript -e 'testthat::test_local(filter = "body-energy-transition|gut-energy-transition")'`; expect FAIL because the cores do not exist and wrappers still enforce representation identity.**
- [ ] **Step 3: Extract body lines 32-86 and gut lines 22-78 from the current files into the named private cores without reordering any expression or safeguard; make wrappers validate, extract, and call exactly once.**

```r
step_gut_energy <- function(state, parameters, input_row) {
  .validate_gut_energy_state(state); .validate_gut_energy_parameters(parameters)
  .validate_ingested_available_energy_input_row(input_row)
  .step_gut_energy_core(as.double(state$gut_available_energy_kj), as.double(parameters$gut_release_fraction_h), as.double(input_row$prescribed_ingested_available_energy_kj_h))
}
step_body_energy <- function(state, parameters, input_row, activity_row) {
  .validate_body_energy_state(state); .validate_body_energy_parameters(parameters)
  .validate_assimilated_energy_input_row(input_row); .validate_routine_activity_expenditure_input_row(activity_row)
  if (as.double(input_row$hour_of_day) != as.double(activity_row$hour_of_day)) stop("`activity_row$hour_of_day` must match `input_row$hour_of_day`.", call. = FALSE)
  .step_body_energy_core(as.double(state$body_energy_reserve_kj), as.double(parameters$maintenance_expenditure_kj_h), as.double(input_row$prescribed_assimilated_energy_kj_h), as.double(activity_row$prescribed_routine_activity_expenditure_kj_h))
}
```

- [ ] **Step 4: Re-run the transition command; expect PASS, then run `git add R/body-energy-transition.R R/gut-energy-transition.R tests/testthat/test-body-energy-transition.R tests/testthat/test-gut-energy-transition.R && git commit -m "refactor: separate validated energy transition cores"`.**

### Task 3: Validate-Once Day And Reference Runners

**Files:** Modify the three runner R files and `test-body-energy-scenarios.R`, `test-gut-body-energy-scenarios.R`, `test-gut-body-energy-reference-cycle.R`, and the runner sections of `test-routine-activity-expenditure.R`.

**Interfaces:** Consume both scalar cores; produce the mapped prevalidated coupled helper. Public runners validate each complete input once, canonicalize validated vectors losslessly, and never construct one-row schedules or call public step wrappers inside loops.

- [ ] **Step 1: Add/adjust tests for semantic public inputs, exact schemas/types, trajectories, continuity, summaries, transition order, negative reserve, all conservation contexts, reference convergence/burn-in/body reset/carry-over, and equality with direct day runs.**
- [ ] **Step 2: Run `Rscript -e 'testthat::test_local(filter = "body-energy-scenarios|gut-body-energy-scenarios|gut-body-energy-reference-cycle|routine-activity-expenditure")'`; expect FAIL on newly accepted input forms and validate-once instrumentation.**
- [ ] **Step 3: Replace body loop lines 54-79 with direct `.step_body_energy_core()` calls. Extract coupled loop lines 40-199 into `.run_gut_body_energy_day_prevalidated()`, retaining gut-core then body-core order and lines 115-155 system accounting; leave `.summarize_gut_body_energy_day()` equations unchanged.**

```r
gut_transition <- .step_gut_energy_core(current_gut_energy_kj, gut_release_fraction_h, ingested_energy_kj_h[[row_index]])
body_transition <- .step_body_energy_core(current_body_energy_kj, maintenance_expenditure_kj_h, gut_transition$fluxes$assimilated_energy_kj_h, routine_activity_kj_h[[row_index]])
```

- [ ] **Step 4: In the reference runner, accept numeric whole `max_burn_in_days >= 2`, use the gut core directly in current lines 200-232, and call the prevalidated coupled helper for both measured days while preserving current lines 234-286 comparison and 319-330 assembly.**
- [ ] **Step 5: Re-run the targeted command; expect PASS, then run `git add R/body-energy-run.R R/gut-body-energy-run.R R/gut-body-energy-reference-cycle.R tests/testthat/test-body-energy-scenarios.R tests/testthat/test-gut-body-energy-scenarios.R tests/testthat/test-gut-body-energy-reference-cycle.R tests/testthat/test-routine-activity-expenditure.R && git commit -m "refactor: validate energy runners once"`.**

### Task 4: Prune Representation Tests, Numerical Fixture, Documentation, And Gates

**Files:** Audit only the ten focused tests in the map; update only the ten listed Rd files and their matching roxygen lines when they still say plain/exact/bare/integer-only input. Do not edit README, model docs, experiments, or generated evidence.

**Interfaces:** No new runtime interface. Preserve output identity tests; delete only assertions whose sole purpose is rejecting equivalent storage, row names, harmless attributes/order, or container subclass metadata.

- [ ] **Step 1: Create a disposable pre-refactor worktree and capture the same canonical fixture before and after.**

Run: `git worktree add --detach /tmp/herbivoreTTR-validation-before "$(git rev-list -1 HEAD -- docs/superpowers/specs/2026-08-07-lean-validation-runner-design.md)"`
Create `/tmp/herbivoreTTR-validation-fixture.R` with this uncommitted script:

```r
for (path in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) sys.source(path, envir = .GlobalEnv)
hours <- 0:23
gut_state <- new_gut_energy_state(400); body_state <- new_body_energy_state(10000)
gut_parameters <- new_gut_energy_parameters(0.25); body_parameters <- new_body_energy_parameters(100)
ingestion <- new_ingested_available_energy_schedule(hours, rep(100, 24L))
assimilation <- new_assimilated_energy_schedule(hours, rep(100, 24L))
activity <- new_routine_activity_expenditure_schedule(hours, rep(0, 24L))
fixture <- list(
  gut_step = step_gut_energy(gut_state, gut_parameters, ingestion[1L, , drop = FALSE]),
  body_step = step_body_energy(body_state, body_parameters, assimilation[1L, , drop = FALSE], activity[1L, , drop = FALSE]),
  body_day = run_body_energy_day(body_state, body_parameters, assimilation, activity),
  coupled_day = run_gut_body_energy_day(gut_state, body_state, gut_parameters, body_parameters, ingestion, activity),
  reference_cycle = run_gut_body_energy_reference_cycle(new_gut_energy_state(0), body_state, gut_parameters, body_parameters, ingestion, activity, 1e-10, 100L)
)
saveRDS(fixture, Sys.getenv("FIXTURE_OUT"))
```

Run: `(cd /tmp/herbivoreTTR-validation-before && FIXTURE_OUT=/tmp/herbivoreTTR-validation-before.rds Rscript /tmp/herbivoreTTR-validation-fixture.R)`
Run: `FIXTURE_OUT=/tmp/herbivoreTTR-validation-after.rds Rscript /tmp/herbivoreTTR-validation-fixture.R`
Expected: two untracked RDS files under `/tmp`; `git status --short` contains neither.

- [ ] **Step 2: Compare numerical values and exact recursive schemas.**

```r
before <- readRDS("/tmp/herbivoreTTR-validation-before.rds"); after <- readRDS("/tmp/herbivoreTTR-validation-after.rds")
schema <- function(x) list(typeof = typeof(x), class = class(x), names = names(x), dim = dim(x), row.names = if (is.data.frame(x)) row.names(x) else NULL, children = if (is.list(x)) lapply(x, schema) else NULL)
stopifnot(identical(schema(before), schema(after)))
comparison <- all.equal(before, after, tolerance = 1e-12, check.attributes = FALSE)
if (!isTRUE(comparison)) stop(paste(comparison, collapse = "\n"), call. = FALSE)
```

- [ ] **Step 3: Run final gates exactly once.**

Run: `Rscript -e 'for (path in sort(list.files("R", pattern = "\\.[Rr]$", full.names = TRUE))) parse(path)'` -> no output/error.
Run: `Rscript -e 'testthat::test_local(filter = "records|conversion|transition|scenarios|routine-activity|reference-cycle")'` -> PASS.
Run: `Rscript -e 'testthat::test_local()'` -> PASS with zero failures.
Run: `git diff --check` -> no output; `git status --short` -> only intended R, test, and narrow Rd edits.

- [ ] **Step 4: Perform one focused repair pass for semantic, numerical, schema, or documentation defects found by those gates; rerun only the gate tied to a material repair, run `git worktree remove /tmp/herbivoreTTR-validation-before`, stage only the audited R/test/Rd paths from the map, and commit with `git commit -m "test: prune representation-only validation checks"`. Do not push.**
