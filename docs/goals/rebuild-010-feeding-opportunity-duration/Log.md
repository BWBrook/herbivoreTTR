# Rebuild Goal 010: Feeding-Opportunity Duration Log

## 2026-07-31 - Design Approval And Formulation

Barry approved:

- an evidence-only duration screen;
- fixed routine activity while feeding opportunity changes;
- `24`, `16`, `12`, and `8 h d^-1` opportunity fixtures;
- equal evening and morning windows for restricted fixtures;
- fixed open-hour intake of `0.020 kg DM h^-1`; and
- a compact three-table, one-figure review pack.

Formulation began from:

```text
branch = main
HEAD = b0b05a1895b6e79ab5d1b1a3d75b4d4e19152f8d
origin/main = b0b05a1895b6e79ab5d1b1a3d75b4d4e19152f8d
live remote main = b0b05a1895b6e79ab5d1b1a3d75b4d4e19152f8d
worktree = clean
index = empty
Goal 009 review output = retained and ignored
```

Barry explicitly authorized Goal 009 publication, Goal 010 packet publication,
and immediate Goal 010 execution. Goal 010 implementation publication remains
a later explicit decision.

## 2026-07-31 - Independent Packet Review And Freeze

Independent scientific review required the packet to distinguish the exact
daily duration relation from within-day trajectories conditional on clock
placement. It also required `opportunity` to be operationalized explicitly as
a prescribed-intake window used fully at the fixed rate. The repaired packet
adds prescribed-intake/activity overlap fields, narrow Goal 008 comparison
claims, tolerance-based raw-output expectations, and explicit rejection of
literal continuous feeding.

Independent repository review required executable reconstruction of the
execution baseline and frozen hashes, exact packet and implementation path
sets, integer-safe test counts, exact ignored-output checks, and zsh-safe
single-tarball discovery.

The repaired packet received:

```text
scientific review = ACCEPT_REPAIR
repository/runbook review = ACCEPT_REPAIR
```

Frozen packet hashes:

```text
Goal.md SHA-256 = 62ee88126404eea426809f5755edb2e361a297e25f47c394464150278de82ca3
Plan.md SHA-256 = 789e2118124acd4b063790ac8408834da2a6f652e9d15b09e42db42ca6862482
Runbook.md SHA-256 = 847ca178d5d34e5ccf415165e3d4ba7de26ba80bc8f7b1424668899a19673710
```

## 2026-07-31 - Execution Baseline

Execution baseline commit = b84ba49bde83d858104333f6320288a39d34b264

The exact four-file packet commit was pushed to `origin/main`; local `HEAD`,
local `origin/main`, and live remote `main` all resolved to this commit before
implementation began.

## 2026-07-31 - Implementation

Implementation remained evidence-only. It added:

```text
experiments/rebuild-010-feeding-opportunity-duration.R
experiments/rebuild-010-review-pack.R
docs/decisions/0010-feeding-opportunity-duration.md
```

and updated the declared README, charter, specification, roadmap, variable
dictionary, and this log. No package code, test, manual, namespace, metadata,
dependency, earlier experiment, or earlier decision changed.

The experiment constructs the exact `24`, `16`, `12`, and `8 h d^-1`
prescribed-intake windows and runs them through existing exported package
interfaces. The review client writes exactly:

```text
figure-1-feeding-opportunity-duration.png
table-1-hourly-prescribed-intake-windows.csv
table-2-duration-summary.csv
table-3-daily-accounting.csv
```

The implementation confirms:

- all four periodic gut cycles converge on burn-in day 7;
- the 16-hour complete result is exactly identical to Goal 008
  `ecological_activity_prescribed_balance`;
- the 12-hour fixture matches the declared Goal 008 uncompensated daily budget
  fields but not its complete result or within-day trajectories;
- the maximum 12-hour comparison differences are `357.570 kJ` across gut
  boundaries and `292.594 kJ` across body boundaries; and
- daily prescribed energy and body change are exactly
  `4800 / +1600`, `3200 / 0`, `2400 / -800`, and
  `1600 / -1600 kJ` for the four durations.

One focused material repair pass removed copied Goal 008 full-ledger
revalidation from the evidence client and repaired a clipped figure legend.
No further implementation polish was pursued.

## 2026-07-31 - Integrated Validation

Root validation produced:

```text
script parse = pass
source-loaded no-write experiment = pass; Git status unchanged
guarded review-pack generation = pass; Git status unchanged
table dimensions = 96 x 7, 4 x 18, 8 x 13
figure dimensions = 1800 x 900
independent CSV schedule and arithmetic reconstruction = pass
human-facing kJ amounts = whole numbers
full suite = 1287 PASS, 0 FAIL, 0 WARN, 0 SKIP
renv status = synchronized
external package build = pass
external package installation = pass
installed-package experiment smoke = pass
installed-package review-pack smoke = pass
figure inspection = pass
git diff check = pass
index = empty
```

The figure visibly distinguishes prescribed intake from the fixed activity
mask, marks the 16-hour neutrality threshold, and presents the four
clock-specific reserve trajectories without an empirical, behavioral, or
viability claim.

## 2026-07-31 - Independent Acceptance

An independent final reviewer returned:

```text
ACCEPT_GOAL_010
Critical findings = none
Important findings = none
focused repair justified = no
```

The reviewer independently checked packet hashes and parentage, exact Git
scope, protected surfaces, script parsing, retained file regularity and
dimensions, exported-API and CSV reconstruction, the Goal 008 comparison
claims, figure fidelity, and absence of temporary residue.

Goal 010 is accepted for the bounded 80/20 evidence handoff. Its result is
conditional on fixed `200 kJ h^-1` prescribed intake in open intervals, fixed
expenditure, and the four declared clock placements. It establishes neither a
generic within-day duration effect nor voluntary feeding, demonstrated
capacity, feasibility, compensation, or viability.

The implementation remains uncommitted and unstaged. Publication requires
later explicit authority from Barry.
