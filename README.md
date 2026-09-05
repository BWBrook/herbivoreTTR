# herbivoreTTR

`herbivoreTTR` is a small functional R package for transparent hourly models
of herbivore energetics, body water, and forage biomass. It is a clean
scientific rebuild with explicit units, plain records, pure transitions, and
inspectable stock-flow accounting.

## Current Model

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
exactly between hours and days. Forage uses constant production and
proportional background loss around a fixed equilibrium, with a residual
threshold below which biomass is unavailable. In the coupled system,
per-animal intake scales by a fixed animal density to remove forage. This is
an aggregate homogeneous load applied to one representative physiology.

Explicit patches carry acquisition capacities, food-energy densities, and
optionally dynamic forage stocks. Directed known routes take one hour,
suspend feeding, and add movement expenditure. Autonomous turnover acts on
every patch; herbivory occurs only in the occupied patch during a stay.

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
closed. Arc 05, landscape constraints, is active. The latest comparison found
that an anticipatory 08:00 top-up could delay the evening energy boundary but
worsened the midday case and did not improve the shifted case. It remains a
comparator to causal thirst-triggered drinking; see
[`Decision 0058`](docs/decisions/0058-temperature-anticipatory-drinking.md).
Cost-aware trip timing is proposed and awaits approval. These are synthetic
mechanism results; energy-boundary termination does not establish mortality
or species viability.

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
| Forage equilibrium | 1,000 kg DM ha^-1 |
| Forage turnover fraction | 0.001 h^-1 |
| Residual unavailable forage | 500 kg DM ha^-1 |
| Coupled-reference animal density | 10 animals ha^-1 |
| Normal body water | 28 kg |
| Thirst trigger | 26 kg |
| Critical body-water boundary | 24 kg |
| Ordinary water loss | 1.56 kg d^-1 |

These are deliberately synthetic reference values, not an empirical kangaroo
parameterization.

Mechanistic thermoregulation, dynamic plant moisture, renal response,
multiple sources, search, population dynamics, reproduction, and mortality
remain deferred. Body mass is a derived energy interpretation without feedback
into transitions.

## Install And Run

From the repository root:

```sh
R CMD INSTALL .
Rscript --vanilla experiments/herbivore-core-reference.R
Rscript --vanilla experiments/herbivore-core-appetite-forage.R
Rscript --vanilla experiments/herbivore-core-implicit-patches.R
Rscript --vanilla experiments/forage-stock-conservation.R
Rscript --vanilla experiments/forage-turnover-reference.R
Rscript --vanilla experiments/forage-availability-boundary.R
Rscript --vanilla experiments/nonspatial-coupled-reference.R
Rscript --vanilla experiments/nonspatial-animal-load-pulse.R
Rscript --vanilla experiments/explicit-known-route-movement.R
Rscript --vanilla experiments/explicit-prescribed-itinerary.R
Rscript --vanilla experiments/explicit-static-patch-acquisition.R
Rscript --vanilla experiments/explicit-known-patch-choice.R
Rscript --vanilla experiments/prescribed-water-source-excursion.R
Rscript --vanilla experiments/body-water-reference.R
Rscript --vanilla experiments/spatial-water-source-benefit.R
Rscript --vanilla experiments/hydration-controlled-water-visits.R
Rscript --vanilla experiments/water-constrained-patch-choice.R
Rscript --vanilla experiments/prescribed-evaporative-loss-regimes.R
Rscript --vanilla experiments/causal-hydration-response.R
Rscript --vanilla experiments/temperature-anticipatory-drinking.R
Rscript --vanilla experiments/spatial-patch-depletion-renewal.R
Rscript --vanilla experiments/spatial-resource-aware-choice.R
Rscript --vanilla experiments/spatial-resource-aware-switch-boundary.R
Rscript --vanilla experiments/spatial-myopic-resource-choice.R
Rscript --vanilla experiments/spatial-experienced-adequacy-choice.R
Rscript --vanilla experiments/explicit-patch-food-quality.R
Rscript --vanilla experiments/spatial-food-quality-choice-boundary.R
```

Run the focused test suite with:

```sh
Rscript --vanilla -e 'testthat::test_local()'
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
- [`HANDOVER.md`](HANDOVER.md): successor entry point and Goal 058 evidence.

The project is licensed under the MIT License.
