# Model Charter

## Purpose

Develop a scientifically legible herbivore energetics model in which every
state transition, unit, assumption, and derived output can be inspected. The
rebuild begins from an intentionally small controlled system and adds ecological
complexity only when the preceding layer is understood.

## Governing Authority

Ecological logic, dimensional consistency, empirical evidence, and transparent
assumptions govern model design. Legacy behavior may motivate questions or
comparisons, but is never scientific truth or architectural authority.

## Architecture

- R is the only implementation language.
- Package code is functional; experiments are thin clients.
- State is represented by plain validated records.
- State, fixed parameters, prescribed inputs, processes, and history remain
  distinct.
- Process functions are pure and use names and documentation with explicit unit
  suffixes.
- Generated outputs remain outside source control.

## Work Contract

Each goal has one principal question and one subsystem, predeclares compact
outputs and proportionate tests, and ends at an explicit stopping point.
Results are discussed before the next layer is authorized. Bulk evidence
machinery is not part of this model-development approach.

## Current Executable Boundary

The first executable layer is a minimal body-energy accounting system. It
tracks one physical reserve through 24 fixed one-hour transitions. Prescribed
already-assimilated energy enters the ledger directly and constant maintenance
expenditure leaves it directly. The package returns an exact hourly ledger and
a daily summary derived from that ledger.

The 50 kg reference mass used in the demonstration is experiment metadata
only. No implemented equation depends on body mass. This layer establishes
arithmetic closure, accounting semantics, and opening-to-closing state
continuity; it does not establish empirical realism, animal viability, or
ecological equilibrium.

## Next Boundary

Controlled food and a one-pool gut/assimilation stock-flow system are the next
unimplemented model layer. They require a separately discussed and approved
goal. Until then, the package does not calculate food intake, gut storage,
passage, digestion, or assimilation. Activity and every later physiological or
ecological layer remain ordered after the gut layer in `roadmap.md`.

The predecessor is preserved privately as `BWBrook/herbivoreTTR-legacy` at tag
`legacy-final-2026-07-16`; its scientific baseline commit is
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
