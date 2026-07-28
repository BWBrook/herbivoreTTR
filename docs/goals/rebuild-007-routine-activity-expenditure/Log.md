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

## 2026-07-28 - Packet Publication And Execution Preflight

The four-file packet was committed and pushed as:

```text
47124cae08de0a04443b25024459732e909fcc8c
```

Execution began from:

```text
branch = main
execution baseline = 47124cae08de0a04443b25024459732e909fcc8c
origin/main = 47124cae08de0a04443b25024459732e909fcc8c
live remote main = 47124cae08de0a04443b25024459732e909fcc8c
worktree = clean
index = empty
Goal, Plan, and Runbook hashes = frozen values recorded above
Goal 007 output directory = absent
```

Implementation uses an explicit core API/caller migration followed by
non-overlapping evidence and documentation lanes. The orchestrator owns
integration, the mutable Log, validation, scientific acceptance, and the final
Git-state boundary.

## 2026-07-28 - Core Implementation

The core implementation adds one strict 24-row prescribed routine-activity
schedule and requires it explicitly at the body transition, body-day,
coupled-day, and reference-cycle interfaces. No default, wrapper, overload,
option, or compatibility path was added.

Routine activity is subtracted from body and whole-system energy alongside,
but separately from, fixed synthetic maintenance. Its rate, one-hour amount,
and daily total are exposed in the declared ledgers and included in the
relevant residual tolerance scales. It changes no gut equation or convergence
criterion and applies only during the two measured body days.

Every accepted Goal 002-006 caller now constructs and passes an explicit zero
schedule. An independent core review returned `ACCEPT_CORE` with no Critical
or Important finding after inspecting the implementation, tests, manuals, and
all eight migrated experiment or review callers.

## 2026-07-28 - Documentation And Diagnostic Evidence

Decision 0007 and the declared README, charter, specification, roadmap, and
variable-dictionary updates distinguish:

- fixed synthetic maintenance from prescribed incremental routine activity;
- external forcing from behavior or locomotion;
- the zero regression control from the diagnostic pulse;
- accounting evidence from empirical physiology; and
- Goal 007 from the Goal 008 ecological scheduling and intake-rebalancing
  discussion gate.

The no-write experiment and guarded review script produced exactly five
ignored files. Read-back evidence shows:

```text
gut convergence = day 7 in both scenarios
maximum pulse-control gut difference = 0 kJ
pulse = 50 kJ h^-1 in four intervals
daily pulse expenditure = 200 kJ
zero-control body closes = 10000, 10000 kJ
pulse body closes = 9800, 9600 kJ
daily pulse-control body-change difference = -200 kJ
```

The native 2200 by 1600 figure is nonblank, legible, and unclipped. It shows
both pulse windows, the 24-hour boundary, the visible zero gut counterfactual,
the four `-50 kJ h^-1` net body-rate intervals per day, and the exact reserve
decline.

## 2026-07-28 - Integrated Validation

The integrated validation ladder reports:

```text
changed source parse = 6/6
changed test parse = 7/7
all experiment parse = 10/10
focused tests = PASS 79 / FAIL 0 / WARN 0 / SKIP 0
full tests = PASS 1037 / FAIL 0 / WARN 0 / SKIP 0
renv status = synchronized
git diff --check = clean
Git index = empty
source-loaded no-write experiment = passed; repository status unchanged
CSV dimensions = 48x3, 14x8, 4x22, 96x26
CSV ordering and scientific reconstruction = passed
temporary package build = passed
temporary package installation = passed
installed no-write experiment = passed
installed review-pack generation and read-back = passed
R CMD check --no-manual = Status: OK
guarded temporary directory cleanup = passed
```

CSV reconstruction differed from the exact in-memory `-50 kJ h^-1`
counterfactual by at most `2.84e-14 kJ h^-1` after decimal read-back, within
the declared scale-aware tolerance of `1.11e-12 kJ h^-1`.

The first external build included the ignored `.superpowers` execution ledger
created during this goal and therefore returned one hidden-directory NOTE.
That orchestration-only scratch directory was removed without changing project
source or metadata. The materially changed package input was then rebuilt once;
the complete external ladder returned `Status: OK`, and no guarded temporary
directory remains.

## 2026-07-28 - Evidence-Guard Repair

The final review found one Important evidence-guard gap: the retained CSV
values were correct, but the review script reconstructed only a subset of the
declared counterfactual after reading the files back from disk.

One focused repair consolidated the in-memory and read-back checks into the
same validator and added:

- exact convergence, ingestion, assimilation, and complete gut-ledger
  invariance;
- exact measured day-1/day-2 gut repetition;
- hourly rate-to-amount and combined-stock identities;
- reconstructed hourly and daily gut, body, and whole-system balances;
- daily totals and opening/closing boundary consistency;
- exact activity totals, body-change contrasts, and reserve landmarks; and
- finite, non-negative stock checks.

The no-write experiment now also asserts exact measured-day gut repetition and
reconstructs gut residuals. Both repaired scripts parse and pass from the
source-loaded package. The review pack was regenerated, and the installed
experiment, installed read-back validator, and full external package check were
rerun because this material evidence repair invalidated their earlier receipt:

```text
installed no-write experiment = passed
installed review-pack generation and complete CSV read-back = passed
R CMD check --no-manual = Status: OK
guarded temporary directory cleanup = passed
```

## 2026-07-28 - Acceptance And Stop

The independent final reviewer returned:

```text
ACCEPT_GOAL_007
Critical/Important findings = none
```

The reviewer independently inspected the implementation, migrations, tests,
documentation, retained CSVs, and native figure; reran the focused tests and
complete retained-CSV validator; and confirmed the frozen hashes, exact
37-path scope, empty index, clean whitespace, exact five ignored outputs, and
absence of build or temporary residue.

Goal 007 is accepted as a synthetic prescribed-activity accounting primitive.
It establishes no empirical activity physiology or behavioral realism. The
implementation remains uncommitted at the publication boundary pending
Barry's separate authority. Goal 008 remains a discussion gate.
