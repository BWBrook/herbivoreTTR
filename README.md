# herbivoreTTR

`herbivoreTTR` is a small functional R package for transparent hourly models
of herbivore energetics, body water, and forage biomass. It is a clean
scientific rebuild: ecological logic, explicit units, and inspectable stock-
flow accounting take precedence over the historical implementation.

## Current Model

The completed herbivore core follows one 24-hour clock:

```text
feeding opportunity and appetite reference
  -> body- and gut-energy feedback
  -> bounded appetite target
  -> external forage-acquisition ceiling
  -> realized dry-matter intake
  -> metabolizable-energy input
  -> one-pool gut release
  -> body reserve minus maintenance and routine activity
  -> hourly ledger and daily summary
```

State is carried exactly between hours and days. The model uses plain lists and
data frames rather than an object system. Transition functions are pure, and
generated diagnostics do not write into the repository.

The isolated forage path currently provides accounting rather than plant
biology:

```text
opening standing forage biomass
  + prescribed growth
  - prescribed non-herbivore background loss
  -> closing standing forage biomass
```

It uses `kg DM ha^-1` on the same hourly clock and remains available as an
isolated reference path. The coupled path below composes it with animal intake.

The first process reference adds constant production and proportional
background loss:

```text
B[next] = (1 - tau) * B[current] + tau * B[equilibrium]
```

This linear turnover null has an exact positive equilibrium and monotonic
recovery from either side. It is not an empirical growth model.

Standing biomass maps to an animal-facing quantity through one fixed residual
threshold:

```text
accessible forage biomass = max(0, standing biomass - residual threshold)
```

This is a pure biomass-density transformation. It neither removes forage nor
defines how quickly an animal can acquire it.

The minimum non-spatial coupling then connects the two accepted subsystems:

```text
autonomous forage turnover
  -> accessible forage per represented animal
  -> appetite, rate, and stock ceilings
  -> realized per-animal intake
  -> gut input and density-scaled forage removal
  -> carried forage, gut, and body states
```

One representative physiology is scaled by a fixed animal density per hectare.
This is an aggregate homogeneous load, not an explicit population model.

The first explicit spatial layer adds named patches with fixed non-depleting
acquisition capacities and metabolizable-energy densities, one animal
location, directed one-hour known routes, and a prescribed daily itinerary. A
move changes the boundary location, suspends feeding during travel, and adds
its incremental expenditure to the accepted appetite-energy system. The
opening patch supplies both food properties during a stay. One transparent
patch-quality choice can rank staying against one known route over a declared
remaining feeding bout using fixed expected dry-matter demand.

The first landscape-constraint diagnostic reuses that spatial core for a
prescribed daily out-and-back trip to a named non-feeding water source. It
compares travel outside and inside the feeding window, separating route
expenditure from lost feeding opportunity. This travel-only null remains the
anchor for the separately implemented water physiology.

The minimum water layer carries one physical body-water stock. Effective water
from realized forage intake and drinking while stationary at a known source add
to the stock; fixed ordinary loss, prescribed incremental evaporative loss, and
any excess above normal remove water as separate fluxes. A critical boundary is
reported but does not alter the transition. The current experiment-level
controller visits the familiar source after body water reaches a declared
thirst threshold on the hourly clock. It composes with the accepted food-patch
system without combining the energy and water ledgers.

The first dynamic spatial-forage layer carries one standing-biomass stock per
patch, applies the accepted autonomous turnover to every patch, and removes
forage only from the occupied opening patch during a stay. A fixed 61-day
occupancy-release diagnostic depletes patch A, transfers the animal once, and
then shows patch A renewing while patch B depletes. Patch production remains
common and prescribed; the animal does not yet choose in response to biomass.

One diagnostic-only resource-aware choice now evaluates full stay and move
counterfactuals from the same opening state. This perfect-state, perfect-model
oracle stays under the accepted mild depletion but moves under a severe
stock-limited positive control. It establishes decision relevance without
adding a behavioral rule or repeated choice to the package.

A one-factor boundary diagnostic varies only occupied-patch opening biomass.
Under the current synthetic reference, the oracle moves through
`497.5 kg DM ha^-1` and stays from `498.0 kg DM ha^-1`. The switch occurs when
the extra metabolizable intake gained by moving no longer repays the fixed
`900 kJ` route expenditure; it remains a perfect-information benchmark.

One minimally informed null replaces exact forecasting with a one-hour
opening-state acquisition cue for the current patch and a prescribed expected
rate for the known destination. It agrees with the oracle except from
`498.0` through `500.0 kg DM ha^-1`, where it moves prematurely because it
cannot anticipate same-day forage renewal. This remains a single diagnostic
decision, not a repeated behavioral policy.

The repeated-choice diagnostic applies that rule once daily. Its 120-day
reference remains resident without energetic stress. The accepted
`50 animals ha^-1` pressure treatment continues to six moves on days 59, 117,
166, 213, 259, and 305. Intervals settle at 46 days as released forage and
animal states approach an alternating recurrence. Two one-day-late choices
cost `101 kJ` in total against the full-model oracle; both self-correct the next
day without chattering. The pattern is closed-loop and attributable, not a
generalized behavioral model.

The first explicit food-quality comparison holds acquisition non-limiting and
removes movement entirely. All-stay days at `10,000` and
`8,000 kJ kg DM^-1` reduce exactly to their non-spatial physiology references.
The adequate patch remains neutral; the lower-quality patch raises intake to
`0.3485 kg DM` but closes `412 kJ` below reference. Patch quality is therefore
transported correctly before it is allowed to affect movement or choice.

A matched one-day oracle then asks when quality alone repays travel to a fixed
`10,000 kJ kg DM^-1` destination. With equal non-limiting acquisition and the
accepted one-hour, `900 kJ` route, it moves through a current-patch density of
`7,300` and stays from `7,400 kJ kg DM^-1`. At the accepted `8,000` contrast,
staying is still better by `137 kJ`. The minimal patch-quality helper moves
through `6,500` and stays from `6,600`; it stays too early over the intervening
oracle-move region, with at most `168 kJ` realized regret. This transparent
fixed-demand rule is not a forecast of appetite or future body state.

The first biomass-quality interaction then runs the existing daily rule for
`305` matched days at `50 animals ha^-1`. Changing patch A alone from `10,000`
to `8,000 kJ kg DM^-1` advances the first move from day 59 to day 40 and
increases switching from six to eight events. Higher dry-matter demand depletes
the lower-quality patch faster and lowers the minimum body reserve from
`38,860` to `36,948 kJ`. Seven local daily oracle disagreements sum to
`2,919 kJ`: the simple rule both leaves the poor patch late and returns to it
early. This is an exposed limit of the operational null, not a fitted behavior
or a long-run oracle-policy comparison.

A bounded follow-up replaces that null with one last-experienced energy return
per patch. It moves from lower-quality A on day 41 but never returns: B's
renewable return stabilizes above the travel-adjusted stale memory of A, even as
A renews to `960.77 kg DM ha^-1`. Body reserve reaches `250 kJ` after day 146,
and neither day-147 action can preserve a non-negative reserve. Memory alone is
therefore insufficient. Its lower one-day regret (`1,333 kJ`) also confirms that
local oracle agreement is not a long-run policy score.

A day-101 checkpoint decomposition crosses that stale destination return with
the animal's own previously experienced abundant-patch return, and crosses a
one-day with a two-day decision horizon. Stale information favours staying at
both horizons. Recovered opportunity alone still favours staying by `295 kJ`
over one day, but recovered opportunity plus two days favours moving by
`511 kJ`. Matched full-model policies reproduce the same reversal: the
two-day move gains `1,411 kJ` of intake and pays the established `900 kJ`
route cost. Recovery information and a short consequence horizon are therefore
jointly required at this checkpoint. This is a diagnostic result, not an
implemented behavioral rule.

Carrying those ingredients for `305` days exposes a further distinction. A
candidate that relaxes each unvisited patch's experienced return toward its
historical best at the forage-turnover rate restores recurrent use: seven
switches occur without chattering or reserve-boundary failure. It is not an
acceptable behavioral model, however. Minimum body reserve falls to
`12,355 kJ`, and all `147` disagreements with a local full-model two-day
evaluator are false stays. Experienced return does not recover on the same
timescale as standing biomass in this flow-limited system. The candidate is
retained as a rejected diagnostic, not package behavior.

The bounded absence-to-return map then starts either destination at the
`500 kg DM ha^-1` residual boundary and lets it recover without herbivory for
prespecified absences from 0 to 60 days. Matched two-day full-model comparisons
show that lower-quality A first repays the route after one day and reaches its
return plateau after two, while higher-quality B repays the route immediately
and plateaus after one day. Standing biomass continues recovering for many
weeks. The result rejects biomass-timescale return recovery and points instead
to accumulated accessible forage plus continued production as the relevant
short-horizon opportunity, without yet promoting a behavioral rule.

A carried familiar-territory clock then lets expected return recover linearly
from last experience to historical best over two absent days, without exposing
unvisited biomass. It reduces two-day evaluator disagreements from `147` to
`43`, but produces `83` switches and `74,700 kJ` of movement expenditure.
Every selected move agrees with the full two-day evaluator, yet body reserve
falls to `9,386 kJ`. This rejects the clock and shows that locally correct
two-day choices can create a poor long-run path by repeatedly harvesting newly
accessible forage before either patch receives a long rest.

A fixed-state horizon decomposition localizes that failure. At day 60, leaving
depleted B for long-rested A becomes increasingly favourable from two through
fourteen days. At day 62, returning to B remains favourable through four days
but reverses by seven days (`-2,009 kJ`) and is strongly unfavourable by fourteen
(`-7,646 kJ`). The missing behavioral information is therefore not immediate
patch recovery but persistence: a scalar expected return does not say how long
the renewed feeding opportunity can support intake.

The accepted closure rule avoids inventing that forecast. It retains the
two-day return clock, stays whenever the current patch's experienced return
meets the `200 kJ` per feeding-opportunity-hour requirement, and accumulates
the energetic shortfall during an inadequate bout. The animal moves only when
the shortfall-adjusted two-day advantage repays travel. At the exact day-60 and
day-62 states it keeps the departure from depleted B and rejects the premature
return from adequate A. Across 305 days, switches fall from `83` to `9`, the
shortest return interval rises from 2 to 27 days, movement falls from `74,700`
to `8,100 kJ`, and minimum reserve rises from `9,386` to `36,221 kJ`.

The current synthetic reference uses:

| Quantity | Value |
| --- | ---: |
| Body-energy reserve | 40,000 kJ |
| Metabolizable-energy density | 10,000 kJ kg^-1 DM |
| Gut release fraction | 0.25 h^-1 |
| Maintenance expenditure | 100 kJ h^-1 |
| Feeding opportunity | hours 0-7 and 16-23 |
| Reference intake while feeding | 0.020 kg DM h^-1 |
| Routine activity while feeding | 50 kJ h^-1 |
| Maximum intake | 0.025 kg DM h^-1 |
| Forage equilibrium | 1,000 kg DM ha^-1 |
| Forage turnover fraction | 0.001 h^-1 |
| Residual unavailable forage | 500 kg DM ha^-1 |
| Coupled-reference animal density | 10 animals ha^-1 |
| Normal body water | 28 kg |
| Thirst trigger | 26 kg |
| Critical body-water boundary | 24 kg |
| Ordinary water loss | 1.56 kg d^-1 |

These are deliberately synthetic reference values, not an empirical kangaroo
parameterization.

## Install And Run

From the repository root:

```sh
R CMD INSTALL .
Rscript --vanilla experiments/herbivore-core-reference.R
Rscript --vanilla experiments/herbivore-core-appetite-forage.R
Rscript --vanilla experiments/herbivore-core-implicit-patches.R
Rscript --vanilla experiments/forage-stock-conservation.R
Rscript --vanilla experiments/forage-turnover-reference.R
Rscript --vanilla experiments/forage-availability-boundary.R
Rscript --vanilla experiments/nonspatial-coupled-reference.R
Rscript --vanilla experiments/nonspatial-animal-load-pulse.R
Rscript --vanilla experiments/explicit-known-route-movement.R
Rscript --vanilla experiments/explicit-prescribed-itinerary.R
Rscript --vanilla experiments/explicit-static-patch-acquisition.R
Rscript --vanilla experiments/explicit-known-patch-choice.R
Rscript --vanilla experiments/prescribed-water-source-excursion.R
Rscript --vanilla experiments/body-water-reference.R
Rscript --vanilla experiments/spatial-water-source-benefit.R
Rscript --vanilla experiments/hydration-controlled-water-visits.R
Rscript --vanilla experiments/water-constrained-patch-choice.R
Rscript --vanilla experiments/prescribed-evaporative-loss-regimes.R
Rscript --vanilla experiments/causal-hydration-response.R
Rscript --vanilla experiments/spatial-patch-depletion-renewal.R
Rscript --vanilla experiments/spatial-resource-aware-choice.R
Rscript --vanilla experiments/spatial-resource-aware-switch-boundary.R
Rscript --vanilla experiments/spatial-myopic-resource-choice.R
Rscript --vanilla experiments/spatial-experienced-adequacy-choice.R
Rscript --vanilla experiments/explicit-patch-food-quality.R
Rscript --vanilla experiments/spatial-food-quality-choice-boundary.R
```

Run the focused test suite with:

```sh
Rscript --vanilla -e 'testthat::test_local()'
```

The experiment scripts print compact summaries and create no files. Historical
goal-by-goal clients remain recoverable from Git and are not part of the active
execution path.

## Public Surface

The package exposes nine related groups:

- plain state, parameter, and 24-hour schedule constructors;
- one-hour gut and body transitions;
- one-day body-only and coupled gut-body runners;
- a repeated-day reference-cycle and appetite-controlled runner;
- pure food-energy and body-mass conversions;
- an independent body-water stock-flow day plus a spatial adapter from realized
  forage intake and stationary drinking access;
- isolated forage accounting, a constant-turnover reference and repeated-day
  runner, and a pure standing-to-accessible biomass transformation;
- a density-scaled herbivory step and repeated-day non-spatial coupled runner;
- explicit patch-landscape, location, food-property, and itinerary records
  plus known-route movement, one-day prescribed spatial composition, and one
  patch-quality feeding-bout choice.

See [`docs/model-specification.md`](docs/model-specification.md) for equations
and transition order, and [`docs/variable-dictionary.md`](docs/variable-dictionary.md)
for the current variables and units.

## Scientific Boundary

The herbivore and forage systems now have one minimum homogeneous coupling.
The plant side contains prescribed biomass accounting, a linear turnover
reference, and a fixed residual-threshold availability boundary. Realized
per-animal intake is scaled by a fixed density and removed from forage, while
accessible biomass can cap intake. A diagnostic animal-load pulse demonstrates
depletion, stock-limited intake, animal-energy loss, and recovery after release
without adding population state. The non-spatial coupling still has no
environmental forcing, seasonality, explicit multiple animals, protein,
thermoregulation, or mass-dependent feedback.

The non-spatial and explicit-patch arcs are closed. The landscape-constraints
stage now has one prescribed water-source excursion and one conserved dynamic
forage stock per patch under a fixed itinerary. A single perfect-information
counterfactual benchmark shows when that resource state can change the preferred
action, and a one-factor sweep locates its current synthetic stay-move boundary.
One myopic intake-rate cue then exposes a narrow cost of incomplete dynamic
information. Repeating that cue once daily produces stable residency at
reference density and an approach to a 46-day reciprocal recurrence under
established pressure. Two small, one-day-late oracle disagreements expose the
rule's inability to anticipate same-day renewal without destabilizing the
loop. Travel, timing, depletion, renewal, and decision relevance remain
separately attributable. Patch-specific metabolizable-energy density now
reproduces the accepted physiology under all-stay conditions. A matched oracle
also shows that quality alone changes the preferred action only below the
current synthetic `7,300` to `7,400 kJ kg DM^-1` bracket; the accepted `8,000`
contrast does not repay travel. Combining that contrast with dynamic biomass
advances and increases switching while exposing both late exits from poor
forage and early returns to it. A diagnostic last-experience memory then fails
because it cannot value unobserved forage renewal or consequences beyond one
day. A bounded day-101 decomposition confirms that recovered opportunity and a
two-day horizon are jointly sufficient to reverse that trapped choice, while
neither change alone is sufficient. A first carried implementation restores
revisitation but systematically stays too long and causes deep reserve cycles,
rejecting direct turnover-rate relaxation of experienced return. A faster
experience-and-time-only clock instead produces a locally supported 2/4-day
rotation, but its travel cost drives a still deeper reserve decline. This
shifts the next diagnostic boundary from recovery timing to consequence
horizon. A fixed-state comparison then shows that leaving depleted B is robust,
but returning after two days becomes unfavourable between four and seven days.
The accepted experience-based closure retains the two-day recovery memory but
refuses to leave a patch while realized return remains energetically adequate;
once inadequate, cumulative shortfall lets a small chronic deficit eventually
repay travel. It resolves both fixed checkpoints, produces nine switches no
closer than 27 days in the baseline, and remains stable across the bounded
movement, food-quality, and viable forage-recovery comparisons. This is
accepted experiment-level behavior, not package API or a viability claim.
The minimum body-water layer now separates forage water, drinking, ordinary
loss, prescribed incremental evaporative loss, source access, and route energy.
Disabling it reproduces the accepted forage-choice anchor exactly. Wetter
forage reduces visits and protects energy; under drier forage or greater
ordinary loss, frequent water excursions reach the energy boundary before the
declared critical-water boundary. Prescribed clustered, repeated, diffuse, and
sustained loss regimes now show that equal cumulative loss can produce unequal
visit timing and recovery. A causal hourly controller protects the water stock
but can move source travel into feeding hours. Under sustained forcing, that
controller reaches the energy boundary after 76 treatment days while remaining
above the synthetic critical-water boundary. These are mechanism results, not
calibrated viability claims. Temperature-response physiology, anticipatory
scheduling, dynamic plant moisture, renal response, multiple water sources, and
package-level repeated behavioral mechanisms remain absent. The staged
programme is indexed in
[`docs/roadmap.md`](docs/roadmap.md).

## Repository Map

- `R/`: reusable model records, transitions, and runners.
- `tests/testthat/`: focused protection of scientific invariants.
- `experiments/`: twenty-six current no-write diagnostics and four shared
  fixture helpers.
- `docs/model-charter.md`: governing scientific and architectural contract.
- `docs/model-specification.md`: equations, transition order, and outputs.
- `docs/variable-dictionary.md`: current quantities and units.
- `docs/decisions/`: retained scientific decision record.
- `docs/arcs/`: stage-level development plans.

The project is licensed under the MIT License.
