# Rebuild Goal 010: Feeding-Opportunity Duration

## Status

Approved for immediate execution by Barry on 2026-07-31.

## Objective

Establish how prescribed feeding-window duration changes daily energy input
under four declared clock geometries while physiology, routine activity, food
energy density, and intake rate during open hours remain fixed. Describe
within-day body-energy trajectories as conditional on both duration and the
declared placement of those hours.

This is an evidence-only duration screen. It must not add a package mechanism,
API, state, schema, test, appetite process, voluntary feeding behavior,
physiological capacity, or empirical feeding limit.

## Scientific Question

Under the accepted synthetic reference system, what happens when prescribed
ingestion is progressively shortened from an operational 24-hour null to the
declared 16-, 12-, and 8-hour evening/morning windows?

The screen isolates duration for daily energy accounting:

- routine activity remains fixed;
- prescribed intake during every open hour remains fixed; and
- only the set of hours in which intake is prescribed changes.

It does not identify a generic duration effect on within-day trajectories.
Clock placement changes with duration: the 24-hour null includes the
activity-off daytime block, whereas the 12- and 8-hour fixtures remove
central-night hours from within the fixed activity window.

## Fixed System

Use the existing exported package interfaces with:

```text
food energy density = 10000 kJ kg^-1 DM
maintenance expenditure = 100 kJ h^-1 for all 24 hours
routine activity expenditure = 50 kJ h^-1 in hours 16:23 and 0:7
routine activity expenditure = 0 kJ h^-1 in hours 8:15
prescribed intake when opportunity is open = 0.020 kg DM h^-1
prescribed energy when opportunity is open = 200 kJ h^-1
prescribed intake when opportunity is closed = 0
gut release fraction = 0.25 h^-1
measurement body-energy reserve = 10000 kJ
measurement horizon = two carried 24-hour days after gut-cycle construction
```

Feeding opportunity is evidence metadata used to construct an ordinary
prescribed intake schedule. An open hour is assumed to be fully used at the
declared rate; it is therefore operationally prescribed ingestion, not merely
unused access or a behavioral option. The opportunity metadata is not passed
into the package.

## Declared Fixtures

Intervals use the package convention `[hour_of_day, hour_of_day + 1)`.

### Operational 24-Hour Null

```text
scenario_id = prescribed_intake_window_24h
open hours = 0:23
duration = 24 h d^-1
prescribed-intake/activity overlap = 16 h d^-1
prescribed intake without activity = 8 h d^-1
activity without prescribed intake = 0 h d^-1
daily prescribed intake = 0.48 kg DM
daily prescribed energy = 4800 kJ
expected daily body-energy change = +1600 kJ
expected closing reserves = 11600 kJ, 13200 kJ
status = surplus
```

This is deliberately unrealistic because intake is prescribed throughout the
routine-activity-off interval as well as the activity window.

### Activity-Off-Closed 16-Hour Reference

```text
scenario_id = prescribed_intake_window_16h
open hours = 16:23 and 0:7
duration = 16 h d^-1
prescribed-intake/activity overlap = 16 h d^-1
prescribed intake without activity = 0 h d^-1
activity without prescribed intake = 0 h d^-1
daily prescribed intake = 0.32 kg DM
daily prescribed energy = 3200 kJ
expected daily body-energy change = 0 kJ
expected closing reserves = 10000 kJ, 10000 kJ
status = neutral
```

This complete result must be exactly identical to the accepted Goal 008
`ecological_activity_prescribed_balance` result.

### Restricted 12-Hour Fixture

```text
scenario_id = prescribed_intake_window_12h
open hours = 16:21 and 2:7
duration = 12 h d^-1
prescribed-intake/activity overlap = 12 h d^-1
prescribed intake without activity = 0 h d^-1
activity without prescribed intake = 4 h d^-1
daily prescribed intake = 0.24 kg DM
daily prescribed energy = 2400 kJ
expected daily body-energy change = -800 kJ
expected closing reserves = 9200 kJ, 8400 kJ
status = deficit
```

This fixture has the same daily intake, prescribed energy, maintenance,
routine-activity expenditure, body-energy change, status, and closing body
reserve as Goal 008 `ecological_activity_uncompensated`. It must not be called
fully identical: its hourly intake pattern, periodic gut state, and within-day
gut/body trajectories differ.

### Restricted 8-Hour Fixture

```text
scenario_id = prescribed_intake_window_8h
open hours = 16:19 and 4:7
duration = 8 h d^-1
prescribed-intake/activity overlap = 8 h d^-1
prescribed intake without activity = 0 h d^-1
activity without prescribed intake = 8 h d^-1
daily prescribed intake = 0.16 kg DM
daily prescribed energy = 1600 kJ
expected daily body-energy change = -1600 kJ
expected closing reserves = 8400 kJ, 6800 kJ
status = deficit
```

The 16-, 12-, and 8-hour fixtures retain equal evening and morning arms while
progressively removing central-night prescribed-intake hours. The 24-hour
comparator additionally opens the routine-activity-off interval `[08:00,
16:00)`.

## Analytical Contract

For opportunity duration `H` in hours per day:

```text
daily prescribed energy(H) = 200 kJ h^-1 * H
daily expenditure = 24 * 100 + 16 * 50 = 3200 kJ
expected daily body-energy change(H) = 200 * H - 3200 kJ
neutrality threshold = 3200 / 200 = 16 h d^-1
```

The expected changes for `H = 24, 16, 12, 8` are exactly:

```text
+1600, 0, -800, -1600 kJ d^-1
```

The model output should reproduce this daily accounting within the existing
scale-aware numerical tolerance. Closing reserves above are analytical display
values rather than raw floating-point equality targets. The linear duration
relation is a property of daily totals in the current periodic, lossless
system. Within-day gut/body trajectories also reflect the declared clock
placement. Human-facing energy stocks and amounts use whole kilojoules.

## Evidence Clients

Create:

```text
experiments/rebuild-010-feeding-opportunity-duration.R
experiments/rebuild-010-review-pack.R
```

The experiment:

- accepts no arguments;
- uses exported package functions for all model execution;
- writes no files;
- constructs all four opportunity schedules explicitly;
- constructs the two Goal 008 oracle schedules independently;
- asserts schedules, analytical results, daily results, reference
  relationships, successful periodic-gut convergence, measurement-day
  carry-over, finite non-negative stocks, and interpretation boundaries; and
- prints compact summaries.

The review script accepts exactly one output-directory argument, guards against
symbolic links and undeclared entries, stages and validates files before
replacement, and writes exactly four ignored files.

## Retained Review Pack

Write exactly:

```text
outputs/rebuild-010-feeding-opportunity-duration/
  figure-1-feeding-opportunity-duration.png
  table-1-hourly-prescribed-intake-windows.csv
  table-2-duration-summary.csv
  table-3-daily-accounting.csv
```

### Table 1

```text
rows = 96
order = scenario order, then hour 0:23
columns =
  scenario_id
  prescribed_intake_window_duration_h_d
  hour_of_day
  prescribed_intake_window_open
  prescribed_dry_matter_intake_kg_dm_h
  prescribed_ingested_available_energy_kj_h
  prescribed_routine_activity_expenditure_kj_h
```

### Table 2

```text
rows = 4
order = 24, 16, 12, 8 h
columns =
  scenario_id
  prescribed_intake_window_duration_h_d
  closed_prescribed_intake_duration_h_d
  prescribed_intake_activity_overlap_h_d
  activity_without_prescribed_intake_h_d
  prescribed_intake_without_activity_h_d
  threshold_relation
  daily_prescribed_dry_matter_intake_kg_dm
  daily_prescribed_energy_kj
  daily_maintenance_expenditure_kj
  daily_routine_activity_expenditure_kj
  expected_body_energy_change_kj
  day_1_body_energy_reserve_final_kj
  day_2_body_energy_reserve_final_kj
  matched_goal008_scenario_id
  daily_input_and_body_change_match
  within_day_body_trajectory_identical
  full_result_identical
```

For the 24- and 8-hour fixtures, the four Goal 008 comparison fields are empty
or `NA` because no comparison oracle is declared. For the 16-hour fixture all
three comparison flags are true. For the 12-hour fixture
`daily_input_and_body_change_match` is true while the two identity flags are
false.

### Table 3

```text
rows = 8
order = scenario order, then measured day 1:2
columns =
  scenario_id
  measurement_day
  prescribed_intake_window_duration_h_d
  daily_prescribed_dry_matter_intake_kg_dm
  total_prescribed_energy_input_kj
  total_assimilated_energy_kj
  total_maintenance_expenditure_kj
  total_routine_activity_expenditure_kj
  expected_body_energy_change_kj
  observed_body_energy_change_kj
  body_energy_reserve_initial_kj
  body_energy_reserve_final_kj
  body_energy_status
```

### Figure

The figure has three panels:

1. the four 24-hour prescribed-intake windows, visibly distinguishing open and
   closed hours while showing the fixed activity window;
2. fixed-rate daily body-energy change versus prescribed-intake-window
   duration, with the exact 16-hour neutrality threshold and all four fixtures
   marked; and
3. body-energy reserve boundary trajectories over `0-48 h`.

Use explicit units and whole-kilojoule labels. Do not imply empirical capacity,
voluntary behavior, viability, or literal continuous feeding, including for
the operational 24-hour null.

## Documentation Surface

Create Decision 0010 and update only:

```text
README.md
docs/decisions/0010-feeding-opportunity-duration.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
```

The documentation must distinguish:

- the approved feeding-opportunity idea from the operational evidence variable,
  `prescribed_intake_window_open`, which forces intake at the fixed rate;
- duration from rate;
- fixed activity from feeding opportunity;
- daily accounting attributable to duration from within-day trajectories
  conditional on clock placement;
- daily-budget equality from trajectory identity; and
- the operational 24-hour null from the activity-off-closed 16-hour reference
  and restricted fixtures.

## Validation

Require:

- both scripts parse;
- source-loaded no-write execution succeeds without changing Git status;
- guarded review-pack generation succeeds without changing Git status;
- exact file set, schemas, dimensions, ordering, analytical values, and CSV
  readback pass;
- the unchanged full suite reports `1287 PASS, 0 FAIL, 0 WARN, 0 SKIP` using
  explicit integer coercion in the count gate;
- `renv::status()` is synchronized;
- one temporary package build and installation succeeds;
- both scripts pass against the installed package;
- the figure is inspected;
- exact path, protected-surface, empty-index, output-regularity, and temporary
  cleanup gates pass; and
- one independent final review returns no Critical or Important finding.

Do not run `R CMD check` unless a material repair changes a package, test,
manual, metadata, namespace, or dependency surface.

## Exact Implementation Scope

Only these nine tracked or untracked paths may change after packet publication:

```text
README.md
docs/decisions/0010-feeding-opportunity-duration.md
docs/goals/rebuild-010-feeding-opportunity-duration/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-010-feeding-opportunity-duration.R
experiments/rebuild-010-review-pack.R
```

Ignored review outputs are limited to the four declared files.

## Exclusions

Do not add or change:

- production R, tests, manuals, exports, package metadata, dependencies,
  `.Rbuildignore`, or `.gitignore`;
- a feeding-opportunity constructor, mask, resolver, package variable, or
  production schema;
- compensatory feeding rates, redistribution, carry-over, choice, appetite,
  access competition, forage availability, or gut capacity;
- activity changes tied to feeding duration;
- duration-by-rate response surfaces;
- empirical calibration, species interpretation, viability, chronic decline,
  plants, water, thermoregulation, or space; or
- Goal 011 design or implementation.

## Stop Rules And Authority

- Stop if the clean synchronized Goal 009 publication commit is not the packet
  parent.
- Stop if frozen Goal, Plan, or Runbook hashes change after packet publication.
- Stop before changing a path outside the exact implementation scope.
- Stop if the 16-hour Goal 008 identity or declared analytical contract fails.
- Stop if the 12-hour case is mistakenly treated as fully identical to the Goal
  008 uncompensated fixture.
- Perform at most one focused repair pass for a material defect.
- Do not reset, clean, stash, force, amend, or delete prior ignored evidence.
- Packet commit and push plus immediate execution are authorized.
- Stop with the Goal 010 implementation uncommitted and unstaged. Commit or
  push it only with later explicit publication authority.

## Acceptance

Goal 010 is accepted when the declared duration screen, evidence tables,
figure, documentation, proportional validation, and independent review all
pass without changing production behavior.

The result will establish the daily accounting response to prescribed
intake-window duration under the four declared clock geometries. It will not
establish a generic trajectory effect of duration, that an animal voluntarily
uses every available hour, that the chosen rate is achievable, or that the
window is biologically realistic.
