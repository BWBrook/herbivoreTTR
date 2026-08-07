# Rebuild Goal 012: Prescribed Energy-Repayment Pulse Implementation Plan

**Goal:** Produce an evidence-only four-day sequence showing how an exact
external repayment pulse returns the whole-system contrast to zero while gut
transit delays realignment of the gut and body stocks.

**Architecture:** Existing exported package functions remain the sole model
engine. A no-write experiment constructs three prescribed schedules, creates
one balanced periodic gut state, and chains the existing one-day runner for a
four-day control and treatment. A guarded review client serializes three
compact tables and one figure. No package interface or production state
changes.

## Global Constraints

- Work from clean synchronized `main` at
  `d8c80a9ae088ab03022868e97eb5a6b943b3cf84`.
- Change only the twelve declared implementation paths.
- Preserve production R, tests, manuals, namespace, metadata, dependencies,
  existing experiments, and earlier goals and decisions.
- Use whole kilojoules for human-facing stocks and amounts, except small
  contrasts and residuals requiring scale-appropriate precision.
- Use `prescribed repayment pulse`, not animal compensation or recovery.
- Perform at most one focused material repair pass.
- Leave all Goal 012 work uncommitted and unstaged.

## Task 1: Freeze The Packet

**Files:**

- Create: `docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Goal.md`
- Create: `docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Plan.md`
- Create: `docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Runbook.md`
- Create: `docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Log.md`

- [ ] Verify clean synchronized `main` at the published Goal 011 commit.
- [ ] Obtain independent scientific and repository/runbook review.
- [ ] Resolve only Critical or Important packet findings.
- [ ] Record Goal, Plan, and Runbook SHA-256 hashes in `Log.md`.
- [ ] Keep the packet uncommitted and the index empty.

## Task 2: Build The Evidence Clients

**Files:**

- Create: `experiments/rebuild-012-prescribed-energy-repayment-pulse.R`
- Create: `experiments/rebuild-012-review-pack.R`

- [ ] Construct the balanced, shortfall, and repayment-pulse schedules.
- [ ] Construct the balanced periodic gut state once.
- [ ] Run both sequences from identical gut and body states.
- [ ] Carry both stocks across four days without another reset.
- [ ] Assert reference identities, state continuity, cumulative input,
  combined-system invariant, gut recurrence, body complement, closure, and
  finite stocks.
- [ ] Keep the experiment no-write and its summaries compact.
- [ ] Independently reconstruct all three expected tables from raw sequence
  results, schedules, and analytical recurrence before and after serialization.
- [ ] Mutation-probe every serialized column in memory and after CSV readback.
- [ ] Generate exactly three CSVs and the three-panel figure.

## Task 3: Document The Evidence Boundary

**Files:**

- Modify: `README.md`
- Create: `docs/decisions/0012-prescribed-energy-repayment-pulse.md`
- Modify: `docs/model-charter.md`
- Modify: `docs/model-specification.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/variable-dictionary.md`

- [ ] Record the two sequences, analytical invariants, and observed results.
- [ ] Separate a zero combined contrast from immediate stock realignment.
- [ ] State that the repayment pulse is synthetic external forcing.
- [ ] Preserve the evidence-only API and unapproved Goal 013 boundary.

## Task 4: Validate And Review

**File:**

- Modify: `docs/goals/rebuild-012-prescribed-energy-repayment-pulse/Log.md`

- [ ] Parse and run both clients with unchanged Git status.
- [ ] Reject invalid argument counts, newline arguments, symbolic destinations
  or ancestors, and undeclared entries; prove a failed staged validation leaves
  an existing valid pack unchanged.
- [ ] Validate exact outputs, schemas, ordering, arithmetic, recurrences, and
  figure legibility.
- [ ] Run the unchanged suite with an integer-safe `1287/0/0/0` gate.
- [ ] Confirm `renv` synchronization.
- [ ] Build and install once externally; run both installed-package clients.
- [ ] Verify frozen hashes, exact scope, protected paths, empty index, remote,
  output regularity, and cleanup.
- [ ] Obtain one independent final audit.
- [ ] Resolve at most one material repair, record acceptance, and stop
  uncommitted.
