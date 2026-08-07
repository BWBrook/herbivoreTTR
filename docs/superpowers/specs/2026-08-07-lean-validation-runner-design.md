# Lean Validation and Runner Design

## Purpose

Simplify validation and hourly runner internals without changing the model's
ecology or numerical behavior. This is a behavior- and science-preserving
refactor: no equation, transition, forcing convention, or biological
assumption is added or revised.

## Contract to Preserve

- Preserve all public function names and signatures.
- Preserve the gut transition order: release a fraction of opening gut energy,
  then add the current hour's ingested available energy.
- Preserve the body transition order and equations: assimilated energy minus
  maintenance and routine-activity expenditure updates the reserve.
- Preserve the existing hourly, daily, coupled, and reference-cycle result
  structures, column names and order, row counts, and canonical output types.
- Preserve reserve-feasibility checks and hourly and daily gut, body, and
  whole-system energy-conservation checks with their current tolerances.
- For every currently valid scenario, preserve numerical results within the
  current test tolerance. Canonical constructor inputs should continue to
  produce identical outputs where the existing tests require identity.

## Scope

In scope:

- replace representation checks in state, parameter, schedule, row, and
  reference-cycle argument validators with semantic checks;
- retain `step_body_energy()` and `step_gut_energy()` as public direct-call
  entry points, backed by small private scalar transition cores;
- make one-day and reference-cycle loops consume already validated scalar
  values and vectors directly;
- remove hourly one-row data-frame construction and repeated validation of
  complete records; and
- update tests to distinguish semantic contracts from incidental R storage and
  attribute details.

Non-goals:

- new ecology, physiology, equations, transition order, outputs, or
  configuration;
- a generic simulation framework, object-oriented layer, compatibility
  adapter, migration path, or alternate legacy entry point;
- performance tuning beyond removing the identified validation and temporary
  allocation burden; and
- changes to experiment conclusions, documentation of scientific assumptions,
  or release machinery.

## Semantic Input Contract

Validation should ask whether an input carries the required scientific values,
not whether it is byte-for-byte identical to a constructor's current output.

- Records must expose the required named fields at the expected cardinality.
  Schedules and step rows must expose the required columns with 24 and one row,
  respectively. Extra fields that change the declared record or schedule
  dimensions remain invalid.
- Schedule hours must be the ordered values `0:23`. Step-row hours must be one
  whole value in `[0, 23]`, and coupled input/activity hours must match by
  numeric value. Integer and double storage are equivalent for these values.
- Energy amounts, rates, fractions, tolerances, and counts must be numeric,
  finite, and of the required length. Integer and double values are accepted
  when scientifically equivalent.
- Non-negativity remains mandatory for energy stocks, inputs, and expenditure.
  The gut release fraction remains in `(0, 1]`; convergence tolerance remains
  in `(0, 1)`; and maximum burn-in days remains a whole value of at least two.
- Names, row names, attribute ordering, and other attributes that do not alter
  values, required fields, lengths, or dimensions are harmless and must not be
  rejection grounds. Validation must not depend on exact `typeof()`, exact
  `class()`, or exact `attributes()` identity.
- Character numerics, factors, logicals, complex values, fractional discrete
  values, and non-finite values are invalid. Do not parse character values or
  silently perform lossy coercion. Lossless canonicalization of validated
  integer/double inputs is permitted where needed to preserve output schemas.

Constructors may continue returning the current canonical plain lists and base
data frames. The simplification changes what public computations accept, not
what constructors emit or what result tables look like.

## Data and Control Flow

### Scalar transition cores

Introduce two small private functions, one for gut arithmetic and one for body
arithmetic. Each receives already validated scalar values, applies the existing
equations in the existing order, enforces finite arithmetic, reserve
feasibility, and hourly conservation, and returns the current state/flux shape.
The cores do not inspect data-frame classes, attributes, or complete records.

`step_gut_energy()` becomes:

1. semantically validate its state, parameters, and one-row input;
2. extract the required scalars; and
3. call the private gut core.

`step_body_energy()` follows the same pattern, including semantic equality of
the input and activity hours, then calls the private body core.

### One-day runners

Each public one-day runner validates every complete input once before mutation
or iteration. Its explicit 24-hour loop indexes validated vectors and calls the
appropriate scalar core directly.

`run_body_energy_day()` passes reserve, maintenance, assimilated energy, and
routine-activity values to the body core. `run_gut_body_energy_day()` calls the
gut core first, passes that hour's released energy directly to the body core,
then performs the existing whole-system accounting. Neither runner constructs
temporary one-row schedules or revalidates state, parameter, or schedule
records inside the loop.

Keep the orchestration visible in these domain functions. A small private
prevalidated coupled-day helper may be shared with the reference-cycle
measurement path, but it must remain specific to this model and return the
current coupled-day schema.

### Reference cycle

`run_gut_body_energy_reference_cycle()` validates its complete public inputs
once. Burn-in indexes the validated ingestion vector and calls the gut scalar
core directly for each hour. The two measured days use the explicit
prevalidated coupled-day path, carrying the same closing gut and body states
forward. Convergence comparison, body reset timing, measurement-day labelling,
and result assembly remain unchanged.

```text
public entry point
  -> semantic validation once
  -> extract validated scalars/vectors
  -> explicit hourly orchestration
       -> gut scalar core
       -> body scalar core where applicable
       -> existing hourly/system accounting
  -> existing daily/reference-cycle summaries and schemas
```

## Error Semantics

- Invalid public inputs fail at the public boundary, before the first
  transition, with `call. = FALSE` and a message naming the invalid argument or
  field and its semantic requirement.
- Messages should describe missing fields, wrong dimensions, invalid hours,
  non-finite or out-of-range values, or hour mismatch. Remove messages about
  retaining constructor storage, exact attributes, or exact base-R identity.
- Arithmetic failures remain local to the transition or summary that detects
  them. A proposed negative body reserve or gut stock remains an error; values
  are never clipped.
- Conservation failures retain separate gut, body, and whole-system contexts.
  The refactor must not weaken or bypass these scientific safeguards.

## Test Strategy

Delete tests whose only assertion is rejection of integer rather than double
storage, harmless attributes, attribute ordering, row-name identity, or an
otherwise equivalent container representation. Preserve output-schema tests;
they protect public results rather than input policing.

Retain or add compact coverage for:

- representative semantic invalid-input classes: missing/extra required
  fields, wrong row or vector length, unordered or fractional hours, mismatched
  input/activity hours, character numerics, logicals, non-finite values, and
  out-of-range or negative values;
- acceptance of scientifically equivalent integer/double inputs and harmless
  attributes at constructor, converter, step, day-runner, and reference-cycle
  public boundaries;
- direct `step_body_energy()` and `step_gut_energy()` equations, transition
  order, nested return schemas, finite arithmetic, negative-closing-stock
  errors, and hourly conservation;
- body-only and coupled daily trajectories, state continuity, daily summaries,
  gut/body/system conservation, and negative-reserve checks;
- reference-cycle convergence, burn-in trajectory, body reset timing,
  carry-over, two-day outputs, and agreement with direct one-day runs; and
- current ecological scenarios and trajectory fixtures. Existing valid
  scenario results must match the pre-refactor values within their current
  tolerance, with exact schema and identity checks retained where already part
  of the public output contract.

## Validation Gates

For implementation, run the repository fast change gate:

1. parse every retained file under `R/`;
2. run targeted validator, transition, one-day, coupled, and reference-cycle
   tests, followed once by the full local test suite because the shared
   validation boundary is cross-cutting; and
3. run `git diff --check` and confirm only intended source, test, and necessary
   documentation changes are present.

Compare representative pre- and post-refactor step, trajectory, coupled-day,
and reference-cycle outputs for numerical equality within current tolerances
and exact output schemas. Do not generate or commit validation artefacts. Run
external `R CMD build` and `R CMD check --no-manual` only at an explicitly
authorized release or accepted-foundation publication boundary.

## Review Surface

Primary production review:

- `R/body-energy-records.R`, `R/gut-energy-records.R`,
  `R/food-energy-records.R`, `R/food-energy-conversion.R`, and
  `R/routine-activity-expenditure-records.R` for semantic field validation;
- `R/body-energy-transition.R` and `R/gut-energy-transition.R` for wrapper/core
  separation and unchanged transition arithmetic;
- `R/body-energy-run.R` and `R/gut-body-energy-run.R` for validate-once loops,
  output assembly, reserve feasibility, and conservation; and
- `R/gut-body-energy-reference-cycle.R` for direct-core burn-in and unchanged
  convergence and measurement control flow.

The corresponding record, transition, scenario, coupled-run, activity,
conversion, and reference-cycle tests are the test review surface. Public
documentation changes are limited to wording that currently promises
representation identity rather than semantic validity.

## Risks and Controls

- **Numerical drift from reordered arithmetic:** keep expressions and update
  order unchanged and compare existing trajectory fixtures within current
  tolerances.
- **Validation becomes too permissive:** require exact scientific fields and
  dimensions, reject non-numeric and lossy conversions, and retain one example
  from every semantic invalid-input class.
- **Validation is accidentally skipped for direct callers:** keep public step
  functions as validating wrappers and test them independently from runners.
- **Scientific safeguards move out of the hot path:** reserve feasibility and
  hourly conservation belong in the scalar cores; daily and system checks stay
  in their current summaries/orchestration.
- **Output representation drifts with newly accepted inputs:** canonicalize
  only after semantic validation, losslessly, and retain exact output-schema
  tests.

## Alternatives Considered

**Prune validators only.** Removing a subset of exact representation checks
would reduce code but leave public wrappers, one-row temporary data frames, and
repeated whole-record validation in every hourly loop. It does not remove the
main runtime and maintenance burden.

**Build a generic simulation engine.** A configurable engine or OO hierarchy
could centralize loops, but this package currently has two small, explicit
energy transitions. Such a layer is premature abstraction and would obscure
the scientifically important order of operations.

## Stop Rule

Deliver the semantic validators, two scalar cores, direct-core runners, and the
preserved scientific/output test set. Perform one focused self-review and
repair pass for material semantic, numerical, or schema defects. Stop when the
remaining differences are naming, deduplication, or other polish unlikely to
change scientific behavior, validation safety, or the implementation decision.
