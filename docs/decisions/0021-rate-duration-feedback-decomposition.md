# Decision 0021: Rate-Duration Feedback Decomposition

Date: 2026-08-09

Status: implemented for ecological review; evidence only

## Context

The accepted appetite controller already raises hourly target intake from body-
and gut-energy deficits. Goal 020 separately showed that opening body deficit
can extend feeding duration. Before adding an acquisition-rate mechanism, Goal
021 asks whether these are already the two relevant animal-side intake levers
and how their recovery contributions overlap.

## Decision

Treat the existing integrated appetite controller as the model's current
deficit-responsive hourly rate mechanism. Do not add a second hunger-driven
acquisition-rate controller.

Retain the Goal 021 four-arm decomposition as evidence:

- fixed rate and fixed duration;
- responsive rate and fixed duration;
- fixed rate and responsive duration; and
- responsive rate and responsive duration.

Here, rate response means the accepted `0.05 h^-1` body and `0.10 h^-1` gut
feedbacks acting on the appetite target. Rate-off sets both gains to zero while
retaining the reference rate, opportunity gate, bounds, and non-limiting forage
ceiling. Duration response is exactly the Goal 020 once-daily rule.

## Verification And Observations

All arms begin from the same state after the accepted `800 kJ` shortfall, run
for nine recovery days, and share exact reference identity.

- With neither response, balanced external forcing preserves the `-800 kJ`
  combined deficit while gut and body energy repartition.
- Rate response alone reaches 90% recovery on day 4 and finishes at
  approximately `-1 kJ`.
- Duration response alone adds four hours on day 1. The extra `0.080 kg DM`
  supplies `800 kJ` and costs `200 kJ`, leaving exactly `-200 kJ`. The opening
  body deficit then settles below the `300 kJ` extension threshold, so no later
  hours are added and 90% recovery is not reached.
- The combined response adds the same four hours on day 1, reaches 90% recovery
  immediately, and converges to effectively zero. Its previously reported
  reference crossing remains below `7 kJ` combined and `2 kJ` in body reserve.

The prespecified interaction contrast is negative throughout, changing from
approximately `-221 kJ` on day 1 to `-599 kJ` on day 9. This is sub-additive
overlap: the isolated responses both recover portions of the same finite debt,
so their gains cannot remain independent as the combined arm approaches zero.
The combined arm is nevertheless at least as recovered as either isolated arm
on every day; the negative contrast does not mean one response causes harm.

No appetite bound or forage-acquisition ceiling binds. Extension schedules,
activity charges, state carry-over, positive body reserve, and gut, body, and
whole-system accounting are preserved.

## Interpretation

The two responses have distinct roles. Hourly appetite feedback supplies a
continuous recovery drive. The daily duration rule supplies a strong but
coarse correction and, by design, has a threshold dead band. Combining them
gives rapid recovery without persistent extra feeding, but their effects are
partly redundant because both respond to the same energy deficit.

This closes the immediate conceptual case for another deficit-responsive rate
controller. Future variation in realized acquisition rate should arise first
from an explicit environmental or effort context, not from duplicating the
existing appetite signal.

## Limits And Stop Boundary

This is one deterministic perturbation at one synthetic parameterization.
There is no alternate deficit, gain, duration threshold, recurrence, forage
ceiling, effort cost, spatial structure, depletion, vegetation, calibration, or
generalized production scheduler. The interaction is defined on daily combined
energy and is not an empirical claim about behavioral or physiological
synergy.

The retained no-write client is:

```text
```

Generated evidence remains disposable under the ignored Goal 021 output
directory. Any production promotion or environmental extension requires a
separate approved goal.
