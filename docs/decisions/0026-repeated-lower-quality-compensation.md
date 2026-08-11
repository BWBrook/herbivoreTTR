# Decision 0026: Repeated Lower-Quality Compensation

Date: 2026-08-11

Status: implemented for ecological review; evidence only

## Context

Goal 025 showed that the reactive appetite controller partly compensates for
lower metabolizable energy density within one day, but closes `412 kJ` below
the adequate-quality reference. Goal 026 tests whether exact state carry-over
allows that existing response to restore daily balance over repeated exposure
without adding food-quality anticipation or learning.

## Decision

Retain one 10-day, two-arm diagnostic comparing homogeneous adequate-quality
forage at `10,000 kJ kg DM^-1` with homogeneous lower-quality forage at
`8,000 kJ kg DM^-1`. Keep acquisition non-limiting, movement cost-free, food
inexhaustible, and every accepted animal-side process unchanged.

Assess whether the lower-quality arm recovers at least 90% of its day-one daily
shortfall by day 10. This threshold describes operational compensation within
the synthetic model; it is not an empirical acclimation criterion.

## Verification And Observations

Every adequate-quality day exactly reproduces the accepted reference:
`0.320 kg DM`, `3,200 kJ`, and zero daily or accumulated energy deviation.
Lower-quality day 1 exactly reproduces Goal 025.

The lower-quality trajectory is:

| Day | Realized intake (kg DM) | Ingested energy (kJ) | Daily change (kJ) | Closing combined deviation (kJ) |
|---:|---:|---:|---:|---:|
| 1 | 0.348 | 2,788 | -412 | -412 |
| 2 | 0.376 | 3,006 | -194 | -606 |
| 3 | 0.388 | 3,103 | -97 | -703 |
| 4 | 0.394 | 3,151 | -49 | -751 |
| 5 | 0.397 | 3,176 | -24 | -776 |
| 10 | 0.400 | 3,199 | -1 | -799 |

The daily shortfall falls by 94% by day 5 and 99.8% by day 10, passing the
prespecified 90% criterion on day 5. Neither the physiological upper-bound
flag nor the acquisition-ceiling flag activates: the appetite target approaches
the common `0.025 kg DM h^-1` limit from below.

Daily stabilization does not repay the accumulated deficit. Closing combined
energy approaches approximately `-800 kJ`; by day 10 this is almost entirely a
body-reserve deviation (`-799 kJ`), while the gut deviation is below `1 kJ`.
All state carry-over is exact, body reserve remains positive, and gut, body,
and whole-system accounting close.

## Interpretation

The accepted reactive controller is sufficient to arrest continuing decline
under this persistent lower-quality environment. Direct anticipatory appetite
is therefore not required for daily energetic stability.

However, the animal stabilizes in a depressed energetic state rather than
returning to its original reserve. This follows from the chosen boundary:
`0.400 kg DM day^-1` at `8,000 kJ kg DM^-1` supplies `3,200 kJ`, exactly the
accepted daily maintenance-plus-activity expenditure. Once intake approaches
that value, there is effectively no feeding-rate headroom within the fixed
16-hour schedule to repay the transient loss. Unused clock hours remain a
potential duration response. The result is a stable offset, not chronic decline
and not evidence that the reactive controller is faulty.

An animal already familiar with this forage might begin near the compensated
intake instead of experiencing the transient. Representing such familiarity
would require a separately justified learned cue, quality-conditioned
reference, or equilibrated initialization; Goal 026 does not choose among
those mechanisms.

## Limits And Stop Boundary

This is one abrupt reference-to-lower-quality transition, two synthetic
densities, 10 fixed days, 16 feeding hours, and no environmental variation.
The lower density deliberately lies at the current daily intake-capacity
boundary. The result does not estimate real forage quality, acclimation time,
gut fill, macropod intake capacity, or physiological reserve recovery.

The retained no-write client is:

```text
```

Generated evidence remains disposable under the ignored Goal 026 output
directory. No production schedule, controller change, anticipation, longer
horizon, access-by-quality factorial, movement, nutrient process, depletion,
or vegetation is authorized by this decision.

## Next Recommended Question

Before adding a new anticipatory mechanism, test whether the already accepted
deficit-responsive feeding-duration response creates enough intake headroom to
repay the reserve loss under persistent lower-quality forage. Compare fixed
versus responsive duration over the same 10-day lower-quality exposure, with
the adequate fixed-duration reference retained as an anchor. This would reuse
an established mechanism and distinguish eating longer from knowing food
quality in advance.
