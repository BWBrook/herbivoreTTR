# Decision 0052: Learned Revisit Clock

Date: 2026-08-30

Status: accepted diagnostic; carried candidate rejected

## Question

Can a familiar-territory animal use only its own experienced returns and time
since visiting a patch to avoid the Goal 050 recovery lag without receiving
current unvisited-patch biomass information?

## Design

The accepted `305`-day lower-quality-patch-A pressure treatment is unchanged.
The animal retains, for each patch, its last experienced return, its historically
experienced best return, and whole days since visit. These are the same
familiar-territory priors used in Goal 050: last returns of `160/200 kJ` per
feeding-opportunity hour and best returns of `200/250 kJ` for patches A/B.

For an unvisited patch aged `a` days, expected return is prespecified as:

```text
recovery fraction = min(a / 2, 1)

expected return =
  last return + (historical-best return - last return) * recovery fraction
```

The occupied patch uses its last experienced return. The animal applies the
accepted two-day score, paying the `900 kJ` route and losing its movement hour.
It receives no current or unvisited biomass, production, perfect forecast,
reserve trigger, fitted recovery rate, or additional behavioral state. A
matched full-model two-day evaluator is calculated from each carried state but
is never information available to the animal.

The operational cue, terminal stale-memory policy, and rejected Goal 050
turnover-rate recovery remain unchanged controls. No parameter is adjusted
after seeing the trajectory.

## Observations

| Outcome | Operational null | Goal 050 turnover | Goal 052 revisit clock |
| --- | ---: | ---: | ---: |
| Completed days | 305 | 305 | 305 |
| Switches | 8 | 7 | 83 |
| Movement expenditure | `7,200 kJ` | `6,300 kJ` | `74,700 kJ` |
| Two-day evaluator disagreements | not evaluated | 147 | 43 |
| Cumulative two-day local regret | not evaluated | `79,142 kJ` | `21,607 kJ` |
| Minimum body reserve | `36,948 kJ` | `12,355 kJ` | `9,386 kJ` |
| Closing body reserve | `38,900 kJ` | `31,146 kJ` | `10,469 kJ` |

The revisit clock moves immediately to higher-quality patch B, returns to A on
day 60, and then settles into a repeated pattern of two days in A and four days
in B. Switches are never more frequent than every two days, but their cumulative
cost is more than ten times that of the operational null. Patch B remains close
to the `500 kg DM ha^-1` residual boundary; patch A oscillates around a higher
renewed stock and closes at `744.22 kg DM ha^-1`.

All `43` two-day disagreements are false stays; none is a false move. Maximum
local regret is `511 kJ` on day 59. Consequently, every one of the candidate's
`83` moves agrees with the matched full-model two-day evaluator. Hourly and
daily forage, coupling, gut-body, and whole-system accounts close throughout,
and the candidate follows its declared bounded recovery equation exactly.

## Interpretation

The fast recovery information solves most of Goal 050's local false-stay error,
but it does not produce a satisfactory carried behavior. The candidate violates
the prespecified rapid-switching stop rule, spends `74,700 kJ` on movement, and
drives body reserve lower than the already rejected turnover-rate policy. It is
rejected without tuning.

This is not simply an overoptimistic or clairvoyant animal. Every selected move
is supported by the full two-day model from the exact carried state. The deeper
result is that a two-day objective can be locally correct yet create a poor
long-run path: the animal repeatedly harvests newly accessible forage, pays the
route again, and never grants the two-patch system a long recovery interval.
The operational null performs better partly because its slower switching
incidentally rests the unoccupied patch.

Do not add an arbitrary cooldown or tune the two-day clock. The next diagnostic
should hold one representative cycling state fixed and compare longer
consequence horizons. That will distinguish inadequate foresight from a system
in which frequent rotation is genuinely favoured even over longer periods
before another behavioral mechanism is designed.
