# Rebuild Goal 011: One-Day Prescribed-Input Shortfall

## Status

Approved for formulation and execution by Barry on 2026-07-31.

## Objective

Establish how one finite prescribed-input shortfall propagates through the
existing gut and body stocks when the balanced reference forcing resumes.
Separate rapid numerical realignment of the gut state from persistence of the
whole-system and body-energy debt.

This is an evidence-only non-stationary sequence. It must not add a production
multi-day runner, new state, new equation, schedule feedback, behavioral
response, compensation process, recovery process, or viability criterion.

## Scientific Question

Starting from the accepted balanced period-24 gut state and the same body
reserve, how is one accepted `800 kJ` prescribed-input shortfall partitioned
between gut and body, and what happens over two subsequent days of restored
balanced forcing?

Goals 009 and 010 construct each scenario from its own periodic gut reference.
They therefore do not observe the transition from one daily forcing regime to
another. Goal 011 changes the forcing for exactly one day and carries both
stocks forward without another reset.

## Fixed System

Use existing exported package interfaces with:

```text
food energy density = 10000 kJ kg^-1 DM
maintenance expenditure = 100 kJ h^-1 for all 24 hours
routine activity expenditure = 50 kJ h^-1 in hours 0:7 and 16:23
routine activity expenditure = 0 kJ h^-1 in hours 8:15
balanced prescribed intake = 0.020 kg DM h^-1 in hours 0:7 and 16:23
shortfall prescribed intake = 0.015 kg DM h^-1 in hours 0:7 and 16:23
prescribed intake = 0 in hours 8:15 for both schedules
gut release fraction = 0.25 h^-1
initial body-energy reserve = 10000 kJ
sequence horizon = three carried 24-hour days
```

Construct the balanced period-24 gut opening state with the existing
reference-cycle runner. Use that same gut state and the same body state to
initialize both sequences. After this common boundary, do not reset either
stock.

The shortfall schedule is the accepted Goal 009 below-threshold forcing. It
retains the same clock placement and routine activity as the balanced
reference, so the event changes prescribed input rate only.

## Declared Sequences

### All-Balanced Control

```text
sequence_id = all_balanced_control
day 1 forcing = balanced
day 2 forcing = balanced
day 3 forcing = balanced
daily prescribed dry matter = 0.32, 0.32, 0.32 kg DM
daily prescribed energy = 3200, 3200, 3200 kJ
```

The first two days must reproduce the accepted Goal 008 balanced reference
result exactly when assembled into the same schemas. The third day must retain
the same periodic gut and approximately neutral body behavior within the
existing scale-aware tolerance.

### One-Day Rate Shortfall

```text
sequence_id = one_day_rate_shortfall
day 1 forcing = shortfall
day 2 forcing = return_to_reference
day 3 forcing = return_to_reference
daily prescribed dry matter = 0.24, 0.32, 0.32 kg DM
daily prescribed energy = 2400, 3200, 3200 kJ
```

The first day uses the same prescribed schedule as Goal 008
`ecological_activity_uncompensated`, but it begins from the balanced periodic
gut state rather than the lower-input schedule's own periodic gut state. It
must not be described as the Goal 008 uncompensated result.

## Contrast Convention

Every contrast is:

```text
one_day_rate_shortfall - all_balanced_control
```

At any matched boundary:

```text
combined-system contrast =
  gut-stock contrast + body-reserve contrast
```

The sequences have identical maintenance and activity. Their cumulative
external energy difference is therefore the cumulative prescribed-input
contrast.

## Analytical Contract

The day-1 prescribed-input difference is:

```text
16 h * (0.015 - 0.020) kg DM h^-1 * 10000 kJ kg^-1 DM
= -800 kJ
```

The combined-system contrast must:

```text
begin at 0 kJ
reach -800 kJ at the end of the shortfall day
remain -800 kJ throughout both return-to-reference days
```

Once balanced forcing resumes, both sequences have identical hourly inputs.
For gut-stock contrast `delta_G` and release fraction `r = 0.25`:

```text
delta_G[t + 1] = (1 - r) * delta_G[t]
               = 0.75 * delta_G[t]

daily gut-contrast contraction factor = 0.75^24
```

At each return-to-reference boundary:

```text
body-reserve contrast =
  -800 kJ - gut-stock contrast
```

The gut contrast should approach zero while the body contrast approaches
`-800 kJ`. These are analytical properties of the declared deterministic,
linear, lossless model. Human-facing energy stocks and amounts use whole
kilojoules, except where a small contrast or residual needs scale-appropriate
precision.

## Interpretation Boundary

The allowed model-dependent inference is:

> Restoring the neutral prescribed forcing halts additional external energy
> debt, but it does not repay the existing debt. Numerical gut-state
> realignment is not body-energy restoration.

Do not call this animal recovery, physiological recovery, catch-up feeding,
compensation, chronic decline, stress, starvation, viability, or fitness. The
model contains none of those processes or criteria.

## Evidence Clients

Create:

```text
experiments/rebuild-011-one-day-prescribed-input-shortfall.R
experiments/rebuild-011-review-pack.R
```

The no-write experiment:

- accepts no arguments;
- uses exported package functions for all model execution;
- writes no files;
- constructs the balanced and shortfall schedules explicitly;
- constructs the balanced periodic gut state once;
- runs the two exact three-day sequences by chaining the exported one-day
  runner;
- exposes one in-memory evidence object for the review client;
- asserts common initialization, exact schedules, state carry-over,
  Goal 008 control identity, the `-800 kJ` system invariant, hourly and daily
  gut-contrast contraction, body complement, accounting closure, and finite
  non-negative stocks; and
- prints compact summaries.

The review script accepts exactly one output-directory argument, guards
against symbolic links and undeclared entries, stages and validates files
before replacement, and writes exactly four ignored files.

## Retained Review Pack

Write exactly:

```text
outputs/rebuild-011-one-day-prescribed-input-shortfall/
  figure-1-one-day-prescribed-input-shortfall.png
  table-1-hourly-boundary-contrasts.csv
  table-2-daily-sequences.csv
  table-3-day-boundary-realignment.csv
```

### Table 1

```text
rows = 73
order = elapsed boundaries 0:72 h
columns =
  elapsed_time_h
  boundary_phase
  cumulative_prescribed_input_contrast_kj
  gut_available_energy_contrast_kj
  body_energy_reserve_contrast_kj
  combined_system_energy_contrast_kj
  contrast_closure_residual_kj
```

`boundary_phase` is `initial` at hour 0, `shortfall_day` at hours 1:24,
`return_to_reference_day_1` at hours 25:48, and
`return_to_reference_day_2` at hours 49:72.

### Table 2

```text
rows = 6
order = all-balanced days 1:3, then shortfall-sequence days 1:3
columns =
  sequence_id
  sequence_day
  forcing_phase
  daily_prescribed_dry_matter_intake_kg_dm
  total_prescribed_energy_input_kj
  total_assimilated_energy_kj
  total_maintenance_expenditure_kj
  total_routine_activity_expenditure_kj
  expected_body_energy_change_kj
  observed_body_energy_change_kj
  gut_available_energy_initial_kj
  gut_available_energy_final_kj
  body_energy_reserve_initial_kj
  body_energy_reserve_final_kj
  total_system_energy_initial_kj
  total_system_energy_final_kj
```

### Table 3

```text
rows = 4
order = elapsed boundaries 0, 24, 48, 72 h
columns =
  elapsed_time_h
  boundary_label
  cumulative_prescribed_input_contrast_kj
  gut_available_energy_contrast_kj
  expected_gut_contrast_kj
  gut_contraction_factor_from_previous_boundary
  body_energy_reserve_contrast_kj
  expected_body_complement_kj
  combined_system_energy_contrast_kj
  contrast_closure_residual_kj
```

The contraction factor is empty at the initial and shortfall-close boundaries
and equals `0.75^24` at the two return-to-reference boundaries.

### Figure

The figure has three panels:

1. prescribed energy input for the two sequences over 72 hours, with the
   shortfall day and two return-to-reference days distinguished;
2. gut-stock and body-reserve contrasts over `0-72 h`; and
3. combined-system contrast against cumulative prescribed-input contrast,
   visibly reaching and retaining `-800 kJ`.

Use explicit units and whole-kilojoule labels. Use
`return-to-reference forcing`, not biological `recovery`.

## Documentation Surface

Create Decision 0011 and update only:

```text
README.md
docs/decisions/0011-one-day-prescribed-input-shortfall.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
```

The documentation must distinguish:

- stationary periodic references from a transition between daily forcings;
- prescribed-input restoration from animal recovery;
- gut-state realignment from body-energy restoration;
- a combined-system debt from its changing partition between gut and body;
- the shortfall day's forcing schedule from the Goal 008 uncompensated
  periodic result; and
- evidence-client sequencing from a production multi-day API.

## Validation

Require:

- both scripts parse;
- source-loaded no-write execution succeeds without changing Git status;
- guarded review-pack generation succeeds without changing Git status;
- exact file set, schemas, dimensions, ordering, analytical values, and CSV
  readback pass;
- the unchanged full suite reports `1287 PASS, 0 FAIL, 0 WARN, 0 SKIP` using
  explicit integer coercion;
- `renv::status()` is synchronized;
- one temporary package build and installation succeeds;
- both scripts pass against the installed package;
- the figure is inspected;
- exact path, protected-surface, empty-index, output-regularity, and temporary
  cleanup gates pass; and
- one independent final review returns no Critical or Important finding.

Do not run `R CMD check` unless a material repair changes package code, tests,
manuals, metadata, namespace, or dependencies.

## Exact Implementation Scope

Only these twelve tracked or untracked paths may change:

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

Ignored outputs are limited to the four declared review files.

## Exclusions

Do not add or change:

- production R, tests, manuals, exports, package metadata, dependencies,
  `.Rbuildignore`, or `.gitignore`;
- a configurable or generalized multi-day runner;
- a production forcing-sequence record or schedule-switch mechanism;
- another shortfall magnitude, duration, clock placement, repeated event,
  stochastic event, or sensitivity grid;
- compensatory intake, redistribution, feedback, appetite, behavior, forage
  availability, or gut capacity;
- biological recovery, chronic decline, viability, body-mass change, protein,
  water, thermoregulation, plants, weather, or space; or
- Goal 012 design or implementation.

## Stop Rules And Authority

- Require clean synchronized `main` at the published Goal 010 commit before
  formulation.
- Stop if frozen Goal, Plan, or Runbook hashes change after review.
- Stop before changing a path outside the exact implementation scope.
- Stop if the shared initial state, `-800 kJ` system invariant, or recovery-day
  gut recurrence fails.
- Stop if the evidence is described as biological recovery or compensation.
- Perform at most one focused repair pass for a material defect.
- Do not reset, clean, stash, force, amend, or delete prior ignored evidence.
- Formulation and execution are authorized.
- Stop with Goal 011 uncommitted and unstaged. Commit or push only with later
  explicit publication authority.

## Acceptance

Goal 011 is accepted when the declared sequence, analytical contrasts,
retained evidence, documentation, proportional validation, and independent
review all pass without changing production behavior.

The result will establish transient stock partitioning under one declared
prescribed-input shortfall. It will not establish animal recovery, a chronic
response, behavioral compensation, feeding capacity, or viability.
