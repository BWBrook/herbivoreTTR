# Active Surface

`herbivoreTTR` provides inspectable hourly models of herbivore energy, body
water, and forage biomass for scientific investigation. This page indexes
the executable contract. Equations and diagnostic details belong in the
[model specification](model-specification.md); the development history and
accepted reasoning belong in [decisions](decisions/README.md).

## Package Entry Points

| Path | Entry points and responsibility |
| --- | --- |
| Prescribed energy | `run_body_energy_day()` isolates the body ledger; `run_gut_body_energy_day()` composes opening-stock gut release with body input, maintenance, and activity. |
| Appetite | `run_gut_body_energy_reference_cycle()` establishes periodic gut state; `run_appetite_controlled_energy_days()` carries body and gut state under bounded intake. |
| Body-mass interpretation | `derive_body_mass_from_energy_reserve()` reports derived mass without changing or feeding back into state. |
| Isolated forage | `run_forage_biomass_day()` accounts for prescribed growth and loss; `run_forage_turnover_days()` applies constant production and proportional loss. |
| Accessibility and removal | `derive_accessible_forage_biomass()` applies the residual threshold; `step_forage_herbivory()` scales realized per-animal intake into forage removal. |
| Homogeneous coupling | `run_nonspatial_coupled_energy_days()` composes turnover, accessibility, appetite, removal, and animal energy at fixed density. |
| Spatial records and movement | `new_known_route_landscape()`, `new_patch_location_state()`, and `step_known_route_movement()` represent patch food properties and directed one-hour routes. |
| Prescribed spatial days | `new_prescribed_patch_itinerary()` declares hourly closing locations; `run_prescribed_spatial_energy_day()` composes them with animal energy. `new_spatial_forage_biomass_state()` and `run_prescribed_spatial_coupled_energy_day()` add locally depleted, independently renewing forage stocks. |
| One feeding-bout choice | `choose_known_patch_for_feeding_bout()` scores stay versus one known route using fixed expected demand, opportunity remaining, patch food properties, and travel cost. |
| Water | `run_body_water_day()` carries an isolated water stock; `run_spatial_body_water_day()` derives food and stationary drinking inputs from an existing spatial energy ledger and accepts separate prescribed evaporative loss. |

Constructors return plain validated records. Public transitions are pure;
closing states can be carried into subsequent calls. The water adapter leaves
the energy ledger unchanged.

## Experiment-Level Behavior

The [diagnostic index](../experiments/README.md) identifies current executable
comparisons. Repeated choice and forcing policies are compositions of the
package functions, outside the package API.

The accepted food-patch rule uses last and best experienced return, elapsed
absence, current energetic adequacy, and accumulated shortfall. Expected
unvisited return recovers over two absent days. The animal stays while its
current patch is adequate; after inadequacy develops, shortfall augments the
travel comparison. The information boundary and accepted contrasts are in
[Decision 0054](decisions/0054-experienced-adequacy-memory.md).

Causal drinking detects the thirst threshold on the hourly clock and makes
at most one complete familiar-source excursion per day, deferring late
crossings. The current hourly composition advances actual state through each
completed interval. The earlier daily-opening policy and Goal 057 provisional
day construction remain explicit comparison paths. The temperature-loss
driver and two recent-experience anticipatory comparators are also experimental.
The cost-aware variant gates optional 08:00 top-ups by estimated trip cost per
kilogram of refill, using completed water draw and food return plus known trip
cost and feeding hours. It cannot defer an already triggered reactive trip.

Perfect-state oracles, myopic comparisons, and rejected memory rules retain
their diagnostic role. An oracle's local action agreement or regret does not
score a separately carried long-run policy. Their numerical boundaries and
historical outcomes are recorded in the specification and decision notes.

## Protected Invariants

- Physical quantities have explicit units. The clock is 24 one-hour intervals
  labelled `0:23`; closing stocks carry exactly between intervals and days.
- Stocks and prescribed inputs are finite and non-negative. Negative closing
  body energy, body water, or forage stocks fail explicitly.
- Gut release uses opening stock before current ingestion. Assimilation is
  an internal energy transfer that cancels from the whole-system balance.
- Hourly and daily energy, forage, and water identities close independently.
  The constant coupled reference repeats with neutral daily energy balance.
- Appetite matches its reference on the reference trajectory, vanishes when
  feeding is closed, and stays within its bounds. Realized intake is capped by
  appetite, acquisition rate, and accessible forage per represented animal.
- Forage turnover is neutral at equilibrium and approaches it monotonically
  from above or below. Accessibility increases one-for-one only above the
  residual threshold. Herbivory equals intake times animal density and cannot
  remove the residual stock.
- Patch and route identifiers are unique and endpoints are valid. A move
  begins at its declared origin, suspends feeding, and closes at its
  destination. Travel duration, feeding time lost, and route expenditure
  remain separately observable.
- Stationary feeding uses the opening patch's acquisition capacity and food
  energy density. Dynamic turnover acts everywhere; unoccupied and transit
  patches have zero herbivory.
- All-stay spatial paths reduce exactly to their corresponding non-spatial
  energy and forage references, including patch-specific food quality. An
  unoccupied patch reduces exactly to isolated turnover.
- The fixed-demand choice applies each patch's food-energy density, subtracts
  travel time and expenditure, and stays on ties. Full-model comparisons use
  matched opening states and attribute advantage to intake energy and cost.
- Food water follows realized intake in the opening patch. Drinking occurs
  only while stationary at a source and cannot raise water above normal.
  Incremental evaporation is a separate non-negative flux; zero forcing
  reproduces the preceding water model.
- Disabling water reproduces the accepted food-patch trajectory. Food-return
  memory uses only stationary open opportunities in food patches, excluding
  water travel and source stays.
- Behavioral comparisons retain their declared information limits: the
  accepted food rule sees no unvisited biomass or oracle result; reactive
  drinking waits for observed thirst; anticipation uses current water and
  completed physiological draw history.
- Temperature phase comparisons preserve imposed dose. Policy costs are
  compared over common completed hourly horizons. Synthetic balance and
  energy-boundary termination do not establish viability or mortality.

The detailed comparison-specific assertions remain in the
[model specification](model-specification.md), tests, and retained diagnostic
scripts. Historical experiment ancestry is recoverable from Git; generated
outputs remain ignored. Compatibility adapters, dormant flags, and retired
review machinery have no role in the active surface.

## Validation

For ordinary changes, parse retained R, run tests affected by the change,
and run `git diff --check`. The full test command is:

```sh
Rscript --vanilla -e 'testthat::test_local()'
```

When publishing a package boundary or completed model stage, run the full
suite, current diagnostics, an external `R CMD build`, and
`R CMD check --no-manual` once. Repeat a gate only for a distinct named risk.

## Current Stop

Arcs 01–04 are closed. Arc 05 has accepted experience-based food choice,
body-water accounting, prescribed evaporative loss, and causal familiar-source
drinking. Goal 060 varied water-route expenditure with trip duration fixed.
Halving cost allows all heated coupled branches to complete 126 d; at the
inherited cost they all stop before heat removal. Doubling cost also stops the
no-added-heat coupled branches around day 85. Lower expenditure need not raise
energy at every checkpoint because appetite and forage feedback alter intake.
Reactive drinking remains the default, with both fallible anticipatory rules
retained. See [Decision 0060](decisions/0060-water-route-expenditure.md) and the
[handover](../HANDOVER.md).

A water-trip duration comparison at fixed round-trip expenditure is proposed
next and awaits approval. Its late-departure, forecast, and day-boundary
conventions need an explicit contract before implementation. Heat balance,
general activity scheduling, dynamic plant moisture, renal response, multiple
sources, search, mortality, and species calibration remain deferred. The
[roadmap](roadmap.md) and [Arc 05](arcs/05-landscape-constraints-and-scenarios.md)
retain the progression and scientific decision gates.
