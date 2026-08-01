# Rebuild Goal 011: One-Day Prescribed-Input Shortfall Log

## 2026-07-31 - Approval And Formulation Baseline

Barry approved the proposed Goal 011 on 2026-07-31.

The orchestrator selected the accepted Goal 009 lower-rate schedule as the sole
event rather than changing window duration. This preserves the balanced clock
geometry and isolates an exact `800 kJ` prescribed-input shortfall.

Formulation began from:

```text
branch = main
HEAD = 468576f11cf407dc6ce6fde3e855758c6e7d0504
origin/main = 468576f11cf407dc6ce6fde3e855758c6e7d0504
live remote main = 468576f11cf407dc6ce6fde3e855758c6e7d0504
worktree = clean
index = empty
Goal 010 review output = retained and ignored
```

Goal 011 formulation and execution are authorized. Publication is not
authorized; all Goal 011 work must remain uncommitted and unstaged for handoff.

## Packet Review And Freeze

Independent scientific review returned `ACCEPT_PACKET`: the treatment-control
contrast is identifiable, the sign convention and transition order are
coherent, the analytic invariants are sufficient, and the interpretation and
exclusions are appropriately bounded.

Independent repository/runbook review first returned `ACCEPT_REPAIR`. The
bounded repair added fail-closed shell settings, made the formulation gate
recognize exactly the four untracked packet files, converted output dimensions
and residue checks from prose to executable assertions, and placed PNG
connection cleanup inside a valid R function context. A narrow re-review then
returned `ACCEPT_PACKET`.

The frozen packet hashes are:

```text
Goal.md SHA-256 = 0c3933ab094edc2debafe8c2eb0e3b2e335938f5f9daf481132b602c7904ce6a
Plan.md SHA-256 = 80ca63bf185209c23a8a302ad18bdb8751f1c3e389f348803093c2a7124490e5
Runbook.md SHA-256 = c7046ec5ca9b50b39a84a143a6fb105246186526b2483e20a4e867162ecf55a4
```

These three files are frozen for execution. Any material contract change must
stop execution and return to Barry.

## Implementation And Observed Evidence

Implementation stayed within the declared evidence-only boundary:

```text
production R changes = none
test changes = none
package interface or schema changes = none
new production multi-day runner = none
evidence clients = 2
retained ignored files = 4
```

Both sequences were initialized from the same balanced period-24 gut state and
the same `10000 kJ` body reserve. The clients then chained the exported one-day
runner for three carried days without another reset.

The observed treatment-minus-control day boundaries were:

| Elapsed time | Gut contrast (kJ) | Body contrast (kJ) | Combined contrast (kJ) |
| ---: | ---: | ---: | ---: |
| 24 h | -181.781258 | -618.218742 | -800 |
| 48 h | -0.182398 | -799.817602 | -800 |
| 72 h | -0.000183 | -799.999817 | -800 |

The return-to-reference daily gut contraction factor was
`0.75^24 = 0.00100339127755333`. The maximum retained
combined-versus-input closure residual was `1.09e-11 kJ`.

The review pack contains exactly:

```text
figure-1-one-day-prescribed-input-shortfall.png
table-1-hourly-boundary-contrasts.csv = 73 x 7
table-2-daily-sequences.csv = 6 x 16
table-3-day-boundary-realignment.csv = 4 x 10
```

The `1800 x 900` figure was inspected directly. It clearly separates the
single shortfall day from the two return-to-reference days, the changing
gut/body partition, and the fixed `-800 kJ` whole-system contrast.

## Focused Repair

Independent implementation review found one Important evidence-integrity gap:
the review client did not bind every Table 2 field to the raw sequence results.
The retained table was correct, but a future column misbinding could have
serialized successfully.

The one permitted material repair reconstructed all sixteen Table 2 columns
inside the review validator and added explicit rounded gut, body, and
whole-system identities plus within-sequence carry-over checks. Mutation probes
then rejected changes in every Table 2 column. No other Critical or Important
finding emerged, and no further repair was justified.

## Post-Repair Validation Receipt

Fresh validation after the focused repair established:

```text
both scripts parse = pass
source-loaded no-write client = pass; Git status unchanged
guarded review-pack client = pass; Git status unchanged
exact output set, schemas, ordering, and regular-file checks = pass
independent CSV reconstruction = pass
CLI, symbolic-link, and undeclared-entry guards = pass
full suite = 1287 pass, 0 fail, 0 warn, 0 skip
renv synchronized = yes
git diff whitespace checks = pass
all twelve implementation paths ASCII = yes
fresh external R CMD build and install = pass
both clients against installed package = pass
R CMD check = not run; no protected package surface changed
frozen packet hashes = unchanged
HEAD, origin/main, and live remote main = 468576f11cf407dc6ce6fde3e855758c6e7d0504
implementation scope = exactly the declared twelve paths
protected package and test paths changed = none
index = empty
temporary build/check residue = none
```

Goal 011 remains uncommitted and unstaged pending independent final audit and
Barry's review. Publication remains unauthorized.

## Independent Final Audit

Independent final audit returned `ACCEPT_GOAL_011` with no remaining Critical
or Important finding. The auditor directly confirmed the frozen base and
hashes, exact twelve-path scope, empty index, protected surfaces, common
initialization, Goal 008 control identity, carried state, retained schemas and
arithmetic, repaired Table 2 validation, client guards, figure, documentation
boundary, and uncommitted publication state.

The accepted interpretation remains conditional on the fixed deterministic,
linear, lossless model, fixed schedules, `0.25 h^-1` gut release, common
balanced initial state, and exact carry-over. It does not establish
physiological recovery, compensation, viability, or robustness beyond this
declared sequence.

The orchestrator accepts Goal 011 for Barry's review. No further repair is
justified under the declared stopping rule. All work remains uncommitted and
unstaged, and publication remains unauthorized.
