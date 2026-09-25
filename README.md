# herbivoreTTR

`herbivoreTTR` is a small functional R package for transparent hourly models
of herbivore energetics, body water, and forage biomass. It is a clean
scientific rebuild with explicit units, plain records, pure transitions, and
inspectable stock-flow accounting.

## Current Model

The [Rebecca archive assessment](docs/rebecca-archive-assessment.md) recovers
four field-study candidates and separates the C++/R history from the current
rebuild. The cases chiefly constrain vegetation responses; none directly
calibrates individual search, memory or physiological decline. The supplied
Borer tables match the publisher's files but need a treatment key before
factorial contrasts can be reconstructed.

The latest [encounter/policy sensitivity study](docs/decisions/0063-encounter-and-policy-sensitivity.md)
shows that alternative policies prevent the tested undisturbed exits, and
higher encounter rates permit the informed policy to complete disturbed
scenarios while experienced animals still exit. These finite-horizon results
remain conditional on synthetic scales and prior history. See the
[dimensionless diagnostics](docs/feeding-access-ratios.md).

The physical feeding-support programme now separates fixed biological search
areas from numerical cells and compares habitat layouts, information and access
controls through disturbance and recovery. See
[Decision 0062](docs/decisions/0062-physical-feeding-support-and-access.md).

The current spatial study uses one focal animal, explicit forage-support areas
and XY coordinates, distance-based fractional travel, and biomass-dependent
plant production with senescence. See [Decision 0061](docs/decisions/0061-area-supported-spatial-grazing.md)
and the [plant-model assessment](docs/plant-model-assessment.md). The earlier
linear-turnover and fixed-route systems below remain diagnostic references.

One animal's gut, body-energy reserve, location, and body water share a
24-hour clock. Intake responds to body and gut energy and is bounded by feeding
opportunity, acquisition capacity, and available forage:

```text
forage turnover and opening patch properties
  -> accessible forage and appetite target
  -> bounded realized dry-matter intake
  -> metabolizable-energy input to the gut
  -> release from opening gut stock to body reserve
  -> maintenance, activity, and movement expenditure
  -> closing states and hourly accounts
```

Current intake enters the gut after opening-stock release. State carries
exactly between hours and days. In the current spatial model, plant production
depends on standing biomass, with proportional senescence and a protected
residual. One animal's intake removes actual dry matter from its fixed feeding
footprint. Eight 100-m² feeding blocks occupy .08 ha of a 100 × 100 m domain;
numerical subdivisions preserve those physical areas.

Forage travel time and incremental expenditure depend on distance. Travel can
occupy part of an hour or span several hours; feeding uses the remaining open
time. Plants grow and senesce throughout the landscape. The earlier constant-
production, density-scaled and one-hour-route systems remain diagnostic
references with their own contracts.

The independent water ledger adds effective water from realized intake and
drinking while stationary at a known source, then accounts for ordinary loss,
prescribed incremental evaporative loss, and excess elimination. It reports a
critical-water boundary. Water, energy, and forage balances remain separate.

The package supplies records, transitions, isolated and coupled runners,
prescribed spatial days, and a fixed-demand feeding-bout choice helper.
Repeated food-patch choices, familiar-source drinking policies, synthetic
temperature forcing, and full-model decision benchmarks live in
[`experiments/`](experiments/README.md). The accepted food-choice rule uses
experienced return, elapsed absence, current adequacy, and accumulated
shortfall. It has no access to unvisited biomass or oracle results.

The herbivore, isolated-forage, non-spatial, and first explicit-patch arcs are
closed. Arc 05, landscape constraints, is active. Decision 0062 establishes
grid-independent feeding support and conditional access/policy effects;
pooled-stock trajectories complete where the tested physical-access policies
exit. These controls also change removal and renewal, so their effects cannot
be added into a unique mechanism decomposition. Reactive drinking remains the
default. Completion does not establish biological recovery or viability.

The current synthetic reference uses:

| Quantity | Value |
| --- | ---: |
| Body-energy reserve | 40,000 kJ |
| Metabolizable-energy density | 10,000 kJ kg^-1 DM |
| Gut release fraction | 0.25 h^-1 |
| Maintenance expenditure | 100 kJ h^-1 |
| Feeding opportunity | hours 0-7 and 16-23 |
| Reference intake while feeding | 0.020 kg DM h^-1 |
| Routine activity while feeding | 50 kJ h^-1 |
| Maximum intake | 0.025 kg DM h^-1 |
| Baseline ungrazed forage equilibrium | 1,000 kg DM ha^-1 |
| Production saturation scale | 2,000 kg DM ha^-1 |
| Intrinsic growth / senescence rates | 0.002 / 0.001 h^-1 |
| Residual unavailable forage | 200 kg DM ha^-1 |
| Focal animals / total vegetated area | 1 / 0.08 ha |
| Effective search area, 062 reference | 0.6 m² h^-1 |
| Forage travel speed / incremental cost | 40 m h^-1 / 1 kJ m^-1 |
| Normal body water | 28 kg |
| Thirst trigger | 26 kg |
| Critical body-water boundary | 24 kg |
| Ordinary water loss | 1.56 kg d^-1 |

These are deliberately synthetic reference values, not a jointly calibrated
organism. In particular, the energetic and water quantities do not establish
one coherent body size. Encounter and movement coefficients have no empirical
anchor. Historical reference systems use different forage contracts; their
parameters should not be substituted into the current spatial model.

Mechanistic thermoregulation, dynamic plant moisture, renal response,
multiple water sources, calibrated search behaviour, population dynamics,
reproduction, and mortality remain deferred. Body mass is a derived energy interpretation without feedback
into transitions.

## Install And Run

From the repository root, with the project library selected by `renv`:

```sh
R CMD INSTALL .
Rscript experiments/feeding-access-study.R
Rscript experiments/herbivore-core-reference.R
Rscript experiments/herbivore-core-appetite-forage.R
Rscript experiments/herbivore-core-implicit-patches.R
Rscript experiments/forage-stock-conservation.R
Rscript experiments/forage-turnover-reference.R
Rscript experiments/forage-availability-boundary.R
Rscript experiments/nonspatial-coupled-reference.R
Rscript experiments/nonspatial-animal-load-pulse.R
Rscript experiments/explicit-known-route-movement.R
Rscript experiments/explicit-prescribed-itinerary.R
Rscript experiments/explicit-static-patch-acquisition.R
Rscript experiments/explicit-known-patch-choice.R
Rscript experiments/prescribed-water-source-excursion.R
Rscript experiments/body-water-reference.R
Rscript experiments/spatial-water-source-benefit.R
Rscript experiments/hydration-controlled-water-visits.R
Rscript experiments/water-constrained-patch-choice.R
Rscript experiments/prescribed-evaporative-loss-regimes.R
Rscript experiments/causal-hydration-response.R
Rscript experiments/temperature-anticipatory-drinking.R
Rscript experiments/cost-aware-drinking.R
Rscript experiments/water-route-expenditure.R
Rscript experiments/spatial-patch-depletion-renewal.R
Rscript experiments/spatial-resource-aware-choice.R
Rscript experiments/spatial-resource-aware-switch-boundary.R
Rscript experiments/spatial-myopic-resource-choice.R
Rscript experiments/spatial-experienced-adequacy-choice.R
Rscript experiments/explicit-patch-food-quality.R
Rscript experiments/spatial-food-quality-choice-boundary.R
```

Run the focused test suite with:

```sh
Rscript -e 'testthat::test_local()'
```

The experiment scripts print compact summaries and create no files. Historical
goal-by-goal clients remain recoverable from Git and are not part of the active
execution path.

See the [active surface](docs/active-surface.md) for entry points, protected
invariants, and proportionate validation gates.

## Repository Map

- `R/`: reusable model records, transitions, and runners.
- `tests/testthat/`: focused protection of scientific invariants.
- [`experiments/README.md`](experiments/README.md): current diagnostics and
  shared fixture helpers.
- [`docs/model-charter.md`](docs/model-charter.md): governing scientific and
  architectural contract.
- [`docs/model-specification.md`](docs/model-specification.md): equations,
  transition order, diagnostic contracts, and outputs.
- [`docs/variable-dictionary.md`](docs/variable-dictionary.md): quantities and
  units.
- [`docs/decisions/`](docs/decisions/README.md): retained scientific reasoning
  and accepted conclusions.
- [`docs/roadmap.md`](docs/roadmap.md): stage status and development plans.
- [`docs/arcs/`](docs/arcs/05-landscape-constraints-and-scenarios.md):
  arc contracts and scientific decision boundaries.
- [`HANDOVER.md`](HANDOVER.md): current successor entry point and evidence.

The project is licensed under the MIT License.
