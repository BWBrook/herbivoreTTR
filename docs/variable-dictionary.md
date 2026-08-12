# Variable Dictionary

## Naming Rules

Names state both meaning and unit. `_h` denotes a rate per hour, `_kj` an energy
amount or stock, `_kg_dm` dry-matter mass, `_ha` a per-hectare basis, and `_kg`
body or tissue mass. Rates and one-hour amounts remain separate even though
their numerical values match on the current hourly clock.

## Dynamic State

| Variable | Unit | Meaning |
| --- | --- | --- |
| `gut_available_energy_kj` | kJ | Energy available for later gut release |
| `body_energy_reserve_kj` | kJ | Labile physical body-energy reserve |
| `forage_biomass_kg_dm_ha` | kg DM ha^-1 | Homogeneous standing edible forage biomass density |

Energy ledgers use `_start_kj`, `_end_kj`, `_initial_kj`, and `_final_kj`.
The forage ledger uses the corresponding `_start_kg_dm_ha`, `_end_kg_dm_ha`,
`_initial_kg_dm_ha`, and `_final_kg_dm_ha` suffixes.

## Fixed Parameters

| Variable | Unit | Meaning |
| --- | --- | --- |
| `gut_release_fraction_h` | h^-1 | Fraction of opening gut stock released each hour |
| `maintenance_expenditure_kj_h` | kJ h^-1 | Fixed body maintenance expenditure |
| `metabolizable_energy_density_kj_kg_dm` | kJ kg^-1 DM | Available energy per dry-matter mass |
| `maximum_dry_matter_intake_kg_dm_h` | kg DM h^-1 | Upper appetite target |
| `body_energy_feedback_fraction_h` | h^-1 | Body-deviation feedback fraction |
| `gut_energy_feedback_fraction_h` | h^-1 | Gut-deviation feedback fraction |
| `structural_body_mass_kg` | kg | Fixed mass outside labile reserve tissue |
| `reserve_tissue_energy_density_kj_kg` | kJ kg^-1 | Effective energy density of reserve tissue |
| `equilibrium_forage_biomass_kg_dm_ha` | kg DM ha^-1 | Positive equilibrium for the linear forage reference |
| `forage_turnover_fraction_h` | h^-1 | Fraction controlling hourly reference production and current-biomass loss |

## Prescribed Schedules

Every schedule has 24 rows and `hour_of_day = 0:23`.

| Variable | Unit | Meaning |
| --- | --- | --- |
| `feeding_opportunity_open` | logical | Whether a positive appetite target is permitted |
| `prescribed_dry_matter_intake_kg_dm_h` | kg DM h^-1 | Externally prescribed intake before appetite control |
| `prescribed_ingested_available_energy_kj_h` | kJ h^-1 | Available energy prescribed to enter the gut |
| `prescribed_assimilated_energy_kj_h` | kJ h^-1 | Body-only diagnostic input |
| `prescribed_routine_activity_expenditure_kj_h` | kJ h^-1 | Activity expenditure incremental to maintenance |
| `forage_acquisition_ceiling_kg_dm_h` | kg DM h^-1 | External upper bound on realized acquisition |
| `reference_dry_matter_intake_kg_dm_h` | kg DM h^-1 | Appetite target on the reference trajectory |
| `reference_body_energy_reserve_kj` | kJ | Reference opening body stock |
| `reference_gut_available_energy_kj` | kJ | Reference opening gut stock |
| `prescribed_forage_growth_kg_dm_ha_h` | kg DM ha^-1 h^-1 | External forage growth input |
| `prescribed_forage_background_loss_kg_dm_ha_h` | kg DM ha^-1 h^-1 | External non-herbivore forage loss |

## Forage-Biomass Fluxes

| Variable | Unit | Meaning |
| --- | --- | --- |
| `net_forage_biomass_rate_kg_dm_ha_h` | kg DM ha^-1 h^-1 | Growth rate minus background-loss rate |
| `prescribed_forage_growth_kg_dm_ha` | kg DM ha^-1 | Growth added during one hour |
| `prescribed_forage_background_loss_kg_dm_ha` | kg DM ha^-1 | Background loss during one hour |
| `forage_biomass_change_kg_dm_ha` | kg DM ha^-1 | Net one-hour stock change |
| `forage_biomass_balance_residual_kg_dm_ha` | kg DM ha^-1 | Observed change minus expected net flow |
| `forage_growth_kg_dm_ha_h` | kg DM ha^-1 h^-1 | Turnover-reference production rate |
| `forage_background_loss_kg_dm_ha_h` | kg DM ha^-1 h^-1 | Turnover-reference proportional loss rate |
| `forage_growth_kg_dm_ha` | kg DM ha^-1 | Turnover-reference production during one hour |
| `forage_background_loss_kg_dm_ha` | kg DM ha^-1 | Turnover-reference loss during one hour |

## Appetite Quantities

| Variable | Unit | Meaning |
| --- | --- | --- |
| `body_energy_deviation_from_reference_kj` | kJ | Opening body stock minus its reference |
| `gut_energy_deviation_from_reference_kj` | kJ | Opening gut stock minus its reference |
| `body_energy_feedback_kj_h` | kJ h^-1 | Signed intake adjustment from body state |
| `gut_energy_feedback_kj_h` | kJ h^-1 | Signed intake adjustment from gut state |
| `unconstrained_dry_matter_intake_kg_dm_h` | kg DM h^-1 | Appetite before bounds and opportunity closure |
| `appetite_target_dry_matter_intake_kg_dm_h` | kg DM h^-1 | Bounded demand before forage limitation |
| `realized_dry_matter_intake_kg_dm_h` | kg DM h^-1 | Intake after forage limitation |
| `lower_intake_bound_active` | logical | Whether zero truncated the open-hour target |
| `upper_intake_bound_active` | logical | Whether the physiological maximum truncated it |
| `forage_acquisition_ceiling_active` | logical | Whether forage supply truncated appetite demand |

Energy-rate counterparts use `_ingested_available_energy_kj_h`.

## Gut And Body Fluxes

| Variable | Unit | Meaning |
| --- | --- | --- |
| `assimilated_energy_kj_h` | kJ h^-1 | Energy released from opening gut stock |
| `gut_energy_change_kj` | kJ | Intake minus assimilation over one hour |
| `maintenance_expenditure_kj` | kJ | One-hour maintenance amount |
| `prescribed_routine_activity_expenditure_kj` | kJ | One-hour routine-activity amount |
| `net_body_energy_rate_kj_h` | kJ h^-1 | Assimilation minus maintenance and activity |
| `body_energy_change_kj` | kJ | One-hour change in body reserve |

`gut_energy_balance_residual_kj`, `body_energy_balance_residual_kj`, and
`system_energy_balance_residual_kj` are numerical accounting diagnostics. They
are not ecological states.

## Time And History

| Variable | Unit | Meaning |
| --- | --- | --- |
| `hour_of_day` | hour index | Interval label from 0 through 23 |
| `time_start_h` | h | Continuous start time from simulation origin |
| `time_end_h` | h | Continuous end time |
| `simulation_day` | day index | Carried day number in repeated runs |
| `measurement_day` | day index | Day number after reference-cycle initialization |

## Daily Summaries

Daily tables report opening and closing gut, body, and combined stocks; total
input, assimilation, maintenance, and activity; expected and observed changes;
and their balance residuals. Appetite-controlled summaries additionally report
daily reference, target, and realized dry-matter intake; counts of active
bounds; and final deviations from the reference trajectory.

The forage daily summary reports opening and closing standing biomass, total
prescribed growth and background loss, expected and observed biomass change,
and their balance residual.

Turnover-reference daily summaries additionally report the declared
equilibrium, total derived growth and loss, and opening and closing deviations
from equilibrium.

`body_energy_status` or `energy_status` is `deficit`, `neutral`, or `surplus`
according to the scale-aware arithmetic tolerance. It is not a viability or
health classification.

## Derived Body Mass

| Variable | Unit | Meaning |
| --- | --- | --- |
| `reserve_tissue_mass_kg` | kg | Body-energy reserve divided by effective tissue density |
| `total_body_mass_kg` | kg | Structural mass plus reserve-tissue mass |

These are derived outputs and never dynamic state.

## Diagnostic-Only Terms

Patch identifiers, treatment labels, movement flags, variable hourly food
density, extra feeding hours, and recovery classifications exist only inside
the retained experiments. They are not package records or supported model
state.
