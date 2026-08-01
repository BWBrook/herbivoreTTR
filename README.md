# herbivoreTTR

`herbivoreTTR` provides transparent functional R models of herbivore
energetics. The current executable model composes one pure food-energy
conversion, a one-pool gut-energy buffer, and a minimal hourly body-energy
ledger with fixed maintenance and prescribed routine-activity expenditure. It
can run one 24-hour schedule directly or repeat that same schedule to establish
a numerical daily gut reference before recording two measured days.

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
be released until a later transition. The coupled runner returns an exact
24-row hourly ledger and a one-row daily summary derived from it, including
separate gut, body, and combined-system accounting residuals. There is no new
dynamic state or integrated food-gut-body runner.

Goal 005 adds
`run_gut_body_energy_reference_cycle()`. It accepts the unchanged Goal 003
available-energy schedule and:

- advances only the gut under identical repeated 24-hour forcing;
- compares the 25 hour-boundary gut stocks on successive days until a declared
  scale-aware numerical tolerance is met;
- resets body energy once to a declared measurement state;
- calls the one-day gut-body runner for two measured days; and
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

Goal 006 changes no package function or model mechanism. It establishes two
named reference fixtures by composing the existing food conversion and
reference-cycle runner:

- the permanent mathematical reference prescribes 0.010 kg DM h^-1, deriving
  100 kJ h^-1, in every hour; and
- the minimally ecological reference prescribes 0.015 kg DM h^-1, deriving
  150 kJ h^-1, in hours 0 through 7 and 16 through 23, with zero intake in
  hours 8 through 15.

Both references prescribe 0.24 kg DM and 2400 kJ per day. Because
`hour_of_day` labels a half-open one-hour interval, the ecological schedule
closes intake exactly during `[08:00, 16:00)` and spans the nominal night from
16:00 through 08:00. This closure is prescribed model intake, not a feeding
decision, permission mask, or observed behavior. The flat schedule adds no
crepuscular peak, maximum-intake constraint, activity cost, endogenous
behavior, plant feedback, or new interface.

The mathematical reference remains the diagnostic and regression baseline.
The ecological reference remains the zero-activity ecological comparator.
Equal steady-cycle daily energy totals are the operational null under the
current linear, lossless, unlimited gut system, while the two references retain
different within-day gut, release, and body-reserve trajectories. Both are
synthetic conventions, not calibrated feeding schedules or evidence of
biological interchangeability.

Goal 007 adds one strict prescribed routine-activity expenditure schedule:

```r
new_routine_activity_expenditure_schedule(
  hour_of_day,
  prescribed_routine_activity_expenditure_kj_h
)
```

The schedule contains integer `hour_of_day = 0:23` and 24 finite,
non-negative rates in kJ h^-1. It is required explicitly by
`step_body_energy()`, `run_body_energy_day()`,
`run_gut_body_energy_day()`, and
`run_gut_body_energy_reference_cycle()`; none supplies an implicit zero
schedule.

Routine activity is an externally prescribed body-energy sink incremental to
the fixed synthetic maintenance term. Over one hour,

```text
body-energy change =
  assimilated energy
  - maintenance expenditure
  - prescribed routine-activity expenditure
```

It does not change ingestion, gut release, assimilation, gut convergence, or
any gut stock. The reference-cycle runner applies activity only during the two
measured body days; gut-only burn-in remains activity-free because it advances
no body state or history.

The Goal 007 zero-activity fixture is the regression control and preserves the
Goal 006 mathematical reference on every shared numerical field. A separate
diagnostic pulse prescribes 50 kJ h^-1 in hours 8 through 11, or 200 kJ per
measured day. Its exact `-200 kJ` daily body effect and zero gut effect test
arithmetic and accounting only. The pulse timing and magnitude are not an
activity observation, locomotion model, behavioral schedule, or empirical
physiology claim.

Goal 008 changes no package function, equation, API, schema, or variable
dictionary. It composes three evidence-only ecological fixtures with intake
during hours 0 through 7 and 16 through 23 and a rest-closed block during hours
8 through 15:

- `ecological_day_resting` prescribes daily input, assimilation, and activity
  of `2400 / 2400 / 0 kJ`;
- `ecological_activity_uncompensated` prescribes
  `2400 / 2400 / 800 kJ`; and
- `ecological_activity_prescribed_balance` prescribes
  `3200 / 3200 / 800 kJ`.

All three gut cycles converge on burn-in day 7. Observed daily body change is
approximately `0 kJ`, `-800 kJ`, and `0 kJ`, and the corresponding body
reserves close measured days 1 and 2 at approximately
`10000 / 10000 kJ`, `9200 / 8400 kJ`, and `10000 / 10000 kJ`.
The baseline and uncompensated gut ledgers match exactly in memory. The balanced
gut and assimilation paths follow the predicted `4/3` scaling with a maximum
in-memory absolute deviation of approximately `1.14e-13 kJ`.

The balanced fixture is now the normal synthetic ecological accounting
reference. The Goal 006 zero-activity ecological fixture remains its comparator,
and the continuous mathematical fixture remains the permanent arithmetic and
regression diagnostic. This hierarchy is an interpretation of verified
synthetic evidence. The balanced fixture's `200 kJ h^-1` input and
`0.32 kg DM d^-1` total are prescribed, not shown feasible; balance is not
behavior, adaptive compensation, biological equilibrium, viability, or
empirical physiology.

Goal 009 also changes no package function, equation, API, state, or schema. An
evidence client starts with the Goal 008 balanced candidate prescription of
`0.020 kg DM h^-1` over the 16 active intervals and applies synthetic hourly
ceilings of `0.015`, `0.020`, and `0.025 kg DM h^-1` by elementwise `pmin`.
The resulting constrained prescription is passed through the unchanged package;
the difference from the candidate is curtailed and discarded, with no
redistribution, storage, carry-over, or feedback.

Under the declared `10000 kJ kg^-1 DM` density, `100 kJ h^-1` maintenance, and
`50 kJ h^-1` active routine-activity fixtures, the exact accounting threshold
is `0.020 kg DM h^-1`, or `200 kJ h^-1`. The below-threshold ceiling constrains
daily intake to `0.24 kg DM` and reproduces the Goal 008 uncompensated
`-800 kJ` daily body change. The at- and above-threshold ceilings preserve the
`0.32 kg DM`, `3200 kJ` prescription and reproduce the Goal 008 balanced
result. Exact touching occurs only in the at-threshold fixture; the
above-threshold fixture instead has `0.08 kg DM`, or `800 kJ`, of unused daily
active-ceiling headroom.

Candidate prescribed intake, the synthetic ceiling, constrained prescribed
intake, curtailed prescribed intake, strict ceiling exceedance, exact positive
touching, and unused active-ceiling headroom are separate evidence quantities.
The ceiling is a client-side accounting prescription used to locate a
conditional threshold. It is not appetite, feeding behavior, forage
availability, gut capacity, a production intake limit, or evidence that the
rate is achievable.

Goal 010 likewise remains evidence-only. It compares prescribed intake windows
of 24, 16, 12, and 8 h d^-1 using open hours `0:23`; `16:23` and `0:7`;
`16:21` and `2:7`; and `16:19` and `4:7`, respectively. Routine activity stays
fixed at `50 kJ h^-1` in hours `16:23` and `0:7` and zero in hours `8:15`. An
open interval is fully used at `0.020 kg DM h^-1`, or `200 kJ h^-1`; this is an
operational prescription, not voluntary opportunity or realized feeding
behavior. The resulting daily prescribed energy is
`4800, 3200, 2400, 1600 kJ`, and the analytical daily body changes are
`+1600, 0, -800, -1600 kJ`, respectively. Expected body reserves close measured
days 1 and 2 at `11600 / 13200`, `10000 / 10000`, `9200 / 8400`, and
`8400 / 6800 kJ`.

The 16-hour result is exactly identical to Goal 008
`ecological_activity_prescribed_balance`. The 12-hour result matches Goal 008
`ecological_activity_uncompensated` only for daily prescribed intake and energy,
maintenance, routine-activity expenditure, body-energy change, status, and
closing body reserve; its intake pattern, periodic gut state, within-day
trajectories, and complete result differ. The 24-hour comparator additionally
opens the activity-off interval `[08:00, 16:00)`, whereas the 12- and 8-hour
fixtures remove central-night prescribed-intake hours from the fixed activity
window. The linear daily accounting relation therefore does not establish a
generic within-day duration effect.

Goal 011 adds one non-stationary, evidence-only contrast without changing the
package. Both sequences start from the same balanced period-24 gut state and
`10000 kJ` body reserve. The control uses balanced forcing on all three carried
days; the treatment uses the lower `0.015 kg DM h^-1` rate on day 1 and returns
to the balanced `0.020 kg DM h^-1` rate on days 2 and 3. Both gut and body
stocks carry exactly across day boundaries without another reset.

The lower-rate schedule is also used by Goal 008
`ecological_activity_uncompensated`, but Goal 011 does not reproduce that
periodic result: its day-1 treatment begins from the balanced periodic gut.
Using `one_day_rate_shortfall - all_balanced_control`, the prescribed-input
contrast reaches exactly `-800 kJ` at 24 hours. The combined gut-plus-body
contrast reaches the same `-800 kJ` and remains there through 72 hours because
the two sequences have identical inputs and expenditures after day 1.

Under return-to-reference forcing, the gut contrast contracts by `0.75` per
hour, or `0.75^24` per day, while the body contrast is
`-800 kJ - gut-stock contrast`. This is numerical gut-state realignment and a
changing partition of a fixed combined-system contrast, not body-energy or
whole-system restoration. The evidence clients obtain the fixed three-day
sequence by chaining existing one-day calls; they add no generalized
production multi-day API.

The 24-hour partition rounds to `-182 kJ` in the gut and `-618 kJ` in the body.
The remaining gut contrast is `-0.182 kJ` at 48 hours and `-0.000183 kJ` at
72 hours; the body holds the unrounded complement to the exact `-800 kJ`
combined-system contrast.

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

The Goal 006 experiment
[`experiments/rebuild-006-ecological-daily-reference.R`](experiments/rebuild-006-ecological-daily-reference.R)
compares the mathematical and ecological references without changing package
code. Its separate review script writes only the five ignored review files
declared by the Goal 006 contract.

The Goal 007 experiment
[`experiments/rebuild-007-routine-activity-expenditure.R`](experiments/rebuild-007-routine-activity-expenditure.R)
compares the zero-activity regression control with the four-hour arithmetic
pulse. Its separate review script writes only the five ignored review files
declared by the Goal 007 contract.

The Goal 008 experiment
[`experiments/rebuild-008-ecological-activity-intake-balance.R`](experiments/rebuild-008-ecological-activity-intake-balance.R)
verifies the three-scenario chain and its paired contrasts. Its review script
retains four tables and one figure under
[`outputs/rebuild-008-ecological-activity-intake-balance/`](outputs/rebuild-008-ecological-activity-intake-balance/)
as ignored evidence.

The Goal 009 experiment
[`experiments/rebuild-009-synthetic-intake-ceiling-threshold.R`](experiments/rebuild-009-synthetic-intake-ceiling-threshold.R)
verifies the three-level synthetic ceiling bracket and exact Goal 008 result
identities. Its review script retains one figure and three tables under
[`outputs/rebuild-009-synthetic-intake-ceiling-threshold/`](outputs/rebuild-009-synthetic-intake-ceiling-threshold/)
as ignored evidence.

The Goal 010 experiment
[`experiments/rebuild-010-feeding-opportunity-duration.R`](experiments/rebuild-010-feeding-opportunity-duration.R)
verifies the four prescribed-intake-window fixtures, analytical duration
relation, and bounded Goal 008 comparisons. Its review script retains one
figure and three tables under
[`outputs/rebuild-010-feeding-opportunity-duration/`](outputs/rebuild-010-feeding-opportunity-duration/)
as ignored evidence.

The Goal 011 experiment
[`experiments/rebuild-011-one-day-prescribed-input-shortfall.R`](experiments/rebuild-011-one-day-prescribed-input-shortfall.R)
verifies the common initialization, three-day control and treatment sequences,
exact stock carry-over, `-800 kJ` combined-system invariant, and analytical gut
recurrence. Its review script retains one figure and three tables under
[`outputs/rebuild-011-one-day-prescribed-input-shortfall/`](outputs/rebuild-011-one-day-prescribed-input-shortfall/)
as ignored evidence.

These demonstrations prove arithmetic, timing, and accounting semantics only.
They do not estimate a maintenance requirement, residence time, gut fill,
feeding schedule, animal viability, ecological equilibrium, or any macropod
trait. The model contains no offered forage, wet-mass conversion, variable food
quality, digestive loss, waste, dry-matter gut stock, gut capacity, production
intake ceiling, feeding behavior, directed locomotion, activity choice or
feedback, body-mass change, plants, or empirical calibration. It also contains
no variable or stochastic days, configurable measurement horizon, season,
chronic-decline process, recovery process, or viability criterion.

## Design

The rebuild uses plain validated state records, pure functions, and strict
separation of dynamic state, fixed parameters, prescribed inputs, process
functions, and history. Variables and documentation use explicit unit suffixes.
Experiments remain thin clients of the package. Each future goal addresses one
principal question and one subsystem, with compact outputs, proportionate tests,
an explicit stop, and discussion before another layer is added.

The executable package contract remains specified in
[`docs/model-specification.md`](docs/model-specification.md). Goals 009 through
011 add evidence about a synthetic accounting threshold, prescribed-intake
window duration, and one fixed forcing transition without changing that
contract. Goal 012 remains unapproved, and its scientific question has not been
selected. Candidate later layers are listed without authorization in
[`docs/roadmap.md`](docs/roadmap.md).

## Provenance

The preceding implementation is preserved in the private repository
`BWBrook/herbivoreTTR-legacy` at annotated tag
`legacy-final-2026-07-16`. The scientific baseline immediately preceding the
freeze is commit `abf68b691b4e30020625d1871dcabe56a5926bc1`.

Legacy R and C++ behavior is historical evidence only. Ecological logic,
dimensional consistency, empirical evidence, and transparent assumptions govern
the rebuild.
