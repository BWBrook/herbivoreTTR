# Arc 04: Explicit Spatial Patches And Movement

Status: closed; one-choice spatial null accepted

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

1. **Patch and location records (implemented):** a plain patch table, directed
   one-hour routes, and one explicit patch-location state.
2. **Known-route transition (implemented):** a pure move suspends feeding,
   exposes incremental movement expenditure, and reproduces the accepted Goal
   024 outcomes without search or uncertainty.
3. **Prescribed itinerary (implemented):** a deterministic closing-patch
   sequence now carries location and composes travel with feeding opportunity,
   appetite, and energy accounting through one day.
4. **Static heterogeneity (implemented):** each patch now supplies one fixed
   non-depleting acquisition ceiling under a prescribed itinerary.
5. **Minimal choice (implemented):** one fixed-demand remaining-bout score
   compares staying with one known route and is checked against both prescribed
   full-model counterfactuals.

## Decision Gates

- **Resolved:** a directed route table is sufficient; coordinates and a graph
  dependency are deferred.
- **Resolved:** current movement starts at an opening hourly boundary and ends
  at the destination boundary one hour later.
- **Resolved:** routes are known to the animal; search and learning are absent.
- **Resolved:** itinerary entries prescribe closing patch; stay versus move is
  inferred from opening location rather than redundantly prescribed.
- **Resolved:** static heterogeneity precedes choice so patch effects can be
  understood before behavior responds to them.
- **Resolved:** acquisition capacity is a fixed patch property in this layer;
  food-energy density and biomass dynamics remain common or absent.
- **Resolved:** the first choice rule ranks expected remaining-bout acquisition
  minus route expenditure, uses stay on ties, and does not claim to forecast
  dynamic appetite feedback.

## Closure Evidence

At hour 16, a limited-patch animal selected movement to adequate forage and
improved its realized combined-energy result from `-800` to `-481 kJ`. An
adequate-patch animal selected staying and retained neutrality rather than
moving to a `-650 kJ` outcome. All alternatives used the same accepted
appetite-energy runner, and resource depletion remained absent.

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
