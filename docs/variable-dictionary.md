# Variable Dictionary

## Status

These are the exact names used by the implemented Goal 002 body-energy ledger
and its thin experiment. Rates in kJ h^-1 and one-hour amounts in kJ are
distinct even when their numerical values match for a one-hour transition.

## Core Records

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `body_energy_reserve_kj` | dynamic state | kJ | Current physical body-energy reserve; the opening state supplied to a transition. |
| `maintenance_expenditure_kj_h` | fixed parameter rate | kJ h^-1 | Constant maintenance-only energy expenditure rate. |
| `hour_of_day` | prescribed clock | integer 0-23 | Label for the one-hour interval `[hour_of_day, hour_of_day + 1)`. |
| `prescribed_assimilated_energy_kj_h` | prescribed input rate | kJ h^-1 | Non-negative energy rate already assimilated before it enters this ledger. |

## Hourly Ledger

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `hour_of_day` | clock key | integer 0-23 | Schedule label for the hourly transition. |
| `time_start_h` | opening time | h | Elapsed time at the start of the transition. |
| `time_end_h` | closing time | h | Elapsed time at the end of the fixed one-hour transition. |
| `body_energy_reserve_start_kj` | opening state | kJ | Reserve before prescribed energy and maintenance are applied. |
| `prescribed_assimilated_energy_kj_h` | input rate | kJ h^-1 | Prescribed already-assimilated energy rate for this hour. |
| `maintenance_expenditure_kj_h` | expenditure rate | kJ h^-1 | Constant maintenance expenditure rate for this hour. |
| `net_body_energy_rate_kj_h` | derived net rate | kJ h^-1 | Input rate minus maintenance rate. |
| `prescribed_assimilated_energy_kj` | one-hour input amount | kJ | Energy entering the reserve ledger during this transition. |
| `maintenance_expenditure_kj` | one-hour expenditure amount | kJ | Maintenance energy leaving the reserve ledger during this transition. |
| `body_energy_change_kj` | one-hour net amount | kJ | Input amount minus maintenance amount. |
| `body_energy_reserve_end_kj` | closing state | kJ | Reserve after the one-hour body-energy change; it opens the next transition. |
| `energy_balance_residual_kj` | hourly accounting residual | kJ | Closing-minus-opening reserve change minus `body_energy_change_kj`. |

## Daily Summary

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `body_energy_reserve_initial_kj` | daily opening state | kJ | Reserve at the start of hour 0. |
| `total_prescribed_assimilated_energy_kj` | daily input total | kJ | Sum of the 24 one-hour prescribed assimilated-energy amounts. |
| `total_maintenance_expenditure_kj` | daily expenditure total | kJ | Sum of the 24 one-hour maintenance amounts. |
| `expected_body_energy_change_kj` | daily expected change | kJ | Daily input total minus daily maintenance total. |
| `observed_body_energy_change_kj` | daily observed change | kJ | Final reserve minus initial reserve. |
| `body_energy_reserve_final_kj` | daily closing state | kJ | Reserve after the hour 23 transition. |
| `energy_balance_residual_kj` | daily accounting residual | kJ | Observed daily change minus expected daily change. |
| `energy_status` | daily status | `neutral`, `deficit`, or `surplus` | Sign classification of observed change using the internal floating-point tolerance. |

## Experiment Metadata

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `scenario_id` | experiment identifier | none | Identifies the neutral, deficit, or surplus demonstration fixture. |
| `body_mass_ref_kg` | experiment metadata | kg | Fixed value 50 used to describe the demonstration animal; never passed to a core model function. |

State, fixed parameters, prescribed inputs, process fluxes, and history must
remain separate even when they share a row in a derived output table. The same
`energy_balance_residual_kj` name is used in the hourly and daily schemas, but
its row context distinguishes transition closure from complete-day closure.

Food, gut, passage, digestion, and assimilation-calculation variables belong
to the next separately approved, unimplemented layer and are not part of this
implemented dictionary.

Historical names in `BWBrook/herbivoreTTR-legacy` at tag
`legacy-final-2026-07-16` are not binding. The corresponding pre-freeze
scientific baseline is `abf68b691b4e30020625d1871dcabe56a5926bc1`.
