# herbivoreTTR

`herbivoreTTR` provides transparent functional R models of herbivore
energetics. The current executable model composes one pure food-energy
conversion, a one-pool gut-energy buffer, and a minimal hourly body-energy
ledger with fixed maintenance and prescribed routine-activity expenditure. It
can run one 24-hour schedule directly or repeat that same schedule to establish
a numerical daily gut reference before recording two measured days. A separate
pure appetite controller calculates a bounded intake target from body- and
gut-energy deviations. One non-depleting forage-acquisition ceiling then limits
realized intake, and the canonical runner can repeat the coupled system over
fixed identical days with exact state carry-over.

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
dynamic state. The prescribed-input path remains a one-day runner; the separate
appetite-controlled path introduced in Goal 015 supplies the repeated fixed-day
horizon described below.

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
whole-system restoration. The retained Goal 011 experiment obtains the fixed
three-day sequence by chaining existing one-day calls; it adds no generalized
production multi-day API.

The 24-hour partition rounds to `-182 kJ` in the gut and `-618 kJ` in the body.
The remaining gut contrast is `-0.182 kJ` at 48 hours and `-0.000183 kJ` at
72 hours; the body holds the unrounded complement to the exact `-800 kJ`
combined-system contrast.

Goal 012 extends that contrast with one prescribed external energy-repayment
pulse and a fourth carried day, again without changing the package. Both
sequences start from the same balanced period-24 gut state and `10000 kJ` body
reserve. The control uses `0.020 kg DM h^-1` in the 16 active hours on all four
days. The treatment uses `0.015 kg DM h^-1` on day 1, directly prescribes
`0.025 kg DM h^-1` on day 2, and returns to `0.020 kg DM h^-1` on days 3 and 4;
every schedule remains zero during hours `8:15`.

Using `shortfall_then_repayment - all_balanced_control`, cumulative external
input and the combined gut-plus-body contrast reach `-800 kJ` at 24 hours and
return to `0 kJ` at 48 hours. At that boundary the gut and body contrasts are
still approximately `+182 kJ` and `-182 kJ`. Under balanced forcing on days 3
and 4, those equal-and-opposite component contrasts contract by `0.75^24` per
day toward zero without reaching exact treatment-control stock equality in
finite time; the combined contrast remains zero.

The `0.025 kg DM h^-1` pulse is direct exogenous synthetic forcing, not Goal
009's above-threshold result: that fixture's actual candidate prescription
remained `0.020 kg DM h^-1` beneath a non-binding ceiling. `Prescribed repayment
pulse` is an accounting label, not compensation, catch-up feeding, appetite,
behavioral response, capacity, or biological recovery. The fixed four-day
sequence chains existing one-day calls and adds no production multi-day API,
state, schema, parameter, or test.

Goal 013 adds the first endogenous intake calculation. For each hour it starts
from the accepted reference intake, subtracts signed feedback proportional to
the body's and gut's deviations above their hour-specific reference states,
then applies zero and maximum intake bounds and the established feeding-
opportunity closure. A state below reference therefore increases intake; a
state above reference suppresses it. Gut energy is a post-ingestive satiation
proxy here, not a physical dry-matter fill state.

The retained diagnostic uses synthetic feedback fractions of `0.05 h^-1` for
body energy and `0.10 h^-1` for gut energy, with reference and maximum rates of
`0.020` and `0.025 kg DM h^-1`. The exact balanced trajectory remains unchanged.
After the established `-800 kJ` shortfall day, realized intake rises to
approximately `0.363 kg DM` on the first feedback day and then approaches the
`0.320 kg DM` reference. At day 10 the body and combined-system deviations are
approximately `-2 kJ` and `-1 kJ`, without body-reserve overshoot or intake
outside the feeding window.

The package exposes the pure records and hourly controller. Goal 013 originally
kept its recovery sequence in a no-write experiment rather than widening the
runtime boundary.

Goal 014 tests that unchanged controller across 27 combinations of synthetic
body response, gut response, and one-day deficit. Every declared scenario
recovers stably without body-reserve overshoot; 90% recovery takes 2 to 9 days.
Body feedback controls recovery speed, gut feedback tempers it, and the maximum
intake rate becomes active mainly under larger deficits and faster body
responses. A four-case component comparison confirms that gut feedback alone
cannot restore a persistent body-energy deficit. This is structural evidence,
not empirical calibration.

Goal 015 promotes the accepted repeated-day composition into
`run_appetite_controlled_energy_days()`. It repeats one fixed 24-hour appetite
reference and routine-activity schedule for a declared number of days, applying
the appetite, gut, and body transitions in that order each hour and carrying
both closing stocks exactly. Its hourly and daily ledgers distinguish realized
from prescribed intake and retain explicit gut, body, and combined-system
accounts. The accepted Goal 013 recovery and all Goal 014 scenarios are
unchanged. A numerical period-24 reference repeats within floating-point
tolerance; it is never clamped to exact reference values.

Goal 016 separates animal-side appetite from environment-limited acquisition.
`calculate_appetite_target()` now names the controller's bounded output as an
appetite target. `new_forage_acquisition_ceiling_schedule()` supplies one
external, non-depleting rate ceiling, and realized intake is the smaller of the
two. A non-binding ceiling preserves every accepted result. A ceiling of
`0.015 kg DM h^-1` during the 16 feeding hours limits realized intake to
`0.240 kg DM` despite a `0.359 kg DM` daily target and produces the analytical
`-800 kJ` combined-system day. This is a coupling interface, not a forage stock
or plant model.

Goals 017 and 018 use no-write experiments to vary recurrence and event
severity over 48 days. Their main capacity result is analytical: a recovery day
can add at most `800 kJ`, so a `1,200 kJ` event every two days must continue
losing `400 kJ` per cycle even at maximum intake.

Goal 019 adds a downstream physical interpretation without another dynamic
state. The current synthetic animal has 38 kg fixed structural mass and 2 kg
labile reserve tissue at `20,000 kJ kg^-1`, giving a `40,000 kJ`, 40 kg
reference. `derive_body_mass_from_energy_reserve()` converts energy outputs to
reserve-tissue and total mass, but mass does not feed back to any transition.
A paired 10,000-versus-40,000 kJ diagnostic preserves all reference-relative
dynamics within floating-point roundoff. The larger reference removes Goal
018's former arbitrary day-47 reserve floor; the strong two-day treatment now
completes 48 days at approximately `-9,792 kJ` combined deviation.

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
zero, constant, and concentrated late-feeding reference cycles.

The Goal 006 experiment
[`experiments/rebuild-006-ecological-daily-reference.R`](experiments/rebuild-006-ecological-daily-reference.R)
compares the mathematical and ecological references without changing package
code.

The Goal 007 experiment
[`experiments/rebuild-007-routine-activity-expenditure.R`](experiments/rebuild-007-routine-activity-expenditure.R)
compares the zero-activity regression control with the four-hour arithmetic
pulse.

The Goal 008 experiment
[`experiments/rebuild-008-ecological-activity-intake-balance.R`](experiments/rebuild-008-ecological-activity-intake-balance.R)
verifies the three-scenario chain and its paired contrasts.

The Goal 009 experiment
[`experiments/rebuild-009-synthetic-intake-ceiling-threshold.R`](experiments/rebuild-009-synthetic-intake-ceiling-threshold.R)
verifies the three-level synthetic ceiling bracket and exact Goal 008 result
identities.

The Goal 010 experiment
[`experiments/rebuild-010-feeding-opportunity-duration.R`](experiments/rebuild-010-feeding-opportunity-duration.R)
verifies the four prescribed-intake-window fixtures, analytical duration
relation, and bounded Goal 008 comparisons.

The Goal 011 experiment
[`experiments/rebuild-011-one-day-prescribed-input-shortfall.R`](experiments/rebuild-011-one-day-prescribed-input-shortfall.R)
verifies the common initialization, three-day control and treatment sequences,
exact stock carry-over, `-800 kJ` combined-system invariant, and analytical gut
recurrence.

The Goal 012 experiment
[`experiments/rebuild-012-prescribed-energy-repayment-pulse.R`](experiments/rebuild-012-prescribed-energy-repayment-pulse.R)
verifies the common initialization, four-day control and treatment sequences,
exact stock carry-over, the `-800 -> 0 kJ` combined-system path, and the
post-pulse gut recurrence.

The Goal 013 experiment
[`experiments/rebuild-013-minimal-endogenous-appetite-control.R`](experiments/rebuild-013-minimal-endogenous-appetite-control.R)
verifies exact reference identity, the shortfall-to-feedback sequence, bounded
and opportunity-gated realized intake, accounting closure, and an isolated
gut-satiation probe through the canonical repeated-day runner.

The Goal 014 experiment
[`experiments/rebuild-014-appetite-controller-sensitivity.R`](experiments/rebuild-014-appetite-controller-sensitivity.R)
verifies the bounded gain-and-deficit screen, controller component comparison,
reference identity, intake constraints, energy closure, and recovery
classification through the same canonical runner.

The Goal 016 experiment
[`experiments/rebuild-016-forage-acquisition-ceiling.R`](experiments/rebuild-016-forage-acquisition-ceiling.R)
compares the accepted non-binding reference with one matched binding
forage-acquisition ceiling and verifies target–realized separation and exact
energy accounting.

The Goal 017 and Goal 018 experiments
[`experiments/rebuild-017-recurrent-forage-limitation.R`](experiments/rebuild-017-recurrent-forage-limitation.R)
and
[`experiments/rebuild-018-severity-recurrence-map.R`](experiments/rebuild-018-severity-recurrence-map.R)
verify the fixed recurrence and severity response surfaces. The Goal 019
experiment
[`experiments/rebuild-019-derived-body-mass.R`](experiments/rebuild-019-derived-body-mass.R)
verifies the energy-coordinate translation and derived mass interpretation.
The Goal 020 experiment
[`experiments/rebuild-020-deficit-responsive-feeding-duration.R`](experiments/rebuild-020-deficit-responsive-feeding-duration.R)
tests a bounded once-daily feeding-duration response after the accepted
shortfall while leaving the production model unchanged.

These demonstrations prove arithmetic, timing, and accounting semantics only.
They do not estimate a maintenance requirement, residence time, physical gut
fill, animal viability, ecological equilibrium, or any macropod trait. The
model contains no forage biomass or depletion, wet-mass conversion, variable
food quality, digestive loss, waste, dry-matter gut stock, physical gut
capacity, meals, food choice, directed locomotion, activity choice or feedback,
mass-dependent energetics, tissue turnover or partitioning, plants, or
empirical calibration. Production runners also contain no variable or
stochastic daily forcing, season, recurrent disturbance, chronic-decline
process, or viability criterion.

## Design

The rebuild uses plain validated state records, pure functions, and strict
separation of dynamic state, fixed parameters, prescribed or realized inputs,
process functions, and history. Variables and documentation use explicit unit
suffixes. Experiments remain thin clients of the package. Each future goal
addresses one principal question and one subsystem, with compact outputs,
proportionate tests, an explicit stop, and discussion before another layer is
added.

The executable package contract remains specified in
[`docs/model-specification.md`](docs/model-specification.md). Goals 009 through
012 add evidence about a synthetic accounting threshold, prescribed-intake
window duration, and two fixed forcing sequences. Goal 013 adds the bounded
hourly controller, Goal 014 adds a fixed sensitivity client, Goal 015 adds the
canonical repeated-day runner, and Goal 016 adds the non-depleting
forage-acquisition boundary. Goals 017-018 add fixed evidence-only recurrence
diagnostics, Goal 019 adds the pure mass conversion and current synthetic
reference scale, and Goal 020 adds the evidence-only duration response. The
next layer remains unapproved and is framed in
[`docs/roadmap.md`](docs/roadmap.md).

## Provenance

The preceding implementation is preserved in the private repository
`BWBrook/herbivoreTTR-legacy` at annotated tag
`legacy-final-2026-07-16`. The scientific baseline immediately preceding the
freeze is commit `abf68b691b4e30020625d1871dcabe56a5926bc1`.

Legacy R and C++ behavior is historical evidence only. Ecological logic,
dimensional consistency, empirical evidence, and transparent assumptions govern
the rebuild.
