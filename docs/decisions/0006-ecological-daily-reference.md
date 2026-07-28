# Decision 0006: Ecological Daily Reference

Date: 2026-07-27

Status: accepted

## Context

The Goal 005 constant-intake fixture is a strong mathematical reference because
it isolates arithmetic, convergence, accounting, and state carry-over. Its
continuous prescribed intake is deliberately artificial, however, and does not
provide a useful normal starting point for discussing later ecological
perturbations.

The next bounded question was whether the accepted Goal 004 food conversion and
Goal 005 repeated-day runner could establish a minimally ecological daily
reference without adding feeding behavior, activity, physiology, or another
public interface.

## Decision

Retain two references with different roles:

- `mathematical_continuous` remains the permanent mathematical diagnostic and
  regression reference; and
- `ecological_day_resting` becomes the normal prescribed reference for
  ecological interpretation.

Both references use an empty initial gut, a 10000 kJ measurement body reserve,
a gut release fraction of 0.25 h^-1, maintenance expenditure of 100 kJ h^-1,
a metabolizable-energy density of 10000 kJ kg^-1 DM, the accepted Goal 005
convergence tolerance, a 100-day maximum gut-only burn-in, and two carried
measurement days.

The mathematical reference prescribes:

```text
hour_of_day = 0:23
prescribed dry-matter intake = 0.010 kg DM h^-1
derived gut input = 100 kJ h^-1
daily dry-matter intake = 0.24 kg DM
daily gut input = 2400 kJ
```

The ecological reference prescribes:

```text
hour_of_day = 0:7 and 16:23
prescribed dry-matter intake = 0.015 kg DM h^-1
derived gut input = 150 kJ h^-1

hour_of_day = 8:15
prescribed dry-matter intake = 0 kg DM h^-1
derived gut input = 0 kJ h^-1

daily dry-matter intake = 0.24 kg DM
daily gut input = 2400 kJ
```

Each `hour_of_day` labels the half-open interval
`[hour_of_day, hour_of_day + 1)`. The ecological reference therefore closes
intake for exactly `[08:00, 16:00)` and prescribes intake across the
night-spanning 16-hour block from 16:00 through 08:00.

Construct both dry-matter schedules through
`new_dry_matter_intake_schedule()`, derive their energy schedules through
`derive_ingested_available_energy_schedule()`, and pass those schedules to
`run_gut_body_energy_reference_cycle()`. The accepted functions, records,
schemas, equations, tolerances, and transition order remain unchanged.

## Interpretation

The ecological reference is a generic synthetic day-resting, nocturnally active
prescribed-intake fixture. Closing intake during the eight-hour rest interval
is an input convention, not a feeding-permission mask, behavioral choice,
observation of realized foraging, or modeled sleep or activity state.

The food-energy density is already metabolizable on a dry-matter basis. Its
product with prescribed dry-matter intake is the available-energy accounting
equivalent entering the gut; no digestive efficiency or loss is applied.

Equal daily dry-matter intake, gut input, and maintenance define an operational
null for the two references. Under the current linear, lossless, unlimited gut
system, their steady-cycle daily assimilation, gut change, and body change
should agree within the existing numerical tolerances. Their within-day gut
stock, gut release, and body-reserve trajectories should differ. This timing
invariance of daily totals is an accounting result, not biological
interchangeability or evidence that either schedule is realistic.

## Rejected Alternatives

- A convenience runner or scenario class was rejected because it would hide
  explicit composition behind a redundant interface.
- A feeding mask, activity state, or endogenous schedule was rejected because
  the reference prescribes intake and contains no behavioral mechanism.
- Explicit crepuscular peaks were rejected because the approved feeding block
  is flat and the nominal clock is not tied to sunrise, season, latitude, or
  light.
- A maximum intake rate, gut capacity, or feeding cost was rejected because
  each would add a new mechanism requiring a separate scientific decision.
- A species-specific or empirically calibrated interpretation was rejected
  because the schedule and all shared parameters remain synthetic conventions.

## Consequences And Stop Boundary

Goal 006 adds a durable scenario, regression, experiment, and review-evidence
layer only. It adds no production R code, dependency, public API, dynamic
state, plant feedback, behavior, activity expenditure, feeding constraint,
digestive process, physiology, or generalized simulation framework.

The mathematical reference remains available for diagnosis. The ecological
reference is the normal starting point for later ecological comparisons, but
it does not authorize any later perturbation or model layer. Stop after the two
fixtures, their distinct roles, exact schedules, operational null, trajectory
contrast, documentation, and review evidence are established and discussed.
