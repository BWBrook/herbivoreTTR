# Arc 02: Isolated Plant-Forage Subsystem

Status: closed; minimum constant reference and availability boundary accepted

## Purpose

Build the smallest forage system whose stocks, growth, losses, and equilibrium
can be understood without an animal. This mirrors the herbivore-first strategy:
stabilize the subsystem in isolation before coupling obscures its behaviour.

## Starting Boundary

Begin with one homogeneous forage biomass stock expressed on an explicit dry-
matter and spatial basis. Use a stock-flow representation, not individual
plants or food particles. The first system has no herbivore, patches, weather,
species composition, or stochasticity.

## Proposed Progression

1. **Units and conservation (implemented):** standing forage is
   `kg DM ha^-1` on the shared hourly clock; prescribed growth and background
   loss are separate, and negative closing biomass fails explicitly.
2. **Constant-forcing reference (implemented):** constant production and
   proportional background loss yield an exact positive equilibrium and
   monotonic recovery from high and low starting biomass.
3. **Availability boundary (implemented):** accessible biomass is standing
   edible biomass above a fixed residual threshold, without consumption or an
   acquisition rate.
4. **Controlled forcing (deferred):** introduce a deterministic seasonal or
   disturbance input only when a coupled scientific question requires it.
5. **Composition extensions:** later separate biomass from metabolizable energy,
   protein, water, fibre, or digestibility when a coupled question requires it.

The implemented turnover reference is an operational null rather than a claim
that plant growth is truly constant. More mechanistic growth should wait until
environmental forcing or another scientific question requires it.

## Decision Gates

- Which forage quantity should control later acquisition: standing biomass,
  accessible biomass, or a deliberately simple transformation?

Goals 028-030 resolved the physical stock, hourly accounting, constant
reference, and animal-facing availability gates. The hourly clock is a shared
integration architecture, not a claim that plant processes are observed at
that resolution.

## Exit Criteria

The isolated forage core is ready for coupling when:

- every stock and flux has explicit units;
- biomass remains finite and non-negative;
- constant forcing produces an understood equilibrium or declared trajectory;
- perturbation recovery is directionally and numerically intelligible;
- growth and loss accounting closes; and
- the animal-facing availability boundary is named without embedding animal
  behaviour in the plant model.

## Deliberate Deferrals

Herbivory, spatial patches, competition, recruitment cohorts, rainfall models,
fire, multiple plant functional types, dynamic food composition, protein,
water, and empirical calibration remain outside the first forage core.

## Handoff

The minimum constant forage core meets these exit criteria. Controlled forcing
is deliberately deferred so that the stable null can anchor
[`03-non-spatial-coupling.md`](03-non-spatial-coupling.md).
