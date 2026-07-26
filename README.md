# herbivoreTTR

`herbivoreTTR` provides transparent functional R models of herbivore
energetics. Its first executable layer is a minimal hourly body-energy ledger:
prescribed energy that is already assimilated enters one physical reserve,
constant maintenance expenditure leaves it, and the package records 24 exact
one-hour transitions.

## Current Capability

The implemented layer keeps dynamic state, fixed parameters, prescribed
inputs, pure transitions, and recorded history separate. It provides strict
constructors for the body-energy state, maintenance parameter, and 24-row
assimilated-energy schedule; a pure one-hour transition; and a daily runner.
The runner returns an exact 24-row hourly ledger and a one-row daily summary
derived from that ledger.

The thin experiment
[`experiments/rebuild-002-body-energy-ledger.R`](experiments/rebuild-002-body-energy-ledger.R)
demonstrates analytically fixed neutral, deficit, and surplus cases. The 50 kg
reference body mass appears only as experiment metadata: it is not model state
or a transition parameter because no implemented equation depends on mass.

This layer proves arithmetic and accounting semantics. It does not establish
an empirically realistic maintenance requirement, animal viability, ecological
equilibrium, or any empirical claim about macropods. It implements no food,
gut, digestion, or assimilation calculation; the prescribed input is already
assimilated energy.

## Design

The rebuild uses plain validated state records, pure functions, and strict
separation of dynamic state, fixed parameters, prescribed inputs, process
functions, and history. Variables and documentation use explicit unit suffixes.
Experiments remain thin clients of the package. Each future goal addresses one
principal question and one subsystem, with compact outputs, proportionate tests,
an explicit stop, and discussion before another layer is added.

The current contract is specified in
[`docs/model-specification.md`](docs/model-specification.md). The next
unimplemented layer would add controlled food and a one-pool gut/assimilation
stock-flow system, but only through a separately discussed and approved goal.
Later layers remain ordered in [`docs/roadmap.md`](docs/roadmap.md).

## Provenance

The preceding implementation is preserved in the private repository
`BWBrook/herbivoreTTR-legacy` at annotated tag
`legacy-final-2026-07-16`. The scientific baseline immediately preceding the
freeze is commit `abf68b691b4e30020625d1871dcabe56a5926bc1`.

Legacy R and C++ behavior is historical evidence only. Ecological logic,
dimensional consistency, empirical evidence, and transparent assumptions govern
the rebuild.
