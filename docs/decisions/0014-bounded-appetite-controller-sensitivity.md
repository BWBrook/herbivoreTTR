# Decision 0014: Bounded Appetite-Controller Sensitivity

Date: 2026-08-08

Status: implemented for ecological review

## Context

Goal 013 established one stable shortfall-recovery trajectory under synthetic
body and gut feedback fractions. That single result did not show whether the
controller was structurally well behaved over nearby response speeds or larger
deficits, nor did it isolate the roles of the two feedback terms.

## Decision

Retain the Goal 013 controller equation, reference trajectory, feeding windows,
and `0.025 kg DM h^-1` maximum unchanged. Diagnose the full factorial
combination of:

- body feedback fractions `0.025`, `0.050`, and `0.100 h^-1`, corresponding to
  reciprocal timescales of 40, 20, and 10 hours;
- gut feedback fractions `0.050`, `0.100`, and `0.200 h^-1`, corresponding to
  reciprocal timescales of 20, 10, and 5 hours; and
- one-day deficits of `400`, `800`, and `1,600 kJ`.

Each shortfall is followed by 14 appetite-controlled days. A separate
`800 kJ` component comparison switches off neither, either, or both feedback
terms. This is a bounded sensitivity and attribution diagnostic, not
calibration or model selection.

A scenario is mechanically valid only when it preserves the exact reference,
respects feeding opportunity and intake bounds, and closes all energy accounts.
Stable recovery additionally requires no body-reserve overshoot, no deepening
daily body deficit, and removal of at least 90% of the combined deficit within
14 days.

## Observations

All 27 factorial scenarios are mechanically valid and meet the declared stable
recovery criterion. All nine gain pairs therefore remain stable across the
three tested deficits. No scenario produces body or combined-system overshoot,
and the lower intake bound is never active.

Recovery speed is controlled principally by body feedback. The 40-hour body
timescale requires 7 to 9 days to remove 90% of the deficit, the 20-hour
timescale requires 3 to 5 days, and the 10-hour timescale requires 2 to 3 days.
Within each body setting, faster gut feedback generally adds one or two days by
braking intake more strongly.

After 14 recovery days, the largest remaining combined deficit is `42 kJ`, or
2.6% of the original deficit, for the slowest body and fastest gut responses
after the `1,600 kJ` shortfall.

The maximum intake constraint is inactive in all `400 kJ` scenarios. It is
active in five of nine `800 kJ` scenarios for 22 hours in total, and eight of
nine `1,600 kJ` scenarios for 103 hours in total. Large-deficit and fast-body
responses therefore become partly capacity-limited rather than expressing the
unconstrained feedback equation alone.

The Goal 013 central setting, with 20-hour body and 10-hour gut timescales,
removes 90% of each tested deficit within four days. Its maximum daily intake
is `0.3414`, `0.3628`, and `0.3955 kg DM` after the `400`, `800`, and
`1,600 kJ` deficits. Only the largest deficit activates the maximum, for 11
hours. All three combined deviations round to `0 kJ` by the end of the 14-day
horizon.

In the `800 kJ` component comparison, no feedback replaces none of the deficit.
Gut feedback alone replaces 6.3%, leaving approximately `750 kJ` missing. Body
feedback alone and the integrated controller both approach complete recovery;
they cross 90% recovery in three and four days, respectively. First-day intake
is `0.3670 kg DM` under body feedback alone and `0.3628 kg DM` under the
integrated controller.

## Interpretation

The controller is qualitatively stable over this declared synthetic range and
does not rely on one finely tuned gain pair. The component comparison supports
the intended division of labour: body reserve supplies the persistent recovery
drive, while the gut signal moderates that drive as post-ingestive energy
accumulates. Gut feedback is therefore a brake, not an independent long-term
energy-deficit controller.

The central Goal 013 gains remain a useful working diagnostic reference. This
is an engineering-scientific convenience, not evidence that 20- and 10-hour
timescales describe a kangaroo or any other herbivore.

## Limits And Next Gate

The grid is deliberately small, deterministic, and local to one periodic
reference. The upper intake limit masks gain differences in many large-deficit
cases. `gut_available_energy_kj` remains an assimilable-energy stock rather
than physical fill, and none of the feedback fractions or deficit sizes are
empirically fitted.

The next layer remains unapproved. The highest-value architectural step is a
minimal canonical appetite-controlled repeated-day runner that reproduces the
accepted experiment trajectories without adding new ecology. That would make a
subsequent, separately approved repeated-shortfall or chronic-stress question
possible without continuing to build multi-day loops inside experiments.

The retained no-write reproduction client is:

```text
```

Generated review tables and the diagnostic panel remain disposable under the
ignored Goal 014 output directory.
