# Model Specification

## Status

Goal 002 implements the first executable model layer: a minimal hourly
body-energy ledger. The model accepts prescribed already-assimilated energy,
applies constant maintenance expenditure, tracks one physical reserve, and
records 24 fixed one-hour transitions.

## Implemented Controlled System

- Represent one semi-synthetic macropod-like herbivore through one
  `body_energy_reserve_kj` state.
- Use an explicit 24-hour clock with fixed one-hour state transitions.
- Treat `prescribed_assimilated_energy_kj_h` as an already-assimilated input
  rate, not food intake or gut outflow.
- Hold `maintenance_expenditure_kj_h` constant over the day.
- Track body-energy reserve in kJ without a dynamic body-mass state.
- Keep `body_mass_ref_kg = 50` outside the model as experiment metadata because
  no implemented equation depends on mass.
- Fail before returning a state if a transition would make the reserve
  negative; do not clip the reserve or impose an upper capacity.

For each hour, the input and maintenance rates become one-hour energy amounts.
Their difference is `body_energy_change_kj`, which is added to the opening
reserve to obtain the closing reserve. Each closing reserve becomes the next
hour's opening reserve.

## Separation Of Roles

Dynamic state, fixed parameters, prescribed hourly inputs, process functions,
and recorded history are distinct objects. A transition receives validated
state, parameters, and one schedule row, then returns a new state and explicitly
named fluxes without hidden mutation. The daily runner performs exactly 24
sequential transitions using intervals `[h, h + 1)` for `hour_of_day = 0:23`.

## Implemented Outputs

The runner returns a plain list containing one 24-row `hourly` data frame and
one one-row `daily` data frame. The hourly ledger records the clock, opening and
closing reserve, input and maintenance rates, corresponding one-hour amounts,
net rate, body-energy change, and accounting residual. The daily summary is
derived from the hourly ledger and records initial and final reserve, input and
maintenance totals, expected and observed change, residual, and `neutral`,
`deficit`, or `surplus` status. Exact names and units are defined in
`variable-dictionary.md`.

No CSV, RDS, figure, dashboard, cache, evidence bundle, or other persistent
output is part of this layer.

## Demonstrated Accounting Cases

The thin experiment uses an opening reserve of 5000 kJ and maintenance of
100 kJ h^-1. Constant prescribed assimilated-energy rates of 100, 90, and
110 kJ h^-1 produce exact daily changes of 0, -240, and +240 kJ and closing
reserves of 5000, 4760, and 5240 kJ. These fixtures test arithmetic and
accounting semantics only; they are not empirical parameter estimates.

## Next Unimplemented Layer

A separately approved layer may replace the externally prescribed assimilated
energy schedule with controlled food and a one-pool gut/assimilation stock-flow
system. Food intake, food quality, gut content and capacity, passage, digestion,
and assimilation calculations are not implemented by Goal 002.

## Exclusions

Activity, dynamic body mass, protein, water, thermoregulation, plants, spatial
foraging, and cross-system coupling are later layers. Calibration, simulation
studies, release machinery, and legacy compatibility are also excluded.

The current ledger does not establish an empirically realistic maintenance
requirement, a viable animal, an ecological equilibrium, or an empirical claim
about macropods.

The historical implementation is private at `BWBrook/herbivoreTTR-legacy`, tag
`legacy-final-2026-07-16`; the pre-freeze scientific baseline is
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
