# Rebuild Goal 002 Plan

## Goal

Implement and interrogate one maintenance-only, 24-hour body-energy ledger with
prescribed already-assimilated energy, then stop before the gut.

## Global Constraints

- R only; base R data frames and plain named lists.
- No new runtime or development dependency.
- Pure functions; no hidden mutation or object-oriented framework.
- One-hour transitions only; no configurable time step.
- Direct kJ arithmetic; no dynamic body mass; scenario mass is metadata only.
- No persistent generated output.
- No commit or push without explicit authority.
- Stop on any validation failure or scope expansion.

## Planned File Surface

The completed Goal 002 review footprint may contain only:

```text
DESCRIPTION
NAMESPACE
R/herbivoreTTR-package.R
R/body-energy-records.R
R/body-energy-transition.R
R/body-energy-run.R
README.md
docs/decisions/0002-ledger-before-gut.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-002-body-energy-ledger.R
man/herbivoreTTR-package.Rd
man/new_body_energy_state.Rd
man/new_body_energy_parameters.Rd
man/new_assimilated_energy_schedule.Rd
man/step_body_energy.Rd
man/run_body_energy_day.Rd
tests/testthat/test-body-energy-records.R
tests/testthat/test-body-energy-transition.R
tests/testthat/test-body-energy-scenarios.R
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Goal.md
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Plan.md
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Runbook.md
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Log.md
```

During implementation, `Goal.md`, `Plan.md`, and `Runbook.md` are frozen
read-only control surfaces identified by the SHA-256 values approved by Barry.
Only `Log.md` may be updated within the goal directory.

`renv.lock`, data directories, output directories, legacy material, release
configuration, and unrelated documentation are outside scope. Roxygen may
regenerate only the declared `NAMESPACE` and `man/` files.

## Task 1: Lock The Ledger Contract In Tests

- [ ] Add failing tests for the exact state, parameter, and schedule records.
- [ ] Add failing tests for hourly timing, continuity, conservation, purity,
  and the negative-reserve boundary.
- [ ] Add failing tests for exact neutral, deficit, and surplus outcomes and
  exact hourly/daily schemas.
- [ ] Parse every new test before running it, then inspect the structured
  failures and call stacks. Accept the red phase only when every failure is the
  expected absent interface or unmet declared contract, with no setup error,
  unexpected warning, or skip. Stop on malformed tests or missing dependencies.

Outcome: executable acceptance criteria exist before model code.

## Task 2: Implement Validated Plain Records

- [ ] Implement `new_body_energy_state()` and
  `new_body_energy_parameters()` as strict plain-list constructors.
- [ ] Implement `new_assimilated_energy_schedule()` for exactly 24 ordered
  hourly inputs.
- [ ] Use concise field-specific failures; do not add a validation framework or
  custom object system.
- [ ] Make the record test file pass without implementing transitions.

Outcome: state, parameters, and prescribed inputs are distinct and validated.

## Task 3: Implement One Pure Hourly Transition

- [ ] Implement the fixed one-hour arithmetic and scale-aware tolerance.
- [ ] Accept exactly one validated two-column schedule row and return the exact
  nested `state` and `fluxes` structure declared in `Goal.md`.
- [ ] Reject every proposed closing reserve below zero without tolerance or
  clipping.
- [ ] Demonstrate no mutation and exact hourly conservation.
- [ ] Make the transition test file pass.

Outcome: one transition can be inspected and calculated independently.

## Task 4: Implement The Daily Runner And Summary

- [ ] Implement `run_body_energy_day()` as exactly 24 sequential transitions with
  the accepted `[h, h + 1)` convention.
- [ ] Derive the returned daily summary solely from the hourly ledger.
- [ ] Produce the exact schemas and `neutral`, `deficit`, or `surplus` status.
- [ ] Make the scenario test file pass for 0, -240, and +240 kJ daily change,
  plus the accepted variable-input fixtures.

Outcome: the first executable model layer closes over a complete day.

## Task 5: Expose One Thin Demonstration

- [ ] Add a thin experiment that constructs the three accepted fixtures using
  package functions, asserts the expected values in memory, and prints only
  their daily summaries to stdout.
- [ ] Generate the declared function documentation and exports.
- [ ] Update package metadata and current-capability prose without claiming
  empirical realism.
- [ ] Update the model charter, specification, variable dictionary, and roadmap
  so the gut is the next separately approved layer.
- [ ] Add the ledger-before-gut decision record.

Outcome: an ecologist can inspect the model contract, run three transparent
cases, and see exactly what is and is not yet represented.

## Task 6: Validate And Review

- [ ] Run the three focused test files and the full test suite.
- [ ] Run the thin experiment and verify the exact daily outcomes.
- [ ] Verify synchronized `renv` without changing the lockfile.
- [ ] Run external `R CMD build` and `R CMD check --no-manual` in a guarded
  temporary directory and remove it.
- [ ] Verify the exact changed-path whitelist across tracked and untracked
  files, clean complete diff, absent outputs, and no changed legacy path.
- [ ] Do not inspect or compare the ignored legacy tree during execution.
- [ ] Obtain independent scientific-contract and code/diff reviews.
- [ ] Resolve all Critical and Important findings, rerun affected validation,
  and present the uncommitted closeout for Barry's decision.

Outcome: Goal 002 is either demonstrably complete within scope or stopped with
one exact unresolved issue. No gut work begins.
