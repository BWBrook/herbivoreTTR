# Arc 04: Explicit Spatial Patches And Movement

Status: ready; non-spatial coupling entry conditions met

## Purpose

Replace prescribed implicit patch sequences with explicit location and travel
while keeping the landscape simple enough to diagnose. The first spatial
system asks how fixed patch arrangement changes feeding opportunity and energy
cost, not how vegetation and animal choice co-evolve.

## Starting Boundary

Enter with a stable homogeneous coupled model. Preserve the Goal 024
decomposition of movement into feeding time lost and incremental energy cost.
Begin with fixed, known patch properties and mentally mapped routes.

## Proposed Progression

1. **Patch and location records:** represent a small fixed set of patches,
   explicit animal location, and a declared route matrix or simple geometry.
2. **Known-route transition:** reproduce the accepted Goal 024 time and energy
   effects from an explicit move with no search or uncertainty.
3. **Prescribed itinerary:** run a deterministic daily sequence through static,
   inexhaustible patches and verify exact location, time, intake, and energy
   accounting.
4. **Minimal choice:** compare a small number of known destinations using one
   transparent decision rule based on current cues, without perfect foresight.
5. **Static heterogeneity:** vary patch acquisition capacity or food quality
   while retaining fixed stocks and no plant depletion.

## Decision Gates

- Does a graph, coordinate geometry, or simpler route table best serve the
  first scientific question?
- At what clock boundary can movement start and finish?
- Which information is known to the animal, and which would require search or
  learning?
- What minimal choice rule remains interpretable under competing time and
  energy costs?

## Exit Criteria

This arc is complete when:

- animal location is explicit and valid at every hour;
- movement time and energy reproduce the known-route anchor;
- feeding suspension during travel is unambiguous;
- a deterministic static landscape produces understandable use and energetic
  outcomes; and
- choice effects can be separated from resource depletion and renewal.

## Deliberate Deferrals

Water obligation, dynamic patch depletion, plant renewal, stochastic search,
territorial learning, multiple animals, fire, weather, and viability scenarios
remain outside the first explicit spatial core.

## Handoff

The next arc is
[`05-landscape-constraints-and-scenarios.md`](05-landscape-constraints-and-scenarios.md).
Only there do water, depletion, richer heterogeneity, and scenario forcing
enter the explicit landscape.
