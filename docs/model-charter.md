# Model Charter

## Purpose

Develop a scientifically legible herbivore energetics model in which every
state transition, unit, assumption, and derived output can be inspected. The
rebuild begins from an intentionally small controlled system and adds ecological
complexity only when the preceding layer is understood.

## Governing Authority

Ecological logic, dimensional consistency, empirical evidence, and transparent
assumptions govern model design. Legacy behavior may motivate questions or
comparisons, but is never scientific truth or architectural authority.

## Architecture

- R is the only implementation language.
- Package code is functional; experiments are thin clients.
- State is represented by plain validated records.
- State, fixed parameters, prescribed inputs, processes, and history remain
  distinct.
- Conversion and process functions are pure and use names and documentation
  with explicit unit suffixes.
- Generated outputs remain outside source control.

## Work Contract

Each goal has one principal question and one subsystem, predeclares compact
outputs and proportionate tests, and ends at an explicit stopping point.
Results are discussed before the next layer is authorized. Bulk evidence
machinery is not part of this model-development approach.

## Current Executable Boundary

The executable model retains two coupled stocks: one gut-energy buffer and one
physical body-energy reserve. Upstream, a pure accounting bridge multiplies a
prescribed 24-hour dry-matter ingestion schedule in kg DM h^-1 by one fixed,
strictly positive metabolizable-energy density in kJ kg^-1 DM. The resulting
kJ h^-1 schedule is the exact existing input to the gut model.

The density is already metabolizable and collapses every unmodelled step
between dry matter and model-available energy. Its product is treated as the
accounting equivalent entering `gut_available_energy_kj`; it is not a
physiological calculation of digestion, assimilation efficiency, or loss.
Prescribed dry matter is ingestion, not offered or available forage, wet or
as-fed mass, or output from a modeled feeding decision. The caller retains the
food parameter, intake schedule, converted energy schedule, and downstream
result as separate objects. The food bridge introduces no new state.

During each of 24 fixed one-hour transitions, a fixed fraction of the opening
gut stock is released and transferred one-for-one into the body ledger, while
constant maintenance expenditure and prescribed routine-activity expenditure
leave the body reserve. The package returns an exact hourly ledger and a daily
summary derived from that ledger.

Maintenance remains one fixed synthetic parameter in kJ h^-1. Routine activity
is a separate, externally prescribed, finite, non-negative 24-hour schedule in
kJ h^-1 and is incremental to maintenance. Every body transition and runner
requires that forcing explicitly; there is no implicit zero schedule. For each
one-hour transition, body change in kJ equals assimilated energy minus
maintenance expenditure minus prescribed routine-activity expenditure.

Gut stock is expressed in assimilable-energy equivalents. Release precedes
current-hour ingestion, so newly ingested energy is not eligible for release
until the next transition. Separate gut, body, and combined-system residuals
make the internal transfer and external inputs and expenditures inspectable.

For repeated identical daily forcing, the reference-cycle runner can advance
only the gut until successive 25-boundary daily trajectories and the
period-24 boundary close within a declared numerical tolerance. It then uses a
declared body state once at the measurement boundary and calls the daily runner
for two measured days with exact gut and body carry-over. The declared activity
schedule applies only to those measured body days. Burn-in creates no body
history, incurs no activity expenditure, and the body is not reset between
measured days.

The reset is a diagnostic protocol rather than a biological process. Gut-cycle
stability and measured body-energy neutrality are separate properties: a
repeatable gut trajectory can accompany persistent deficit or surplus. The
convergence tolerance describes floating-point resolution only, and daily
timing equivalence is interpreted only after numeric body-path feasibility is
verified.

Only the product of dry-matter intake and density enters downstream dynamics,
so those prescribed inputs are structurally non-identifiable from the resulting
energy trajectories. Equivalent products demonstrate an accounting property,
not biological interchangeability among foods or feeding regimes.

Goal 006 adds no executable mechanism or interface. It retains the continuous
100 kJ h^-1 schedule as the permanent mathematical diagnostic and establishes a
minimally ecological prescribed reference with 150 kJ h^-1 in hours 0 through 7
and 16 through 23 and zero intake in hours 8 through 15. At the fixed fixture
density of 10000 kJ kg^-1 DM, these rates correspond to 0.010 and 0.015 kg DM
h^-1 respectively, and both references prescribe 0.24 kg DM and 2400 kJ per
day.

The ecological schedule closes intake during the half-open interval
`[08:00, 16:00)`. That closure is a prescribed input convention, not a modeled
feeding decision, activity or sleep state, or observation of behavior. Equal
steady-cycle daily energy totals form an operational accounting null in the
current linear, lossless, unlimited system; within-day gut, release, and
body-reserve trajectories remain distinct.

Goal 007 adds the first separable non-maintenance expenditure component without
changing gut dynamics. Its zero-activity schedule preserves the Goal 006
references on shared numerical fields. Its separate four-hour diagnostic pulse
prescribes 50 kJ h^-1 during `[08:00, 12:00)`, giving exactly 200 kJ of
additional body expenditure per measured day while gut stock, ingestion,
assimilation, and convergence remain unchanged.

The activity schedule is imposed by the caller. It is not behavior, directed
locomotion, exercise, thermic effect of food, total metabolism, or an emergent
response. The zero fixture is a regression control and the pulse is an
arithmetic probe; neither supplies empirical evidence about animal activity or
physiology.

Goal 008 adds no executable mechanism. It uses the accepted functions to compare
`ecological_day_resting`, `ecological_activity_uncompensated`, and
`ecological_activity_prescribed_balance`. All prescribe intake during hours
`0:7` and `16:23` and close intake during hours `8:15`; the two activity
fixtures prescribe 50 kJ h^-1 over the same 16 non-rest intervals.

The observed daily input, assimilation, and activity totals are
`2400 / 2400 / 0 kJ`, `2400 / 2400 / 800 kJ`, and
`3200 / 3200 / 800 kJ`. All three gut cycles converge on burn-in day 7.
Observed body change is approximately `0 kJ`, `-800 kJ`, and `0 kJ` per
measured day. The zero-activity and uncompensated gut ledgers match exactly in
memory, while the balanced gut and assimilation paths follow the predicted
`4/3` scaling within approximately `1.14e-13 kJ`.

The balanced fixture is the normal synthetic ecological accounting reference.
The Goal 006 zero-activity ecological fixture remains its comparator, and the
continuous mathematical fixture remains the permanent arithmetic and
regression diagnostic. The balanced input of `200 kJ h^-1`, equivalent to
`0.32 kg DM d^-1` under the fixed fixture density, is prescribed rather than
shown feasible. Its approximate daily neutrality is not behavior, adaptive
compensation, biological equilibrium, viability, or empirical physiology.

Goal 009 adds evidence without changing this executable boundary. An evidence
client clips the Goal 008 candidate prescription of `0.020 kg DM h^-1` over 16
active intervals against synthetic ceilings of `0.015`, `0.020`, and
`0.025 kg DM h^-1`. The exact conditional accounting threshold is
`0.020 kg DM h^-1`, or `200 kJ h^-1`: the lower ceiling reproduces the Goal 008
uncompensated result, while the at- and above-threshold ceilings reproduce the
balanced result.

The candidate, ceiling, constrained prescription, curtailed prescription,
strict exceedance, exact positive touching, and unused active-ceiling headroom
remain separate evidence quantities. Curtailment is discarded. The synthetic
ceiling is a client-side prescription for locating an accounting threshold,
not appetite, feeding behavior, forage availability, gut capacity, intake
redistribution, or a package-level constraint.

Goal 010 also adds evidence without changing the executable boundary. Its
formal client-side field is `prescribed_intake_window_open`, which defines a
prescribed intake window: every open interval is fully used at the fixed
prescription of `0.020 kg DM h^-1`, or `200 kJ h^-1`. Windows of 24, 16, 12,
and 8 h d^-1 therefore prescribe
`4800, 3200, 2400, 1600 kJ` per day against fixed daily maintenance and routine
activity of `2400 kJ` and `800 kJ`. Their analytical daily body changes are
`+1600, 0, -800, -1600 kJ`, with whole-kilojoule day 1/day 2 closes of
`11600 / 13200`, `10000 / 10000`, `9200 / 8400`, and `8400 / 6800 kJ`.

The 16-hour result is exactly the Goal 008 balanced reference. The 12-hour
fixture shares only the declared daily input, expenditure, body-change, status,
and closing-reserve results with the Goal 008 uncompensated fixture; their
hourly schedules, periodic gut states, within-day trajectories, and complete
results differ. The daily duration relation is clean because rate and activity
are fixed, but within-day trajectories also depend on placement: the 24-hour
comparator opens `[08:00, 16:00)`, while the shorter restricted fixtures remove
central-night prescribed-intake hours. An open prescribed-intake interval is
not voluntary access, realized behavior, or demonstrated capacity.

Goal 011 adds a fixed three-day evidence sequence without changing the
executable boundary. The control receives balanced forcing on all three days;
the treatment receives the lower `0.015 kg DM h^-1` rate on day 1 and balanced
forcing on days 2 and 3. Both start from one common balanced period-24 gut state
and one `10000 kJ` body state, and both stocks carry exactly between days
without another reset.

The lower-rate schedule is the schedule used by Goal 008
`ecological_activity_uncompensated`, but its Goal 011 result is not the Goal 008
periodic result because the shortfall day opens from the balanced periodic gut.
Under the `one_day_rate_shortfall - all_balanced_control` convention, the
external prescribed-input contrast and combined-system contrast reach
`-800 kJ` at 24 hours. With identical forcing thereafter, the combined-system
contrast stays at `-800 kJ`.

During return-to-reference forcing, the gut contrast contracts by `0.75` per
hour, or `0.75^24` per day, and the body contrast equals
`-800 kJ - gut-stock contrast`. This is numerical gut-state realignment, not
body-energy or whole-system restoration and not evidence of biological or
physiological recovery. The evidence clients chain existing one-day calls;
they add no production multi-day API, state, equation, or feedback.

The 50 kg reference mass used in the Goal 002 demonstration is experiment
metadata only. No implemented equation depends on body mass. All food-energy
and gut-body fixtures are synthetic. The current layer establishes unit
conversion, arithmetic closure, delayed stock-flow behavior, accounting
semantics, and opening-to-closing state continuity; it does not establish
empirical realism, animal viability, ecological equilibrium, or chronic
multi-day dynamics.

## Current Stop Boundary

The implemented gut stock is energy, not dry matter, gross energy, plant
biomass, or measured gut fill. Variable or stochastic days, configurable
measurement horizons, seasons, chronic decline, recovery, and viability
criteria are absent. Offered and wet forage, variable or multiple foods,
digestive loss, efficiency, waste, capacity, production intake limits, feeding
behavior, activity choice or feedback, directed locomotion, dynamic body mass,
protein, water, thermoregulation, plants, space, calibration, and all other
physiological or ecological detail remain outside the executable boundary.

Goals 009 through 011 establish only the declared synthetic threshold,
prescribed intake window, and one-day forcing-transition evidence. Their
client-side fields are not package state or schemas, and Goal 011's fixed
three-day sequence is not a generalized production runner. Goal 012 remains
unapproved; its scientific question and any later mechanism remain undecided.

The predecessor is preserved privately as `BWBrook/herbivoreTTR-legacy` at tag
`legacy-final-2026-07-16`; its scientific baseline commit is
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
