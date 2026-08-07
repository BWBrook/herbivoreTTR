# Model Specification

## Status

Through Goal 012, prescribed dry-matter ingestion is converted to the existing
available-energy schedule, and the reference-cycle runner can repeat one
identical schedule to construct a numerical period-24 gut reference, reset body
energy once, and record two carried measurement days. Goal 006 adds two named
input fixtures and evidence only. Goal 007 adds one strict prescribed
routine-activity schedule and requires it explicitly in every body transition
and runner. Goal 008 adds a three-fixture ecological evidence chain without
changing that executable contract. Goal 009 adds a synthetic intake-ceiling
threshold screen in evidence clients only. Goal 010 adds a four-fixture
prescribed intake window duration screen in the same evidence-only layer. Goal
011 uses evidence clients to chain existing one-day calls across one lower-rate
day and two return-to-reference days. Goal 012 chains a separate fixed four-day
control and prescribed-pulse sequence. All of these evidence goals leave the
executable contract unchanged.

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
  production intake limit, availability process, or body-state feedback.
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
Goal 007 adds no dynamic state and changes no gut process. Goal 008 adds no
production code, equation, interface, record, schema, validator, or variable.
Goal 009 also adds none of these; its clipping transformation and additional
columns exist only in experiment and review evidence. Goal 010 likewise keeps
its prescribed-intake-window and comparison fields out of package state,
forcing records, return schemas, constructors, and validators. Goal 011 keeps
its sequence, phase, and contrast fields in evidence clients and adds no
production multi-day runner. Goal 012 likewise keeps its prescribed-pulse
sequence, phase, boundary, contrast, recurrence, and complement fields in
evidence clients and adds no production API, state, schema, parameter, or test.

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

At public boundaries, state, parameter, schedule, and convergence arguments
are validated by semantic numeric value; harmless classes and metadata are
accepted when conversion preserves those values. Returned records and tables
remain canonical plain objects. The convergence control must be finite and
strictly between zero and one, and maximum burn-in must be a whole numeric
scalar of at least two because convergence requires successive daily
trajectories.

Every burn-in day applies the private gut scalar core across the already
validated ordered 24-row schedule. Only gut state advances. For each day, the
runner retains the 25 boundary stocks formed by the openings of hours 0 through
23 and the closing stock after hour 23. Define:

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
top-level runner and passed to the model-specific prevalidated coupled-day
helper for measured days 1 and 2. Gut-only burn-in remains activity-free
because it advances no body state or history. The closing gut and body stocks
of measured day 1 open measured day 2. Public step functions serve direct
callers; validated day and reference loops call private scalar cores. Each
measured daily slice therefore reduces exactly to a direct one-day runner
result after removing `measurement_day` and restoring canonical row names.

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

## Reference Hierarchy And Goal 008 Evidence

The reference hierarchy is:

- `mathematical_continuous` remains the permanent arithmetic, convergence,
  accounting, and regression diagnostic;
- `ecological_day_resting` remains the zero-activity ecological comparator;
- `ecological_activity_prescribed_balance` is the normal synthetic ecological
  accounting reference; and
- `ecological_activity_uncompensated` is the activity-only counterfactual, not
  a neutral reference.

The mathematical diagnostic is:

```text
hour_of_day = 0:23
prescribed_dry_matter_intake_kg_dm_h = 0.010
prescribed_ingested_available_energy_kj_h = 100
prescribed_routine_activity_expenditure_kj_h = 0
```

The three ecological fixtures use an empty initial gut, a 10000 kJ measurement
body reserve, release 0.25 h^-1, maintenance 100 kJ h^-1,
metabolizable-energy density 10000 kJ kg^-1 DM, the Goal 005 convergence
tolerance, at most 100 gut-only burn-in days, and two carried measurement days.
Their exact prescriptions are:

```text
scenario_id = ecological_day_resting
hours 0:7 and 16:23
  dry-matter intake = 0.015 kg DM h^-1
  gut input = 150 kJ h^-1
  routine activity = 0 kJ h^-1
daily dry matter / gut input / activity = 0.24 kg DM / 2400 kJ / 0 kJ

scenario_id = ecological_activity_uncompensated
hours 0:7 and 16:23
  dry-matter intake = 0.015 kg DM h^-1
  gut input = 150 kJ h^-1
  routine activity = 50 kJ h^-1
daily dry matter / gut input / activity = 0.24 kg DM / 2400 kJ / 800 kJ

scenario_id = ecological_activity_prescribed_balance
hours 0:7 and 16:23
  dry-matter intake = 0.020 kg DM h^-1
  gut input = 200 kJ h^-1
  routine activity = 50 kJ h^-1
daily dry matter / gut input / activity = 0.32 kg DM / 3200 kJ / 800 kJ

hour_of_day = 8:15
  dry-matter intake, gut input, and routine activity = 0
```

Because `hour_of_day` labels `[hour_of_day, hour_of_day + 1)`, all three
ecological fixtures close intake during `[08:00, 16:00)` and prescribe it
across the night-spanning 16-hour block from 16:00 through 08:00. The two
activity fixtures close activity during the same rest interval and prescribe
it across the same 16-hour block; the baseline prescribes zero activity
throughout.

The retained Goal 008 evidence observes that all three gut cycles first
converge on burn-in day 7. Daily assimilation is approximately `2400 kJ`,
`2400 kJ`, and `3200 kJ`, matching the respective prescribed daily inputs.
Observed daily body change is approximately `0 kJ`, `-800 kJ`, and `0 kJ`.
Body reserve closes measured days 1 and 2 at approximately
`10000 / 10000 kJ`, `9200 / 8400 kJ`, and `10000 / 10000 kJ`.

The baseline and uncompensated convergence and gut ledgers match exactly in
memory. The balanced gut-boundary and assimilation trajectories follow the
predicted `4/3` scaling with a maximum in-memory absolute deviation of
approximately `1.14e-13 kJ`. The observed baseline-minus-uncompensated
body-reserve contrasts at `0, 8, 16, 24, 32, 40, 48 h` are exactly
`0, 400, 400, 800, 1200, 1200, 1600 kJ`.

These numerical results are observations from the declared synthetic fixtures.
The interpretation that added prescribed intake balances prescribed activity
depends on the unchanged periodic, linear, lossless, unlimited model. The
balanced rate of `200 kJ h^-1` and total of `0.32 kg DM d^-1` are prescribed,
not shown feasible. Arithmetic balance is not a feeding decision, behavior,
adaptive compensation, biological equilibrium, viability, empirical
physiology, or evidence of biological interchangeability.

## Goal 009 Evidence-Only Ceiling Screen

Goal 009 starts with the Goal 008 balanced candidate prescription:
`0.020 kg DM h^-1` in the 16 active intervals and zero in the eight rest
intervals. Evidence clients construct synthetic ceilings of `0.015`, `0.020`,
and `0.025 kg DM h^-1` in active intervals and zero during rest, then apply:

```text
constrained prescribed intake at hour t =
  min(candidate prescribed intake at hour t,
      synthetic hourly ceiling at hour t)

curtailed prescribed intake at hour t =
  candidate prescribed intake at hour t
  - constrained prescribed intake at hour t
```

`ceiling_exceeded` is true only when candidate intake is strictly greater than
the ceiling. Touching counts only active intervals in which candidate and
ceiling are equal and strictly positive; rest intervals therefore neither
exceed nor touch. Daily unused active-ceiling headroom sums
`max(ceiling - constrained intake, 0)` over the 16 active intervals.
Curtailment is discarded with no redistribution, storage, carry-over, or
feedback.

At the fixed `10000 kJ kg^-1 DM` density, daily maintenance of `2400 kJ`, and
daily routine activity of `800 kJ`, the exact conditional threshold is:

```text
3200 kJ / (16 h * 10000 kJ kg^-1 DM)
  = 0.020 kg DM h^-1
  = 200 kJ h^-1
```

The retained evidence observes:

| Relation | Active ceiling | Exceeded / touching intervals | Daily constrained / curtailed intake | Daily unused headroom | Constrained energy and body change |
| --- | --- | --- | --- | --- | --- |
| below | 0.015 kg DM h^-1 | 16 / 0 | 0.24 / 0.08 kg DM | 0 kg DM | 2400 kJ and -800 kJ |
| at | 0.020 kg DM h^-1 | 0 / 16 | 0.32 / 0 kg DM | 0 kg DM | 3200 kJ and approximately 0 kJ |
| above | 0.025 kg DM h^-1 | 0 / 0 | 0.32 / 0 kg DM | 0.08 kg DM = 800 kJ | 3200 kJ and approximately 0 kJ |

The below-threshold complete result is exactly identical in memory to
`ecological_activity_uncompensated`. The at- and above-threshold complete
results are exactly identical to each other and to
`ecological_activity_prescribed_balance`. Thus a static client-side ceiling is
downstream-equivalent to selecting the corresponding lower prescribed
schedule; it adds no animal mechanism.

The threshold is conditional on the declared fixture and accounting
assumptions. It is not an empirical maximum, appetite, feeding behavior, forage
availability, gut capacity, intake redistribution, a demonstrated achievable
rate, or a production package constraint.

## Goal 010 Evidence-Only Prescribed Intake Window Screen

Goal 010 holds the Goal 008 balanced open-interval intake rate at
`0.020 kg DM h^-1`, equivalent to `200 kJ h^-1` at the fixed
`10000 kJ kg^-1 DM` density. It also holds routine activity at `50 kJ h^-1` in
hours `16:23` and `0:7`, maintenance at `100 kJ h^-1` in all hours, and every
other model input and runner control fixed. Evidence clients construct ordinary
intake schedules from exactly these prescribed-intake windows:

| Scenario | Open hours | Duration | Intake/activity overlap | Intake without activity | Activity without intake |
| --- | --- | ---: | ---: | ---: | ---: |
| `prescribed_intake_window_24h` | `0:23` | 24 h d^-1 | 16 h d^-1 | 8 h d^-1 | 0 h d^-1 |
| `prescribed_intake_window_16h` | `16:23`, `0:7` | 16 h d^-1 | 16 h d^-1 | 0 h d^-1 | 0 h d^-1 |
| `prescribed_intake_window_12h` | `16:21`, `2:7` | 12 h d^-1 | 12 h d^-1 | 0 h d^-1 | 4 h d^-1 |
| `prescribed_intake_window_8h` | `16:19`, `4:7` | 8 h d^-1 | 8 h d^-1 | 0 h d^-1 | 8 h d^-1 |

`prescribed_intake_window_open` is an evidence construction field. `TRUE`
forces the fixed prescribed rate throughout the labeled one-hour interval;
`FALSE` forces zero. It is not unused access, voluntary opportunity, realized
behavior, forage availability, or an indication that the rate is achievable,
and it is never passed to a package function.

For duration `H` in hours per day, the clean daily accounting relation is:

```text
daily prescribed energy(H) = 200 kJ h^-1 * H
daily expenditure = 24 * 100 + 16 * 50 = 3200 kJ
expected daily body-energy change(H) = 200 * H - 3200 kJ
neutrality threshold = 16 h d^-1
```

The exact fixture expectations are:

| Duration | Daily intake | Daily energy | Daily body change | Day 1 / day 2 closing reserve | Status |
| ---: | ---: | ---: | ---: | ---: | --- |
| 24 h d^-1 | 0.48 kg DM | 4800 kJ | +1600 kJ | 11600 / 13200 kJ | surplus |
| 16 h d^-1 | 0.32 kg DM | 3200 kJ | 0 kJ | 10000 / 10000 kJ | neutral |
| 12 h d^-1 | 0.24 kg DM | 2400 kJ | -800 kJ | 9200 / 8400 kJ | deficit |
| 8 h d^-1 | 0.16 kg DM | 1600 kJ | -1600 kJ | 8400 / 6800 kJ | deficit |

The complete 16-hour result is exactly identical to Goal 008
`ecological_activity_prescribed_balance`. The 12-hour fixture matches Goal 008
`ecological_activity_uncompensated` only in daily intake, prescribed energy,
maintenance, routine-activity expenditure, body-energy change, status, and
closing body reserve. Its hourly intake schedule, periodic gut state,
within-day gut and body trajectories, and complete result differ. No Goal 008
comparison oracle is declared for the 24- or 8-hour fixture.

The linear relation above belongs to daily totals under the fixed rate and
fixed activity schedule. It is not a generic within-day effect of duration.
The 24-hour comparator additionally opens the activity-off interval
`[08:00, 16:00)`, whereas the 12- and 8-hour fixtures progressively remove
central-night prescribed-intake hours from within the fixed activity window.
Their within-day trajectories are therefore conditional on both duration and
the declared clock placement.

## Goal 011 Evidence-Only One-Day Shortfall Sequence

Goal 011 constructs the Goal 008 balanced period-24 gut state once and pairs it
with a `10000 kJ` body-energy reserve. Both evidence sequences start from those
same stocks and carry their closing gut and body states exactly across three
days:

| Sequence | Day 1 forcing | Day 2 forcing | Day 3 forcing |
| --- | --- | --- | --- |
| `all_balanced_control` | balanced | balanced | balanced |
| `one_day_rate_shortfall` | lower-rate shortfall | balanced | balanced |

Both forcings prescribe intake in hours `0:7` and `16:23`, zero intake in hours
`8:15`, routine activity of `50 kJ h^-1` in the 16 intake intervals, and zero
routine activity otherwise. At `10000 kJ kg^-1 DM`, balanced forcing uses
`0.020 kg DM h^-1` and supplies `3200 kJ d^-1`; the lower-rate day uses
`0.015 kg DM h^-1` and supplies `2400 kJ d^-1`.

The lower-rate schedule is the accepted Goal 009 below-threshold prescription
and exactly the Goal 008 `ecological_activity_uncompensated` schedule, but the
Goal 011 shortfall day does not use that fixture's periodic gut state. Starting
it from the common balanced periodic gut makes this a transition between
prescribed daily forcings rather than another stationary reference result.

All evidence contrasts are:

```text
one_day_rate_shortfall - all_balanced_control
```

The exact external prescribed-input contrast accumulated on day 1 is:

```text
16 h * (0.015 - 0.020) kg DM h^-1 * 10000 kJ kg^-1 DM
  = -800 kJ
```

Because maintenance and routine activity match, the combined gut-plus-body
contrast reaches `-800 kJ` at the 24-hour boundary and remains `-800 kJ`
through the two return-to-reference days. After hour 24 the hourly input
contrast is zero. For gut-stock contrast `delta_G` and release fraction
`r = 0.25 h^-1`:

```text
delta_G[t + 1] = (1 - r) * delta_G[t]
               = 0.75 * delta_G[t]

daily gut-contrast contraction factor = 0.75^24

body-reserve contrast = -800 kJ - gut-stock contrast
```

The first two control days are exactly identical to the accepted Goal 008
balanced hourly and daily result, and the third retains its periodic gut
boundary and approximately neutral body accounting. The retained evidence also
confirms the combined-system invariant, hourly and daily gut recurrence, body
complement, and exact stock carry-over. Return-to-reference forcing denotes
resumption of the balanced prescribed schedule only. Contraction of the gut
contrast is numerical state realignment, not body-energy or whole-system
restoration and not biological or physiological recovery.

At 24 hours, the treatment-minus-control partition rounds to `-182 kJ` in the
gut and `-618 kJ` in the body. The gut contrast then contracts to
`-0.182 kJ` at 48 hours and `-0.000183 kJ` at 72 hours, while the body contrast
is the unrounded complement to the exact `-800 kJ` combined-system contrast.
Extra precision is retained only for these small gut remainders.

The experiment obtains this deliberately fixed sequence by calling
`run_gut_body_energy_day()` three times per sequence. It does not widen the
public reference-cycle interface or add a configurable production multi-day
API.

## Goal 012 Evidence-Only Prescribed Repayment Sequence

Goal 012 constructs the same balanced period-24 gut state once and pairs it
with a `10000 kJ` body-energy reserve. Both evidence sequences start from those
identical stocks and carry their closing gut and body states exactly across
four days:

| Sequence | Day 1 forcing | Day 2 forcing | Day 3 forcing | Day 4 forcing |
| --- | --- | --- | --- | --- |
| `all_balanced_control` | balanced | balanced | balanced | balanced |
| `shortfall_then_repayment` | shortfall | prescribed repayment pulse | balanced | balanced |

Every schedule prescribes zero intake in hours `8:15`. In hours `0:7` and
`16:23`, balanced forcing prescribes `0.020 kg DM h^-1`, shortfall forcing
prescribes `0.015 kg DM h^-1`, and the direct repayment-pulse forcing prescribes
`0.025 kg DM h^-1`. At `10000 kJ kg^-1 DM`, the corresponding daily amounts are
`0.32, 0.24, 0.40 kg DM` and `3200, 2400, 4000 kJ`.

Maintenance remains `100 kJ h^-1` for all 24 hours. Routine activity remains
`50 kJ h^-1` in the same 16 active intervals and zero in hours `8:15`. Gut
release remains `0.25 h^-1`. The day-1 forcing and common initialization
reproduce the accepted Goal 011 shortfall boundary; neither stock is reset
after that common opening boundary.

All evidence contrasts are:

```text
shortfall_then_repayment - all_balanced_control
```

The hourly input contrast is `-50 kJ` in each active hour on day 1, `+50 kJ`
in each active hour on day 2, and zero on days 3 and 4 and during every central
eight-hour closure. With matched expenditure, cumulative prescribed input and
the combined gut-plus-body contrast therefore follow:

```text
0 kJ initially
-800 kJ at 24 h
0 kJ at 48 h
0 kJ at 72 and 96 h
```

For gut-stock contrast `delta_G`, hourly input contrast `delta_I`, and release
fraction `r = 0.25 h^-1`:

```text
delta_G[t + 1] = (1 - r) * delta_G[t] + delta_I[t]
               = 0.75 * delta_G[t] + delta_I[t]

after hour 48: delta_G[t + 1] = 0.75 * delta_G[t]
daily post-pulse contraction factor = 0.75^24

body-reserve contrast =
  cumulative prescribed-input contrast - gut-stock contrast
```

The analytical day-boundary fixtures are:

| Elapsed time | Gut contrast (kJ) | Body contrast (kJ) | Combined contrast (kJ) |
| ---: | ---: | ---: | ---: |
| 0 h | 0 | 0 | 0 |
| 24 h | -181.781258 | -618.218742 | -800 |
| 48 h | 181.598860 | -181.598860 | 0 |
| 72 h | 0.182215 | -0.182215 | 0 |
| 96 h | 0.000183 | -0.000183 | 0 |

Thus the prescribed pulse returns the whole-system contrast to zero at hour
48 while the two component contrasts remain equal and opposite. Under balanced
forcing on days 3 and 4, those contrasts contract toward zero by `0.75^24` per
day but do not reach exact treatment-control stock equality in finite time.

The `0.025 kg DM h^-1` schedule is direct exogenous synthetic forcing. It is
not Goal 009's above-threshold result, whose `0.020 kg DM h^-1` candidate was
unchanged by a non-binding `0.025 kg DM h^-1` ceiling. `Prescribed repayment
pulse` does not denote compensation, catch-up feeding, appetite, behavioral
response, capacity, animal recovery, physiological recovery, or a realistic
ecological repayment process.

The no-write experiment exposes only client-side evidence. It constructs a
97-row hourly boundary-contrast table, an eight-row daily-sequence table, and a
five-row day-boundary realignment table. Their exact evidence-only columns are
defined in `variable-dictionary.md`. The experiment chains
`run_gut_body_energy_day()` four times per sequence and adds no production
runner, interface, state, schema, parameter, equation, validator, or test.

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

Goal 008 uses the three ecological fixtures specified above to distinguish the
observed activity-only body loss from the observed effect of higher prescribed
input. It is an evidence and reference layer only. It changes no equation,
interface, output schema, or variable definition.

Goal 009 uses a candidate prescription and three evidence-only ceiling
schedules to locate the conditional accounting threshold specified above. The
candidate, ceiling, constrained prescription, curtailed prescription,
exceedance, touching, and unused headroom are experiment quantities, not
production state or forcing schemas.

Goal 010 uses four evidence-only prescribed intake window schedules to establish
the fixed-rate daily duration relation and its declared Goal 008 comparisons.
Window, overlap, duration, threshold, comparison, and identity fields remain
experiment and review quantities, not production state, input, or result
schemas.

Goal 011 uses one common balanced periodic gut boundary and two exact,
three-day sequences to establish the finite `-800 kJ` prescribed-input
contrast, its fixed combined-system expression, and its changing gut/body
partition. Sequence, phase, boundary, contrast, recurrence, and complement
fields remain evidence quantities. The clients chain the existing one-day
runner and add no model mechanism or production horizon.

Goal 012 uses that same common initialization for two exact four-day sequences
to establish the `-800 -> 0 kJ` cumulative input and combined-system path and
the delayed realignment of equal-and-opposite gut and body contrasts. Its direct
repayment-pulse prescription and all sequence, phase, boundary, contrast,
recurrence, and complement fields remain evidence quantities. The clients add
no model mechanism, endogenous response, or production horizon.

## Exclusions And Stop

The model does not represent variable or stochastic days, a configurable
measurement horizon, seasons, chronic decline, recovery, viability criteria,
offered or wet forage, water content, gross or digestible energy, time-varying
density, multiple food types, food choice, preference, diet mixing, nutrient
composition, assimilation efficiency, digestive loss, waste, dry-matter gut
state, gut capacity, production intake limits, multiple gut compartments,
feeding decisions, behavior, activity choice or feedback, directed locomotion,
feeding-associated expenditure, thermic effect of food, total metabolism,
dynamic body mass, protein, water, thermoregulation, plants, weather, space,
individuals, populations, empirical calibration, parameter estimation, or
uncertainty analysis.

Goal 012 ended after the common initialization, exact four-day control and
prescribed-pulse sequences, analytical contrast partition, no-write experiment,
and documentation were validated and reviewed. It added no generalized
production multi-day API or biological response. Goal 013 remains unapproved
and scientifically unspecified; any next layer is pending discussion.

The historical implementation is private at `BWBrook/herbivoreTTR-legacy`, tag
`legacy-final-2026-07-16`; the pre-freeze scientific baseline is
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
