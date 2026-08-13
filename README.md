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

It uses `kg DM ha^-1` on the same hourly clock. It is not connected to the
animal's forage-acquisition ceiling.

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
```

Run the focused test suite with:

```sh
Rscript --vanilla -e 'testthat::test_local()'
```

The experiment scripts print compact summaries and create no files. Historical
goal-by-goal clients remain recoverable from Git and are not part of the active
execution path.

## Public Surface

The package exposes six related groups:

- plain state, parameter, and 24-hour schedule constructors;
- one-hour gut and body transitions;
- one-day body-only and coupled gut-body runners;
- a repeated-day reference-cycle and appetite-controlled runner;
- pure food-energy and body-mass conversions; and
- isolated forage accounting, a constant-turnover reference and repeated-day
  runner, and a pure standing-to-accessible biomass transformation.

See [`docs/model-specification.md`](docs/model-specification.md) for equations
and transition order, and [`docs/variable-dictionary.md`](docs/variable-dictionary.md)
for the current variables and units.

## Scientific Boundary

The herbivore and forage systems are still isolated. The plant side contains
prescribed biomass accounting, a linear constant-turnover reference, and a
fixed residual-threshold availability boundary, but no environmental forcing,
depletion, or seasonality. The animal side still uses a non-depleting external
acquisition ceiling. Neither subsystem contains spatial state, protein, water,
thermoregulation, or mass-dependent feedback.

The isolated forage arc is closed. The next stage is the minimum non-spatial
herbivore-forage coupling; controlled environmental forcing remains deferred.
The staged programme is indexed in [`docs/roadmap.md`](docs/roadmap.md).

## Repository Map

- `R/`: reusable model records, transitions, and runners.
- `tests/testthat/`: focused protection of scientific invariants.
- `experiments/`: six current no-write diagnostics and one fixture helper.
- `docs/model-charter.md`: governing scientific and architectural contract.
- `docs/model-specification.md`: equations, transition order, and outputs.
- `docs/variable-dictionary.md`: current quantities and units.
- `docs/decisions/`: retained scientific decision record.
- `docs/arcs/`: stage-level development plans.

The project is licensed under the MIT License.
