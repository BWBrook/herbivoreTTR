# Decision 0015: Canonical Repeated-Day Appetite Runner

Date: 2026-08-08

Status: implemented for ecological review

## Context

Goals 013 and 014 established a minimal appetite controller and its bounded
synthetic sensitivity, but each experiment still owned a local loop that
repeated appetite, gut, and body transitions. The science was accepted; the
remaining question was whether that repeated composition should become one
small package boundary before recurrent disturbance is studied.

## Decision

Add `run_appetite_controlled_energy_days()` as the sole canonical repeated-day
appetite path. It accepts the existing state, parameter, appetite-reference,
and routine-activity records plus `number_of_days`. One fixed 24-hour reference
and activity schedule repeats for the declared horizon.

At the public boundary, inputs are validated and canonicalized once. Each hour
then applies the unchanged appetite, gut, and body scalar equations in that
order. Closing gut and body stocks carry exactly across every hour and day.
The runner returns only an hourly ledger and daily summary; it does not
duplicate final-state objects already present in the last daily row.

Endogenous intake fields are named `realized`. The interface does not admit
day-specific forcing, callbacks, events, automatic burn-in, recurrent
disturbance, or reference-state clamping.

## Observations

The accepted numerical period-24 reference repeats for three measured days
within `1e-12` trajectory tolerance. State continuity is exact, controller
feedback and closing reference deviations remain negligible, and gut, body,
and whole-system accounts close. Tiny floating-point drift is retained rather
than hidden by resetting state to the reference.

Starting from the accepted `800 kJ` shortfall boundary reproduces the Goal 013
nine-day recovery. Daily realized intake declines from approximately `0.363`
to `0.320 kg DM`, while the rounded closing body deviation contracts from
`-439` to `-2 kJ` and the combined deviation from `-372` to `-1 kJ`.

The rewritten Goal 014 client retains all accepted results: all 27 scenarios
meet the declared stable-recovery criterion, all nine gain pairs are robust
across tested deficits, and the upper intake bound is active in 13 scenarios.
The Goal 013 and 014 experiment-local recovery loops are removed.

## Interpretation

The new runner is an architectural promotion, not a biological extension. It
creates one inspectable path for the model's already accepted endogenous-intake
dynamics and removes duplicated orchestration before a genuinely new
scientific forcing pattern is introduced.

## Limits And Next Gate

Every simulated day currently has the same reference and activity schedule.
The appetite gains, intake maximum, food density, and reference trajectory
remain synthetic, and gut energy remains a post-ingestive satiation proxy
rather than physical gut fill.

At this decision boundary, recurrent shortfall was the leading next question.
Decision 0016 subsequently inserted the missing appetite-target versus forage-
acquisition boundary before that experiment; recurrent limitation therefore
moves to the proposed Goal 017.

The retained no-write reproduction clients are:

```text
experiments/rebuild-013-minimal-endogenous-appetite-control.R
experiments/rebuild-014-appetite-controller-sensitivity.R
```
