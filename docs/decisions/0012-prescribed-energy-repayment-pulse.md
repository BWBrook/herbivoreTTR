# Decision 0012: Prescribed Energy-Repayment Pulse

Date: 2026-08-01

Status: accepted

## Context

Goal 011 showed that one lower-input day creates an exact `-800 kJ`
whole-system contrast. Resuming balanced prescribed forcing prevents further
debt but cannot replace that missing external input. The approved extension
asks a narrower accounting question: what happens when the next day's external
forcing supplies exactly the missing `800 kJ`?

This remains a finite, evidence-only sequence under the unchanged
deterministic, linear, lossless gut-body system. It does not ask whether an
animal can or would alter intake, and it does not add a repayment, response, or
recovery mechanism to the model.

## Decision

Construct the accepted balanced period-24 gut state once and pair it with a
`10000 kJ` body-energy reserve. Use those identical stocks to initialize both
four-day sequences, then carry the closing gut and body stocks exactly into
each subsequent day without another reset:

| Sequence | Day 1 | Day 2 | Day 3 | Day 4 |
| --- | --- | --- | --- | --- |
| `all_balanced_control` | balanced | balanced | balanced | balanced |
| `shortfall_then_repayment` | shortfall | prescribed repayment pulse | balanced | balanced |

All schedules prescribe zero intake in hours `8:15`. During hours `0:7` and
`16:23`, the control prescribes `0.020 kg DM h^-1` on every day. The treatment
prescribes `0.015 kg DM h^-1` on day 1, directly prescribes
`0.025 kg DM h^-1` on day 2, and prescribes `0.020 kg DM h^-1` on days 3 and 4.
At the fixed `10000 kJ kg^-1 DM` density, these treatment days supply
`2400, 4000, 3200, 3200 kJ`.

Both sequences retain maintenance of `100 kJ h^-1` for all 24 hours, routine
activity of `50 kJ h^-1` over the same 16 active hours and zero otherwise, and
gut release of `0.25 h^-1`.

The `0.025 kg DM h^-1` pulse is direct exogenous synthetic forcing. It is not
Goal 009's above-threshold result: that fixture clipped a
`0.020 kg DM h^-1` candidate against a non-binding `0.025 kg DM h^-1` ceiling,
so its realized prescription remained `0.020 kg DM h^-1`.

Implement the sequence only in evidence clients by chaining the existing
exported one-day runner. Add no production API, state, schema, parameter,
equation, validator, or test.

## Analytical And Observed Evidence

Every contrast uses:

```text
shortfall_then_repayment - all_balanced_control
```

The hourly prescribed-input contrast is `-50 kJ` in each of the 16 active
hours on day 1, `+50 kJ` in those hours on day 2, and zero otherwise. Because
maintenance and routine activity match between sequences, cumulative
prescribed input and the combined gut-plus-body contrast follow the same
boundary path:

```text
0 kJ at initialization
-800 kJ at 24 h
0 kJ at 48 h
0 kJ through 72 and 96 h
```

For gut-stock contrast `delta_G`, hourly input contrast `delta_I`, and release
fraction `r = 0.25 h^-1`:

```text
delta_G[t + 1] = (1 - r) * delta_G[t] + delta_I[t]
               = 0.75 * delta_G[t] + delta_I[t]
```

After hour 48, balanced forcing gives `delta_I[t] = 0`, so each subsequent
24-hour day multiplies the gut contrast by `0.75^24`. At every boundary:

```text
body-reserve contrast =
  cumulative prescribed-input contrast - gut-stock contrast
```

The retained boundary evidence records:

| Elapsed time | Gut contrast | Body contrast | Combined contrast |
| ---: | ---: | ---: | ---: |
| 24 h | -182 kJ | -618 kJ | -800 kJ |
| 48 h | +182 kJ | -182 kJ | 0 kJ |
| 72 h | +0.182 kJ | -0.182 kJ | 0 kJ |
| 96 h | +0.000183 kJ | -0.000183 kJ | 0 kJ |

The analytical fixtures retain unrounded values where needed for recurrence
and complement checks. The apparent whole-kilojoule values at 48 hours do not
mean that either stock is individually realigned: their contrasts are equal
and opposite. During days 3 and 4 those component contrasts contract by
`0.75^24` per day toward zero but do not become exactly zero in finite time.

## Consequences

An external pulse equal to the missing prescribed energy returns the
whole-system contrast to zero at 48 hours. Gut transit delays realignment of
the individual gut and body stocks, so whole-system equality and individual-
stock equality are separate properties.

`Prescribed repayment pulse` is an accounting label for imposed forcing. It is
not compensation, catch-up feeding, appetite, behavioral response,
demonstrated capacity, animal recovery, physiological recovery, or a realistic
ecological repayment mechanism. The evidence does not show that an organism
could realize the pulse.

The result is conditional on the declared schedules, common balanced periodic
initial state, fixed `0.25 h^-1` release fraction, exact carry-over, and the
current deterministic, linear, lossless accounting model. It establishes a
stock-partition identity under those assumptions, not a production-model or
biological-response claim.

The retained source-controlled reproduction client is:

```text
experiments/rebuild-012-prescribed-energy-repayment-pulse.R
```

All sequence, phase, boundary, contrast, recurrence, and complement fields are
evidence-only aliases.

## Limits And Next Gate

Goal 012 adds one deliberately fixed four-day sequence, not a configurable
horizon or generalized production sequence runner. It adds no endogenous
forcing, compensation process, appetite, intake capacity, behavioral feedback,
or recovery criterion.

At Goal 012 closeout, Goal 013 remained unapproved and scientifically
unspecified. Any later layer required a separately approved goal.
