# Model Specification

## Scope

The current package implements a synthetic hourly herbivore-energy model and a
separate isolated forage-biomass ledger. The animal model tracks energy entering
through dry-matter intake, delayed in one gut stock, and transferred to a
body-energy reserve after maintenance and routine activity. An appetite
controller can set intake demand, while an external rate schedule can constrain
forage acquisition. The plant-side ledger carries standing biomass under
prescribed growth and background loss. A pure residual-threshold transformation
derives accessible biomass without coupling it to the animal.

The model is deterministic. All rates apply over one-hour intervals, so their
one-hour amounts have the same numerical value but retain distinct names.

## Clock And State

Each day contains intervals `hour_of_day = 0:23`. Interval `h` represents
`[h, h + 1)`. The three implemented dynamic stocks are:

- `gut_available_energy_kj`: energy available for later release from the gut;
- `body_energy_reserve_kj`: labile body-energy reserve; and
- `forage_biomass_kg_dm_ha`: homogeneous standing edible forage biomass
  density.

All stocks are finite and non-negative. Closing stocks become the next
interval's opening stocks without implicit reset or clamping.

## Fixed Parameters

- `gut_release_fraction_h` is in `(0, 1]`.
- `maintenance_expenditure_kj_h` is non-negative.
- `metabolizable_energy_density_kj_kg_dm` is strictly positive.
- appetite feedback fractions are non-negative.
- `maximum_dry_matter_intake_kg_dm_h` is strictly positive.
- `residual_unavailable_forage_threshold_kg_dm_ha` is non-negative.

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

Six no-write experiments protect the current scientific interpretation:

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
  accepted turnover trajectories without consumption or depletion.

Patch labels, movement, variable hourly food density, and duration response are
diagnostic treatments only. They are not additional package state.

## Exclusions

The current model excludes resource- or weather-dependent plant production,
explicit senescence processes, forage acquisition rates, herbivore depletion,
protein, water, thermoregulation, explicit space, search, mortality,
reproduction, and population dynamics. These require separately approved
layers.
