# Arc 03: Non-Spatial Herbivore-Forage Coupling

Status: planned after the isolated forage arc

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

1. **Scaling contract:** decide how one animal's `kg DM` intake maps to forage
   biomass and area. This is a scientific decision, not bookkeeping.
2. **Removal-only bridge:** subtract realized intake from forage stock over a
   short controlled run and prove exact dry-matter conservation and
   non-negativity.
3. **Availability feedback:** let forage state constrain acquisition through
   one transparent, bounded relationship while keeping plant growth off.
4. **Growth-consumption balance:** restore plant growth/loss and locate a stable
   homogeneous coupled reference.
5. **Controlled stress:** vary one driver at a time, such as forage renewal,
   food-energy density, or animal load, and attribute any decline to the
   correct subsystem.

## Decision Gates

- What forage area or resource unit corresponds to one modeled animal?
- Is animal load represented by one individual, a density multiplier, or a
  separate population layer deferred until later?
- What minimal availability-to-acquisition function is scientifically legible?
- Which state defines coupled stability: plant biomass, daily animal balance,
  body reserve, or their joint trajectory?

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

Patches, travel, water sites, search, choice, multiple animals, stochastic
weather, fire, heterogeneous composition, and viability scenarios remain
outside this arc.

## Handoff

The next arc is
[`04-explicit-spatial-patches-and-movement.md`](04-explicit-spatial-patches-and-movement.md).
Spatial structure is added only after the homogeneous coupled machine is
understood.
