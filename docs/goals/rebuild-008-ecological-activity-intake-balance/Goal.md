# Rebuild Goal 008: Ecological Activity And Intake Balance

## Status And Authority

Barry approved the scientific design and authorized execution on 2026-07-30.
Packet publication on `main` is part of that authority. The Goal 008
implementation must stop uncommitted after validation and independent review;
staging, committing, or pushing it requires separate publication authority.

## Principal Question

Under the unchanged Goal 007 equations, can the Goal 006 ecological reference
be extended with one prescribed night-spanning routine-activity schedule and
one explicitly co-prescribed intake increase that restores steady-cycle daily
body-energy neutrality, while keeping the activity and intake effects
separately identifiable?

## Completed Outcome

The repository contains three named synthetic ecological fixtures composed
only through existing public functions:

1. the accepted Goal 006 ecological intake with zero activity;
2. the same intake with prescribed routine activity and no intake increase;
   and
3. the same activity with uniformly higher prescribed intake during the same
   16 non-rest intervals.

The three-fixture chain demonstrates:

- the activity-only counterfactual leaves gut dynamics unchanged and removes
  exactly 800 kJ from body reserve per measured day;
- the added-input counterfactual supplies 800 kJ more per day and restores
  daily body-energy neutrality under the current periodic, linear, lossless,
  unlimited accounting system;
- the baseline and balanced cases are both daily-neutral but have different
  gut, assimilation, net body-rate, and body-reserve trajectories within each
  day; and
- balancing is a prescribed accounting construction, not adaptive feeding,
  behavioral compensation, demonstrated intake feasibility, or ecological
  equilibrium.

The balanced fixture becomes the normal synthetic ecological accounting
reference for later discussion. The Goal 006 ecological fixture remains its
zero-activity comparator, and the mathematical continuous reference remains
the permanent arithmetic and regression diagnostic.

## Preserved Model Contract

Goal 008 changes no package function, record, equation, schema, validator,
transition order, numerical tolerance, export, manual, dependency, or caller.

It reuses:

- `new_food_energy_parameters()`;
- `new_dry_matter_intake_schedule()`;
- `derive_ingested_available_energy_schedule()`;
- `new_routine_activity_expenditure_schedule()`;
- the existing gut and body state and parameter constructors; and
- `run_gut_body_energy_reference_cycle()`.

The balancing arithmetic remains explicit in the fixture:

```text
balanced daily prescribed ingestion
  = daily maintenance expenditure
  + daily prescribed routine-activity expenditure

3200 kJ = 2400 kJ + 800 kJ
```

No convenience runner, scenario class, feedback rule, intake adjustment
function, or generalized expenditure framework is added.

## Shared Fixture

All three scenarios use:

```text
initial gut available energy = 0 kJ
measurement body-energy reserve = 10000 kJ
gut release fraction = 0.25 h^-1
maintenance expenditure = 100 kJ h^-1
metabolizable-energy density = 10000 kJ kg^-1 DM
gut convergence relative tolerance = 100 * .Machine$double.eps
maximum gut-only burn-in = 100 d
measured duration = 2 d
active/intake intervals = hours 0:7 and 16:23
rest-closed intervals = hours 8:15
```

Each `hour_of_day` labels
`[hour_of_day, hour_of_day + 1)`. The rest block is therefore exactly
`[08:00, 16:00)`, repeated as `[32:00, 40:00)` on measured day 2.

The density is already metabolizable energy on a dry-matter basis. No
digestive efficiency, loss, or physiological assimilation calculation is
introduced.

## Exact Scenarios

Scenario order is fixed throughout tests, reports, tables, and figures:

```text
ecological_day_resting
ecological_activity_uncompensated
ecological_activity_prescribed_balance
```

### Ecological Zero-Activity Baseline

```text
scenario_id = ecological_day_resting

hours 0:7 and 16:23
  prescribed dry-matter intake = 0.015 kg DM h^-1
  derived gut input = 150 kJ h^-1
  prescribed routine activity = 0 kJ h^-1

hours 8:15
  all prescribed intake and activity = 0

daily dry-matter intake = 0.24 kg DM
daily gut input = 2400 kJ
daily routine activity = 0 kJ
daily maintenance = 2400 kJ
```

This is the accepted Goal 006 ecological reference with its explicit Goal 007
zero-activity schedule.

### Activity-Unbalanced Counterfactual

```text
scenario_id = ecological_activity_uncompensated

hours 0:7 and 16:23
  prescribed dry-matter intake = 0.015 kg DM h^-1
  derived gut input = 150 kJ h^-1
  prescribed routine activity = 50 kJ h^-1

hours 8:15
  all prescribed intake and activity = 0

daily dry-matter intake = 0.24 kg DM
daily gut input = 2400 kJ
daily routine activity = 800 kJ
daily maintenance = 2400 kJ
```

Relative to the baseline, this scenario must have identical dry-matter intake,
gut input, gut convergence, gut stocks, and assimilation. Its body and
whole-system changes differ by exactly `-800 kJ` on each measured day.

The baseline-minus-unbalanced body-reserve difference at continuous
measurement boundaries is:

```text
time h =  0    8   16   24   32   40   48
difference kJ = 0  400  400  800 1200 1200 1600
```

Thus the unbalanced body reserve closes measured days 1 and 2 exactly 800 and
1600 kJ below the matched baseline, respectively. Given the baseline's
accepted neutrality tolerance, the expected displayed closes are approximately
9200 and 8400 kJ.

### Activity-Balanced Prescribed Reference

```text
scenario_id = ecological_activity_prescribed_balance

hours 0:7 and 16:23
  prescribed dry-matter intake = 0.020 kg DM h^-1
  derived gut input = 200 kJ h^-1
  prescribed routine activity = 50 kJ h^-1

hours 8:15
  all prescribed intake and activity = 0

daily dry-matter intake = 0.32 kg DM
daily gut input = 3200 kJ
daily routine activity = 800 kJ
daily maintenance = 2400 kJ
```

The balanced input is exactly `4/3` of the baseline input at every hour. Under
the unchanged linear gut recurrence starting from the same empty state, the
balanced gut-boundary and assimilation trajectories are predicted to scale by
`4/3`. Goal 008 must verify that prediction within declared scale-aware
tolerances and verify, rather than assume, convergence on burn-in day 7.

At the periodic gut cycle, daily assimilation is predicted to equal 3200 kJ
within the existing numerical tolerance. Daily body and whole-system changes
must therefore be neutral within independently reconstructed tolerances, and
the displayed body reserve should close both measured days at approximately
10000 kJ.

## Counterfactual Estimands

### Activity Effect

Compare:

```text
ecological_day_resting
minus
ecological_activity_uncompensated
```

Require:

- exact equality of prescribed intake, convergence, measured gut ledgers, and
  assimilation;
- `50 kJ h^-1` net body-rate and one-hour body-change differences during hours
  `0:7` and `16:23`, and zero differences during hours `8:15`;
- the seven declared body-boundary landmarks; and
- exactly `800 kJ` less body and whole-system change per measured day in the
  unbalanced case.

### Added Prescribed-Input Effect

Compare:

```text
ecological_activity_prescribed_balance
minus
ecological_activity_uncompensated
```

Require:

- identical activity schedules and maintenance;
- `50 kJ h^-1` more prescribed gut input in the 16 non-rest intervals and zero
  difference during the rest block;
- `800 kJ` more daily prescribed ingestion and periodic assimilation;
- `800 kJ` more daily body and whole-system change; and
- balanced-minus-unbalanced closing body-reserve differences of approximately
  800 and 1600 kJ after measured days 1 and 2, within the summed accounting
  tolerances.

### Neutral-Reference Contrast

Compare the baseline and balanced references.

Both must be daily-neutral within their own reconstructed tolerances. Their
within-day trajectories must differ. Under the verified `4/3` gut scaling, the
balanced-minus-baseline net body-rate contrast is predicted to be:

```text
active intervals = baseline assimilation rate / 3 - 50 kJ h^-1
rest intervals   = baseline assimilation rate / 3
```

This timing contrast is scientifically useful because prescribed intake enters
the gut before later release; equal daily totals do not imply hourly
cancellation.

## Numerical Doctrine

Use the existing scenario-specific convergence, gut-ledger, body-ledger, and
whole-system tolerance constructions. Reconstruct daily tolerances from raw
hourly and daily ledgers, including routine-activity amounts.

For comparisons between scenarios, use the sum of the relevant
scenario-specific tolerances. Exact prescribed schedules and exact
baseline/unbalanced gut equality remain exact comparisons in memory.

For the balanced `4/3` prediction, require each observed scaled value to differ
from its prediction by no more than:

```text
100 * .Machine$double.eps * max(
  1,
  abs(observed value),
  abs(predicted value)
)
```

Decimal CSV read-back may use the same scale-aware tolerance. Bit-identical
serialization is not required.

## Focused Regression Contract

Add one focused test file protecting:

- exact scenario ids, hours, dry-matter rates, energy rates, activity rates,
  and daily totals;
- the eight rest-closed and 16 non-rest intervals;
- finite convergence and the predicted day-7 outcome for all three scenarios;
- exact baseline/unbalanced convergence and gut-ledger equality;
- measured day-1/day-2 gut repetition and exact state carry-over;
- balanced `4/3` gut-boundary and assimilation scaling;
- independently reconstructed gut, body, and whole-system balances;
- baseline and balanced daily neutrality;
- the exact activity-only daily and boundary contrasts;
- the exact added-input daily contrast;
- distinct baseline/balanced within-day net-rate and body-reserve trajectories;
- finite, non-negative gut and body stocks; and
- expected body status labels.

Do not repeat strict API, schema, mutation, overflow, or failure-mode tests
already covered by Goals 004-007. All required public interfaces already
exist, so there is no legitimate missing-interface red phase. A focused-test
failure is evidence to diagnose, not authority to change production code.

## No-Write Experiment

Add:

```text
experiments/rebuild-008-ecological-activity-intake-balance.R
```

It constructs all three dry-matter and activity schedules explicitly through
exported functions, runs the accepted reference-cycle runner, asserts the
complete scientific contract in memory, and prints compact schedule,
convergence, daily-balance, boundary, scaling, and counterfactual summaries.

Human-facing stocks and amounts use whole kilojoules. Rates and dry-matter
values retain appropriate precision. The script accepts no arguments and
writes no files.

## Review Pack

Add one guarded base-R review script:

```text
experiments/rebuild-008-review-pack.R
```

It accepts exactly one non-empty output-directory argument, rejects symbolic
links and undeclared entries, stages and validates all files before
publication, reads every CSV back through one shared evidence validator, and
writes exactly:

```text
outputs/rebuild-008-ecological-activity-intake-balance/
  figure-1-ecological-activity-intake-balance.png
  table-1-prescribed-schedules.csv
  table-2-convergence.csv
  table-3-daily-summary.csv
  table-4-hourly-ledgers.csv
```

The figure spans continuous measurement time `0-48 h` with four panels:

- prescribed gut-input rate;
- prescribed routine-activity rate;
- net body-energy rate; and
- body-energy reserve.

It identifies all three synthetic scenarios, marks the day boundary at 24 h,
and shades the repeated rest intervals `[08:00, 16:00)` and
`[32:00, 40:00)`. Axes state units. Titles and captions must not imply
behavior, voluntary compensation, feasible intake, or ecological equilibrium.

The exact table contracts are:

```text
table-1-prescribed-schedules.csv
rows = 72
order = scenario order above, then hour 0:23
columns =
  scenario_id
  hour_of_day
  prescribed_dry_matter_intake_kg_dm_h
  prescribed_ingested_available_energy_kj_h
  prescribed_routine_activity_expenditure_kj_h

table-2-convergence.csv
rows = 21
order = scenario order above, then burn-in day 1:7
columns =
  scenario_id
  burn_in_day
  gut_available_energy_initial_kj
  gut_available_energy_final_kj
  cycle_boundary_change_kj
  max_abs_previous_day_trajectory_difference_kj
  realized_convergence_tolerance_kj
  converged

table-3-daily-summary.csv
rows = 6
order = scenario order above, then measured day 1:2
columns =
  scenario_id
  measurement_day
  gut_available_energy_initial_kj
  total_prescribed_ingested_available_energy_kj
  total_assimilated_energy_kj
  expected_gut_energy_change_kj
  observed_gut_energy_change_kj
  gut_available_energy_final_kj
  gut_energy_balance_residual_kj
  body_energy_reserve_initial_kj
  total_maintenance_expenditure_kj
  total_prescribed_routine_activity_expenditure_kj
  expected_body_energy_change_kj
  observed_body_energy_change_kj
  body_energy_reserve_final_kj
  body_energy_balance_residual_kj
  total_system_energy_initial_kj
  expected_total_system_energy_change_kj
  observed_total_system_energy_change_kj
  total_system_energy_final_kj
  system_energy_balance_residual_kj
  body_energy_status

table-4-hourly-ledgers.csv
rows = 144
order = scenario order above, then measured day 1:2, then hour 0:23
columns =
  scenario_id
  measurement_day
  hour_of_day
  time_start_h
  time_end_h
  gut_available_energy_start_kj
  prescribed_ingested_available_energy_kj_h
  gut_release_fraction_h
  assimilated_energy_kj_h
  prescribed_ingested_available_energy_kj
  assimilated_energy_kj
  gut_energy_change_kj
  gut_available_energy_end_kj
  gut_energy_balance_residual_kj
  body_energy_reserve_start_kj
  maintenance_expenditure_kj_h
  prescribed_routine_activity_expenditure_kj_h
  net_body_energy_rate_kj_h
  maintenance_expenditure_kj
  prescribed_routine_activity_expenditure_kj
  body_energy_change_kj
  body_energy_reserve_end_kj
  body_energy_balance_residual_kj
  total_system_energy_start_kj
  total_system_energy_end_kj
  system_energy_balance_residual_kj
```

After CSV read-back, compact shared validation must reproduce all material
schedule, convergence, scaling, daily-balance, state-continuity, activity-only,
added-input, and boundary claims. Avoid duplicating the package test suite or
building a second simulation implementation in the review script.

Generated review files are ignored, retained for Barry's discussion, and never
commit inputs.

## Documentation Outcome

Add Decision 0008 and update the README, model charter, model specification,
roadmap, and Goal 008 Log.

Documentation must distinguish:

- the retained zero-activity ecological comparator from the new balanced
  reference;
- prescribed balance from adaptive or voluntary compensation;
- arithmetic neutrality from biological feasibility or equilibrium;
- expected `4/3` linear scaling from verified numerical evidence; and
- Goal 008 from Goal 009's later feeding-opportunity or intake-limit question.

No variable dictionary change is needed because Goal 008 adds no variable,
record, or schema.

## Exact Implementation Surface

After packet publication, implementation may change only:

```text
README.md
docs/decisions/0008-ecological-activity-intake-balance.md
docs/goals/rebuild-008-ecological-activity-intake-balance/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
experiments/rebuild-008-ecological-activity-intake-balance.R
experiments/rebuild-008-review-pack.R
tests/testthat/test-ecological-activity-intake-balance.R
```

Protect:

```text
DESCRIPTION
NAMESPACE
renv.lock
.Rbuildignore
.gitignore
all files under R/
all files under man/
docs/variable-dictionary.md
all Goal 001-007 packets
all Decision 0001-0007 files
all existing tests and experiments
all undeclared documentation
```

Any additional path requires a specific documented justification. A material
scope expansion requires Barry's approval.

## Validation And Acceptance

Goal 008 is accepted only when:

- the Goal, Plan, and Runbook hashes remain frozen;
- the new test and both experiment scripts parse;
- focused Goal 008 tests pass with no failure, warning, error, or skip;
- the full suite exceeds the Goal 007 baseline of 1037 passes with no failure,
  warning, error, or skip;
- the no-write experiment passes from the source-loaded and temporary
  installed package without changing repository status;
- all three fixtures satisfy their schedule, convergence, repetition,
  accounting, scaling, neutrality, and counterfactual contracts;
- the review pack contains exactly the five declared ignored files and passes
  complete material CSV read-back validation;
- the figure is nonblank, legible, unclipped, and faithful to the tables;
- `renv::status()` reports synchronization;
- external build, temporary installation, and
  `R CMD check --no-manual` return `Status: OK`;
- the complete changed-path set equals the nine authorized implementation
  paths;
- protected paths remain unchanged;
- the Git index remains empty during execution;
- no package tarball, check directory, or guarded temporary directory remains;
  and
- one independent final reviewer reports no Critical or Important defect.

Perform one focused repair pass only for material findings. Stop when the
high-value contract passes; do not iterate on cosmetic prose, plot styling, or
defensive duplication.

## Explicit Non-Goals

Goal 008 does not add:

- production R code, a public interface, or a new schema;
- an adaptive intake rule, feeding decision, or behavioral compensation;
- a feeding-permission mask, maximum intake rate, gut capacity, or feasibility
  constraint;
- directed locomotion, distance to water, movement mechanics, feeding cost, or
  thermic effect of food;
- dynamic body mass, viability, fitness, calibration, or parameter estimation;
- variable, stochastic, seasonal, sunrise-relative, or state-dependent
  schedules;
- protein, water, thermoregulation, plants, weather, space, individuals, or
  populations; or
- a general scenario or simulation framework.

## Stop Boundary

Stop after the three prescribed fixtures, their exact paired contrasts, focused
regression, no-write experiment, five review files, documentation, validation,
and independent review are complete.

Do not interpret `200 kJ h^-1` or `0.32 kg DM d^-1` as achievable intake. Do
not implement a feeding limit or infer whether the balanced reference is
biologically viable. Those are separate Goal 009 decisions.

Do not stage, commit, or push the Goal 008 implementation without Barry's
separate publication authority after he reviews the completed evidence.
