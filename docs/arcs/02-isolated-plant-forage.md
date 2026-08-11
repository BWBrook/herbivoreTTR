# Arc 02: Isolated Plant-Forage Subsystem

Status: next development stage; not yet implemented

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

1. **Units and conservation:** choose the biomass state, area basis, clock, and
   non-negative transition; expose growth input and loss output separately.
2. **Constant-forcing reference:** select one transparent synthetic growth/loss
   formulation and demonstrate a known equilibrium plus recovery from high and
   low starting biomass.
3. **Availability boundary:** define the forage quantity that can later inform
   animal acquisition without yet invoking consumption.
4. **Controlled forcing:** only after the constant reference is understood,
   consider one deterministic seasonal or disturbance input.
5. **Composition extensions:** later separate biomass from metabolizable energy,
   protein, water, fibre, or digestibility when a coupled question requires it.

The exact growth equation is a scientific decision for the first forage goal;
this arc does not prespecify logistic growth or another familiar form merely
for convenience.

## Decision Gates

- What physical stock and area units make animal removal interpretable?
- Should the first plant transition be daily, or an hourly rate integrated on
  the shared clock?
- What minimal growth and senescence formulation has an interpretable constant
  equilibrium?
- Which forage quantity should control later acquisition: standing biomass,
  accessible biomass, or a deliberately simple transformation?

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

The next arc is [`03-non-spatial-coupling.md`](03-non-spatial-coupling.md).
Coupling begins only after both isolated subsystems have stable references.
