# Model Charter

## Purpose

Build a transparent ecological model that can explain when habitat and forage
conditions permit or prevent a large herbivore from maintaining physiological
state. The model grows through small, interpretable subsystems before they are
coupled.

## Scientific Authority

Ecological logic, dimensional consistency, empirical evidence, and explicit
assumptions govern the rebuild. Historical implementations are evidence about
previous thinking, not behavioral or architectural authority.

## Architecture

- Use R and a small functional package.
- Use a 24-hour clock with hourly transitions.
- Keep state in plain validated lists and histories in data frames.
- Separate state, parameters, prescribed inputs, process functions, and output.
- Keep transition functions pure and carry state explicitly.
- Put unit and basis suffixes in variable names.
- Validate public boundaries once; keep internal scalar transitions direct.
- Do not preserve obsolete interfaces or speculative extension points.

## Scientific Contract

The active animal model contains:

- dry-matter intake and metabolizable-energy conversion;
- a one-pool gut-energy stock with fractional hourly release;
- body-energy reserve with maintenance and prescribed routine activity;
- a bounded appetite target responding to body- and gut-energy deviations;
- an external non-depleting forage-acquisition ceiling; and
- a read-only body-mass interpretation.

Synthetic reference values are chosen for tractability and diagnosis. They are
not estimates for a named species or proof of physiological viability.

The isolated plant-side model contains one homogeneous standing edible-forage
stock, prescribed growth and non-herbivore background loss, and exact hourly
and daily biomass accounting. Its first process reference combines constant
production with proportional background loss around a declared positive
equilibrium. A fixed residual threshold purely derives standing biomass
accessible for later animal acquisition. The plant subsystem remains synthetic
and retains its isolated reference.

The minimum non-spatial coupling represents one focal physiology at a fixed
animal density per hectare. It scales realized per-animal intake to forage
removal, constrains intake by accessible forage per represented animal, and
carries forage, gut, and body state together. The density is an aggregate load,
not explicit population state.

The first spatial layer contains named patches with fixed non-depleting
acquisition capacities and metabolizable-energy densities, one focal animal
location, directed one-hour routes, and a prescribed closing-patch itinerary.
Movement suspends feeding for the interval and adds incremental expenditure to
the accepted appetite-energy system. The opening patch supplies food density
to the physiology. One fixed-demand remaining-bout score can choose between
staying and one known route using the two patches' acquisition capacities and
metabolizable-energy densities. Anticipation, richer nutritional composition,
and dynamic vegetation require separate contracts.

A prescribed scenario may designate one patch as a non-feeding water source
and impose a daily visit using the same route and itinerary records. This adds
only travel time, lost feeding opportunity, and incremental expenditure. It
is retained as the travel-only null for the separate water layer.

The minimum water layer carries one physical body-water stock independently of
the energy ledger. Effective water from realized dry-matter intake and drinking
while stationary at a known source add to it; fixed ordinary loss, one explicit
prescribed incremental evaporative-loss schedule, and excess elimination remove
water separately. A critical boundary is reported without implying mortality
or changing a transition. The current familiar-source null detects thirst on
the hourly clock, begins at most one complete trip only after detection, and
defers a late crossing. The thirst rule and temporal forcing regimes remain
experiment-level behavior rather than package API. Prescribed loss is not a
temperature-response or thermoregulation model.

The first dynamic spatial-forage layer keeps one biomass-density stock per
patch, separate from static patch acquisition capacity. Common autonomous
turnover acts in every patch; the co-located representative animal load removes
forage only from its occupied opening patch during a stay. The accepted first
comparison prescribes location rather than allowing resource-aware choice.

One retained diagnostic may use perfect knowledge of the complete opening
state and accepted model to compare a stay and one move counterfactual. This is
an upper benchmark for whether resource state can change the preferred action,
not a behavioral mechanism. A one-factor sweep may locate and attribute that
oracle boundary without promoting it into package behavior. Perception, memory,
prediction, and repeated decision-making require separate scientific contracts.

One independent diagnostic may compare full-day stay and move counterfactuals
while varying only current-patch metabolizable-energy density against a fixed
adequate destination. This perfect-model oracle establishes whether quality can
repay a declared route. The minimal patch-quality helper may be compared with
that oracle to expose its information error without becoming a forecast of
appetite or body state.

One diagnostic may compare the resource-state oracle with a myopic
current-patch acquisition cue and a prescribed destination expectation. Any
disagreement is reported as realized energetic regret. The cue remains an
information-limited null rather than a claim about animal perception or an
accepted repeated policy.

One closed-loop diagnostic may apply that cue at successive day boundaries
while carrying all accepted state. Both daily actions remain independently
evaluated so repeated spatial patterns can be attributed before any richer
behavioral mechanism is proposed.

That same diagnostic may change one established patch-energy density while
holding biomass dynamics and every other input fixed. This is the minimum
quality-by-biomass interaction test. Daily oracle disagreement is a local
information diagnostic along the carried myopic path, not the performance of a
separately carried optimal policy.

## Development Contract

Each substantive goal must introduce one interpretable process or scientific
comparison. It should declare its decision, protected invariants, compact
review surface, and stopping rule before implementation. New components are
tested in isolation before coupling.

Scientific conclusions receive rigorous verification. Engineering machinery
is proportional to current research risk. Git preserves superseded development
paths; the active tree contains only current code, evidence, and documentation.

## Boundaries

The current package does not include resource-dependent plant production,
weather or seasonal forcing, explicit senescence mechanisms, forage
functional responses beyond the accepted ceilings, explicit or heterogeneous
multiple animals, repeated or stochastic route choice as package behavior,
search, temperature- or state-dependent water loss, dynamic plant moisture,
renal physiology, multiple or uncertain drinking sources, protein,
thermoregulation, disease, reproduction, mortality, anticipatory quality-aware
choice, patch-specific turnover, or population dynamics. These are candidate
future layers, not placeholders in the current code.
