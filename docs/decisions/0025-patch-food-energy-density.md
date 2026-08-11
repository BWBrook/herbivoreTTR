# Decision 0025: Patch Food-Energy Density

Date: 2026-08-11

Status: implemented for ecological review; evidence only

## Context

Goals 022 through 024 varied forage acquisition and movement while retaining
one fixed metabolizable energy density. Goal 025 isolates a second static
environmental property: the energy supplied by each kilogram of dry matter.

## Decision

Retain one one-day evidence diagnostic with adequate quality at
`10,000 kJ kg DM^-1` and lower quality at `8,000 kJ kg DM^-1`. Compare
adequate-adequate, lower-lower, lower-adequate, and adequate-lower schedules
across the accepted two feeding windows. Keep acquisition non-limiting,
movement cost-free, and every animal-side process unchanged.

Treat density as already metabolizable. Do not infer gross energy,
digestibility, protein, fibre, water, or assimilation efficiency from this
single synthetic property.

## Verification And Observations

The adequate-adequate client reproduces the canonical appetite, intake, gut,
body, and accounting trajectory exactly: `0.320 kg DM`, `3,200 kJ`, and neutral
combined energy.

The four daily outcomes are:

| Quality sequence | Realized intake (kg DM) | Ingested energy (kJ) | Closing combined deviation (kJ) |
|---|---:|---:|---:|
| adequate then adequate | 0.320 | 3,200 | 0 |
| lower then lower | 0.348 | 2,788 | -412 |
| lower then adequate | 0.337 | 3,032 | -168 |
| adequate then lower | 0.330 | 2,956 | -244 |

Under lower quality throughout, fixed reference intake would supply only
`2,560 kJ`. Appetite feedback raises dry-matter intake by approximately
`0.028 kg DM` and recovers about `228 kJ`, but it does not restore neutrality
within the day. Neither the physiological maximum nor the acquisition ceiling
binds. Compensation is incomplete because demand builds gradually after the
energy deficit appears, not because intake capacity is exhausted.

The equal-exposure mixed schedules differ by order. Lower-then-adequate
realizes an additional `0.008 kg DM` and `76 kJ` relative to
adequate-then-lower. Encountering lower quality first raises appetite before
the adequate-quality second window. At day close the contrast is `+129 kJ` in
the gut and `-53 kJ` in body reserve, leaving the same `+76 kJ` whole-system
advantage. As in earlier order diagnostics, much of the advantage remains
unassimilated at midnight.

All arms retain 16 feeding hours, `800 kJ` routine activity, non-limiting
acquisition, positive body reserve, and closed gut, body, and whole-system
accounting.

## Interpretation

Patch food quality is a coherent environmental axis distinct from acquisition
capacity. The animal compensates for lower energy density by eating more dry
matter, but the current appetite feedback is neither anticipatory nor
instantaneous. Exposure order therefore matters even when total time at each
quality is identical.

The result does not establish an empirical forage-quality range or macropod
response. It shows how the accepted controller and gut stock-flow system react
to one transparent synthetic contrast.

## Limits And Stop Boundary

This is one day, two fixed densities, non-limiting access, and cost-free
switching. There is no third quality, quality-access interaction, movement,
multi-day exposure, protein, fibre, digestibility, assimilation efficiency,
forage stock, depletion, vegetation, calibration, or production density
schedule.

The evidence client is sufficient for this single question; a production API
is not yet warranted. The next smallest environmental test should cross
adequate versus limited acquisition with adequate versus lower energy density
in four homogeneous one-day environments. That would determine whether access
limits the compensatory dry-matter response before spatial order is added.

The retained no-write client is:

```text
experiments/rebuild-025-patch-food-energy-density.R
```

Generated evidence remains disposable under the ignored Goal 025 output
directory. Any quality-access factorial or production promotion requires a
separate approved goal.
