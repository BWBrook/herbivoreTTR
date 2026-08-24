# Decision 0040: Resource-Aware Stay-Move Boundary

Date: 2026-08-15

Status: accepted

## Question

Where does the accepted perfect-information oracle switch between moving and
staying as current-patch forage changes, and what mechanism determines that
boundary?

## Design

Patch A opening biomass alone varies from `450` to `550 kg DM ha^-1` in fixed
`0.5 kg DM ha^-1` steps. Patch B remains at the `1,000 kg DM ha^-1`
equilibrium. Location, gut and body state, acquisition capacities, turnover,
animal density, appetite, feeding opportunities, energy density, and the
`900 kJ` one-hour route are identical at every level.

At each level, the Goal 039 perfect-state, perfect-model oracle runs the same
full-day stay and move counterfactuals. Move is preferred only when its closing
combined energy is strictly higher; ties stay. This is a one-factor diagnostic,
not an animal choice rule.

## Evidence

The preference changes once. Move is favored through `497.5 kg DM ha^-1`;
stay is favored from `498.0 kg DM ha^-1`. This `0.5 kg DM ha^-1` numerical
bracket describes the synthetic experiment, not empirical precision.

| Patch A opening biomass | Oracle | Stay intake | Move intake | Intake energy gained by moving | Route cost | Move minus stay | Stay stock-limited hours |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 450.0 kg DM ha^-1 | Move | 0.000 kg DM | 0.355 kg DM | 3,551 kJ | 900 kJ | 2,651 kJ | 16 |
| 490.0 kg DM ha^-1 | Move | 0.110 kg DM | 0.355 kg DM | 2,447 kJ | 900 kJ | 1,547 kJ | 12 |
| 497.5 kg DM ha^-1 | Move | 0.262 kg DM | 0.355 kg DM | 935 kJ | 900 kJ | 35 kJ | 5 |
| 498.0 kg DM ha^-1 | Stay | 0.278 kg DM | 0.355 kg DM | 775 kJ | 900 kJ | -125 kJ | 4 |
| 500.0 kg DM ha^-1 | Stay | 0.320 kg DM | 0.355 kg DM | 351 kJ | 900 kJ | -549 kJ | 0 |
| 550.0 kg DM ha^-1 | Stay | 0.320 kg DM | 0.355 kg DM | 351 kJ | 900 kJ | -549 kJ | 0 |

At every biomass level:

```text
move minus stay energy
  = extra metabolizable intake gained by moving
    - incremental route expenditure
```

The identity closes numerically, as do all patch, coupling, gut, body, and
combined-energy accounts.

## Interpretation

The result is coherent. Movement becomes worthwhile only when remaining in
patch A loses more than `900 kJ` of metabolizable intake relative to the known
destination. Same-day autonomous renewal means the switch occurs slightly
below the `500 kg DM ha^-1` residual threshold rather than at it.

The hour-0 move always loses one otherwise open feeding hour. Under adequate
forage, subsequent appetite feedback nevertheless raises total move-day intake
to `0.355 kg DM`, compared with `0.320 kg DM` for a non-limited stay. That
recovers `351 kJ`, leaving a `549 kJ` net disadvantage rather than the full
route cost. As patch A declines, avoided stock-limited feeding hours make the
move progressively more valuable.

The underlying energetic advantage declines monotonically as patch A biomass
rises. Its plateaus and changes in slope arise from the hourly clock, two fixed
feeding windows, the hard residual boundary, and the acquisition ceiling.
Those features merit remembering, but this diagnostic gives no evidence of a
faulty or multiply switching response. The binary action necessarily changes
at one point; that is not itself emergent animal behavior.

Repeated decisions, imperfect information, memory, learning, endogenous timing,
destination uncertainty, patch-specific turnover, richer forage composition,
water physiology, weather, and chronic stress remain separate questions.
