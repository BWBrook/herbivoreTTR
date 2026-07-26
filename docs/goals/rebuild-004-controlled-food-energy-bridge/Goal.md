# Rebuild Goal 004: Controlled Food-Energy Bridge

## Status

This packet defines a proposed implementation goal. Formulation creates only
the four files in this goal directory. It does not authorize implementation,
staging, committing, or pushing.

## Principal Question

Can a prescribed hourly dry-matter intake schedule and one fixed
dry-matter-basis metabolizable-energy density generate the existing gut
available-energy input transparently, without changing the accepted gut-body
model or implying unimplemented digestive physiology?

## Completed Outcome

The package contains one pure upstream food-energy conversion boundary.
Prescribed dry-matter intake in kg DM h^-1 is multiplied by one fixed
metabolizable-energy density in kJ kg^-1 DM. The result is the exact existing
24-row ingested available-energy schedule accepted by
`run_gut_body_energy_day()`.

No new dynamic state or coupled runner is added. The caller retains the food
parameter, dry-matter schedule, derived gut-energy schedule, and coupled result
as separate inspectable objects.

Synthetic constant and pulse fixtures reproduce the accepted Goal 003
equilibrium and pulse inputs exactly. A factorization fixture demonstrates that
intake and density are structurally non-identifiable from downstream energy
trajectories when only their product enters the model.

The implementation stops before variable food quality, digestive losses, gut
capacity, feeding decisions, plant availability, or empirical calibration.

## Scientific Meaning

The new density is already metabolizable-energy density on a dry-matter basis.
It collapses every unmodelled step between dry matter and model-available
energy into one prescribed food property. It does not separately represent
gross energy, digestibility, assimilation efficiency, faecal loss, urinary
loss, gaseous loss, heat increment, or net energy.

Within this deliberately simplified layer, metabolizable energy is treated as
the accounting equivalent that enters the existing
`gut_available_energy_kj` pool. The gut release fraction continues to provide
storage and delay only. Goal 003 timing, gut accounting, body accounting, and
whole-system accounting remain unchanged.

Dry matter is prescribed ingestion, not food offered, vegetation availability,
wet mass, or realized foraging behavior.

## Accepted Approach

Three approaches were considered:

1. Extend the Goal 003 gut schedule with food-mass and density columns.
   Rejected because it would break an accepted exact public schema and mix
   prescribed mass with derived energy.
2. Add an integrated food-gut-body runner. Rejected because it would only
   convert and forward existing objects, hide the intermediate schedule, and
   add a redundant public entry point.
3. Add strict food records and one pure schedule converter. Accepted because it
   adds one mechanism, preserves Goal 003, and keeps every input and derived
   object explicit.

A dry-matter gut stock was also rejected. With one fixed energy density it
would be algebraically redundant with the existing energy stock and would
introduce unnecessary initial-mass and mass-flow semantics.

## Model Contract

### Dynamic State

Goal 004 adds no dynamic state. The existing states remain:

```text
gut_available_energy_kj
body_energy_reserve_kj
```

### Fixed Food Parameter

The food parameter record is one exact plain named list:

```text
metabolizable_energy_density_kj_kg_dm
```

The value is a bare, finite, strictly positive numeric scalar and is stored as
a double. Its unit is kJ per kg dry matter. Zero is rejected because the record
describes a food-energy density; zero intake already provides the exact
no-energy control.

The density is constant within a 24-hour run. Separate runs may prescribe
different densities, but Goal 004 does not support multiple foods or
time-varying density within one schedule.

### Prescribed Dry-Matter Input

The intake schedule is a base R data frame with exactly:

```text
hour_of_day
prescribed_dry_matter_intake_kg_dm_h
```

It has exactly 24 ordered rows for `hour_of_day = 0:23`. Each row labels the
half-open interval `[hour_of_day, hour_of_day + 1)`. Intake rates are bare,
finite, non-negative numeric values stored as doubles.

No intake limit, gut-capacity check, feeding decision, or body-state feedback
is applied.

### Conversion

For every hour:

```text
prescribed_ingested_available_energy_kj_h =
  prescribed_dry_matter_intake_kg_dm_h *
  metabolizable_energy_density_kj_kg_dm
```

The dimensional identity is:

```text
kg DM h^-1 * kJ kg^-1 DM = kJ h^-1
```

The converter performs elementwise multiplication, rejects any non-finite
product, and calls the existing
`new_ingested_available_energy_schedule()` constructor to create its return
value. It does not calculate a one-hour amount, advance a state, call the
gut-body runner, or write an artifact.

### Structural Non-Identifiability

Downstream dynamics depend only on:

```text
prescribed_dry_matter_intake_kg_dm_h *
metabolizable_energy_density_kj_kg_dm
```

Multiplying intake by a positive constant and dividing density by the same
constant produces the same derived energy schedule. Therefore neither intake
nor density can be inferred separately from the energy trajectories generated
by this model layer. They are prescribed inputs, not estimated parameters.

This equivalence is an accounting property, not a claim that different foods
or feeding regimes are biologically interchangeable.

### Numerical And Presentation Policy

All accepted food quantities and returned energy rates use double precision.
The `hour_of_day` key remains integer `0:23` for compatibility with the Goal
003 schedule. No value is rounded before or during conversion or downstream
dynamics. The converter requires finite products and introduces no numerical
tolerance because it checks a direct deterministic mapping rather than an
approximate conservation identity.

Human-facing summaries normally present energy stocks and amounts as whole
kilojoules. Rates retain decimals only when those decimals convey meaningful
temporal structure. Dry-matter quantities and energy density use enough
significant digits to identify the prescribed fixture. Machine-readable model
objects retain full precision.

### Public Functional Interface

The package adds:

```text
new_food_energy_parameters(
  metabolizable_energy_density_kj_kg_dm
)

new_dry_matter_intake_schedule(
  hour_of_day,
  prescribed_dry_matter_intake_kg_dm_h
)

derive_ingested_available_energy_schedule(
  parameters,
  schedule
)
```

`new_food_energy_parameters()` returns the exact parameter list.

`new_dry_matter_intake_schedule()` returns the exact 24-row prescribed
dry-matter schedule.

`derive_ingested_available_energy_schedule()` returns the exact existing base
R data-frame schema:

```text
hour_of_day
prescribed_ingested_available_energy_kj_h
```

No S3, S4, R6, reference class, compatibility layer, or generalized validation
framework is introduced.

## Analytical Fixtures

The zero-intake, constant, and pulse fixtures use:

```text
metabolizable_energy_density_kj_kg_dm = 10000
```

The factorization-equivalence fixture deliberately also uses a density of
`5000` to demonstrate structural non-identifiability.

These values are synthetic arithmetic choices, not food measurements or
macropod intake estimates.

### Zero Intake

```text
prescribed_dry_matter_intake_kg_dm_h = 0 for every hour
```

The derived gut-energy schedule is exactly zero for all 24 hours.

### Constant Equilibrium Bridge

```text
prescribed_dry_matter_intake_kg_dm_h = 0.010 for every hour
```

Every derived input is exactly 100 kJ h^-1. Daily prescribed intake is
0.24 kg DM and daily derived available energy is 2400 kJ. With the accepted
Goal 003 equilibrium initial states and parameters, the downstream result is
identical to the Goal 003 equilibrium fixture.

### Pulse Bridge

```text
prescribed_dry_matter_intake_kg_dm_h = 0.040 in hour 0
prescribed_dry_matter_intake_kg_dm_h = 0 in hours 1:23
```

The derived schedule is 400 kJ h^-1 in hour 0 and zero thereafter. Passing it
to the unchanged Goal 003 runner reproduces the delayed assimilation sequence:

```text
0, 100, 75, 56.25 kJ h^-1
```

for hours 0, 1, 2, and 3.

### Factorization Equivalence

The following constant prescriptions both derive 100 kJ h^-1:

```text
0.010 kg DM h^-1 * 10000 kJ kg^-1 DM
0.020 kg DM h^-1 *  5000 kJ kg^-1 DM
```

Their derived schedules and downstream Goal 003 results are identical. Their
prescribed food inputs remain scientifically distinct.

## Validation And Tests

Tests must demonstrate:

- exact public signatures, plain record names, data-frame schemas, dimensions,
  ordered hours, and double storage;
- rejection of zero, negative, non-finite, classed, attributed, or otherwise
  malformed density values;
- rejection of negative, non-finite, wrong-length, unordered, classed,
  attributed, or otherwise malformed intake schedules;
- exact elementwise unit conversion without recycling;
- exact zero, constant, pulse, and factorization fixtures;
- a clear error for non-finite converted rates, including overflow;
- no mutation of supplied parameters or schedule;
- exact equality between converted schedules and manually constructed Goal 003
  schedules;
- identical downstream Goal 003 results from equivalent schedules;
- unchanged Goal 002 and Goal 003 public interfaces, equations, schemas,
  fixtures, source, and tests;
- synchronized `renv`, clean external build, installation, experiment, and
  `R CMD check --no-manual`; and
- no persistent generated product in the repository.

## Documentation And Review Surface

Execution updates the package description, package documentation, README, model
charter, model specification, variable dictionary, and roadmap. One decision
record explains the dry-matter basis, already-metabolizable density, pure
conversion boundary, and structural non-identifiability.

The thin experiment asserts every fixture in memory and prints:

- one compact conversion summary with prescribed dry matter and derived energy;
  and
- one compact downstream equivalence summary.

Energy stocks and amounts in those summaries are displayed as whole
kilojoules. Rates retain meaningful decimals. The experiment writes nothing.

No external review pack or figure is required. A plot of this deterministic
multiplication would add presentation cost without additional scientific
information. The review surface is the exact function output, focused tests,
experiment stdout, documentation, complete diff, and validation log.

## Planned File Surface

The completed implementation changes exactly:

```text
DESCRIPTION
NAMESPACE
R/food-energy-records.R
R/food-energy-conversion.R
R/herbivoreTTR-package.R
README.md
docs/decisions/0004-dry-matter-metabolizable-energy-bridge.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
experiments/rebuild-004-controlled-food-energy-bridge.R
man/herbivoreTTR-package.Rd
man/new_food_energy_parameters.Rd
man/new_dry_matter_intake_schedule.Rd
man/derive_ingested_available_energy_schedule.Rd
tests/testthat/test-food-energy-records.R
tests/testthat/test-food-energy-conversion.R
docs/goals/rebuild-004-controlled-food-energy-bridge/Goal.md
docs/goals/rebuild-004-controlled-food-energy-bridge/Plan.md
docs/goals/rebuild-004-controlled-food-energy-bridge/Runbook.md
docs/goals/rebuild-004-controlled-food-energy-bridge/Log.md
```

Every path is required and no extra path is accepted. `renv.lock`, Goal 001-003
packet files, existing body and gut source, existing body and gut tests,
legacy material, data, and generated outputs are outside scope.

## Exclusions

Goal 004 excludes:

- wet or as-fed mass, water content, gross energy, digestible energy,
  assimilation efficiency, explicit metabolic losses, heat increment, net
  energy, waste, urine, gas, and faeces;
- time-varying density, multiple food types, food choice, preference, diet
  mixing, selectivity, and nutrient composition;
- gut dry-matter state, gut capacity, passage changes, intake limits, hunger,
  satiety, behavior, and feedback from body or gut state;
- activity, dynamic body mass, protein, water balance, thermoregulation,
  mortality, reproduction, and condition indices;
- plants, forage availability, weather, space, seasons, individuals,
  populations, and ecological subsystem coupling;
- empirical calibration, parameter estimation, uncertainty analysis, legacy
  comparison, and release machinery; and
- a new coupled runner, figure bundle, persistent CSV, RDS, cache, dashboard,
  or other generated repository product.

## Authority And Stop Rule

Goal 003 is published at baseline:

```text
e2622ca739d89124e8cb8361fb40363363686d49
```

Execution requires Barry's explicit authorization after packet review.
Formulation authority does not include implementation, staging, committing, or
pushing.

At authorization, the SHA-256 identities of `Goal.md`, `Plan.md`, and
`Runbook.md` become frozen. `Log.md` remains the only mutable packet file during
execution.

Stop before implementation on a changed upstream, unexpected dirty path,
control-document hash mismatch, or changed scientific requirement. After
implementation begins, stop on a new dynamic state, modified Goal 003
interface, non-finite conversion, new dependency, undeclared path, persistent
repository output, or expansion into an excluded process.

Apply one focused self-review and repair pass after core validation. Further
iteration is justified only by a material unit, scientific, data-integrity,
scope, or publication defect. Stop after the reviewed uncommitted Goal 004
closeout and return the evidence to Barry before any later biological layer.
