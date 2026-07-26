# Rebuild Goal 002 Log

## 2026-07-16 - Scientific Direction

After completing the clean repository rebuild, Barry and the Herbivore TTR
orchestrator agreed that the first executable layer must be simpler than the
future controlled-food and gut core recorded by Rebuild Goal 001.

Barry explicitly approved a minimal hourly body-energy ledger that stops before
the gut. The accepted purpose is to prove direct energy arithmetic, 24-hour
transition semantics, functional separation, and neutral/deficit/surplus
diagnostics before digestive storage or delay is introduced.

The implementation target is one fixed-mass, semi-synthetic 50 kg
macropod-like scenario. Prescribed already-assimilated energy enters directly;
fixed maintenance expenditure leaves directly. Activity remains excluded in
accordance with the existing roadmap. The 50 kg mass is scenario metadata, not
a dead transition parameter or an implicit allometric calculation.

Neutrality in this goal means only that prescribed daily energy input equals
maintenance expenditure and the modeled reserve is unchanged. It is not a
claim of empirical realism, physiological health, ecological equilibrium, or
long-term viability.

## 2026-07-16 - Formulation Preflight

Read-only inspection before packet creation confirmed:

```text
repository = /Users/bwbrook/git/herbivoreTTR
branch = main
HEAD = ca2c9711f8e81831180a1c4875de44f84f964498
origin/main = ca2c9711f8e81831180a1c4875de44f84f964498
status = clean
origin = git@github.com:BWBrook/herbivoreTTR.git
```

The foundation documents were internally consistent but treated the food, gut,
and reserve as one future first layer. Goal 002 therefore predeclares narrow
documentation changes that split that layer into:

1. the maintenance-only body-energy ledger implemented here; and
2. a later, separately approved controlled-food and gut stock-flow layer.

## 2026-07-16 - Formulation State

Created only:

```text
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Goal.md
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Plan.md
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Runbook.md
docs/goals/rebuild-002-minimal-hourly-energy-ledger/Log.md
```

No R source, package metadata, test, documentation outside this packet,
experiment, dependency, output, branch, staging, commit, push, or physiological
implementation was created or changed during formulation.

At formulation closeout, execution had not started and was not authorized.

## 2026-07-16 - Formulation Review

Independent scientific-contract review initially identified ambiguity in the
negative-reserve boundary and hourly transition return schema. These were
resolved by requiring every proposed reserve below zero to fail without
tolerance or clipping, declaring the exact input-row and nested return
structures, and making the status thresholds explicit. Final scientific review
accepted the packet with no Critical or Important findings.

Independent operational review identified false-pass risks in packet identity,
untracked-file review, red-test interpretation, experiment side effects,
legacy-read authority, and pre-publish Git gates. The packet now freezes its
three control documents by externally approved SHA-256 values, reviews complete
tracked and untracked content, requires interpretable red failures, defines
in-memory assertions plus stdout as the experiment boundary, forbids legacy
inspection, and rechecks both remote URLs and remote state before Git writes.
Final operational review accepted the packet.

Root review confirmed exactly the four packet files are untracked, with no
other working-tree change, placeholder marker, trailing whitespace, or line
over 100 characters. No R command, test, package check, implementation, Git
mutation, or legacy inspection was performed during formulation.

## 2026-07-16 - Authorization Identities

Any execution authorization applies only to these exact control-document
identities:

```text
Goal.md     862f2c0df704cc9553e6dfe9d535d9a5df9be9e3003698b9e0f2c9eebf617f71
Plan.md     7650dc44d72a054188cf36f575e174de73712730004722c01d82dee956638789
Runbook.md  a15fe2768f9d1354a0f69caf0e20bbf76c7befb4b83ef0b5ede0ffb55a49ab21
```

`Goal.md`, `Plan.md`, and `Runbook.md` are frozen during execution. `Log.md`
may receive execution evidence without changing the authorized scientific or
operational contract.

## 2026-07-16 - Execution Authorization And Preflight

Barry explicitly authorized Goal 002 execution without commit or push. The
preflight confirmed `main`, local `HEAD`, `origin/main`, and live remote `main`
at `ca2c9711f8e81831180a1c4875de44f84f964498`; the fetch and push URLs both
matched `git@github.com:BWBrook/herbivoreTTR.git`; the working tree contained
only the four formulation files; and all three frozen control-document hashes
matched the authorized values.

## 2026-07-16 - Test-First Implementation

Three test files were created before production source. All parsed. The focused
red phase was reproduced independently and failed only because the declared
public functions were absent:

```text
records     FAIL 9  WARN 0  SKIP 0
transition  FAIL 7  WARN 0  SKIP 0
scenarios   FAIL 9  WARN 0  SKIP 0
```

The implementation then added strict plain-record constructors, one pure
hourly transition, and one 24-transition daily runner. Post-roxygen focused
tests passed:

```text
records     PASS 64  FAIL 0  WARN 0  SKIP 0
transition  PASS 49  FAIL 0  WARN 0  SKIP 0
scenarios   PASS 85  FAIL 0  WARN 0  SKIP 0
```

Roxygen initially added its version metadata to `DESCRIPTION` and skipped the
pre-existing manually generated package help file. Execution stopped at that
boundary. Integration retained the roxygen version as explicit package
metadata, removed the stale help file, regenerated all declared help from
source, and reran roxygen. A before-and-after SHA-256 check then confirmed
roxygen no longer altered `DESCRIPTION`.

## 2026-07-16 - Integration Validation

Root validation produced:

```text
full test suite = PASS 208, FAIL 0, WARN 0, SKIP 0
renv status = synchronized
external R CMD build = OK
temporary-library R CMD INSTALL = OK
installed-package experiment = three exact expected rows
external R CMD check --no-manual = Status: OK
changed-path whitelist = exact
tracked and untracked whitespace checks = clean
persistent outputs, root tarballs, root check directories = absent
renv.lock change = absent
```

The installed-package experiment reported:

```text
neutral  50  neutral    0  5000
deficit  50  deficit -240  4760
surplus  50  surplus  240  5240
```

Execution remains uncommitted and unstaged pending independent scientific and
code/diff review. Food, gut, digestion, assimilation calculation, activity,
dynamic mass, calibration, and coupling remain unimplemented.

## 2026-07-16 - Final Review Repair

Independent scientific review accepted the implemented contract. Independent
code review then rejected three exact-record and numerical-boundary defects:

1. matrices, classed numerics, attributed values, and pairlists could pass
   validators intended for bare numeric vectors and ordinary named lists;
2. accepted integer energy values were not normalized to double and could
   overflow unnecessarily; and
3. individually finite hourly rates could overflow daily totals and trigger an
   internal R condition instead of a model error.

Regression tests were written first. Their red phase reproduced all three
defects without unrelated warnings, skips, or setup failures. The subsequent
fix requires exact plain-list containers, bare integer or double constructor
inputs, normalized double energy storage, exact schedule column types, and
explicit finite guards for daily derived quantities and accounting tolerance.

Post-fix focused validation produced:

```text
records     PASS 77  FAIL 0  WARN 0  SKIP 0
transition  PASS 61  FAIL 0  WARN 0  SKIP 0
scenarios   PASS 91  FAIL 0  WARN 0  SKIP 0
```

The full suite then passed 239 expectations with no failure, warning, or skip.
`renv` remained synchronized. Roxygen changed no package metadata. A fresh
temporary external build, installation, installed-package experiment, and
`R CMD check --no-manual` again completed with `Status: OK`; the experiment
retained the exact three expected rows. No persistent product remained in the
repository.

The repaired implementation now awaits independent re-review. It remains
uncommitted and unstaged.

## 2026-07-16 - Final Acceptance

Independent scientific re-review confirmed that the representation and
finite-arithmetic safeguards do not alter the approved equations,
interpretation, or stop-before-gut scope. Independent code/diff re-review found
no unresolved or newly introduced Critical or Important issue. Both reviewers
accepted the repaired implementation.

Final parent gates reconfirmed the three frozen control-document hashes, exact
26-path whitelist, empty index, clean tracked and untracked whitespace checks,
unchanged `renv.lock`, absent persistent products, unchanged local and remote
baseline `ca2c9711f8e81831180a1c4875de44f84f964498`, and expected fetch and push
URLs.

Goal 002 is accepted as implemented and locally validated. It remains
uncommitted and unpushed because execution authority did not include
publication. The next model layer remains a discussion, not an authorization.

## 2026-07-26 - Scientific Closeout And Publication Authorization

Barry and the Herbivore TTR orchestrator reviewed the compact diagnostic
figures and tables generated outside the repository. Constant neutral, deficit,
and surplus inputs produced the expected linear reserve trajectories. Reversing
the within-day timing of equal total prescribed input changed the transient
reserve trajectory but not the daily endpoint. This was interpreted as
within-day timing sensitivity, not endpoint path dependence or biological
realism.

Barry accepted Goal 002 as having served its intended purpose: the minimal
hourly transition, direct energy arithmetic, and accounting foundation behave
as expected. Discussion then approved a separately bounded Goal 003 design for
a one-pool gut-energy buffer.

Immediately before publication, fresh validation produced:

```text
records = PASS 77, FAIL 0, WARN 0, SKIP 0
transition = PASS 61, FAIL 0, WARN 0, SKIP 0
scenarios = PASS 91, FAIL 0, WARN 0, SKIP 0
full suite = PASS 239, FAIL 0, WARN 0, SKIP 0
renv status = synchronized
external R CMD build = OK
temporary-library R CMD INSTALL = OK
installed-package experiment = three exact expected rows
external R CMD check --no-manual = Status: OK
changed-path whitelist = exact
tracked and untracked whitespace checks = clean
persistent outputs, root tarballs, root check directories = absent
```

An independent final pre-publication review inspected the complete 26-path
tracked-and-untracked footprint and returned `ACCEPT`, with no Critical or
Important defect, unsupported scientific claim, or scope breach. Barry
explicitly authorized commit and push of Goal 002. Goal 003 formulation may
follow only from the resulting published baseline; its implementation and
publication remain separately gated.
