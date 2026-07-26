# Model Specification

## Status

Goal 003 couples one first-order gut-energy stock to the accepted Goal 002
body-energy ledger. The model converts controlled prescribed ingestion into
delayed, smoothed assimilation while recording 24 fixed one-hour transitions.

The gut stock is measured in assimilable-energy equivalents. This is a
deliberately synthetic accounting model, not an empirical model of food,
digestion, or macropod physiology.

## Implemented Controlled System

- Represent the internal stocks as `gut_available_energy_kj` and
  `body_energy_reserve_kj`.
- Use an explicit 24-hour clock with fixed one-hour state transitions.
- Treat `prescribed_ingested_available_energy_kj_h` as controlled energy
  entering the gut, not food mass, gross energy, plant biomass, or energy that
  has already entered the body.
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

## Implemented Outputs

`step_gut_energy()` returns a closing gut state and the one-hour ingestion,
assimilation, change, and residual fluxes.

`run_gut_body_energy_day()` returns a plain list containing:

- one 24-row `hourly` data frame with clock fields, opening and closing gut and
  body stocks, rates, one-hour amounts, stock changes, combined modeled energy,
  and separate gut, body, and system residuals; and
- one one-row `daily` data frame derived from the hourly ledger, with gut,
  body, and combined-system totals, expected and observed changes, residuals,
  and the Goal 002 body-reserve status.

Exact names and units are defined in `variable-dictionary.md`. No package
function writes a CSV, RDS, figure, cache, or evidence bundle.

## Synthetic Demonstrations

All Goal 003 fixtures use `gut_release_fraction_h = 0.25` and begin with
`body_energy_reserve_kj = 5000`.

- **Equilibrium:** opening gut stock 400 kJ, ingestion 100 kJ h^-1, and
  maintenance 100 kJ h^-1 keep both stocks constant.
- **Empty start:** opening gut stock 0 kJ with the same ingestion and
  maintenance approaches the 400 kJ gut equilibrium geometrically; the
  temporary body-reserve loss equals energy accumulating in the gut.
- **Single pulse:** 400 kJ enters an empty gut in hour 0 with zero maintenance.
  Nothing is assimilated in hour 0; subsequent release is geometric while
  combined gut-plus-body energy remains constant.

These fixtures test update order, buffering, and conservation. They are not
estimates of gut residence time, maintenance, intake, gut fill, physiological
stress, viability, or ecological equilibrium.

## Exclusions And Stop

The model does not represent food dry mass, gross energy, food quality,
digestibility, assimilation efficiency, digestive loss, waste, gut capacity,
multiple compartments, feeding decisions, behavior, activity, dynamic body
mass, protein, water, thermoregulation, plants, weather, space, individuals,
populations, empirical calibration, or uncertainty analysis.

No subsequent model layer is specified or authorized. Goal 003 ends after the
one-pool storage-and-delay mechanism and its synthetic demonstrations are
validated and reviewed.

The historical implementation is private at `BWBrook/herbivoreTTR-legacy`, tag
`legacy-final-2026-07-16`; the pre-freeze scientific baseline is
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
