# Decision 0003: Opening-Stock Gut Release

Date: 2026-07-26

Status: accepted

## Context

Goal 002 established an exact body-energy ledger whose prescribed input was
already assimilated. The next question was whether one transparent internal
stock could delay and smooth controlled ingestion before that energy reached
the body, without adding food composition, digestive losses, parcel
provenance, or feedback behavior.

The timing convention matters. Allowing newly ingested energy to leave the gut
in the same hourly transition would mix inflow and release order and obscure
the minimum delay represented by the stock.

## Decision

Represent the gut as one well-mixed stock,
`gut_available_energy_kj`, measured in assimilable-energy equivalents. During
each fixed one-hour transition:

1. release `gut_release_fraction_h` of the opening gut stock;
2. transfer every released kilojoule one-for-one into the unchanged body-energy
   ledger; and
3. add the current hour's prescribed ingested available energy to the gut.

Current-hour ingestion therefore first becomes eligible for release in the
next transition. The gut receives no feedback from body reserve, maintenance,
or body-energy status. The release fraction is fixed within a daily run.

## Rejected Alternatives

- A fixed-delay queue was rejected because it would track cohorts or
  parcel-like provenance that is unnecessary for the storage-and-delay
  question.
- Multiple gut compartments and a digestive-efficiency pathway were rejected
  because they would add transit structure, food quality, and loss processes
  simultaneously.
- Same-hour release of current ingestion was rejected because it would remove
  the explicit one-transition delay and make the within-hour update order less
  legible.

## Consequences

The opening-stock rule gives analytically predictable equilibrium,
initialization, and pulse-response trajectories, while gut, body, and combined
modeled energy can each be checked explicitly. Assimilated energy is an
internal transfer and cancels from the combined-system balance.

The gut stock is not food mass, gross energy, plant biomass, or measured gut
fill. No digestive loss, waste, gut capacity, feeding behavior, activity,
dynamic body mass, plant process, or empirical calibration is represented.
The three Goal 003 fixtures are synthetic arithmetic demonstrations, not
biological parameter estimates.

## Stop Boundary

Stop after the one-pool gut transition, its coupling to the existing body
ledger, and the three synthetic demonstrations. No subsequent physiological or
ecological layer is authorized by this decision.
