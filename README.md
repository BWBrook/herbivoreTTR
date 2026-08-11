# herbivoreTTR

`herbivoreTTR` is a small functional R package for transparent hourly models
of herbivore energetics. It is a clean scientific rebuild: ecological logic,
explicit units, and inspectable energy accounting take precedence over the
historical implementation.

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
```

Run the focused test suite with:

```sh
Rscript --vanilla -e 'testthat::test_local()'
```

The experiment scripts print compact summaries and create no files. Historical
goal-by-goal clients remain recoverable from Git and are not part of the active
execution path.

## Public Surface

The package exposes five related groups:

- plain state, parameter, and 24-hour schedule constructors;
- one-hour gut and body transitions;
- one-day body-only and coupled gut-body runners;
- a repeated-day reference-cycle and appetite-controlled runner; and
- pure food-energy and body-mass conversions.

See [`docs/model-specification.md`](docs/model-specification.md) for equations
and transition order, and [`docs/variable-dictionary.md`](docs/variable-dictionary.md)
for the current variables and units.

## Scientific Boundary

The current core represents energy only. It includes a non-depleting external
forage-acquisition ceiling but no plant biomass, renewal, spatial state,
protein, water, thermoregulation, or mass-dependent feedback. Patch labels,
movement costs, variable food quality, and feeding-duration response remain
diagnostic treatments rather than production state.

The next approved development arc is an isolated plant-forage stock-flow
model. The staged programme is indexed in [`docs/roadmap.md`](docs/roadmap.md).

## Repository Map

- `R/`: reusable model records, transitions, and runners.
- `tests/testthat/`: focused protection of scientific invariants.
- `experiments/`: three current no-write diagnostics and one fixture helper.
- `docs/model-charter.md`: governing scientific and architectural contract.
- `docs/model-specification.md`: equations, transition order, and outputs.
- `docs/variable-dictionary.md`: current quantities and units.
- `docs/decisions/`: retained scientific decision record.
- `docs/arcs/`: stage-level development plans.

The project is licensed under the MIT License.
