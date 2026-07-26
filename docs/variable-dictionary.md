# Variable Dictionary

## Status

These are the exact public record, flux, and ledger names implemented through
Goal 003. Rates in kJ h^-1 and one-hour amounts in kJ remain distinct even when
their numerical values match for the fixed one-hour transition.

The gut stock is expressed in assimilable-energy equivalents. It is not food
mass, gross energy, plant biomass, measured gut fill, or a calibrated
physiological quantity.

## Core Records And Prescribed Inputs

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `gut_available_energy_kj` | dynamic gut state | kJ | Assimilable-energy equivalent available in the single gut pool at a transition boundary. |
| `body_energy_reserve_kj` | dynamic body state | kJ | Physical body-energy reserve at a transition boundary. |
| `gut_release_fraction_h` | fixed gut parameter | h^-1 | Fraction of opening gut energy released during each fixed one-hour transition; constrained to `(0, 1]`. |
| `maintenance_expenditure_kj_h` | fixed body parameter rate | kJ h^-1 | Constant maintenance-only energy expenditure rate. |
| `hour_of_day` | prescribed clock | integer 0-23 | Label for the half-open one-hour interval `[hour_of_day, hour_of_day + 1)`. |
| `prescribed_ingested_available_energy_kj_h` | prescribed gut-input rate | kJ h^-1 | Controlled assimilable-energy equivalent entering the gut during an hour. |
| `prescribed_assimilated_energy_kj_h` | prescribed body-input rate | kJ h^-1 | Already-assimilated energy supplied directly to the standalone Goal 002 body ledger. |

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
| `body_energy_reserve_start_kj` | opening body state | kJ | Body reserve before assimilation and maintenance are applied. |
| `maintenance_expenditure_kj_h` | body expenditure rate | kJ h^-1 | Constant maintenance expenditure rate for the hour. |
| `maintenance_expenditure_kj` | body expenditure amount | kJ | Maintenance energy leaving the body reserve during the hour. |
| `body_energy_change_kj` | body-stock change | kJ | Assimilated amount minus maintenance amount. |
| `body_energy_reserve_end_kj` | closing body state | kJ | Body reserve after assimilation and maintenance; it opens the next hour. |
| `body_energy_balance_residual_kj` | body accounting residual | kJ | Observed body-stock change minus assimilation plus maintenance. |
| `total_system_energy_start_kj` | opening combined state | kJ | Opening gut stock plus opening body reserve for the modeled two-stock system. |
| `total_system_energy_end_kj` | closing combined state | kJ | Closing gut stock plus closing body reserve for the modeled two-stock system. |
| `system_energy_balance_residual_kj` | combined accounting residual | kJ | Observed combined-stock change minus prescribed ingestion plus maintenance; internal assimilation cancels. |

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
| `expected_body_energy_change_kj` | expected body change | kJ | Total assimilation minus total maintenance. |
| `observed_body_energy_change_kj` | observed body change | kJ | Final body reserve minus initial body reserve. |
| `body_energy_reserve_final_kj` | daily closing body state | kJ | Body reserve after the hour 23 transition. |
| `body_energy_balance_residual_kj` | daily body residual | kJ | Observed body change minus expected body change. |
| `total_system_energy_initial_kj` | daily opening combined state | kJ | Initial gut stock plus initial body reserve. |
| `expected_total_system_energy_change_kj` | expected combined change | kJ | Total prescribed ingestion minus total maintenance. |
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
| `body_energy_reserve_start_kj` | opening state | kJ | Reserve before prescribed assimilated energy and maintenance. |
| `prescribed_assimilated_energy_kj_h` | input rate | kJ h^-1 | Already-assimilated energy rate supplied directly to the body ledger. |
| `maintenance_expenditure_kj_h` | expenditure rate | kJ h^-1 | Constant maintenance expenditure rate. |
| `net_body_energy_rate_kj_h` | derived net rate | kJ h^-1 | Prescribed assimilated-energy rate minus maintenance rate. |
| `prescribed_assimilated_energy_kj` | input amount | kJ | Already-assimilated energy entering the reserve during the hour. |
| `maintenance_expenditure_kj` | expenditure amount | kJ | Maintenance energy leaving the reserve during the hour. |
| `body_energy_change_kj` | net amount | kJ | Input amount minus maintenance amount. |
| `body_energy_reserve_end_kj` | closing state | kJ | Reserve after the one-hour change. |
| `energy_balance_residual_kj` | hourly accounting residual | kJ | Observed reserve change minus `body_energy_change_kj`. |

Its daily summary uses:

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `body_energy_reserve_initial_kj` | daily opening state | kJ | Reserve at the start of hour 0. |
| `total_prescribed_assimilated_energy_kj` | daily input total | kJ | Sum of the 24 prescribed assimilated-energy amounts. |
| `total_maintenance_expenditure_kj` | daily expenditure total | kJ | Sum of the 24 maintenance amounts. |
| `expected_body_energy_change_kj` | daily expected change | kJ | Daily input total minus daily maintenance total. |
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
adds storage and delay only. Food properties, digestive losses, capacity,
behavior, activity, mass change, plants, and calibration have no implemented
variables.

Historical names in `BWBrook/herbivoreTTR-legacy` at tag
`legacy-final-2026-07-16` are not binding. The corresponding pre-freeze
scientific baseline is `abf68b691b4e30020625d1871dcabe56a5926bc1`.
