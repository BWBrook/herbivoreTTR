# Experiments

Experiments are thin, source-controlled, no-write scientific clients of the
package. They may prescribe inputs, compose public transitions into a fixed
diagnostic sequence, and check the scientific question they were written to
answer. Reusable process equations and generalized runners do not belong here.

Generated tables and figures belong under ignored `outputs/` paths and are
disposable. Goal-specific publishers, scope guards, bulk receipts, and similar
review machinery may exist temporarily while a result is under review, but are
not retained after the accepted conclusion is recorded in `docs/decisions/`
and the current model documentation.

`rebuild-013-minimal-endogenous-appetite-control.R` establishes the first
accepted endogenous-intake recovery sequence. It now calls the canonical
package runner for its balanced and nine-day recovery paths; its sequence
labels and summaries remain evidence rather than another model loop.

`rebuild-014-appetite-controller-sensitivity.R` reuses that fixed transition
sequence for a prespecified 27-scenario gain-and-deficit screen plus one
four-case component comparison. It calls the same canonical runner once per
scenario, changes no model equation, and does not select empirical parameters.

`rebuild-016-forage-acquisition-ceiling.R` compares the accepted non-binding
reference with one matched day whose external acquisition ceiling binds during
all 16 feeding hours. It demonstrates appetite-target versus realized intake
without adding forage state, depletion, plant dynamics, or spatial behavior.

`rebuild-017-recurrent-forage-limitation.R` sequences the same binding day over
a common 48-day horizon with no event, one event, or recurrence every 8, 4, or
2 days. It varies recurrence alone and reports inter-event recovery and
finite-horizon energy-debt cycles without adding production recurrence logic,
vegetation, space, mass feedback, or viability thresholds.

`rebuild-018-severity-recurrence-map.R` crosses fixed event losses of 400, 800,
and 1,200 kJ with recurrence every 8, 4, and 2 days. It reproduces Goal 017's
central trajectories and reports whether energy debt recovers, settles, or
continues to accumulate. At the current 40,000 kJ reference reserve all nine
scenarios complete 48 days; it adds no model process or production interface.

`rebuild-019-derived-body-mass.R` proves that shifting the appetite reference
from 10,000 to 40,000 kJ changes no reference-relative energetic trajectory
beyond floating-point roundoff. It then applies the pure body-mass converter to
Goal 018 output. The derived masses are interpretations of energy state, not a
second dynamic stock or feedback process.

`rebuild-020-deficit-responsive-feeding-duration.R` compares fixed-duration
recovery with a once-daily rule that can open up to two symmetric feeding-hour
pairs from opening body deficit. It preserves the accepted within-hour model,
central rest block, and activity charge, and adds no production scheduler or
acquisition-rate response.

`rebuild-021-rate-duration-feedback-decomposition.R` crosses the existing
hourly appetite-rate feedback off/on with the Goal 020 duration response off/on
after one common shortfall. It quantifies their isolated recovery and
sub-additive overlap without adding another acquisition controller or package
mechanism.

`rebuild-022-implicit-two-patch-forage.R` prescribes adequate and limited
non-depleting acquisition ceilings across the two accepted feeding windows. It
compares homogeneous anchors with two equal-exposure mixed orders and retains
patch labels as evidence only, without adding location, movement, choice,
depletion, vegetation, or a production spatial interface.

`rebuild-023-two-day-patch-carryover.R` repeats each Goal 022 schedule for one
additional identical day through the canonical carried-state runner. It tests
whether the mixed-order intake and energy partition persist without adding a
third day, recurrence machinery, movement cost, choice, depletion, vegetation,
or production spatial state.

`rebuild-024-known-route-movement-cost.R` crosses one lost feeding hour with an
additional `100 kJ` movement charge for both mixed patch orders. It separates
time and energy effects without adding distance, speed, search, choice, water,
multi-day travel, or production movement state.

`rebuild-025-patch-food-energy-density.R` composes public hourly transitions
for adequate and lower metabolizable energy densities across the accepted
feeding windows. Acquisition remains non-limiting and movement cost-free; the
client adds no production density schedule, nutrient process, depletion, or
vegetation.

`rebuild-026-repeated-food-quality.R` calls the canonical repeated-day runner
for 10 homogeneous adequate- and lower-quality days. It tests daily reactive
compensation and accumulated reserve state without adding anticipation,
learning, environmental variation, or another runner.

`rebuild-027-lower-quality-duration-response.R` compares adequate fixed,
lower-quality fixed, and lower-quality responsive-duration trajectories over
10 days. It reuses the Goal 020 rule unchanged and closes the current
herbivore-core stage without adding a scheduler or another animal mechanism.
