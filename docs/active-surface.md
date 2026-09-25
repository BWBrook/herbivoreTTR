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
| Fixed feeding footprints | `rectangle_overlap_m2()` measures physical intersections; `step_footprint_grazing()` limits encounters by searched area and removes realized intake conservatively. Numerical cells may subdivide the same fixed footprint. |
| Responsive area-supported forage | `step_responsive_forage()` integrates biomass-dependent production and senescence exactly; `new_area_landscape()`, `landscape_distance_m()`, and `remove_area_forage()` provide metric geometry and focal-animal mass removal. |
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

The current physical-support comparison uses `feeding-access-fixtures.R` and
`feeding-access-policy.R`, with the frozen matrix in `feeding-access-study.R`.
Separate validation files cover memory and integration. The explicitly adaptive
seven-day dose is in `feeding-access-recovery-followup.R`; figures are rendered
only by explicit calls in `feeding-access-figures.R`. See Decision 0062 for
limits of the non-nested counterfactuals.

`feeding-access-sensitivity.R` carries the 063 coefficient/policy matrix with
shared day-60 baselines, analytic reporting ratios and historical replay checks.
Its figure helper writes only to an explicit path. See
[Decision 0063](decisions/0063-encounter-and-policy-sensitivity.md).

The area-supported study is composed in `experiments/spatial-grazing-fixtures.R`,
with a frozen factorial in `spatial-grazing-study.R`, integration controls in
`spatial-grazing-validation.R`, and an explicit plotting helper in
`spatial-grazing-figures.R`. It uses a fixed local threshold/cyclic grazing rule;
the informed current-stock rule is a diagnostic comparator. These are a new
spatial representation experiment, distinct from the earlier memory-policy
comparisons below.

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

Arcs 01–04 are closed. Arc 05 now includes metric area-supported forage,
fixed physical feeding footprints, responsive production/senescence and
fractional travel. Decision 0062 separates pooled-stock feasibility from the
observed physical-access exits and records the limits of those controls.
The encounter/policy sensitivity study is closed under
[the 063 specification](feeding-access-sensitivity-specification.md).
All four missing undisturbed policy controls complete; sustained completion
depends jointly on policy and the sampled encounter coefficient. The
[recovered empirical-case assessment](rebecca-archive-assessment.md) is complete;
its proposed animal-grounding and plant-response tranche remains a scientific
discussion, with no new model implementation authorised by the assessment.

Reactive drinking remains the default. Heat balance, general activity
scheduling, dynamic plant moisture, renal response, multiple water sources,
calibrated search behaviour, mortality, and species calibration remain
deferred. The earlier duration-only proposal was superseded by the spatial
programme. The
[roadmap](roadmap.md) and [Arc 05](arcs/05-landscape-constraints-and-scenarios.md)
retain the progression and scientific decision gates.
