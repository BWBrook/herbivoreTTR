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

## 2026-07-30 - Execution Baseline

Execution baseline commit = ffbabaf3491c662717f30672f413adafaaf6092c

The exact four-file packet commit was pushed to `origin/main`; local `HEAD`,
local `origin/main`, and live remote `main` all resolved to this commit before
implementation began.

## 2026-07-30 - Implementation And Focused Review

The implementation added only the declared evidence clients, Decision 0009,
and bounded explanatory documentation. Production R, tests, package metadata,
exports, manuals, dependencies, schemas, and existing experiments were
unchanged.

The retained evidence establishes:

```text
analytical threshold = 0.020 kg DM h^-1 = 200 kJ h^-1
below constrained input = 2400 kJ d^-1
below body change = -800 kJ d^-1
below closing reserves = 9200 kJ, 8400 kJ
at constrained input = 3200 kJ d^-1
above constrained input = 3200 kJ d^-1
at and above closing reserves = 10000 kJ, 10000 kJ
curtailed active intervals = 16, 0, 0
touching active intervals = 0, 16, 0
unused active-ceiling headroom = 0 kJ, 0 kJ, 800 kJ
exact Goal 008 oracle identities = TRUE for all six measured days
```

One focused orchestrator review repaired human-facing floating-point dust,
non-portable plot unit glyphs, an overlong console table, and visual
overprinting of the exactly identical at/above trajectories. Energy stocks and
amounts now appear as whole kilojoules; rates and dry matter retain appropriate
precision.

The retained ignored review pack contains exactly:

```text
figure-1-synthetic-intake-ceiling-threshold.png = 1800 x 900
table-1-hourly-ceiling-screen.csv = 72 x 7
table-2-threshold-summary.csv = 3 x 15
table-3-daily-accounting.csv = 6 x 14
```

## 2026-07-30 - Validation And Acceptance

Validation receipts:

```text
new scripts parse = passed
source-loaded no-write experiment = passed
source-loaded guarded review pack = passed
Git status across source-loaded runs = unchanged
independent CSV contract and whole-kJ readback = passed
full tests = PASS 1287, FAIL 0, WARN 0, SKIP 0
renv status = synchronized
external package build = passed
temporary package installation = passed
installed-package experiment and review pack = passed
R CMD check --no-manual = Status: OK
frozen packet hashes = matched
exact nine-path scope = passed
protected paths = unchanged
index = empty
retained outputs = exact, regular, and non-symbolic
temporary build/check residue = absent
```

The frozen runbook's literal full-count assertion compared integer test counts
with double literals using `identical()` and therefore rejected the otherwise
correct `1287/0/0/0` result. Repeating the suite once with explicit integer
coercion passed. This was a validation-wrapper type defect, not a package or
test failure; the frozen packet was not altered during execution.

Independent final review returned:

```text
ACCEPT_80_20
Critical findings = none
Important findings = none
```

The only recorded visual limitation is a redundant threshold text annotation
outside the first panel's plotted range. The red reference line intersects the
explicit `200 kJ/h` axis tick, so the threshold remains unambiguous and another
polish pass is not justified.

Goal 009 is accepted for review. The implementation remains uncommitted and
unstaged pending separate publication authority.
