# Decision 0001: Clean Rebuild

Date: 2026-07-16

Status: accepted

## Context

The earlier repository contains useful historical evidence, but its coupled R
and C++ implementation, release machinery, generated evidence, and inherited
assumptions must not define the rebuilt model.

## Decision

- Preserve the predecessor as the private, read-only repository
  `BWBrook/herbivoreTTR-legacy` at annotated tag
  `legacy-final-2026-07-16`.
- Start `BWBrook/herbivoreTTR` as an unrelated private repository with one clean
  root foundation commit.
- Keep R as the sole implementation language.
- Use a small functional package and thin experiments: plain validated state
  records, pure functions, and strict separation of state, fixed parameters,
  prescribed inputs, processes, and history.
- Do not use an object-oriented framework or reproduce legacy behavior through
  a compatibility layer.
- Rank ecological logic, dimensional consistency, empirical evidence, and
  transparent assumptions above legacy R or C++ behavior.
- Use explicit unit suffixes and small, separately approved subsystem goals.

## Consequences

No legacy source, prose, simulation, generated output, targets pipeline, release
machinery, or physiological implementation enters the new foundation. The
future irreducible core is a design contract only and later layers require
separate discussion and authorization.

The scientific baseline immediately before the legacy freeze is commit
`abf68b691b4e30020625d1871dcabe56a5926bc1`.
