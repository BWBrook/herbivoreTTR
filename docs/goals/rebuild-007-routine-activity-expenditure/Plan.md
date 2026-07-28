# Rebuild Goal 007: Routine-Activity Expenditure Plan

> **For agentic workers:** use native subagent-driven development for bounded,
> non-overlapping tasks. The orchestrator owns integration, scientific
> judgement, final validation, and acceptance.

## Goal

Add one explicit prescribed routine-activity expenditure schedule as an
incremental body-energy sink throughout the existing body and coupled runners,
prove its arithmetic with zero and pulse fixtures, and stop before ecological
activity timing.

## Architecture

Keep routine activity separate from fixed maintenance, assimilation, and gut
ingestion. Add a strict schedule record and require it in every body transition
and runner without a default. Propagate its rate, amount, and daily total
through existing ledgers while leaving all gut equations and gut-only burn-in
unchanged.

## Global Constraints

- R only; plain records and pure functions.
- Fixed one-hour transitions on integer `hour_of_day = 0:23`.
- Routine activity is prescribed, non-negative, and incremental to maintenance.
- No compatibility layer, hidden zero default, object system, or dependency.
- Existing callers migrate explicitly to a zero schedule.
- Generated review outputs remain ignored and uncommitted.
- One focused repair pass only for material defects.
- Goal 007 implementation remains uncommitted until separately authorized.

## Task 1: Freeze And Publish The Packet

**Files**

- Create and freeze `Goal.md`, `Plan.md`, and `Runbook.md`.
- Create and retain mutable `Log.md`.

**Outcome**

- Record the clean `d9c7567` Goal 006 baseline.
- Obtain independent scientific and repository-surface packet reviews.
- Freeze SHA-256 hashes.
- Commit and push only the four packet files.

## Task 2: Add The Activity Schedule Record

**Files**

- Create `R/routine-activity-expenditure-records.R`.
- Create `tests/testthat/test-routine-activity-expenditure.R`.
- Generate the constructor manual and NAMESPACE export.

**Interfaces**

```r
new_routine_activity_expenditure_schedule(
  hour_of_day,
  prescribed_routine_activity_expenditure_kj_h
)
```

**Outcome**

- Exact 24-row plain data frame.
- Strict clock, type, length, finiteness, non-negativity, attribute, and
  storage validation.
- Pure construction with no mutation.

## Task 3: Extend The Body Transition And Day Runner

**Files**

- Modify `R/body-energy-transition.R`.
- Modify `R/body-energy-run.R`.
- Modify body transition and body scenario tests.
- Regenerate their two manuals.

**Interfaces**

```r
step_body_energy(state, parameters, input_row, activity_row)

run_body_energy_day(
  initial_state,
  parameters,
  schedule,
  routine_activity_schedule
)
```

**Outcome**

- Enforce exact row-hour alignment.
- Subtract activity from body change and net rate.
- Record activity rate, amount, and daily total.
- Include activity in residuals and tolerances.
- Prove zero preservation, exact pulse loss, purity, strict failure, and
  negative-reserve propagation.

## Task 4: Extend Coupled And Reference Runners

**Files**

- Modify `R/gut-body-energy-run.R`.
- Modify `R/gut-body-energy-reference-cycle.R`.
- Modify `R/herbivoreTTR-package.R`.
- Modify coupled and reference-cycle tests.
- Regenerate their two manuals and the package manual.

**Outcome**

- Require and validate the activity schedule.
- Pass matching activity rows into each measured body transition.
- Keep gut-only burn-in free of activity.
- Expand coupled and measured ledgers.
- Include activity in body and whole-system accounting.
- Prove exact gut invariance and `-200/-400 kJ` pulse-control body differences.

## Task 5: Migrate Accepted Callers

**Files**

- Modify the two additional declared tests.
- Modify all eight declared Goal 002-006 experiment/review scripts.

**Outcome**

- Every existing caller constructs and passes an explicit zero-activity
  schedule.
- Goal 002-006 numerical trajectories remain unchanged on shared fields.
- No optional default or compatibility wrapper is introduced.

## Task 6: Add Goal 007 Evidence

**Files**

- Create `experiments/rebuild-007-routine-activity-expenditure.R`.
- Create `experiments/rebuild-007-review-pack.R`.
- Generate the exact five-file ignored review pack with the row counts,
  columns, and deterministic ordering declared in `Goal.md`.

**Outcome**

- The no-write experiment asserts and prints the complete zero/pulse contract.
- The review generator stages, validates, reads back, and atomically publishes
  its five declared files.
- The four-panel figure visibly demonstrates activity forcing, zero gut
  difference, body change, and cumulative body reserve.

## Task 7: Update Scientific Documentation

**Files**

- Add Decision 0007.
- Modify README, model charter, model specification, roadmap, variable
  dictionary, and Goal 007 Log.

**Outcome**

- Record the exact interface, equations, fields, diagnostics, limits, and
  Goal 008 discussion gate.
- Avoid BMR, NEAT, behaviour, locomotion, or empirical-realism claims.

## Task 8: Validate And Review

**Outcome**

- Parse all touched R files and every accepted experiment.
- Run focused and full structured test counts.
- Confirm synchronized `renv`.
- Run source and installed no-write experiments.
- Generate and inspect the exact review pack.
- Run guarded external build, install, and `R CMD check --no-manual`.
- Confirm exact scope, frozen hashes, protected paths, empty index, ignored
  outputs, and no temporary residue.
- Obtain one independent final scientific/evidence review.
- Record the complete uncommitted closeout in Log.md.

## Publication Boundary

Packet publication is part of authorized execution. Goal 007 implementation
publication is not. Stop with the reviewed implementation uncommitted and the
ignored review pack retained for Barry.
