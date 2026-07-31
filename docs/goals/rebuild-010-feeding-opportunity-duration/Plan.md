# Rebuild Goal 010: Feeding-Opportunity Duration Plan

> **For agentic workers:** Use native subagent-driven development. Each worker
> receives one bounded, non-overlapping file surface and must return evidence,
> not a self-commit.

**Goal:** Produce an evidence-only four-level feeding-opportunity duration
screen while holding physiology, activity, food density, and prescribed
open-hour intake rate fixed.

**Architecture:** Existing exported package functions remain the sole model
engine. A no-write experiment constructs four ordinary intake schedules from
evidence-only prescribed-intake-window masks; a guarded review client
serializes compact tables and one figure. No package interface or production
state changes.

**Tech Stack:** R 4.6.x, base R graphics and CSV utilities, existing
`herbivoreTTR` exports, `testthat`, `pkgload`, and `renv`.

## Global Constraints

- Work from the clean synchronized Goal 010 packet commit on `main`.
- Change only the nine declared implementation paths.
- Preserve production R, tests, manuals, namespace, metadata, dependencies, and
  existing experiments.
- Use whole kilojoules for human-facing energy stocks and amounts.
- Stop after one focused material repair pass.
- Leave implementation uncommitted and unstaged.

## Task 1: Freeze And Publish The Packet

**Files:**

- Create: `docs/goals/rebuild-010-feeding-opportunity-duration/Goal.md`
- Create: `docs/goals/rebuild-010-feeding-opportunity-duration/Plan.md`
- Create: `docs/goals/rebuild-010-feeding-opportunity-duration/Runbook.md`
- Create: `docs/goals/rebuild-010-feeding-opportunity-duration/Log.md`

- [ ] Verify clean `main` at the Goal 009 publication commit.
- [ ] Obtain independent scientific and repository/runbook review.
- [ ] Resolve only Critical or Important packet findings.
- [ ] Record Goal, Plan, and Runbook SHA-256 hashes in `Log.md`.
- [ ] Commit and push exactly the four packet files.
- [ ] Record the synchronized packet commit as the execution baseline.

## Task 2: Build The Evidence Clients

**Files:**

- Create: `experiments/rebuild-010-feeding-opportunity-duration.R`
- Create: `experiments/rebuild-010-review-pack.R`

**Consumes:** Existing exported constructors and reference-cycle runner.

**Produces:** In-memory fixtures, the three declared evidence tables, four body
trajectories, and the exact four-file ignored review pack.

- [ ] Construct explicit prescribed-intake-window masks and schedules for 24,
  16, 12, and 8 hours.
- [ ] Construct the fixed routine-activity schedule and direct Goal 008
  comparison schedules.
- [ ] Run all fixtures through exported package functions.
- [ ] Assert exact schedules, prescribed-intake/activity overlap, analytical
  accounting, daily closures, 16-hour full identity, and the narrower 12-hour
  daily-budget match.
- [ ] Keep the experiment no-write and its printed summaries compact.
- [ ] Build the guarded serializer and validate tables before and after CSV
  serialization.
- [ ] Generate the three-panel figure and exactly three CSVs.

## Task 3: Document The Evidence Boundary

**Files:**

- Modify: `README.md`
- Create: `docs/decisions/0010-feeding-opportunity-duration.md`
- Modify: `docs/model-charter.md`
- Modify: `docs/model-specification.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/variable-dictionary.md`

- [ ] Record the four fixtures, analytical threshold, observations, and
  reference relationships.
- [ ] Mark prescribed-intake-window fields as evidence-only rather than
  production state or voluntary opportunity.
- [ ] Separate the daily duration relation from within-day effects conditional
  on the declared clock placement.
- [ ] Distinguish daily-budget equality from within-day/full-result identity.
- [ ] Preserve the unapproved Goal 011 decision boundary.

## Task 4: Validate And Review

**Files:**

- Modify: `docs/goals/rebuild-010-feeding-opportunity-duration/Log.md`

- [ ] Parse both scripts.
- [ ] Run source-loaded no-write and guarded review clients with unchanged Git
  status.
- [ ] Validate exact output sets, dimensions, ordering, values, whole-kJ
  presentation, and figure legibility.
- [ ] Run the unchanged full suite with an integer-safe `1287/0/0/0` gate.
- [ ] Confirm `renv` synchronization.
- [ ] Build and install once in a guarded external directory; run both clients
  against the installed package.
- [ ] Verify exact scope, frozen hashes, protected paths, empty index, output
  regularity, and cleanup.
- [ ] Obtain one independent final audit.
- [ ] Resolve at most one material repair pass, record acceptance, and stop
  uncommitted.
