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

Rebuild Goal 008 adds a three-fixture evidence and reference layer without
changing production code, equations, the package API, schemas, or the variable
dictionary. The zero-activity ecological baseline, uncompensated activity
counterfactual, and prescribed-balance reference all use intake hours `0:7` and
`16:23` with hours `8:15` rest-closed. Their observed daily
input/assimilation/activity totals are `2400 / 2400 / 0 kJ`,
`2400 / 2400 / 800 kJ`, and `3200 / 3200 / 800 kJ`; all converge on burn-in
day 7. Observed daily body changes are approximately `0 kJ`, `-800 kJ`, and
`0 kJ`. The balanced fixture becomes the normal synthetic ecological accounting
reference, while the Goal 006 zero-activity ecological fixture and continuous
mathematical diagnostic are retained.

Rebuild Goal 009 adds a synthetic intake-ceiling threshold screen in evidence
clients only. It clips the Goal 008 candidate prescription of
`0.020 kg DM h^-1` over 16 active intervals against ceilings of `0.015`,
`0.020`, and `0.025 kg DM h^-1`, without changing production code, APIs,
state, or schemas. The exact conditional accounting threshold is
`0.020 kg DM h^-1`, or `200 kJ h^-1`. The lower ceiling reproduces the Goal 008
uncompensated result; the at- and above-threshold ceilings reproduce the
balanced result, with `0.08 kg DM` or `800 kJ` of unused daily active-ceiling
headroom above the threshold. Candidate, constrained, and curtailed
prescriptions, strict exceedance, exact positive touching, and unused headroom
remain separate evidence quantities. Curtailment is discarded rather than
redistributed. The screen does not establish appetite, feeding behavior, forage
availability, gut capacity, an empirical maximum, or an achievable intake rate.

Rebuild Goal 010 adds a four-fixture prescribed intake window duration screen
in evidence clients only. With activity fixed and every open interval fully
used at the fixed prescription of `0.020 kg DM h^-1`, or `200 kJ h^-1`, windows
of 24, 16, 12, and 8 h d^-1 prescribe `4800, 3200, 2400, 1600 kJ` per day and
produce analytical daily body changes of `+1600, 0, -800, -1600 kJ`. The
16-hour complete result is exactly the Goal 008 balanced reference. The 12-hour
fixture matches the Goal 008 uncompensated fixture only for daily prescribed
intake and energy, maintenance, routine-activity expenditure, body-energy
change, status, and closing body reserve; its within-day and complete results
differ. The 24-hour comparator opens the activity-off interval
`[08:00, 16:00)`, while the 12- and 8-hour fixtures remove central-night
prescribed-intake hours. The daily relation therefore does not identify a
generic within-day duration effect. The windows and comparison fields remain
evidence-only, and open hours are prescribed ingestion rather than voluntary
behavior or empirical capacity.

Rebuild Goal 011 adds one fixed three-day forcing-transition contrast in
evidence clients only. Both sequences start from the same balanced period-24
gut state and `10000 kJ` body reserve with exact stock carry-over. The control
uses balanced forcing on all three days; the treatment uses the lower
`0.015 kg DM h^-1` rate on day 1 and balanced forcing on days 2 and 3. The
lower-rate schedule is reused from Goal 008, but its result is not the Goal 008
periodic result because Goal 011 starts from the balanced periodic gut.

Using treatment minus control, the day-1 external prescribed-input contrast and
combined-system contrast reach exactly `-800 kJ` at 24 hours. With identical
forcing thereafter, the combined-system contrast remains `-800 kJ`, the gut
contrast contracts by `0.75` per hour or `0.75^24` per day, and the body
contrast is `-800 kJ - gut-stock contrast`. This is return-to-reference forcing
and numerical gut-state realignment, not body-energy or whole-system
restoration. The fixed sequence chains existing one-day calls and adds no
production multi-day API.

Rebuild Goal 012 adds one fixed four-day prescribed energy-repayment sequence
in evidence clients only. Both sequences start from the same balanced
period-24 gut state and `10000 kJ` body reserve. `all_balanced_control` remains
balanced; `shortfall_then_repayment` prescribes `0.015 kg DM h^-1` over the 16
active hours on day 1, directly prescribes `0.025 kg DM h^-1` on day 2, and
returns to the balanced `0.020 kg DM h^-1` rate on days 3 and 4. The cumulative
external-input and combined-system contrasts move from `-800 kJ` at 24 hours
to `0 kJ` at 48 hours. Gut and body contrasts are then equal and opposite and
contract by `0.75^24` per balanced day toward zero without exact
treatment-control stock equality in finite time.

The repayment pulse is exogenous synthetic forcing, not Goal 009's
above-threshold result, compensation, catch-up feeding, appetite, behavioral
response, demonstrated capacity, or recovery. The fixed sequence chains the
existing one-day runner and adds no production API, state, schema, parameter,
equation, or test.

## Next Decision Gate

Goal 013 remains unapproved and scientifically unspecified. The next layer is
pending discussion. Goal 012 establishes only the declared prescribed-forcing
contrast under the current deterministic accounting model; it does not
authorize a configurable horizon, production sequence runner, endogenous
response, or later biological or empirical layer.

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
