# Decision 0007: Routine-Activity Expenditure

Date: 2026-07-28

Status: accepted

## Context

Through Goal 006, the body ledger had one fixed synthetic maintenance
expenditure and no separable non-maintenance expenditure. The next bounded
question was whether an externally prescribed routine-activity sink could be
added to every body transition and measured runner while preserving exact gut,
body, and whole-system accounting.

The purpose is to establish an explicit accounting mechanism before considering
an ecological activity schedule. It is not to infer behavior, locomotion, or
physiology.

## Decision

Retain `maintenance_expenditure_kj_h` as the fixed synthetic maintenance
parameter. Add routine activity as a separate prescribed hourly input,
incremental to maintenance, through:

```text
new_routine_activity_expenditure_schedule(
  hour_of_day,
  prescribed_routine_activity_expenditure_kj_h
)
```

The constructor returns an exact plain 24-row data frame containing integer
`hour_of_day = 0:23`, in order, and 24 finite, non-negative expenditure rates
stored as doubles in kJ h^-1.

Require the activity schedule explicitly in every body transition and runner:

```text
step_body_energy(state, parameters, input_row, activity_row)

run_body_energy_day(
  initial_state,
  parameters,
  schedule,
  routine_activity_schedule
)

run_gut_body_energy_day(
  initial_gut_state,
  initial_body_state,
  gut_parameters,
  body_parameters,
  schedule,
  routine_activity_schedule
)

run_gut_body_energy_reference_cycle(
  initial_gut_state,
  measurement_body_state,
  gut_parameters,
  body_parameters,
  schedule,
  routine_activity_schedule,
  gut_convergence_relative_tolerance,
  max_burn_in_days
)
```

There is no default, implicit zero schedule, wrapper, compatibility interface,
option, or global setting. At the transition boundary, `activity_row` must be
exactly one schedule row and its `hour_of_day` must match the energy-input row.

For a fixed one-hour transition, let `B_t` be opening body reserve in kJ, `A_t`
already-assimilated energy entering the body in kJ, `M` maintenance expenditure
in kJ, and `R_t` prescribed routine-activity expenditure in kJ. Then:

```text
B_(t+1) = B_t + A_t - M - R_t

body-energy change =
  assimilated energy
  - maintenance expenditure
  - prescribed routine-activity expenditure
```

For opening gut stock `G_t` and prescribed gut input `I_t`, both in kJ:

```text
(G+B)_(t+1) - (G+B)_t =
  ingested available energy
  - maintenance expenditure
  - prescribed routine-activity expenditure
```

Rates in kJ h^-1 and amounts in kJ have the same numerical value only because
each transition is exactly one hour. Hourly body and coupled ledgers record the
activity rate and amount. Daily summaries record
`total_prescribed_routine_activity_expenditure_kj`. Body and whole-system
equations, residuals, and numerical tolerance scales include activity. No
redundant total-expenditure field is stored.

Routine activity changes no gut equation, ingestion, release fraction,
assimilation transfer, convergence criterion, or seven-column convergence
table. The reference-cycle runner validates and retains the activity schedule,
but applies it only during the two measured body days. Gut-only burn-in remains
activity-free because it advances no body state or body history.

## Diagnostic Interpretation

Use two Goal 007 fixtures with the Goal 006 mathematical continuous reference:

- `zero_routine_activity` prescribes 0 kJ h^-1 in every hour. It is the
  regression control and must preserve every pre-Goal-007 numerical trajectory
  on shared ledger fields.
- `four_hour_routine_activity_pulse` prescribes 50 kJ h^-1 in hours 8 through
  11, the half-open interval `[08:00, 12:00)`, and 0 kJ h^-1 otherwise. It
  removes exactly 200 kJ per measured day relative to the control.

The pulse must leave gut stocks, prescribed ingestion, assimilation, gut
accounting, and convergence exactly equal to the matched zero control. Its
timing and magnitude are an arithmetic and accounting probe, not an observed
daily activity pattern, directed movement, exercise prescription, feeding
cost, or empirical estimate.

## Rejected Alternatives

- Relabelling fixed maintenance as an empirical metabolic quantity was rejected
  because it remains a synthetic accounting baseline.
- Folding activity into maintenance was rejected because it would hide the
  incremental forcing and prevent direct counterfactual accounting.
- An implicit zero default was rejected because every caller must declare its
  forcing.
- Activity-dependent ingestion, gut release, or assimilation was rejected
  because each would add a separate mechanism.
- A behavioral state, locomotion model, or endogenous response was rejected
  because Goal 007 prescribes expenditure externally.
- A generalized expenditure taxonomy was rejected because it exceeds the
  bounded principal question.

## Consequences And Stop Boundary

Goal 007 adds one explicit prescribed input and expands body and coupled
ledgers without adding dynamic state. The zero schedule keeps the Goal 006
mathematical and ecological references numerically unchanged on shared fields;
the pulse establishes the exact additional body loss and gut invariance.

These results establish interface, arithmetic, and accounting semantics only.
They do not calibrate maintenance or activity, establish empirical realism, or
represent behavior, locomotion, thermic effect of food, exercise, total
metabolism, choice, feedback, or stochastic forcing.

Goal 008 remains a discussion gate for a later ecological day/night activity
schedule and intake rebalancing. Neither is specified, implemented, or
authorized by Goal 007.
