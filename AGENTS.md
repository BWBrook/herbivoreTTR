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
- Do not introduce an object-oriented framework or a compatibility layer.

## Scientific Work

- Prefer ecological logic, dimensional consistency, empirical evidence, and
  transparent assumptions over legacy behavior.
- Record scientific assumptions and consequential design choices in `docs/`.
- Work in small goals: one principal question, one subsystem, compact
  predeclared outputs, proportionate tests, and an explicit stopping point.
- Discuss and approve the next layer before implementing it.

## Repository Discipline

- Keep source, experiments, references, and generated outputs separate.
- Never commit `outputs/`, package tarballs, check directories, or generated
  validation evidence.
- Do not copy legacy code or prose into this repository.
- Run the skeleton test and external `R CMD build` and
  `R CMD check --no-manual` for foundation changes.
- Stop before physiology unless a later, separately approved goal authorizes it.
