# Rebuild Goal 007: Routine-Activity Expenditure

## Status And Authority

Barry approved this design and authorized Goal 007 execution on 2026-07-28.
The Goal, Plan, and Runbook must be reviewed, frozen, committed, and pushed
from the clean Goal 006 baseline before implementation begins.

Execution authorizes only the paths and effects declared here. It does not
authorize staging, committing, or pushing the Goal 007 implementation.
Publication of the reviewed implementation requires separate authority.

## Principal Question

Can prescribed routine-activity expenditure be added as an explicit external
body-energy sink throughout the body-only, coupled gut-body, and repeated-day
reference runners while leaving gut dynamics unchanged and preserving exact
hourly, daily, and whole-system accounting?

## Completed Outcome

The package contains one strict routine-activity expenditure schedule and
requires it explicitly in every body transition and runner. The existing
synthetic maintenance rate remains a fixed parameter. Routine activity is a
separate prescribed hourly input incremental to maintenance.

At completion:

- a zero-activity schedule preserves every pre-Goal-007 numerical trajectory
  on shared ledger columns;
- a four-hour diagnostic pulse produces the exact additional body-energy loss
  implied by its prescribed expenditure;
- the pulse changes no gut stock, ingestion, release, convergence, or other
  gut quantity relative to a matched zero-activity control;
- body and whole-system ledgers expose routine activity explicitly and close
  within scale-aware numerical tolerances;
- the Goal 006 mathematical and ecological references remain valid when each
  receives an explicit zero-activity schedule; and
- a compact review pack makes both the activity effect and gut invariance
  directly inspectable.

## Scientific Meaning

Routine activity is a prescribed, finite, non-negative expenditure above the
existing constant maintenance term. It is the model's first separable
non-maintenance expenditure component.

The current maintenance parameter remains a synthetic baseline. It is not
relabelled or interpreted as an empirically parameterized basal metabolic
rate. Routine activity is not thermic effect of food, directed locomotion,
exercise, total metabolism, observed behaviour, or an emergent response.

The diagnostic pulse is an arithmetic probe. Its timing and magnitude are not
claims about kangaroos, daytime activity, feeding effort, or field energetics.

## Exact Public Interface

Add:

```r
new_routine_activity_expenditure_schedule(
  hour_of_day,
  prescribed_routine_activity_expenditure_kj_h
)
```

It returns an exact plain base-R data frame with 24 ordered rows and only:

```text
hour_of_day
prescribed_routine_activity_expenditure_kj_h
```

Require:

- `hour_of_day` to be integer `0:23`, in order;
- the expenditure vector to be a bare numeric vector of length 24;
- every expenditure rate to be finite and non-negative; and
- accepted values to be stored as doubles without attributes.

Change the existing signatures to:

```r
step_body_energy(
  state,
  parameters,
  input_row,
  activity_row
)

run_body_energy_day(
  initial_state,
  parameters,
  schedule,
  routine_activity_schedule
)

run_gut_body_energy_day(
  initial_gut_state,
  initial_body_state,
  gut_parameters,
  body_parameters,
  schedule,
  routine_activity_schedule
)

run_gut_body_energy_reference_cycle(
  initial_gut_state,
  measurement_body_state,
  gut_parameters,
  body_parameters,
  schedule,
  routine_activity_schedule,
  gut_convergence_relative_tolerance,
  max_burn_in_days
)
```

No activity argument has a default. Do not add an overload, wrapper,
compatibility interface, implicit zero schedule, option, or global setting.
Every caller must state its activity forcing explicitly.

`step_body_energy()` requires `activity_row` to be exactly one row from the new
schedule. Its `hour_of_day` must match `input_row$hour_of_day`.

## Exact Accounting

For each fixed one-hour interval, let:

```text
B_t = opening body-energy reserve, kJ
A_t = already-assimilated energy entering the body, kJ
M   = fixed maintenance expenditure, kJ
R_t = prescribed routine-activity expenditure, kJ
I_t = prescribed energy entering the gut, kJ
G_t = opening gut available-energy stock, kJ
```

Then:

```text
B_(t+1) = B_t + A_t - M - R_t

body-energy change =
  assimilated energy
  - maintenance expenditure
  - routine-activity expenditure

(G+B)_(t+1) - (G+B)_t =
  ingested available energy
  - maintenance expenditure
  - routine-activity expenditure
```

The one-hour rate and amount have the same numerical value only because every
transition is exactly one hour. These terms are interval totals; their
arithmetic does not assert a finer within-hour physiological order.

Routine activity does not alter the gut equation, release fraction, food
conversion, ingestion schedule, assimilation transfer, or convergence
criterion. Include routine-activity amounts in body and whole-system residual
calculations and tolerance scales.

Do not store a redundant total-expenditure column in production ledgers.
Review code may derive total expenditure as maintenance plus routine activity.

## Ledger Additions

Add exactly these fields where applicable:

```text
prescribed_routine_activity_expenditure_kj_h
prescribed_routine_activity_expenditure_kj
total_prescribed_routine_activity_expenditure_kj
```

The hourly rate and amount appear in body-only and coupled hourly ledgers. The
daily total appears in body-only and coupled daily summaries. The measured
reference-cycle ledgers inherit those expanded schemas after
`measurement_day`.

The seven-column gut convergence table is unchanged.

`net_body_energy_rate_kj_h`, expected body change, expected whole-system
change, body status, and the corresponding residuals must use the expanded
equations. Numerical stocks and fluxes remain the primary evidence; status
labels are not balance evidence.

## Reference-Cycle Boundary

The top-level reference-cycle runner validates and retains the declared
activity schedule. Gut-only burn-in remains activity-free because it advances
no body state or body history.

The activity schedule is applied only to the two measured body days. The
measurement body reserve is still used once, and exact gut and body carry-over
continues from measured day 1 to measured day 2.

## Exact Diagnostic Fixtures

Both Goal 007 diagnostic scenarios use the Goal 006 mathematical continuous
reference:

```text
prescribed dry-matter intake = 0.010 kg DM h^-1 in all 24 intervals
derived gut input = 100 kJ h^-1 in all 24 intervals
gut release fraction = 0.25 h^-1
maintenance expenditure = 100 kJ h^-1
initial gut available energy = 0 kJ before burn-in
measurement body-energy reserve = 10000 kJ
gut convergence relative tolerance = 100 * .Machine$double.eps
maximum gut-only burn-in = 100 d
measured duration = 2 d
```

### Zero Control

```text
scenario_id = zero_routine_activity
routine activity = 0 kJ h^-1 in hours 0:23
daily routine activity = 0 kJ
```

This scenario must reproduce the Goal 006 mathematical reference exactly on
every pre-existing numerical field after excluding the intentionally added
activity columns.

### Four-Hour Pulse

```text
scenario_id = four_hour_routine_activity_pulse
routine activity = 50 kJ h^-1 in hours 8:11
routine activity = 0 kJ h^-1 in hours 0:7 and 12:23
pulse interval = [08:00, 12:00)
daily routine activity = 200 kJ
```

Relative to the matched zero control:

```text
hours 0:7 net_body_energy_rate_kj_h difference = 0 kJ h^-1
hours 8:11 net_body_energy_rate_kj_h difference = -50 kJ h^-1
hours 12:23 net_body_energy_rate_kj_h difference = 0 kJ h^-1

hours 0:7 body_energy_change_kj difference =
  0 kJ per one-hour transition
hours 8:11 body_energy_change_kj difference =
  -50 kJ per one-hour transition
hours 12:23 body_energy_change_kj difference =
  0 kJ per one-hour transition

daily body change difference = -200 kJ
gut trajectory difference = exactly 0 kJ
ingestion difference = exactly 0 kJ
assimilation difference = exactly 0 kJ
```

The pulse body reserve is unchanged through the 08:00 boundary, declines by
exactly 50 kJ over each of the next four intervals, reaches 9800 kJ at 12:00
on measured day 1, and remains flat to the day boundary. Measured day 2 starts
at 9800 kJ and closes at 9600 kJ. The zero control remains at 10000 kJ.

Thus the pulse-control body-reserve difference is:

```text
day-1 close = -200 kJ
day-2 close = -400 kJ
incremental loss on each day = -200 kJ
```

Both scenarios must retain the same day-7 gut convergence and exact two-day
gut repetition.

## Focused Regression Contract

Tests must protect:

- exact constructor signature, schema, storage, validation, and purity;
- required activity arguments on all four public functions;
- one-row schema and exact hour alignment at the transition boundary;
- exact zero-activity numerical preservation on shared columns;
- exact pulse schedule, rate, one-hour amount, and daily total;
- the four `-50 kJ` pulse transitions and `-200 kJ` daily increment;
- body-reserve boundary landmarks at 08:00, 12:00, day 1 close, and day 2
  close;
- unchanged gut stock, ingestion, assimilation, and convergence between the
  matched activity scenarios;
- exact state continuity and day-to-day carry-over;
- independently reconstructed body and whole-system balances and tolerance
  scales;
- negative-closing-reserve failure caused by activity;
- no mutation of states, parameters, schedules, or rows; and
- explicit zero schedules in all accepted Goal 002-006 callers and fixtures.

Do not duplicate unrelated gut, food, convergence, or strict validation tests.

## Experiments And Review Pack

Add one thin no-write experiment:

```text
experiments/rebuild-007-routine-activity-expenditure.R
```

It constructs both scenarios through exported functions, asserts the complete
scientific contract in memory, and prints compact schedule, convergence,
daily, boundary, and counterfactual summaries. Human-facing energy amounts use
whole kilojoules; internal assertions retain full precision.

Add one guarded base-R review script:

```text
experiments/rebuild-007-review-pack.R
```

It accepts exactly one output-directory argument, stages and validates all
files before publication, rejects a symbolic-link destination and undeclared
entries, reads every CSV back, and writes exactly:

```text
outputs/rebuild-007-routine-activity-expenditure/
  figure-1-routine-activity-accounting.png
  table-1-routine-activity-schedules.csv
  table-2-convergence.csv
  table-3-daily-summary.csv
  table-4-hourly-ledgers.csv
```

The figure covers the two measured days on a continuous 0-48 hour axis and
contains four panels:

- prescribed routine-activity expenditure rate;
- pulse-minus-control gut boundary difference;
- `net_body_energy_rate_kj_h`, labelled in kJ h^-1; and
- body-energy reserve.

Mark both pulse windows `[08:00, 12:00)` and `[32:00, 36:00)` and the 24-hour
day boundary. The gut-difference panel must visibly demonstrate a zero trace.
Titles and captions must describe synthetic diagnostic scenarios, not animal
behaviour.

The tables retain sufficient numerical precision to reproduce every check
after CSV read-back. Their exact contracts are:

```text
table-1-routine-activity-schedules.csv
rows = 48
order = zero_routine_activity hours 0:23,
        then four_hour_routine_activity_pulse hours 0:23
columns =
  scenario_id
  hour_of_day
  prescribed_routine_activity_expenditure_kj_h

table-2-convergence.csv
rows = 14
order = zero_routine_activity burn-in days 1:7,
        then four_hour_routine_activity_pulse burn-in days 1:7
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
rows = 4
order = zero_routine_activity measured days 1:2,
        then four_hour_routine_activity_pulse measured days 1:2
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
rows = 96
order = zero_routine_activity measured day 1 hours 0:23,
        zero_routine_activity measured day 2 hours 0:23,
        four_hour_routine_activity_pulse measured day 1 hours 0:23,
        four_hour_routine_activity_pulse measured day 2 hours 0:23
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

Generated review files are ignored, retained for Barry's discussion, and
never commit inputs.

## Documentation Outcome

Add Decision 0007 and update the README, model charter, model specification,
roadmap, and variable dictionary.

Documentation must distinguish:

- fixed synthetic maintenance from prescribed incremental routine activity;
- externally imposed activity from behaviour or locomotion;
- zero-activity regression from the diagnostic pulse;
- arithmetic accounting evidence from empirical physiology; and
- Goal 007 from the later ecological activity schedule and intake
  rebalancing planned for Goal 008.

## Exact Implementation Surface

After packet publication, Goal 007 implementation may change only:

```text
README.md
NAMESPACE
R/routine-activity-expenditure-records.R
R/body-energy-transition.R
R/body-energy-run.R
R/gut-body-energy-run.R
R/gut-body-energy-reference-cycle.R
R/herbivoreTTR-package.R
man/new_routine_activity_expenditure_schedule.Rd
man/step_body_energy.Rd
man/run_body_energy_day.Rd
man/run_gut_body_energy_day.Rd
man/run_gut_body_energy_reference_cycle.Rd
man/herbivoreTTR-package.Rd
tests/testthat/test-routine-activity-expenditure.R
tests/testthat/test-body-energy-transition.R
tests/testthat/test-body-energy-scenarios.R
tests/testthat/test-gut-body-energy-scenarios.R
tests/testthat/test-gut-body-energy-reference-cycle.R
tests/testthat/test-food-energy-conversion.R
tests/testthat/test-ecological-daily-reference.R
experiments/rebuild-002-body-energy-ledger.R
experiments/rebuild-003-one-pool-gut-buffer.R
experiments/rebuild-003-review-pack.R
experiments/rebuild-004-controlled-food-energy-bridge.R
experiments/rebuild-005-repeated-day-reference-cycle.R
experiments/rebuild-005-review-pack.R
experiments/rebuild-006-ecological-daily-reference.R
experiments/rebuild-006-review-pack.R
experiments/rebuild-007-routine-activity-expenditure.R
experiments/rebuild-007-review-pack.R
docs/decisions/0007-routine-activity-expenditure.md
docs/goals/rebuild-007-routine-activity-expenditure/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
```

This is an intentionally broad caller migration for one narrow mechanism.
Explicitness is preferred to a hidden zero default.

Protect:

```text
DESCRIPTION
renv.lock
.Rbuildignore
.gitignore
R/food-energy-conversion.R
R/food-energy-records.R
R/gut-energy-records.R
R/gut-energy-transition.R
all Goal 001-006 packets
all Decision 0001-0006 files
all undeclared tests, experiments, manuals, and documentation
```

Roxygen may change only `NAMESPACE` and the six declared manual files.

## Validation And Acceptance

Goal 007 is accepted only when:

- the packet hashes remain frozen;
- all new and changed R files parse;
- focused routine-activity tests pass with no failure, warning, error, or
  skip;
- the full suite exceeds the Goal 006 baseline of 949 passes with no failure,
  warning, error, or skip;
- every accepted Goal 002-006 experiment and review script parses;
- the no-write Goal 007 experiment passes from source and a temporary
  installed package;
- all zero and pulse outcomes match the exact contract;
- the review pack contains exactly the five declared ignored files and passes
  complete CSV read-back;
- the figure is nonblank, legible, unclipped, and faithful to the tables;
- `renv::status()` reports synchronization;
- roxygen produces only the declared namespace/manual changes;
- external build, temporary installation, and
  `R CMD check --no-manual` return `Status: OK`;
- the changed path set equals the authorized surface;
- protected paths remain unchanged;
- the Git index remains empty during execution;
- no package tarball, check directory, or guarded temporary directory remains;
  and
- one independent final reviewer reports no Critical or Important defect.

Perform one focused repair pass only for material findings. Stop when the
fit-for-purpose core and explicit gates pass; do not iterate on marginal prose,
plot styling, or defensive duplication.

## Stop Boundary

Goal 007 does not add:

- the ecological day/night activity schedule;
- intake rebalancing against activity;
- feeding-associated expenditure or thermic effect of food;
- directed locomotion, distance to water, movement mechanics, or space;
- behaviour, choice, feedback, or stochastic forcing;
- dynamic body mass, allometry, calibration, viability, or fitness;
- protein, water, thermoregulation, plants, or plant-herbivore coupling; or
- a general expenditure taxonomy or simulation framework.

Goal 008 remains a discussion gate. No later mechanism or scenario is
authorized by Goal 007.
