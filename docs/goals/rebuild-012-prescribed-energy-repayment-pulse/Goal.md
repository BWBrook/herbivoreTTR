# Rebuild Goal 012: Prescribed Energy-Repayment Pulse

## Status

Approved for formulation and execution by Barry on 2026-08-01.

## Objective

Establish how an externally prescribed input pulse that exactly cancels the
Goal 011 shortfall propagates through the existing gut and body stocks.
Separate return of the whole-system contrast to zero from subsequent numerical
realignment of the two stock contrasts.

This is an evidence-only non-stationary sequence. It must not add a production
multi-day runner, new state, new equation, behavioral response, compensation
process, capacity claim, recovery process, or viability criterion.

## Scientific Question

Starting from the accepted balanced period-24 gut state and the same body
reserve, what happens when one `-800 kJ` prescribed-input day is followed by
one `+800 kJ` prescribed-input day and then two balanced days?

Goal 011 showed that return to balanced forcing stops additional whole-system
debt but does not replace missing energy. Goal 012 changes only the day-2
forcing so that the cumulative external-input contrast returns exactly to
zero.

## Fixed System

Use existing exported package interfaces with:

```text
food energy density = 10000 kJ kg^-1 DM
maintenance expenditure = 100 kJ h^-1 for all 24 hours
routine activity expenditure = 50 kJ h^-1 in hours 0:7 and 16:23
routine activity expenditure = 0 kJ h^-1 in hours 8:15
balanced prescribed intake = 0.020 kg DM h^-1 in hours 0:7 and 16:23
shortfall prescribed intake = 0.015 kg DM h^-1 in hours 0:7 and 16:23
repayment-pulse prescribed intake = 0.025 kg DM h^-1 in hours 0:7 and 16:23
prescribed intake = 0 in hours 8:15 for all schedules
gut release fraction = 0.25 h^-1
initial body-energy reserve = 10000 kJ
sequence horizon = four carried 24-hour days
```

Construct the balanced period-24 gut opening state with the existing
reference-cycle runner. Use that same gut state and the same body state to
initialize both sequences. After this common boundary, do not reset either
stock.

The `0.025 kg DM h^-1` rate is a controlled synthetic forcing. It is not an
empirical maximum, demonstrated feeding rate, appetite, voluntary response, or
animal decision. It is also not Goal 009's above-threshold result: that
evidence clipped a `0.020 kg DM h^-1` candidate against a non-binding `0.025`
ceiling, so actual prescribed intake remained `0.020 kg DM h^-1`.

## Declared Sequences

### All-Balanced Control

```text
sequence_id = all_balanced_control
days 1:4 forcing = balanced
daily prescribed dry matter = 0.32 kg DM
daily prescribed energy = 3200 kJ
```

The first two days must reproduce the accepted Goal 008 balanced reference
result exactly when assembled into the same schemas. Days 3 and 4 must retain
the same periodic gut and approximately neutral body behavior within the
existing scale-aware tolerance.

### Shortfall Then Prescribed Repayment

```text
sequence_id = shortfall_then_repayment
day 1 forcing = shortfall
day 2 forcing = prescribed_repayment_pulse
days 3:4 forcing = return_to_reference
daily prescribed dry matter = 0.24, 0.40, 0.32, 0.32 kg DM
daily prescribed energy = 2400, 4000, 3200, 3200 kJ
```

The day-1 forcing and common initialization must reproduce the published Goal
011 shortfall-day boundary oracle. Both stocks then carry forward through the
repayment pulse and the two balanced days without another reset.

## Contrast Convention

Every contrast is:

```text
shortfall_then_repayment - all_balanced_control
```

At any matched boundary:

```text
combined-system contrast =
  gut-stock contrast + body-reserve contrast
```

The sequences have identical maintenance and routine activity. Their
cumulative external energy difference is therefore the cumulative prescribed-
input contrast.

## Analytical Contract

The hourly prescribed-input contrast is `-50 kJ` in each of the 16 feeding
hours on day 1, `+50 kJ` in those hours on day 2, and zero on days 3 and 4.
It is zero during every central eight-hour intake closure.

The cumulative prescribed-input and combined-system contrasts must:

```text
begin at 0 kJ
reach -800 kJ at the end of day 1
return to 0 kJ at the end of day 2
remain 0 kJ through days 3 and 4
```

For gut-stock contrast `delta_G`, hourly input contrast `delta_I`, and release
fraction `r = 0.25`:

```text
delta_G[t + 1] = (1 - r) * delta_G[t] + delta_I[t]
               = 0.75 * delta_G[t] + delta_I[t]
```

Once balanced forcing resumes after hour 48:

```text
delta_G[t + 1] = 0.75 * delta_G[t]
daily gut-contrast contraction factor = 0.75^24
```

At every boundary:

```text
body-reserve contrast =
  cumulative prescribed-input contrast - gut-stock contrast
```

The expected day-boundary fixtures are:

| Elapsed time | Gut contrast (kJ) | Body contrast (kJ) | Combined contrast (kJ) |
| ---: | ---: | ---: | ---: |
| 0 h | 0 | 0 | 0 |
| 24 h | -181.781258 | -618.218742 | -800 |
| 48 h | 181.598860 | -181.598860 | 0 |
| 72 h | 0.182215 | -0.182215 | 0 |
| 96 h | 0.000183 | -0.000183 | 0 |

Human-facing energy stocks and amounts use whole kilojoules, except where a
small contrast or residual needs scale-appropriate precision.

## Interpretation Boundary

The allowed model-dependent inference is:

> An external pulse equal to the missing energy returns the whole-system
> contrast to zero, but gut transit delays realignment of the individual gut
> and body contrasts.

`Prescribed repayment pulse` is an accounting label for imposed forcing. Do
not call it compensatory feeding, catch-up feeding, appetite, adaptive
behavior, demonstrated capacity, animal recovery, physiological recovery,
stress relief, viability, or fitness. A zero combined contrast is not evidence
that a biological organism could realize this schedule.

## Evidence Clients

Create:

```text
experiments/rebuild-012-prescribed-energy-repayment-pulse.R
experiments/rebuild-012-review-pack.R
```

The no-write experiment:

- accepts no arguments and writes no files;
- constructs the balanced, shortfall, and repayment-pulse schedules explicitly;
- constructs the balanced periodic gut state once;
- chains the exported one-day runner for both exact four-day sequences;
- exposes one in-memory object named `goal012_evidence`;
- asserts common initialization, schedules, exact state carry-over, Goal 008
  control identity, the published Goal 011 day-1 oracle, cumulative input and
  combined-system invariants, hourly and daily gut recurrences, body
  complement, accounting closure, and finite non-negative stocks; and
- prints compact summaries.

The review script accepts exactly one output-directory argument, guards
against symbolic links and undeclared entries, stages and validates files
before replacement, and writes exactly four ignored files. Its validators must
independently reconstruct all three expected data frames from the raw sequence
results, declared schedules, and analytical recurrence. They must not validate
a table against itself, another preassembled serialized table, or another
retained table. Mutation probes must reject a change in every column of every
table both before serialization and after CSV readback.

## Retained Review Pack

Write exactly:

```text
outputs/rebuild-012-prescribed-energy-repayment-pulse/
  figure-1-prescribed-energy-repayment-pulse.png
  table-1-hourly-boundary-contrasts.csv
  table-2-daily-sequences.csv
  table-3-day-boundary-realignment.csv
```

### Table 1

```text
rows = 97
order = elapsed boundaries 0:96 h
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
`prescribed_repayment_pulse_day` at hours 25:48,
`return_to_reference_day_1` at hours 49:72, and
`return_to_reference_day_2` at hours 73:96.

### Table 2

```text
rows = 8
order = all_balanced_control days 1:4, then shortfall_then_repayment days 1:4
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

The exact forcing-phase order is:

```text
balanced
balanced
balanced
balanced
shortfall
prescribed_repayment_pulse
return_to_reference
return_to_reference
```

### Table 3

```text
rows = 5
order = elapsed boundaries 0, 24, 48, 72, 96 h
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

The contraction factor is empty at the initial, shortfall-close, and
repayment-close boundaries and equals `0.75^24` at the two subsequent balanced
boundaries.

The exact `boundary_label` order is:

```text
initial
shortfall_day_close
prescribed_repayment_pulse_day_close
return_to_reference_day_1_close
return_to_reference_day_2_close
```

### Figure

The `1800 x 900` figure has three panels:

1. prescribed energy input for the two sequences over 96 hours, distinguishing
   the shortfall, repayment-pulse, and return-to-reference days;
2. gut-stock and body-reserve contrasts over `0-96 h`; and
3. combined-system contrast against cumulative prescribed-input contrast,
   visibly moving from `-800 kJ` back to zero and remaining there.

Use explicit units, whole-kilojoule labels, and `prescribed repayment pulse` or
`return-to-reference forcing`, not biological recovery language.

## Documentation Surface

Update only:

```text
README.md
docs/decisions/0012-prescribed-energy-repayment-pulse.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
```

Document the sequences, invariants, observed partition, synthetic-forcing
boundary, evidence-only API status, and the fact that Goal 013 remains
unapproved and scientifically unspecified.

## Acceptance Criteria

Goal 012 is accepted only when:

1. the frozen packet remains unchanged;
2. implementation changes exactly the declared twelve tracked paths;
3. production R, tests, manuals, metadata, namespace, and dependencies remain
   unchanged;
4. both clients parse and run with unchanged Git status;
5. retained files have the exact names, schemas, dimensions, order, arithmetic,
   and figure geometry declared above;
6. the unchanged full suite remains `1287/0/0/0` and `renv` is synchronized;
7. one external build/install runs both clients against the installed package;
8. one independent final audit finds no Critical or Important defect after at
   most one material repair pass; and
9. all Goal 012 work remains uncommitted and unstaged for Barry's review.

Do not run `R CMD check`. If any repair would require a protected package or
test change, stop and return for a separately authorized goal.

## Authority Boundary

Formulation and execution are authorized. Commit and push are not authorized.
Stop before publication, any package-model change, any behavioral or
physiological mechanism, or selection of Goal 013.
