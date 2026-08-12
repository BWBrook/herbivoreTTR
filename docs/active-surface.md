# Active Surface

## Product Promise

`herbivoreTTR` provides inspectable hourly stock-flow models for herbivore
energy and isolated forage biomass. Its current user is Barry Brook. Its
purpose is scientific understanding, not a general-purpose simulation
platform.

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
- Realized intake is the smaller of appetite target and forage acquisition.
- Hourly and daily forage stock-flow identities close numerically.
- The turnover reference is neutral at equilibrium and approaches it
  monotonically from positive low or high biomass.
- Synthetic balance is not interpreted as viability or empirical calibration.

## Retained Surface

| Surface | Disposition |
| --- | --- |
| Functional package core | Retain and extend by approved layers |
| Explicit records, units, and balance residuals | Retain |
| Five current diagnostics | Retain |
| Focused invariant tests | Retain |
| Scientific decision notes | Retain as the research notebook |
| Goal-by-goal experiment ancestry | Removed from the active tree; Git retains it |
| Exotic numeric-class compatibility | Removed |
| Generated outputs and review machinery | Keep ignored or disposable |
| Compatibility adapters and dormant flags | Decline |

## Validation

For ordinary changes, parse retained R, run the tests affected by the change,
and inspect the diff. When publishing a package boundary or completed model
stage, run the full focused suite, all five diagnostics, an external build,
and `R CMD check --no-manual` once.

Repeat a gate only for a distinct named risk. Additional polish or repeated
confirmation is not a release criterion.

## Current Stop

The herbivore-energy core is closed, and the isolated forage stock plus linear
turnover reference are implemented. The next plant decision is a deliberately
simple standing-to-accessible forage boundary. Protein, water,
thermoregulation, coupling, seasonality, and explicit spatial choice remain
deferred.
