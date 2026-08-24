# Decision 0037: Prescribed Water-Source Excursion

Date: 2026-08-14

Status: accepted

## Question

Can the accepted spatial model represent a mandatory daily water-source trip
and separate movement expenditure from lost feeding opportunity before water
physiology is introduced?

## Design

One synthetic animal starts at an adequate non-depleting forage patch. A named
water-source patch has zero food acquisition and is connected by reciprocal
one-hour routes. Three otherwise identical days prescribe no trip, a two-leg
trip at hours 8 and 9 when feeding is closed, or the same trip at hours 6 and 7
when feeding is open. Each leg adds `900 kJ` incremental expenditure.

The route value is a physiologically ratio-informed synthetic scale, not a
macropod parameter estimate. Red kangaroo level hopping has been measured at
about ten times resting metabolic rate; scaling that ratio to the current
`100 kJ h^-1` synthetic maintenance rate implies about `900 kJ h^-1`
incremental movement expenditure. Absolute empirical calibration is deferred
because the entire energy reference remains synthetic.

Primary locomotion anchors:

- Dawson, T. J. and Taylor, C. R. (1973), *Nature* 246:313-314,
  <https://doi.org/10.1038/246313a0>.
- Kram, R. and Dawson, T. J. (1998), *Comparative Biochemistry and Physiology
  Part B* 120:41-49, <https://doi.org/10.1016/S0305-0491(98)00022-4>.

## Evidence

| Treatment | Movement cost | Feeding time lost | Intake | Gut change | Body change | Combined change |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| No excursion | 0 kJ | 0 h | 0.32 kg DM | 0 kJ | 0 kJ | 0 kJ |
| Off-window excursion | 1,800 kJ | 0 h | 0.36 kg DM | 180 kJ | -1,580 kJ | -1,400 kJ |
| Within-window excursion | 1,800 kJ | 2 h | 0.32 kg DM | 176 kJ | -1,976 kJ | -1,800 kJ |

Both excursions make exactly two moves and return to the forage patch. Hourly
and daily energy identities close. The off-window animal acquires `0.04 kg DM`
above reference through appetite compensation, offsetting `400 kJ` of travel
cost. In the within-window treatment, the extra acquisition instead replaces
the `0.04 kg DM` missed during travel, leaving daily intake at reference and the
route cost unoffset. It therefore ends `400 kJ` lower.

## Interpretation

The expected ordering is recovered and the timing effect is attributable. The
scenario is a movement-and-opportunity null, not a claim that the animal can
benefit from visiting water. Thirst, drinking duration or benefit, hydration,
water balance, thermoregulation, route choice, depletion, renewal, and chronic
decline remain deferred.
