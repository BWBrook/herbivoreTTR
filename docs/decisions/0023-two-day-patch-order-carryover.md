# Decision 0023: Two-Day Patch-Order Carry-Over

Date: 2026-08-09

Status: implemented for ecological review; evidence only

## Context

Goal 022 found a one-day sequence effect under equal exposure to adequate and
limited acquisition ceilings. Limited-then-adequate closed `124 kJ` above the
reverse order, but much of that advantage remained in the gut at midnight.
Goal 023 tests whether this was only a day-boundary partition or whether it
affects the next identical daily cycle.

## Decision

Retain one two-day evidence client that repeats all four Goal 022 schedules
with exact gut and body-state carry-over. Preserve the accepted controller,
fixed feeding duration, food, gut, maintenance, routine activity, acquisition
ceilings, and cost-free central-rest switch. Add no new model process.

## Verification And Observations

Every day-one hourly and daily result reproduces Goal 022 exactly, and every
day-two opening stock equals the preceding closing stock. Adequate-adequate
remains exactly neutral on both days. Limited-limited realizes `0.240 kg DM`
and loses `800 kJ` on each day, closing at `-1,600 kJ`. On day 2 its appetite
target reaches `0.400 kg DM` and the accepted maximum-intake bound is active
for 15 hours, but the environmental acquisition ceiling still limits all 16
feeding hours.

The mixed schedules remain distinct:

| Schedule | Day | Realized intake (kg DM) | Daily energy change (kJ) | Closing combined deviation (kJ) |
|---|---:|---:|---:|---:|
| limited then adequate | 1 | 0.292 | -276 | -276 |
| adequate then limited | 1 | 0.280 | -400 | -400 |
| limited then adequate | 2 | 0.301 | -192 | -468 |
| adequate then limited | 2 | 0.294 | -256 | -656 |

Limited-then-adequate gains another `0.006 kg DM`, or `64 kJ`, relative to the
reverse order on day 2. Its cumulative whole-system advantage therefore grows
from `124` to `188 kJ`. The new daily advantage is smaller than on day 1, so
the order effect persists but attenuates.

The closing partition also persists. The limited-then-adequate minus
adequate-then-limited contrast changes from `+228 kJ` gut and `-104 kJ` body on
day 1 to `+262 kJ` gut and `-74 kJ` body on day 2. The body-reserve disadvantage
shrinks, but the whole-system advantage remains concentrated in the gut rather
than becoming an immediate body-reserve gain.

All appetite and acquisition bounds are recorded coherently, body reserve
remains positive, and gut, body, and whole-system accounting closes.

## Interpretation

The Goal 022 ordering effect is not an arbitrary midnight snapshot. State
carry-over changes appetite on the second day and produces another advantage
for limited-then-adequate exposure, albeit a smaller one. Within-day sequence
therefore remains scientifically relevant when the same implicit patch pattern
is repeated.

Both mixed schedules still lose energy on day 2. This experiment compares
relative sequence performance; it does not establish that either schedule is
energetically viable under chronic exposure. Nor does it imply that an animal
should choose poor forage first. Patch exposure remains externally prescribed.

## Limits And Stop Boundary

The horizon is exactly two days. There is no third-day projection, recurrence
classification, endogenous choice, movement time or cost, water-source
excursion, geometry, forage stock, depletion, vegetation, calibration, or
production spatial interface.

This result is sufficient to stop repeating cost-free schedules. The next
smallest spatial rung is to discuss one prescribed energetic charge for the
implicit patch transition while holding feeding opportunity and patch order
fixed. Lost feeding time should remain a later, separate effect.

The retained no-write client is:

```text
```

Generated evidence remains disposable under the ignored Goal 023 output
directory. Any movement charge or production promotion requires a separate
approved goal.
