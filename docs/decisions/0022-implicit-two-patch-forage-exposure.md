# Decision 0022: Implicit Two-Patch Forage Exposure

Date: 2026-08-09

Status: implemented for ecological review; evidence only

## Context

Goal 021 established the accepted appetite-rate response as the current
animal-side intake controller. Goal 022 asks the smallest environmental
question that can follow it: whether prescribed exposure to two static,
non-depleting forage contexts changes intake when the contexts differ only in
their hourly acquisition ceiling.

## Decision

Retain one evidence-only, one-day two-patch diagnostic. Use the accepted
feeding windows, appetite controller, gut and body dynamics, and fixed routine
activity. Define an adequate ceiling of `0.025 kg DM h^-1` and a limited
ceiling of `0.015 kg DM h^-1`, with a cost-free implicit switch during the
central rest block.

Compare adequate-adequate, limited-limited, limited-adequate, and
adequate-limited schedules. The two mixed schedules each provide eight open
hours in each patch and the same aggregate ceiling capacity of `0.32 kg DM`.
Patch labels and schedules remain experiment evidence, not production spatial
state.

## Verification And Observations

The homogeneous anchors are exact. Adequate-adequate reproduces the accepted
non-binding reference trajectory and closes at `0 kJ` combined deviation.
Limited-limited reproduces the Goal 016 binding day: `0.240 kg DM` realized
intake, 16 binding hours, and `-800 kJ` combined deviation.

Both mixed schedules bind for eight hours, but their order matters:

| Schedule | Realized intake (kg DM) | Closing gut deviation (kJ) | Closing body deviation (kJ) | Closing combined deviation (kJ) |
|---|---:|---:|---:|---:|
| limited then adequate | 0.292 | 48 | -324 | -276 |
| adequate then limited | 0.280 | -180 | -220 | -400 |

Limited-then-adequate therefore acquires an additional `0.012 kg DM`, or
`124 kJ`, despite identical aggregate patch exposure. Its early limitation
raises the appetite target before the later adequate window, where the higher
ceiling permits extra acquisition. Whole-system energy is consequently
`124 kJ` higher at day close.

The immediate body-reserve contrast is nevertheless `-104 kJ`: the
limited-then-adequate schedule closes with `228 kJ` more energy still in the
gut. This is delayed stock-flow partitioning, not an energetic contradiction
or an immediate body-condition benefit. Gut, body, and whole-system accounting
close, body reserve remains positive, and no appetite bound binds.

## Interpretation

This is the first useful implicit spatial result. The appetite and gut dynamics
make temporal ordering consequential even when total patch exposure and
nominal acquisition capacity are identical. It justifies retaining within-day
patch sequence when spatial realism is later introduced.

It does not show habitat choice, preference, learning, movement, or a general
advantage of encountering poor forage first. Exposure is prescribed and the
result is conditional on this one synthetic day and parameterization.

## Limits And Stop Boundary

There is no repeated exposure, recovery, endogenous location choice, switching
time, movement cost, water-source excursion, geometry, forage stock,
depletion, vegetation, calibration, or production spatial interface. The next
scientific question should first test whether the closing gut/body partition
persists or reverses on a second identical day; adding travel cost at the same
time would confound carry-over with movement expenditure.

The retained no-write client is:

```text
experiments/rebuild-022-implicit-two-patch-forage.R
```

Generated evidence remains disposable under the ignored Goal 022 output
directory. Any repetition or production promotion requires a separate
approved goal.
