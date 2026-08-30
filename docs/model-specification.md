# Model Specification

## Scope

The current package implements a synthetic hourly herbivore-energy model, an
isolated forage-biomass ledger, their minimum non-spatial coupling, and one
prescribed explicit-patch day built from known-route transitions. The spatial
null also includes patch-specific metabolizable-energy density, one bounded
patch-quality stay-versus-known-route choice over a declared remaining feeding
bout, and one fixed-itinerary runner with dynamic forage biomass in every
patch. The animal model tracks energy entering
through dry-matter intake, delayed in one gut stock, and transferred to a
body-energy reserve after maintenance and routine activity. An appetite
controller can set intake demand, while an external rate schedule can constrain
forage acquisition. The plant-side ledger carries standing biomass under
prescribed growth and background loss. A pure residual-threshold transformation
derives accessible biomass. The first non-spatial coupling scales per-animal
intake by a fixed animal density and removes the corresponding forage biomass.

The model is deterministic. All rates apply over one-hour intervals, so their
one-hour amounts have the same numerical value but retain distinct names.

## Clock And State

Each day contains intervals `hour_of_day = 0:23`. Interval `h` represents
`[h, h + 1)`. Depending on the composed runner, the implemented dynamic state
contains:

- `gut_available_energy_kj`: energy available for later release from the gut;
- `body_energy_reserve_kj`: labile body-energy reserve; and
- `forage_biomass_kg_dm_ha`: one homogeneous standing biomass density or one
  density keyed to every landscape patch; and
- `patch_id`: the named patch occupied by the focal animal at an hourly
  boundary.

All stocks are finite and non-negative. Closing stocks become the next
interval's opening stocks without implicit reset or clamping.

## Fixed Parameters

- `gut_release_fraction_h` is in `(0, 1]`.
- `maintenance_expenditure_kj_h` is non-negative.
- `metabolizable_energy_density_kj_kg_dm` is strictly positive.
- appetite feedback fractions are non-negative.
- `maximum_dry_matter_intake_kg_dm_h` is strictly positive.
- `residual_unavailable_forage_threshold_kg_dm_ha` is non-negative.
- `herbivore_density_animals_ha` is strictly positive.

Metabolizable-energy density is already an available-energy quantity. The
current model does not separately represent gross energy, digestibility,
assimilation efficiency, methane, heat increment, or nutrient composition.

## Food-Energy Conversion

For hour `h`:

```text
ingested_available_energy_kj_h[h] =
  dry_matter_intake_kg_dm_h[h] *
  metabolizable_energy_density_kj_kg_dm
```

This conversion is pure. It changes no state.

## Gut Transition

Release is calculated from opening gut stock before current intake is added:

```text
assimilated_energy_kj[h] =
  gut_release_fraction_h * gut_energy_start_kj[h]

gut_energy_end_kj[h] =
  gut_energy_start_kj[h] + ingested_energy_kj[h]
  - assimilated_energy_kj[h]
```

Consequently, energy ingested during hour `h` cannot be released until a later
hour. The gut residual checks the same stock-flow identity independently.

## Body Transition

```text
body_energy_change_kj[h] =
  assimilated_energy_kj[h]
  - maintenance_expenditure_kj[h]
  - routine_activity_expenditure_kj[h]

body_energy_end_kj[h] =
  body_energy_start_kj[h] + body_energy_change_kj[h]
```

Routine activity is prescribed separately from maintenance. A proposed
negative closing body reserve raises an error rather than being clipped.

## Whole-System Accounting

Gut release is an internal transfer. For the combined gut and body system:

```text
combined_energy_change_kj[h] =
  ingested_energy_kj[h]
  - maintenance_expenditure_kj[h]
  - routine_activity_expenditure_kj[h]
```

Hourly and daily residuals are checked against a scale-aware floating-point
tolerance. These tolerances address arithmetic only, not biological variation
or measurement uncertainty.

## Isolated Forage-Biomass Transition

The plant-side accounting layer has no endogenous process parameters. For each
hour it receives independent prescribed growth and non-herbivore background
loss rates:

```text
forage_biomass_change_kg_dm_ha[h] =
  prescribed_forage_growth_kg_dm_ha[h]
  - prescribed_forage_background_loss_kg_dm_ha[h]

forage_biomass_end_kg_dm_ha[h] =
  forage_biomass_start_kg_dm_ha[h]
  + forage_biomass_change_kg_dm_ha[h]
```

Because each interval is one hour, the prescribed rates in
`kg DM ha^-1 h^-1` have the same numerical values as their one-hour amounts in
`kg DM ha^-1`; their names remain distinct. Closing biomass carries into the
next hour exactly. A proposed negative closing stock raises an error rather
than being clamped.

`run_forage_biomass_day()` records the 24 hourly transitions and reports daily
growth, background loss, expected change, observed change, and the balance
residual. Prescribed fluxes may vary by hour but are not calculated from
biomass, weather, or another process state, and the forage stock does not
constrain animal intake.

## Constant-Turnover Forage Reference

The first plant process reference declares a positive equilibrium `B*` and an
hourly turnover fraction `tau` in `(0, 1]`:

```text
forage_growth_kg_dm_ha_h[h] = tau * B*

forage_background_loss_kg_dm_ha_h[h] = tau * B[h]

B[h + 1] = B[h] + tau * B* - tau * B[h]
         = (1 - tau) * B[h] + tau * B*
```

At `B*`, growth and loss are equal and positive. Away from equilibrium, closing
biomass is a convex combination of current biomass and `B*`, giving positive,
monotonic recovery without overshoot. The exact hourly trajectory is:

```text
B[n] - B* = (B[0] - B*) * (1 - tau)^n
```

`run_forage_turnover_days()` repeats this transition on the shared hourly clock
and reports hourly process fluxes plus daily stock-flow summaries. Constant
production represents aggregate regeneration supported by unrepresented basal
tissue, meristems, or recruitment. Recovery is therefore linear, symmetric,
and independent of perturbation size. Those properties define an operational
null, not an empirical plant-growth claim.

## Standing-To-Accessible Forage Boundary

For standing edible forage biomass `B` and fixed residual threshold `R`:

```text
accessible_forage_biomass_kg_dm_ha = max(0, B - R)
```

Both `B` and `R` are biomass densities in `kg DM ha^-1`. The residual threshold
represents aggregate structural inaccessibility. It is not a second stock and
does not change the standing forage trajectory.

`derive_accessible_forage_biomass()` applies the transformation to one or more
standing-biomass values. The output is bounded between zero and standing
biomass. Above the threshold it increases one-for-one; at or below the threshold
it is zero. It remains a quantity per hectare rather than an animal acquisition
rate, so demand, intake, consumption, and depletion remain outside this layer.

## Minimum Non-Spatial Coupling

Let `D` be a fixed aggregate herbivore density in animals per hectare. One
representative animal physiology supplies the per-animal appetite and intake;
the model does not instantiate `D` separate individuals.

Autonomous turnover is applied first each hour:

```text
B[before herbivory] = (1 - tau) * B[start] + tau * B*

A = max(0, B[before herbivory] - R)

accessible forage per animal = A / D
```

The existing appetite and external acquisition-rate ceiling first define a
rate-limited one-hour candidate amount `q[candidate]`. The stock then supplies
one additional ceiling:

```text
q[realized] = min(q[candidate], A / D)

herbivory removal = q[realized] * D

B[end] = B[before herbivory] - herbivory removal
```

The same `q[realized]` enters the gut-energy conversion. This gives two linked
conservation identities: plant removal equals realized per-animal intake times
density, and the forage stock changes by growth minus background loss minus
herbivory. Rates and one-hour amounts are named separately.

Because autonomous turnover precedes herbivory, production during the shared
hour can contribute to accessible biomass. This is an explicit discrete-time
integration order. It is not a claim that production causally precedes feeding
within a real hour.

`step_forage_herbivory()` isolates scaling and stock limitation without plant
fluxes or animal-energy change. `run_nonspatial_coupled_energy_days()` carries
forage, gut, and body stocks over repeated days with complete dry-matter and
energy ledgers.

The constant coupled reference is period-24 rather than static because feeding
and herbivory occur in two daily windows. Stability requires a repeating forage
and gut trajectory together with neutral daily body-energy balance.

## Explicit Known-Route Movement

The minimum spatial record contains a finite set of unique patch identifiers,
one finite non-negative acquisition ceiling and one finite strictly positive
metabolizable-energy density per patch, and unique directed routes between
different declared patches. Every current route has a fixed duration of one
hour and a finite, non-negative incremental movement expenditure in
kilojoules.

For an opening location `L[start]` and declared destination `L[destination]`:

```text
require one directed route L[start] -> L[destination]

travel duration = 1 h
feeding suspended during travel = TRUE
L[end] = L[destination]
```

The route's incremental movement expenditure is reported as both a one-hour
amount and rate. Maintenance and ordinary routine activity are not embedded in
the spatial transition. A caller composes them explicitly with feeding
suspension and the route increment. Actual feeding time lost depends on whether
the travel interval overlaps an otherwise open feeding opportunity; the
accepted hour-16 anchor loses one hour.

Movement starts at the opening boundary, occupies the interval, and ends at the
destination boundary. There is no in-transit state because multi-hour routes
are excluded from this layer. The route is known to the focal animal; the step
does not select among destinations.

## Prescribed Explicit-Patch Day

`new_prescribed_patch_itinerary()` records the patch occupied at each of the 24
closing hourly boundaries. Given opening location `L[h]` and prescribed closing
patch `P[h]`:

```text
if P[h] = L[h]: stay
otherwise: require and traverse known route L[h] -> P[h]

L[h + 1] = P[h]
```

`run_prescribed_spatial_energy_day()` performs this location transition before
composing the interval with the accepted appetite-energy inputs. During travel,
feeding opportunity, reference intake, and the acquisition ceiling are set to
zero; route expenditure is added to ordinary routine activity. The opening
patch supplies the interval's metabolizable-energy density whether the animal
stays or travels, although realized travel intake is zero. The unmodified
reference body and gut trajectories remain the homeostatic targets, allowing
appetite to respond to the resulting energetic deviation in later open hours.

Travel duration and actual feeding time lost are distinct. The latter is one
hour only when travel overlaps a baseline open feeding interval.

## Static Patch Food Properties

Each patch `p` carries one fixed non-depleting acquisition ceiling `C[p]` in
`kg DM h^-1` and one metabolizable-energy density `E[p]` in
`kJ kg^-1 DM`. For an interval opening in patch `L[h]`:

```text
if staying: applied acquisition ceiling = C[L[h]]
if moving:  applied acquisition ceiling = 0

applied metabolizable-energy density = E[L[h]]
```

The ceiling then constrains appetite through the accepted energy runner. Patch
capacity is recorded independently of the applied ceiling, so a travel hour
retains its opening-patch property while correctly applying zero acquisition.

Neither property is dynamic. `C[p]` is not standing biomass and does not
deplete or renew; `E[p]` is already metabolizable energy and is not decomposed
into gross energy, digestibility, protein, fibre, or water. The prescribed
itinerary remains external to the energy runner.

In the retained all-stay comparison, both patches have a non-limiting
`0.025 kg DM h^-1` acquisition ceiling. At `10,000 kJ kg DM^-1`, the animal
eats `0.3200 kg DM` and remains energy-neutral. At `8,000 kJ kg DM^-1`, it
increases intake to `0.3485 kg DM` but realizes only `2,788 kJ` and closes
`412 kJ` below reference. Each spatial result is field-for-field identical to
the scalar-food appetite runner at the same density.

## One Known-Patch Feeding-Bout Choice

`choose_known_patch_for_feeding_bout()` compares staying with one declared
known-route destination. Let `d` be a constant expected demand proxy, `H` the
remaining feeding-opportunity hours, `T` route duration, `E[p]` patch-specific
metabolizable-energy density, and `M` incremental route expenditure:

```text
stay intake = min(d, C[current]) * H
move intake = min(d, C[destination]) * max(0, H - T)

stay score = stay intake * E[current]
move score = move intake * E[destination] - M
```

The animal moves only when `move score > stay score` beyond scale-aware
floating-point tolerance; ties stay. Maintenance and ordinary routine activity
are common to both candidates and therefore cancel from the comparison.

Demand remains fixed within the score. The rule does not simulate future
appetite, gut release, or body reserve and must not be interpreted as predicting
the magnitude of the realized energetic benefit. The accepted spatial runner
evaluates the chosen and rejected prescribed actions separately.

Both `C[p]` and `E[p]` come from the landscape; there is no second food-quality
parameter at the choice boundary. The result is a minimal patch-quality
operational null, not an anticipatory or state-responsive choice rule.

## Single Food-Quality Oracle Choice

The full-model quality oracle remains outside the package API. At the day
boundary, it compares two prescribed
counterfactuals from the accepted reference animal state: stay in the current
patch all day, or move at hour 0 to one known destination. Both patches have
equal non-limiting `0.025 kg DM h^-1` acquisition capacity. The destination is
fixed at `10,000 kJ kg DM^-1`; only current-patch energy density varies, from
`4,000` to `10,000 kJ kg DM^-1` in `100 kJ kg DM^-1` steps. The route lasts one
hour, loses one open feeding hour, and costs `900 kJ`.

The oracle moves only for a strictly greater closing combined-energy stock; a
tie stays. At every density, maintenance and ordinary activity cancel between
the candidates, giving:

```text
move minus stay combined energy
  = move ingested energy - stay ingested energy - route expenditure
```

Movement advantage declines monotonically with current-patch quality. The
oracle moves through `7,300` and stays from `7,400 kJ kg DM^-1`. This bracket
reflects the declared grid, not empirical precision. At the accepted `8,000`
versus `10,000 kJ kg DM^-1` contrast, moving adds `763 kJ` of ingested energy
but costs `900 kJ`, so staying is better by `137 kJ`.

The move result is invariant across the sweep because no intake occurs during
the hour-0 route and every treatment then enters the same adequate destination.
The minimal patch-quality helper moves through `6,500` and stays from
`6,600 kJ kg DM^-1`. It therefore stays while the oracle moves from `6,600`
through `7,300`, with maximum realized regret of `168 kJ` at the first
disagreement. The fixed-demand score underestimates the later appetite
compensation induced by movement expenditure and consequently underestimates
the move option more strongly. At the accepted `8,000` contrast, helper and
oracle both stay. The comparison exposes information error without giving the
animal perfect forecasting.

## Prescribed Water-Source Excursion

The first landscape constraint uses the existing spatial runner without adding
a water stock or behavioral decision. One adequate static forage patch is
connected to one named patch with zero food acquisition. The latter is treated
semantically as a water source only. Consecutive outbound and return intervals
make one prescribed daily visit with no stationary drinking interval.

Each route lasts one hour and adds `900 kJ` incremental expenditure. This value
is a ratio-informed synthetic cost: level hopping in red kangaroos has been
measured at roughly ten times resting metabolism, but the current animal-energy
reference is not an empirical species calibration. The retained comparison is:

| Treatment | Movement | Feeding time lost | Intake | Gut change | Body change | Combined change |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| No excursion | 0 h | 0 h | 0.32 kg DM | 0 kJ | 0 kJ | 0 kJ |
| Off-window excursion | 2 h | 0 h | 0.36 kg DM | 180 kJ | -1,580 kJ | -1,400 kJ |
| Within-window excursion | 2 h | 2 h | 0.32 kg DM | 176 kJ | -1,976 kJ | -1,800 kJ |

The off-window animal uses later appetite compensation to acquire `0.04 kg DM`
above reference, offsetting `400 kJ` of route expenditure. In the within-window
treatment, the same extra acquisition replaces the `0.04 kg DM` missed during
travel, so daily intake only returns to reference and none of the route cost is
offset. Route cost and trip timing are therefore separately attributable.

## Dynamic Spatial Forage Coupling

`new_spatial_forage_biomass_state()` records one standing-biomass density for
each unique landscape patch. It contains only `patch_id` and
`forage_biomass_kg_dm_ha`; acquisition capacity remains a static landscape
property. The runner reorders valid input state to deterministic landscape
order and requires exact patch-set membership.

`run_prescribed_spatial_coupled_energy_day()` applies this hourly order:

1. identify the opening and prescribed closing patch;
2. apply the common accepted autonomous turnover to every patch;
3. infer stay or known-route movement;
4. calculate appetite using the opening patch's static acquisition ceiling and
   metabolizable-energy density;
5. on a stay, remove density-scaled realized intake from that opening patch;
6. on a move, set intake and herbivory to zero;
7. update gut and body energy with routine plus route expenditure; and
8. carry closing location, gut, body, and every patch stock.

For patch `p`, the one-hour balance is

```text
B[p, h + 1] = B[p, h] + growth[p, h] - background_loss[p, h]
              - local_herbivory[p, h]
```

The representative density is co-located in exactly one patch. Local
herbivory is therefore zero for every unoccupied patch and for all patches
during movement. Each patch is a separate `kg DM ha^-1` ledger; no landscape
mass is inferred without patch areas.

The accepted 61-day fixed-itinerary comparison starts both patches at
`1,000 kg DM ha^-1`, occupies patch A for 30 days, moves once at closed hour 8
for `900 kJ`, and occupies patch B for 30 days. Patch A ends day 30 at
`931.54 kg DM ha^-1`, then renews to `966.72`; patch B remains exactly at
equilibrium until the transfer, then declines to `930.32`. No stock ceiling
binds. The transfer-day energy loss is recovered through subsequent appetite
feedback, but this diagnostic tests local depletion and renewal, not
adaptive patch selection or chronic stress.

## Single Resource-Aware Oracle Choice

The first resource-aware decision remains outside the package API. At one day
boundary, the diagnostic gives a perfect-state, perfect-model oracle the exact
opening location, gut, body, and patch stocks. It runs two fully prescribed
counterfactuals through `run_prescribed_spatial_coupled_energy_day()`:

```text
stay score = closing combined energy after staying in patch A
move score = closing combined energy after moving to patch B at hour 0
```

Both candidates share the same opening state, so ranking closing energy is
equivalent to ranking daily combined-energy change. Move is selected only for
a strictly higher result; a tie stays. This reuses the complete accepted
turnover, stock limitation, appetite, movement, and energy transitions instead
of introducing an approximate biomass score.

With equal static capacities and the accepted `900 kJ` route, the mild
Goal 038 state (`931.54 kg DM ha^-1` in patch A) remains non-binding. Staying is
neutral, whereas moving closes `549 kJ` lower despite compensated intake, so
both the static rule and oracle stay. In the severe positive control, patch A
opens at `450 kg DM ha^-1`, exactly `90%` of the residual threshold. Staying is
stock-limited for all 16 feeding hours and loses `3,200 kJ`; moving loses
`549 kJ`, so the oracle moves while the biomass-blind static rule stays.

The oracle therefore establishes that resource state can become
decision-relevant, but it is not a behavioral model. It assumes perfect
knowledge and exact one-day counterfactual evaluation.

### Stay-Move Switch Boundary

The boundary diagnostic varies only patch A opening biomass from `450` to
`550 kg DM ha^-1` in `0.5 kg DM ha^-1` steps. Patch B stays at equilibrium and
all animal, forage, schedule, acquisition, and route parameters remain fixed.
The same stay and move counterfactuals are evaluated at every level.

The oracle moves through `497.5 kg DM ha^-1` and stays from
`498.0 kg DM ha^-1`. This numerical bracket is diagnostic resolution, not
empirical precision. At every level the score decomposes exactly as:

```text
move minus stay energy
  = (move intake - stay intake) * metabolizable-energy density
    - incremental route expenditure
```

At the last move level, movement gains `935 kJ` of intake energy and costs
`900 kJ`, leaving a `35 kJ` advantage. At the first stay level it gains only
`775 kJ`, leaving a `125 kJ` disadvantage. Same-day renewal places the switch
slightly below the `500 kg DM ha^-1` residual threshold. The advantage declines
monotonically with occupied-patch biomass; hourly feeding windows, the residual
boundary, and the acquisition ceiling create plateaus and changes in slope but
no multiple switching.

The hour-0 move loses one open feeding hour at every level. Under adequate
forage, appetite compensation raises later intake enough to recover `351 kJ`
of the route expenditure, leaving the accepted `549 kJ` move-day disadvantage.

### Myopic Resource-Choice Null

The first information-limited comparison reuses
`choose_known_patch_for_feeding_bout()` without adding a package API. At the
day boundary, opening accessible forage in the current patch is divided by
represented animal density and the one-hour cue interval, then capped by the
patch's static acquisition capacity:

```text
current cue rate = min(static acquisition capacity,
                       opening accessible forage / density / 1 hour)
```

The destination has a prescribed expected `0.025 kg DM h^-1` acquisition rate.
The existing score holds `0.020 kg DM h^-1` expected demand constant over 16
feeding-opportunity hours, subtracts one travel hour and `900 kJ` from moving,
and treats each cue rate as persistent. It does not predict same-day turnover,
appetite feedback, or later stock limitation.

Across the Goal 040 grid, the myopic score changes from move to stay at
approximately `500.13 kg DM ha^-1`, bracketed by grid levels `500.0` and
`500.5`. The full-model oracle changes between `497.5` and `498.0`. The rules
disagree only at five grid levels from `498.0` through `500.0`: the myopic rule
moves early, with realized regret from `125` to `549 kJ`. It never stays when
the oracle moves. This is a transparent cost of omitting within-day renewal
knowledge, not an accepted repeated behavioral policy.

### Daily Myopic Choice Closed Loop

The repeated-choice diagnostic applies the same rule once at each day boundary.
Selected location, both forage stocks, gut energy, and body reserve carry into
the next decision. Each candidate remains a full-day itinerary: stay in the
opening patch, or move at hour 0 and remain in the known destination. Both are
evaluated from the exact same opening state every day; the myopic result alone
is carried, while the better result defines local daily oracle agreement and
regret.

Two patches open at `1,000 kg DM ha^-1`. At the reference density of
`10 animals ha^-1`, equal adequate-quality patches remain resident for 120 days
without stock limitation, and body reserve stays at `40,000 kJ`. At the
pressure density of `50 animals ha^-1`, the equal-quality control runs for 305
days and moves on days 59, 117, 166, 213, 259, and 305. Its last two intervals
are both 46 days. Two one-day-late oracle disagreements cost `101 kJ` locally;
the rule corrects on the following day without chattering.

The matched biomass-quality treatment changes patch A alone from `10,000` to
`8,000 kJ kg DM^-1`. It advances the first move to day 40 and produces eight
moves by day 305, on days 40, 97, 129, 168, 195, 231, 258, and 293. Its shortest
interval is 27 days. Higher dry-matter intake depletes lower-quality patch A
more quickly, and minimum body reserve falls from `38,860` in the control to
`36,948 kJ`.

The quality treatment has seven daily oracle disagreements. The helper stays
one day too long in lower-quality patch A on days 39, 128, and 257, and moves
back to it too early on days 97, 168, 231, and 293. These local opportunity
costs sum to `2,919 kJ` along the myopic trajectory. They are not the cumulative
performance difference from a separately carried oracle policy. The result
exposes a limitation of the operational null without creating a general
behavioral API or a viability result.

### Last-Experienced Return Memory

One diagnostic comparison replaces both biomass and prescribed destination
cues with a single last-experienced return for each patch, measured in `kJ` per
feeding-opportunity hour. Memories open at fixed expected demand times patch
energy density (`160 kJ h^-1` for A and `200 kJ h^-1` for B). Only the occupied
patch is updated, using realized ingested energy divided by actual feeding-
opportunity hours. The unvisited patch retains its last value.

The stay score multiplies current-patch memory by 16 hours. The move score
multiplies destination memory by 15 hours and subtracts `900 kJ`. This rule has
no biomass observation, renewal expectation, exploration, body-state trigger,
or multi-day horizon.

Under the matched lower-quality-patch-A treatment, it moves once on day 41 and
remains in B. Patch A renews unobserved to `960.77 kg DM ha^-1`, while its stale
remembered return remains `119.73 kJ h^-1`. B supplies `149.67 kJ h^-1` at its
residual boundary, so the travel-adjusted memory score continues to favour B.
Body reserve closes day 146 at `250 kJ`; neither day-147 action preserves a
non-negative reserve. The run therefore terminates explicitly.

The memory trajectory has only two local oracle disagreements and `1,333 kJ`
of summed one-day regret, less than the operational null, despite its much worse
physiological outcome. The local oracle is an action diagnostic, not a long-run
policy objective. Last-experience memory is rejected as a sufficient realistic
rule and remains outside the package API.

### Recovery Information and Decision Horizon

A bounded decomposition reconstructs the opening day-101 animal, gut, and
forage state from the accepted last-experience trajectory. It compares two
destination-information assumptions crossed with one- and two-day horizons:

- stale last experience uses patch A's retained `119.73 kJ` per feeding-
  opportunity hour;
- recovered opportunity uses the animal's own maximum previously experienced
  return in patch A, `200 kJ` per feeding-opportunity hour; and
- neither assumption reads current destination biomass.

For horizon `H`, the transparent scores are:

```text
stay score = current-patch return * (16 * H)
move score = destination return * (16 * H - 1) - 900 kJ
```

The subtraction represents the established hour-0 route: one lost feeding
opportunity and `900 kJ` incremental movement expenditure. Stale information
selects stay at both horizons. Recovered opportunity selects stay over one day
by `295 kJ`, then move over two days by `511 kJ`.

Matched full-model policies start from the identical snapshot and either stay
in B or move to A on the first hour and remain there. Over two days, moving
gains `1,411 kJ` of intake and incurs `900 kJ` of route expenditure, reproducing
the `511 kJ` reversal with exact gut, body, forage, and whole-system closure.
The predeclared extension through day 7 is not invoked because the primary
two-day comparison reverses.

This identifies a joint information-horizon requirement at one checkpoint. It
does not establish a general policy, grant perfect biomass knowledge, or
specify how recovery expectations are learned and carried.

### Carried Recovery-Aware Memory

One diagnostic candidate carries the Goal 049 ingredients for `305` days. Each
patch stores a last experienced return, a historical-best return, and whole
days since visit. Familiar-territory priors are `160/200 kJ` per feeding-
opportunity hour for last return and `200/250 kJ` for historical best in
patches A/B. The best priors equal maxima actually observed in the accepted
memory trajectory and the appetite ceiling times patch energy density.

For an unvisited patch aged `a` days:

```text
expected return =
  best return - (best return - last return) * (1 - 0.001)^(24 * a)
```

The occupied patch uses its last return. The action score remains:

```text
stay score = current expected return * 32 h
move score = destination expected return * 31 h - 900 kJ
```

The rule moves on day 1 and then on days 60, 99, 155, 187, 247, and 280.
Intervals are never shorter than `32` days, and both patches remain in use.
The full horizon completes without a negative reserve, but minimum body reserve
falls to `12,355 kJ` and closing reserve is `31,146 kJ`.

A matched full-model two-day evaluator is recomputed from every carried state.
It disagrees on `147` days, always preferring movement when the memory rule
stays. Summed local regret is `79,142 kJ`; this is not a cumulative comparison
against a separately carried oracle. All valid counterfactual accounts close.

The mechanism is rejected. Experienced return is a flow response to production,
accessibility, demand, and food quality, not a standing stock that should
recover at the biomass turnover half-life. The candidate remains diagnostic-
only and must not be tuned or promoted into package behavior.

### Absence-To-Return Recovery Map

The bounded recovery map starts an unvisited patch at the residual boundary,
advances the accepted turnover equation for a prespecified whole-day absence,
and introduces the identical reference animal state only after that absence.
Matched two-day stay and move policies expose realized feeding return and route
repayment alongside standing biomass, accessible forage per animal, and
instantaneous net production. The Goal 050 return equation is retained only as
a rejected comparator. No recovery-map quantity is package state or information
available to the animal.

## Reference Cycle

`run_gut_body_energy_reference_cycle()` repeatedly applies one fixed 24-hour
ingestion schedule to the gut until successive 25-boundary gut trajectories
match within the declared relative tolerance. It then resets body reserve once
to the declared measurement state and records two carried gut-body days.

The reset is an initialization protocol, not a physiological process. Gut
periodicity and body-energy neutrality are separate outcomes.

## Appetite Controller

The appetite controller compares opening body and gut stocks with an
hour-specific reference trajectory:

```text
reference_energy_kj_h =
  reference_intake_kg_dm_h * energy_density_kj_kg_dm

body_feedback_kj_h =
  -body_feedback_fraction_h * (body_energy_kj - reference_body_energy_kj)

gut_feedback_kj_h =
  -gut_feedback_fraction_h * (gut_energy_kj - reference_gut_energy_kj)

unconstrained_intake_kg_dm_h =
  (reference_energy_kj_h + body_feedback_kj_h + gut_feedback_kj_h) /
  energy_density_kj_kg_dm
```

When feeding opportunity is open, the target is constrained to `[0, maximum]`.
When it is closed, the target is zero. Negative stock deviations therefore
increase demand and positive deviations suppress it.

This is a compressed homeostatic controller. It does not explicitly model
hunger hormones, anticipation, learning, stomach fill, or choice.

## Forage-Acquisition Boundary

The environment supplies an hourly non-negative ceiling:

```text
realized_intake_kg_dm_h = min(
  appetite_target_kg_dm_h,
  forage_acquisition_ceiling_kg_dm_h
)
```

Only realized intake enters the gut. The ceiling is not a biomass stock and has
no depletion, production, senescence, seasonality, or spatial state.

## Repeated-Day Runner

For every hour, `run_appetite_controlled_energy_days()` performs:

1. calculate appetite from opening gut and body state;
2. apply the external forage-acquisition ceiling;
3. convert realized dry matter to available energy;
4. release opening gut energy and add current intake;
5. update body reserve from assimilation, maintenance, and activity;
6. record gut, body, and combined-system accounting; and
7. carry both closing stocks forward.

One fixed reference, forage schedule, and activity schedule repeat over the
requested number of days. Day-specific events are composed outside this runner
until a generalized process is scientifically justified.

## Body-Mass Interpretation

Body-energy reserve can be translated without feedback:

```text
reserve_tissue_mass_kg =
  body_energy_reserve_kj / reserve_tissue_energy_density_kj_kg

total_body_mass_kg = structural_body_mass_kg + reserve_tissue_mass_kg
```

Structural mass is fixed. Gut contents are excluded.

## Synthetic Reference

The retained reference has 40,000 kJ body reserve, 10,000 kJ kg^-1 DM food,
0.25 h^-1 gut release, 100 kJ h^-1 maintenance, and two eight-hour feeding
windows. Intake is 0.020 kg DM h^-1 and routine activity is 50 kJ h^-1 during
those windows. Daily input is 3,200 kJ; maintenance plus activity is also
3,200 kJ.

The reference is an operational null. It is not a calibrated animal or an
assertion that daily energetic balance alone establishes health or viability.

## Retained Diagnostics

Twenty-two no-write experiments protect the current scientific interpretation:

- the reference diagnostic checks neutrality, conservation, and gut order;
- the appetite-forage diagnostic checks a binding ceiling, deficit recovery,
  and lower-quality compensation; and
- the implicit-patch diagnostic checks patch order, movement costs, variable
  food quality, and bounded feeding-duration response; and
- the forage stock diagnostic checks balanced turnover, net gain, net loss,
  state carry-over, and stock-flow closure; and
- the forage-turnover diagnostic checks positive equilibrium and analytic,
  monotonic recovery from matched low and high perturbations; and
- the forage-availability diagnostic checks the residual threshold against the
  accepted turnover trajectories without consumption or depletion; and
- the non-spatial coupled-reference diagnostic checks density scaling, a
  binding stock ceiling, joint conservation, and period-24 stability; and
- the animal-load pulse diagnostic changes density alone and checks forage
  depletion, stock-limited intake, animal-energy loss, and recovery after load
  release against a constant-density control; and
- the explicit known-route diagnostic checks patch-location change, feeding
  suspension, incremental movement expenditure, and reproduction of the
  accepted Goal 024 energy outcomes; and
- the prescribed-itinerary diagnostic checks exact all-stay reduction and a
  two-move round trip with contextual feeding-time loss and energy closure;
  and
- the static patch-acquisition diagnostic reverses adequate and limited patch
  order under matched travel and checks the resulting intake and energy state;
  and
- the known-patch choice diagnostic ranks staying and moving once, then checks
  the selected action against both full appetite-energy counterfactuals; and
- the prescribed water-source diagnostic gives matched two-leg excursions
  different timing, checking route expenditure, lost feeding opportunity,
  appetite compensation, return location, and energy closure; and
- the spatial patch depletion-and-renewal diagnostic checks common turnover,
  occupied-patch removal, movement-hour closure, release, renewal, and full
  patch-animal conservation; and
- the resource-aware choice diagnostic compares matched full stay and move
  counterfactuals under mild and severe depletion, distinguishing the
  perfect-information oracle from the biomass-blind static rule; and
- the resource-aware boundary diagnostic varies current-patch opening biomass
  alone, checks one monotonic preference transition, and decomposes its energy
  difference into intake gained and route expenditure; and
- the myopic resource-choice diagnostic compares one opening-state acquisition
  cue with the full-model oracle and localizes its disagreement and regret; and
- the daily myopic-choice diagnostic carries animal and patch states under a
  low-load reference and matched equal- versus unequal-quality pressure runs,
  checking residence, recurrence, quality-by-biomass effects, local daily
  oracle regret, physiological state, and full accounting, then compares one
  last-experienced-return memory through its explicit terminal boundary and
  one recovery-aware two-day candidate through its rejected carried result; and
- the memory-horizon decomposition reconstructs the opening day-101 state and
  crosses stale versus recovered experienced return with one- and two-day
  horizons, checking score choices against full-model policies and decomposing
  the reversal into intake gained and route expenditure; and
- the absence-to-return recovery diagnostic advances an unvisited residual
  patch across prespecified ages, compares realized two-day return and route
  repayment with resource stocks and flow, and exposes the rejected belief's
  timescale error; and
- the explicit patch food-quality diagnostic holds acquisition non-limiting
  and movement absent, checking exact reduction of adequate and lower-quality
  all-stay patches to their corresponding non-spatial physiology; and
- the food-quality choice-boundary diagnostic varies current-patch energy
  density alone, compares the minimal helper and full-model oracle transitions,
  decomposes realized energy advantage, and reports helper regret.

Implicit patch treatment labels and feeding-duration response remain
diagnostic treatments only. Explicit patch identity, static acquisition
capacity, patch-specific metabolizable-energy density, one-hour known-route
movement, and one prescribed day are now supported package state. One bounded
feeding-bout choice is a patch-quality decision helper over that state. The
resource-aware oracle remains a diagnostic benchmark only, and the myopic cue
remains a diagnostic approximation to it. Its repeated application also
remains diagnostic-only. The food-quality oracle is likewise diagnostic-only;
the package helper remains fixed-demand and non-anticipatory. Last-experienced
return memory and the recovery-horizon decomposition are also diagnostic-only
and are not accepted package behavior. The carried turnover-rate recovery
candidate is likewise diagnostic-only and explicitly rejected. The
absence-to-return recovery map is a diagnostic mechanism check, not a carried
behavioral rule.

## Exclusions

The current model excludes resource- or weather-dependent plant production,
explicit senescence processes, acquisition functional responses beyond the
accepted ceilings, multiple explicit or heterogeneous animals, protein, water
balance or drinking benefit, thermoregulation, repeated or stochastic route
choice as package behavior, dynamic anticipation, explicit package-level
perception or memory, endogenous decision timing, multi-hour transit, anticipatory
quality-aware choice, patch-specific production, search, mortality,
reproduction, and population dynamics. These require separately approved
layers.
