# Rebuild Goal 003: One-Pool Gut Energy Buffer

## Status

This packet defines a proposed implementation goal. Formulation creates only
the four files in this goal directory. It does not authorize implementation,
staging, committing, or pushing.

## Principal Question

Can one transparent gut-energy stock convert controlled hourly ingestion into
delayed, smoothed assimilation while conserving energy exactly within the gut,
within the body reserve, and across the combined system?

## Completed Outcome

The package contains a one-pool gut-energy buffer coupled to the accepted
Goal 002 body-energy ledger. The gut stores energy from a controlled prescribed
input, releases a fixed fraction of its opening stock each hour, and supplies
that released energy to the existing body reserve. One integrated daily runner
records 24 fixed one-hour transitions and derives a compact daily summary.

Three deterministic fixtures demonstrate:

1. exact equilibrium when gut stock is initialized analytically;
2. the interpretable initialization transient from an empty gut; and
3. delayed geometric release after a single ingestion pulse.

The implementation stops before food mass or quality, digestive loss, waste,
gut capacity, feeding behavior, activity, body-mass change, plants, or
calibration.

## Scientific Meaning

This goal introduces one mechanism only: storage and delayed release of energy
between prescribed ingestion and body assimilation. It tests whether the
rebuilt architecture can represent that internal stock-flow boundary without
losing the exact accounting and legibility established by Goal 002.

The gut stock is measured in assimilable-energy equivalents. Every kilojoule
released from it enters the body-energy ledger; no digestive inefficiency or
waste pathway is represented. The prescribed input is therefore not gross food
energy, food mass, plant biomass, or empirically calibrated intake.

The fixture values are synthetic arithmetic choices. They do not estimate a
macropod gut residence time, maintenance requirement, gut fill, feeding
schedule, viability threshold, or ecological equilibrium.

## Accepted Approach

Three approaches were considered:

1. A fixed-delay queue. Rejected because it would reintroduce cohorts or
   parcel-like provenance when the scientific question requires only storage
   and delay.
2. Multiple gut compartments with digestive efficiency. Rejected because it
   would add transit structure, food quality, and loss processes
   simultaneously.
3. One first-order, well-mixed gut-energy pool. Accepted because its equilibrium
   and transients are analytically predictable and it adds only one new
   mechanism.

## Model Contract

### Dynamic States

The gut state is one exact named list:

```text
gut_available_energy_kj
```

The existing body state remains:

```text
body_energy_reserve_kj
```

Both are finite, non-negative numeric scalars. Neither stock is clipped. A
transition that proposes a negative body-energy reserve fails before returning
a result. No upper capacity is introduced for either stock.

### Fixed Parameters

The gut parameter record is one exact named list:

```text
gut_release_fraction_h
```

`gut_release_fraction_h` is a finite numeric scalar in `(0, 1]` h^-1. With the
fixed one-hour transition, this bound ensures that release cannot exceed the
opening gut stock.

The existing body parameter remains:

```text
maintenance_expenditure_kj_h
```

No parameter varies within a daily run.

### Prescribed Inputs

The daily ingestion schedule is a base R data frame with exactly:

```text
hour_of_day
prescribed_ingested_available_energy_kj_h
```

It has exactly 24 ordered rows for `hour_of_day = 0:23`. Each row labels the
half-open interval `[hour_of_day, hour_of_day + 1)`. The prescribed rate is
finite and non-negative.

This input is energy available to enter the gut stock. It is not food mass,
gross energy, plant biomass, or already-assimilated energy.

### Hourly Gut Transition

Every transition lasts exactly one hour. Release is calculated from the opening
gut stock before the current hour's ingestion is added:

```text
assimilated_energy_kj_h =
  gut_release_fraction_h * gut_available_energy_start_kj

assimilated_energy_kj =
  assimilated_energy_kj_h * 1 h

prescribed_ingested_available_energy_kj =
  prescribed_ingested_available_energy_kj_h * 1 h

gut_energy_change_kj =
  prescribed_ingested_available_energy_kj - assimilated_energy_kj

gut_available_energy_end_kj =
  gut_available_energy_start_kj + gut_energy_change_kj
```

Newly ingested energy cannot be released during the same transition. It first
appears in the closing gut stock and becomes eligible for release in the next
hour.

### Coupling To The Existing Body Ledger

For the same hour, `assimilated_energy_kj_h` becomes the already-assimilated
input rate consumed by the unchanged `step_body_energy()` function:

```text
body_energy_change_kj =
  assimilated_energy_kj - maintenance_expenditure_kj

body_energy_reserve_end_kj =
  body_energy_reserve_start_kj + body_energy_change_kj
```

The gut receives no feedback from body reserve, maintenance, or energy status
in this goal.

### Accounting Identities

For every hour:

```text
gut_energy_balance_residual_kj =
  (gut_available_energy_end_kj - gut_available_energy_start_kj) -
  (prescribed_ingested_available_energy_kj - assimilated_energy_kj)

body_energy_balance_residual_kj =
  (body_energy_reserve_end_kj - body_energy_reserve_start_kj) -
  (assimilated_energy_kj - maintenance_expenditure_kj)

system_energy_balance_residual_kj =
  (
    gut_available_energy_end_kj + body_energy_reserve_end_kj -
    gut_available_energy_start_kj - body_energy_reserve_start_kj
  ) -
  (
    prescribed_ingested_available_energy_kj -
    maintenance_expenditure_kj
  )
```

Assimilated energy is an internal transfer and therefore cancels from the
whole-system balance.

### Numerical Policy

The hourly gut tolerance is:

```text
100 * .Machine$double.eps * max(
  1,
  abs(gut_available_energy_start_kj),
  abs(gut_available_energy_end_kj),
  abs(prescribed_ingested_available_energy_kj),
  abs(assimilated_energy_kj)
)
```

The unchanged `step_body_energy()` function validates its hourly residual with
the existing Goal 002 tolerance:

```text
100 * .Machine$double.eps * max(
  1,
  abs(body_energy_reserve_start_kj),
  abs(body_energy_reserve_end_kj),
  abs(assimilated_energy_kj),
  abs(maintenance_expenditure_kj)
)
```

The hourly whole-system tolerance is:

```text
100 * .Machine$double.eps * max(
  1,
  abs(gut_available_energy_start_kj),
  abs(gut_available_energy_end_kj),
  abs(body_energy_reserve_start_kj),
  abs(body_energy_reserve_end_kj),
  abs(prescribed_ingested_available_energy_kj),
  abs(assimilated_energy_kj),
  abs(maintenance_expenditure_kj)
)
```

The daily gut tolerance is:

```text
100 * .Machine$double.eps * max(
  1,
  abs(gut_available_energy_initial_kj),
  abs(gut_available_energy_final_kj),
  sum(abs(prescribed_ingested_available_energy_kj)),
  sum(abs(assimilated_energy_kj))
)
```

The daily whole-system tolerance is:

```text
100 * .Machine$double.eps * max(
  1,
  abs(gut_available_energy_initial_kj),
  abs(gut_available_energy_final_kj),
  abs(body_energy_reserve_initial_kj),
  abs(body_energy_reserve_final_kj),
  sum(abs(prescribed_ingested_available_energy_kj)),
  sum(abs(assimilated_energy_kj)),
  sum(abs(maintenance_expenditure_kj))
)
```

The daily body residual and `body_energy_status` reuse
`.body_energy_tolerance()` with initial and final body reserve, the vector of
24 assimilated-energy amounts, and the vector of 24 maintenance amounts.

Assimilated energy is included in the whole-system numerical scale because its
internal cancellation can contribute floating-point error. It remains excluded
from expected whole-system change, which uses only prescribed ingestion and
maintenance.

Tolerance addresses floating-point representation only. It cannot conceal a
negative stock, a non-finite result, or a substantive energy discrepancy.

### Public Functional Interface

The package adds:

```text
new_gut_energy_state(gut_available_energy_kj)
new_gut_energy_parameters(gut_release_fraction_h)
new_ingested_available_energy_schedule(
  hour_of_day,
  prescribed_ingested_available_energy_kj_h
)
step_gut_energy(state, parameters, input_row)
run_gut_body_energy_day(
  initial_gut_state,
  initial_body_state,
  gut_parameters,
  body_parameters,
  schedule
)
```

Records remain plain named lists and schedules remain base R data frames. No
S3, S4, R6, reference class, compatibility layer, or validation framework is
introduced.

`step_gut_energy()` returns:

```text
state
  gut_available_energy_kj
fluxes
  prescribed_ingested_available_energy_kj
  assimilated_energy_kj_h
  assimilated_energy_kj
  gut_energy_change_kj
  gut_energy_balance_residual_kj
```

`run_gut_body_energy_day()` returns one plain list with exact `hourly` and
`daily` data frames. It calls the existing body transition rather than
duplicating its arithmetic.

## Exact Outputs

The integrated hourly ledger has 24 rows and these columns:

```text
hour_of_day
time_start_h
time_end_h
gut_available_energy_start_kj
prescribed_ingested_available_energy_kj_h
gut_release_fraction_h
assimilated_energy_kj_h
prescribed_ingested_available_energy_kj
assimilated_energy_kj
gut_energy_change_kj
gut_available_energy_end_kj
gut_energy_balance_residual_kj
body_energy_reserve_start_kj
maintenance_expenditure_kj_h
maintenance_expenditure_kj
body_energy_change_kj
body_energy_reserve_end_kj
body_energy_balance_residual_kj
total_system_energy_start_kj
total_system_energy_end_kj
system_energy_balance_residual_kj
```

The daily summary has one row and these columns:

```text
gut_available_energy_initial_kj
total_prescribed_ingested_available_energy_kj
total_assimilated_energy_kj
expected_gut_energy_change_kj
observed_gut_energy_change_kj
gut_available_energy_final_kj
gut_energy_balance_residual_kj
body_energy_reserve_initial_kj
total_maintenance_expenditure_kj
expected_body_energy_change_kj
observed_body_energy_change_kj
body_energy_reserve_final_kj
body_energy_balance_residual_kj
total_system_energy_initial_kj
expected_total_system_energy_change_kj
observed_total_system_energy_change_kj
total_system_energy_final_kj
system_energy_balance_residual_kj
body_energy_status
```

Daily values are derived from the hourly ledger. `body_energy_status` retains
the Goal 002 `neutral`, `deficit`, or `surplus` interpretation for body reserve
change only.

The expected daily changes are:

```text
expected_gut_energy_change_kj =
  total_prescribed_ingested_available_energy_kj -
  total_assimilated_energy_kj

expected_body_energy_change_kj =
  total_assimilated_energy_kj -
  total_maintenance_expenditure_kj

expected_total_system_energy_change_kj =
  total_prescribed_ingested_available_energy_kj -
  total_maintenance_expenditure_kj
```

Each observed change is its closing stock minus its opening stock. Each daily
residual is the corresponding observed change minus expected change.

No package function writes a CSV, RDS, figure, cache, or evidence bundle.

## Analytical Fixtures

All fixtures use `gut_release_fraction_h = 0.25` and begin with
`body_energy_reserve_kj = 5000`.

### Equilibrium Reference

```text
gut_available_energy_kj = 400
prescribed_ingested_available_energy_kj_h = 100 for every hour
maintenance_expenditure_kj_h = 100
```

For all 24 hours, gut stock remains 400 kJ, assimilation is 100 kJ h^-1, and
body reserve remains 5000 kJ. All residuals are zero within tolerance.

### Empty-Gut Initialization

```text
gut_available_energy_kj = 0
prescribed_ingested_available_energy_kj_h = 100 for every hour
maintenance_expenditure_kj_h = 100
```

For elapsed hour `t`:

```text
gut_available_energy_kj = 400 * (1 - 0.75^t)
```

After 24 transitions, the body-reserve loss equals the energy accumulated in
the gut:

```text
gut_available_energy_final_kj = 400 * (1 - 0.75^24)
body_energy_reserve_final_kj =
  5000 - gut_available_energy_final_kj
total_system_energy_final_kj = 5000
```

This is an initialization transient, not evidence of physiological stress.

### Single-Pulse Response

```text
gut_available_energy_kj = 0
prescribed input = 400 kJ h^-1 in hour 0 and 0 thereafter
maintenance_expenditure_kj_h = 0
```

Hour 0 releases no energy and closes with 400 kJ in the gut. Assimilation in
hours 1, 2, and 3 is exactly 100, 75, and 56.25 kJ. Gut content then decays
geometrically while combined gut-plus-body energy remains 5400 kJ.

## Validation And Tests

Tests must demonstrate:

- exact plain-record and schedule names, types, dimensions, and bounds;
- rejection of zero, negative, greater-than-one, non-finite, classed, or
  otherwise malformed gut release fractions;
- exact opening-stock release order and one-hour minimum delay;
- exact equilibrium, empty-start recurrence, and pulse-response values;
- hourly continuity for gut and body stocks;
- no mutation of supplied state, parameters, or schedule;
- non-negative finite closing stocks without clipping;
- gut, body, and whole-system conservation at every hour and over the day;
- exact hourly and daily output schemas and row counts;
- propagation of existing body-reserve boundary errors without a partial
  returned result;
- unchanged Goal 002 public interfaces, fixtures, and tests;
- synchronized `renv`, clean external build, installation, experiment, and
  `R CMD check --no-manual`; and
- no persistent generated product in the repository.

## Documentation And Review Artifacts

Execution updates the package description, package documentation, README, model
charter, model specification, variable dictionary, and roadmap. One decision
record explains the opening-stock release convention and why more detailed gut
structure remains deferred.

The thin experiment asserts all three fixtures in memory and prints compact
daily and selected-hour summaries to stdout.

After core validation, `experiments/rebuild-003-review-pack.R` generates the
required discussion pack at:

```text
/Users/bwbrook/work/herbivoreTTR-review/goal-003/
```

The script uses only base R plotting and public installed-package functions. It
is run from the repository root and accepts the exact destination as its sole
command-line argument. The destination itself must not be a symlink. If it is
absent, the script creates it. If it exists, every entry must be one of the
eight declared regular files below; any unknown path, directory, or symlink
stops generation. The script may then replace only those exact files.

The recursive file set after generation is exactly:

```text
artifact-manifest.sha256
figure-1-equilibrium-and-initialization.png
figure-2-pulse-response.png
generation-metadata.txt
source-manifest.sha256
table-1-daily-summary.csv
table-2-hourly-checkpoints.csv
table-3-full-hourly-ledgers.csv
```

Figure 1 contains gut-stock and body-reserve panels for the equilibrium and
empty-start fixtures. Figure 2 contains prescribed-input, assimilation,
gut-stock, and body-reserve panels for the pulse fixture. Every axis states its
unit, and both figures identify the fixtures as synthetic.

`table-1-daily-summary.csv` contains `scenario_id` followed by the exact daily
schema. `table-2-hourly-checkpoints.csv` contains exactly these columns:

```text
scenario_id
hour_of_day
time_start_h
time_end_h
prescribed_ingested_available_energy_kj_h
assimilated_energy_kj_h
gut_available_energy_start_kj
gut_available_energy_end_kj
body_energy_reserve_start_kj
body_energy_reserve_end_kj
system_energy_balance_residual_kj
```

It contains hours `0, 1, 2, 3, 6, 12, 18, 23` for each of the three fixtures,
giving 24 rows. `table-3-full-hourly-ledgers.csv` contains `scenario_id`
followed by the exact hourly schema, giving 72 rows.

`generation-metadata.txt` records the generation time and time zone; repository
path, branch, `HEAD`, and complete short status; all fixture constants; and the
synthetic interpretation boundary. `source-manifest.sha256` records SHA-256
values for these repository-relative paths, in this order:

```text
DESCRIPTION
NAMESPACE
R/*.R in bytewise path order
experiments/rebuild-003-review-pack.R
```

Before build and installation, the runbook creates this exact manifest from the
source repository. The same manifest is recalculated immediately before and
after review-pack generation. All three copies and the generated
`source-manifest.sha256` must be byte-identical. Its checksums are verified from
the repository root, not the review directory.

`artifact-manifest.sha256` records SHA-256 values for the other seven declared
files. The source-repository status fingerprint must also be byte-identical
before and after build, validation, and generation.

These artifacts are mandatory review aids but are never package outputs or
commit inputs.

## Planned File Surface

The completed implementation changes exactly:

```text
DESCRIPTION
NAMESPACE
R/gut-energy-records.R
R/gut-energy-transition.R
R/gut-body-energy-run.R
R/herbivoreTTR-package.R
README.md
docs/decisions/0003-opening-stock-gut-release.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-003-one-pool-gut-buffer.R
experiments/rebuild-003-review-pack.R
man/herbivoreTTR-package.Rd
man/new_gut_energy_state.Rd
man/new_gut_energy_parameters.Rd
man/new_ingested_available_energy_schedule.Rd
man/step_gut_energy.Rd
man/run_gut_body_energy_day.Rd
tests/testthat/test-gut-energy-records.R
tests/testthat/test-gut-energy-transition.R
tests/testthat/test-gut-body-energy-scenarios.R
docs/goals/rebuild-003-one-pool-gut-energy-buffer/Goal.md
docs/goals/rebuild-003-one-pool-gut-energy-buffer/Plan.md
docs/goals/rebuild-003-one-pool-gut-energy-buffer/Runbook.md
docs/goals/rebuild-003-one-pool-gut-energy-buffer/Log.md
```

Every path is required. Roxygen documentation must use the five declared
manual-page paths rather than grouping or renaming them. Any missing or extra
path requires a reviewed scope amendment and renewed authorization.

`renv.lock`, Goal 002 files, existing body-energy source and tests, legacy
material, data, and repository output directories are outside scope.

## Exclusions

This goal excludes:

- food dry mass, gross energy, digestibility, assimilation efficiency, waste,
  faeces, gut capacity, compartment age, and multiple gut pools;
- variable release, feeding decisions, hunger, satiety, behavior, and feedback
  from body state to ingestion or gut dynamics;
- activity expenditure, movement, dynamic body mass, protein, water,
  thermoregulation, mortality, reproduction, and condition indices;
- plants, weather, space, seasons, individuals, populations, and coupling to
  ecological subsystems;
- empirical calibration, literature synthesis, parameter fitting, uncertainty
  analysis, legacy comparison, and release machinery; and
- committed generated figures, tables, CSV files, caches, or evidence bundles.

## Authority And Stop Rule

Execution requires Barry's explicit authorization after packet review.
Formulation authority does not include implementation, staging, commit, or
push.

At authorization, the SHA-256 identities of `Goal.md`, `Plan.md`, and
`Runbook.md` become frozen. `Log.md` remains the only mutable packet file during
execution.

Stop before implementation on a changed upstream, an unexpected dirty path, or
a control-document hash mismatch. After implementation begins, stop on a
scientific ambiguity that changes the accepted equations, a new dependency, an
undeclared file, a failed accounting identity, a persistent repository output,
or scope expansion into an excluded process.

Apply one focused self-review and repair pass after the core validation. Further
iteration is justified only by a material scientific, accounting, data-
integrity, or scope defect. Stop after the reviewed Goal 003 closeout and return
the diagnostic evidence to Barry before proposing a more realistic gut or food
layer.
