# herbivoreTTR

`herbivoreTTR` is a small functional R package for transparent hourly models
of herbivore energetics and forage biomass. It is a clean scientific rebuild:
ecological logic, explicit units, and inspectable stock-flow accounting take
precedence over the historical implementation.

## Current Model

The completed herbivore core follows one 24-hour clock:

```text
feeding opportunity and appetite reference
  -> body- and gut-energy feedback
  -> bounded appetite target
  -> external forage-acquisition ceiling
  -> realized dry-matter intake
  -> metabolizable-energy input
  -> one-pool gut release
  -> body reserve minus maintenance and routine activity
  -> hourly ledger and daily summary
```

State is carried exactly between hours and days. The model uses plain lists and
data frames rather than an object system. Transition functions are pure, and
generated diagnostics do not write into the repository.

The isolated forage path currently provides accounting rather than plant
biology:

```text
opening standing forage biomass
  + prescribed growth
  - prescribed non-herbivore background loss
  -> closing standing forage biomass
```

It uses `kg DM ha^-1` on the same hourly clock and remains available as an
isolated reference path. The coupled path below composes it with animal intake.

The first process reference adds constant production and proportional
background loss:

```text
B[next] = (1 - tau) * B[current] + tau * B[equilibrium]
```

This linear turnover null has an exact positive equilibrium and monotonic
recovery from either side. It is not an empirical growth model.

Standing biomass maps to an animal-facing quantity through one fixed residual
threshold:

```text
accessible forage biomass = max(0, standing biomass - residual threshold)
```

This is a pure biomass-density transformation. It neither removes forage nor
defines how quickly an animal can acquire it.

The minimum non-spatial coupling then connects the two accepted subsystems:

```text
autonomous forage turnover
  -> accessible forage per represented animal
  -> appetite, rate, and stock ceilings
  -> realized per-animal intake
  -> gut input and density-scaled forage removal
  -> carried forage, gut, and body states
```

One representative physiology is scaled by a fixed animal density per hectare.
This is an aggregate homogeneous load, not an explicit population model.

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

These are deliberately synthetic reference values, not an empirical kangaroo
parameterization.

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
```

Run the focused test suite with:

```sh
Rscript --vanilla -e 'testthat::test_local()'
```

The experiment scripts print compact summaries and create no files. Historical
goal-by-goal clients remain recoverable from Git and are not part of the active
execution path.

## Public Surface

The package exposes seven related groups:

- plain state, parameter, and 24-hour schedule constructors;
- one-hour gut and body transitions;
- one-day body-only and coupled gut-body runners;
- a repeated-day reference-cycle and appetite-controlled runner;
- pure food-energy and body-mass conversions;
- isolated forage accounting, a constant-turnover reference and repeated-day
  runner, and a pure standing-to-accessible biomass transformation; and
- a density-scaled herbivory step and repeated-day non-spatial coupled runner.

See [`docs/model-specification.md`](docs/model-specification.md) for equations
and transition order, and [`docs/variable-dictionary.md`](docs/variable-dictionary.md)
for the current variables and units.

## Scientific Boundary

The herbivore and forage systems now have one minimum homogeneous coupling.
The plant side contains prescribed biomass accounting, a linear turnover
reference, and a fixed residual-threshold availability boundary. Realized
per-animal intake is scaled by a fixed density and removed from forage, while
accessible biomass can cap intake. A diagnostic animal-load pulse demonstrates
depletion, stock-limited intake, animal-energy loss, and recovery after release
without adding population state. The coupled system still has no environmental
forcing, seasonality, spatial state, explicit multiple animals, protein, water,
thermoregulation, or mass-dependent feedback.

The non-spatial arc is closed. The next stage introduces explicit fixed patches,
animal location, and known-route movement while keeping choice and dynamic
spatial vegetation deferred. The staged programme is indexed in
[`docs/roadmap.md`](docs/roadmap.md).

## Repository Map

- `R/`: reusable model records, transitions, and runners.
- `tests/testthat/`: focused protection of scientific invariants.
- `experiments/`: eight current no-write diagnostics and one fixture helper.
- `docs/model-charter.md`: governing scientific and architectural contract.
- `docs/model-specification.md`: equations, transition order, and outputs.
- `docs/variable-dictionary.md`: current quantities and units.
- `docs/decisions/`: retained scientific decision record.
- `docs/arcs/`: stage-level development plans.

The project is licensed under the MIT License.
