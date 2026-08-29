# Decision 0049: Memory Recovery and Decision Horizon

Date: 2026-08-29

Status: accepted

## Question

Does the Goal 048 one-way residence arise from stale information about the
unvisited patch, a one-day decision horizon, or their interaction?

## Design

The accepted last-experience trajectory is reconstructed through day 100. The
opening day-101 animal, gut, location, and forage state is then held identical
across all comparisons. The animal is in patch B with `37,294 kJ` of body
reserve and `582 kJ` in the gut. Patch A has renewed to
`881.62 kg DM ha^-1`; patch B is at its `500 kg DM ha^-1` residual boundary.

Two information assumptions are crossed with one- and two-day horizons:

- `stale_last_experience`: patch A retains its depleted experienced return of
  `119.73 kJ` per feeding-opportunity hour; and
- `recovered_opportunity`: patch A is represented by the animal's own maximum
  previously experienced return there, `200 kJ` per feeding-opportunity hour.

The recovered value is historical animal experience, not current patch biomass
or a perfect-model forecast. Current patch B supplies `149.67 kJ` per feeding-
opportunity hour. For horizon `H`:

```text
stay score = current-patch return * (16 * H)
move score = destination return * (16 * H - 1) - 900 kJ
```

Matched full-model policies either stay in B or move to A at hour 0 of the
first day and remain there. A predeclared extension through day 7 applies only
if no full-model reversal occurs by two days.

## Observations

| Destination information | Horizon | Move-score advantage | Score action |
| --- | ---: | ---: | --- |
| Stale last experience | 1 day | -1,499 kJ | Stay |
| Stale last experience | 2 days | -1,978 kJ | Stay |
| Recovered opportunity | 1 day | -295 kJ | Stay |
| Recovered opportunity | 2 days | 511 kJ | Move |

The full-model policy comparison agrees:

| Horizon | Move-minus-stay total-system energy | Intake advantage | Route disadvantage | Preferred action |
| --- | ---: | ---: | ---: | --- |
| 1 day | -295 kJ | 605 kJ | 900 kJ | Stay |
| 2 days | 511 kJ | 1,411 kJ | 900 kJ | Move |

After one day, body reserve is `36,489 kJ` under staying and `36,049 kJ` under
moving. After two days it is `35,684 kJ` under staying and `36,049 kJ` under
moving. The two-day move closes patch A at `849.29 kg DM ha^-1` and patch B at
`523.44 kg DM ha^-1`; staying closes them at `887.17` and
`500 kg DM ha^-1`, respectively. All gut, body, forage, coupling, and whole-
system accounts close. The day-7 fallback is not invoked.

## Interpretation

The trap is an interaction. A longer horizon cannot rescue a destination that
is still believed to be poor, while recovered opportunity alone cannot repay
the route within one day. Together they are sufficient to reverse the
day-101 choice.

At this checkpoint, the transparent score matches the full model because the
experienced returns are stable over the short comparison and the route is the
only policy difference. That agreement is local evidence, not proof of a
general behavioral model.

The diagnostic light is green, but no behavior is promoted into the package.
The next design must specify the smallest transparent way for an animal to
update an unvisited patch's recovery opportunity and apply a bounded
consequence horizon without perfect biomass information, parameter tuning,
exploration, or new physiology.
