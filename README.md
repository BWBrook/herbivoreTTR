# herbivoreTTR

`herbivoreTTR` is a small functional R package for transparent hourly models
of herbivore energetics and forage biomass. It is a clean scientific rebuild:
ecological logic, explicit units, and inspectable stock-flow accounting take
precedence over the historical implementation.

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
expenditure from lost feeding opportunity. The water source currently has no
drinking benefit, duration, or physiological state.

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
Rscript --vanilla experiments/spatial-patch-depletion-renewal.R
Rscript --vanilla experiments/spatial-resource-aware-choice.R
Rscript --vanilla experiments/spatial-resource-aware-switch-boundary.R
Rscript --vanilla experiments/spatial-myopic-resource-choice.R
Rscript --vanilla experiments/spatial-daily-myopic-choice.R
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

The package exposes eight related groups:

- plain state, parameter, and 24-hour schedule constructors;
- one-hour gut and body transitions;
- one-day body-only and coupled gut-body runners;
- a repeated-day reference-cycle and appetite-controlled runner;
- pure food-energy and body-mass conversions;
- isolated forage accounting, a constant-turnover reference and repeated-day
  runner, and a pure standing-to-accessible biomass transformation; and
- a density-scaled herbivory step and repeated-day non-spatial coupled runner;
  and
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
environmental forcing, seasonality, explicit multiple animals, protein, water,
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
forage and early returns to it. Water physiology and anticipatory,
state-responsive, or package-level repeated behavioral mechanisms remain
absent. The staged
programme is indexed in
[`docs/roadmap.md`](docs/roadmap.md).

## Repository Map

- `R/`: reusable model records, transitions, and runners.
- `tests/testthat/`: focused protection of scientific invariants.
- `experiments/`: twenty current no-write diagnostics and one fixture helper.
- `docs/model-charter.md`: governing scientific and architectural contract.
- `docs/model-specification.md`: equations, transition order, and outputs.
- `docs/variable-dictionary.md`: current quantities and units.
- `docs/decisions/`: retained scientific decision record.
- `docs/arcs/`: stage-level development plans.

The project is licensed under the MIT License.
