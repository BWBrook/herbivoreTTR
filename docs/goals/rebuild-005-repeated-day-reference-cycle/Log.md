# Rebuild Goal 005 Log

## 2026-07-26 - Formulation

Goal 004 was revalidated, committed as
`bca9c035a873f0db68a5f70be6e28439ceb2680b`, and pushed to `origin/main`.
Local `main`, `origin/main`, and the live remote `main` matched, with a clean
worktree, before Goal 005 formulation began.

Barry and the Herbivore TTR orchestrator agreed that Goal 005 will:

- repeat one identical 24-hour schedule;
- converge the gut numerically without advancing body energy;
- reset body energy once before measurement;
- record two measured days with exact state carry-over;
- compare zero, constant, and energy-matched concentrated feeding;
- separate gut-cycle stability from body-energy neutrality; and
- stop before any new physiological or ecological mechanism.

The late six-hour feeding window was selected as a synthetic day-boundary
diagnostic. In the current linear, lossless model, feeding timing may alter
within-day trajectories but must not alter steady-cycle daily totals.

Packet formulation created only:

```text
docs/goals/rebuild-005-repeated-day-reference-cycle/Goal.md
docs/goals/rebuild-005-repeated-day-reference-cycle/Plan.md
docs/goals/rebuild-005-repeated-day-reference-cycle/Runbook.md
docs/goals/rebuild-005-repeated-day-reference-cycle/Log.md
```

No Goal 005 implementation, generated output, staging, commit, or push was
authorized. Packet review and Barry's approval remain pending.

The formulation review accepted the packet after one focused repair pass.
Frozen control-document hashes are:

```text
Goal.md = f29893aa02c5f2573533181ed71d1c142318a9d07b794392ee431f02f1c600cc
Plan.md = 8e6bc295bd218aea922e2425abdca5c34aec6800034dc0375c5b89811319cd18
Runbook.md = 13a3aeefe9af63a3eb77030954921ef39c48955557ac35452ae5fe66751b07b3
```

## 2026-07-27 - Approval And Packet Publication Gate

Barry approved the Goal 005 design and authorized the recommended next action:
publish the four-file packet, then execute the goal.

Before publication:

```text
branch = main
HEAD = bca9c035a873f0db68a5f70be6e28439ceb2680b
origin/main = bca9c035a873f0db68a5f70be6e28439ceb2680b
worktree = exactly the four untracked Goal 005 packet files
index = empty
Goal, Plan, and Runbook hashes = approved values above
```

No implementation file or generated output existed at this gate.

The packet was committed as
`14a1e20b937d336b6f9bca962d1beb66f35dfa29` and pushed to `origin/main`.
Local `main`, `origin/main`, and the live remote `main` matched that commit with
a clean worktree.

## 2026-07-27 - Execution Preflight

Goal 005 execution began from:

```text
branch = main
execution baseline = 14a1e20b937d336b6f9bca962d1beb66f35dfa29
origin/main = 14a1e20b937d336b6f9bca962d1beb66f35dfa29
live remote main = 14a1e20b937d336b6f9bca962d1beb66f35dfa29
worktree = clean
index = empty
outputs = absent
Goal, Plan, and Runbook hashes = approved values
```

Execution was divided into non-overlapping core and documentation/diagnostic
lanes. Existing Goal 001-004 source and tests remain protected.

### Evidence Clarifications

A bounded read-only science-contract check identified three implementation
clarifications that remain within the approved goal:

- define `cycle_boundary_change_kj` exactly as the current day's closing gut
  boundary minus its opening gut boundary;
- independently reconstruct all 25 gut boundaries in tests, including the
  measured day-1 versus day-2 comparison; and
- preserve full numeric precision and explicit `scenario_id` keys in review
  tables, with continuous derived time from 0 to 48 hours in figures.

The timing-equivalence estimand is restricted to prescribed ingestion,
maintenance, total assimilation, observed gut change, and observed body change.
It explicitly excludes phase-specific gut and body stocks, absolute
whole-system stock levels, and categorical `body_energy_status`.

## 2026-07-27 - Core And Documentation Lanes

The focused core test file was created before production source. Its red phase
reported:

```text
reference-cycle red: PASS 0 FAIL 8 WARN 0 SKIP 0
```

All eight failures were the absent
`run_gut_body_energy_reference_cycle()` interface. There was no parse, package
load, dependency, warning, skip, or unrelated failure.

The new temporal runner then passed its focused context:

```text
reference-cycle green: PASS 78 FAIL 0 WARN 0 SKIP 0
```

The focused tests independently replay burn-in, reconstruct all 25 boundaries,
recalculate convergence scales and tolerances, verify measured day-to-day
periodicity, reduce both measured days to direct Goal 003 calls, and exercise
purity, non-convergence, overflow, and body-boundary failures.

The documentation and diagnostic lane updated only its declared ten paths. All
three owned R files parsed, `DESCRIPTION` was readable, and whitespace checks
were clean. Runtime experiments, generated tables and figures, roxygen output,
the full suite, and external package validation remained for parent
integration.

## 2026-07-27 - Integration And External Validation

Roxygen regenerated the declared export and package documentation. Integrated
validation then reported:

```text
focused Goal 005 tests = PASS 78 FAIL 0 WARN 0 SKIP 0
full test suite = PASS 704 FAIL 0 WARN 0 SKIP 0
renv status = synchronized
git diff --check = clean
renv.lock = unchanged
```

The first guarded external run built and installed the source package and
passed the installed no-write experiment, but the review script stopped before
publication when an exact CSV round-trip assertion exposed an R 4.6.1 decimal
parser edge case. The temporary check tree was removed and no partial review
pack was retained.

The bounded repair keeps ordinary readable decimal encodings when they
round-trip bit-exactly and uses R's hexadecimal numeric notation only for the
few values its decimal parser cannot recover exactly. Every exported table
then read back identically. This changed review serialization only; it did not
change model arithmetic, fixtures, tolerances, or conclusions.

After that material repair, the full guarded external ladder passed:

```text
R CMD build = passed
temporary R CMD INSTALL = passed
installed no-write experiment = passed
installed review-pack generation = passed
R CMD check --no-manual = Status: OK
guarded temporary directory cleanup = passed
```

The retained ignored review pack contains exactly the five declared files:

```text
figure-1-burn-in-convergence.png
figure-2-measured-reference-cycles.png
table-1-convergence.csv
table-2-daily-summary.csv
table-3-hourly-ledgers.csv
```

The three tables contain 16 convergence rows, 6 daily rows, and 144 hourly
rows. An independent read-back from those CSVs reproduced the convergence,
cycle repetition, exact carry-over, body-path feasibility, zero-intake
deficit, energy neutrality, and timing-equivalence checks.

Initial figure inspection confirmed legibility, scenario identity, units, and
the explicit 24-hour boundary, but did not detect that Figure 1 displayed only
one of the two convergence criteria and used no point marker for the
zero-intake tolerance. The independent final review identified and corrected
that evidence claim below.

The no-write console report presents stock and daily energy amounts as whole
kilojoules, while retaining additional precision only for rates and numerical
convergence diagnostics.

## 2026-07-27 - Independent Review And Focused Repair

The independent final reviewer found no production-code, API, numerical,
accounting, scientific-method, or scope defect. It rejected the first
acceptance candidate for two evidence defects:

- the exact zero, constant, and concentrated fixture outcomes were asserted in
  the no-write experiment but not protected by focused regression tests; and
- Figure 1 showed the successive-day trajectory difference but omitted the
  absolute cycle-boundary change and did not visibly mark the single
  zero-intake tolerance.

Barry's renewed Goal 005 execution go-ahead authorized a narrow repair. No
production source, public interface, equation, parameter, fixture, tolerance,
CSV schema, or scientific conclusion changed.

The focused test file now independently constructs all three declared fixtures
and recalculates tolerances from raw ledgers. It protects burn-in replay, the
single body reset, exact state carry-over, direct one-day reduction,
zero-intake deficit, neutral energy cycles, feasible body paths, timing
equivalence, and distinct within-day trajectories.

Figure 1 now identifies and marks:

- the successive-day 25-boundary maximum;
- the absolute within-day cycle-boundary change; and
- the realized convergence tolerance.

Exact zeros use disclosed open markers at the panel-specific log floor. The
tolerance has point markers, so the zero-intake day-2 threshold is visible.
Figure 2 and all three CSV files remained byte-identical during this repair.

Post-repair validation reported:

```text
focused Goal 005 tests = PASS 186 FAIL 0 WARN 0 SKIP 0
full test suite = PASS 812 FAIL 0 WARN 0 SKIP 0 ERROR 0
source no-write experiment = passed
review-pack generation = passed; exact five-file set
R CMD build = passed
temporary R CMD INSTALL = passed
installed no-write experiment = passed
installed review-pack generation = passed
R CMD check --no-manual = Status: OK
guarded temporary directory cleanup = passed
```

The repaired Figure 1 was reinspected at its native dimensions. Both
convergence criteria and the threshold are legible in all three panels, day-1
unavailability is explicit, and exact-zero proxies are honestly disclosed.

The same independent reviewer then performed a targeted read-only re-review,
reran the focused tests, and accepted Goal 005 with no remaining Critical or
Important finding. It confirmed the exact authorized path set, unchanged
protected Goal 001-004 source and tests, unchanged `renv.lock`, frozen packet
hashes, empty index, ignored five-file review pack, and absence of retained
build or temporary-check artifacts.

Goal 005 is complete for Barry-facing discussion. Its residual risk is the
declared synthetic, deterministic, linear, unlimited, and lossless model
boundary, not an unresolved implementation or evidence defect.
