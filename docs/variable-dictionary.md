# Variable Dictionary

## Status

These names reserve a dimensionally explicit vocabulary for the future
irreducible core. No variable below is implemented by the foundation commit.

| Name | Role | Unit | Meaning |
| --- | --- | --- | --- |
| `time_h` | history key | h | Elapsed model time from the start of the run. |
| `hour_of_day` | prescribed clock | integer 0-23 | Hour in the explicit daily cycle. |
| `body_mass_ref_kg` | fixed parameter | kg | Fixed 50 kg reference body mass. |
| `intake_food_kg_dm_h` | prescribed input | kg dry matter h^-1 | Controlled hourly food intake. |
| `food_energy_density_kj_kg_dm` | fixed parameter | kJ kg dry matter^-1 | Energy density of the homogeneous food. |
| `gut_content_kg_dm` | dynamic state | kg dry matter | Material in the one well-mixed gut pool. |
| `gut_capacity_kg_dm` | validation parameter | kg dry matter | Fail-fast upper boundary for gut content. |
| `gut_passage_rate_h` | fixed parameter | h^-1 | First-order hourly gut passage rate. |
| `body_energy_reserve_kj` | dynamic state | kJ | Tracked body-energy reserve. |
| `maintenance_expenditure_kj_h` | fixed parameter | kJ h^-1 | Maintenance-only energy expenditure. |
| `gut_outflow_kg_dm_h` | process flux | kg dry matter h^-1 | Material leaving the gut pool. |
| `assimilated_energy_kj_h` | process flux | kJ h^-1 | Energy assimilated from the controlled food. |
| `body_energy_change_kj_h` | derived flux | kJ h^-1 | Assimilated energy minus maintenance expenditure. |

State, fixed parameters, prescribed inputs, process fluxes, and history must
remain separate even when they share a row in a derived output table. Exact
definitions and assumptions require approval in the implementation goal.

Historical names in `BWBrook/herbivoreTTR-legacy` at tag
`legacy-final-2026-07-16` are not binding. The corresponding pre-freeze
scientific baseline is `abf68b691b4e30020625d1871dcabe56a5926bc1`.
