# Rebuild Goal 006 Plan

## Goal

Establish a minimally plausible day-resting ecological reference and compare
its within-day trajectories with the energy-matched mathematical reference,
using the accepted Goal 004-005 functions unchanged.

## Architecture

Goal 006 adds a durable scenario and evidence layer only:

```text
two explicit dry-matter schedules
  -> unchanged Goal 004 food-energy conversion
  -> unchanged Goal 005 reference-cycle runner
  -> focused regression, no-write experiment, and compact review pack
```

There is no production-code task.

## Global Constraints

- R only, using existing base R records, data frames, and plotting.
- Mathematical schedule: 0.010 kg DM h^-1 and 100 kJ h^-1 in all 24 intervals.
- Ecological schedule: zero intake in hours 8:15 and 0.015 kg DM h^-1 or
  150 kJ h^-1 in hours 0:7 and 16:23.
- Both schedules total 0.24 kg DM and 2400 kJ per day.
- Preserve all Goal 001-005 functions, tests, schemas, equations, and
  tolerances.
- No new dependency, package API, state, mechanism, or generalized scenario
  framework.
- Generated review files stay ignored and uncommitted.
- One focused self-review and one independent final review; repair only
  material findings.
- No implementation or publication without separate authority.

## Task 1: Lock The Two Reference Fixtures

- [ ] Add one focused test file without changing any existing test.
- [ ] Construct both dry-matter schedules explicitly.
- [ ] Derive both energy schedules through the Goal 004 converter.
- [ ] Verify exact interval identities and switch boundaries, dry-matter totals
  within the declared floating tolerance, and exact 2400 kJ energy totals.
- [ ] Run both through the unchanged Goal 005 reference-cycle function.
- [ ] Independently reconstruct the existing cycle and ledger tolerances.
- [ ] Verify convergence, repetition, carry-over, feasible body paths, and
  daily neutrality.
- [ ] Verify equal daily totals using summed scenario-specific tolerances.
- [ ] Verify the declared trajectory-distinctness inequalities, phase
  landmarks, and whole-kJ magnitude bands.
- [ ] Treat any failure as evidence to diagnose rather than a missing-API red
  phase.

Outcome: both references are durable regression fixtures over accepted
production behavior.

## Task 2: Add The No-Write Scientific Demonstration

- [ ] Add one thin experiment using only exported package functions.
- [ ] Repeat the focused checks independently in memory.
- [ ] Print exact schedule totals and compact convergence summaries.
- [ ] Print two-day daily energy summaries using whole-kJ human display.
- [ ] Print the 08:00 and 16:00 switch checkpoints.
- [ ] Report gut, assimilation, and body trajectory contrasts plus their phase
  landmarks.
- [ ] Write no file and mutate no supplied object.

Outcome: the reference distinction can be inspected without generated output.

## Task 3: Generate A Compact Review Pack

- [ ] Add one guarded base-R review script.
- [ ] Generate the exact five declared files through temporary staging.
- [ ] Produce one four-panel 0-48 hour comparison figure.
- [ ] Mark the repeated rest-closed blocks and the 24-hour day boundary.
- [ ] Write the exact input, convergence, daily, and hourly table schemas.
- [ ] Preserve sufficient numeric precision and verify CSV read-back.
- [ ] Reject symbolic links, undeclared entries, and partial publication.
- [ ] Keep accepted Goal 005 evidence code unchanged.

Outcome: Barry can inspect the schedule, convergence, daily accounting, and
within-day trajectory contrast directly.

## Task 4: Record The Reference Doctrine

- [ ] Add Decision 0006.
- [ ] Define mathematical and ecological reference roles.
- [ ] Document the exact clock intervals and prescribed rates.
- [ ] State that the schedule is prescribed intake, not modeled behavior.
- [ ] Record the accounting interpretation and prohibited biological claims.
- [ ] Update only README, model charter, model specification, roadmap, and the
  mutable Goal 006 log.
- [ ] Leave the variable dictionary and all package documentation unchanged.

Outcome: later goals can use the two references without confusing diagnosis
with ecological interpretation.

## Task 5: Validate, Review, And Stop

- [ ] Run parse checks, the focused tests, and the full suite.
- [ ] Require zero failures, warnings, errors, and skips.
- [ ] Confirm the full suite exceeds the 812-pass Goal 005 baseline.
- [ ] Confirm all production, API, manual, dependency, and prior-test paths are
  unchanged.
- [ ] Confirm synchronized `renv` and clean whitespace.
- [ ] Run the experiment from source and a temporary installed package.
- [ ] Run guarded build, install, and `R CMD check --no-manual`.
- [ ] Generate, read back, and inspect the exact review pack.
- [ ] Review the complete diff, output files, and Git state.
- [ ] Obtain one independent final review.
- [ ] Perform at most one material repair pass.
- [ ] Stop with an uncommitted implementation closeout for Barry.

Outcome: Goal 006 either establishes the ecological reference cleanly or stops
with one explicit material blocker.

## Publication Boundary

This formulation does not authorize implementation, staging, committing, or
pushing. After packet approval, publish the packet separately and capture that
clean commit as the execution baseline. Goal 006 implementation remains
uncommitted and unpushed until Barry reviews the completed evidence and grants
publication authority.
