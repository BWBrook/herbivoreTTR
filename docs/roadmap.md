# Roadmap

## Implemented Layers

Rebuild Goal 001 establishes package metadata, reproducible environment support,
and the design contract.

Rebuild Goal 002 adds the first executable layer: prescribed
already-assimilated energy, constant maintenance expenditure, one physical
body-energy reserve, 24 fixed one-hour transitions, and exact hourly and daily
ledgers. This proves arithmetic and accounting semantics, not empirical
realism, viability, or equilibrium.

Rebuild Goal 003 adds one well-mixed gut-energy stock in assimilable-energy
equivalents. A fixed fraction of opening gut stock is released each hour into
the unchanged body ledger, and current-hour ingestion is added afterwards.
Synthetic equilibrium, empty-start, and pulse-response fixtures demonstrate
storage, delay, and exact gut, body, and combined-system accounting.

Rebuild Goal 004 adds a pure upstream bridge from prescribed dry-matter
ingestion in kg DM h^-1 and one fixed dry-matter-basis metabolizable-energy
density in kJ kg^-1 DM to the unchanged Goal 003 gut-energy schedule. The
density is already metabolizable and its product is an accounting equivalent
entering the existing gut pool. Zero, constant, pulse, and alternative
factorization fixtures demonstrate exact conversion and unchanged downstream
dynamics without adding state, a runner, or digestive physiology.

Rebuild Goal 005 adds a repeated-day reference-cycle orchestrator over the
unchanged Goal 003 energy schedule. It advances only the gut under identical
24-hour forcing until a numerical period-24 cycle is detected, resets body
energy once, and records two measured days with exact state carry-over. Zero,
constant, and concentrated late-feeding fixtures separate gut periodicity from
body-energy neutrality and demonstrate conditional timing equivalence without
adding biological processes or a general multi-day horizon.

Rebuild Goal 006 adds a reference and evidence layer without changing production
code or the package API. The permanent mathematical reference prescribes
0.010 kg DM h^-1 and derives 100 kJ h^-1 in every hour. The minimally
ecological reference prescribes 0.015 kg DM h^-1 and derives 150 kJ h^-1 in
hours 0 through 7 and 16 through 23, with intake closed in hours 8 through 15.
Both total 0.24 kg DM and 2400 kJ per day. Equal steady-cycle daily energy
totals are the operational null in the current linear, lossless, unlimited
system, while their within-day stock and flow trajectories differ. The
ecological reference remains a generic synthetic prescribed schedule, not a
behavioral or empirical model.

Rebuild Goal 007 adds a strict 24-hour schedule of externally prescribed
routine-activity expenditure in kJ h^-1. It remains separate from the fixed
synthetic maintenance parameter and is required explicitly by every body
transition and runner. Activity is applied only during measured body days in
the reference cycle, while gut-only burn-in and all gut dynamics remain
unchanged. A zero-activity regression preserves earlier trajectories on shared
fields, and a four-hour 50 kJ h^-1 pulse demonstrates an exact additional
200 kJ body loss per measured day with no gut effect. These are arithmetic and
accounting results, not an empirical activity or physiology model.

## Next Decision Gate

Goal 008 remains a discussion gate for a later ecological day/night activity
schedule and intake rebalancing. Goal 007 adds neither: its routine-activity
forcing is externally prescribed, and its diagnostic pulse is not an ecological
schedule. The Goal 007 results and the Goal 006 ecological reference must be
discussed before Goal 008 receives a bounded principal question, scientific
contract, or implementation authority.

## Candidate Later Layers

Previously discussed candidates include dynamic body mass, protein, water,
thermoregulation, plants, spatial foraging, and coupling between established
subsystems. Variable food quality, digestion, gut capacity, feeding behavior,
directed locomotion, and activity feedback also remain unimplemented. This list
records possible directions, not an approved sequence, a claim that any layer
comes next, or a promise to implement one.

Each layer requires a separately approved small goal with one principal
question, one subsystem, compact predeclared outputs, proportionate tests, and
an explicit stop. Results must be discussed before the next layer begins.

Legacy features are not migration tasks. `BWBrook/herbivoreTTR-legacy` at
`legacy-final-2026-07-16` is historical evidence only; its pre-freeze scientific
baseline is `abf68b691b4e30020625d1871dcabe56a5926bc1`.
