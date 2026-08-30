# Active Surface

## Product Promise

`herbivoreTTR` provides inspectable hourly stock-flow models for herbivore
energy, forage biomass, their minimum non-spatial coupling, and one prescribed
explicit-patch day with static acquisition and food-energy heterogeneity plus a
bounded patch-quality choice.
One retained scenario imposes a prescribed trip to a named water source without
water physiology. A second prescribed spatial path carries and locally removes
dynamic forage biomass by patch. Its current user is Barry Brook. Its purpose
is scientific understanding, not a general-purpose simulation platform.

## Canonical Paths

The one-day physiological path is:

```text
dry-matter intake x metabolizable-energy density
  -> gut input
  -> release from opening gut stock
  -> body input
  -> maintenance and routine activity
  -> closing gut and body stocks
```

`run_gut_body_energy_day()` is the canonical prescribed-input day.
`run_gut_body_energy_reference_cycle()` establishes a periodic gut opening
state. `run_appetite_controlled_energy_days()` is the canonical repeated-day
path when intake responds to body and gut state and is capped by an external
forage-acquisition schedule.

`derive_body_mass_from_energy_reserve()` is a downstream interpretation. Its
result is never stored in or fed back to a transition.

The isolated forage path is:

```text
opening standing biomass + prescribed growth - prescribed background loss
  -> closing standing biomass
```

`run_forage_biomass_day()` is the canonical plant-side accounting day. It has
no endogenous growth equation and no connection to herbivore intake.

`run_forage_turnover_days()` is the canonical constant-reference trajectory.
It combines constant production with proportional background loss around a
declared equilibrium, still without herbivore intake or environmental forcing.

`derive_accessible_forage_biomass()` is a pure animal-facing interpretation of
standing biomass. It subtracts a fixed residual threshold and floors the result
at zero; it does not change forage state or define an acquisition rate.

`step_forage_herbivory()` is the pure scaling and removal bridge.
`run_nonspatial_coupled_energy_days()` applies autonomous turnover, availability,
appetite, removal, and the accepted gut-body transition on the shared clock.

`new_known_route_landscape()` and `new_patch_location_state()` define the first
explicit spatial records, including one fixed acquisition capacity and
metabolizable-energy density per patch.
`step_known_route_movement()` moves the focal animal over one known one-hour
route, suspends feeding, and exposes incremental movement expenditure for
composition with the energy model.
`new_prescribed_patch_itinerary()` declares the closing patch at every hourly
boundary. `run_prescribed_spatial_energy_day()` infers stay versus move and
composes that itinerary with the accepted appetite-energy day, using the
opening patch's energy density during each interval.
`new_spatial_forage_biomass_state()` adds one ordered dynamic biomass stock per
landscape patch. `run_prescribed_spatial_coupled_energy_day()` applies common
turnover to all patches, local herbivory during occupied stays, movement, and
animal energetics, then returns composable location, gut, body, and forage
states.
`choose_known_patch_for_feeding_bout()` ranks staying against one known route
using a declared fixed demand, remaining feeding opportunity, and the two
patches' acquisition capacities and metabolizable-energy densities. It is a
choice heuristic, not a forecast of the ensuing appetite-energy trajectory.

The retained resource-aware choice is deliberately diagnostic-only. It runs
the accepted stay and move counterfactuals once from the same complete opening
state and uses closing combined energy as a perfect-model benchmark. It does
not add a behavioral API. A one-factor sweep locates the current synthetic
stay-move transition between `497.5` and `498.0 kg DM ha^-1` and attributes it
to intake energy gained relative to the `900 kJ` route cost.

The first minimally informed comparison converts current opening accessible
forage into a one-hour attainable acquisition-rate cue and gives the known
destination a prescribed expected rate. It agrees with the oracle outside a
narrow `498.0` to `500.0 kg DM ha^-1` interval, where omitted within-day renewal
causes premature movement. It remains diagnostic-only.

One closed-loop diagnostic applies that cue daily while carrying location,
forage, gut, and body state. The reference load produces stable residence. The
accepted pressure load reaches six alternating moves by day 305, with the last
two intervals both 46 days and converging same-direction forage and animal
states. Two small, one-day-late oracle disagreements self-correct without
chattering. Repeated choice remains outside the package API.

One independent food-quality oracle holds acquisition non-limiting, removes
biomass dynamics, fixes the destination at `10,000 kJ kg DM^-1`, and varies
only current-patch energy density. Under the accepted `900 kJ` hour-0 route,
the oracle moves through `7,300` and stays from `7,400 kJ kg DM^-1`. The
accepted `8,000` contrast favours staying by `137 kJ`. This remains a
perfect-model diagnostic. The minimal patch-quality helper moves through
`6,500` and stays from `6,600 kJ kg DM^-1`; it stays too early through `7,300`,
with at most `168 kJ` realized regret.

The matched 305-day biomass-quality interaction changes patch A alone from
`10,000` to `8,000 kJ kg DM^-1` under the accepted pressure load. The first
move advances from day 59 to day 40, six switches become eight, and minimum
body reserve falls from `38,860` to `36,948 kJ`. Seven local daily oracle
disagreements expose late exits from poor forage and early returns to it. The
rule remains an explicitly fallible operational null.

One diagnostic alternative stores only the last realized energy return per
feeding-opportunity hour for each patch. It leaves lower-quality A on day 41,
then remains in B until body reserve reaches `250 kJ` after day 146, even while
A renews unobserved to `960.77 kg DM ha^-1`. Neither day-147 action preserves a
non-negative reserve. This is a failed sufficiency test for memory alone, not
accepted behavior. Its lower local regret also demonstrates that the one-day
oracle is not a long-run policy score.

The accepted day-101 decomposition holds the animal, gut, and forage snapshot
fixed and crosses stale versus recovered destination information with one- and
two-day horizons. The recovered value is the animal's own maximum previously
experienced return in patch A (`200 kJ` per feeding-opportunity hour), not
current biomass or perfect-model knowledge. Stale information favours staying
at both horizons; recovered information still favours staying by `295 kJ` over
one day, but favours moving by `511 kJ` over two days. Full-model policies
match the score reversal exactly, with `1,411 kJ` greater two-day intake offset
by the `900 kJ` route cost. The result identifies a joint information-horizon
requirement without adding package behavior.

The first carried candidate keeps last and historical-best returns plus days
since visit, relaxes unvisited return toward the best at the established forage
turnover rate, and applies the two-day score for `305` days. It completes the
run and switches seven times at intervals of `32` to `60` days, eliminating
the one-way trap without chattering. The result is nevertheless rejected:
minimum body reserve falls to `12,355 kJ`, and all `147` local two-day oracle
disagreements are false stays. Return opportunity recovers faster than
standing biomass under the current production and accessibility rules, so
experienced return must not inherit the biomass turnover timescale directly.

The absence-to-return diagnostic maps that mismatch directly. Starting either
destination at the residual boundary, realized two-day return recovers over
one to two days: lower-quality A first repays the route after one day and
reaches its return plateau after two, while higher-quality B repays it
immediately and plateaus after one. Standing biomass continues recovering for
weeks. Accumulated accessible forage plus continuing production is the leading
mechanistic explanation, but the map does not yet separate those contributions
or add behavior.

The first carried fast-recovery candidate uses only last and historical-best
experienced returns plus elapsed absence, reaching the best after two days.
It reduces local two-day evaluator disagreements from `147` to `43` but settles
into two days in A and four days in B, producing `83` switches and `74,700 kJ`
of movement expenditure. Every selected move agrees with the evaluator, yet
minimum reserve falls to `9,386 kJ`. The rule is rejected: accurate local
recovery knowledge plus a two-day objective is not sufficient for a good
long-run trajectory.

## Protected Invariants

- Every modeled quantity has an explicit unit suffix.
- The clock is 24 one-hour intervals labelled `0:23`.
- Dynamic stocks and prescribed inputs are finite and non-negative.
- A negative closing body reserve or forage stock fails explicitly.
- Gut release uses opening stock; current intake enters after release.
- Assimilation transfers energy between modeled stocks and cancels from the
  whole-system balance.
- Hourly and daily gut, body, and whole-system identities close numerically.
- Closing stocks carry exactly into the next interval and day.
- Appetite equals its reference on the reference trajectory, is zero when
  feeding opportunity is closed, and remains within declared bounds.
- Realized intake is the smallest of appetite target, external acquisition-rate
  ceiling, and accessible forage per represented animal.
- Hourly and daily forage stock-flow identities close numerically.
- The turnover reference is neutral at equilibrium and approaches it
  monotonically from positive low or high biomass.
- Accessible forage is non-negative, no greater than standing forage, and
  increases one-for-one only above the declared residual threshold.
- Herbivory removal equals realized per-animal intake times animal density.
- Herbivory cannot remove forage below the residual threshold.
- The constant coupled reference repeats over 24 hours with neutral daily
  animal-energy balance.
- Patch and route identifiers are unique and every route endpoint is valid.
- A known-route move starts at its declared origin, suspends feeding during
  travel, and closes at its destination with route expenditure reported
  exactly. The hour-16 anchor loses one otherwise open feeding hour.
- An all-stay itinerary reduces exactly to the non-spatial reference. Travel
  time and actual feeding time lost remain separately observable.
- During a stay, the opening patch supplies the applied non-depleting
  acquisition ceiling and metabolizable-energy density; during travel,
  acquisition is zero.
- At either accepted patch density, an all-stay day reduces exactly to the
  corresponding scalar-food non-spatial physiology.
- The one-choice null applies each candidate patch's energy density, subtracts
  travel time and route expenditure, selects stay on ties, and is checked
  against both full-model counterfactuals.
- The prescribed water trip makes exactly two matched route transitions and
  separates movement expenditure from feeding time lost through trip timing.
- Every dynamic patch closes as opening biomass plus autonomous growth minus
  background loss and local herbivory; unoccupied and movement-hour patches
  have zero herbivory.
- An all-stay dynamic patch reduces exactly to the non-spatial coupling, while
  an unoccupied patch reduces exactly to isolated turnover.
- The resource-aware oracle compares matched full-model counterfactuals, stays
  on a tie, and is labelled as perfect information rather than behavior.
- Across the retained biomass sweep, movement advantage is non-increasing and
  equals extra metabolizable intake minus route expenditure.
- Across the retained food-quality sweep, movement advantage is non-increasing,
  the helper and oracle each have one transition, realized regret is
  non-negative, and full-model advantage equals the difference in ingested
  energy minus route expenditure.
- The myopic resource cue is derived from opening accessible forage, has one
  decision transition, and reports non-negative regret against the oracle.
- In the retained repeated-choice comparison, every daily action is checked
  against both full counterfactuals before only the myopic result is carried.
- The biomass-quality comparison changes one patch energy density only, holds
  both pressure runs to 305 days, and keeps local daily oracle regret distinct
  from a separately carried policy comparison.
- Synthetic balance is not interpreted as viability or empirical calibration.

## Retained Surface

| Surface | Disposition |
| --- | --- |
| Functional package core | Retain and extend by approved layers |
| Explicit records, units, and balance residuals | Retain |
| Twenty-two current diagnostics | Retain |
| Focused invariant tests | Retain |
| Scientific decision notes | Retain as the research notebook |
| Goal-by-goal experiment ancestry | Removed from the active tree; Git retains it |
| Exotic numeric-class compatibility | Removed |
| Generated outputs and review machinery | Keep ignored or disposable |
| Compatibility adapters and dormant flags | Decline |

## Validation

For ordinary changes, parse retained R, run the tests affected by the change,
and inspect the diff. When publishing a package boundary or completed model
stage, run the full focused suite, all twenty-two diagnostics, an external build,
and `R CMD check --no-manual` once.

Repeat a gate only for a distinct named risk. Additional polish or repeated
confirmation is not a release criterion.

## Current Stop

The herbivore, isolated forage, and non-spatial coupling arcs are closed. The
coupled system has a stable period-24 reference and one controlled animal-load
pulse with attributable depletion, intake limitation, and recovery. The first
explicit spatial arc is also closed: location, known-route travel, static patch
capacity, a prescribed day, and one validated choice are separated cleanly.
Arc 05 now separates one prescribed water-source trip from one fixed-itinerary
dynamic-forage comparison. One diagnostic perfect-information choice shows
that the accepted mild depletion does not justify movement, whereas severe
stock limitation does. Travel, timing, depletion, renewal, and decision
relevance remain inspectable. Protein, water balance, thermoregulation,
environmental forcing, anticipatory or state-responsive behavioral choice, and
explicit population dynamics remain deferred. Patch-specific
metabolizable-energy density reproduces its accepted all-stay physiological
response exactly. One diagnostic oracle locates where quality alone repays the
fixed route, and one minimal patch-quality score exposes its bounded
information error. The first
dynamic biomass-quality interaction is attributable, but it also shows that
the operational choice rule is not yet a minimally realistic behavioral model.
A last-experience memory does not close that gap. The day-101 decomposition
shows why: neither recovered opportunity information nor a two-day consequence
horizon is sufficient alone, but together they reverse the trapped choice in
both the transparent score and full model. The next decision is how to carry
those two ingredients through time without granting perfect biomass knowledge.
Direct turnover-rate relaxation of experienced return has now been rejected;
the absence map shows that realized opportunity recovers within one to two days
despite weeks-long standing-biomass recovery. Carrying that fast expectation
then produces a locally supported but physiologically poor 2/4-day rotation.
The next diagnostic should hold a representative cycling state fixed and vary
only consequence horizon, before any cooldown, behavioral parameter, or new
ecological layer is considered.
