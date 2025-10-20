# Herbivore TTR

## Description / Purpose

Herbivore TTR is an R package implementing a quantitative plant–herbivore simulation. It
couples a Thornley Transport Resistance (TTR) plant growth model with an individual-based
herbivore foraging model in a spatially explicit, toroidal environment. The package supports
minute-resolution herbivore behaviour (movement and intake), daily plant updates, and daily
energy and water balance tallies. It is designed to facilitate testing, calibration, and
extension within the R ecosystem.

## Table of Contents

- [Herbivore TTR](#herbivore-ttr)
  - [Description / Purpose](#description--purpose)
  - [Table of Contents](#table-of-contents)
  - [Installation Instructions](#installation-instructions)
  - [Usage Examples](#usage-examples)
  - [Features and Architecture Overview](#features-and-architecture-overview)
  - [File Structure](#file-structure)
  - [Roadmap](#roadmap)
  - [Contributing Guidelines](#contributing-guidelines)
  - [License](#license)
  - [References \& Further Documentation](#references--further-documentation)

## Installation Instructions

- From a fresh R session in the project root:
  - Option A: Install the package from the local source
    - `devtools::install()` or `R CMD INSTALL .`
  - Option B: Develop in-place with renv (recommended for contributors)
    - See Developer Quickstart in `docs/README-dev.md` for `renv` bootstrap and testing
      instructions.
- Optional: Build vignettes
  - `devtools::build_vignettes()`

Minimum suggested environment: R >= 4.5.

## Usage Examples

Basic quick start (initialise a small simulation and run one day):

```r
# Set up default conditions, plants, and a herbivore
sim <- herbivoreTTR::init_simulation(
  temp_mode = "flat",
  veg_types = c(0, 1, 2),
  herbivore_mass = 5e5
)

# Run one day (2 hours shown here to keep output short)
res <- herbivoreTTR::run_daily_herbivore_simulation(
  sim$herbivore,
  sim$plants,
  sim$conditions,
  day_of_simulation = 1,
  minute_limit = 120
)

# Inspect results
names(res)
res$daily_summary
```

Derive herbivore traits from mass (allometric relations):

```r
h <- herbivoreTTR::init_herbivore(mass = 5e5)
h <- herbivoreTTR::calc_foraging_traits(h)
list(
  bite_size = h$bite_size,
  gut_capacity = h$gut_capacity,
  handling_time = h$handling_time,
  fv_max = h$fv_max
)
```

Find nearby plants and compute tastiness:

```r
near <- herbivoreTTR::get_plants_within_range(h, sim$plants)
scores <- herbivoreTTR::calc_plant_tastiness(near, h, desired_dp_dc_ratio = 0.2)
head(data.frame(
  plant_id = near$plant_id,
  distance = near$distance,
  score = scores
))
```

[TODO: Add usage example showing a short multi-day loop and simple summaries/plots]

## Features and Architecture Overview

- Plant growth (TTR):
  - Single-day TTR update per plant row driven by daily conditions (temperature, water, N).
  - Uptake, transport (resistances), and growth allocation to leaf/stem/root (defence currently
    disabled to mirror reference).
- Herbivore behaviour:
  - Minute-resolution step: select target via tastiness, move (toroidal), eat when within radius,
    update gut and balances.
  - Allometric traits: bite size, handling time, gut capacity, foraging velocity.
- Budgets:
  - Daily energy intake (protein and non-protein) and costs (maintenance, locomotion).
  - Daily water balance with metabolic water; drinking triggers travel distance.
- Simulation controls:
  - Spin-up period (plant-only) before herbivory activates.
  - Global `CONSTANTS` list for parameters and scenario switches.
- Testing and CI:
  - Unit tests in `tests/testthat`.
  - GitHub Actions workflow runs R CMD check on push/PR.

## File Structure

```text
herbivoreTTR/
├── DESCRIPTION                # Package metadata
├── NAMESPACE                  # Exports (roxygen-generated)
├── LICENSE                    # License text (see 'License' below)
├── CITATION.cff               # Citation metadata
├── Makefile                   # Convenience tasks (setup/test/lint/etc.)
├── README.md                  # This file
├── R/                         # Package R code
│   ├── constants.R            # Global CONSTANTS list
│   ├── options.R              # Reproducibility helpers (init_project_options)
│   ├── packages.R             # Interactive helpers (renv/pak/bootstrap)
│   ├── utils.R                # select_randomly(), calc_toroidal_distance(), helpers
│   ├── herbivore_utils.R      # Allometric trait calculators
│   ├── init_conditions.R      # init_conditions()
│   ├── init_plants.R          # init_plants()
│   ├── init_herbivore.R       # init_herbivore()
│   ├── init_simulation.R      # init_simulation()
│   ├── run_daily_herbivore_simulation.R
│   ├── herbivore_step.R       # One behavioural step (move/eat)
│   ├── herbivore_move.R       # Movement with toroidal wrap
│   ├── herbivore_eat.R        # Internal: intake + plant update
│   ├── calc_foraging_traits.R # Populate herbivore traits
│   ├── update_gut_content.R   # Gut content tally
│   ├── hourly_digestion_step.R
│   ├── check_daily_water_balance.R
│   ├── calc_daily_energy_balance.R
│   ├── get_plants_within_range.R
│   ├── calc_plant_tastiness.R
│   ├── select_new_plant.R     # Internal selection helper
│   ├── ttr_daily.R            # transport_resistance() orchestrator (internal)
│   ├── monod.R, trap1.R, trap2.R
│   ├── herbivoreTTR-package.R # Package doc and imports
│   └── globals.R              # NSE globals for R CMD check
├── man/                       # Auto-generated Rd docs (roxygen)
├── vignettes/
│   └── herbivoreTTR-intro.Rmd # Getting started vignette
├── tests/
│   └── testthat/              # Unit tests
│       ├── helper-ttr.R
│       ├── test_sanity.R
│       ├── test_module*/*.R   # Module smoke/integration tests
│       └── ... (TTR and IO writers tests)
├── docs/
│   ├── README-dev.md          # Developer Quickstart (env, tests, targets)
│   ├── model_logic.md         # Detailed pseudo-code and logical flow
│   ├── closure_tests.md       # Closure tests plan and verification protocol
│   ├── idea_for_new_input.txt # Proposed input spec (scenarios, grids, GCM)
│   └── progress.txt           # Status matrix + future extensions
├── inst/
│   ├── scripts/
│   │   └── main.R             # Example script entrypoint
│   └── containers/
│       ├── Dockerfile
│       └── apptainer.def
├── config/
│   └── config.yaml            # Project/Pipeline config
├── data/                      # Data hierarchy (raw/external/interim/processed)
├── profiles/
│   └── targets/
│       ├── ci.R
│       └── local.R
├── _targets.R                 # Targets pipeline
├── .github/
│   └── workflows/
│       └── R-CMD-check.yaml   # CI workflow
├── renv/, renv.lock           # Reproducible env (optional)
└── .Rbuildignore, .gitignore, .lintr, .pre-commit-config.yaml
```

## Roadmap

Near-term

- Expand vignette coverage (multi-day runs, basic plotting).
  [TODO: Add multi-day example vignette]
- Complete closure tests (numeric parity and determinism) per `docs/closure_tests.md`.
- Finalise a single "simulate_day()/simulate()" high-level driver wrapping daily logic
  consistently.

Medium-term

- Enrich environmental drivers (seasonal/stochastic water and N, additional climate
  variables).
- Herbivore population dynamics (multiple agents; optional growth/condition).
- Defence compartment dynamics and potential feedbacks to soils (excretion/recycling).
- Performance: vectorised updates, profiling and hotspots refactoring.

Long-term / ideas

- Enhanced phenology and reproduction modules for plants.
- Calibration and sensitivity workflows; documented parameter sets.

## Contributing Guidelines

- Setup
  - See `docs/README-dev.md` for the Developer Quickstart: `renv` bootstrap, running tests, and
    the minimal `{targets}` pipeline.
  - Use `devtools::document()` to regenerate docs after changes.
- Code style and checks
  - Linting via `.lintr`; optional pre-commit hooks in `.pre-commit-config.yaml`.
  - Keep functions focused with clear roxygen2 headers and examples.
- Tests
  - Add or update `tests/testthat/` for new or modified functionality.
  - Aim for fast smoke tests for core interfaces and logic.
- Issues and PRs
  - Please describe motivation, scope, and any interface changes.
  - Reference relevant sections in `docs/` when proposing design changes.

[TODO: Add a formal CODE_OF_CONDUCT.md and CONTRIBUTING.md if desired]

## License

This repository includes an MIT `LICENSE` file.


## References & Further Documentation

- Developer Quickstart: [docs/README-dev.md](docs/README-dev.md)
  - Environment bootstrap with `renv`, fast tests, minimal `{targets}` run, and parity-check
    notes.
- Model Logic (Pseudo-code): [docs/model_logic.md](docs/model_logic.md)
  - Detailed overview of initialization, daily plant growth (TTR), herbivore
    selection/movement/intake, budgets, and outputs; includes step-by-step flow.
- Closure Tests Plan: [docs/closure_tests.md](docs/closure_tests.md)
  - Structured unit/integration checks, determinism tests, and verification protocol to ensure
    parity with the C++ reference.
- Proposed Inputs: [docs/idea_for_new_input.txt](docs/idea_for_new_input.txt)
  - Sketch of a richer input specification for single-point and grid/block runs, including
    GCM-driven scenarios and output configuration.
- Progress and Future Work: [docs/progress.txt](docs/progress.txt)
  - Status table mapping pseudo-code steps to C++ counterparts and current R functions, with
    candidate future extensions.

Vignettes

- Getting Started: [vignettes/herbivoreTTR-intro.Rmd](vignettes/herbivoreTTR-intro.Rmd)
  (basic setup and one-day run).
- Multi-day Simulation: [vignettes/herbivoreTTR-multiday.Rmd](vignettes/herbivoreTTR-multiday.Rmd)
  (7-day run with simple plots).
