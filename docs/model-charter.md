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
gut stock is released and transferred one-for-one into the unchanged body
ledger, while constant maintenance expenditure leaves the body reserve. The
package returns an exact hourly ledger and a daily summary derived from that
ledger.

Gut stock is expressed in assimilable-energy equivalents. Release precedes
current-hour ingestion, so newly ingested energy is not eligible for release
until the next transition. Separate gut, body, and combined-system residuals
make the internal transfer and external inputs and expenditures inspectable.

For repeated identical daily forcing, the reference-cycle runner can advance
only the gut until successive 25-boundary daily trajectories and the
period-24 boundary close within a declared numerical tolerance. It then uses a
declared body state once at the measurement boundary and calls the unchanged
daily runner for two days with exact gut and body carry-over. Burn-in creates no
body history, and the body is not reset between measured days.

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

The 50 kg reference mass used in the Goal 002 demonstration is experiment
metadata only. No implemented equation depends on body mass. All food-energy
and gut-body fixtures are synthetic. The current layer establishes unit
conversion, arithmetic closure, delayed stock-flow behavior, accounting
semantics, and opening-to-closing state continuity; it does not establish
empirical realism, animal viability, ecological equilibrium, or chronic
multi-day dynamics.

## Current Stop Boundary

No later layer is specified or authorized. The implemented gut stock is energy,
not dry matter, gross energy, plant biomass, or measured gut fill. Variable or
stochastic days, configurable measurement horizons, seasons, chronic decline,
recovery, and viability criteria are absent. Offered and wet forage, variable
or multiple foods, digestive loss, efficiency, waste, capacity, intake limits,
feeding behavior, and body feedback are also absent. Activity, dynamic body
mass, protein, water, thermoregulation, plants, space, calibration, and all
other physiological or ecological detail remain outside the executable
boundary. Goal 006 results must be discussed before the next principal question
is chosen. The mathematical and ecological references do not themselves
authorize a later mechanism or scenario.

The predecessor is preserved privately as `BWBrook/herbivoreTTR-legacy` at tag
`legacy-final-2026-07-16`; its scientific baseline commit is
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
