# herbivoreTTR

`herbivoreTTR` provides transparent functional R models of herbivore
energetics. The current executable model composes one pure food-energy
conversion, a one-pool gut-energy buffer, and a minimal hourly body-energy
ledger. It can run one 24-hour schedule directly or repeat that same schedule
to establish a numerical daily gut reference before recording two measured
days.

## Current Capability

The package keeps dynamic state, fixed parameters, prescribed inputs, pure
transitions, and recorded history separate. Goal 002's public body-only
interface remains available: it accepts a prescribed already-assimilated
energy schedule and records the resulting body-energy ledger. Goal 003 adds
strict records for gut stock, its fixed hourly release fraction, and a 24-row
ingested available-energy schedule; one pure gut transition; and a coupled
daily runner.

Goal 004 adds three compositional functions:

- `new_food_energy_parameters()` creates an exact one-field record containing a
  strictly positive fixed metabolizable-energy density in kJ kg^-1 DM;
- `new_dry_matter_intake_schedule()` creates an exact 24-row schedule of
  prescribed ingestion rates in kg DM h^-1; and
- `derive_ingested_available_energy_schedule()` multiplies those rates and
  returns the unchanged Goal 003 schedule in kJ h^-1.

The density is already metabolizable. Its product with prescribed dry-matter
intake is treated as the accounting equivalent entering the existing
`gut_available_energy_kj` pool; the bridge does not calculate digestion,
digestibility, assimilation efficiency, or energy loss. Dry matter means
prescribed ingestion, not offered or available forage, wet or as-fed mass, or
the result of a modeled feeding decision.

Gut release is still calculated from the stock present at the start of each
hour. The current hour's converted ingestion is added afterwards, so it cannot
be released until a later transition. The coupled runner is unchanged and
returns an exact 24-row hourly ledger and a one-row daily summary derived from
it, including separate gut, body, and combined-system accounting residuals.
There is no new dynamic state or integrated food-gut-body runner.

Goal 005 adds
`run_gut_body_energy_reference_cycle()`. It accepts the unchanged Goal 003
available-energy schedule and:

- advances only the gut under identical repeated 24-hour forcing;
- compares the 25 hour-boundary gut stocks on successive days until a declared
  scale-aware numerical tolerance is met;
- resets body energy once to a declared measurement state;
- calls the unchanged one-day gut-body runner for two measured days; and
- carries both closing states from measured day 1 into measured day 2.

Gut-cycle stability and energetic neutrality are different diagnostics. A gut
trajectory can repeat while the body reserve declines, as the zero-intake
fixture demonstrates. The one body reset is a measurement protocol that removes
the arbitrary empty-gut initialization debt; it is not a physiological process
and is not repeated between measured days. The numerical convergence tolerance
addresses floating-point arithmetic only, not biological variation,
measurement precision, viability, or parameter uncertainty.

The constant and concentrated late-feeding fixtures both prescribe 0.24 kg DM
and 2400 kJ per day. In the current unlimited, linear, lossless gut model they
have different within-day gut, assimilation, and body trajectories but the
same steady-cycle daily energy-flow totals within explicit numerical
tolerances. This timing equivalence is conditional on both body paths
completing above the unchanged non-negative reserve boundary. It is checked
from numeric stocks and flows, never inferred from `body_energy_status`, and
does not make real foods or feeding schedules biologically interchangeable.

Only the product of intake and density reaches downstream dynamics. Scaling
intake by a positive constant and density by its reciprocal therefore produces
identical energy trajectories. The two prescribed inputs are structurally
non-identifiable from those trajectories; this accounting equivalence does not
make different foods or feeding regimes biologically interchangeable.

The thin experiment
[`experiments/rebuild-002-body-energy-ledger.R`](experiments/rebuild-002-body-energy-ledger.R)
demonstrates the standalone body's analytically fixed neutral, deficit, and
surplus cases. The Goal 003 experiment
[`experiments/rebuild-003-one-pool-gut-buffer.R`](experiments/rebuild-003-one-pool-gut-buffer.R)
demonstrates a synthetic gut-body equilibrium, the transient from an empty gut,
and delayed geometric release after a single ingestion pulse. The Goal 004
experiment
[`experiments/rebuild-004-controlled-food-energy-bridge.R`](experiments/rebuild-004-controlled-food-energy-bridge.R)
demonstrates exact zero, constant, pulse, and factorization conversions and
their unchanged downstream results. The Goal 005 experiment
[`experiments/rebuild-005-repeated-day-reference-cycle.R`](experiments/rebuild-005-repeated-day-reference-cycle.R)
demonstrates gut-only spin-up, the single body reset, state carry-over, and the
zero, constant, and concentrated late-feeding reference cycles. Its separate
review script writes only the five ignored synthetic figures and tables
declared by the Goal 005 contract.

These demonstrations prove arithmetic, timing, and accounting semantics only.
They do not estimate a maintenance requirement, residence time, gut fill,
feeding schedule, animal viability, ecological equilibrium, or any macropod
trait. The model contains no offered forage, wet-mass conversion, variable food
quality, digestive loss, waste, dry-matter gut stock, gut capacity, feeding
behavior, activity expenditure, body-mass change, plants, or empirical
calibration. It also contains no variable or stochastic days, configurable
measurement horizon, season, chronic-decline process, recovery process, or
viability criterion.

## Design

The rebuild uses plain validated state records, pure functions, and strict
separation of dynamic state, fixed parameters, prescribed inputs, process
functions, and history. Variables and documentation use explicit unit suffixes.
Experiments remain thin clients of the package. Each future goal addresses one
principal question and one subsystem, with compact outputs, proportionate tests,
an explicit stop, and discussion before another layer is added.

The current Goal 005 contract is specified in
[`docs/model-specification.md`](docs/model-specification.md). No later model
layer is currently specified or authorized. Goal 005 results must be discussed
before another bounded question is chosen; candidate later layers are listed
without authorization in [`docs/roadmap.md`](docs/roadmap.md).

## Provenance

The preceding implementation is preserved in the private repository
`BWBrook/herbivoreTTR-legacy` at annotated tag
`legacy-final-2026-07-16`. The scientific baseline immediately preceding the
freeze is commit `abf68b691b4e30020625d1871dcabe56a5926bc1`.

Legacy R and C++ behavior is historical evidence only. Ecological logic,
dimensional consistency, empirical evidence, and transparent assumptions govern
the rebuild.
