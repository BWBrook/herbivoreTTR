# Rebuild Goal 004 Plan

## Goal

Add one pure conversion from prescribed dry-matter intake and fixed
dry-matter-basis metabolizable-energy density to the existing Goal 003 gut
available-energy schedule.

## Architecture

The new layer is strictly upstream and compositional. One exact parameter
record and one exact 24-hour intake schedule are validated independently. A
pure converter multiplies them elementwise and returns the existing
`new_ingested_available_energy_schedule()` result. Existing gut and body
functions remain unchanged.

## Global Constraints

- R only; base R data frames and exact plain named lists.
- No new runtime or development dependency.
- Fixed 24-hour schedule with one-hour rates.
- Dry-matter intake in kg DM h^-1.
- Metabolizable-energy density in kJ kg^-1 DM and strictly positive.
- Density is already metabolizable; no explicit digestive loss or efficiency.
- Preserve full internal precision; round only human-facing energy amounts and
  stocks.
- No new dynamic state, integrated runner, figure pack, or repository output.
- No implementation, staging, commit, or push without explicit authority.
- Stop on scientific ambiguity, changed baseline, validation failure, or scope
  expansion.

## Planned File Responsibilities

```text
R/food-energy-records.R
  strict food-energy parameter and dry-matter intake constructors

R/food-energy-conversion.R
  pure elementwise conversion into the existing gut-energy schedule

tests/testthat/test-food-energy-records.R
  exact record, schedule, units, bounds, types, and purity

tests/testthat/test-food-energy-conversion.R
  conversion arithmetic, fixtures, overflow, composition, and regression

experiments/rebuild-004-controlled-food-energy-bridge.R
  in-memory assertions and compact stdout summaries only

docs and generated man files
  implemented meaning, structural non-identifiability, exports, and exclusions
```

The complete required 22-path set is declared in `Goal.md`. Every path must be
present at closeout, with no extra path.

## Task 1: Lock The Food Record Contract In Tests

- [ ] Create the record test file before production source.
- [ ] Test the exact parameter list and 24-row dry-matter schedule.
- [ ] Test finite, bare, double-normalized inputs and exact bounds.
- [ ] Reject zero density, negative intake, malformed hours, attributes,
  matrices, missing values, non-finite values, and extra arguments.
- [ ] Parse the test and accept a red phase only for absent declared
  interfaces.
- [ ] Implement the two constructors and make the focused context green.

Outcome: the prescribed food inputs have one executable and fail-fast contract.

## Task 2: Implement The Pure Conversion

- [ ] Create conversion tests before production source.
- [ ] Require the red phase to fail only because the converter is absent.
- [ ] Multiply the 24 rates by the fixed density without recycling.
- [ ] Reject every non-finite converted rate before returning a result.
- [ ] Return only the existing exact Goal 003 gut-energy schedule.
- [ ] Prove that parameters and schedule are not mutated.
- [ ] Make the focused conversion context green.

Outcome: the package can derive a valid Goal 003 input without changing Goal
003.

## Task 3: Demonstrate Analytical And Compositional Fixtures

- [ ] Assert the zero-intake schedule.
- [ ] Assert the 100 kJ h^-1 constant bridge and its 0.24 kg DM and 2400 kJ
  daily totals.
- [ ] Assert the 400 kJ hour-0 pulse bridge.
- [ ] Assert factorization equivalence for alternative prescribed
  intake-density pairs.
- [ ] Pass converted and manually constructed schedules through the unchanged
  Goal 003 runner and require identical results.
- [ ] Preserve every Goal 002 and Goal 003 test and analytical fixture.

Outcome: the new layer changes input units and provenance, not downstream
dynamics.

## Task 4: Add The Thin Experiment And Documentation

- [ ] Add the no-write experiment with in-memory assertions.
- [ ] Print compact conversion and downstream equivalence summaries.
- [ ] Display energy stocks and amounts as whole kJ without rounding model
  objects.
- [ ] Add roxygen documentation and generate only declared exports and manuals.
- [ ] Update package prose, model docs, dictionary, roadmap, and decision
  record.
- [ ] State the metabolizable-to-gut-available accounting equivalence and
  structural non-identifiability explicitly.

Outcome: an ecologist can inspect the conversion without mistaking it for a
digestion or food-choice model.

## Task 5: Validate, Review, And Stop

- [ ] Run both focused test files and the full suite.
- [ ] Require nonzero focused counts and zero failures, warnings, or skips.
- [ ] Require the full suite to exceed the published 499-expectation Goal 003
  baseline with zero failures, warnings, or skips.
- [ ] Run the installed-package experiment and inspect its display precision.
- [ ] Confirm synchronized `renv` without changing `renv.lock`.
- [ ] Run external build, temporary-library installation, experiment, and
  `R CMD check --no-manual`.
- [ ] Require exact equality to the declared 22-path set.
- [ ] Review the complete diff, whitespace, index, baseline, absent outputs,
  and unchanged Goal 002-003 files.
- [ ] Perform one focused parent review and one independent final scientific
  and code review.
- [ ] Repair only material findings, rerun affected checks, and stop with an
  uncommitted closeout for Barry.

Outcome: Goal 004 is either complete within its single conversion boundary or
stopped with one explicit material issue. No later food or physiological layer
begins.
