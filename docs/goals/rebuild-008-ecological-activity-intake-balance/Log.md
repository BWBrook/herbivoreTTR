# Rebuild Goal 008: Ecological Activity And Intake Balance Log

## 2026-07-30 - Design Approval And Formulation

Barry approved the Goal 008 design and authorized execution.

Formulation began from:

```text
branch = main
HEAD = fab7c0b9340ca4befa18fe0943dd86869c02cff8
origin/main = fab7c0b9340ca4befa18fe0943dd86869c02cff8
live remote main = fab7c0b9340ca4befa18fe0943dd86869c02cff8
worktree = clean
index = empty
Goal 007 review output = retained and ignored
```

The approved three-fixture design uses the Goal 006 ecological timing:

```text
baseline = 150 kJ h^-1 intake, 0 kJ h^-1 activity
activity-unbalanced = 150 kJ h^-1 intake, 50 kJ h^-1 activity
activity-balanced = 200 kJ h^-1 intake, 50 kJ h^-1 activity
active/intake hours = 0:7 and 16:23
rest hours = 8:15
```

Goal 008 is an evidence-only reference tranche. It adds no production
mechanism, schema, feedback, intake feasibility, or behavior.

## 2026-07-30 - Packet Review And Freeze

Independent scientific review accepted the packet without a Critical or
Important finding. Independent repository-surface review identified an
operational ambiguity between the clean Goal 007 formulation parent and the
post-publication execution baseline, plus declarative rather than executable
final scope gates. One focused repair:

- distinguished `fab7c0b` as the formulation parent from the packet commit
  used as `EXECUTION_BASE`;
- prescribed a machine-readable execution-baseline record;
- added executable branch, synchronization, packet-hash, exact-path,
  protected-path, empty-index, and tracked/untracked whitespace gates; and
- corrected a zsh-specific loop-variable collision found by live dry-run.

The repository-surface reviewer accepted the repaired packet. Frozen control
hashes are:

```text
Goal.md SHA-256 = 89626e84a74f270d6c1d0b11c5a80c7a6a221ca9e2af5372373ae3627b21479f
Plan.md SHA-256 = bce47dafa6bfaef746d86f09e7748afbe7fc52c81be07ea5bd8755a27ffc564b
Runbook.md SHA-256 = ed387d938738fcda6c02b2dc198711419e89063b77cdfa2465f7f02d86e1fd74
```
