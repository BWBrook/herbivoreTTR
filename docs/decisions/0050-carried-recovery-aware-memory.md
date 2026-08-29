# Decision 0050: Carried Recovery-Aware Memory

Date: 2026-08-29

Status: accepted diagnostic; behavioral candidate rejected

## Question

Does a transparent recovery expectation plus the accepted two-day horizon
produce a plausible carried patch-choice policy without current unvisited-
patch biomass information?

## Design

The accepted lower-quality-patch-A pressure treatment is run for `305` days.
Animal physiology, forage dynamics, density, route time, and the `900 kJ`
movement cost are unchanged. The established operational cue and failed stale
last-experience memory are retained as controls.

The new diagnostic policy stores three values per patch:

- last experienced metabolizable-energy return per feeding-opportunity hour;
- best historically experienced return; and
- whole days since the patch was last visited.

The familiar-territory priors are `160/200 kJ` per feeding-opportunity hour for
the last return in patches A/B and `200/250 kJ` for the historical best. Those
best values equal the maxima actually observed in the accepted Goal 048
trajectory and the appetite ceiling times each patch's energy density. They do
not use current biomass.

For an unvisited patch aged `a` days, expected return is:

```text
best return - (best return - last return) * (1 - 0.001)^(24 * a)
```

The occupied patch uses its last experienced return. The animal then applies
the Goal 049 two-day score:

```text
stay score = current expected return * 32 h
move score = destination expected return * 31 h - 900 kJ
```

Ties stay. The candidate receives no unvisited biomass, perfect forecast,
reserve trigger, exploration, stochasticity, or fitted recovery rate. At every
carried state, matched full-model stay and move policies over two days provide
a local evaluator, not information available to the animal and not a
separately carried oracle policy.

## Observations

| Outcome | Operational cue | Stale memory | Recovery + two days |
| --- | ---: | ---: | ---: |
| Completed days | 305 | 146 | 305 |
| Switches | 8 | 1 | 7 |
| Switch days | 40, 97, 129, 168, 195, 231, 258, 293 | 41 | 1, 60, 99, 155, 187, 247, 280 |
| Days in A / B | 138 / 167 | 40 / 106 | 104 / 201 |
| Movement expenditure | 7,200 kJ | 900 kJ | 6,300 kJ |
| Minimum body reserve | 36,948 kJ | 250 kJ | 12,355 kJ |
| Closing body reserve | 38,900 kJ | 250 kJ | 31,146 kJ |
| Closing A / B biomass | 619.56 / 634.29 | 960.77 / 500.00 | 732.19 / 500.00 kg DM ha^-1 |

The recovery-aware rule moves immediately to higher-quality B, then revisits
both patches with intervals of `32` to `60` days. It therefore removes the
one-way trap without chattering or crossing the non-negative reserve boundary.
Its body reserve nevertheless undergoes deep repeated declines and reaches its
minimum on day 280.

The carried rule disagrees with the local full-model two-day evaluator on
`147` days. Every disagreement is a false stay: the evaluator prefers moving
while the recovery belief retains the animal in its current patch. These days
form seven blocks: days 58-59, 62-98, 140-154, 157-186, 216-246, 249-279, and
305. Summed local regret is `79,142 kJ`; the maximum is `3,019 kJ` on day 279.
This sum is a diagnostic along the carried recovery-policy path, not the
performance of a separately carried oracle.

All selected days and valid one- and two-day counterfactuals close their gut,
body, forage, coupling, and whole-system accounts. The recovery calculation is
bounded by last and historical-best returns and follows the declared equation
exactly.

## Interpretation

Recovered opportunity and a two-day horizon are necessary at the Goal 049
checkpoint, but this particular way of carrying recovery is not sufficient.
Relaxing experienced *return* at the standing-biomass turnover rate makes the
destination look poor for too long. The most direct mechanistic interpretation
is that, in this model, short-horizon feeding
opportunity can recover much faster than standing biomass because same-day
production becomes accessible forage and interacts with the per-animal stock
ceiling. Return is therefore not a stock that should inherit the biomass
half-life directly. That explanation follows the current model equations but
its production and accessibility contributions were not separately decomposed
in this goal.

The candidate solves the one-way residence problem but produces an
inferior physiological trajectory and systematic false stays. It is rejected
as behavior and remains diagnostic-only. Do not tune the `0.001 h^-1` rate or
the score to rescue it. The next decision should compare a small number of
scientifically distinct, flow-aware recovery representations rather than make
incremental changes to this failed equation.
