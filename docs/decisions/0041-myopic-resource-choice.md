# Decision 0041: Myopic Resource-Choice Null

Date: 2026-08-16

Status: accepted

## Question

Can one minimally informed, animal-facing resource cue approximate the accepted
perfect-model oracle without prematurely adding memory, learning, forecasting,
or repeated decisions?

## Decision Null

At the day boundary, the animal receives a one-hour opening-state cue for its
current patch:

```text
current attainable acquisition rate
  = min(static acquisition capacity,
        opening accessible forage per represented animal / 1 hour)
```

It receives a prescribed `0.025 kg DM h^-1` expected acquisition rate for the
known destination. The existing feeding-bout choice score then projects these
rates over 16 remaining feeding-opportunity hours using fixed
`0.020 kg DM h^-1` expected demand, one hour of travel, and `900 kJ` route
expenditure. The opening cue is treated as persistent over the bout; it does
not forecast turnover, appetite, or later stock limitation.

The same `450` to `550 kg DM ha^-1` patch-A biomass grid used in Goal 040 is
evaluated at `0.5 kg DM ha^-1` spacing. Both actions are then run through the
full accepted dynamic model. The Goal 040 oracle supplies the independent
best-action benchmark, and regret is the closing combined energy forgone by
the myopic choice.

## Evidence

The myopic score has one analytic move-to-stay boundary at approximately
`500.13 kg DM ha^-1`, bracketed by the retained grid between `500.0` and
`500.5 kg DM ha^-1`. This numerical value belongs only to the synthetic
parameters. The oracle boundary remains between `497.5` and
`498.0 kg DM ha^-1`.

| Patch A opening biomass | Current cue | Myopic choice | Oracle | Myopic move advantage | Oracle move advantage | Regret | Stay stock-limited hours |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: |
| 450.0 kg DM ha^-1 | 0.000 kg DM h^-1 | Move | Move | 2,100 kJ | 2,651 kJ | 0 kJ | 16 |
| 497.5 kg DM ha^-1 | 0.000 kg DM h^-1 | Move | Move | 2,100 kJ | 35 kJ | 0 kJ | 5 |
| 498.0 kg DM ha^-1 | 0.000 kg DM h^-1 | Move | Stay | 2,100 kJ | -125 kJ | 125 kJ | 4 |
| 499.0 kg DM ha^-1 | 0.000 kg DM h^-1 | Move | Stay | 2,100 kJ | -370 kJ | 370 kJ | 2 |
| 500.0 kg DM ha^-1 | 0.000 kg DM h^-1 | Move | Stay | 2,100 kJ | -549 kJ | 549 kJ | 0 |
| 500.5 kg DM ha^-1 | 0.025 kg DM h^-1 | Stay | Stay | -1,100 kJ | -549 kJ | 0 kJ | 0 |
| 550.0 kg DM ha^-1 | 0.025 kg DM h^-1 | Stay | Stay | -1,100 kJ | -549 kJ | 0 kJ | 0 |

The rules agree at 196 of 201 grid levels. All five disagreements occur from
`498.0` through `500.0 kg DM ha^-1`: the myopic rule moves while the oracle
stays. Regret rises from `125` to `549 kJ`; the rule never stays when the oracle
moves. All 402 full counterfactuals close their patch, coupling, gut, body, and
combined-energy accounts.

## Interpretation

The approximation is simple, transparent, and conservatively biased. It reacts
correctly to severe current depletion and adequate current forage, but an
opening snapshot cannot anticipate autonomous renewal during the coming day.
It therefore leaves slightly too early near the hard residual boundary.

This is a useful result rather than a defect to hide: incomplete information
now has a localized, quantified energetic consequence. Agreement counts are
properties of the declared synthetic grid, not probabilities of correct animal
choice. The current cue is not yet accepted as a repeated behavioral policy.

Dynamic memory, learning, destination updating, uncertainty, endogenous
decision timing, repeated choice, patch-specific turnover, richer forage
composition, water physiology, weather, and chronic stress remain separate
questions.
