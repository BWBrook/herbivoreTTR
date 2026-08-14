# Decision 0036: One Known-Patch Feeding-Bout Choice

Date: 2026-08-14

Status: accepted in the Arc 04 closure

## Question

Can one transparent decision choose sensibly between staying and moving in the
static known-patch system without introducing a general behavioral engine?

## Rule

Hold one declared dry-matter demand proxy constant across the remaining feeding
bout. Expected acquisition is the smaller of demand and patch capacity,
multiplied by available feeding hours. Moving loses the known route duration
and pays its incremental expenditure:

```text
stay score = min(demand, current capacity) * remaining hours * energy density

move score = min(demand, destination capacity) *
             max(0, remaining hours - travel duration) * energy density
             - route expenditure
```

Move only when its score is greater beyond scale-aware arithmetic tolerance;
ties stay. Maintenance and ordinary activity are omitted because they are
common to both candidates. The score ranks actions but does not forecast
within-bout appetite feedback.

## Evidence

The fixed comparison used hour 16, eight remaining feeding-opportunity hours,
`0.020 kg DM h^-1` demand, `0.015` and `0.025 kg DM h^-1` patch capacities,
`10,000 kJ kg^-1 DM`, and a one-hour `100 kJ` route.

| Current patch | Stay score | Move score | Choice | Selected outcome | Rejected outcome |
| --- | ---: | ---: | --- | ---: | ---: |
| Limited | 1,200 kJ | 1,300 kJ | Move | -481 kJ | -800 kJ |
| Adequate | 1,600 kJ | 950 kJ | Stay | 0 kJ | -650 kJ |

Both selected actions improved the realized combined-energy result. The
limited case improved by `319 kJ`, larger than its `100 kJ` score margin,
because subsequent appetite feedback amplified the realized benefit. This is
expected and confirms that the heuristic is ordinal rather than predictive.

## Decision

Accept the rule as the operational one-choice null and close Arc 04. The
explicit spatial core now separates location, movement time, movement energy,
static acquisition heterogeneity, prescribed itinerary, and one bounded choice
without resource dynamics.

Repeated decisions, dynamic anticipation, learning, search, spatial forage
stocks, depletion, renewal, water, and multiple animals remain deferred.
