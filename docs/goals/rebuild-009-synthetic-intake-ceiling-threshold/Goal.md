# Rebuild Goal 009: Synthetic Intake-Ceiling Threshold

## Status And Authority

Barry approved the evidence-only design and authorized execution on
2026-07-30. Packet publication on `main` is part of that authority. The Goal
009 implementation must stop uncommitted after validation and independent
review; staging, committing, or pushing it requires separate publication
authority.

## Principal Question

With the accepted 16-hour ecological intake window, fixed food-energy density,
maintenance, and routine activity held unchanged, what synthetic hourly
dry-matter ceiling is just sufficient to admit the Goal 008 neutral intake
prescription?

## Scientific Position

Goal 009 is a feasibility-threshold screen, not a new feeding mechanism.

The current package already accepts externally prescribed ingestion. Applying
a static ceiling produces another prescribed schedule and adds no downstream
dynamics. Goal 009 therefore keeps the ceiling transformation inside evidence
clients and does not add a package constructor, resolver, state, schema, or
export.

The evidence distinguishes:

- a candidate externally prescribed intake schedule;
- a synthetic exogenous hourly ceiling;
- the constrained prescribed schedule obtained by elementwise clipping; and
- the curtailed portion of the candidate prescription.

None of these is appetite, demand, offered forage, feeding choice, voluntary
intake, physiological capacity, or behavior.

## Preserved Model Contract

Goal 009 changes no production R code, package API, state, parameter, record,
schema, transition, runner, equation, tolerance, dependency, manual, or test.

It reuses:

- `new_food_energy_parameters()`;
- `new_dry_matter_intake_schedule()`;
- `derive_ingested_available_energy_schedule()`;
- `new_routine_activity_expenditure_schedule()`;
- the accepted gut and body constructors; and
- `run_gut_body_energy_reference_cycle()`.

The evidence-only constraint is:

```text
constrained prescribed intake at hour t
  = min(candidate prescribed intake at hour t,
        synthetic hourly ceiling at hour t)

curtailed prescribed intake at hour t
  = candidate prescribed intake at hour t
  - constrained prescribed intake at hour t

ceiling exceeded at hour t
  = candidate prescribed intake at hour t
  > synthetic hourly ceiling at hour t

daily unused active-ceiling headroom
  = sum over active hours of
    max(synthetic ceiling - constrained prescribed intake, 0)
```

Curtailment is discarded. It is not carried, stored, shifted, or compensated
in another interval.

An active interval is counted as touching the ceiling only when candidate and
ceiling are equal and strictly positive. Rest intervals therefore count as
neither exceeded nor touching.

## Shared Fixture

All scenarios retain:

```text
hour_of_day = 0:23
intake/activity intervals = hours 0:7 and 16:23
rest-closed intervals = hours 8:15
candidate active intake = 0.020 kg DM h^-1
candidate rest intake = 0 kg DM h^-1
metabolizable-energy density = 10000 kJ kg^-1 DM
active routine activity = 50 kJ h^-1
rest routine activity = 0 kJ h^-1
maintenance expenditure = 100 kJ h^-1
gut release fraction = 0.25 h^-1
initial gut available energy = 0 kJ
measurement body-energy reserve = 10000 kJ
gut convergence relative tolerance = 100 * .Machine$double.eps
maximum gut-only burn-in = 100 d
measured duration = 2 d
```

Each `hour_of_day` labels
`[hour_of_day, hour_of_day + 1)`. The candidate schedule therefore prescribes
intake over 16 one-hour intervals and closes intake over `[08:00, 16:00)`.

## Analytical Threshold

The daily accounting requirement is:

```text
daily maintenance = 24 h * 100 kJ h^-1 = 2400 kJ
daily routine activity = 16 h * 50 kJ h^-1 = 800 kJ
daily required input = 3200 kJ
```

The threshold ceiling is:

```text
C* = 3200 kJ /
     (16 h * 10000 kJ kg^-1 DM)
   = 0.020 kg DM h^-1
   = 200 kJ h^-1 at the fixed density
```

For active-hour ceiling `C`:

```text
daily constrained input =
  16 * min(C, 0.020 kg DM h^-1) * 10000 kJ kg^-1 DM

daily body-energy change =
  daily constrained input - 3200 kJ
```

This equation is an exact oracle under the unchanged periodic, linear,
lossless accounting system.

## Exact Scenarios

Scenario order is fixed:

```text
intake_ceiling_below_threshold
intake_ceiling_at_threshold
intake_ceiling_above_threshold
```

All ceiling schedules are zero during rest hours `8:15`.

### Below Threshold

```text
scenario_id = intake_ceiling_below_threshold
active ceiling = 0.015 kg DM h^-1
energy equivalent = 150 kJ h^-1
threshold multiple = 0.75
relation = below
curtailed active intervals = 16
touching active intervals = 0
daily candidate intake = 0.32 kg DM
daily constrained intake = 0.24 kg DM
daily curtailed intake = 0.08 kg DM
daily constrained energy = 2400 kJ
daily energy shortfall = 800 kJ
expected body change = -800 kJ d^-1
expected displayed body closes = 9200 and 8400 kJ
```

The constrained schedule and complete downstream result must be exactly
identical in memory to Goal 008
`ecological_activity_uncompensated`.

### At Threshold

```text
scenario_id = intake_ceiling_at_threshold
active ceiling = 0.020 kg DM h^-1
energy equivalent = 200 kJ h^-1
threshold multiple = 1.00
relation = at
curtailed active intervals = 0
touching active intervals = 16
daily candidate intake = 0.32 kg DM
daily constrained intake = 0.32 kg DM
daily curtailed intake = 0 kg DM
daily constrained energy = 3200 kJ
daily energy shortfall = 0 kJ
daily unused active-ceiling headroom = 0 kg DM and 0 kJ
expected body change = approximately 0 kJ d^-1
expected displayed body closes = 10000 and 10000 kJ
```

The constrained schedule and complete downstream result must be exactly
identical in memory to Goal 008
`ecological_activity_prescribed_balance`.

### Above Threshold

```text
scenario_id = intake_ceiling_above_threshold
active ceiling = 0.025 kg DM h^-1
energy equivalent = 250 kJ h^-1
threshold multiple = 1.25
relation = above
curtailed active intervals = 0
touching active intervals = 0
daily candidate intake = 0.32 kg DM
daily constrained intake = 0.32 kg DM
daily curtailed intake = 0 kg DM
daily constrained energy = 3200 kJ
daily energy shortfall = 0 kJ
daily unused active-ceiling headroom = 0.08 kg DM and 800 kJ
candidate-to-ceiling ratio = 0.80
expected body change = approximately 0 kJ d^-1
expected displayed body closes = 10000 and 10000 kJ
```

The constrained schedule and complete downstream result must be exactly
identical in memory to the at-threshold scenario and Goal 008
`ecological_activity_prescribed_balance`.

The `0.80` ratio is an accounting ratio between the candidate prescription and
the synthetic ceiling. It must not be described as physiological capacity use.

## Required Evidence

The evidence clients must verify:

- exact candidate, ceiling, constrained, and curtailed hourly schedules;
- rest closure and the 16 declared active intervals;
- exact threshold reconstruction from maintenance, activity, density, and
  opportunity duration;
- exact daily dry-matter, energy, shortfall, and headroom arithmetic;
- the below/at/above relation, curtailed-interval counts, and touching counts;
- finite non-negative schedules and returned stock paths;
- the expected deficit and neutral daily outcomes;
- exact full-result identity with the accepted Goal 008 oracles; and
- distinct below-threshold body trajectory but identical at/above-threshold
  body trajectories.

The experiment may define one small local clipping helper. It must not define
a generalized constraint engine, duplicate gut/body transitions, or add a
package function.

## No-Write Experiment

Add:

```text
experiments/rebuild-009-synthetic-intake-ceiling-threshold.R
```

The script:

- accepts no arguments;
- uses exported package functions for all model execution;
- writes no files;
- constructs the candidate and direct Goal 008 oracle schedules explicitly;
- applies the three evidence-only ceiling schedules;
- asserts the complete contract in memory; and
- prints compact threshold, hourly constraint, daily outcome, identity, and
  limitation summaries.

Human-facing energy stocks and amounts use whole kilojoules. Rates and
dry-matter values retain appropriate precision.

## Review Pack

Add:

```text
experiments/rebuild-009-review-pack.R
```

It accepts exactly one non-empty output-directory argument, rejects symbolic
links and undeclared destination entries, stages and validates all files before
replacement, and writes exactly:

```text
outputs/rebuild-009-synthetic-intake-ceiling-threshold/
  figure-1-synthetic-intake-ceiling-threshold.png
  table-1-hourly-ceiling-screen.csv
  table-2-threshold-summary.csv
  table-3-daily-accounting.csv
```

### Table 1

```text
rows = 72
order = scenario order, then hour 0:23
columns =
  scenario_id
  hour_of_day
  candidate_prescribed_dry_matter_intake_kg_dm_h
  synthetic_intake_ceiling_kg_dm_h
  constrained_prescribed_dry_matter_intake_kg_dm_h
  curtailed_prescribed_dry_matter_intake_kg_dm_h
  ceiling_exceeded
```

### Table 2

```text
rows = 3
order = scenario order
columns =
  scenario_id
  active_ceiling_kg_dm_h
  active_ceiling_energy_equivalent_kj_h
  threshold_multiple
  threshold_relation
  curtailed_active_intervals
  touching_active_intervals
  daily_candidate_intake_kg_dm
  daily_ceiling_capacity_kg_dm
  daily_constrained_intake_kg_dm
  daily_curtailed_intake_kg_dm
  daily_constrained_energy_kj
  daily_energy_shortfall_kj
  daily_unused_ceiling_headroom_kg_dm
  daily_unused_ceiling_headroom_kj
```

### Table 3

```text
rows = 6
order = scenario order, then measured day 1:2
columns =
  scenario_id
  measurement_day
  daily_candidate_intake_kg_dm
  daily_constrained_intake_kg_dm
  daily_curtailed_intake_kg_dm
  total_constrained_energy_input_kj
  total_assimilated_energy_kj
  total_maintenance_expenditure_kj
  total_routine_activity_expenditure_kj
  observed_body_energy_change_kj
  body_energy_reserve_final_kj
  body_energy_status
  goal008_oracle_scenario_id
  exact_oracle_identity
```

### Figure

The figure has three panels:

1. analytical active-ceiling response versus daily constrained energy, with
   the 3200 kJ requirement and 200 kJ h^-1 threshold marked;
2. analytical daily body-energy change versus active ceiling, with zero and
   the three fixtures marked; and
3. measured body-reserve boundary trajectories over `0-48 h` for all three
   scenarios.

The figure identifies the synthetic nature of the ceiling, uses explicit
units, and does not imply empirical capacity, behavior, continuous feeding,
or viability.

The review script validates exact schemas, rows, order, threshold arithmetic,
schedule-level clipping, oracle identity, and material claims before and after
CSV serialization. Exact full-result identity is the downstream gate; Goal 009
does not independently revalidate convergence, carry-over, or complete
gut/body/system accounting already established by Goal 008.

## Documentation Outcome

Add Decision 0009 and update:

- `README.md`;
- `docs/model-charter.md`;
- `docs/model-specification.md`;
- `docs/roadmap.md`;
- `docs/variable-dictionary.md`; and
- the mutable Goal 009 Log.

The variable dictionary update corrects stale Goal-status prose only. Goal 009
adds no package variable or schema.

Documentation must distinguish observation from conditional inference and
state that:

- `0.020 kg DM h^-1` is an accounting threshold under declared assumptions;
- it is not an empirical maximum or demonstrated achievable rate;
- a static ceiling is equivalent to a lower prescribed schedule downstream;
- no curtailed intake is redistributed; and
- Goal 010 remains an unapproved decision between promoting a durable ceiling,
  varying opportunity duration, or pausing for empirical evidence.

## Exact Implementation Surface

After packet publication, implementation may change only:

```text
README.md
docs/decisions/0009-synthetic-intake-ceiling-threshold.md
docs/goals/rebuild-009-synthetic-intake-ceiling-threshold/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-009-synthetic-intake-ceiling-threshold.R
experiments/rebuild-009-review-pack.R
```

Protect all production R, tests, manuals, namespace and package metadata,
dependencies, existing decisions and goal packets, and existing experiments.
Any additional path requires a documented justification; material expansion
requires Barry's approval.

## Validation And Acceptance

Goal 009 is accepted only when:

- the Goal, Plan, and Runbook hashes remain frozen;
- both new R scripts parse;
- the no-write experiment passes source-loaded and installed-package runs
  without changing repository status;
- all analytical, schedule, identity, convergence, accounting, and body
  trajectory claims pass;
- the review pack contains exactly the four declared ignored files;
- all CSVs pass material read-back reconstruction;
- the figure is nonblank, legible, unclipped, and faithful to the tables;
- the unchanged full suite reports exactly 1287 passes with no failure,
  warning, error, or skip;
- `renv::status()` reports synchronization;
- external build, temporary installation, and
  `R CMD check --no-manual` return `Status: OK`;
- the complete changed-path set equals the nine authorized paths;
- protected paths remain unchanged;
- the Git index remains empty during execution;
- no package tarball, check directory, or guarded temporary directory remains;
  and
- one independent final reviewer reports no Critical or Important defect.

Perform one focused repair pass only for a material finding. Stop when the
high-value contract passes; do not iterate on cosmetic prose, plot styling, or
script compression.

## Explicit Non-Goals

Goal 009 does not add:

- a package ceiling constructor, resolver, export, record, or schema;
- appetite, demand, offered forage, feeding choice, or voluntary intake;
- an empirical maximum ingestion rate or sub-hour feeding-bout rate;
- redistribution, compensation, storage, carry-over, or catch-up feeding;
- a daily allowance, depletion stock, feeding-permission process, or
  generalized constraint engine;
- gut capacity, dry-matter gut state, digestive physiology, or food-quality
  variation;
- activity feedback, body-state feedback, dynamic body mass, or viability;
- plants, weather, space, individuals, populations, or calibration; or
- a rate-by-opportunity grid or opportunity-duration experiment.

## Stop Boundary

Stop after the three-level synthetic threshold bracket, exact Goal 008 oracle
identities, no-write experiment, four review files, bounded documentation,
validation, and independent review are complete.

Do not infer that an animal can achieve `0.020 kg DM h^-1`, feeds continuously
for 16 hours, or uses any fraction of physiological capacity. Do not implement
Goal 010.

Do not stage, commit, or push the Goal 009 implementation without Barry's
separate publication authority after he reviews the completed evidence.
