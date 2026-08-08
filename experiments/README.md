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
vegetation, space, body-mass change, or viability thresholds.

`rebuild-018-severity-recurrence-map.R` crosses fixed event losses of 400, 800,
and 1,200 kJ with recurrence every 8, 4, and 2 days. It reproduces Goal 017's
central trajectories, records the existing positive-reserve boundary without
bypassing it, and adds no model process, production interface, or test.
