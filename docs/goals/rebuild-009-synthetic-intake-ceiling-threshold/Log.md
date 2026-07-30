# Rebuild Goal 009: Synthetic Intake-Ceiling Threshold Log

## 2026-07-30 - Design Approval And Formulation

Barry approved the evidence-only threshold design and authorized execution.

Formulation began from:

```text
branch = main
HEAD = 96caf0eaa1f542be8b529546d1aa0b999adf5eab
origin/main = 96caf0eaa1f542be8b529546d1aa0b999adf5eab
live remote main = 96caf0eaa1f542be8b529546d1aa0b999adf5eab
worktree = clean
index = empty
Goal 008 review output = retained and ignored
```

The approved design brackets the exact accounting threshold with synthetic
active-hour ceilings:

```text
below = 0.015 kg DM h^-1
at = 0.020 kg DM h^-1
above = 0.025 kg DM h^-1
candidate prescription = 0.020 kg DM h^-1
active/intake hours = 0:7 and 16:23
rest hours = 8:15
```

Goal 009 is evidence-only. It adds no production mechanism, package API,
schema, physiological ceiling, feeding behavior, or intake redistribution.

## 2026-07-30 - Independent Packet Review And Freeze

Three independent reviews examined the draft packet before publication:

- scientific review rejected the initial ambiguous use of `binding` at the
  exact threshold; the repaired packet now distinguishes ceiling exceedance,
  curtailment, exact touching, and unused active-ceiling headroom;
- repository-surface review rejected initially descriptive publication and
  final-state checks; the repaired runbook now reconstructs exact path sets,
  verifies packet ancestry and hashes, checks the empty index and protected
  paths, and stops uncommitted; and
- contrarian scope review challenged redundant downstream accounting work; the
  repaired packet retains the four Barry-approved review outputs but uses exact
  Goal 008 full-result identity as the sole downstream accounting gate.

The repaired packet received:

```text
scientific review = ACCEPT_REPAIR
repository-surface review = ACCEPT_REPAIR
contrarian scope review = ACCEPT_SCOPE_REPAIR
```

Frozen packet hashes:

```text
Goal.md SHA-256 = c8d29c61de778a858d9d241e9542d8899bbc961fadf77e7015f77f40260df69c
Plan.md SHA-256 = 0cada40133e8a5d6bc744db29917becefdfe62cd639ca72e38c6ed40a8d22e64
Runbook.md SHA-256 = 7ecd88a622adaa72c9459b3c9e44e8974e4b1a7aa61b86601bb158dcfa911260
```
