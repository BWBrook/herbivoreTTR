# Rebuild Goal 005: Repeated-Day Reference Cycle

## Status

This packet defines a proposed implementation goal. Formulation creates only
the four files in this goal directory. It does not authorize implementation,
staging, committing, or pushing.

Execution requires Barry's approval after review of this packet. The packet
should then be published on `main` before implementation begins so that the
execution baseline is clean and unambiguous.

## Principal Question

When one prescribed 24-hour food schedule is repeated without change, does the
existing one-pool gut system converge from an arbitrary opening stock to a
repeatable daily cycle, and does an energy-matched schedule maintain body
energy after the initialization transient is removed?

## Completed Outcome

The package can:

1. repeat one unchanged 24-hour gut-input schedule;
2. advance only the gut during a declared numerical burn-in;
3. detect convergence to a period-24 gut cycle;
4. reset body energy once at the measurement boundary;
5. run two measured days through the unchanged Goal 003 daily runner while
   carrying gut and body states forward; and
6. return compact convergence, hourly, and daily diagnostics.

Three synthetic cases demonstrate:

- a zero-intake gut cycle accompanied by sustained body-energy deficit;
- an energy-neutral constant-intake equilibrium; and
- an energy-neutral, concentrated feeding window with a non-constant daily gut
  and body trajectory.

The constant and concentrated schedules have identical daily dry-matter and
available-energy totals. In the current linear, lossless model they therefore
have the same steady-cycle daily energy balance even though their within-day
trajectories differ.

## Agreed Scientific Decisions

- Stability has two distinct meanings:
  - **gut-cycle stability:** the 24-hour gut trajectory repeats; and
  - **energetic stability:** measured daily body-energy change is approximately
    zero.
- A stable gut cycle does not imply energetic neutrality. Sustained surplus or
  deficit can coexist with a repeatable gut trajectory.
- Burn-in is convergence-based rather than a fixed one- or two-day discard.
- Burn-in advances the gut only. It does not advance, debit, or credit body
  energy.
- Body energy is reset to a declared measurement state once, after gut
  convergence and before measured day 1.
- Measured day 2 begins from the closing gut and body states of measured day 1.
  The body is not reset between measured days.
- Two measured days are sufficient for this diagnostic goal. Goal 005 does not
  introduce a general ecological multi-day simulation horizon.
- When both body trajectories remain above the existing non-negative reserve
  boundary, feeding timing alone must not change steady-cycle daily totals in
  this model. A difference outside the declared numerical tolerances would
  indicate a carry-over, update-order, accounting, or implementation defect.

## Scientific Meaning

The constant schedule represents a fixed point under constant hourly forcing.
The concentrated schedule represents a period-24 cycle under time-varying but
identical daily forcing. This distinction is useful: a constant fixture can
verify arithmetic while concealing day-boundary errors, whereas a concentrated
late-day feeding window forces energy to cross the midnight boundary.

The body reset is a diagnostic protocol, not a physiological process. It
prevents an arbitrary empty-gut initialization from imposing a permanent
one-off energy debt on the measured reference state.

The convergence tolerance is numerical. It does not express measurement
precision, biological variation, a viability threshold, or confidence in any
parameter value.

## Preserved Model Contract

Goal 005 composes the implemented Goal 001-004 system without changing it:

- R only;
- plain exact records and base R data frames;
- 24 ordered one-hour transitions on `hour_of_day = 0:23`;
- release from opening gut stock before current-hour ingestion;
- `gut_release_fraction_h` in `(0, 1]`;
- non-negative finite gut and body stocks without clipping;
- failure before returning a negative body reserve;
- fixed maintenance expenditure;
- prescribed dry-matter intake converted explicitly upstream through one fixed
  metabolizable-energy density;
- pure functions without hidden mutation or file writes; and
- unchanged Goal 001-004 public interfaces, schemas, equations, and tests.

The reference-cycle runner accepts the existing Goal 003 available-energy
schedule. It does not absorb the Goal 004 food records or converter. Callers
must retain those objects and compose the conversion explicitly.

## Public Functional Interface

Goal 005 adds one public function:

```text
run_gut_body_energy_reference_cycle(
  initial_gut_state,
  measurement_body_state,
  gut_parameters,
  body_parameters,
  schedule,
  gut_convergence_relative_tolerance,
  max_burn_in_days
)
```

The first five arguments must satisfy the existing Goal 003 validators.

`gut_convergence_relative_tolerance` is a bare, finite numeric scalar strictly
between 0 and 1. It is dimensionless and is stored internally as a double.

`max_burn_in_days` is a bare integer scalar of at least 2. A minimum of two
days is required because convergence compares hour-matched trajectories on
successive days.

No S3, S4, R6, reference class, generalized simulation object, or compatibility
layer is introduced.

## Burn-In Contract

One burn-in day applies `step_gut_energy()` to the same 24-row schedule in the
accepted Goal 003 order. The closing gut state becomes the next day's opening
gut state. No body transition is evaluated.

For each day, retain the 25 gut boundary stocks:

```text
opening stocks for hours 0:23
closing stock for hour 23
```

From burn-in day 2 onward:

```text
max_abs_previous_day_trajectory_difference_kj =
  max(abs(current_boundary_stocks_kj - previous_boundary_stocks_kj))
```

The realized comparison tolerance is:

```text
gut_convergence_relative_tolerance * max(
  1,
  abs(current_boundary_stocks_kj),
  abs(previous_boundary_stocks_kj),
  sum(abs(current_ingested_energy_kj)),
  sum(abs(current_assimilated_energy_kj)),
  sum(abs(previous_assimilated_energy_kj))
)
```

The fixed one-hour transition means each ingested or assimilated rate has the
same numerical value as its corresponding one-hour amount.

The realized scale and tolerance must both be finite and the tolerance must be
strictly positive. Any overflow or other non-finite convergence arithmetic
raises an error before comparison.

Convergence occurs when both:

```text
max_abs_previous_day_trajectory_difference_kj <=
  realized_convergence_tolerance_kj

abs(cycle_boundary_change_kj) <=
  realized_convergence_tolerance_kj
```

The second condition makes the period-24 boundary explicit rather than relying
only on the successive-trajectory comparison. The final converged day's
closing gut state becomes the opening gut state for measured day 1.

If convergence is not achieved within `max_burn_in_days`, the function raises a
clear error and returns no partial result. This is especially important for
very small positive release fractions.

## Measurement Contract

After burn-in:

1. use the converged closing gut state;
2. use `measurement_body_state` exactly, without applying burn-in history;
3. call the unchanged `run_gut_body_energy_day()` for measured day 1;
4. reconstruct valid gut and body state records from the day-1 closing stocks;
5. call the unchanged daily runner for measured day 2; and
6. return the combined measured ledgers.

The exact one-day result for each measured day, after removing the added
`measurement_day` column and resetting that slice to canonical row names
`1:24`, must be identical to a direct call of the Goal 003 runner from the same
opening states. The corresponding daily slice is compared after resetting its
single row name to `1`.

## Return Contract

The function returns an exact plain list with:

```text
convergence
hourly
daily
```

### Convergence Table

`convergence` is a base R data frame with one row per completed burn-in day and
exactly:

```text
burn_in_day
gut_available_energy_initial_kj
gut_available_energy_final_kj
cycle_boundary_change_kj
max_abs_previous_day_trajectory_difference_kj
realized_convergence_tolerance_kj
converged
```

`burn_in_day` is integer. The first row has `NA_real_` for the two
comparison-only fields and `FALSE` for `converged`. The final row is the first
row satisfying the convergence rule and has `TRUE` for `converged`.

### Measured Hourly Ledger

`hourly` has exactly 48 rows. It prepends integer `measurement_day`, with values
1 and 2 repeated 24 times each, to the unchanged 21-column Goal 003 hourly
schema. Within each day, `hour_of_day` remains exactly `0:23`. The combined
table has canonical row names `1:48`.

### Measured Daily Summary

`daily` has exactly two rows. It prepends integer `measurement_day = 1:2` to
the unchanged 19-column Goal 003 daily schema and has canonical row names
`1:2`.

All returned values retain full internal precision. Human-facing energy stocks
and amounts are shown as whole kilojoules; rates retain meaningful decimals.

## Analytical Fixtures

All fixtures are synthetic diagnostics, not macropod parameter estimates.

Common settings:

```text
initial_gut_available_energy_kj = 0
measurement_body_energy_reserve_kj = 10000
gut_release_fraction_h = 0.25
maintenance_expenditure_kj_h = 100
metabolizable_energy_density_kj_kg_dm = 10000
gut_convergence_relative_tolerance = 100 * .Machine$double.eps
max_burn_in_days = 100
```

### Zero Intake

```text
prescribed_dry_matter_intake_kg_dm_h = 0 for hours 0:23
```

The gut trajectory is identically zero and converges at the first possible
comparison. Each measured day has zero ingestion and assimilation and loses
2400 kJ from body reserve. This proves that gut-cycle stability and energetic
stability are separate diagnostics.

### Constant Intake

```text
prescribed_dry_matter_intake_kg_dm_h = 0.010 for hours 0:23
```

The schedule contains 0.24 kg DM and 2400 kJ per day. After burn-in, the gut
approaches the accepted 400 kJ fixed point, assimilation approaches 100 kJ
h^-1, and measured body energy is neutral within the declared numerical
tolerances.

### Concentrated Late Feeding

```text
prescribed_dry_matter_intake_kg_dm_h = 0.040 for hours 18:23
prescribed_dry_matter_intake_kg_dm_h = 0 for hours 0:17
```

The schedule also contains 0.24 kg DM and 2400 kJ per day. Its late six-hour
window deliberately carries unreleased energy across the day boundary.

After burn-in, its measured gut, assimilation, and body trajectories differ
from the constant case, but:

- day-1 and day-2 gut trajectories repeat within the realized convergence
  tolerance;
- measured daily ingestion and maintenance are each 2400 kJ;
- measured daily assimilation is 2400 kJ within numerical tolerance;
- measured daily body-energy change is zero within numerical tolerance; and
- constant and concentrated daily totals agree within numerical tolerance.

Freeze the numerical acceptance rules for each neutral scenario and measured
day as follows:

```text
cycle_tolerance_kj =
  final_realized_convergence_tolerance_kj

gut_ledger_tolerance_kj =
  the existing Goal 003 daily gut-accounting tolerance for that ledger

body_ledger_tolerance_kj =
  the existing Goal 003 daily body-accounting tolerance for that ledger

assimilation_total_tolerance_kj =
  cycle_tolerance_kj + gut_ledger_tolerance_kj

body_neutrality_tolerance_kj =
  assimilation_total_tolerance_kj + body_ledger_tolerance_kj
```

Require:

```text
abs(measured_gut_final_kj - measured_gut_initial_kj) <=
  cycle_tolerance_kj

abs(total_assimilated_energy_kj -
    total_prescribed_ingested_available_energy_kj) <=
  assimilation_total_tolerance_kj

abs(observed_body_energy_change_kj) <=
  body_neutrality_tolerance_kj
```

For constant-versus-concentrated comparisons, the permitted absolute
difference is the sum of the corresponding scenario-specific tolerances.
Prescribed daily ingestion and maintenance must each equal 2400 kJ exactly.

Do not use the categorical `body_energy_status` as convergence or neutrality
evidence. Its reserve-scaled accounting tolerance answers a different
question.

Timing invariance is conditional on both measured paths completing without
crossing the unchanged negative-body-reserve boundary. The declared 10000 kJ
measurement fixture must be verified to satisfy this condition.

These equivalences are conditional on the current unlimited, linear gut-energy
stock and lossless transfer. They are not claims that real feeding schedules or
foods are biologically interchangeable.

## Review Surfaces

The thin no-write experiment asserts all fixtures in memory and prints:

- burn-in days and final convergence differences;
- measured daily ingestion, assimilation, maintenance, and body-energy change;
- selected day-boundary and feeding-window checkpoints; and
- the constant-versus-concentrated timing equivalence.

A separate base-R review script, run against the temporary installed package,
writes only these files under the ignored directory
`outputs/rebuild-005-repeated-day-reference-cycle/`:

```text
figure-1-burn-in-convergence.png
figure-2-measured-reference-cycles.png
table-1-convergence.csv
table-2-daily-summary.csv
table-3-hourly-ledgers.csv
```

Figure 1 shows convergence differences and realized thresholds by burn-in day.
Figure 2 compares the measured 48-hour ingestion, assimilation, gut-stock, and
body-reserve trajectories for the three fixtures. Axes state units and the
figures identify all cases as synthetic.

The tables retain sufficient numerical precision to reproduce the checks.
Generated files are review aids, remain ignored, and are never commit inputs.
They are retained for discussion with Barry until deletion is separately
authorized.

## Validation And Acceptance

Goal 005 is accepted only when:

- focused tests cover strict inputs, pure behavior, convergence, carry-over,
  non-convergence, and body-boundary failure;
- the zero, constant, and concentrated fixtures satisfy the declared outcomes;
- measured day 1 carries into day 2 exactly;
- each measured day reduces exactly to an unchanged one-day runner call;
- the timing-equivalence claim is checked numerically rather than inferred from
  `body_energy_status`;
- every realized convergence scale and tolerance is finite and positive;
- the declared 10000 kJ body fixture completes both measured days in every
  scenario without crossing the body-reserve boundary;
- all Goal 001-004 tests pass unchanged;
- no existing body, gut, or food source or test file changes;
- `renv` remains synchronized and no dependency is added;
- the no-write experiment passes from source and an installed package;
- external build, temporary installation, and `R CMD check --no-manual` pass;
- the five review artifacts are generated and inspected;
- the complete diff and Git state remain within the authorized surface; and
- one independent final reviewer finds no material scientific, accounting,
  implementation, or scope defect.

After the core checks, perform at most one focused repair pass for material
findings. Stop when the high-value contract is satisfied; do not iterate on
cosmetic or non-decision-relevant polish.

## Planned Implementation Surface

Expected new implementation files:

```text
R/gut-body-energy-reference-cycle.R
docs/decisions/0005-repeated-day-reference-cycle.md
experiments/rebuild-005-repeated-day-reference-cycle.R
experiments/rebuild-005-review-pack.R
man/run_gut_body_energy_reference_cycle.Rd
tests/testthat/test-gut-body-energy-reference-cycle.R
```

Expected modified files:

```text
DESCRIPTION
NAMESPACE
R/herbivoreTTR-package.R
README.md
docs/goals/rebuild-005-repeated-day-reference-cycle/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
docs/variable-dictionary.md
man/herbivoreTTR-package.Rd
```

Any additional path requires a specific, documented justification. A material
scope expansion requires Barry's approval.

## Explicit Non-Goals

Goal 005 does not add:

- variable or stochastic days;
- a configurable number of measured days;
- seasons, chronic decline, recovery, or viability criteria;
- gut capacity, intake limits, digestive loss, or multiple compartments;
- time-varying food quality or multiple foods;
- feeding choice, behavior, or body-state feedback;
- dynamic body mass, protein, water, thermoregulation, or activity;
- plants, weather, space, individuals, or populations;
- empirical calibration, parameter estimation, or uncertainty analysis;
- a new dependency, object-oriented framework, or generalized simulation
  engine; or
- committed generated figures, tables, caches, or evidence bundles.

## Authority And Stop Boundary

Packet formulation authorizes only the four Goal 005 packet files.

Implementation, staging, committing, and pushing each require explicit
authority. Goal 005 execution stops after the repeated-day reference-cycle
function, fixtures, diagnostics, documentation, validation, and review pack are
complete. No later physiological or ecological layer begins automatically.
