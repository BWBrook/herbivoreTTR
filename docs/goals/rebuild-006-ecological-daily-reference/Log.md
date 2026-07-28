# Rebuild Goal 006 Log

## 2026-07-27 - Formulation

Barry and the Herbivore TTR orchestrator adopted a two-reference doctrine:

- retain the Goal 005 constant-intake case as a permanent mathematical
  diagnostic and regression reference; and
- establish a minimally plausible ecological reference as the normal starting
  point for later ecological perturbations.

Barry approved:

```text
rest-closed interval = [08:00, 16:00)
rest-closed hour_of_day rows = 8:15
feeding hour_of_day rows = 0:7 and 16:23
feeding-period gut input = 150 kJ h^-1
rest-period gut input = 0 kJ h^-1
feeding intervals = 16
rest-closed intervals = 8
daily gut input = 2400 kJ
```

At the accepted Goal 004 fixture density of 10000 kJ kg^-1 DM, this is
0.015 kg DM h^-1 during feeding intervals and zero during rest, totalling
0.24 kg DM per day. Barry approved framing it as a generic day-resting,
nocturnally active reference rather than a calibrated species schedule or a
true crepuscular pattern.

Formulation began from:

```text
branch = main
HEAD = f043ab5f0a9713980337d201c99774eac4bcc0b6
origin/main = f043ab5f0a9713980337d201c99774eac4bcc0b6
worktree = clean
Goal 005 review output = retained and ignored
```

A read-only planning probe through the accepted Goal 004-005 functions found:

```text
mathematical reference burn-in = 7 d
ecological reference burn-in = 7 d
both daily prescribed inputs = 2400 kJ
both daily maintenance totals = 2400 kJ
both daily assimilation totals = 2400 kJ within Goal 005 tolerance
both daily body changes = 0 kJ within Goal 005 tolerance

ecological measured gut range = approximately 60-595 kJ
ecological measured body range = approximately 9917-10411 kJ
```

These probe values support packet feasibility but are not execution acceptance
evidence. They must be reproduced under the approved packet after publication.

Bounded read-only scientific and repository-surface reviews found the goal
draftable with no unresolved Barry-level decision. They recommended no
production source, public API, package metadata, manual, dependency, or
variable-dictionary change.

Packet formulation creates only:

```text
docs/goals/rebuild-006-ecological-daily-reference/Goal.md
docs/goals/rebuild-006-ecological-daily-reference/Plan.md
docs/goals/rebuild-006-ecological-daily-reference/Runbook.md
docs/goals/rebuild-006-ecological-daily-reference/Log.md
```

No Goal 006 implementation, test, experiment, generated output, staging,
commit, or push is authorized by this formulation. Barry's packet review and
execution approval remain pending.

## 2026-07-27 - Packet Review

A repository-surface review accepted the exact path, validation, artefact,
guard, and publication contract without a material finding.

The scientific review found one Important ambiguity: the primary within-day
trajectory contrast was described as "materially distinct" without an
executable magnitude or phase contract. One focused textual repair:

- fixed between-reference daily comparisons to the sums of the corresponding
  scenario-specific tolerances;
- fixed the ecological gut, release, and body phase landmarks; and
- added broad whole-kilojoule bands for the maximum gut, assimilation, and
  body trajectory differences.

This repair changed no schedule, fixture, model assumption, path surface,
validation boundary, or implementation authority.

The targeted scientific re-review accepted the repaired packet with no
remaining Critical or Important finding. No further formulation repair is
justified.

Frozen control-document hashes are:

```text
Goal.md = 7feb5854577c4f3cd1a56bc2ec355d4c19d13e4bf4d841914c3a2741766e8d26
Plan.md = 2dfc215aa14d9de1d05260946433c821059a9d23a61bf9a68f23451b7c74b933
Runbook.md = cc184497cf62542c24a1b5ca32e869fa7cbe2b659a2601731f69bf778496fcd6
```

The packet is ready for Barry's review. It remains uncommitted and does not
authorize Goal 006 execution or publication.

## 2026-07-27 - Approval, Publication, And Execution Preflight

Barry approved packet publication and Goal 006 execution.

The four-file packet was committed as:

```text
40021133a75b7e0a46230ff442dbb241c0179c9d
```

and pushed to `origin/main`. Local `main`, `origin/main`, and the live remote
`main` matched that commit with a clean worktree and empty index.

Execution began from:

```text
branch = main
execution baseline = 40021133a75b7e0a46230ff442dbb241c0179c9d
origin/main = 40021133a75b7e0a46230ff442dbb241c0179c9d
live remote main = 40021133a75b7e0a46230ff442dbb241c0179c9d
worktree = clean
index = empty
Goal, Plan, and Runbook hashes = approved values recorded above
Goal 006 output directory = absent
```

Execution is divided into non-overlapping fixture/experiment, review-pack, and
documentation lanes. The orchestrator owns integration, the mutable log,
validation, artefact inspection, scientific acceptance, and final Git-state
checks.

## 2026-07-27 - Implementation Checkpoint

The three non-overlapping execution lanes produced exactly the planned
implementation surface:

```text
README.md
docs/decisions/0006-ecological-daily-reference.md
docs/goals/rebuild-006-ecological-daily-reference/Log.md
docs/model-charter.md
docs/model-specification.md
docs/roadmap.md
experiments/rebuild-006-ecological-daily-reference.R
experiments/rebuild-006-review-pack.R
tests/testthat/test-ecological-daily-reference.R
```

No production source, public interface, package metadata, dependency, manual,
variable-dictionary entry, or previously accepted test changed.

The first executable drafts reproduced the approved numerical results but were
too large for the intended thin evidence layer. One focused proportionality
repair reduced the no-write experiment to 393 lines and the review-pack
generator to 641 lines, materially smaller than its Goal 005 predecessor,
without changing the fixture, assertions, output contract, or results. No
further style pass is justified.

The focused regression reported:

```text
PASS 137
FAIL 0
WARN 0
SKIP 0
```

Both references converged on burn-in day 7 and retained equal daily prescribed
dry matter, gut input, assimilation within tolerance, maintenance, gut change
within tolerance, and body change within tolerance. The two measured days
repeated with exact state carry-over and feasible non-negative body paths.

The ecological reference reproduced the approved phase landmarks:

```text
gut boundary maximum = 08:00
gut boundary minimum = 16:00
hourly gut release maximum = hour 8
hourly gut release minimum = hour 16
body-reserve boundary maximum = 10:00
body-reserve boundary minimum = 20:00
```

The maximum between-reference contrasts on each measured day were:

```text
gut boundary = 340.474558 kJ
hourly gut release = 85.118640 kJ
body boundary = 411.438555 kJ
```

The guarded review script generated the exact five ignored files, validated
all CSVs after read-back, and replaced the destination atomically. The complete
root validation ladder and independent final review remain pending.

## 2026-07-27 - Root Validation

The integrated implementation passed:

```text
new R files parse = OK
focused tests = PASS 137 / FAIL 0 / WARN 0 / SKIP 0
full tests = PASS 949 / FAIL 0 / WARN 0 / SKIP 0
renv status = synchronized
git diff --check = clean
source-loaded no-write experiment = passed with unchanged repository status
temporary package build = passed
temporary package installation = passed
installed-package no-write experiment = passed
installed-package review-pack generation and CSV read-back = passed
R CMD check --no-manual = Status: OK
guarded temporary directory cleanup = passed
```

The installed-package review run regenerated exactly:

```text
figure-1-measured-reference-comparison.png
table-1-input-schedules.csv
table-2-convergence.csv
table-3-daily-summary.csv
table-4-hourly-ledgers.csv
```

The CSV row counts excluding headers are 48 input rows, 14 convergence rows,
4 daily rows, and 96 hourly rows. Their schemas and values reproduce both
fixtures, day-7 convergence, daily accounting equivalence, the six ecological
phase landmarks, and the three declared trajectory-contrast bands.

Native-resolution figure inspection found a nonblank and legible four-panel
0-48 hour comparison with correct reference identities, units, two shaded
rest-closed intervals, the 24-hour boundary, and no clipping or overlap.

The exact scope, protected-path, ignored-output, frozen-hash, empty-index,
temporary-residue, and independent-review gates remain to be recorded.

## 2026-07-27 - Independent Review And Execution Closeout

An independent read-only final reviewer returned:

```text
verdict = ACCEPT
Critical findings = 0
Important findings = 0
```

The reviewer inspected the complete nine-path diff and five ignored outputs,
confirmed the frozen packet hashes and protected-path boundary, reran the
focused regression at 137 passes with no failure, warning, error, or skip, and
independently read the four CSV tables. It reproduced:

```text
table rows = 48 input / 14 convergence / 4 daily / 96 hourly
both burn-in endpoints = day 7
gut contrast = 340.474558434 kJ
hourly gut-release contrast = 85.118639609 kJ
body contrast = 411.438555335 kJ
ecological landmarks = 8 / 16 / 8 / 16 / 10 / 20
daily assimilation difference = 0 kJ
daily gut-change difference = 0 kJ
daily body-change difference = 1.8189894e-12 kJ
summed body comparison bound = 6.5725203e-10 kJ
```

The reviewer also confirmed that the 2200 by 1600 pixel figure is nonblank,
legible, correctly labelled, and faithful to the declared schedules and
landmarks.

Final root gates confirmed:

```text
changed path set = exact nine authorized paths
Git index = empty
production and Goal 001-005 protected paths = unchanged
Goal, Plan, and Runbook hashes = frozen values
review output = exact five-file set and ignored
repository tarball or Rcheck residue = absent
guarded temporary directory residue = absent
local HEAD = origin/main = live remote main
git diff --check = clean
```

Goal 006 execution is complete at the approved uncommitted review surface. The
ignored review pack is retained for Barry's discussion. No production code or
model mechanism changed, no material repair remains, and no implementation
path has been staged, committed, or pushed. Publication requires separate
authority.
