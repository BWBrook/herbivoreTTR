# Decision 0035: Static Patch Acquisition Capacity

Date: 2026-08-14

Status: accepted in the Arc 04 closure

## Question

Does the prescribed spatial system expose understandable energetic effects
when patches differ only in their fixed non-depleting acquisition capacity?

## Contract

Give each declared patch one finite, non-negative acquisition ceiling in
`kg DM h^-1`. During a stay, the opening patch supplies the ceiling applied to
appetite. During travel, acquisition is zero regardless of either endpoint.
Capacity does not deplete and has no biomass, renewal, nutritional composition,
or food-energy-density interpretation.

Patch capacity is part of the existing landscape patch table. The spatial
runner no longer accepts a redundant common acquisition schedule. This is a
pre-publication interface replacement, not a compatibility migration.

## Evidence

Equal `0.025 kg DM h^-1` patch capacities reproduced Decision 0034 exactly:
the all-stay day remained neutral at `0.320000 kg DM`, and the two-move round
trip retained `0.313494 kg DM` intake and a `-265 kJ` combined change.

The heterogeneous comparison used `0.015` and `0.025 kg DM h^-1` patches. Both
treatments moved once during hour 16, lost one feeding hour, and paid `100 kJ`.

| Treatment | First-window capacity | Second-window capacity | Intake | Combined change |
| --- | ---: | ---: | ---: | ---: |
| Limited to adequate | 0.015 | 0.025 | 0.281905 kg DM | -481 kJ |
| Adequate to limited | 0.025 | 0.015 | 0.265000 kg DM | -650 kJ |

Hourly and daily energy identities closed. The results reproduce the accepted
known-route anchor without parameter tuning.

## Interpretation

Order matters because appetite is state-dependent and acquisition is capped.
Early limitation creates demand that a later adequate patch can partly satisfy;
a later limited patch instead caps compensation after the animal has already
left the adequate patch. The result is therefore not a simple comparison of
daily mean capacity.

This establishes interpretable static heterogeneity before behavior responds
to it. Decision 0036 adds one minimal choice rule. Food-energy-density
heterogeneity, patch biomass, depletion, renewal, multi-day spatial dynamics,
search, and water remain deferred.
