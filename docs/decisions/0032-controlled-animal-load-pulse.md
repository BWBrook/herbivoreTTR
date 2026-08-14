# Decision 0032: Controlled Animal-Load Pulse

Date: 2026-08-14

Status: accepted

## Context

The homogeneous coupled reference is stable at `10 animals ha^-1`, but that
non-binding null does not show whether temporary forage pressure produces an
understandable animal response or whether the system recovers after pressure is
released.

## Design

Begin on the exact period-24 reference. Compare a constant
`10 animals ha^-1` control with a treatment comprising:

1. 7 days at `10 animals ha^-1`;
2. 60 days at `50 animals ha^-1`; and
3. 60 days restored to `10 animals ha^-1`.

Animal density is the only changed quantity. The same representative physiology
is carried across phases; density changes aggregate removal pressure rather than
the number or identity of explicit modeled animals.

The first design pilot used 40 pulse days and ended at
`537.4 kg DM ha^-1`, before the residual became binding. Exact recurrence
analysis placed the unlimited-intake crossing near pulse day 49, so the final
design was corrected once to 60 days at the unchanged pulse density. The pilot
is design evidence, not part of the reported treatment.

## Result

The control remained on its period-24 reference for all 127 days. Treatment and
control were numerically identical through day 7, and all hourly dry-matter,
coupling, and energy identities closed.

| Quantity | Reference | Load pulse | Recovery |
| --- | ---: | ---: | ---: |
| Duration | 7 days | 60 days | 60 days |
| Density | 10 animals ha^-1 | 50 animals ha^-1 | 10 animals ha^-1 |
| Opening forage | 866.7 kg DM ha^-1 | 866.7 kg DM ha^-1 | 500.0 kg DM ha^-1 |
| Closing forage | 866.7 kg DM ha^-1 | 500.0 kg DM ha^-1 | 777.3 kg DM ha^-1 |
| Mean daily intake | 0.320 kg DM | 0.304 kg DM | 0.336 kg DM |
| Stock-limited hours | 0 | 128 | 0 |
| Opening body reserve | 40,000 kJ | 40,000 kJ | 30,834 kJ |
| Closing body reserve | 40,000 kJ | 30,834 kJ | 40,000 kJ |

The stock ceiling first bound on experiment day 56, which is pulse day 49, and
remained active on 12 pulse days. Minimum daily intake was `0.239 kg DM`.
Once the forage residual became binding, body reserve continued to decline to
the pulse boundary rather than stabilizing.

Restoring reference density removed stock limitation. The appetite controller
raised mean recovery intake above the `0.320 kg DM` reference, repaying the
animal-energy deficit completely within the recovery window. Standing forage
recovered 75.6% of its displacement but remained `89.4 kg DM ha^-1` below its
reference after 60 days.

## Interpretation

The response is attributable to animal load alone. High load first depletes the
plant stock without changing animal intake; only after the residual boundary is
reached does the animal become energy-limited. Load release then separates two
timescales: existing appetite and acquisition headroom restore the animal
quickly, while the slow linear plant turnover governs forage recovery.

This is a diagnostic stress experiment, not an empirical density estimate or a
population model. It does not establish health, survival, carrying capacity, or
long-term coexistence. Density feedback, plant forcing, composition, space,
water, mortality, and multiple explicit animals remain deferred.
