# Rebuild Goal 007: Routine-Activity Expenditure Log

## 2026-07-28 - Design Approval And Formulation

Barry approved the Goal 007 design and authorized execution after publication
of the accepted Goal 006 implementation.

Goal 006 was committed and pushed as:

```text
d9c75676cc65cd155d7bb46d6291740e76f53ad9
```

Formulation began from:

```text
branch = main
HEAD = d9c75676cc65cd155d7bb46d6291740e76f53ad9
origin/main = d9c75676cc65cd155d7bb46d6291740e76f53ad9
live remote main = d9c75676cc65cd155d7bb46d6291740e76f53ad9
worktree = clean
index = empty
Goal 006 review output = retained and ignored
```

Barry and the orchestrator agreed on the provisional sequence:

```text
Goal 007 = routine-activity expenditure primitive
Goal 008 = minimally ecological activity schedule and balanced reference
Goal 009 = finite feeding opportunity or maximum intake
Goal 010 = energy imbalance translated into body-mass change
```

This sequence is provisional beyond Goal 007 and creates no later
implementation authority.

Two independent read-only formulation reviews found no unresolved Barry-level
decision. They agreed that:

- activity must be a separate exact prescribed schedule, not a parameter,
  ingestion column, hidden default, or compatibility wrapper;
- it is an incremental cost above the existing synthetic maintenance term;
- neither term should be described as empirical BMR, NEAT, TEF, locomotion, or
  total metabolism;
- the zero and four-hour pulse fixtures are sufficient for this linear
  additive primitive;
- gut-only burn-in remains activity-free;
- every existing caller must migrate explicitly to a zero schedule; and
- the material implementation risk is caller breadth, not scientific
  complexity.

One review refinement fixed all pulse claims as counterfactual differences
from a matched zero-activity control. Another required the review figure to
show an explicit zero gut-difference trace rather than relying on visually
overlapping curves.

Formulation creates only the four files in this goal directory. No production
implementation, generated output, staging, commit, or push has occurred yet.

## 2026-07-28 - Packet Review And Focused Repair

The scientific packet review found one Important dimensional ambiguity:
`body_energy_change_kj` had been described as a rate. The repository-surface
review found two Important omissions: package-level documentation still
described a maintenance-only ledger, and the review-table schemas were not
fully executable.

One focused textual repair:

- separated `net_body_energy_rate_kj_h` from the one-hour
  `body_energy_change_kj` amount;
- named the plotted rate field and units explicitly;
- authorized the package source and generated package-manual updates; and
- fixed every review table's exact columns, row count, and deterministic
  ordering.

The repair changes no model equation, fixture, public interface, scientific
interpretation, stop boundary, or implementation authority. Targeted
re-reviews remain pending.

Both targeted re-reviews returned `ACCEPT_PACKET`. No Critical or Important
finding remains.

Frozen control-document hashes are:

```text
Goal.md = 5a774865bf97281ce17bba5a67a8717cd1221fbe7bb2a2b3593eefb59a83f653
Plan.md = 0592c21d420db2c86645cdbd4140a6342025f9345394142e261a910e1f2ef43c
Runbook.md = 69f5495ccc434e4219f4acedbf16e0d11ec524991fc0dcb3837ee5ed7145b6f5
```

The packet is ready for publication and authorized execution.
