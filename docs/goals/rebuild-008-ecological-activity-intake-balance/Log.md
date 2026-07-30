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

## 2026-07-30 - Execution Start

Execution baseline commit = 675d4082ae2d1fb0ec74618b07a8424198bdac05

The packet-only commit was pushed to synchronized `main`. Goal 008
implementation began from that clean baseline with an empty index.

## 2026-07-30 - Evidence And Documentation

Goal 008 was implemented without changing production code, package interfaces,
records, schemas, validators, dependencies, or the variable dictionary.

The exact three fixtures were composed through existing exported functions.
Observed results were:

```text
scenario                                  input  assimilation  activity  body change
ecological_day_resting                    2400          2400         0       about 0 kJ/d
ecological_activity_uncompensated         2400          2400       800            -800 kJ/d
ecological_activity_prescribed_balance    3200          3200       800       about 0 kJ/d
```

All three gut cycles first converged on burn-in day 7. Body reserve closed
measured days 1 and 2 at approximately:

```text
ecological_day_resting                    10000 / 10000 kJ
ecological_activity_uncompensated          9200 /  8400 kJ
ecological_activity_prescribed_balance    10000 / 10000 kJ
```

The baseline and uncompensated convergence and gut ledgers matched exactly in
memory. Baseline-minus-uncompensated body-reserve differences at continuous
boundaries `0, 8, 16, 24, 32, 40, 48 h` were exactly
`0, 400, 400, 800, 1200, 1200, 1600 kJ`. The balanced gut and assimilation
paths followed the predicted `4/3` scaling; the largest in-memory error was
approximately `1.14e-13 kJ`.

The retained review pack contains exactly:

```text
figure-1-ecological-activity-intake-balance.png
table-1-prescribed-schedules.csv          72 x 5
table-2-convergence.csv                   21 x 8
table-3-daily-summary.csv                  6 x 22
table-4-hourly-ledgers.csv               144 x 26
```

The native `2400 x 1800` figure is nonblank, legible, unclipped, faithful to
the CSV ledgers, and `355637` bytes after final regeneration. It shows the
prescribed input and activity schedules, net body-energy rates, and body
reserves over two measured days.

Documentation now makes
`ecological_activity_prescribed_balance` the normal synthetic ecological
accounting reference, retains `ecological_day_resting` as its zero-activity
ecological comparator, and retains `mathematical_continuous` as the permanent
arithmetic and regression diagnostic. Decision 0008 records the evidence and
interpretive boundary.

The balanced rate `200 kJ h^-1` and total `0.32 kg DM d^-1` remain prescribed,
not shown feasible. Daily balance is not feeding behavior, adaptive
compensation, biological equilibrium, viability, or empirical physiology.
Goal 009 remains a discussion and approval gate for finite feeding opportunity
or intake limits.

## 2026-07-30 - Validation And Review

Validation receipts:

```text
new R files parsed = 3
focused test counts = PASS 250, FAIL 0, WARN 0, SKIP 0
full test counts = PASS 1287, FAIL 0, WARN 0, SKIP 0
renv status = synchronized
source-loaded no-write experiment = passed; Git status unchanged
source-loaded review generation = passed; CSV read-back passed
review output = exactly 5 ignored regular non-symbolic files
external build = passed
temporary installation = passed
installed-package no-write experiment = passed
installed-package review generation = passed
R CMD check --no-manual = Status: OK
packet hashes = frozen and verified
changed implementation paths = exactly 9 authorized paths
protected paths = unchanged
Git index = empty
external temporary residue = absent
```

Independent evidence review returned `ACCEPT_EVIDENCE` with no Critical or
Important finding. It independently reconstructed the CSV accounting,
convergence, `4/3` scaling, carry-over, paired contrasts, and boundary
landmarks, and matched a fresh exported-API run to the retained CSVs within
declared read-back tolerances.

The three evidence clients are long and repeat local fixture and tolerance
scaffolding. Independent review judged this non-material because they remain
self-contained clients of exported functions and reimplement no gut
recurrence, body transition, convergence loop, or production mechanism.
Compressing them now would add risk for little scientific gain, so no further
polish loop was undertaken.

Goal 008 remains uncommitted pending final full-diff review and Barry's
separate publication authority.

## 2026-07-30 - Final Acceptance

Independent final full-diff audit returned `ACCEPT_GOAL_008` with no Critical
or Important finding and no justified repair. It checked the frozen packet,
exact nine-path diff, protected surfaces, tests and evidence clients, fresh
public-API reconstruction, retained CSVs and figure, documentation claims,
ignored-output boundary, empty index, and absence of build/check residue.

Goal 008 is accepted at the requested 80/20 handoff. The implementation and
retained review pack remain uncommitted pending Barry's separate publication
authority.
