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

## Foundation Boundary

This repository foundation implements no physiology. The first model core and
the later layer order are contracts in `model-specification.md` and
`roadmap.md`, not capabilities of version `0.0.0.9000`.

The predecessor is preserved privately as `BWBrook/herbivoreTTR-legacy` at tag
`legacy-final-2026-07-16`; its scientific baseline commit is
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
