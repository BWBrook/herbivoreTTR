# Decision 0039: One Resource-Aware Patch Decision

Date: 2026-08-15

Status: accepted

## Question

Does current patch depletion become decision-relevant under the accepted
coupled model, and can that effect be distinguished from the biomass-blind
static choice without prematurely inventing a behavioral engine?

## Decision Benchmark

At one day boundary, a perfect-state, perfect-model oracle evaluates exactly
two accepted full-day counterfactuals from the same opening location, gut,
body, and spatial-forage state. One stays in patch A; the other moves to known
patch B at hour 0 and remains there. The candidate with higher closing combined
energy is selected, with ties staying.

The oracle knows both patch stocks, static acquisition capacities, common
turnover, appetite and energy parameters, schedules, and the `900 kJ` route.
This is an omniscient decision-relevance benchmark, not a proposed account of
animal perception, memory, prediction, or behavior.

A bounded exploratory check rejected a simpler current-stock-only algebraic
score: near the residual threshold it can recommend movement while ignoring
forage renewal during the bout, even when the full stay counterfactual performs
better. Reusing the accepted runner is therefore both leaner and scientifically
safer than adding a second approximate resource model.

## Evidence

Both patches have equal `0.025 kg DM h^-1` static capacity. The static choice
uses `0.020 kg DM h^-1` expected demand, 16 feeding hours, and the same route.

| Opening state | Patch A biomass | Static choice | Oracle choice | Stay intake | Move intake | Stay change | Move change | Selected advantage |
| --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |
| Mild depletion | 931.54 kg DM ha^-1 | Stay | Stay | 0.320 kg DM | 0.355 kg DM | 0 kJ | -549 kJ | 549 kJ |
| Severe depletion | 450.00 kg DM ha^-1 | Stay | Move | 0.000 kg DM | 0.355 kg DM | -3,200 kJ | -549 kJ | 2,651 kJ |

The mild state is reproduced by carrying the exact accepted 30-day occupancy
trajectory. Its forage stock never limits intake, so the additional compensated
intake after moving does not repay route expenditure. The severe positive
control sets patch A to exactly `90%` of the `500 kg DM ha^-1` residual
threshold. Staying is stock-limited in all 16 feeding hours, making movement
energetically preferable despite its cost.

All four counterfactuals close patch, herbivore-forage coupling, gut, body, and
combined-energy accounts.

## Interpretation

The accepted Goal 038 depletion is real but not yet functionally severe enough
to justify movement under this route cost. Resource state can nevertheless
change the preferred action once depletion constrains acquisition. The static
choice remains a valid acquisition-capacity null; the oracle shows what that
null cannot detect.

No behavioral rule is accepted from this result. The location of the dynamic
switch boundary, imperfect information, endogenous timing, repeated decisions,
memory, learning, destination uncertainty, patch-specific turnover, water
physiology, and chronic stress remain separate questions.
