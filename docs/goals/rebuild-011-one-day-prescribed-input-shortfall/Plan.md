# Rebuild Goal 011: One-Day Prescribed-Input Shortfall Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use native subagent-driven
> development to implement this plan task by task. Steps use checkbox syntax
> for tracking.

**Goal:** Produce an evidence-only one-day prescribed-input shortfall sequence
that distinguishes gut-state realignment from persistent body and
whole-system energy debt.

**Architecture:** Existing exported package functions remain the sole model
engine. A no-write experiment constructs the accepted balanced and lower-rate
schedules, initializes both sequences from one balanced periodic gut state,
and chains the existing one-day runner for three carried days. A guarded
review client serializes compact tables and one figure. No package interface or
production state changes.

**Tech Stack:** R 4.6.x, base R graphics and CSV utilities, existing
`herbivoreTTR` exports, `testthat`, `pkgload`, and `renv`.

## Global Constraints

- Work from clean synchronized `main` at
  `468576f11cf407dc6ce6fde3e855758c6e7d0504`.
- Change only the twelve declared implementation paths.
- Preserve production R, tests, manuals, namespace, metadata, dependencies,
  existing experiments, and earlier goals and decisions.
- Use whole kilojoules for human-facing stocks and amounts, except small
  contrasts and residuals that require scale-appropriate precision.
- Use `return-to-reference forcing`, not animal `recovery`.
- Stop after one focused material repair pass.
- Leave all Goal 011 work uncommitted and unstaged.

## Task 1: Freeze The Packet

**Files:**

- Create: `docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Goal.md`
- Create: `docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Plan.md`
- Create: `docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Runbook.md`
- Create: `docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Log.md`

- [ ] Verify clean synchronized `main` at the published Goal 010 commit.
- [ ] Obtain independent scientific and repository/runbook review.
- [ ] Resolve only Critical or Important packet findings.
- [ ] Record Goal, Plan, and Runbook SHA-256 hashes in `Log.md`.
- [ ] Keep the packet uncommitted and the index empty.

## Task 2: Build The Evidence Clients

**Files:**

- Create: `experiments/rebuild-011-one-day-prescribed-input-shortfall.R`
- Create: `experiments/rebuild-011-review-pack.R`

**Consumes:** Existing exported schedule constructors, energy converter,
reference-cycle runner, and one-day gut-body runner.

**Produces:** One shared periodic starting state, two three-day sequences,
boundary contrasts, daily evidence, recurrence evidence, and the exact
four-file ignored review pack.

- [ ] Construct the balanced and shortfall schedules explicitly.
- [ ] Construct the balanced periodic gut state once.
- [ ] Run control and shortfall sequences from identical gut and body states.
- [ ] Carry both stocks exactly across three days without another reset.
- [ ] Assert the control oracle, state continuity, cumulative input contrast,
  combined-system invariant, gut recurrence, body complement, and finite
  stocks.
- [ ] Keep the experiment no-write and its printed summaries compact.
- [ ] Validate tables before and after CSV serialization.
- [ ] Generate the three-panel figure and exactly three CSVs.

## Task 3: Document The Evidence Boundary

**Files:**

- Modify: `README.md`
- Create: `docs/decisions/0011-one-day-prescribed-input-shortfall.md`
- Modify: `docs/model-charter.md`
- Modify: `docs/model-specification.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/variable-dictionary.md`

- [ ] Record the two sequences, analytical invariants, and observed results.
- [ ] Separate forcing restoration from biological recovery.
- [ ] Separate gut-state realignment from persistent body/system debt.
- [ ] State that the shortfall day is not the periodic uncompensated result.
- [ ] Preserve the unapproved Goal 012 decision boundary.

## Task 4: Validate And Review

**Files:**

- Modify:
  `docs/goals/rebuild-011-one-day-prescribed-input-shortfall/Log.md`

- [ ] Parse both scripts.
- [ ] Run source-loaded no-write and guarded review clients with unchanged Git
  status.
- [ ] Validate exact output sets, dimensions, ordering, arithmetic,
  recurrences, and figure legibility.
- [ ] Run the unchanged full suite with an integer-safe `1287/0/0/0` gate.
- [ ] Confirm `renv` synchronization.
- [ ] Build and install once in a guarded external directory; run both clients
  against the installed package.
- [ ] Verify exact scope, frozen hashes, protected paths, empty index, output
  regularity, and cleanup.
- [ ] Obtain one independent final audit.
- [ ] Resolve at most one material repair pass, record acceptance, and stop
  uncommitted.
