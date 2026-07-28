# Model Specification

## Status

Through Goal 007, prescribed dry-matter ingestion is converted to the existing
available-energy schedule, and the reference-cycle runner can repeat one
identical schedule to construct a numerical period-24 gut reference, reset body
energy once, and record two carried measurement days. Goal 006 adds two named
input fixtures and evidence only. Goal 007 adds one strict prescribed
routine-activity schedule and requires it explicitly in every body transition
and runner.

The fixed density is already metabolizable. Its product with dry matter is
treated as the accounting equivalent entering the existing gut available-energy
pool. This is a deliberately synthetic accounting model, not an empirical model
of food, digestion, activity, foraging, or macropod physiology.

## Food-Energy Bridge

The public interface is exactly:

```text
new_food_energy_parameters(
  metabolizable_energy_density_kj_kg_dm
)

new_dry_matter_intake_schedule(
  hour_of_day,
  prescribed_dry_matter_intake_kg_dm_h
)

derive_ingested_available_energy_schedule(
  parameters,
  schedule
)
```

`new_food_energy_parameters()` returns an exact plain named list containing
only `metabolizable_energy_density_kj_kg_dm`. Its value is a bare, finite,
strictly positive numeric scalar stored as a double, with units kJ kg^-1 DM.
The density is constant within a 24-hour run. Separate runs may use different
values.

`new_dry_matter_intake_schedule()` returns an exact base R data frame with:

```text
hour_of_day
prescribed_dry_matter_intake_kg_dm_h
```

It has 24 ordered rows. `hour_of_day` is the integer sequence `0:23` and labels
the half-open interval `[hour_of_day, hour_of_day + 1)`. Intake is a bare,
finite, non-negative numeric vector stored as doubles in kg DM h^-1. It is
prescribed ingestion, not offered or available forage, wet or as-fed mass, or
the outcome of a modeled feeding decision.

For every hour the converter applies:

```text
prescribed_ingested_available_energy_kj_h =
  prescribed_dry_matter_intake_kg_dm_h *
  metabolizable_energy_density_kj_kg_dm

kg DM h^-1 * kJ kg^-1 DM = kJ h^-1
```

It rejects a non-finite product and creates its return through the existing
`new_ingested_available_energy_schedule()` constructor. The returned base R
data frame retains the exact Goal 003 schema:

```text
hour_of_day
prescribed_ingested_available_energy_kj_h
```

The converter performs no rounding, one-hour amount calculation, state
transition, runner call, or write. The caller composes the converted schedule
with `run_gut_body_energy_day()` and retains each object separately.

Only the product of intake and density enters downstream dynamics. Multiplying
intake by a positive constant and dividing density by the same constant
produces identical schedules and energy trajectories. The two prescribed
inputs are therefore structurally non-identifiable from downstream outputs.
This accounting equivalence does not imply that foods or feeding regimes are
biologically interchangeable.

## Routine-Activity Schedule

The Goal 007 public constructor is exactly:

```text
new_routine_activity_expenditure_schedule(
  hour_of_day,
  prescribed_routine_activity_expenditure_kj_h
)
```

It returns an exact plain base R data frame with 24 ordered rows and only:

```text
hour_of_day
prescribed_routine_activity_expenditure_kj_h
```

`hour_of_day` is integer `0:23`. The expenditure rate is a bare numeric vector
of length 24 containing only finite, non-negative values, stored as doubles in
kJ h^-1. It is prescribed externally and is incremental to, not part of, the
fixed maintenance parameter.

The exact affected public interfaces are:

```text
step_body_energy(state, parameters, input_row, activity_row)

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

No activity argument has a default. `activity_row` must be exactly one row from
the routine-activity schedule, and its `hour_of_day` must match the body input
row. Rates in kJ h^-1 and one-hour amounts in kJ remain distinct fields even
though their numerical values match for the fixed one-hour transition.

## Implemented Controlled System

- Represent the internal stocks as `gut_available_energy_kj` and
  `body_energy_reserve_kj`.
- Use an explicit 24-hour clock with fixed one-hour state transitions.
- Treat `prescribed_dry_matter_intake_kg_dm_h` as controlled ingestion, with no
  intake limit, availability process, or body-state feedback.
- Treat `prescribed_ingested_available_energy_kj_h` as the controlled energy
  entering the gut, whether constructed directly through the retained Goal 003
  interface or derived by the Goal 004 bridge. It is not gross energy, plant
  biomass, or energy that has already entered the body.
- Release the fixed fraction `gut_release_fraction_h` of opening gut stock each
  hour.
- Transfer released energy one-for-one into the body-energy transition as its
  already-assimilated input.
- Apply the constant synthetic body parameter
  `maintenance_expenditure_kj_h`.
- Apply the separate prescribed input
  `prescribed_routine_activity_expenditure_kj_h` as an incremental body-energy
  sink.
- Fail before returning a result if a transition proposes a negative body
  reserve or any non-finite stock or accounting value. Do not clip stocks or
  impose an upper capacity.

The standalone Goal 002 body-only interface remains public. It accepts a
prescribed already-assimilated-energy schedule and now also requires the
routine-activity schedule explicitly.

Goal 004 adds no dynamic state, food choice, variable density, dry-matter gut
stock, or coupled food-gut-body runner. Goal 005 adds temporal orchestration and
diagnostics only. Goal 006 adds reference fixtures and review evidence only.
Goal 007 adds no dynamic state and changes no gut process.

## Hourly Transition Order

For an hour beginning with gut stock `G_t`, prescribed ingestion `I_t`,
release fraction `r`, body reserve `B_t`, maintenance expenditure `M`, and
prescribed routine-activity expenditure `R_t`, all energy quantities below
being one-hour amounts in kJ, the fixed transition is:

```text
assimilated_energy_kj = r * G_t
gut_available_energy_end_kj = G_t + I_t - assimilated_energy_kj
body_energy_reserve_end_kj =
  B_t + assimilated_energy_kj - M - R_t
```

The rate and one-hour amount have the same numerical value only because the
transition lasts exactly one hour. Release is calculated before current-hour
ingestion is added. Newly ingested energy therefore first becomes eligible for
release in the next transition. The body equation records interval totals and
does not assert a finer within-hour physiological order.

The closing gut and body stocks open the next hour. Body state, maintenance,
routine activity, and body-energy status do not feed back to the gut or
ingestion schedule.

When the Goal 004 bridge is used, `I_t` is the one-hour numerical equivalent of
the converted kJ h^-1 rate because every transition is exactly one hour. The
conversion itself returns a rate and does not calculate this amount.

## Repeated-Day Reference Cycle

The reference-cycle public interface is now:

```text
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

The state, parameter, gut-input schedule, and routine-activity schedule
arguments use their exact validators. The convergence control is a bare finite
numeric scalar strictly between zero and one, stored as a double. The maximum
burn-in is a bare integer scalar of at least two because convergence requires
successive daily trajectories.

Every burn-in day applies `step_gut_energy()` across the same ordered 24-row
schedule. Only gut state advances. For each day, the runner retains the 25
boundary stocks formed by the openings of hours 0 through 23 and the closing
stock after hour 23. Define:

```text
cycle_boundary_change_kj =
  current_boundary_stocks_kj[25] -
  current_boundary_stocks_kj[1]

max_abs_previous_day_trajectory_difference_kj =
  max(abs(current_boundary_stocks_kj -
          previous_boundary_stocks_kj))
```

The successive-day difference is unavailable on burn-in day 1. From day 2, the
realized scale is:

```text
max(
  1,
  abs(current_boundary_stocks_kj),
  abs(previous_boundary_stocks_kj),
  sum(abs(current_ingested_energy_kj)),
  sum(abs(current_assimilated_energy_kj)),
  sum(abs(previous_assimilated_energy_kj))
)
```

The relative tolerance multiplied by that scale is the realized absolute
tolerance in kJ. Both values must be finite and the tolerance strictly
positive. Convergence occurs on the first day when the maximum trajectory
difference and absolute cycle-boundary change are each no greater than the
realized tolerance. Failure within `max_burn_in_days` returns an error without
a partial result.

The converged closing gut stock opens measured day 1. The supplied measurement
body state is used exactly once at this boundary; no body transition occurs
during burn-in. The declared routine-activity schedule is validated by the
top-level runner but applies only when `run_gut_body_energy_day()` records
measured day 1 and measured day 2. Gut-only burn-in remains activity-free
because it advances no body state or history. The closing gut and body stocks
of measured day 1 open measured day 2. Each measured daily slice therefore
reduces exactly to a direct one-day runner result after removing
`measurement_day` and restoring canonical row names.

The body reset removes the one-off debt associated with an arbitrary empty-gut
initialization. It is a diagnostic protocol, not a physiological process. A
periodic gut cycle does not imply energetic neutrality: body energy may still
decline or increase on every repeated day.

## Numerical Diagnostics

Measured gut periodicity is verified by reconstructing both measured days'
25-boundary trajectories and comparing day 2 with day 1 using the final realized
cycle tolerance. Daily energetic neutrality is checked from numeric stocks and
flows. For each measured day:

```text
assimilation_total_tolerance_kj =
  cycle_tolerance_kj + gut_ledger_tolerance_kj

body_neutrality_tolerance_kj =
  assimilation_total_tolerance_kj + body_ledger_tolerance_kj
```

For the explicit zero-activity schedules used by the Goal 005 and Goal 006
neutrality fixtures, the gut must close within the cycle tolerance, total
assimilation must equal prescribed ingestion within the assimilation tolerance,
and observed body change must equal zero within the neutrality tolerance. These
thresholds describe numerical arithmetic only. The reserve-scaled
`body_energy_status` classification is not convergence or neutrality evidence.

For energy-matched schedules, timing equivalence compares prescribed ingestion,
maintenance, prescribed routine activity, total assimilation, observed gut
change, and observed body change. It does not compare phase-specific stocks,
absolute combined-system levels, or status labels. The equivalence is
interpreted only when every measured body stock is finite and non-negative.

The Goal 006 references pass an explicit zero-activity schedule. For any
activity-aware reconstruction:

```text
expected body change =
  total assimilation
  - total maintenance expenditure
  - total prescribed routine-activity expenditure

expected whole-system change =
  total prescribed ingestion
  - total maintenance expenditure
  - total prescribed routine-activity expenditure
```

Body and whole-system tolerance scales include the activity amounts. These
tolerances address floating-point arithmetic only.

## Mathematical And Ecological References

Goal 006 assigns different roles to two energy-matched fixtures. The
`mathematical_continuous` reference remains the permanent arithmetic,
convergence, accounting, and regression diagnostic. The
`ecological_day_resting` reference is the normal prescribed starting point for
later ecological interpretation.

Both use an empty initial gut, a 10000 kJ measurement body reserve, release
0.25 h^-1, maintenance 100 kJ h^-1, metabolizable-energy density
10000 kJ kg^-1 DM, the Goal 005 convergence tolerance, at most 100 gut-only
burn-in days, two carried measurement days, and an explicit 0 kJ h^-1
routine-activity schedule in every hour.

The mathematical reference is:

```text
hour_of_day = 0:23
prescribed_dry_matter_intake_kg_dm_h = 0.010
prescribed_ingested_available_energy_kj_h = 100
```

The ecological reference is:

```text
hour_of_day = 0:7 and 16:23
prescribed_dry_matter_intake_kg_dm_h = 0.015
prescribed_ingested_available_energy_kj_h = 150

hour_of_day = 8:15
prescribed_dry_matter_intake_kg_dm_h = 0
prescribed_ingested_available_energy_kj_h = 0
```

Each contains 0.24 kg DM and 2400 kJ per day. Because `hour_of_day` labels
`[hour_of_day, hour_of_day + 1)`, the ecological reference closes intake
exactly during `[08:00, 16:00)` and prescribes intake across the night-spanning
16-hour block from 16:00 through 08:00.

The ecological closure is prescribed intake. It is not an offered-food
schedule, feeding-permission mask, realized feeding decision, observation of
foraging behavior, or activity or sleep state. Its flat feeding block contains
no explicit crepuscular peaks.

Equal daily dry-matter intake, gut input, maintenance, and zero prescribed
routine activity define the operational null. In the current linear, lossless,
unlimited gut system, steady-cycle daily assimilation, observed gut change, and
observed body change should also agree within the existing scenario-specific
tolerances. The references must nevertheless have different within-day gut
stocks, gut release, and body reserve trajectories. This timing invariance is
an accounting property, not evidence of biological interchangeability or
empirical realism.

## Accounting

Each gut transition records prescribed ingestion, assimilation, gut-stock
change, and a gut balance residual. The body transition records assimilation,
fixed maintenance, prescribed routine activity, body-stock change, and a body
balance residual. The coupled runner also records combined modeled
gut-plus-body energy.

Assimilated energy is an internal transfer. It leaves the gut and enters the
body by the same amount, so it cancels from the combined-system balance.
Expected combined-system change is prescribed ingestion minus maintenance minus
prescribed routine activity. Scale-aware tolerances include the activity
amounts and address floating-point representation only; they do not permit
negative or non-finite stocks or substantive imbalance.

## Separation Of Roles

Dynamic state, fixed parameters, prescribed hourly inputs, process functions,
and recorded history are distinct plain R objects. A transition receives
validated state, parameters, and matching energy and activity rows, then
returns a new state and explicitly named fluxes without hidden mutation. The
coupled daily runner calls the gut and body transitions rather than duplicating
their arithmetic.

The food parameter, dry-matter schedule, derived energy schedule, initial
states, gut and body parameters, routine-activity schedule, and downstream
result remain separate. The pure converter does not hide composition behind a
higher-level runner. The reference-cycle runner accepts the existing energy and
activity schedules rather than absorbing the food records or converter.

## Implemented Outputs

`step_gut_energy()` returns a closing gut state and the one-hour ingestion,
assimilation, change, and residual fluxes.

`derive_ingested_available_energy_schedule()` returns the exact existing
24-row gut-input schedule and no food columns or attributes.

`step_body_energy()` returns a closing body state plus prescribed assimilation,
fixed maintenance, prescribed routine activity, net body-energy rate, body
change, and balance residual fluxes.

`run_body_energy_day()` returns a 14-column, 24-row `hourly` ledger and a
nine-column, one-row `daily` summary. Activity appears as its prescribed rate,
one-hour amount, and daily total; no redundant total-expenditure field is
stored.

`run_gut_body_energy_day()` returns a plain list containing:

- one 24-column, 24-row `hourly` data frame with clock fields, opening and
  closing gut and body stocks, rates, one-hour amounts including routine
  activity, stock changes, combined modeled energy, and separate gut, body, and
  system residuals; and
- one 20-column, one-row `daily` data frame derived from the hourly ledger, with
  gut, body, and combined-system totals including prescribed routine activity,
  expected and observed changes, residuals, and the Goal 002 body-reserve
  status.

`run_gut_body_energy_reference_cycle()` returns an exact plain list containing:

- a `convergence` data frame with one row per completed burn-in day and the
  seven columns defined in `variable-dictionary.md`;
- a 48-row `hourly` data frame that prepends `measurement_day` to the current
  24-column coupled hourly ledger; and
- a two-row `daily` data frame that prepends `measurement_day` to the current
  20-column coupled daily summary.

Exact names and units are defined in `variable-dictionary.md`. No package
function writes a CSV, RDS, figure, cache, or evidence bundle.

## Synthetic Demonstrations

The Goal 004 zero, constant, and pulse conversion fixtures use
`metabolizable_energy_density_kj_kg_dm = 10000`. These are synthetic arithmetic
choices, not measured food properties or macropod intake estimates.

- **Zero intake:** 0 kg DM h^-1 derives exactly 0 kJ h^-1 in all 24 hours.
- **Constant bridge:** 0.010 kg DM h^-1 derives exactly 100 kJ h^-1. Across the
  fixed day, prescribed intake is analytically 0.24 kg DM and derived available
  energy is 2400 kJ.
- **Pulse bridge:** 0.040 kg DM h^-1 in hour 0 and zero thereafter derives 400
  kJ h^-1 in hour 0 and zero thereafter.
- **Factorization equivalence:** 0.010 kg DM h^-1 at 10000 kJ kg^-1 DM and
  0.020 kg DM h^-1 at 5000 kJ kg^-1 DM both derive exactly 100 kJ h^-1. Their
  prescribed food inputs remain scientifically distinct.

The downstream fixtures use `gut_release_fraction_h = 0.25`, begin with
`body_energy_reserve_kj = 5000`, and pass an explicit zero-activity schedule.

- **Equilibrium:** opening gut stock 400 kJ, ingestion 100 kJ h^-1, and
  maintenance 100 kJ h^-1 keep both stocks constant.
- **Empty start:** opening gut stock 0 kJ with the same ingestion and
  maintenance approaches the 400 kJ gut equilibrium geometrically; the
  temporary body-reserve loss equals energy accumulating in the gut.
- **Single pulse:** 400 kJ enters an empty gut in hour 0 with zero maintenance.
  Nothing is assimilated in hour 0; subsequent release is geometric while
  combined gut-plus-body energy remains constant.

The converted constant and pulse schedules are exactly identical to their
manually constructed Goal 003 schedules and therefore produce identical
downstream results. The pulse retains the accepted assimilation-rate sequence
of 0, 100, 75, and 56.25 kJ h^-1 in hours 0 through 3.

These fixtures test conversion, update order, buffering, and conservation. They
are not estimates of food energy, gut residence time, maintenance, intake, gut
fill, physiological stress, viability, or ecological equilibrium.

The Goal 005 reference fixtures use an empty initial gut, measurement body
reserve 10000 kJ, release 0.25 h^-1, maintenance 100 kJ h^-1, density
10000 kJ kg^-1 DM, relative tolerance `100 * .Machine$double.eps`, and at most
100 burn-in days. They now pass an explicit zero-activity schedule.

- **Zero intake:** the gut is identically empty and periodic, while body reserve
  declines by 2400 kJ on each measured day.
- **Constant intake:** 0.010 kg DM h^-1 in every hour supplies 0.24 kg DM and
  2400 kJ per day. The gut approaches its 400 kJ fixed point and the measured
  body balance is neutral within the declared tolerances.
- **Concentrated late feeding:** 0.040 kg DM h^-1 in hours 18 through 23 and zero
  earlier also supplies 0.24 kg DM and 2400 kJ per day. Gut energy crosses the
  day boundary, producing a non-constant period-24 gut, assimilation, and body
  trajectory.

The constant and concentrated fixtures have equal daily ingestion,
assimilation, maintenance, gut change, and body change within their declared
numeric tolerances, while their within-day trajectories differ. This is
conditional on the verified 10000 kJ body paths completing without crossing
the non-negative reserve boundary and on the current unlimited, linear,
lossless system. It is not a biological claim about feeding schedules.

Goal 006 retains the constant fixture as `mathematical_continuous` and adds
`ecological_day_resting`. At density 10000 kJ kg^-1 DM, the ecological fixture
derives 150 kJ h^-1 from 0.015 kg DM h^-1 in hours 0 through 7 and 16 through
23 and derives zero intake in hours 8 through 15. Both named references contain
0.24 kg DM and 2400 kJ per day. Their daily energy totals provide an
operational null, while their steady-cycle within-day stock and flow
trajectories differ. Both now pass an explicit zero-activity schedule and retain
their accepted shared numerical results.

This minimally ecological fixture is a generic synthetic day-resting,
nocturnally active convention. It is not a species schedule, true crepuscular
pattern, maximum feasible intake, or model of behavior or activity.

Goal 007 uses the mathematical continuous reference for two matched diagnostic
fixtures:

- `zero_routine_activity` prescribes 0 kJ h^-1 in hours 0 through 23. It is the
  regression control and preserves every pre-Goal-007 numerical field.
- `four_hour_routine_activity_pulse` prescribes 50 kJ h^-1 in hours 8 through
  11, the interval `[08:00, 12:00)`, and 0 kJ h^-1 otherwise. Its daily
  prescribed routine-activity expenditure is exactly 200 kJ.

Relative to the control, the pulse changes `net_body_energy_rate_kj_h` and
`body_energy_change_kj` by exactly -50 in each of the four pulse intervals and
by zero outside them. The body-reserve difference is -200 kJ at measured day 1
close and -400 kJ at measured day 2 close. Gut stocks, prescribed ingestion,
assimilation, gut accounting, and day-7 convergence remain exactly unchanged.

The zero fixture tests regression preservation. The pulse tests the new
arithmetic and accounting pathway. Its timing and magnitude do not represent
animal behavior, locomotion, or an empirically calibrated activity pattern or
physiological cost.

## Exclusions And Stop

The model does not represent variable or stochastic days, a configurable
measurement horizon, seasons, chronic decline, recovery, viability criteria,
offered or wet forage, water content, gross or digestible energy, time-varying
density, multiple food types, food choice, preference, diet mixing, nutrient
composition, assimilation efficiency, digestive loss, waste, dry-matter gut
state, gut capacity, intake limits, multiple gut compartments, feeding
decisions, behavior, activity choice or feedback, directed locomotion,
feeding-associated expenditure, thermic effect of food, total metabolism,
dynamic body mass, protein, water, thermoregulation, plants, weather, space,
individuals, populations, empirical calibration, parameter estimation, or
uncertainty analysis.

Goal 007 ends after the explicit routine-activity interface, expanded
accounting, zero regression, diagnostic pulse, no-write experiment, and ignored
review outputs are validated and reviewed. Goal 008 remains a discussion gate
for a later ecological day/night activity schedule and intake rebalancing.
Goal 007 authorizes neither that scenario nor any later model mechanism.

The historical implementation is private at `BWBrook/herbivoreTTR-legacy`, tag
`legacy-final-2026-07-16`; the pre-freeze scientific baseline is
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
