# Model Specification

## Status

Goal 005 composes the accepted Goal 003-004 system without changing its
records, conversions, transitions, or one-day runner. Prescribed dry-matter
ingestion is still converted to the existing available-energy schedule. The new
reference-cycle runner can repeat one identical schedule to construct a
numerical period-24 gut reference, reset body energy once, and record two
carried measurement days.

The fixed density is already metabolizable. Its product with dry matter is
treated as the accounting equivalent entering the existing gut available-energy
pool. This is a deliberately synthetic accounting model, not an empirical model
of food, digestion, foraging, or macropod physiology.

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
- Transfer released energy one-for-one into the unchanged body-energy
  transition as its already-assimilated input.
- Apply the constant body parameter `maintenance_expenditure_kj_h`.
- Fail before returning a result if a transition proposes a negative body
  reserve or any non-finite stock or accounting value. Do not clip stocks or
  impose an upper capacity.

The standalone Goal 002 body-only interface remains public and continues to
accept a prescribed already-assimilated-energy schedule.

Goal 004 adds no dynamic state, food choice, variable density, dry-matter gut
stock, or coupled food-gut-body runner. Goal 005 adds temporal orchestration and
diagnostics only.

## Hourly Transition Order

For an hour beginning with gut stock `G_t`, prescribed ingestion `I_t`,
release fraction `r`, body reserve `B_t`, and maintenance `M`, the fixed
one-hour transition is:

```text
assimilated_energy_kj = r * G_t
gut_available_energy_end_kj = G_t + I_t - assimilated_energy_kj
body_energy_reserve_end_kj = B_t + assimilated_energy_kj - M
```

The rate and one-hour amount have the same numerical value only because the
transition lasts exactly one hour. Release is calculated before current-hour
ingestion is added. Newly ingested energy therefore first becomes eligible for
release in the next transition.

The closing gut and body stocks open the next hour. Body state, maintenance,
and body-energy status do not feed back to the gut or ingestion schedule.

When the Goal 004 bridge is used, `I_t` is the one-hour numerical equivalent of
the converted kJ h^-1 rate because every transition is exactly one hour. The
conversion itself returns a rate and does not calculate this amount.

## Repeated-Day Reference Cycle

The Goal 005 public interface is:

```text
run_gut_body_energy_reference_cycle(
  initial_gut_state,
  measurement_body_state,
  gut_parameters,
  body_parameters,
  schedule,
  gut_convergence_relative_tolerance,
  max_burn_in_days
)
```

The first five arguments use the existing exact validators. The convergence
control is a bare finite numeric scalar strictly between zero and one, stored as
a double. The maximum burn-in is a bare integer scalar of at least two because
convergence requires successive daily trajectories.

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
during burn-in. The unchanged `run_gut_body_energy_day()` then records measured
day 1. Its closing gut and body stocks open measured day 2, which is another
unchanged one-day call. Each measured daily slice therefore reduces exactly to
a direct Goal 003 runner result after removing `measurement_day` and restoring
canonical row names.

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

The gut must close within the cycle tolerance, total assimilation must equal
prescribed ingestion within the assimilation tolerance, and observed body
change must equal zero within the neutrality tolerance. These thresholds
describe numerical arithmetic only. The reserve-scaled
`body_energy_status` classification is not convergence or neutrality evidence.

For energy-matched schedules, timing equivalence compares prescribed ingestion,
maintenance, total assimilation, observed gut change, and observed body change.
It does not compare phase-specific stocks, absolute combined-system levels, or
status labels. The equivalence is interpreted only when every measured body
stock is finite and non-negative.

## Accounting

Each gut transition records prescribed ingestion, assimilation, gut-stock
change, and a gut balance residual. The existing body transition records
assimilation, maintenance, body-stock change, and a body balance residual. The
coupled runner also records combined modeled gut-plus-body energy.

Assimilated energy is an internal transfer. It leaves the gut and enters the
body by the same amount, so it cancels from the combined-system balance.
Expected combined-system change is prescribed ingestion minus maintenance.
Scale-aware tolerances address floating-point representation only; they do not
permit negative or non-finite stocks or substantive imbalance.

## Separation Of Roles

Dynamic state, fixed parameters, prescribed hourly inputs, process functions,
and recorded history are distinct plain R objects. A transition receives
validated state, parameters, and one schedule row, then returns a new state and
explicitly named fluxes without hidden mutation. The coupled daily runner calls
the gut transition and the unchanged body transition rather than duplicating
their arithmetic.

The food parameter, dry-matter schedule, derived energy schedule, initial
states, gut and body parameters, and downstream result remain separate. The
pure converter does not hide composition behind a higher-level runner.
The reference-cycle runner accepts the existing energy schedule rather than
absorbing the food records or converter.

## Implemented Outputs

`step_gut_energy()` returns a closing gut state and the one-hour ingestion,
assimilation, change, and residual fluxes.

`derive_ingested_available_energy_schedule()` returns the exact existing
24-row gut-input schedule and no food columns or attributes.

`run_gut_body_energy_day()` returns a plain list containing:

- one 24-row `hourly` data frame with clock fields, opening and closing gut and
  body stocks, rates, one-hour amounts, stock changes, combined modeled energy,
  and separate gut, body, and system residuals; and
- one one-row `daily` data frame derived from the hourly ledger, with gut,
  body, and combined-system totals, expected and observed changes, residuals,
  and the Goal 002 body-reserve status.

`run_gut_body_energy_reference_cycle()` returns an exact plain list containing:

- a `convergence` data frame with one row per completed burn-in day and the
  seven columns defined in `variable-dictionary.md`;
- a 48-row `hourly` data frame that prepends `measurement_day` to the unchanged
  21-column coupled hourly ledger; and
- a two-row `daily` data frame that prepends `measurement_day` to the unchanged
  19-column coupled daily summary.

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

The downstream fixtures use `gut_release_fraction_h = 0.25` and begin with
`body_energy_reserve_kj = 5000`.

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
100 burn-in days.

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

## Exclusions And Stop

The model does not represent variable or stochastic days, a configurable
measurement horizon, seasons, chronic decline, recovery, viability criteria,
offered or wet forage, water content, gross or digestible energy, time-varying
density, multiple food types, food choice, preference, diet mixing, nutrient
composition, assimilation efficiency, digestive loss, waste, dry-matter gut
state, gut capacity, intake limits, multiple gut compartments, feeding
decisions, behavior, activity, dynamic body mass, protein, water,
thermoregulation, plants, weather, space, individuals, populations, empirical
calibration, parameter estimation, or uncertainty analysis.

No subsequent model layer is specified or authorized. Goal 005 ends after the
identical-day gut reference, one body reset, two carried measurement days,
synthetic diagnostics, and ignored review outputs are validated and reviewed.

The historical implementation is private at `BWBrook/herbivoreTTR-legacy`, tag
`legacy-final-2026-07-16`; the pre-freeze scientific baseline is
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
