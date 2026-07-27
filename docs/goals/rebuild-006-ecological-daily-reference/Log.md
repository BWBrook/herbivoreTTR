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
