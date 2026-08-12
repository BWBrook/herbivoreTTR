# Decision 0029: Constant-Turnover Forage Reference

Date: 2026-08-12

Status: accepted implementation; publication pending

## Context

Goal 028 established standing forage biomass and exact prescribed stock-flow
accounting. The next rung requires a stable plant-side reference whose
equilibrium and perturbation recovery can be understood before environmental
forcing or herbivory obscures them.

## Decision

Use a linear turnover reference with equilibrium standing biomass `B*` and
hourly turnover fraction `tau`:

```text
growth = tau * B*
background loss = tau * B
B[next] = (1 - tau) * B + tau * B*
```

For `0 < tau <= 1`, the closing stock is a convex combination of current
biomass and equilibrium biomass. The process is non-negative and approaches
`B*` monotonically without overshoot. Its exact deviation after `n` hours is
the initial deviation multiplied by `(1 - tau)^n`.

This formulation was preferred to logistic growth for the first reference
because it preserves separate positive growth and loss at equilibrium, has an
exact discrete-time solution, and does not create numerical overshoot or
negative growth above equilibrium.

## Verification

The diagnostic used `B* = 1,000 kg DM ha^-1`, `tau = 0.001 h^-1`, matched
starting stocks of `500` and `1,500 kg DM ha^-1`, and a 180-day horizon.

| Day | Low start trajectory | Reference | High start trajectory |
| ---: | ---: | ---: | ---: |
| 0 | 500.0 | 1,000.0 | 1,500.0 |
| 1 | 511.9 | 1,000.0 | 1,488.1 |
| 30 | 756.7 | 1,000.0 | 1,243.3 |
| 90 | 942.4 | 1,000.0 | 1,057.6 |
| 180 | 993.4 | 1,000.0 | 1,006.6 |

All table values are `kg DM ha^-1`. Equilibrium production and loss are each
`24 kg DM ha^-1 d^-1`. Numerical and analytic trajectories agree across all
4,320 hourly transitions; matched deviations remain equal and opposite; no
trajectory overshoots; and all stock-flow residuals close. Only 1.3% of the
initial perturbation remains after 180 days.

## Interpretation And Limits

The reference now gives the isolated plant subsystem a stable, transparent
anchor. It also makes strong simplifications. Production is constant rather
than resource- or weather-dependent, proportional loss is the only density
feedback, recovery is symmetric and independent of perturbation magnitude,
and zero standing biomass regrows because regenerative capacity is outside the
represented stock.

These are useful null properties, not claims about tropical-savanna forage.
The next isolated-forage decision should define a minimal mapping from standing
biomass to forage accessible for animal acquisition, still without removal or
coupling. Mechanistic growth, seasonality, rainfall, and disturbance remain
later rungs.
