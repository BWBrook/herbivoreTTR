# Decision 0030: Standing-To-Accessible Forage Boundary

Date: 2026-08-12

Status: accepted

## Context

Goals 028 and 029 established an exactly conserved standing-forage stock and a
stable constant-turnover reference. Later coupling needs an animal-facing
forage quantity, but introducing intake rate or herbivore removal now would
combine the plant availability decision with animal behaviour.

## Decision

For standing edible forage biomass `B` and a fixed non-negative residual
threshold `R`, define:

```text
accessible forage biomass = max(0, B - R)
```

Both quantities are biomass densities in `kg DM ha^-1`. The residual is a
boundary parameter representing edible biomass that cannot be acquired because
of aggregate structural constraints such as height or distribution. It is not
a second dynamic stock, a management target, or an empirical calibration.

The transformation is pure and vector-capable. It neither changes standing
biomass nor converts accessible biomass into a rate. This keeps plant supply
separate from animal demand and acquisition mechanics.

## Synthetic Reference

The diagnostic uses a residual threshold of `500 kg DM ha^-1` and maps the
accepted low, equilibrium, and high turnover trajectories through the boundary.
At the declared `1,000 kg DM ha^-1` equilibrium, accessible forage is therefore
`500 kg DM ha^-1`. A trajectory beginning at the threshold initially has no
accessible forage and gains access only as standing biomass recovers above it.

## Verification

| Turnover trajectory | Day 0 accessible | Day 180 accessible |
| --- | ---: | ---: |
| Low (`500 kg DM ha^-1` start) | 0.0 | 493.4 |
| Equilibrium (`1,000 kg DM ha^-1`) | 500.0 | 500.0 |
| High (`1,500 kg DM ha^-1` start) | 1,000.0 | 506.6 |

Table values are `kg DM ha^-1`. Across all three 180-day trajectories,
accessible biomass equals `max(0, B - R)`, remains between zero and standing
biomass, and leaves the accepted turnover trajectories unchanged. Focused and
full tests, all six no-write diagnostics, and an external package build/check
passed; `R CMD check --no-manual` reported `Status: OK`.

## Interpretation And Limits

The threshold creates the intended piecewise-linear null: no availability at
or below the residual and one-for-one availability above it. It deliberately
compresses many possible causes of inaccessibility into one visible assumption.

No acquisition rate, intake, depletion, regrowth response, spatial structure,
or environmental forcing has been introduced. The isolated forage arc now
meets its exit criteria. Controlled forcing is deferred, and the next stage is
the minimum non-spatial herbivore-forage coupling.
