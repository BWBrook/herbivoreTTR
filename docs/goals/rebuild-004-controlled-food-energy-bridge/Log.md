# Rebuild Goal 004 Log

## 2026-07-26 - Scientific Direction

Barry accepted Rebuild Goal 003 as a correct one-pool storage-and-delay layer.
The initialized equilibrium, empty-start transient, and pulse response behaved
as designed. Barry approved the next bounded question: convert prescribed food
dry matter into the existing gut available-energy input using one fixed
dry-matter-basis metabolizable-energy density.

Barry confirmed:

- prescribed food mass should use a dry-matter basis;
- energy density should be treated as already metabolizable;
- the reason is to add ecological units without adding digestive mechanisms;
  and
- internal precision should be retained, while human-facing energy stocks and
  amounts should normally be shown as whole kilojoules.

The accepted design uses a pure upstream converter. It does not extend the Goal
003 schedule, alter gut or body transitions, or add another coupled runner.

## 2026-07-26 - Goal 003 Published Baseline

Barry explicitly authorized commit and push of the accepted Goal 003
implementation. Exactly its reviewed 27 paths were staged and committed as:

```text
branch = main
commit = e2622ca739d89124e8cb8361fb40363363686d49
message = Implement one-pool gut energy buffer
origin/main = e2622ca739d89124e8cb8361fb40363363686d49
live remote main = e2622ca739d89124e8cb8361fb40363363686d49
status = clean
```

This commit is the immutable Goal 004 formulation and proposed execution
baseline.

## 2026-07-26 - Formulation State

Formulation is authorized by Barry's approval of the Goal 004 design.
Formulation creates only:

```text
docs/goals/rebuild-004-controlled-food-energy-bridge/Goal.md
docs/goals/rebuild-004-controlled-food-energy-bridge/Plan.md
docs/goals/rebuild-004-controlled-food-energy-bridge/Runbook.md
docs/goals/rebuild-004-controlled-food-energy-bridge/Log.md
```

No source, test, experiment, package metadata, generated documentation,
dependency, output, staging, commit, push, legacy inspection, or Goal 004
implementation is authorized during formulation.

The packet deliberately requires no external figure bundle. The conversion is
a deterministic multiplication, so exact schedules, focused tests, compact
experiment stdout, and downstream equivalence provide the decision-relevant
review surface.

## 2026-07-26 - Independent Packet Review

Two read-only reviewers independently examined the proposed packet.

The scientific review found no Critical defect and two Important wording
contradictions. The numerical policy was narrowed to food quantities and
energy rates so the required integer hour key remains explicit. The fixture
section now states that the factorization-equivalence case deliberately uses
the second density needed to demonstrate structural non-identifiability. A
focused confirmation accepted both repairs.

The execution review found no Critical defect and one Important cleanup-status
defect in the external validation trap. The repaired trap now checks the
recursive deletion result, verifies that the temporary directory is absent,
reports cleanup failure when the run otherwise succeeded, and preserves any
earlier nonzero validation status. A focused confirmation accepted the final
repair.

No broad second pass was justified. Neither reviewer edited files, ran R,
tests, builds, or experiments, generated artifacts, or mutated Git state.

## 2026-07-26 - Frozen Execution Contract

The reviewed execution contract is frozen at:

```text
Goal.md = 81f1c8b6f1a1ee80dbe381f436eaa623eca5c4febc1713033b7a7e8641c8e803
Plan.md = 2eb49592483b93264d15e5bb780053aa000542f46cc4244247a9a74805dd73ef
Runbook.md = 26aa1d1b00b48438b3fb9b24b1246cb420fca784368de14d8adc940e905e6171
```

These hashes, the published Goal 003 baseline, and the exact four-file packet
state are the proposed Goal 004 execution preconditions.

## 2026-07-26 - Packet Publication Authority

Barry explicitly authorized commit and push of the reviewed Goal 004 packet.
This authority covers exactly the four formulation files listed above. It does
not authorize Goal 004 implementation, changes to any source or test file,
release publication, tagging, or any other repository mutation.
