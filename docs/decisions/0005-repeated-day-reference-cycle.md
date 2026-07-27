# Decision 0005: Repeated-Day Reference Cycle

Date: 2026-07-27

Status: accepted

## Context

The accepted one-day gut-body runner begins from caller-supplied stocks. An
empty arbitrary gut opening therefore contains a one-off initialization
transient that can obscure the response to a daily schedule. The next bounded
question was whether identical 24-hour forcing produces a repeatable gut cycle
and, separately, whether energy-matched schedules maintain body energy after
that transient is removed.

A repeatable gut trajectory and a neutral body-energy balance are not the same
property. A stable gut cycle can coexist with sustained body-energy deficit or
surplus. The diagnostic must therefore establish gut periodicity independently
of body energetics.

## Decision

Add one pure temporal orchestrator,
`run_gut_body_energy_reference_cycle()`, over the unchanged Goal 003 schedule
and transitions. It:

1. repeats one identical 24-row available-energy schedule;
2. advances only the gut during numerical burn-in;
3. compares hour-matched gut boundary stocks on successive days;
4. resets body energy once to the supplied measurement state;
5. calls the unchanged one-day gut-body runner twice; and
6. carries both closing states from measured day 1 into measured day 2.

Burn-in retains 25 gut stocks per day: the opening stocks for hours 0 through
23 and the closing stock after hour 23. Define:

```text
cycle_boundary_change_kj =
  current_boundary_stocks_kj[25] -
  current_boundary_stocks_kj[1]
```

From burn-in day 2 onward, convergence requires both the maximum absolute
hour-matched difference from the previous day's 25-stock trajectory and the
absolute cycle-boundary change to be no greater than the realized scale-aware
tolerance. The first day cannot be declared converged. Non-finite arithmetic
and failure to converge within the declared maximum raise errors without a
partial result.

The body reset is a diagnostic measurement protocol, not a state transition or
physiological process. Burn-in creates no body history, and the body is not
reset between measured days.

## Numerical Interpretation

`gut_convergence_relative_tolerance` is dimensionless and strictly between zero
and one. The reference fixtures use `100 * .Machine$double.eps`; this addresses
floating-point representation only. It does not encode observation error,
biological variation, parameter confidence, viability, or an acceptable
energetic deficit.

Measured periodicity is checked directly by reconstructing the 25 gut
boundaries for each measured day and comparing day 2 with day 1 using the final
realized cycle tolerance. Energetic neutrality is checked separately from
numeric body-energy change using the cycle, gut-ledger, and body-ledger
tolerances. The categorical `body_energy_status` is not convergence or
neutrality evidence because its reserve-scaled accounting tolerance answers a
different question.

## Synthetic Reference Fixtures

All fixtures start burn-in from 0 kJ gut energy, reset measurement body reserve
once to 10000 kJ, use release 0.25 h^-1, maintenance 100 kJ h^-1, food density
10000 kJ kg^-1 DM, relative tolerance `100 * .Machine$double.eps`, and a
100-day burn-in limit.

- Zero intake has a repeatable zero gut cycle and loses 2400 kJ of body reserve
  per measured day.
- Constant intake prescribes 0.010 kg DM h^-1 in all hours.
- Concentrated late feeding prescribes 0.040 kg DM h^-1 in hours 18 through 23
  and zero earlier.

The constant and concentrated schedules each contain 0.24 kg DM and 2400 kJ
per day. Their daily prescribed ingestion and maintenance are exactly equal.
Timing equivalence compares only total assimilation, observed gut change, and
observed body change using the sums of the corresponding scenario-specific
tolerances. It does not compare phase-specific gut or body stocks, absolute
system-energy levels, or status labels. Their within-day trajectories must
differ, and every measured body stock must remain finite and non-negative
before the equivalence is interpreted.

This equivalence is conditional on the current unlimited, linear gut stock,
lossless one-for-one transfer, identical daily forcing, and feasible body paths.
It is an accounting result, not evidence that real foods or feeding schedules
are biologically interchangeable.

## Review Evidence

The no-write experiment asserts the three fixtures in memory and uses compact
whole-kilojoule display for human-facing stocks and amounts while retaining
full precision internally.

The separate base-R review script accepts exactly one output-directory argument
and may replace only:

```text
figure-1-burn-in-convergence.png
figure-2-measured-reference-cycles.png
table-1-convergence.csv
table-2-daily-summary.csv
table-3-hourly-ledgers.csv
```

It stops before publishing if the destination contains any other entry.
Convergence, daily, and hourly tables prepend `scenario_id` to their exact
runner schemas and retain round-trippable numeric precision. Human rounding is
restricted to console and figure presentation. The measured figure derives a
continuous 0-48 hour clock; the convergence figure distinguishes unavailable
first-day comparisons from exact zero differences.

## Rejected Alternatives

- Advancing the body during burn-in was rejected because it would retain the
  arbitrary initialization debt and confound gut-cycle construction with body
  energetics.
- Resetting the body every day was rejected because it would destroy measured
  state carry-over.
- A fixed discard period was rejected because convergence rate depends on the
  release fraction and forcing.
- A configurable measurement horizon or generalized multi-day engine was
  rejected because two measured days answer the diagnostic question.
- `body_energy_status` was rejected as neutrality evidence because it is a
  categorical accounting diagnostic with a different tolerance.

## Consequences And Stop Boundary

Goal 005 adds temporal orchestration and recorded diagnostics only. It changes
no state record, transition equation, one-day schema, food conversion, release
order, maintenance process, or body-reserve boundary.

Stop after the repeated identical-day gut reference, one body reset, two
carried measured days, three synthetic fixtures, documentation, and five
ignored review files are validated. Do not add variable or stochastic days,
seasons, chronic decline, recovery, viability criteria, gut capacity, intake
limits, digestive losses, multiple compartments or foods, feeding choice,
body-state feedback, dynamic mass, other physiology, plants, weather, space,
individuals, populations, empirical calibration, parameter estimation,
uncertainty analysis, a dependency, or a generalized simulation framework.
