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

## 2026-07-26 - Execution Authorization And Baseline Reconciliation

Barry explicitly authorized Goal 004 execution after the packet was published.
The live execution state was verified as:

```text
branch = main
HEAD = 8645e05cc314551abaf167891912bcd607e19c36
origin/main = 8645e05cc314551abaf167891912bcd607e19c36
live remote main = 8645e05cc314551abaf167891912bcd607e19c36
status = clean
outputs = absent
```

The frozen runbook preflight names the earlier Goal 003 commit and the
then-untracked four-file packet state. Publishing the packet necessarily
advanced `HEAD` while changing no model source, tests, package metadata,
experiments, or model documentation. Direct comparison confirmed that:

```text
scientific content baseline = e2622ca739d89124e8cb8361fb40363363686d49
live execution HEAD = 8645e05cc314551abaf167891912bcd607e19c36
intervening paths = the four Goal 004 packet files only
```

Execution therefore uses `8645e05cc314551abaf167891912bcd607e19c36`
as the live Git and remote-state gate, while retaining
`e2622ca739d89124e8cb8361fb40363363686d49` as the scientific content baseline
for the declared 22-path Goal inventory. The three frozen control-document
hashes were independently reverified and remain unchanged. This reconciliation
does not broaden scientific scope or publication authority.

## 2026-07-26 - Test-First Implementation

The two input constructors and pure converter were implemented through
separate test-first phases:

```text
food records red = PASS 0, FAIL 8, WARN 0, SKIP 0
conversion red = PASS 0, FAIL 9, WARN 0, SKIP 0
```

Every red failure was attributable to its intentionally absent public
interface. No parse, package-load, dependency, warning, or unrelated regression
occurred.

The implementation added:

- one exact food-parameter record with a strictly positive, double-stored
  dry-matter-basis metabolizable-energy density;
- one exact 24-row prescribed dry-matter intake schedule with integer hours and
  double-stored non-negative rates; and
- one pure converter that validates constructor-retained records, multiplies
  intake by density elementwise, rejects non-finite products, and returns the
  unchanged Goal 003 available-energy schedule.

The converter adds no state, runner, dependency, tolerance, rounding, or file
write. It rejects hand-built integer-valued consumer records and nonstandard
container attributes even though the constructors accept bare integer inputs
and normalize them to doubles.

## 2026-07-26 - Analytical Clients And Documentation

Roxygen generated exactly three declared exports, three new function manuals,
and the refreshed package manual. No other generated path changed.

The no-write installed-package experiment asserted zero, constant, pulse, and
factorization fixtures in memory. Its compact summaries showed:

```text
zero = 0 kg DM and 0 kJ per day
constant = 0.24 kg DM and 2400 kJ per day
pulse = 0.04 kg DM and 400 kJ in hour 0
factorized alternative = 0.48 kg DM and 2400 kJ per day
pulse assimilation hours 0-3 = 0 / 100 / 75 / 56.25 kJ h^-1
```

Converted zero, constant, and pulse schedules were exactly identical to their
manually constructed Goal 003 schedules. The alternative factorization used
different prescribed intake and density but produced an identical schedule
and downstream result. The 0.24 kg DM accumulated total was compared with a
scale-aware floating-point tolerance; model objects were not rounded.

Human output displayed energy stocks and amounts as whole kilojoules while
retaining meaningful rate precision. The documentation states that the density
is already metabolizable, the conversion is an accounting equivalence rather
than digestive physiology, and intake and density are structurally
non-identifiable from downstream energy trajectories.

## 2026-07-26 - Validation And Parent Scope Gate

Fresh integrated validation produced:

```text
food records = PASS 67, FAIL 0, WARN 0, SKIP 0
conversion = PASS 60, FAIL 0, WARN 0, SKIP 0
full suite = PASS 626, FAIL 0, WARN 0, SKIP 0
renv status = synchronized
external R CMD build = OK
temporary-library R CMD INSTALL = OK
installed-package experiment = all analytical assertions passed
external R CMD check --no-manual = Status: OK
```

Dependency lookup printed unreachable Bioconductor-index warnings before the
check proceeded. These were environmental network messages, not package-check
findings: the completed `00check.log` contained `Status: OK`, no dependency
changed, and `renv` remained synchronized. Repeating the otherwise successful
check solely to remove network noise was not justified.

Parent review confirmed:

- exact equality to the declared 22-path scientific inventory relative to
  `e2622ca739d89124e8cb8361fb40363363686d49`;
- an empty Git index and clean tracked and untracked whitespace;
- unchanged frozen Goal, Plan, and Runbook hashes;
- unchanged Goal 001-003 packet files, body and gut source and tests, and
  `renv.lock`;
- no repository output, package tarball, check directory, or retained temporary
  validation directory; and
- local `HEAD`, `origin/main`, and live remote `main` still equal to
  `8645e05cc314551abaf167891912bcd607e19c36`.

## 2026-07-26 - Independent Final Acceptance

The independent final reviewer inspected the complete source, tests,
documentation, experiment, generated manuals, exact scope, frozen controls,
protected surfaces, and live Git state. It independently reproduced the two
focused contexts, full suite, and in-memory experiment.

The reviewer returned:

```text
verdict = ACCEPT
Critical findings = none
Important findings = none
focused repair justified = no
```

The reviewer accepted the root's external build, installation, installed
experiment, and package-check evidence without duplicating that expensive
validation. It confirmed that the Bioconductor messages were network lookup
warnings rather than package findings.

Goal 004 is accepted as implemented and validated. It remains uncommitted and
unpushed because execution authority did not include publication.

## 2026-07-26 - Core Implementation

The strict record constructors and pure conversion were developed test first.
The initial record red phase produced:

```text
records red: PASS 0 FAIL 8 WARN 0 SKIP 0
```

All failures were caused by the two absent declared constructors. Production
source then implemented:

```text
new_food_energy_parameters()
new_dry_matter_intake_schedule()
derive_ingested_available_energy_schedule()
```

An independent contract scout identified two material traps. The converter now
requires constructor-retained double storage and exact plain containers,
including canonical data-frame row names. A focused regression test first
failed only for the custom-row-name case:

```text
container red: PASS 59 FAIL 1 WARN 0 SKIP 0
```

The repaired converter rejects malformed parameter records, malformed
schedules, integer-valued hand-built consumer records, attributed containers,
and non-finite products including overflow. Constructors still accept bare
integer or double quantities and normalize the quantities to doubles.

The scout also identified that summing 24 binary floating-point
representations of `0.010` is not bitwise identical to literal `0.24`.
Aggregate dry-matter intake therefore uses a scale-aware numerical comparison.
Converted schedules and downstream Goal 003 results retain exact equality.

## 2026-07-26 - Documentation And Experiment

The completed documentation states that dry matter is prescribed ingestion,
not offered or wet forage, and that density is already metabolizable on a
dry-matter basis. The product is the accounting equivalent entering the
existing gut available-energy pool. No digestion, efficiency, dry-matter gut
stock, variable food quality, feeding decision, state, or runner was added.

The no-write experiment passed zero, constant, pulse, and factorization
fixtures in memory. Its compact output reported:

```text
constant = 0.24 kg DM d^-1 and 2400 kJ d^-1
pulse input = 400 kJ in hour 0
pulse release h0-h3 = 0, 100, 75, 56.25 kJ h^-1
factorized and constant schedules identical = TRUE
factorized and constant downstream results identical = TRUE
```

Human-facing energy stocks and amounts were displayed as whole kilojoules.
Model objects retained full double precision.

## 2026-07-26 - Integrated Validation

Roxygen generated only the declared exports and manual pages. Structured test
results were:

```text
records: PASS 67 FAIL 0 WARN 0 SKIP 0
conversion: PASS 60 FAIL 0 WARN 0 SKIP 0
full: PASS 626 FAIL 0 WARN 0 SKIP 0
published Goal 003 floor: PASS 499
```

The source-package experiment passed. `renv::status()` reported a synchronized
project without changing `renv.lock`.

A guarded external validation built the source package, installed it into a
temporary library, passed the installed-package experiment, and completed:

```text
R CMD check --no-manual
Status: OK
```

The command wrapper yielded while this healthy check continued, which made its
temporary directory appear retained and caused one inadvertent duplicate
external check to start. Both checks subsequently completed successfully and
both guarded temporary roots were removed. The first run is the canonical
external-validation result. No repository package tarball, check directory,
output directory, or other generated product remains.

Integrity checks confirmed:

```text
declared scientific-baseline inventory = 22 paths exactly
live-HEAD implementation inventory = 19 paths exactly
Git index = empty
outputs = absent
Goal, Plan, and Runbook hashes = unchanged
Goal 002 and Goal 003 source and tests = unchanged
renv.lock = unchanged
HEAD = 8645e05cc314551abaf167891912bcd607e19c36
origin/main = 8645e05cc314551abaf167891912bcd607e19c36
live remote main = 8645e05cc314551abaf167891912bcd607e19c36
```

The 19-path live inventory differs from the 22-path scientific inventory only
because the frozen `Goal.md`, `Plan.md`, and `Runbook.md` were already published
at the live execution baseline. Nothing is staged, committed, or pushed by
Goal 004 execution.

## 2026-07-26 - Independent Final Review

An independent read-only reviewer inspected all 19 live changed or untracked
paths and accepted Goal 004:

```text
verdict = ACCEPT
Critical findings = 0
Important findings = 0
repair pass justified = no
```

The reviewer independently reproduced:

```text
records: PASS 67 FAIL 0 WARN 0 SKIP 0
conversion: PASS 60 FAIL 0 WARN 0 SKIP 0
full: PASS 626 FAIL 0 WARN 0 SKIP 0
source-loaded experiment = passed
```

It also verified the exact 22-path scientific inventory, exact 19-path live
inventory, frozen hashes, synchronized `renv`, unchanged protected Goal 002 and
Goal 003 surfaces, empty index, clean whitespace, absent repository artifacts,
and unchanged local and remote baseline.

The reviewer did not rerun external package validation because its mandate
explicitly excluded that duplicate expense. The successful external
build/install/installed-experiment/check evidence above remains the canonical
record. No further review or repair is scientifically or operationally
justified.
