# Variable Dictionary

## Status

These are the exact public record, flux, and ledger names implemented through
Goal 010. The production schema last changed in Goal 007; Goals 008, 009, and
010 add evidence outputs only. Rates in kJ h^-1 and one-hour amounts in kJ
remain distinct even when their numerical values match for the fixed one-hour
transition.

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

## Goal 009 Evidence-Only Review Columns

Goal 009 adds no package variable, state, parameter, record, or return schema.
The names below exist only in the no-write experiment and ignored review pack.
They describe a synthetic client-side `pmin` prescription, not appetite,
feeding behavior, forage availability, gut capacity, or a production ceiling.

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
and ignored review pack. `prescribed_intake_window_open = TRUE` means that the
labeled interval is fully used at the fixed prescribed intake rate; it is not
voluntary opportunity, realized behavior, forage access, or empirical capacity.

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

State, fixed parameters, prescribed inputs, process fluxes, and recorded
history remain distinct even when they share a derived output table. Goal 003
adds storage and delay only; Goal 004 adds one fixed food property and one
prescribed dry-matter input without new state; Goal 005 adds numerical
gut-cycle construction, one measurement reset, and two carried day keys without
new biology; Goal 006 adds named reference fixtures; Goal 007 adds one
externally prescribed incremental routine-activity expenditure without new
state or gut dynamics; and Goals 008, 009, and 010 add evidence only. Offered
or wet forage, variable food properties, digestive losses or efficiency,
dry-matter gut state, capacity, production intake limits, behavior, directed
locomotion, activity choice or feedback, mass change, variable or stochastic
days, seasons, chronic change, viability, plants, and calibration have no
implemented variables.

Goal 009's `0.020 kg DM h^-1` threshold is conditional on the declared
16-hour, density, maintenance, activity, and discarded-curtailment fixture. It
does not establish an empirical maximum or achievable feeding rate. Goal 010's
duration relation is likewise conditional on the fixed open-interval rate,
activity schedule, and four declared clock placements. It does not establish
voluntary use, empirical capacity, or a generic within-day duration effect.
Goal 011 remains unapproved.

Historical names in `BWBrook/herbivoreTTR-legacy` at tag
`legacy-final-2026-07-16` are not binding. The corresponding pre-freeze
scientific baseline is `abf68b691b4e30020625d1871dcabe56a5926bc1`.
