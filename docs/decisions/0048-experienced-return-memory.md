# Decision 0048: Experienced-Return Memory

Date: 2026-08-29

Status: accepted

## Question

Does one patch-specific memory of experienced intake return correct the
operational daily choice errors exposed by the biomass-quality interaction?

## Design

The accepted Goal 047 lower-quality-patch-A treatment is repeated without
changing animal physiology, forage turnover, density, route time, route cost,
or the requested `305`-day horizon. The operational null remains the control.

The comparison rule holds one remembered metabolizable-energy return for each
patch, in `kJ` per feeding-opportunity hour. Initial memories use the established
fixed-demand expectation: `160 kJ h^-1` for patch A and `200 kJ h^-1` for patch
B. After each day, the occupied patch's memory is replaced by that day's
realized ingested energy divided by its actual feeding-opportunity hours. The
unvisited patch's memory is unchanged.

At the next day boundary:

```text
stay score = current-patch remembered return * 16 h
move score = destination remembered return * 15 h - 900 kJ
```

The rule stays on ties. It has no biomass observation, renewal forecast,
forgetting, exploration, reserve trigger, multi-day horizon, or full-model
foresight. The full stay and move simulations remain a local one-day oracle,
not information available to the animal.

## Observations

| Outcome | Operational null | Last-experience memory |
| --- | ---: | ---: |
| Requested days | 305 | 305 |
| Completed days | 305 | 146 |
| Terminal day | none | 147 |
| Switches | 8 | 1 |
| Switch days | 40, 97, 129, 168, 195, 231, 258, 293 | 41 |
| Foraging days in A / B | 138 / 167 | 40 / 106 |
| Movement expenditure | 7,200 kJ | 900 kJ |
| Local one-day oracle disagreements | 7 | 2 |
| Summed local one-day regret | 2,919 kJ | 1,333 kJ |
| Minimum body reserve | 36,948 kJ | 250 kJ |
| Closing body reserve | 38,900 kJ | 250 kJ |
| Closing patch A biomass | 619.56 kg DM ha^-1 | 960.77 kg DM ha^-1 |
| Closing patch B biomass | 634.29 kg DM ha^-1 | 500.00 kg DM ha^-1 |

The operational trajectory reproduces Goal 047 exactly. The memory rule stays
in A while the one-day oracle moves on days 39 and 40, then moves on day 41.
Its stored return for A is then `119.73 kJ` per feeding-opportunity hour.

While the animal remains in B, B reaches the residual boundary and supplies a
stable experienced return of `149.67 kJ` per feeding-opportunity hour through
same-day turnover. Patch A renews unobserved, but its stored value remains
`119.73`. The resulting scores favour staying by about `1,499 kJ` each day:

```text
stay in B = 149.67 * 16       = 2,395 kJ
move to A = 119.73 * 15 - 900 =   896 kJ
```

On day 146, staying leaves `250 kJ` in body reserve and moving would cross the
non-negative reserve boundary. On day 147, neither action preserves a
non-negative reserve, so the diagnostic stops rather than inventing a negative
animal state. All valid counterfactuals close their forage and energy accounts.

## Interpretation

The simplest memory hypothesis is not sufficient. It removes the four early
returns to lower-quality A only by preventing every return: a depleted last
experience becomes stale while the unvisited patch renews. This is a structural
information limitation, not evidence against ecological memory in general.

The comparison also falsifies a tempting evaluation shortcut. The memory rule
has fewer local oracle disagreements and lower summed one-day regret, yet its
long-run physiological outcome is far worse. A one-day oracle can rationally
prefer the renewable current patch while failing to represent the benefit of
paying a route cost to improve subsequent days. Local regret is useful for
diagnosing individual choices but is not a long-run policy score.

The amber light therefore remains. Do not promote this memory rule to package
behavior or tune its update rate. Before the next ecological layer, a separate
decision should identify the smallest transparent representation of both
unvisited-patch recovery and consequences beyond the current day. Candidate
mechanisms include memory age plus an explicit recovery expectation, bounded
exploration, a body-state trigger, or a short multi-day horizon; their scientific
assumptions should be compared before implementation.
