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

Rebuild Goal 013 adds the first package-level endogenous intake calculation.
One pure hourly controller combines the accepted reference intake with signed
feedback from body- and gut-energy deviations, then applies zero and maximum
intake bounds plus the established feeding-opportunity closure. The accepted
reference remains an exact fixed trajectory. A fixed experiment applies the
Goal 011 shortfall and then activates the controller for nine days: daily
intake approaches the balanced reference from above, body reserve approaches
its reference without overshoot, and the combined-system deviation contracts
from `-800 kJ` to approximately `-1 kJ` by day 10.

The diagnostic feedback fractions (`0.05 h^-1` for body energy and `0.10 h^-1`
for gut energy) and the `0.025 kg DM h^-1` maximum are synthetic. Gut energy is
a post-ingestive satiation proxy rather than physical gut fill. Goal 013 adds
no meals, hormones, physical capacity, empirical calibration, generalized
appetite-controlled runner, or production multi-day horizon.

Rebuild Goal 014 adds a bounded evidence-only sensitivity and attribution
diagnostic over the unchanged Goal 013 controller. It combines body feedback
timescales of 40, 20, and 10 hours; gut feedback timescales of 20, 10, and 5
hours; and one-day deficits of `400`, `800`, and `1,600 kJ`. All 27 scenarios
preserve the exact reference and recover stably without body-reserve overshoot;
90% recovery takes 2 to 9 days. Faster body feedback accelerates recovery,
while faster gut feedback brakes it. The maximum intake constraint is inactive
at `400 kJ` but active in five `800 kJ` and eight `1,600 kJ` scenarios.

An `800 kJ` component comparison shows that body feedback provides the
persistent recovery drive. Gut feedback alone replaces only 6.3% of the
deficit, while adding gut feedback to body feedback modestly slows and tempers
the response. These are synthetic structural results, not empirical gain or
capacity estimates. Goal 014 changes no package equation, state, schema, or
production runner.

Rebuild Goal 015 promotes the accepted appetite-controlled composition into
one canonical package runner. It repeats one fixed 24-hour appetite reference
and routine-activity schedule, carries gut and body stocks exactly, and returns
explicit hourly and daily ledgers using realized-intake names. Goal 013's
nine-day recovery and Goal 014's sensitivity results are unchanged. The runner
adds no new equation, ecological process, day-specific forcing, or automatic
reference correction.

Rebuild Goal 016 separates the appetite target from environmentally realized
intake. One explicit 24-hour forage-acquisition ceiling caps the bounded target
before energy enters the gut. A `0.025 kg DM h^-1` ceiling preserves all
accepted trajectories. A matched `0.015 kg DM h^-1` ceiling during the 16 open
feeding hours binds throughout those hours: the animal targets `0.359 kg DM`,
realizes `0.240 kg DM`, and closes the day exactly `800 kJ` below reference.
The ceiling is a non-depleting rate input, not forage biomass or a plant model.

Rebuild Goal 017 adds a fixed recurrence experiment in evidence clients only.
Over 48 days, the Goal 016 limited day occurs never, once, or every 8, 4, or 2
days while every other model input remains fixed. Eight-day recurrence permits
effective inter-event recovery. Four-day recurrence settles near `-107 kJ`
before and `-907 kJ` after each event. Two-day recurrence approaches a much
deeper, capacity-limited cycle, reaching approximately `-1060 kJ` before and
`-1860 kJ` after the final event. These are synthetic combined-energy debt
regimes, not body-mass, mortality, or demographic outcomes. Goal 017 changes no
package equation, state, schema, parameter, API, dependency, or test.

Rebuild Goal 018 crosses the existing 8-, 4-, and 2-day recurrence intervals
with exact `400`, `800`, and `1,200 kJ` event losses in a 3-by-3 evidence-only
map. Every 8-day treatment recovers effectively, every 4-day treatment settles
into modest persistent debt, and the 2-day treatments separate by capacity:
the mild treatment settles without reaching maximum intake, the central
treatment approaches neutrality only near maximum intake, and the strong
treatment accumulates energy debt because its maximum-capacity cycle margin is
an unavoidable `-400 kJ`. Under the current 40,000 kJ reference reserve it
completes the 48-day horizon at approximately `-9,792 kJ` combined deviation;
the earlier day-47 boundary under a 10,000 kJ fixture was an arbitrary energy-
coordinate floor, not a biological threshold. Goal 018 changes no package
equation, state, schema, parameter, API, dependency, or test.

Rebuild Goal 019 adds a pure, read-only body-mass interpretation. The synthetic
reference animal has 38 kg fixed structural mass and 2 kg labile reserve tissue
at an effective 20,000 kJ kg^-1, so its 40,000 kJ energy reserve corresponds to
40 kg total mass. Body energy remains the sole dynamic state. Derived reserve-
tissue and total mass have no feedback on any transition. A paired 10,000-
versus-40,000 kJ experiment confirms the appetite, intake, gut, and relative
body-energy trajectories are invariant within floating-point roundoff, while
the larger reference removes Goal 018's artificial day-47 floor. This is a
synthetic interpretation layer, not macropod calibration or a claim that all
reserve tissue is fat.

## Next Decision Gate

Goal 020 remains unapproved. The next discussion should decide whether one
small animal-side consequence is still required or whether the model is ready
for a static, heterogeneous, non-depleting spatial forage environment. No
dynamic vegetation or mass-dependent energetic feedback is authorized.

## Candidate Later Layers

Previously discussed candidates include mass-dependent energetics, protein,
water, thermoregulation, plants, spatial foraging, and coupling between
established subsystems. Variable food quality, digestion, physical gut
capacity, meals, directed locomotion, and activity feedback also remain
unimplemented. This list records possible directions, not an approved sequence,
a claim that any layer comes next, or a promise to implement one.

Each layer requires a separately approved small goal with one principal
question, one subsystem, compact predeclared outputs, proportionate tests, and
an explicit stop. Results must be discussed before the next layer begins.

Legacy features are not migration tasks. `BWBrook/herbivoreTTR-legacy` at
`legacy-final-2026-07-16` is historical evidence only; its pre-freeze scientific
baseline is `abf68b691b4e30020625d1871dcabe56a5926bc1`.
