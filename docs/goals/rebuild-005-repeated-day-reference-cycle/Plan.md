# Rebuild Goal 005 Plan

## Goal

Add one repeated-day reference-cycle runner that spins up the existing gut
under identical daily forcing, resets body energy once, and records two
measured days without changing any implemented biological process.

## Architecture

The new function is temporal orchestration over the existing pure transitions
and one-day runner:

```text
Goal 004 food conversion
  -> existing Goal 003 energy schedule
  -> gut-only repeated-day burn-in
  -> one body reset at measurement start
  -> existing Goal 003 daily runner, twice
```

The existing body, gut, and food functions remain unchanged.

## Global Constraints

- R only, with base R records, data frames, and plotting.
- Identical 24-hour forcing on every burn-in and measured day.
- Convergence compares hour-matched gut boundary trajectories.
- Burn-in advances no body state.
- Body resets once before measurement and carries forward thereafter.
- Exactly two measured days.
- Preserve full internal precision and whole-kJ human display.
- No new dependency, biological mechanism, or generalized simulation engine.
- Generated review files stay ignored and uncommitted.
- One focused self-review and one independent final review; repair only
  material findings.
- No implementation or publication without separate authority.

## Task 1: Lock The Reference-Cycle Contract In Tests

- [ ] Create the focused test file before production source.
- [ ] Test exact argument validation and return schemas.
- [ ] Test gut-only burn-in from an empty and a non-equilibrium state.
- [ ] Test scale-aware successive-trajectory and day-boundary convergence.
- [ ] Reject non-finite realized scales or tolerances before comparison.
- [ ] Test maximum-day failure.
- [ ] Test that no supplied object is mutated.
- [ ] Accept a red phase only for the absent declared function.

Outcome: temporal semantics are executable before implementation.

## Task 2: Implement Gut Burn-In And Two-Day Measurement

- [ ] Repeat `step_gut_energy()` over the unchanged schedule.
- [ ] Record the seven-column convergence table.
- [ ] Stop at the first successful successive-day comparison.
- [ ] Reset body to `measurement_body_state` once.
- [ ] Run two direct Goal 003 days with exact state carry-over.
- [ ] Return only `convergence`, `hourly`, and `daily`.
- [ ] Propagate existing body-boundary errors without a partial result.

Outcome: the package can construct a measured daily reference cycle without
adding biology.

## Task 3: Demonstrate The Three Fixtures

- [ ] Compose every energy schedule through the Goal 004 food bridge.
- [ ] Demonstrate zero-intake gut stability with body deficit.
- [ ] Demonstrate constant-intake fixed-point neutrality.
- [ ] Demonstrate concentrated late-feeding periodicity and neutrality.
- [ ] Require equal daily totals for the energy-matched schedules.
- [ ] Require distinct within-day trajectories for those schedules.
- [ ] Verify both measured body paths remain feasible at the declared reserve.
- [ ] Prove each measured day is an unchanged Goal 003 runner result.

Outcome: stability, neutrality, and timing are separated cleanly.

## Task 4: Add Documentation And Compact Review Outputs

- [ ] Add one thin no-write experiment with in-memory assertions.
- [ ] Add one base-R review script that writes the five declared ignored files.
- [ ] Generate two legible figures and three auditable tables.
- [ ] Document reset semantics, convergence meaning, conditional timing
  equivalence, and exclusions.
- [ ] Generate only the declared export and manual updates.

Outcome: Barry can inspect both convergence and measured trajectories directly.

## Task 5: Validate, Review, And Stop

- [ ] Run the focused tests and full suite with structured counts.
- [ ] Require zero failures, warnings, and skips.
- [ ] Confirm all Goal 001-004 source and tests are unchanged.
- [ ] Confirm synchronized `renv` and no dependency change.
- [ ] Run source and installed-package experiments.
- [ ] Run external build, installation, and package check.
- [ ] Generate and inspect the review pack.
- [ ] Review the complete diff, outputs, and Git state.
- [ ] Obtain one independent final review.
- [ ] Perform at most one material repair pass.
- [ ] Stop with an uncommitted implementation closeout for Barry.

Outcome: Goal 005 either satisfies its single temporal question or stops with
one explicit material blocker.

## Publication Boundary

This formulation does not authorize implementation, staging, committing, or
pushing. After packet approval, publish the packet separately and capture that
clean commit as the execution baseline. Goal 005 implementation remains
uncommitted and unpushed until Barry reviews the completed evidence and grants
publication authority.
