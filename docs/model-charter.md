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
equilibrium. It remains synthetic and is not coupled to the animal.

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
availability, herbivore depletion, explicit locations, search, water balance,
protein, thermoregulation, disease, reproduction, mortality, or population
dynamics. These are candidate future layers, not placeholders in the current
code.
