# Decision 0054: Experienced-Adequacy Memory

Date: 2026-08-31

Status: accepted diagnostic behavior; experience-based patch-choice tranche closed

## Question

Can the animal resolve the Goal 052 rapid rotation using only its own realized
feeding return and elapsed time, without current unvisited biomass, a perfect
multi-day forecast, or an arbitrary residence constraint?

## Design

The accepted rule retains the two-day absence-to-return memory supported by
Goals 051 and 052. For each patch it stores last and historically best realized
return plus whole days since visit. Expected return in an unvisited patch moves
linearly from last to best over two absent days.

The animal also knows its reference energetic requirement. The synthetic
reference needs `3,200 kJ d^-1` across 16 feeding-opportunity hours, giving an
adequacy return of `200 kJ` per feeding-opportunity hour. At each day boundary:

1. stay if the current patch's last realized return is at least `200 kJ h^-1`;
2. otherwise compare the established two-day stay and move scores; and
3. add the cumulative energetic shortfall experienced during the current
   inadequate bout to the move-score advantage.

Daily shortfall is:

```text
max(200 - realized return, 0) * feeding-opportunity hours
```

The animal moves when the deficit-adjusted advantage is positive. The shortfall
memory resets after an adequate day or movement. Thus a small but persistent
deficit can eventually repay travel, while an adequately performing current
patch is not abandoned merely because a recently released destination has a
higher immediate return.

The rule has no current forage biomass, production, reserve trigger, explicit
bout-duration forecast, stochastic exploration, perfect counterfactual,
cooldown, or fitted behavioral coefficient. It remains an experiment-level
behavior rather than package API.

## Candidate Selection

A current-adequacy gate alone passed the baseline but became trapped under
faster forage turnover: the depleted higher-quality patch supplied about
`187 kJ h^-1`, too little for neutrality but too close to repay the route in the
fixed two-day comparison. Accumulated shortfall corrects that chronic-deficit
trap without lengthening the animal's forecast.

A one-for-one rule requiring a destination to rest as long as its preceding
residence was also tested and rejected. It forced 58-day reciprocal bouts and
crossed the reserve boundary on day 218 in the baseline because lower-quality A
could not support the residence imposed by B's history. That duration state and
its code are not retained.

## Goal 053 Checkpoints

| Day | Current to destination | Current return | Destination return | Accumulated shortfall | Raw two-day advantage | Accepted action |
| ---: | --- | ---: | ---: | ---: | ---: | --- |
| 60 | B to A | `150 kJ h^-1` | `200 kJ h^-1` | `1,260 kJ` | `511 kJ` | move |
| 62 | A to B | `200 kJ h^-1` | `250 kJ h^-1` | `0 kJ` | `450 kJ` | stay |

The day-60 departure is retained. At day 62, the raw two-day score still prefers
B, but A is demonstrably adequate, so the animal does not make the damaging
early return.

## Baseline Result

| Outcome | Goal 052 revisit clock | Accepted adequacy memory |
| --- | ---: | ---: |
| Completed days | 305 | 305 |
| Switches | 83 | 9 |
| Shortest return interval | 2 days | 27 days |
| Movement expenditure | `74,700 kJ` | `8,100 kJ` |
| Minimum body reserve | `9,386 kJ` | `36,221 kJ` |
| Closing body reserve | `10,469 kJ` | `39,962 kJ` |
| Days in A / B | 82 / 223 | 122 / 183 |

The accepted switch days are `1, 59, 98, 141, 170, 207, 234, 270, and 297`.
The trajectory uses both patches repeatedly without rapid rotation and closes
near the `40,000 kJ` reference reserve.

## Bounded Robustness

The acceptance set changes one axis at a time and is not a fitted calibration
grid.

| Scenario | Switches | Shortest interval | Minimum reserve | Closing reserve |
| --- | ---: | ---: | ---: | ---: |
| Baseline | 9 | 27 d | `36,221 kJ` | `39,962 kJ` |
| Movement `600 kJ` | 9 | 27 d | `37,099 kJ` | `39,985 kJ` |
| Movement `1,200 kJ` | 9 | 27 d | `35,413 kJ` | `39,955 kJ` |
| A quality `9,000 kJ kg^-1 DM` | 7 | 35 d | `38,273 kJ` | `40,000 kJ` |
| Equal patch quality | 6 | 46 d | `38,860 kJ` | `38,872 kJ` |
| Turnover `0.0009 h^-1` | 12 | 18 d | `35,741 kJ` | `38,246 kJ` |
| Turnover `0.00125 h^-1` | 5 | 45 d | `36,885 kJ` | `40,000 kJ` |

Every acceptance run completes 305 days, uses both patches, has no return within
seven days, retains more than `35 MJ` at its minimum, and closes all forage and
energy accounts.

An additional `0.00075 h^-1` turnover case is retained as a supply stress, not
an acceptance case. At the residual boundary its two patches jointly provide
only `3,240 kJ animal^-1 d^-1`, a movement-free margin of `40 kJ d^-1` above
maintenance. The rule eventually contracts to four-day returns, for which
travel alone averages `225 kJ d^-1`, and crosses the reserve boundary on day
304. This red result is an explicit low-supply limit rather than a hidden rule
failure or a viability claim.

## Interpretation

Goal 053 correctly identified persistence as the missing information, but an
explicit prediction of destination bout duration is unnecessary here. The
leaner solution uses demonstrated persistence: while the current patch
continues meeting energetic need, the animal stays. Once return becomes
inadequate, the magnitude and duration of the experienced deficit determine
when travel has been earned.

This is a satisficing, marginal-value-style mechanism, not a claim of optimal
foraging. It is compatible with the established principle that patch departure
depends on declining marginal return and travel cost, while avoiding the
complete environmental knowledge assumed by a formal optimum.

The experience-based patch-choice problem is closed for the present synthetic
two-patch system. Do not add a longer forecast, reserve trigger, destination-
depth state, or parameter optimization before a new ecological question earns
it. The next layer should build on this accepted behavior rather than reopen its
development history.

## Reference

Charnov, E. L. (1976). Optimal foraging, the marginal value theorem.
*Theoretical Population Biology* 9:129-136.
https://doi.org/10.1016/0040-5809(76)90040-X
