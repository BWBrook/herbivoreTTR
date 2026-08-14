# Arc 03: Non-Spatial Herbivore-Forage Coupling

Status: closed through Goal 032

## Purpose

Connect one understood herbivore to one understood homogeneous forage stock
using the smallest two-way interaction. The central question is when intake,
removal, plant renewal, and animal energetics form a stable and interpretable
system.

## Starting Boundary

Enter this arc with the frozen herbivore core and an isolated forage model that
has explicit dry-matter units and a stable constant-forcing reference. Retain a
single homogeneous environment and avoid location, patch choice, or weather.

## Proposed Progression

1. **Scaling contract (implemented):** one representative physiology at a
   fixed density in animals per hectare maps per-animal intake to biomass
   removal per hectare.
2. **Removal-only bridge (implemented):** a pure herbivory step proves exact
   dry-matter conservation and non-negativity without autonomous plant fluxes.
3. **Availability feedback (implemented):** accessible biomass per represented
   animal caps intake while plant growth remains absent from the checkpoint.
4. **Growth-consumption balance (implemented):** accepted turnover produces a
   stable period-24 homogeneous coupled reference.
5. **Controlled stress (implemented):** one temporary increase in aggregate
   animal load depletes forage, activates stock-limited intake, lowers animal
   energy, and separates animal from plant recovery after load release.

## Decision Gates

- **Resolved:** animal load is a fixed density multiplier in animals per
  hectare; explicit individuals and population dynamics remain deferred.
- **Resolved:** accessible biomass above the residual, divided by density,
  supplies a one-hour per-animal stock ceiling after autonomous turnover.
- **Resolved:** the constant reference requires a period-24 forage and gut
  trajectory plus neutral daily body-energy balance.
- **Resolved:** the first stress treatment changes animal density only; it is
  an aggregate removal-pressure pulse, not population dynamics.

## Closure Evidence

At `10 animals ha^-1`, forage and animal state repeat on the accepted reference.
A 60-day pulse at `50 animals ha^-1` reaches the residual on pulse day 49,
causes 12 stock-limited days, and lowers body reserve from `40,000` to
`30,834 kJ`. Restoring reference density returns body reserve to `40,000 kJ`
and recovers 75.6% of the forage displacement over 60 days. The response is
mechanistically attributable and all conservation identities close.

## Exit Criteria

This arc is complete when:

- plant removal equals realized animal intake on the declared basis;
- both energy and dry-matter ledgers close;
- a homogeneous coupled reference is stable and understandable;
- low-resource and recovery trajectories can be attributed mechanistically;
- the model distinguishes temporary bottlenecks from continuing coupled
  decline; and
- no spatial mechanism is needed to explain the reference behaviour.

## Deliberate Deferrals

Patches, travel, water sites, search, choice, multiple explicit or heterogeneous
animals, population dynamics, stochastic weather, fire, heterogeneous
composition, and viability scenarios remain outside this arc.

## Handoff

The next arc is
[`04-explicit-spatial-patches-and-movement.md`](04-explicit-spatial-patches-and-movement.md).
Spatial structure is added only after the homogeneous coupled machine is
understood.
