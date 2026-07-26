# Rebuild Goal 003 Plan

## Goal

Add one first-order gut-energy stock between controlled prescribed ingestion
and the accepted Goal 002 body-energy ledger, then demonstrate its equilibrium,
initialization transient, and pulse response.

## Global Constraints

- R only; base R data frames and exact plain named lists.
- No new runtime or development dependency.
- Fixed one-hour transitions only.
- Release uses opening gut stock; current-hour ingestion cannot release until
  the next transition.
- Gut energy is an assimilable-energy equivalent with no digestive loss.
- Reuse the existing body transition without changing its interface or
  equations.
- No persistent generated output inside the repository.
- No implementation, commit, or push without explicit authority.
- Stop on validation failure, changed scope, or scientific ambiguity.

## Planned File Responsibilities

```text
R/gut-energy-records.R
  strict gut state, parameter, and ingestion-schedule constructors

R/gut-energy-transition.R
  one pure opening-stock gut transition and accounting check

R/gut-body-energy-run.R
  24-hour orchestration through gut and existing body transitions

tests/testthat/test-gut-energy-records.R
  exact record and schedule contract

tests/testthat/test-gut-energy-transition.R
  transition order, recurrence, conservation, and purity

tests/testthat/test-gut-body-energy-scenarios.R
  integrated fixtures, schemas, boundaries, and Goal 002 regression

experiments/rebuild-003-one-pool-gut-buffer.R
  in-memory analytical assertions and compact stdout summaries

experiments/rebuild-003-review-pack.R
  exact external figures, tables, provenance metadata, and file manifest

docs and generated man files
  implemented meaning, variables, decision, exports, and remaining exclusions
```

The complete required 27-path set is declared in `Goal.md`. Every path must be
present at closeout, with no extra path. Goal 002 source, tests, and packet
files remain unchanged.

## Task 1: Lock The Gut Record Contract In Tests

- [ ] Create the record test file before production code.
- [ ] Test exact state and parameter list names, plain containers, finite
  numeric storage, non-negative gut stock, and release fraction in `(0, 1]`.
- [ ] Test the exact 24-row ingestion schedule, ordered hours, double energy
  storage, and rejection of malformed or attributed values.
- [ ] Parse the test file, run the focused red phase, and accept only failures
  caused by the absent declared interfaces.

Outcome: the new model inputs have an executable, fail-fast contract.

## Task 2: Implement One Pure Gut Transition

- [ ] Add the three strict constructors with the smallest local validation
  helpers needed.
- [ ] Make the record tests pass before adding the transition.
- [ ] Add transition tests for opening-stock release, the one-hour delay,
  finite non-negative closing stock, purity, and exact gut conservation.
- [ ] Implement `step_gut_energy()` with the exact return structure in
  `Goal.md`.
- [ ] Make the transition tests pass.

Outcome: one gut transition can be calculated and inspected independently.

## Task 3: Couple Gut Release To The Existing Body Ledger

- [ ] Add integrated tests before the runner.
- [ ] Implement `run_gut_body_energy_day()` as 24 sequential gut transitions
  whose release rate is passed into the unchanged `step_body_energy()`.
- [ ] Derive hourly and daily results from returned transitions without hidden
  state or duplicate body arithmetic.
- [ ] Enforce exact gut, body, and whole-system accounting and schemas.
- [ ] Demonstrate continuity, purity, and propagation of body boundary errors.

Outcome: the first coupled internal stock-flow model closes over one day.

## Task 4: Demonstrate The Three Analytical Fixtures

- [ ] Implement exact tests for the equilibrium reference.
- [ ] Implement the empty-gut recurrence and closing-stock identity.
- [ ] Implement the single-pulse delay and geometric release sequence.
- [ ] Add the thin experiment with in-memory assertions and stdout only.
- [ ] Preserve every Goal 002 test and analytical outcome.

Outcome: equilibrium, initialization, and buffering behavior are explicit and
independently predictable.

## Task 5: Document The Implemented Layer

- [ ] Add roxygen documentation and generate only declared `NAMESPACE` and
  `man/` changes.
- [ ] Update `DESCRIPTION`, package prose, README, model charter,
  specification, dictionary, and roadmap.
- [ ] Add the opening-stock release decision record.
- [ ] State clearly that energy equivalence, release fraction, and fixture
  values are synthetic and that no food quality or digestive loss exists.

Outcome: an ecologist can distinguish implemented storage and delay from all
deferred biological detail.

## Task 6: Validate, Review, And Stop

- [ ] Run the three focused test files and the full suite.
- [ ] Require each focused test context to contain at least one passing
  expectation and zero failures, warnings, or skips; require the full suite to
  retain at least the 239 published Goal 002 expectations.
- [ ] Run the thin experiment and verify its exact analytical checkpoints.
- [ ] Confirm synchronized `renv` without changing `renv.lock`.
- [ ] Run external build, temporary-library install, experiment, and
  `R CMD check --no-manual`.
- [ ] Require equality to the exact 27-path implementation set, then review the
  complete diff, whitespace, absent repository outputs, clean index, and
  unchanged Goal 002 files.
- [ ] Run the declared review-pack generator and verify its exact eight-file
  set, table schemas and row counts, source hashes, artifact manifest, visual
  rendering, and unchanged source-repository status fingerprint.
- [ ] Require a nonsymlink review root and byte-identical repository-relative
  source manifests before build, immediately before generation, after
  generation, and inside the generated pack.
- [ ] Perform one focused parent review and obtain one independent final
  scientific/code review.
- [ ] Repair only material findings, rerun affected checks, and stop with an
  uncommitted closeout for Barry.

Outcome: Goal 003 is either complete within its narrow contract or stopped with
one explicit material issue. No later gut, food, activity, or plant layer
begins.
