# Model Specification

## Scope

The current package implements a synthetic hourly herbivore-energy model, an
isolated forage-biomass ledger, their minimum non-spatial coupling, and one
prescribed explicit-patch day built from known-route transitions. The spatial
null also includes one bounded stay-versus-known-route choice over a declared
remaining feeding bout. The animal model tracks energy entering
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
`[h, h + 1)`. The implemented dynamic state comprises three stocks and one
location identifier:

- `gut_available_energy_kj`: energy available for later release from the gut;
- `body_energy_reserve_kj`: labile body-energy reserve; and
- `forage_biomass_kg_dm_ha`: homogeneous standing edible forage biomass
  density; and
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
one finite non-negative acquisition ceiling per patch, and unique directed
routes between different declared patches. Every current route has a fixed
duration of one hour and a finite, non-negative incremental movement
expenditure in kilojoules.

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
zero; route expenditure is added to ordinary routine activity. The unmodified
reference body and gut trajectories remain the homeostatic targets, allowing
appetite to respond to the resulting energetic deviation in later open hours.

Travel duration and actual feeding time lost are distinct. The latter is one
hour only when travel overlaps a baseline open feeding interval.

## Static Patch Acquisition Capacity

Each patch `p` carries one fixed non-depleting acquisition ceiling `C[p]` in
`kg DM h^-1`. For an interval opening in patch `L[h]`:

```text
if staying: applied acquisition ceiling = C[L[h]]
if moving:  applied acquisition ceiling = 0
```

The ceiling then constrains appetite through the accepted energy runner. Patch
capacity is recorded independently of the applied ceiling, so a travel hour
retains its opening-patch property while correctly applying zero acquisition.

This is acquisition-rate heterogeneity only. `C[p]` is not standing biomass,
does not deplete or renew, and does not alter metabolizable-energy density.
The prescribed itinerary remains external to the energy runner.

## One Known-Patch Feeding-Bout Choice

`choose_known_patch_for_feeding_bout()` compares staying with one declared
known-route destination. Let `d` be a constant expected demand proxy, `H` the
remaining feeding-opportunity hours, `T` route duration, `E` metabolizable-
energy density, and `M` incremental route expenditure:

```text
stay intake = min(d, C[current]) * H
move intake = min(d, C[destination]) * max(0, H - T)

stay score = stay intake * E
move score = move intake * E - M
```

The animal moves only when `move score > stay score` beyond scale-aware
floating-point tolerance; ties stay. Maintenance and ordinary routine activity
are common to both candidates and therefore cancel from the comparison.

Demand remains fixed within the score. The rule does not simulate future
appetite, gut release, or body reserve and must not be interpreted as predicting
the magnitude of the realized energetic benefit. The accepted spatial runner
evaluates the chosen and rejected prescribed actions separately.

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

Twelve no-write experiments protect the current scientific interpretation:

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
  the selected action against both full appetite-energy counterfactuals.

Implicit patch treatment labels, variable hourly food density, and feeding-
duration response remain diagnostic treatments only. Explicit patch identity,
static acquisition capacity, one-hour known-route movement, and one prescribed
day are now supported package state. One bounded feeding-bout choice is a pure
decision helper over that state.

## Exclusions

The current model excludes resource- or weather-dependent plant production,
explicit senescence processes, acquisition functional responses beyond the
accepted ceilings, multiple explicit or heterogeneous animals, protein, water,
thermoregulation, repeated or stochastic route choice, dynamic anticipation,
multi-hour transit, patch food-energy-density heterogeneity, patch biomass or
production, search, mortality, reproduction, and population dynamics. These
require separately approved layers.
