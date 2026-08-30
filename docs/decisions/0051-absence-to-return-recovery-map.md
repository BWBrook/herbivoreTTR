# Decision 0051: Absence-To-Return Recovery Map

Date: 2026-08-30

Status: accepted diagnostic; biomass-timescale return belief rejected

## Question

How quickly does realized feeding return recover after an animal leaves a
depleted patch, and which resource quantities track that recovery closely
enough to inform the next behavioral design?

## Design

Each destination patch starts at the accepted residual boundary of
`500 kg DM ha^-1` and recovers without herbivory under the established linear
turnover model. Prespecified absence ages are `0, 1, 2, 3, 5, 7, 10, 14, 21,
28, 42, and 60` days. Patch A retains `8,000 kJ kg DM^-1`; patch B retains
`10,000 kJ kg DM^-1`.

At every age, an identical neutral animal, gut, and body state is placed in the
other patch, which also starts at the residual boundary. Two matched full-model
policies are then run for two days:

- stay in the current patch; or
- pay the accepted `900 kJ` hour-0 route and remain in the recovered
  destination.

The comparison records standing biomass, accessible forage per represented
animal, instantaneous net production, realized destination return, and final
whole-system move advantage. It also evaluates the rejected Goal 050 belief,
which relaxes experienced return toward its historical best at the forage
turnover rate. No behavioral state is carried, fitted, or added to the package.

## Observations

| Destination | Actual return at ages 0 / 1 / 2 days | Actual route repayment | Goal 050 belief repayment | Maximum belief error |
| --- | ---: | --- | --- | ---: |
| A, `8,000 kJ kg DM^-1` | `124 / 184 / 200 kJ h^-1` | first moves at 1 day | does not move by 60 days | `77 kJ h^-1` |
| B, `10,000 kJ kg DM^-1` | `154 / 227 / 227 kJ h^-1` | moves at 0 days | first moves at 2 days | `75 kJ h^-1` |

Here and below, hourly return is per feeding-opportunity hour. Patch A's
two-day move advantage changes from `-1,858 kJ` at age 0 to `7 kJ` at age 1
and `511 kJ` at age 2. Patch B already repays travel by `58 kJ` at age 0 and by
`2,293 kJ` from age 1. Thus patch quality and the quality of the current patch
matter alongside elapsed absence.

Resource recovery is much slower than return recovery. At age 1, standing
biomass is only `511.86 kg DM ha^-1`, accessible forage is
`0.237 kg DM` per represented animal, and net production is
`0.488 kg DM ha^-1 h^-1`. At age 2 these values are `523.44 kg DM ha^-1`,
`0.469 kg DM` per animal, and `0.477 kg DM ha^-1 h^-1`. Standing biomass then
continues rising toward equilibrium through day 60, while realized return has
already reached its plateau.

All prespecified cases are finite and close their hourly and daily forage,
coupling, gut-body, and whole-system accounts. Recovery is monotonic, and the
route thresholds are bracketed directly by the prespecified ages rather than
fitted.

## Interpretation

The direct observation is that feeding return in this synthetic system
recovers over roughly one to two days, not on the roughly 29-day biomass
half-life implied by `0.001 h^-1` turnover. Standing biomass is therefore a poor
proxy for the return timescale. Instantaneous net production alone is also not
a sufficient monotonic proxy: it declines as biomass recovers while feeding
return rises and plateaus.

The most plausible mechanistic inference is that accessible forage accumulated
during absence, together with continuing production during the two-day visit,
restores short-horizon feeding opportunity long before the full standing stock
recovers. Goal 051 maps that combined response but does not manipulate those
two contributions separately, so this explanation remains an inference rather
than an identified causal partition.

Do not tune or reuse the rejected exponential return equation. The next
behavioral candidate should encode a small, learned absence-to-return
relationship or another directly interpretable opportunity cue, retain the
accepted two-day consequence horizon, and remain diagnostic until its carried
trajectory is tested.
