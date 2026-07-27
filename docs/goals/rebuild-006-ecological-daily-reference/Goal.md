# Rebuild Goal 006: Ecological Daily Reference

## Status

This packet defines a proposed implementation goal. Formulation creates only
the four files in this goal directory. It does not authorize implementation,
staging, committing, or pushing.

Execution requires Barry's approval after review of this packet. The packet
should then be published on `main` before implementation begins so that the
execution baseline is clean and unambiguous.

## Principal Question

Under the unchanged Goal 004-005 system, what repeatable gut-release and
body-reserve trajectory follows from a minimally plausible day-resting,
night-spanning prescribed-intake schedule, relative to the continuous
mathematical reference with the same daily energy input?

## Completed Outcome

The repository contains two explicitly named and distinct reference fixtures:

1. a **mathematical reference** that prescribes constant intake in all 24
   hourly intervals; and
2. an **ecological reference** that closes intake during one fixed daytime rest
   block and compensates with constant prescribed intake during the remaining
   16 intervals.

Both fixtures:

- compose dry-matter intake through the unchanged Goal 004 food-energy bridge;
- run through the unchanged Goal 005 reference-cycle runner;
- converge to a repeatable period-24 gut cycle;
- preserve the existing one-time body reset and two measured days;
- prescribe 0.24 kg DM and 2400 kJ per day;
- maintain body energy within the existing numerical tolerances; and
- expose different within-day gut, assimilation, and body-reserve
  trajectories.

The mathematical reference remains the permanent diagnostic and regression
baseline. After Goal 006 acceptance, the ecological reference becomes the
default starting point for discussing later ecological perturbations. This
does not authorize any later mechanism or scenario.

## Reference Doctrine

The two references serve different purposes.

### Mathematical Reference

The mathematical reference is deliberately artificial and maximally
transparent. It isolates arithmetic, accounting, update order, convergence,
and state carry-over. It should remain stable even after more realistic
features are added.

### Ecological Reference

The ecological reference adds one minimal timing constraint: prescribed intake
is zero during a declared daytime rest block. It is more plausible than
continuous feeding, but it is still synthetic.

The ecological reference is not a second model implementation. It is one
declared input fixture composed through existing public functions. Future
mechanisms should first be diagnosed against the mathematical reference and
then, when relevant, incorporated into the ecological reference.

Not every future experiment requires two complete scenario families. The
mathematical reference is retained for diagnosis; the ecological reference is
the normal comparator for ecological interpretation.

## Exact Shared Fixture

Both references use:

```text
initial gut available energy = 0 kJ
measurement body-energy reserve = 10000 kJ
gut release fraction = 0.25 h^-1
maintenance expenditure = 100 kJ h^-1
metabolizable-energy density = 10000 kJ kg^-1 DM
gut convergence relative tolerance = 100 * .Machine$double.eps
maximum gut-only burn-in = 100 d
measured duration = 2 d
```

The density is already metabolizable energy on a dry-matter basis. It does not
represent gross energy, digestive efficiency, or a physiological assimilation
calculation.

## Exact Mathematical Reference

Use:

```text
scenario_id = mathematical_continuous
reference_type = mathematical
hour_of_day = 0:23
prescribed dry-matter intake = 0.010 kg DM h^-1 in every interval
derived gut input = 100 kJ h^-1 in every interval
feeding intervals = 24
rest-closed intervals = 0
daily dry-matter intake = 0.24 kg DM
daily gut input = 2400 kJ
```

This is the accepted constant fixture from Goal 005.

## Exact Ecological Reference

Use:

```text
scenario_id = ecological_day_resting
reference_type = ecological

hour_of_day = 0:7
prescribed dry-matter intake = 0.015 kg DM h^-1
derived gut input = 150 kJ h^-1

hour_of_day = 8:15
prescribed dry-matter intake = 0 kg DM h^-1
derived gut input = 0 kJ h^-1

hour_of_day = 16:23
prescribed dry-matter intake = 0.015 kg DM h^-1
derived gut input = 150 kJ h^-1

feeding intervals = 16
rest-closed intervals = 8
daily dry-matter intake = 0.24 kg DM
daily gut input = 2400 kJ
```

Each `hour_of_day` labels the half-open interval
`[hour_of_day, hour_of_day + 1)`. The rest-closed block is therefore exactly
`[08:00, 16:00)`. The 16 feeding intervals form one night-spanning block from
16:00 through 08:00 across the nominal midnight boundary.

This schedule prescribes actual model intake. It is not an offered-food
schedule, permission mask, feeding decision, or observation of realized
foraging behavior.

## Scientific Estimand

The primary estimand is the deterministic within-day trajectory contrast
between the two energy-matched references after each gut has reached its own
period-24 cycle.

Compare:

- prescribed gut-input timing;
- hourly gut release to the body;
- the 25 gut boundary stocks for each measured day; and
- the 25 body-reserve boundary stocks for each measured day.

The references must have equal daily prescribed ingestion and maintenance.
Within the existing scenario-specific tolerances, they must also have equal
daily assimilation, observed gut change, and observed body change.

For each between-reference daily comparison, the permitted absolute difference
is the sum of the corresponding mathematical-reference and
ecological-reference tolerances:

```text
assimilation difference <=
  mathematical assimilation-total tolerance +
  ecological assimilation-total tolerance

observed gut-change difference <=
  mathematical cycle tolerance +
  ecological cycle tolerance

observed body-change difference <=
  mathematical body-neutrality tolerance +
  ecological body-neutrality tolerance
```

Do not compare absolute combined-system energy levels as an equivalence
criterion because each periodic schedule has a different phase-specific
opening gut stock.

Equal daily totals are an accounting consequence of the current linear,
lossless, unlimited gut system. The scientifically useful result is the shape
and magnitude of the within-day trajectory contrast under the declared timing
constraint.

## Numerical Checks

Use the final realized Goal 005 convergence tolerance for gut-cycle
comparisons. For each measured day, reconstruct the existing Goal 005
gut-ledger and body-ledger tolerances from the raw hourly and daily ledgers:

```text
gut_ledger_tolerance_kj =
  100 * .Machine$double.eps * max(
    1,
    abs(daily opening and closing gut stocks),
    sum(abs(hourly ingestion amounts)),
    sum(abs(hourly assimilation amounts))
  )

assimilation_total_tolerance_kj =
  cycle_tolerance_kj + gut_ledger_tolerance_kj

body_ledger_tolerance_kj =
  100 * .Machine$double.eps * max(
    1,
    abs(daily opening and closing body stocks),
    sum(abs(hourly assimilation amounts)),
    sum(abs(hourly maintenance amounts))
  )

body_neutrality_tolerance_kj =
  cycle_tolerance_kj +
  gut_ledger_tolerance_kj +
  body_ledger_tolerance_kj
```

Require:

- daily dry-matter totals equal to 0.24 kg DM within
  `100 * .Machine$double.eps` kg DM;
- finite, strictly positive realized convergence tolerances;
- convergence of both fixtures;
- measured day-2 gut boundaries equal to measured day 1 within the
  scenario-specific cycle tolerance;
- exact day-1 to day-2 state carry-over;
- finite and non-negative body stocks at every measured boundary;
- daily ingestion and maintenance of exactly 2400 kJ;
- daily gut closure, assimilation, and body neutrality within their declared
  tolerances; and
- the between-reference daily equivalence bounds defined above.

Use numerical stocks and flows for neutrality. Do not infer it from
`body_energy_status`.

Both fixed reference fixtures are expected to converge on burn-in day 7 under
the accepted Goal 005 tolerance. A different result is a regression signal to
investigate, not authority to modify the production model.

## Trajectory Contrast Contract

For each measured day, derive 25 gut and body boundary stocks from the opening
hour-0 stock plus the 24 hourly closing stocks. Require:

```text
maximum absolute gut-boundary difference >
  mathematical cycle tolerance +
  ecological cycle tolerance

maximum absolute hourly assimilation-amount difference >
  mathematical assimilation-total tolerance +
  ecological assimilation-total tolerance

maximum absolute body-boundary difference >
  mathematical body-neutrality tolerance +
  ecological body-neutrality tolerance
```

Protect the expected ecological phase landmarks:

```text
gut boundary maximum = 08:00
gut boundary minimum = 16:00
hourly gut release maximum = hour 8, [08:00, 09:00)
hourly gut release minimum = hour 16, [16:00, 17:00)
body-reserve boundary maximum = 10:00
body-reserve boundary minimum = 20:00
```

The planned fixture should also retain these broad, human-readable magnitude
bands:

```text
maximum between-reference gut-boundary difference = 340-341 kJ
maximum between-reference hourly assimilation difference = 85-86 kJ
maximum between-reference body-boundary difference = 411-412 kJ
```

These bands protect the intended trajectory scale without treating
whole-kilojoule presentation as floating-point precision. A phase landmark or
magnitude outside the declared contract is evidence to diagnose before
changing any model or fixture.

## Scientific Meaning And Limits

The ecological reference may be described as a generic day-resting,
nocturnally active prescribed-feeding reference. The nominal feeding block
includes dusk and dawn by clock convention, but intake is flat throughout the
16 feeding intervals. It does not represent explicit crepuscular peaks.

The clock is nominal. It is not tied to sunrise, season, latitude, weather, or
light. The model contains no activity or sleep state.

Goal 006 does not establish:

- a species-specific kangaroo schedule;
- observed feeding duration or maximum intake;
- achievable or voluntary intake;
- activity expenditure or the cost of feeding;
- gut capacity, digestive loss, or rate-limited assimilation;
- biological energy balance, viability, fitness, or optimality;
- real gut fill or residence time;
- behavioral choice, feedback, or adaptive compensation; or
- empirical realism of any parameter.

The phrase "minimally plausible" refers only to closing intake during a fixed
rest interval. All parameters remain synthetic conventions.

## Preserved Model Contract

Goal 006 changes no package function, record, equation, schema, validator,
transition order, numerical tolerance, or dependency.

It reuses:

- `new_food_energy_parameters()`;
- `new_dry_matter_intake_schedule()`;
- `derive_ingested_available_energy_schedule()`;
- the existing gut and body state and parameter constructors; and
- `run_gut_body_energy_reference_cycle()`.

No convenience runner, activity record, feeding mask, scenario class, new
public interface, S3, S4, R6, reference class, or compatibility layer is added.

## Focused Regression Contract

Add one focused test file for the two references. It must protect:

- exact dry-matter and derived energy schedules;
- the 8 rest-closed and 16 feeding intervals;
- daily dry-matter and energy totals;
- finite convergence and the expected burn-in day;
- measured cycle repetition and exact state carry-over;
- finite, non-negative body paths;
- daily neutrality using independently reconstructed tolerances;
- timing-equivalent daily totals using summed scenario tolerances;
- distinct within-day gut, assimilation, and body trajectories using the
  declared tolerance bounds;
- the six ecological phase landmarks; and
- the three broad trajectory-contrast magnitude bands.

Do not repeat strict API validation, mutation, overflow, failure-mode, or
schema tests already covered by Goal 004-005.

Because all required public functions already exist, there is no legitimate
missing-interface red phase. The complete focused test should pass against the
accepted production model. A failure is evidence to diagnose, not permission
to alter production source.

## No-Write Experiment

Add one thin no-write experiment that:

- constructs both dry-matter schedules explicitly;
- composes them through the Goal 004 converter;
- runs the Goal 005 reference-cycle function;
- asserts all focused scientific outcomes in memory;
- prints schedule totals, convergence diagnostics, daily summaries, and
  selected 08:00 and 16:00 boundary checkpoints; and
- reports the maximum between-reference differences in gut boundaries,
  assimilation, and body boundaries.

Human-facing stocks and amounts use whole kilojoules. Rates may retain
appropriate additional precision. Internal checks retain full precision.

## Review Pack

A separate base-R review script, run against a temporary installed package,
writes exactly:

```text
outputs/rebuild-006-ecological-daily-reference/
  figure-1-measured-reference-comparison.png
  table-1-input-schedules.csv
  table-2-convergence.csv
  table-3-daily-summary.csv
  table-4-hourly-ledgers.csv
```

The figure contains four 0-48 hour panels:

- prescribed gut-input rate;
- gut release to the body;
- gut boundary stock; and
- body-reserve boundary stock.

It identifies both references, marks the 24-hour day boundary, and lightly
identifies the two repeated rest-closed intervals `[08:00, 16:00)` and
`[32:00, 40:00)`. Axes state units and the title identifies the cases as
synthetic references.

The input table contains, in order:

```text
scenario_id
reference_type
hour_of_day
prescribed_dry_matter_intake_kg_dm_h
prescribed_ingested_available_energy_kj_h
```

The convergence table prepends `scenario_id` and `reference_type` to the exact
seven-column Goal 005 convergence schema.

The daily table prepends `scenario_id` and `reference_type` to the exact
20-column Goal 005 measured daily schema.

The hourly table prepends:

```text
scenario_id
reference_type
prescribed_dry_matter_intake_kg_dm_h
```

to the exact 22-column Goal 005 measured hourly schema.

Tables retain sufficient numerical precision to reproduce the declared checks
after CSV read-back. Bit-identical binary round-trip is not required when the
read-back values preserve schemas and all declared numerical outcomes.
Generated files are ignored review aids and are never commit inputs. They
remain available for Barry's discussion until deletion is separately
authorized.

The review script must:

- accept exactly one output-directory argument;
- reject a symbolic-link destination;
- reject undeclared destination entries;
- generate into temporary staging;
- validate the exact staged file set and CSV read-back;
- overwrite only the five declared regular files; and
- stop before publication if any analytical or serialization check fails.

Keep the script focused on Goal 006. Do not copy the complete Goal 005 review
script wholesale or refactor accepted Goal 005 evidence code.

## Validation And Acceptance

Goal 006 is accepted only when:

- the focused reference tests pass with no failure, warning, error, or skip;
- the complete suite exceeds the accepted 812-pass Goal 005 baseline with no
  failure, warning, error, or skip;
- the no-write experiment passes from source and a temporary installed
  package;
- both references satisfy the declared schedules, convergence, cycle,
  carry-over, feasibility, neutrality, and trajectory-contrast checks;
- no file under `R/`, `man/`, or the protected Goal 001-005 tests changes;
- `DESCRIPTION`, `NAMESPACE`, `renv.lock`, `.Rbuildignore`, `.gitignore`, and
  `docs/variable-dictionary.md` remain unchanged;
- `renv` remains synchronized;
- external build, temporary installation, and `R CMD check --no-manual` pass;
- the exact five-file review pack is generated, read back, and inspected;
- the complete diff remains within the authorized surface;
- the approved Goal, Plan, and Runbook hashes remain unchanged;
- the Git index remains empty during execution; and
- one independent final reviewer finds no material scientific, evidence,
  implementation, or scope defect.

After the core checks, perform at most one focused repair pass for material
findings. Stop when the high-value contract is satisfied; do not iterate on
cosmetic or non-decision-relevant polish.

## Planned Implementation Surface

Expected new implementation files:

```text
docs/decisions/0006-ecological-daily-reference.md
experiments/rebuild-006-ecological-daily-reference.R
experiments/rebuild-006-review-pack.R
tests/testthat/test-ecological-daily-reference.R
```

Expected modified files:

```text
README.md
docs/goals/rebuild-006-ecological-daily-reference/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
```

Any additional path requires a specific, documented justification. A material
scope expansion requires Barry's approval.

## Explicit Non-Goals

Goal 006 does not add:

- production R code or a public interface;
- a modeled activity, sleep, feeding-permission, or light state;
- true crepuscular peaks;
- a maximum intake rate or feeding-time feasibility constraint;
- feeding or activity expenditure;
- variable, stochastic, seasonal, or sunrise-relative schedules;
- behavior, choice, adaptation, or body-state feedback;
- gut capacity, digestive loss, or assimilation limits;
- dynamic body mass or any other physiology;
- plants, weather, space, individuals, or populations;
- empirical calibration, parameter estimation, or uncertainty analysis; or
- a generalized scenario or simulation framework.

## Stop Boundary

Stop after the two-reference doctrine, exact ecological schedule, focused
regression, no-write experiment, five review files, documentation, validation,
and independent review are complete.

Do not implement maximum intake or interpret whether 150 kJ h^-1 is
biologically achievable. That is a separate future mechanism and decision.

Do not stage, commit, or push the Goal 006 implementation without Barry's
separate authorization after he reviews the completed evidence.
