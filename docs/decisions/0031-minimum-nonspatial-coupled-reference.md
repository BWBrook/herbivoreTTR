# Decision 0031: Minimum Non-Spatial Coupled Reference

Date: 2026-08-13

Status: accepted

## Context

The herbivore core and isolated forage core each have an understood reference.
The first coupled rung must connect their dry-matter flows without introducing
spatial behaviour, environmental forcing, or a population model.

## Scaling Decision

Represent animal load as a fixed density `D` in animals per hectare. One focal
physiology stands for every represented animal; this is an aggregate removal
multiplier, not a collection of explicit individuals.

For one-hour realized intake `q` per represented animal:

```text
herbivory removal = q * D
```

The left side is `kg DM ha^-1`; `q` is `kg DM animal^-1` over the one-hour
interval; and `D` is `animals ha^-1`. Rate-limited intake and one-hour intake
amount remain separately named even though their values match on the hourly
clock.

## Hourly Coupling Decision

Apply autonomous forage turnover first. Then derive accessible forage above the
residual threshold and divide it by `D` to obtain the one-hour stock ceiling per
represented animal. Realized intake is the minimum of appetite, the existing
external acquisition-rate ceiling, and this stock ceiling.

The same realized dry matter is removed from forage on the declared density
basis and converted to energy entering the gut. Herbivory cannot remove the
residual forage. Allowing same-hour autonomous production to enter the
availability calculation is an explicit hourly integration convention, not a
claim about sub-hour causal timing.

## Checkpoint Verification

With `D = 10 animals ha^-1` and no autonomous plant fluxes:

| Checkpoint | Candidate intake | Realized intake | Removal | Closing forage |
| --- | ---: | ---: | ---: | ---: |
| Non-binding removal | 0.020 | 0.020 | 0.200 | 999.8 |
| Binding residual boundary | 0.020 | 0.010 | 0.100 | 500.0 |

Intake values are `kg DM animal^-1` over one hour; removal and forage are
`kg DM ha^-1`. The binding case starts at `500.1 kg DM ha^-1` with a
`500 kg DM ha^-1` residual. Both dry-matter identities close exactly.

A zero-intake coupled run reproduces the standalone constant-turnover forage
trajectory exactly.

## Constant Coupled Reference

The synthetic reference retains `B* = 1,000 kg DM ha^-1`, `tau = 0.001 h^-1`,
the `500 kg DM ha^-1` residual, and the accepted animal schedule. With
`D = 10 animals ha^-1`, its exact period-24 forage opening was calculated from
the linear hourly recurrence and run for two consecutive days.

| Quantity | Reference result |
| --- | ---: |
| Mean standing forage | 866.7 kg DM ha^-1 |
| Within-day standing-forage range | 866.1-867.2 kg DM ha^-1 |
| Per-animal daily intake | 0.32 kg DM |
| Daily herbivory removal | 3.2 kg DM ha^-1 |
| Daily animal energy change | 0 kJ |
| Stock-limited hours | 0 |

The exact periodic opening is `866.665 kg DM ha^-1`. The two forage trajectories
match numerically, forage begins and ends each day at the same state, gut state
remains period-24, body-energy balance is neutral, and hourly and daily forage,
coupling, and energy residuals close.

## Interpretation And Limits

The result is the intended operational null: a persistent homogeneous animal
load depresses mean forage below its no-herbivore equilibrium while remaining
far from the availability threshold, so animal intake and energy balance stay
unchanged. It proves the coupling direction and scaling without yet testing a
stressed animal.

The density is synthetic, all represented animals are identical and
synchronous, and the plant reference remains linear. Chronic high-pressure
decline, recovery after release, density response surfaces, forcing, and
spatial mechanisms are deferred to later goals.
