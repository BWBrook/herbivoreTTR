# Decision 0028: Isolated Forage Stock Accounting

Date: 2026-08-11

Status: accepted accounting foundation; plant process equation deferred

## Context

The herbivore core previously treated forage only as an external,
non-depleting acquisition ceiling. Before coupling plants and animals, the
forage subsystem needs its own transparent state and conservation law.

## Decision

Represent homogeneous standing edible forage as one stock in `kg DM ha^-1` on
the shared hourly clock. Apply prescribed growth and non-herbivore background
loss as separate `kg DM ha^-1 h^-1` fluxes. Record their one-hour amounts, net
stock change, closing biomass, and an accounting residual.

Negative closing biomass raises an error rather than being clamped. The hourly
clock supplies a common integration architecture; it does not assert that
plant processes are observed or parameterized hourly.

## Verification

The prespecified one-day diagnostic begins at `1,000 kg DM ha^-1`:

| Treatment | Daily growth | Daily loss | Closing biomass |
| --- | ---: | ---: | ---: |
| Balanced turnover | 48 kg DM ha^-1 | 48 kg DM ha^-1 | 1,000 kg DM ha^-1 |
| Net gain | 48 kg DM ha^-1 | 24 kg DM ha^-1 | 1,024 kg DM ha^-1 |
| Net loss | 24 kg DM ha^-1 | 48 kg DM ha^-1 | 976 kg DM ha^-1 |

Hourly state carry-over and hourly and daily stock-flow residuals close to
floating-point tolerance. These values test accounting only and are not
tropical-savanna estimates.

## Interpretation And Boundary

The plant side now has a physical stock and auditable flow ledger, but it is
not yet a biological growth model. Growth and loss do not depend on biomass,
weather, season, or any other process state, although the prescribed schedule
may vary by hour. Standing biomass does not yet determine animal acquisition,
and herbivores do not remove biomass.

The next goal should compare candidate minimal growth-and-loss formulations and
select one with a known positive equilibrium and transparent recovery from high
and low starting biomass. Availability, seasonality, herbivory, and spatial
structure remain outside this decision.
