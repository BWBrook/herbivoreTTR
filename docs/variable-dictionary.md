# Variable Dictionary

## Status

These are the exact public record, flux, and ledger names implemented through
Goal 019. The prescribed coupled ledger schema last changed in Goal 007; Goals
008 through 012 add evidence outputs only, Goal 013 adds appetite records, Goal
015 adds the repeated-day appetite runner, Goal 016 separates appetite target
from forage-limited realized intake, and Goal 019 adds a downstream derived-
mass record without changing a ledger. Rates in kJ h^-1 and one-hour amounts in
kJ remain distinct even when their numerical values match for the fixed one-
hour transition.

The Goal 004 density is already metabolizable energy on a dry-matter basis. Its
product with prescribed dry-matter ingestion is the accounting equivalent
entering the existing gut available-energy pool. The gut stock is energy, not
dry matter, gross energy, plant biomass, measured gut fill, or a calibrated
physiological quantity.

## Core Records And Prescribed Inputs

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `metabolizable_energy_density_kj_kg_dm` | fixed food parameter | kJ kg^-1 DM | Strictly positive dry-matter-basis energy density that is already metabolizable and remains fixed within a 24-hour run. |
| `prescribed_dry_matter_intake_kg_dm_h` | prescribed food-input rate | kg DM h^-1 | Dry matter ingested during the labeled hour; not offered or wet forage, availability, or output from a feeding decision. |
| `gut_available_energy_kj` | dynamic gut state | kJ | Available-energy accounting equivalent in the single gut pool at a transition boundary. |
| `body_energy_reserve_kj` | dynamic body state | kJ | Physical body-energy reserve at a transition boundary. |
| `structural_body_mass_kg` | fixed mass-conversion parameter | kg | Strictly positive body mass held fixed when energy reserve is interpreted as total mass. |
| `reserve_tissue_energy_density_kj_kg` | fixed mass-conversion parameter | kJ kg^-1 | Strictly positive effective energy density used only to translate body-energy reserve into labile reserve-tissue mass. |
| `gut_release_fraction_h` | fixed gut parameter | h^-1 | Fraction of opening gut energy released during each fixed one-hour transition; constrained to `(0, 1]`. |
| `maintenance_expenditure_kj_h` | fixed body parameter rate | kJ h^-1 | Constant synthetic maintenance-only expenditure rate; not an empirically parameterized metabolic requirement. |
| `prescribed_routine_activity_expenditure_kj_h` | prescribed body-expenditure rate | kJ h^-1 | Finite, non-negative routine-activity expenditure imposed externally for the labeled hour, incremental to fixed maintenance; not behavior or locomotion. |
| `hour_of_day` | prescribed clock | integer 0-23 | Label for the half-open one-hour interval `[hour_of_day, hour_of_day + 1)`. |
| `prescribed_ingested_available_energy_kj_h` | prescribed or derived gut-input rate | kJ h^-1 | Controlled available-energy accounting equivalent entering the gut during an hour; the Goal 004 converter derives it as dry-matter intake multiplied by fixed density. |
| `prescribed_assimilated_energy_kj_h` | prescribed body-input rate | kJ h^-1 | Already-assimilated energy supplied directly to the standalone Goal 002 body ledger. |
| `gut_convergence_relative_tolerance` | numerical runner control | dimensionless | Finite scalar strictly between zero and one; scales the repeated-day gut convergence threshold and has no biological interpretation. |
| `max_burn_in_days` | numerical runner control | d | Integer maximum number of identical gut-only burn-in days; at least two because convergence compares successive days. |
| `burn_in_day` | convergence index | integer d | Completed gut-only burn-in day, beginning at 1. |
| `measurement_day` | measured-day key | integer 1-2 | Identifies the two carried gut-body days after the single body reset. |
| `number_of_days` | appetite-runner control | d | One finite whole numeric value from 1 to `.Machine$integer.max`; repeats one fixed daily schedule without adding day-specific forcing. |
| `simulation_day` | appetite-runner day key | integer d | Identifies a repeated appetite-controlled day, beginning at 1. |
| `forage_acquisition_ceiling_kg_dm_h` | external environmental rate | kg DM h^-1 | Maximum dry matter that can be acquired during the labeled hour; finite and non-negative, with no implied forage stock, depletion, or plant process. |

## Goal 004 Food-Energy Record Schemas

`new_food_energy_parameters()` returns an exact plain named list with:

```text
metabolizable_energy_density_kj_kg_dm
```

The value is a finite, strictly positive double. Zero is rejected because zero
intake already supplies the exact no-energy control.

`new_dry_matter_intake_schedule()` returns an exact 24-row base R data frame
with columns in this order:

```text
hour_of_day
prescribed_dry_matter_intake_kg_dm_h
```

`hour_of_day` is integer `0:23`. The intake column contains finite,
non-negative doubles.

`derive_ingested_available_energy_schedule()` returns the exact existing
24-row Goal 003 data-frame schema:

```text
hour_of_day
prescribed_ingested_available_energy_kj_h
```

The derived rate is the elementwise product:

```text
kg DM h^-1 * kJ kg^-1 DM = kJ h^-1
```

The converter adds no food columns, attributes, amount variables, or state.

## Goal 019 Derived Body-Mass Record And Output

`new_body_mass_parameters()` returns an exact plain named list with:

```text
structural_body_mass_kg
reserve_tissue_energy_density_kj_kg
```

Both values are finite, strictly positive doubles. The accepted synthetic
reference uses `38 kg` and `20,000 kJ kg^-1`, respectively.

`derive_body_mass_from_energy_reserve()` returns a base data frame with one row
per supplied non-negative body-energy reserve and columns in this order:

```text
body_energy_reserve_kj
reserve_tissue_mass_kg
total_body_mass_kg
```

All columns are finite doubles. Reserve-tissue mass is body-energy reserve
divided by the fixed effective density; total mass is fixed structural mass
plus reserve-tissue mass. It excludes physical gut contents, which are not a
modeled mass stock. These are derived outputs, not dynamic states or runner
inputs.

## Goal 007 Routine-Activity Record Schema

`new_routine_activity_expenditure_schedule()` returns an exact plain 24-row
base R data frame with columns in this order:

```text
hour_of_day
prescribed_routine_activity_expenditure_kj_h
```

`hour_of_day` is integer `0:23`. The activity column contains finite,
non-negative doubles in kJ h^-1. Every body transition and runner requires this
forcing explicitly; no interface supplies a default or implicit zero schedule.
For `step_body_energy()`, the one-row activity input must have the same
`hour_of_day` as the assimilated-energy input row.

The schedule is an externally prescribed incremental body-energy sink. It does
not represent a behavioral state, directed locomotion, exercise, thermic effect
of food, total metabolism, or an emergent response.

## Goal 013 Appetite-Control Records And Output

`new_appetite_control_parameters()` returns an exact plain named list with:

```text
maximum_dry_matter_intake_kg_dm_h
body_energy_feedback_fraction_h
gut_energy_feedback_fraction_h
```

The maximum is a finite, strictly positive physiological ceiling on appetite
target in kg DM h^-1. Each feedback fraction is a finite, non-negative double
in h^-1. Multiplying a feedback fraction by its energy-stock deviation in kJ
gives a signed contribution in kJ h^-1.

`new_appetite_reference_schedule()` returns an exact 24-row base data frame:

```text
hour_of_day
feeding_opportunity_open
reference_dry_matter_intake_kg_dm_h
reference_body_energy_reserve_kj
reference_gut_available_energy_kj
```

The clock is integer `0:23`, opportunity is logical, and the remaining columns
are finite non-negative doubles. Reference intake must be zero in closed hours.
The two reference stocks are opening-state targets for the labeled hour.

`calculate_appetite_target()` returns one exact plain named list:

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `feeding_opportunity_open` | controller gate | logical | Whether a positive appetite target is permitted in the labeled hour. |
| `reference_dry_matter_intake_kg_dm_h` | feedforward reference | kg DM h^-1 | Accepted reference intake before state feedback. |
| `maximum_dry_matter_intake_kg_dm_h` | physiological upper bound | kg DM h^-1 | Declared maximum appetite-target rate. |
| `reference_ingested_available_energy_kj_h` | feedforward reference | kJ h^-1 | Reference dry matter multiplied by fixed metabolizable-energy density. |
| `body_energy_deviation_from_reference_kj` | slow state signal | kJ | Current opening body reserve minus its hour-specific reference; negative means deficit. |
| `body_energy_feedback_kj_h` | signed intake adjustment | kJ h^-1 | Negative body feedback fraction multiplied by body deviation; positive under deficit. |
| `gut_energy_deviation_from_reference_kj` | fast state signal | kJ | Current opening gut-energy stock minus its hour-specific reference; positive means above reference. |
| `gut_energy_feedback_kj_h` | signed intake adjustment | kJ h^-1 | Negative gut feedback fraction multiplied by gut deviation; negative above reference. |
| `unconstrained_ingested_available_energy_kj_h` | integrated controller rate | kJ h^-1 | Reference energy plus the two signed feedback contributions before bounds or opportunity closure. |
| `unconstrained_dry_matter_intake_kg_dm_h` | integrated controller rate | kg DM h^-1 | Unconstrained energy rate divided by fixed metabolizable-energy density. |
| `appetite_target_dry_matter_intake_kg_dm_h` | animal-side intake target | kg DM h^-1 | Unconstrained rate after opportunity closure and physiological lower and upper bounds, before environmental limitation. |
| `appetite_target_ingested_available_energy_kj_h` | animal-side energy target | kJ h^-1 | Appetite-target dry matter multiplied by the fixed density; it enters the gut only when realized after the forage ceiling. |
| `lower_intake_bound_active` | diagnostic | logical | Whether an open-hour unconstrained rate was below zero. |
| `upper_intake_bound_active` | diagnostic | logical | Whether an open-hour unconstrained rate exceeded the declared maximum. |

The Goal 013 experiment additionally uses evidence-only `sequence_day`,
`forcing`, daily realized-intake totals, and closing gut, body, and combined
deviations from reference. These are not a package return schema or generalized
multi-day state.

## Goal 016 Forage-Acquisition Record

`new_forage_acquisition_ceiling_schedule()` returns an exact 24-row base data
frame:

```text
hour_of_day
forage_acquisition_ceiling_kg_dm_h
```

The clock is integer `0:23`; the ceiling is a finite, non-negative double in
kg DM h^-1. The record supplies an external rate constraint only. It contains
no forage mass, depletion, renewal, vegetation type, or location.

## Goal 015–016 Repeated-Day Appetite-Controlled Ledgers

`run_appetite_controlled_energy_days()` returns a plain list containing
`hourly` and `daily`. The exact 42-column hourly order is:

```text
simulation_day
hour_of_day
time_start_h
time_end_h
feeding_opportunity_open
reference_dry_matter_intake_kg_dm_h
maximum_dry_matter_intake_kg_dm_h
reference_ingested_available_energy_kj_h
body_energy_deviation_from_reference_kj
body_energy_feedback_kj_h
gut_energy_deviation_from_reference_kj
gut_energy_feedback_kj_h
unconstrained_ingested_available_energy_kj_h
unconstrained_dry_matter_intake_kg_dm_h
appetite_target_dry_matter_intake_kg_dm_h
appetite_target_ingested_available_energy_kj_h
lower_intake_bound_active
upper_intake_bound_active
forage_acquisition_ceiling_kg_dm_h
forage_acquisition_ceiling_active
realized_dry_matter_intake_kg_dm_h
realized_ingested_available_energy_kj_h
gut_available_energy_start_kj
gut_release_fraction_h
assimilated_energy_kj_h
realized_ingested_available_energy_kj
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

The exact 32-column daily order is:

```text
simulation_day
reference_dry_matter_intake_kg_dm
appetite_target_dry_matter_intake_kg_dm
realized_dry_matter_intake_kg_dm
total_reference_ingested_available_energy_kj
total_appetite_target_ingested_available_energy_kj
lower_intake_bound_hours
upper_intake_bound_hours
forage_acquisition_ceiling_active_hours
gut_available_energy_initial_kj
total_realized_ingested_available_energy_kj
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
gut_energy_deviation_from_reference_final_kj
body_energy_deviation_from_reference_final_kj
combined_energy_deviation_from_reference_final_kj
```

The hourly table has `24 * number_of_days` rows and cumulative clock fields;
the daily table has one row per day. `appetite_target_*` fields describe the
animal-side bounded target. `realized_*` fields describe the amount remaining
after the forage-acquisition ceiling, and only that amount enters the gut.
Reference deviations in the daily table compare the closing stocks with the
reference opening stocks for hour 0 of the next repeated day. Closing states
carry exactly and are not stored again as separate result objects.

## Goal 009 Evidence-Only Review Columns

Goal 009 adds no package variable, state, parameter, record, or return schema.
The names below exist only in the no-write experiment and its generated
evidence tables. They describe a synthetic client-side `pmin` prescription,
not appetite, feeding behavior, forage availability, gut capacity, or a
production ceiling.

The hourly screen contains:

```text
scenario_id
hour_of_day
candidate_prescribed_dry_matter_intake_kg_dm_h
synthetic_intake_ceiling_kg_dm_h
constrained_prescribed_dry_matter_intake_kg_dm_h
curtailed_prescribed_dry_matter_intake_kg_dm_h
ceiling_exceeded
```

The threshold summary contains:

```text
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

The measured daily accounting table contains:

```text
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

Shared package-result names retain their definitions elsewhere in this
dictionary. Their review-table values are copied from the unchanged Goal 008
result. The Goal 009-specific evidence meanings are:

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `scenario_id` | evidence fixture key | none | Identifies the below-, at-, or above-threshold synthetic ceiling fixture. |
| `hour_of_day` | evidence clock key | integer 0-23 | Retains the package interval label `[hour_of_day, hour_of_day + 1)`. |
| `candidate_prescribed_dry_matter_intake_kg_dm_h` | candidate prescribed rate | kg DM h^-1 | External prescription before clipping: 0.020 in each active interval and zero during rest. |
| `synthetic_intake_ceiling_kg_dm_h` | evidence-only ceiling rate | kg DM h^-1 | Synthetic exogenous clipping prescription for the labeled hour; not a physiological or production limit. |
| `constrained_prescribed_dry_matter_intake_kg_dm_h` | constrained prescribed rate | kg DM h^-1 | Elementwise minimum of candidate prescription and synthetic ceiling. |
| `curtailed_prescribed_dry_matter_intake_kg_dm_h` | curtailed prescribed rate | kg DM h^-1 | Candidate minus constrained prescription; discarded without redistribution, storage, carry-over, or feedback. |
| `ceiling_exceeded` | strict exceedance flag | logical | `TRUE` only when candidate prescription is strictly greater than the ceiling; false for rest intervals where both are zero. |
| `active_ceiling_kg_dm_h` | active fixture ceiling rate | kg DM h^-1 | Constant ceiling prescribed across the 16 active intervals for the scenario. |
| `active_ceiling_energy_equivalent_kj_h` | derived ceiling-rate equivalent | kJ h^-1 | Active ceiling multiplied by the fixed 10000 kJ kg^-1 DM evidence density. |
| `threshold_multiple` | threshold ratio | dimensionless | Active ceiling divided by the analytical threshold of 0.020 kg DM h^-1. |
| `threshold_relation` | threshold classification | `below`, `at`, or `above` | Declared relation of the active ceiling to the analytical threshold. |
| `curtailed_active_intervals` | curtailment count | integer intervals | Number of the 16 active intervals with strictly positive curtailed prescribed intake. |
| `touching_active_intervals` | exact-touch count | integer intervals | Number of active intervals where candidate and ceiling are equal and strictly positive. |
| `daily_candidate_intake_kg_dm` | candidate daily amount | kg DM | Sum of the 24 candidate prescribed hourly rates over fixed one-hour intervals. |
| `daily_ceiling_capacity_kg_dm` | synthetic daily ceiling sum | kg DM | Sum of the 24 hourly ceiling rates over fixed one-hour intervals; not forage availability, an allowance, or physiological capacity. |
| `daily_constrained_intake_kg_dm` | constrained daily amount | kg DM | Sum of the 24 constrained prescribed hourly rates over fixed one-hour intervals. |
| `daily_curtailed_intake_kg_dm` | curtailed daily amount | kg DM | Sum of candidate minus constrained prescribed intake; not deferred intake. |
| `daily_constrained_energy_kj` | constrained daily energy equivalent | kJ | Daily constrained intake multiplied by the fixed evidence density. |
| `daily_energy_shortfall_kj` | threshold shortfall | kJ | Declared 3200 kJ daily accounting requirement minus constrained daily energy. |
| `daily_unused_ceiling_headroom_kg_dm` | unused active-ceiling sum | kg DM | Active-interval sum of `max(ceiling - constrained intake, 0)`; not physiological capacity use. |
| `daily_unused_ceiling_headroom_kj` | unused headroom energy equivalent | kJ | Dry-matter headroom multiplied by the fixed evidence density. |
| `measurement_day` | measured-day key | integer 1-2 | Retains the two carried measurement-day identifiers from the reference-cycle result. |
| `total_constrained_energy_input_kj` | measured constrained input total | kJ | Existing daily total prescribed gut input produced from the constrained schedule. |
| `total_assimilated_energy_kj` | measured internal transfer total | kJ | Existing daily sum of energy transferred from gut to body. |
| `total_maintenance_expenditure_kj` | measured maintenance total | kJ | Existing daily sum of fixed maintenance expenditure. |
| `total_routine_activity_expenditure_kj` | measured activity total | kJ | Existing daily prescribed routine-activity total, renamed only in the evidence table. |
| `observed_body_energy_change_kj` | measured body change | kJ | Existing closing-minus-opening daily body-reserve change. |
| `body_energy_reserve_final_kj` | measured closing body state | kJ | Existing body reserve after hour 23 for the measurement day. |
| `body_energy_status` | measured body status | `neutral`, `deficit`, or `surplus` | Existing sign classification using the Goal 002 numerical tolerance. |
| `goal008_oracle_scenario_id` | evidence oracle key | none | Names the accepted Goal 008 scenario used for complete-result comparison. |
| `exact_oracle_identity` | evidence identity flag | logical | `TRUE` only when the complete in-memory result is exactly identical to the named Goal 008 oracle. |

The candidate, ceiling, constrained prescription, curtailed prescription,
strict exceedance, exact positive touching, and unused active-ceiling headroom
are distinct. None is a new production forcing or state variable.

## Goal 010 Evidence-Only Review Columns

Goal 010 adds no package variable, state, parameter, record, or return schema.
The prescribed intake window fields below exist only in the no-write experiment
and its generated evidence tables. `prescribed_intake_window_open = TRUE`
means that the labeled interval is fully used at the fixed prescribed intake
rate; it is not voluntary opportunity, realized behavior, forage access, or
empirical capacity.

The hourly prescribed-intake-window table contains:

```text
scenario_id
prescribed_intake_window_duration_h_d
hour_of_day
prescribed_intake_window_open
prescribed_dry_matter_intake_kg_dm_h
prescribed_ingested_available_energy_kj_h
prescribed_routine_activity_expenditure_kj_h
```

The duration summary contains:

```text
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

The measured daily accounting table contains:

```text
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

The Goal 010-specific fields and evidence-table aliases are:

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `prescribed_intake_window_duration_h_d` | prescribed intake window duration | h d^-1 | Count of one-hour intervals in which the fixed prescribed intake rate is applied: 24, 16, 12, or 8. |
| `prescribed_intake_window_open` | prescribed intake window flag | logical | `TRUE` forces the fixed prescribed intake rate for the labeled interval; `FALSE` forces zero. It is evidence construction metadata, not a package input or behavioral choice. |
| `closed_prescribed_intake_duration_h_d` | closed-window duration | h d^-1 | `24` minus the prescribed-intake-window duration. |
| `prescribed_intake_activity_overlap_h_d` | intake/activity overlap | h d^-1 | Count of intervals in which both fixed prescribed intake and fixed routine activity are positive. |
| `activity_without_prescribed_intake_h_d` | activity-only duration | h d^-1 | Count of intervals with positive prescribed routine activity and zero prescribed intake. |
| `prescribed_intake_without_activity_h_d` | intake-only duration | h d^-1 | Count of intervals with positive prescribed intake and zero prescribed routine activity. |
| `threshold_relation` | duration-threshold classification | `below`, `at`, or `above` | Relation of the prescribed-intake-window duration to the analytical 16 h d^-1 neutrality threshold in the Goal 010 fixture; distinct from the Goal 009 ceiling-rate classification. |
| `daily_prescribed_dry_matter_intake_kg_dm` | prescribed daily amount | kg DM | Sum of the 24 hourly prescribed dry-matter intake rates over fixed one-hour intervals. |
| `daily_prescribed_energy_kj` | prescribed daily energy | kJ | Daily prescribed dry matter multiplied by the fixed evidence density; `4800`, `3200`, `2400`, or `1600 kJ`. |
| `daily_maintenance_expenditure_kj` | fixed daily maintenance | kJ | Sum of the 24 fixed maintenance amounts; `2400 kJ` in every Goal 010 fixture. |
| `daily_routine_activity_expenditure_kj` | fixed daily activity | kJ | Sum of the fixed prescribed routine-activity amounts; `800 kJ` in every Goal 010 fixture. |
| `expected_body_energy_change_kj` | expected daily body change | kJ | In the duration summary, the day-invariant analytical amount `200 * H - 3200 kJ`; in the measured daily table, a copy of the existing package daily-summary field. |
| `day_1_body_energy_reserve_final_kj` | day 1 closing body state | kJ | Day 1 value extracted from the inherited `body_energy_reserve_final_kj` result field. |
| `day_2_body_energy_reserve_final_kj` | day 2 closing body state | kJ | Day 2 value extracted from the inherited `body_energy_reserve_final_kj` result field. |
| `matched_goal008_scenario_id` | evidence oracle key | none | Names the accepted Goal 008 comparison for the 16- or 12-hour fixture; empty for the 24- and 8-hour fixtures, for which no oracle is declared. |
| `daily_input_and_body_change_match` | selected daily/closing match flag | logical | For a declared Goal 008 oracle, indicates equality of daily prescribed intake and energy, maintenance, routine activity, body change, status, and the two closing reserves; empty when no oracle is declared. |
| `within_day_body_trajectory_identical` | body-trajectory identity flag | logical | Indicates exact identity of the within-day body trajectory with the named oracle; `TRUE` for 16 hours and `FALSE` for 12 hours. |
| `full_result_identical` | complete-result identity flag | logical | Indicates exact in-memory identity of the complete result with the named oracle; `TRUE` for 16 hours and `FALSE` for 12 hours. |
| `total_prescribed_energy_input_kj` | measured prescribed input alias | kJ | Evidence-table copy of inherited `total_prescribed_ingested_available_energy_kj`; no package field is renamed. |
| `total_routine_activity_expenditure_kj` | measured activity alias | kJ | Evidence-table copy of inherited `total_prescribed_routine_activity_expenditure_kj`; no package field is renamed. |

`scenario_id` remains experiment metadata. `hour_of_day`,
`prescribed_dry_matter_intake_kg_dm_h`,
`prescribed_ingested_available_energy_kj_h`, and
`prescribed_routine_activity_expenditure_kj_h` retain the core schedule
definitions above. `measurement_day`, `total_assimilated_energy_kj`,
`total_maintenance_expenditure_kj`, `expected_body_energy_change_kj`,
`observed_body_energy_change_kj`, `body_energy_reserve_initial_kj`,
`body_energy_reserve_final_kj`, and `body_energy_status` are copied from the
unchanged reference-cycle daily result and retain their definitions below.

The 16-hour comparison flags are all true because the complete result is
exactly the Goal 008 balanced result. For 12 hours, only the declared
daily/closing match flag is true; both identity flags are false because the
hourly schedule, periodic gut state, within-day trajectories, and complete
result differ. These comparison fields are evidence assertions, not production
schema.

## Goal 011 Evidence-Only Review Columns

Goal 011 adds no package variable, state, parameter, record, or return schema.
The sequence, phase, boundary, contrast, recurrence, and complement fields
below exist only in the no-write experiment and its generated evidence tables.
Every contrast is `one_day_rate_shortfall - all_balanced_control`.

The hourly boundary-contrast table has 73 rows for elapsed boundaries
`0:72 h` and contains:

```text
elapsed_time_h
boundary_phase
cumulative_prescribed_input_contrast_kj
gut_available_energy_contrast_kj
body_energy_reserve_contrast_kj
combined_system_energy_contrast_kj
contrast_closure_residual_kj
```

The daily-sequence table has six rows, ordered as control days 1 through 3 and
then shortfall-sequence days 1 through 3, and contains:

```text
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

The day-boundary realignment table has four rows at elapsed boundaries
`0, 24, 48, 72 h` and contains:

```text
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

The Goal 011-specific fields and evidence-table aliases are:

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `sequence_id` | sequence key | none | Identifies `all_balanced_control` or `one_day_rate_shortfall`; experiment metadata only. |
| `sequence_day` | carried-day key | integer 1-3 | Identifies the day within the fixed evidence sequence; not a new package measurement-day field. |
| `forcing_phase` | daily forcing label | `balanced`, `shortfall`, or `return_to_reference` | Labels the schedule applied on that sequence day. `return_to_reference` denotes balanced prescribed forcing after the shortfall, not an animal process. |
| `elapsed_time_h` | evidence boundary time | h | Hours elapsed from the common initial boundary; integer `0:72` in the hourly table and `0, 24, 48, 72` in the day-boundary table. |
| `boundary_phase` | hourly boundary phase | `initial`, `shortfall_day`, `return_to_reference_day_1`, or `return_to_reference_day_2` | `initial` at 0 h, `shortfall_day` at 1:24 h, and the two return-to-reference labels at 25:48 h and 49:72 h. |
| `boundary_label` | selected day-boundary label | `initial`, `shortfall_day_close`, `return_to_reference_day_1_close`, or `return_to_reference_day_2_close` | Labels the four selected day boundaries in elapsed-time order. |
| `daily_prescribed_dry_matter_intake_kg_dm` | prescribed daily amount | kg DM | Sum of the 24 hourly prescribed dry-matter rates over fixed one-hour intervals; `0.32 kg DM` on balanced days and `0.24 kg DM` on the shortfall day. |
| `total_prescribed_energy_input_kj` | measured prescribed input alias | kJ | Evidence-table copy of inherited `total_prescribed_ingested_available_energy_kj`; `3200 kJ` on balanced days and `2400 kJ` on the shortfall day. |
| `total_routine_activity_expenditure_kj` | measured activity alias | kJ | Evidence-table copy of inherited `total_prescribed_routine_activity_expenditure_kj`; `800 kJ` on every sequence day. |
| `cumulative_prescribed_input_contrast_kj` | cumulative external-input contrast | kJ | Treatment-minus-control prescribed energy accumulated from the common initial boundary; reaches `-800 kJ` at 24 hours and remains there. |
| `gut_available_energy_contrast_kj` | gut-stock contrast | kJ | Treatment gut stock minus control gut stock at the matched boundary. |
| `body_energy_reserve_contrast_kj` | body-stock contrast | kJ | Treatment body reserve minus control body reserve at the matched boundary. |
| `combined_system_energy_contrast_kj` | two-stock system contrast | kJ | Sum of gut-stock and body-reserve contrasts; reaches `-800 kJ` at 24 hours and remains there. |
| `contrast_closure_residual_kj` | contrast accounting residual | kJ | Combined-system contrast minus cumulative prescribed-input contrast; zero within the declared numerical tolerance. |
| `expected_gut_contrast_kj` | analytical gut contrast | kJ | Expected matched-boundary gut contrast from the exact day-1 forcing difference and subsequent recurrence `delta_G[t + 1] = 0.75 * delta_G[t]`. |
| `gut_contraction_factor_from_previous_boundary` | daily recurrence factor | dimensionless | Empty at the initial and shortfall-close boundaries; `0.75^24` at each return-to-reference boundary. |
| `expected_body_complement_kj` | analytical body contrast | kJ | Body contrast required to complement the expected gut contrast to the cumulative combined-system contrast; after the shortfall this is `-800 kJ - expected_gut_contrast_kj`. |

`total_assimilated_energy_kj`, `total_maintenance_expenditure_kj`,
`expected_body_energy_change_kj`, `observed_body_energy_change_kj`,
`gut_available_energy_initial_kj`, `gut_available_energy_final_kj`,
`body_energy_reserve_initial_kj`, `body_energy_reserve_final_kj`,
`total_system_energy_initial_kj`, and `total_system_energy_final_kj` are copied
from the unchanged coupled daily result and retain their definitions below.
None of the Goal 011 fields widens the production runner or package schema.

## Goal 012 Evidence-Only Client Columns

Goal 012 adds no package variable, state, parameter, record, return schema,
validator, or test. The names below are client-side evidence aliases used only
in the no-write experiment. Every contrast is `shortfall_then_repayment -
all_balanced_control`. The label
`prescribed_repayment_pulse` denotes the direct exogenous
`0.025 kg DM h^-1` prescription over the 16 active hours, not compensation,
a modeled animal response, or a production input type.

The hourly boundary-contrast table has 97 rows for elapsed boundaries
`0:96 h` and contains:

```text
elapsed_time_h
boundary_phase
cumulative_prescribed_input_contrast_kj
gut_available_energy_contrast_kj
body_energy_reserve_contrast_kj
combined_system_energy_contrast_kj
contrast_closure_residual_kj
```

The daily-sequence table has eight rows, ordered as
`all_balanced_control` days 1 through 4 and then
`shortfall_then_repayment` days 1 through 4, and contains:

```text
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

Its exact `forcing_phase` order is:

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

The day-boundary realignment table has five rows at elapsed boundaries
`0, 24, 48, 72, 96 h` and contains:

```text
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

Its exact `boundary_label` order is:

```text
initial
shortfall_day_close
prescribed_repayment_pulse_day_close
return_to_reference_day_1_close
return_to_reference_day_2_close
```

The Goal 012-specific uses of these fields and evidence-table aliases are:

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `sequence_id` | sequence key | none | Identifies `all_balanced_control` or `shortfall_then_repayment`; experiment metadata only. |
| `sequence_day` | carried-day key | integer 1-4 | Identifies the day within the fixed evidence sequence; not a package measurement-day field. |
| `forcing_phase` | daily forcing label | `balanced`, `shortfall`, `prescribed_repayment_pulse`, or `return_to_reference` | Labels the externally prescribed schedule for that sequence day. Neither pulse nor return label denotes an animal process. |
| `elapsed_time_h` | evidence boundary time | h | Hours elapsed from the common initial boundary; integer `0:96` in the hourly table and `0, 24, 48, 72, 96` in the day-boundary table. |
| `boundary_phase` | hourly boundary phase | `initial`, `shortfall_day`, `prescribed_repayment_pulse_day`, `return_to_reference_day_1`, or `return_to_reference_day_2` | `initial` at 0 h; the four daily phases occupy boundaries 1:24, 25:48, 49:72, and 73:96 h. |
| `boundary_label` | selected day-boundary label | `initial`, `shortfall_day_close`, `prescribed_repayment_pulse_day_close`, `return_to_reference_day_1_close`, or `return_to_reference_day_2_close` | Labels the five selected boundaries in elapsed-time order. |
| `daily_prescribed_dry_matter_intake_kg_dm` | prescribed daily amount | kg DM | Sum over the fixed one-hour intervals: `0.32 kg DM` for balanced forcing, `0.24 kg DM` for shortfall forcing, and `0.40 kg DM` for the prescribed pulse. |
| `total_prescribed_energy_input_kj` | measured prescribed input alias | kJ | Evidence-table copy of inherited `total_prescribed_ingested_available_energy_kj`; `3200`, `2400`, or `4000 kJ` for balanced, shortfall, or pulse forcing. |
| `total_routine_activity_expenditure_kj` | measured activity alias | kJ | Evidence-table copy of inherited `total_prescribed_routine_activity_expenditure_kj`; `800 kJ` on every sequence day. |
| `cumulative_prescribed_input_contrast_kj` | cumulative external-input contrast | kJ | Treatment-minus-control prescribed energy accumulated from the common boundary; `-800 kJ` at 24 h and `0 kJ` from 48 through 96 h. |
| `gut_available_energy_contrast_kj` | gut-stock contrast | kJ | Treatment gut stock minus control gut stock at the matched boundary. |
| `body_energy_reserve_contrast_kj` | body-stock contrast | kJ | Treatment body reserve minus control body reserve at the matched boundary. |
| `combined_system_energy_contrast_kj` | two-stock system contrast | kJ | Sum of gut and body contrasts; follows the cumulative prescribed-input contrast from `-800 kJ` at 24 h to zero at 48 h and thereafter. |
| `contrast_closure_residual_kj` | contrast accounting residual | kJ | Combined-system contrast minus cumulative prescribed-input contrast; zero within the declared numerical tolerance. |
| `expected_gut_contrast_kj` | analytical gut contrast | kJ | Expected matched-boundary contrast from `delta_G[t + 1] = 0.75 * delta_G[t] + delta_I[t]`, using the declared hourly input contrast. |
| `gut_contraction_factor_from_previous_boundary` | daily post-pulse recurrence factor | dimensionless | Empty at the initial, shortfall-close, and pulse-close boundaries; `0.75^24` at each subsequent return-to-reference boundary. |
| `expected_body_complement_kj` | analytical body contrast | kJ | Cumulative prescribed-input contrast minus `expected_gut_contrast_kj`; after hour 48 it is the equal-and-opposite gut complement. |

`total_assimilated_energy_kj`, `total_maintenance_expenditure_kj`,
`expected_body_energy_change_kj`, `observed_body_energy_change_kj`,
`gut_available_energy_initial_kj`, `gut_available_energy_final_kj`,
`body_energy_reserve_initial_kj`, `body_energy_reserve_final_kj`,
`total_system_energy_initial_kj`, and `total_system_energy_final_kj` remain
copies of fields from the unchanged coupled daily result. Reusing their names
in a Goal 012 table does not redefine the package schema or the Goal 011
evidence. All Goal 012 sequence and contrast names remain evidence-only.

## Goal 005 Reference-Cycle Schemas

`run_gut_body_energy_reference_cycle()` returns an exact plain list named:

```text
convergence
hourly
daily
```

The `convergence` data frame has one row per completed gut-only burn-in day and
these columns in order:

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `burn_in_day` | convergence index | integer d | Completed burn-in day; day 1 cannot be declared converged. |
| `gut_available_energy_initial_kj` | burn-in opening gut state | kJ | Gut stock before hour 0 of the burn-in day. |
| `gut_available_energy_final_kj` | burn-in closing gut state | kJ | Gut stock after hour 23 of the burn-in day. |
| `cycle_boundary_change_kj` | period-24 boundary diagnostic | kJ | Closing stock after hour 23 minus opening stock before hour 0 for the same burn-in day. |
| `max_abs_previous_day_trajectory_difference_kj` | successive-cycle diagnostic | kJ | Maximum absolute hour-matched difference between the current and previous 25-boundary gut trajectories; `NA_real_` on day 1. |
| `realized_convergence_tolerance_kj` | numerical threshold | kJ | Scale-aware absolute threshold for both convergence comparisons; `NA_real_` on day 1 and finite and strictly positive thereafter. |
| `converged` | convergence flag | logical | `TRUE` only for the first day satisfying both the trajectory and boundary comparisons. |

The 25 boundaries are the opening stocks for hours 0 through 23 plus the
closing stock after hour 23. Burn-in advances no body state.

The measured `hourly` data frame prepends integer `measurement_day` to the
24-column coupled hourly ledger, giving 48 rows and 25 columns.
Within each measured day, `hour_of_day` remains `0:23`; continuous review time
is derived as `24 * (measurement_day - 1) + time_start_h` or `time_end_h`.

The measured `daily` data frame prepends integer `measurement_day = 1:2` to the
20-column coupled daily summary, giving two rows and 21 columns. The body state
is reset only before measured day 1. The closing gut and body stocks of day 1
open day 2 exactly.

The declared routine-activity schedule is applied only to those two measured
body days. Gut-only burn-in advances no body state or body history and remains
activity-free. Its seven-column convergence schema is unchanged.

Review tables add only a leading `scenario_id` to the exact convergence,
measured-daily, or measured-hourly schemas. CSVs retain round-trippable numeric
precision; whole-kilojoule formatting is limited to human-facing console and
figure presentation.

## One-Hour Gut Transition Fluxes

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `prescribed_ingested_available_energy_kj` | external gut input | kJ | One-hour amount added after release has been calculated from opening gut stock. |
| `assimilated_energy_kj_h` | internal transfer rate | kJ h^-1 | Fixed fraction of opening gut energy released toward the body during the hour. |
| `assimilated_energy_kj` | internal transfer amount | kJ | One-hour energy amount released from the gut and transferred one-for-one into the body ledger. |
| `gut_energy_change_kj` | gut-stock change | kJ | Prescribed ingested available energy minus assimilated energy. |
| `gut_energy_balance_residual_kj` | gut accounting residual | kJ | Observed gut-stock change minus prescribed ingestion plus assimilation. |

## Coupled Hourly Ledger

The coupled runner returns exactly these columns in this order:

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `hour_of_day` | clock key | integer 0-23 | Schedule label for the transition. |
| `time_start_h` | opening time | h | Elapsed time at the start of the transition. |
| `time_end_h` | closing time | h | Elapsed time at the end of the transition. |
| `gut_available_energy_start_kj` | opening gut state | kJ | Gut assimilable-energy equivalent before release and current-hour ingestion. |
| `prescribed_ingested_available_energy_kj_h` | prescribed gut-input rate | kJ h^-1 | Controlled input rate for the current hour. |
| `gut_release_fraction_h` | gut parameter | h^-1 | Fraction of opening gut stock released during the hour. |
| `assimilated_energy_kj_h` | internal transfer rate | kJ h^-1 | Opening-stock gut release rate passed to the body transition. |
| `prescribed_ingested_available_energy_kj` | external gut input | kJ | One-hour amount added to the gut after opening-stock release. |
| `assimilated_energy_kj` | internal transfer amount | kJ | Energy leaving the gut and entering the body during the hour. |
| `gut_energy_change_kj` | gut-stock change | kJ | Ingested amount minus assimilated amount. |
| `gut_available_energy_end_kj` | closing gut state | kJ | Gut stock after release and current-hour ingestion; it opens the next hour. |
| `gut_energy_balance_residual_kj` | gut accounting residual | kJ | Observed gut-stock change minus expected gut-stock change. |
| `body_energy_reserve_start_kj` | opening body state | kJ | Body reserve before assimilation, fixed maintenance, and prescribed routine activity are applied. |
| `maintenance_expenditure_kj_h` | body expenditure rate | kJ h^-1 | Constant synthetic maintenance expenditure rate for the hour. |
| `prescribed_routine_activity_expenditure_kj_h` | prescribed body-expenditure rate | kJ h^-1 | Externally prescribed routine-activity expenditure rate for the hour, incremental to maintenance. |
| `net_body_energy_rate_kj_h` | derived body rate | kJ h^-1 | Assimilation rate minus maintenance rate minus prescribed routine-activity rate. |
| `maintenance_expenditure_kj` | body expenditure amount | kJ | Maintenance energy leaving the body reserve during the hour. |
| `prescribed_routine_activity_expenditure_kj` | prescribed body-expenditure amount | kJ | Routine-activity energy leaving the body reserve during the one-hour interval. |
| `body_energy_change_kj` | body-stock change | kJ | Assimilated amount minus maintenance amount minus prescribed routine-activity amount. |
| `body_energy_reserve_end_kj` | closing body state | kJ | Body reserve after assimilation, maintenance, and prescribed routine activity; it opens the next hour. |
| `body_energy_balance_residual_kj` | body accounting residual | kJ | Observed body-stock change minus assimilation plus maintenance plus prescribed routine activity. |
| `total_system_energy_start_kj` | opening combined state | kJ | Opening gut stock plus opening body reserve for the modeled two-stock system. |
| `total_system_energy_end_kj` | closing combined state | kJ | Closing gut stock plus closing body reserve for the modeled two-stock system. |
| `system_energy_balance_residual_kj` | combined accounting residual | kJ | Observed combined-stock change minus prescribed ingestion plus maintenance plus prescribed routine activity; internal assimilation cancels. |

## Coupled Daily Summary

The coupled daily summary is derived from the hourly ledger and has exactly
these columns in this order:

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `gut_available_energy_initial_kj` | daily opening gut state | kJ | Gut stock at the start of hour 0. |
| `total_prescribed_ingested_available_energy_kj` | daily external input | kJ | Sum of the 24 prescribed ingested available-energy amounts. |
| `total_assimilated_energy_kj` | daily internal transfer | kJ | Sum of energy released from the gut and transferred into the body. |
| `expected_gut_energy_change_kj` | expected gut change | kJ | Total prescribed ingestion minus total assimilation. |
| `observed_gut_energy_change_kj` | observed gut change | kJ | Final gut stock minus initial gut stock. |
| `gut_available_energy_final_kj` | daily closing gut state | kJ | Gut stock after the hour 23 transition. |
| `gut_energy_balance_residual_kj` | daily gut residual | kJ | Observed gut change minus expected gut change. |
| `body_energy_reserve_initial_kj` | daily opening body state | kJ | Body reserve at the start of hour 0. |
| `total_maintenance_expenditure_kj` | daily body expenditure | kJ | Sum of the 24 maintenance amounts. |
| `total_prescribed_routine_activity_expenditure_kj` | daily prescribed body expenditure | kJ | Sum of the 24 prescribed routine-activity expenditure amounts. |
| `expected_body_energy_change_kj` | expected body change | kJ | Total assimilation minus total maintenance minus total prescribed routine activity. |
| `observed_body_energy_change_kj` | observed body change | kJ | Final body reserve minus initial body reserve. |
| `body_energy_reserve_final_kj` | daily closing body state | kJ | Body reserve after the hour 23 transition. |
| `body_energy_balance_residual_kj` | daily body residual | kJ | Observed body change minus expected body change. |
| `total_system_energy_initial_kj` | daily opening combined state | kJ | Initial gut stock plus initial body reserve. |
| `expected_total_system_energy_change_kj` | expected combined change | kJ | Total prescribed ingestion minus total maintenance minus total prescribed routine activity. |
| `observed_total_system_energy_change_kj` | observed combined change | kJ | Final combined modeled energy minus initial combined modeled energy. |
| `total_system_energy_final_kj` | daily closing combined state | kJ | Final gut stock plus final body reserve. |
| `system_energy_balance_residual_kj` | daily combined residual | kJ | Observed combined change minus expected combined change. |
| `body_energy_status` | daily body status | `neutral`, `deficit`, or `surplus` | Sign classification of observed body-reserve change using the Goal 002 tolerance. |

## Standalone Goal 002 Body Ledger

The body-only public interface remains implemented. Its hourly ledger uses:

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `hour_of_day` | clock key | integer 0-23 | Schedule label for the hourly transition. |
| `time_start_h` | opening time | h | Elapsed time at the start of the transition. |
| `time_end_h` | closing time | h | Elapsed time at the end of the transition. |
| `body_energy_reserve_start_kj` | opening state | kJ | Reserve before prescribed assimilated energy, fixed maintenance, and prescribed routine activity. |
| `prescribed_assimilated_energy_kj_h` | input rate | kJ h^-1 | Already-assimilated energy rate supplied directly to the body ledger. |
| `maintenance_expenditure_kj_h` | expenditure rate | kJ h^-1 | Constant synthetic maintenance expenditure rate. |
| `prescribed_routine_activity_expenditure_kj_h` | prescribed expenditure rate | kJ h^-1 | Externally prescribed routine-activity expenditure rate, incremental to maintenance. |
| `net_body_energy_rate_kj_h` | derived net rate | kJ h^-1 | Prescribed assimilated-energy rate minus maintenance rate minus prescribed routine-activity rate. |
| `prescribed_assimilated_energy_kj` | input amount | kJ | Already-assimilated energy entering the reserve during the hour. |
| `maintenance_expenditure_kj` | expenditure amount | kJ | Maintenance energy leaving the reserve during the hour. |
| `prescribed_routine_activity_expenditure_kj` | prescribed expenditure amount | kJ | Routine-activity energy leaving the reserve during the one-hour interval. |
| `body_energy_change_kj` | net amount | kJ | Input amount minus maintenance amount minus prescribed routine-activity amount. |
| `body_energy_reserve_end_kj` | closing state | kJ | Reserve after the one-hour change. |
| `energy_balance_residual_kj` | hourly accounting residual | kJ | Observed reserve change minus `body_energy_change_kj`. |

Its daily summary uses:

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `body_energy_reserve_initial_kj` | daily opening state | kJ | Reserve at the start of hour 0. |
| `total_prescribed_assimilated_energy_kj` | daily input total | kJ | Sum of the 24 prescribed assimilated-energy amounts. |
| `total_maintenance_expenditure_kj` | daily expenditure total | kJ | Sum of the 24 maintenance amounts. |
| `total_prescribed_routine_activity_expenditure_kj` | daily prescribed expenditure total | kJ | Sum of the 24 prescribed routine-activity expenditure amounts. |
| `expected_body_energy_change_kj` | daily expected change | kJ | Daily input total minus daily maintenance total minus daily prescribed routine-activity total. |
| `observed_body_energy_change_kj` | daily observed change | kJ | Final reserve minus initial reserve. |
| `body_energy_reserve_final_kj` | daily closing state | kJ | Reserve after the hour 23 transition. |
| `energy_balance_residual_kj` | daily accounting residual | kJ | Observed daily change minus expected daily change. |
| `energy_status` | daily status | `neutral`, `deficit`, or `surplus` | Sign classification of observed change using the Goal 002 tolerance. |

## Experiment Metadata

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `scenario_id` | experiment identifier | none | Identifies a synthetic demonstration fixture. |
| `body_mass_ref_kg` | experiment metadata | kg | Fixed value 50 used only to describe the Goal 002 demonstration animal. |

State, fixed parameters, prescribed or realized inputs, process fluxes, and
recorded history remain distinct even when they share a derived output table.
Goal 003
adds storage and delay only; Goal 004 adds one fixed food property and one
prescribed dry-matter input without new state; Goal 005 adds numerical
gut-cycle construction, one measurement reset, and two carried day keys without
new biology; Goal 006 adds named reference fixtures; Goal 007 adds one
externally prescribed incremental routine-activity expenditure without new
state or gut dynamics; Goals 008 through 012 add evidence only; and Goal 013
adds the bounded appetite controller without new dynamic state. Goal 015 adds
the repeated fixed-day appetite-controlled ledgers without a new biological
variable. Goal 016 adds one external forage-acquisition rate and its binding
indicator without resource state. Forage biomass, depletion or renewal, wet
forage, variable food properties, digestive losses or efficiency, dry-matter
gut state, physical capacity, meals, broader behavior, directed locomotion,
activity choice or feedback, mass-dependent dynamics, tissue turnover,
variable or stochastic daily forcing, seasons, chronic change, viability,
plants, and calibration have no implemented variables.

Goal 009's `0.020 kg DM h^-1` threshold is conditional on the declared
16-hour, density, maintenance, activity, and discarded-curtailment fixture. It
does not establish an empirical maximum or achievable feeding rate. Goal 010's
duration relation is likewise conditional on the fixed open-interval rate,
activity schedule, and four declared clock placements. It does not establish
voluntary use, empirical capacity, or a generic within-day duration effect.
Goal 011's fixed sequence and contrast fields are likewise evidence-only. Goal
012's direct prescribed-pulse sequence and aliases are also evidence-only.
Those clients chain existing one-day calls and add no production multi-day API,
state, schema, parameter, or test. Goal 013's fixed sequence is likewise
evidence-only beyond the three declared package records/functions. Goal 014's
factorial and component summaries remain evidence-only. Goal 015 replaces the
Goal 013 and 014 local recovery loops with the declared package runner and
ledgers above; it does not promote evidence-only gain, deficit, or recovery
summaries into package state. Goal 016 adds only the declared ceiling schedule
and target-to-realized ledger fields; its matched scenario summaries remain
evidence-only.

Historical names in `BWBrook/herbivoreTTR-legacy` at tag
`legacy-final-2026-07-16` are not binding. The corresponding pre-freeze
scientific baseline is `abf68b691b4e30020625d1871dcabe56a5926bc1`.
