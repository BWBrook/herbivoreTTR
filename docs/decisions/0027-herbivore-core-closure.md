# Decision 0027: Herbivore-Core Closure

Date: 2026-08-11

Status: current herbivore-core stage closed; duration rule remains evidence only

## Context

Goal 026 showed that reactive appetite rate nearly restores daily energetic
balance under persistent lower-quality forage, but leaves an approximately
`800 kJ` reserve offset because the fixed 16-hour schedule provides no rate
headroom for repayment. Goal 027 tests whether the already accepted bounded
feeding-duration response closes that gap before the current herbivore stage
is frozen.

## Decision

Retain one 10-day, three-arm closure diagnostic:

- adequate quality with fixed duration;
- lower quality with fixed duration; and
- lower quality with the unchanged Goal 020 duration response.

The duration rule decides once from opening body-reserve deficit, adds one
symmetric hour pair per complete `300 kJ` deficit, permits at most four added
hours, keeps hours 10 through 13 closed, and charges `50 kJ` activity per added
feeding hour. It remains a transparent synthetic probe, not a calibrated or
production behavioural scheduler.

## Verification And Observations

Both fixed-duration arms exactly reproduce Goal 026. Responsive day 1 also
exactly reproduces lower-quality fixed day 1 because the animal opens at the
reference body reserve and receives no extension.

From day 2 onward, the responsive arm adds one two-hour pair each day:

```text
extra feeding hours by day: 0,2,2,2,2,2,2,2,2,2
```

The four-hour bound is never reached. Opening body deficit remains between
`342` and `429 kJ`, enough for one pair but not two. The comparison closes as:

| Arm | Day-10 intake (kg DM) | Day-10 input (kJ) | Day-10 activity (kJ) | Day-10 daily change (kJ) | Day-10 combined deviation (kJ) |
|---|---:|---:|---:|---:|---:|
| adequate fixed | 0.320 | 3,200 | 800 | 0 | 0 |
| lower fixed | 0.400 | 3,199 | 800 | -1 | -799 |
| lower responsive | 0.412 | 3,300 | 900 | 0 | -476 |

Responsive duration improves the closing state by `323 kJ` relative to fixed
lower quality, but it does not meet the prespecified reserve-restoration
criterion. Its day-10 deficit (`476 kJ`) remains larger than the initial
Goal 026 day-one loss (`412 kJ`), giving a restoration fraction of `-15.5%`.
The 90% threshold is never crossed.

No physiological intake bound or acquisition ceiling activates. Body reserve
remains positive, extension hours and activity charges follow the accepted
contract, state carry-over is exact, and gut, body, and whole-system accounting
close.

## Interpretation

Feeding longer is beneficial but does not restore the original reserve under
this rule. The responsive arm approaches approximately `3,300 kJ` intake
against `2,400 kJ` maintenance and `900 kJ` activity, so its daily balance
approaches zero around a depressed state. The rule itself needs a body deficit
of at least `300 kJ` to keep an extension pair active; it therefore creates a
non-zero control point rather than driving reserve back to its reference.

This is not a numerical failure and should not be tuned away. It demonstrates
the consequence of the prespecified discrete response. The current animal can
maintain a neutral reference, expose coherent transient and chronic deficits,
increase intake rate and duration within bounds, and propagate environmental
constraints into transparent gut and body-energy outcomes. That is sufficient
for the intended minimal herbivore core.

## Stage Closure

The current herbivore-core stage closes here. No further herbivore mechanism
is required before constructing the isolated plant-forage subsystem. The
accepted core and its limits are summarized in:

```text
docs/arcs/01-herbivore-core.md
```

The duration rule, implicit patches, movement decomposition, recurrence
screens, and variable food quality remain evidence clients around the small
production package. Closing the stage does not promote them into generalized
runtime machinery.

Important extensions remain scientifically relevant rather than rejected:

- food composition and digestibility;
- protein and water balance;
- thermoregulation and weather-dependent expenditure;
- physical gut fill and passage constraints;
- learned or anticipatory food-quality responses;
- dynamic mass feedback, tissue allocation, reproduction, survival, and
  individual variation.

They are deferred until a coupled-system or explicit research question makes
their inclusion decision-relevant.

## Stop Boundary And Next Stage

Do not tune the duration thresholds, add another appetite mechanism, extend
the horizon, or seek reserve restoration merely to improve this result. The
next development stage is a plant-forage model run in isolation, beginning
with the smallest auditable biomass stock-flow system under constant forcing.

The retained no-write client is:

```text
```

Generated evidence remains disposable under the ignored Goal 027 output
directory. Plant implementation, coupling, spatial structure, commit, and push
require separate authority.
