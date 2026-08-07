# AGENTS.md for herbivoreTTR

## Purpose

Build transparent functional R models of herbivore energetics from an explicit
scientific contract. This repository is a clean rebuild. The private legacy
repository is historical evidence, not scientific or architectural authority.

## Architecture

- Use R only.
- Keep the package small and functional, with thin scripts under `experiments/`.
- Represent state as plain validated records and transitions as pure functions.
- Separate dynamic state, fixed parameters, prescribed inputs, process
  functions, and recorded history.
- Use explicit unit suffixes in variable names and documentation.
- Do not preserve backwards compatibility. Remove obsolete paths rather than
  adding adapters, fallbacks, migrations, or dormant flags.

## Scientific Work

- Prefer ecological logic, dimensional consistency, empirical evidence, and
  transparent assumptions over legacy behavior.
- Record scientific assumptions and consequential design choices in `docs/`.
- Work in small goals: one principal question, one subsystem, compact
  predeclared outputs, proportionate tests, and an explicit stopping point.
- Discuss and approve the next layer before implementing it.
- Keep active goal working material minimal. On closeout, retain accepted
  conclusions in `docs/decisions/` and the current contract in the model docs;
  retire Goal, Plan, Runbook, and Log machinery.

## Evidence And Repository Discipline

- Keep source, no-write scientific experiments, references, and generated
  outputs separate.
- Never commit `outputs/`, package tarballs, check directories, or generated
  validation evidence.
- Do not retain review-pack publishers, bulk receipts, mutation suites, or
  goal-specific publication guards after their accepted conclusion is recorded.
- Do not copy legacy code or prose into this repository.
- Stop before physiology unless a later, separately approved goal authorizes it.

## Validation

- Fast change gate: parse retained R, run tests targeted at the affected
  scientific behavior, and run `git diff --check`.
- Explicit release gate: run the full test suite plus external `R CMD build`
  and `R CMD check --no-manual` when a package boundary or accepted foundation
  is being published.
- Repeat a full gate only for a distinct named risk. Stop when more work is
  unlikely to change the scientific or publication decision.
