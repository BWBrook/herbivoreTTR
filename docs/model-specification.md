# Model Specification

## Status

This document defines the future irreducible core. The foundation commit does
not implement it.

## Controlled System

- Represent one 50 kg semi-synthetic macropod-like herbivore.
- Use an explicit 24-hour clock with hourly state transitions.
- Treat hourly intake as a prescribed input.
- Use one homogeneous controlled food.
- Represent digestion as one well-mixed gut pool with first-order hourly
  passage.
- Track body-energy reserve in kJ while holding reference body mass fixed.
- Include maintenance-only energy expenditure.
- Initialize gut content at its periodic steady state for the prescribed daily
  intake cycle.
- Define an exact neutral baseline in which assimilated energy equals
  maintenance expenditure and body-energy reserve is unchanged.
- Treat gut capacity as a fail-fast input-validation boundary, not as an
  emergent clipping rule.

## Separation Of Roles

Dynamic state, fixed parameters, prescribed hourly inputs, process functions,
and recorded history are distinct objects. A transition receives validated
state, parameters, and the current prescribed input, then returns a new state
and explicitly named fluxes without hidden mutation.

## Planned Outputs

The core will produce one tidy hourly table and one derived daily summary. No
additional evidence bundle, dashboard, compatibility output, or persistent
generated artefact is part of the core contract.

## Planned Tests

The implementation goal will predeclare tests for conservation and for exact
neutral, deficit, and surplus energy cases. Dimensional consistency and the gut
capacity boundary must be tested directly. These tests are not implemented in
the foundation.

## Exclusions

Activity, dynamic body mass, protein, water, thermoregulation, plants, spatial
foraging, and cross-system coupling are later layers. Calibration, simulation
studies, release machinery, and legacy compatibility are also excluded.

The historical implementation is private at `BWBrook/herbivoreTTR-legacy`, tag
`legacy-final-2026-07-16`; the pre-freeze scientific baseline is
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
