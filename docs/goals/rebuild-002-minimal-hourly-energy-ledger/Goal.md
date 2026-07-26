# Rebuild Goal 002: Minimal Hourly Energy Ledger

## Status

This packet defines a proposed implementation goal. Formulation creates only
the four files in this goal directory. It does not authorize physiological
implementation, staging, committing, or pushing.

## Principal Question

Can the rebuilt package execute a transparent 24-hour, maintenance-only body-
energy budget whose neutral, deficit, and surplus outcomes are analytically
predictable and whose energy accounting closes at every hourly transition and
over the complete day?

## Completed Outcome

The package contains the first executable model layer: one fixed-mass,
semi-synthetic macropod-like herbivore with a physical body-energy reserve and
24 explicit one-hour transitions. Prescribed already-assimilated energy enters
the reserve ledger directly. Fixed maintenance expenditure leaves it directly.

The implementation produces one tidy 24-row hourly ledger and one one-row
daily summary. Three compact, deterministic scenarios demonstrate exact
neutrality and known daily deficit and surplus. No food, gut, digestion,
activity, plant, behavior, mass-change, calibration, or coupling process is
implemented.

## Scientific Meaning

This goal establishes accounting correctness, transition semantics, functional
architecture, and diagnostic legibility. It does not establish a biologically
realistic maintenance requirement, a viable animal, an ecological equilibrium,
or any empirical claim about macropods.

The 50 kg reference mass is scenario metadata in this goal. It is not a model
state or transition parameter because no approved equation depends on mass.
Maintenance is supplied directly in kJ h^-1 so that an allometric or empirical
parameterization decision is not introduced implicitly.

## Accepted Approach

Three approaches were considered:

1. Implement the controlled food and gut together with the energy reserve.
   Rejected because digestive storage and delay would obscure the first test of
   body-energy accounting.
2. Use one daily transition. Rejected because it would not establish the
   approved 24-hour clock or expose off-by-one and opening/closing-state errors.
3. Implement a maintenance-only hourly ledger with prescribed assimilated
   energy. Accepted because every result can be calculated independently and
   the gut can later be inserted at one explicit boundary.

## Model Contract

### Dynamic State

The state is one exact named list:

```text
body_energy_reserve_kj
```

`body_energy_reserve_kj` is one finite, non-negative numeric scalar. The model
never clips it. A transition whose proposed closing reserve is less than zero
fails before returning a state. Zero is an accounting boundary, not a calibrated
death or viability threshold. No upper reserve capacity is introduced.

### Fixed Parameters

The parameter record is one exact named list:

```text
maintenance_expenditure_kj_h
```

`maintenance_expenditure_kj_h` is one finite, non-negative numeric scalar and
remains constant over the 24-hour run. A daily maintenance total is derived as
24 times this hourly rate; no competing daily parameter is accepted.

### Prescribed Inputs

The daily schedule is a base R data frame with exactly these columns:

```text
hour_of_day
prescribed_assimilated_energy_kj_h
```

It has exactly 24 rows. `hour_of_day` is integer `0:23`, in order, with no
duplicates. Each row labels the half-open interval `[hour_of_day,
hour_of_day + 1)`. The energy-input rate is finite and non-negative.

The schedule represents energy that is already assimilated. It is not food
intake, digestible energy, or gut outflow.

### Hourly Transition

Every transition has a fixed duration of one hour. No configurable time step is
introduced in this goal.

For hour `h`:

```text
prescribed_assimilated_energy_kj =
  prescribed_assimilated_energy_kj_h * 1 h
maintenance_expenditure_kj = maintenance_expenditure_kj_h * 1 h
net_body_energy_rate_kj_h =
  prescribed_assimilated_energy_kj_h - maintenance_expenditure_kj_h
body_energy_change_kj =
  prescribed_assimilated_energy_kj - maintenance_expenditure_kj
body_energy_reserve_end_kj =
  body_energy_reserve_start_kj + body_energy_change_kj
```

The closing reserve for hour `h` is the opening reserve for hour `h + 1`.
Inputs, parameters, and the caller's opening state are not mutated.

### Numerical Policy

Accounting residuals use one internal, scale-aware tolerance:

```text
100 * .Machine$double.eps * max(
  1,
  abs(opening or initial reserve),
  abs(closing or final reserve),
  sum(abs(prescribed assimilated energy amounts)),
  sum(abs(maintenance expenditure amounts))
)
```

The tolerance is for floating-point representation only. It must not conceal a
model discrepancy, permit a negative physical reserve, or redefine a deficit
or surplus of substantive magnitude as neutral.

### Public Functional Interface

The package exposes these functions:

```text
new_body_energy_state(body_energy_reserve_kj)
new_body_energy_parameters(maintenance_expenditure_kj_h)
new_assimilated_energy_schedule(
  hour_of_day,
  prescribed_assimilated_energy_kj_h
)
step_body_energy(state, parameters, input_row)
run_body_energy_day(initial_state, parameters, schedule)
```

State and parameter constructors return plain named lists, and the schedule
constructor returns a base R data frame. None uses S3, S4, R6, or
reference-class behavior. `input_row` is exactly one row from the validated
schedule and retains its two exact columns and types.

`step_body_energy()` returns this exact nested plain-list structure:

```text
state
  body_energy_reserve_kj
fluxes
  prescribed_assimilated_energy_kj
  maintenance_expenditure_kj
  net_body_energy_rate_kj_h
  body_energy_change_kj
  energy_balance_residual_kj
```

`run_body_energy_day()` returns one plain list with exact `hourly` and `daily`
data frames. The daily result is derived from the hourly ledger rather than
from hidden state.

## Exact Outputs

The hourly ledger has exactly 24 rows and these columns:

```text
hour_of_day
time_start_h
time_end_h
body_energy_reserve_start_kj
prescribed_assimilated_energy_kj_h
maintenance_expenditure_kj_h
net_body_energy_rate_kj_h
prescribed_assimilated_energy_kj
maintenance_expenditure_kj
body_energy_change_kj
body_energy_reserve_end_kj
energy_balance_residual_kj
```

The daily summary has exactly one row and these columns:

```text
body_energy_reserve_initial_kj
total_prescribed_assimilated_energy_kj
total_maintenance_expenditure_kj
expected_body_energy_change_kj
observed_body_energy_change_kj
body_energy_reserve_final_kj
energy_balance_residual_kj
energy_status
```

For each hourly row:

```text
energy_balance_residual_kj =
  (body_energy_reserve_end_kj - body_energy_reserve_start_kj) -
  body_energy_change_kj
```

For the daily row:

```text
expected_body_energy_change_kj =
  total_prescribed_assimilated_energy_kj -
  total_maintenance_expenditure_kj
observed_body_energy_change_kj =
  body_energy_reserve_final_kj - body_energy_reserve_initial_kj
energy_balance_residual_kj =
  observed_body_energy_change_kj - expected_body_energy_change_kj
```

`energy_status` is `neutral` when
`abs(observed_body_energy_change_kj) <= tolerance`, `deficit` when the observed
change is less than `-tolerance`, and `surplus` when it is greater than
`tolerance`.

No CSV, RDS, figure, dashboard, evidence bundle, cache, or persistent output is
created. The thin experiment constructs the fixtures, asserts their expected
values in memory, and then prints the compact summaries; stdout is its only
side effect. It may attach `scenario_id` and `body_mass_ref_kg = 50` to its
printed copy of the three daily rows; those labels are experiment metadata and
are not columns in either core output schema.

## Analytical Scenarios

The experiment identifies the demonstration animal as a 50 kg
semi-synthetic macropod-like herbivore in scenario metadata. The core function
does not consume that value. All three scenarios use:

```text
body_energy_reserve_kj = 5000
maintenance_expenditure_kj_h = 100
```

The fixtures are arithmetic examples, not empirical parameter estimates.

| Scenario | Input, each hour | Expected daily change | Expected closing reserve |
| --- | ---: | ---: | ---: |
| neutral | 100 kJ h^-1 | 0 kJ | 5000 kJ |
| deficit | 90 kJ h^-1 | -240 kJ | 4760 kJ |
| surplus | 110 kJ h^-1 | +240 kJ | 5240 kJ |

For all three, every hourly residual and the daily residual are zero within the
documented tolerance. The neutral fixture must be exactly unchanged with these
integer-valued quantities.

## Validation And Tests

Tests must demonstrate:

- exact record names and fail-fast rejection of missing, extra, non-scalar,
  non-finite, wrongly signed, or wrongly typed values;
- exact 24-row schedule ordering and rejection of missing, repeated, or
  displaced hours;
- the `[h, h + 1)` row convention, including first-hour opening state,
  final-hour closing state, and continuity between consecutive rows;
- no mutation of caller-supplied state, parameters, or schedule;
- hourly and daily energy conservation;
- exact analytical outcomes for the neutral, deficit, and surplus fixtures;
- a daily-neutral schedule with 12 hours at 0 kJ h^-1 followed by 12 hours at
  200 kJ h^-1, which reaches 3800 kJ before returning exactly to 5000 kJ;
- a nonconstant schedule with maintenance 80 kJ h^-1 and prescribed input
  `60 + hour_of_day` kJ h^-1, which closes at exactly 4796 kJ;
- preservation of the daily endpoint but not necessarily the hourly trajectory
  when a feasible input schedule is permuted;
- fail-fast rejection of a transition that would make reserve negative rather
  than clipping or silently continuing;
- exact output row counts, column names, and status values; and
- unchanged package validity under the full test suite, synchronized `renv`,
  external `R CMD build`, and external `R CMD check --no-manual`.

## Documentation Changes

Execution updates the model charter, model specification, variable dictionary,
roadmap, README, and package documentation to distinguish:

1. the implemented maintenance-only energy ledger;
2. the still-future controlled-food and gut stock-flow layer; and
3. all later physiological and ecological layers.

A decision record explains why the energy ledger was implemented before the
gut. Implementation follows this approved contract without reading, comparing,
or copying material from the ignored legacy tree.

## Exclusions

This goal excludes:

- food mass, food quality, gut content, gut capacity, passage, digestion, and
  assimilation calculations;
- activity expenditure, movement, behavior, hunger, and feeding decisions;
- dynamic body mass, reserve-to-mass conversion, condition indices, mortality,
  reproduction, protein, water, thermoregulation, and waste;
- plants, space, weather, seasons, individuals, populations, and coupling;
- allometry, literature calibration, parameter fitting, uncertainty analysis,
  simulation studies, legacy comparison, compatibility layers, and release
  machinery; and
- persistent generated outputs or evidence.

## Review Surface

Review is limited to the goal packet, complete tracked-and-untracked package
diff, public function interfaces, exact hourly and daily tables, the three
printed scenario summaries, test results, external package check log, and final
Git state. No bulky artifact is part of review.

## Authority And Stop Rule

Execution requires Barry's explicit authorization after packet review. Unless
that authorization also says otherwise, it permits implementation and local
validation but not commit or push.

Authorization is bound to the SHA-256 identities of `Goal.md`, `Plan.md`, and
`Runbook.md` reported at packet closeout. Those three files become read-only
control surfaces during execution. `Log.md` may record execution evidence. Any
hash mismatch stops execution and requires renewed review and authorization.

Stop before implementation on any unexpected dirty path or changed upstream.
After implementation begins, stop on any scientific ambiguity that would
change the accepted equations or interpretation, any request for an additional
dependency, any failed validation, any persistent generated output, or any
scope expansion toward the gut or later layers.

Completion stops after the reviewed Goal 002 closeout. Do not formulate or
implement the gut layer until Barry and the Herbivore TTR orchestrator discuss
the result.
