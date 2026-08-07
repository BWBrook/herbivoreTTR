# Rebuild Goal 012: Prescribed Energy-Repayment Pulse Log

## 2026-08-01 - Approval And Formulation Baseline

Barry approved the complete recommended sequence on 2026-08-01: publish the
accepted Goal 011, formulate and freeze Goal 012, execute it, and stop before
Goal 012 publication.

Goal 011 was published as:

```text
commit = d8c80a9ae088ab03022868e97eb5a6b943b3cf84
message = Add prescribed energy shortfall sequence
origin/main = d8c80a9ae088ab03022868e97eb5a6b943b3cf84
live remote main = d8c80a9ae088ab03022868e97eb5a6b943b3cf84
post-push worktree = clean
```

Goal 012 formulation began from that clean synchronized state with an empty
index. The accepted scientific design uses one `-800 kJ` prescribed-input day,
one `+800 kJ` prescribed-input day, and two balanced days. It remains an
evidence-only forcing sequence.

Formulation and execution are authorized. Publication is not authorized; all
Goal 012 work must remain uncommitted and unstaged for handoff.

## Packet Review And Freeze

Independent scientific review returned `ACCEPT_DESIGN`. It independently
derived the hourly contrast recurrence and confirmed the exact day-boundary
oracle: combined-system contrast is `-800 kJ` at 24 h and `0 kJ` at 48, 72,
and 96 h; gut and body contrasts remain equal and opposite after 48 h and
contract by `0.75^24` per balanced day.

Independent repository/runbook review initially found five Important execution
ambiguities. One bounded packet repair added executable output and schema
gates, separate no-write and publisher-guard probes, independent table
reconstruction with per-column mutation probes, frozen character ordering, and
an explicit protected-surface stop without `R CMD check`. Narrow re-review
returned `ACCEPT_SURFACE` with no remaining Critical or Important finding.

The accepted packet was frozen before implementation:

```text
Goal.md SHA-256 = 88e8394e1e98cf9bd865003e26c763a5512efd637ad9b49efed8c85a0b424094
Plan.md SHA-256 = 890fc84f314f5a0f61abff82dd066d0dad8a7bf688347fe43536a4b2ed83cbb6
Runbook.md SHA-256 = ce6aa504c88386c3f88bdb5d6a1537ad4ce203519b9ae827aa5afdf4511cabcc
```

## Implementation And Evidence

Implementation remained within the exact twelve-path scope. The two new thin
clients chain the existing exported reference-cycle and one-day runners; no
production R, test, package metadata, namespace, dependency, or earlier-goal
surface changed. The six documentation surfaces record the result as
evidence-only and leave Goal 013 unapproved.

The ignored review pack contains exactly:

```text
figure-1-prescribed-energy-repayment-pulse.png          1800 x 900
table-1-hourly-boundary-contrasts.csv                   97 x 7
table-2-daily-sequences.csv                              8 x 16
table-3-day-boundary-realignment.csv                     5 x 10
```

Observed treatment-minus-control values at `0, 24, 48, 72, 96 h` were:

| Elapsed time | Gut contrast (kJ) | Body contrast (kJ) | Combined contrast (kJ) |
| ---: | ---: | ---: | ---: |
| 0 h | 0 | 0 | 0 |
| 24 h | -181.781258 | -618.218742 | -800 |
| 48 h | 181.598860 | -181.598860 | approximately 0 |
| 72 h | 0.182215 | -0.182215 | approximately 0 |
| 96 h | 0.000183 | -0.000183 | approximately 0 |

Maximum retained contrast-closure residue was `8.98e-12 kJ`. The post-pulse
gut contrast matched the declared hourly recurrence and `0.75^24` daily
contraction. The daily table presents energy amounts and stocks as whole
kilojoules. Independently rounded identities use explicit worst-case tolerances
of `2-3 kJ`; all unrounded model and contrast invariants remain machine-scale
strict.

## Validation Receipts

Root-level validation confirmed:

- both clients parse and the experiment writes nothing under a Git-status
  invariance gate;
- the publisher retains the exact four-file set, schemas, row and character
  ordering, regular-file constraints, and `1800 x 900` PNG geometry;
- all 99 deliberate column mutations are rejected: 33 across the three
  in-memory tables, 33 after staged CSV readback, and 33 after retained CSV
  readback;
- each expected table is reconstructed directly from raw sequence results,
  schedules, and the analytical recurrence rather than from another retained
  table;
- zero, multiple, empty, and newline arguments, symbolic destinations,
  symbolic ancestors, and undeclared destination entries are rejected for
  their intended reason using checked physical `/private/tmp` fixtures;
- an induced staged semantic corruption is rejected before publication and
  preserves the existing exact four-file set and all four SHA-256 hashes;
- the full test suite reports `1287 passed, 0 failed, 0 warnings, 0 skipped`;
- `renv::status()` reports a synchronized environment;
- an external `R CMD build`, isolated installation, and both installed-package
  clients pass, with checked removal of the external build directory; and
- visual inspection confirms a legible three-panel figure with the positive
  gut overshoot visible and the whole-system return to zero shown separately.

`R CMD check` was not run, as required by the evidence-only goal boundary.
No package tarball, check directory, smoke directory, or guard fixture remains.

Independent implementation review inspected the real diff, raw-to-CSV
validation logic, 99 mutation probes, retained artefacts, figure, documentation,
frozen hashes, Git scope, and live base state. It reported no Critical or
Important defect. Final-state acceptance follows after the consolidated scope
and cleanliness gate.

## Acceptance

Independent final review returned `ACCEPT_IMPLEMENTATION` with no Critical or
Important finding. Root independently confirmed the full-suite, environment,
external build/install, installed-client, guard, preservation, artefact, and
visual-review receipts above.

The final gate passed with:

```text
HEAD = d8c80a9ae088ab03022868e97eb5a6b943b3cf84
origin/main = d8c80a9ae088ab03022868e97eb5a6b943b3cf84
live remote main = d8c80a9ae088ab03022868e97eb5a6b943b3cf84
Goal 012 changed-path set = exact twelve declared paths
index = empty
protected package and test surfaces = unchanged
declared ignored output set = exact four regular non-symbolic files
temporary/build/check residue = absent
```

Goal 012 is accepted for supervisor review and deliberately remains uncommitted
and unstaged. Publication requires later explicit authority from Barry.
