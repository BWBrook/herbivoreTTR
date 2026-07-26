# herbivoreTTR

`herbivoreTTR` provides transparent functional R models of herbivore
energetics. The current executable model couples a one-pool gut-energy buffer
to a minimal hourly body-energy ledger over 24 exact one-hour transitions.
Controlled prescribed ingestion enters the gut, a fixed fraction of its
opening stock is released each hour, and released energy enters the body
reserve against constant maintenance expenditure.

## Current Capability

The package keeps dynamic state, fixed parameters, prescribed inputs, pure
transitions, and recorded history separate. Goal 002's public body-only
interface remains available: it accepts a prescribed already-assimilated
energy schedule and records the resulting body-energy ledger. Goal 003 adds
strict records for gut stock, its fixed hourly release fraction, and a 24-row
ingested available-energy schedule; one pure gut transition; and a coupled
daily runner.

Gut release is calculated from the stock present at the start of each hour.
The current hour's ingestion is added afterwards, so it cannot be released
until a later transition. Gut stock is measured in assimilable-energy
equivalents and transfers one-for-one into the unchanged body ledger. The
coupled runner returns an exact 24-row hourly ledger and a one-row daily
summary derived from it, including separate gut, body, and combined-system
accounting residuals.

The thin experiment
[`experiments/rebuild-002-body-energy-ledger.R`](experiments/rebuild-002-body-energy-ledger.R)
demonstrates the standalone body's analytically fixed neutral, deficit, and
surplus cases. The Goal 003 experiment
[`experiments/rebuild-003-one-pool-gut-buffer.R`](experiments/rebuild-003-one-pool-gut-buffer.R)
demonstrates a synthetic gut-body equilibrium, the transient from an empty gut,
and delayed geometric release after a single ingestion pulse.

These demonstrations prove arithmetic, timing, and accounting semantics only.
They do not estimate a maintenance requirement, residence time, gut fill,
feeding schedule, animal viability, ecological equilibrium, or any macropod
trait. The model contains no food mass or quality, digestive loss, waste, gut
capacity, feeding behavior, activity expenditure, body-mass change, plants, or
empirical calibration.

## Design

The rebuild uses plain validated state records, pure functions, and strict
separation of dynamic state, fixed parameters, prescribed inputs, process
functions, and history. Variables and documentation use explicit unit suffixes.
Experiments remain thin clients of the package. Each future goal addresses one
principal question and one subsystem, with compact outputs, proportionate tests,
an explicit stop, and discussion before another layer is added.

The current contract is specified in
[`docs/model-specification.md`](docs/model-specification.md). No further model
layer is currently specified or authorized. The Goal 003 results must be
discussed before another bounded question is chosen; candidate later layers are
listed without authorization in [`docs/roadmap.md`](docs/roadmap.md).

## Provenance

The preceding implementation is preserved in the private repository
`BWBrook/herbivoreTTR-legacy` at annotated tag
`legacy-final-2026-07-16`. The scientific baseline immediately preceding the
freeze is commit `abf68b691b4e30020625d1871dcabe56a5926bc1`.

Legacy R and C++ behavior is historical evidence only. Ecological logic,
dimensional consistency, empirical evidence, and transparent assumptions govern
the rebuild.
