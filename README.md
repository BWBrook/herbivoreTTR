# herbivoreTTR

`herbivoreTTR` is the clean foundation for transparent functional R models of
herbivore energetics. This repository currently contains package metadata and
the approved scientific design contract only. It implements no physiology,
plant dynamics, simulation, or generated evidence.

## Design

The rebuild uses plain validated state records, pure functions, and strict
separation of dynamic state, fixed parameters, prescribed inputs, process
functions, and history. Variables and documentation use explicit unit suffixes.
Experiments remain thin clients of the package. Each future goal addresses one
principal question and one subsystem, with compact outputs, proportionate tests,
an explicit stop, and discussion before another layer is added.

The future irreducible core is specified in
[`docs/model-specification.md`](docs/model-specification.md), but is deliberately
not implemented by this foundation commit. Later layers are ordered in
[`docs/roadmap.md`](docs/roadmap.md).

## Provenance

The preceding implementation is preserved in the private repository
`BWBrook/herbivoreTTR-legacy` at annotated tag
`legacy-final-2026-07-16`. The scientific baseline immediately preceding the
freeze is commit `abf68b691b4e30020625d1871dcabe56a5926bc1`.

Legacy R and C++ behavior is historical evidence only. Ecological logic,
dimensional consistency, empirical evidence, and transparent assumptions govern
the rebuild.
