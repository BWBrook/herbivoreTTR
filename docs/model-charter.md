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

The executable model contains two coupled stocks: one gut-energy buffer and
one physical body-energy reserve. Controlled prescribed ingestion enters the
gut during 24 fixed one-hour transitions. A fixed fraction of the opening gut
stock is released each hour and transferred one-for-one into the unchanged
body ledger, while constant maintenance expenditure leaves the body reserve.
The package returns an exact hourly ledger and a daily summary derived from
that ledger.

Gut stock is expressed in assimilable-energy equivalents. Release precedes
current-hour ingestion, so newly ingested energy is not eligible for release
until the next transition. Separate gut, body, and combined-system residuals
make the internal transfer and external inputs and expenditures inspectable.

The 50 kg reference mass used in the demonstration is experiment metadata
only. No implemented equation depends on body mass. The fixture values are
synthetic. This layer establishes arithmetic closure, delayed stock-flow
behavior, accounting semantics, and opening-to-closing state continuity; it
does not establish empirical realism, animal viability, or ecological
equilibrium.

## Current Stop Boundary

No further layer is specified or authorized. The implemented gut stock is not
food mass or gross energy and contains no food quality, digestive loss, waste,
capacity, feeding behavior, or body feedback. Activity, dynamic body mass,
protein, water, thermoregulation, plants, space, calibration, and all other
physiological or ecological detail remain outside the executable boundary.
Goal 003 results must be discussed before the next principal question is
chosen.

The predecessor is preserved privately as `BWBrook/herbivoreTTR-legacy` at tag
`legacy-final-2026-07-16`; its scientific baseline commit is
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
