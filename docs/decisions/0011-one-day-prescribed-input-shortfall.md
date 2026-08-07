# Decision 0011: One-Day Prescribed-Input Shortfall

Date: 2026-07-31

Status: accepted

## Context

Goals 008 through 010 compare stationary fixtures constructed from their own
periodic gut references. Those results do not show what happens when prescribed
input changes for one day and then returns to the accepted balanced reference.

The approved question is therefore a finite, evidence-only forcing sequence
under the unchanged deterministic, linear, lossless system. It asks how one
prescribed-input shortfall is partitioned between the existing gut and body
stocks, not whether an animal undergoes biological or physiological recovery.

## Decision

Construct the accepted balanced period-24 gut state once and pair it with a
`10000 kJ` body-energy reserve. Use that identical gut and body state to start
both sequences, then carry both closing stocks exactly into each subsequent
day without another reset:

| Sequence | Day 1 | Day 2 | Day 3 |
| --- | --- | --- | --- |
| `all_balanced_control` | balanced | balanced | balanced |
| `one_day_rate_shortfall` | lower-rate shortfall | balanced | balanced |

Both schedules prescribe intake in hours `0:7` and `16:23`, close intake in
hours `8:15`, and prescribe routine activity of `50 kJ h^-1` over the same 16
non-rest intervals. At the fixed density of `10000 kJ kg^-1 DM`, balanced
forcing uses `0.020 kg DM h^-1` and supplies `0.32 kg DM` or `3200 kJ` per day.
The lower-rate day uses `0.015 kg DM h^-1` and supplies `0.24 kg DM` or
`2400 kJ`.

The lower-rate schedule is the accepted Goal 009 below-threshold prescription
and exactly the schedule used by Goal 008
`ecological_activity_uncompensated`. Goal 011 does not reuse that Goal 008
scenario's periodic result: its shortfall sequence begins from the balanced
periodic gut state, so its day-1 gut and body trajectories describe a forcing
transition rather than the lower-input schedule's stationary cycle.

Implement this only in evidence clients. Chain the existing exported one-day
runner for the three carried days; do not add a generalized production
multi-day API, state, equation, schema, or forcing mechanism.

## Analytical And Observed Evidence

Every contrast uses:

```text
one_day_rate_shortfall - all_balanced_control
```

The exact day-1 external prescribed-input contrast is:

```text
16 h * (0.015 - 0.020) kg DM h^-1 * 10000 kJ kg^-1 DM
  = -800 kJ
```

Maintenance and routine activity are identical between sequences. The
combined gut-plus-body contrast therefore reaches `-800 kJ` at the 24-hour
boundary and remains `-800 kJ` throughout the two return-to-reference days,
including the 48- and 72-hour boundaries. The retained hourly and daily
evidence confirms that invariant and exact within-sequence carry-over of both
stocks.

The first two control days are exactly identical to the accepted Goal 008
balanced hourly and daily result. Its third day retains the same periodic gut
boundary and approximately neutral body accounting within the existing
scale-aware numerical tolerance.

After balanced forcing resumes, the hourly input contrast is zero. With gut
release fraction `r = 0.25 h^-1`, the gut-stock contrast follows:

```text
delta_G[t + 1] = (1 - r) * delta_G[t]
               = 0.75 * delta_G[t]

daily gut-contrast contraction factor = 0.75^24
```

At each return-to-reference day boundary:

```text
body-reserve contrast = -800 kJ - gut-stock contrast
```

The evidence therefore records a fixed `-800 kJ` combined-system contrast
whose partition changes as the gut contrast contracts toward zero and the
body-reserve contrast approaches `-800 kJ`.

At the declared day boundaries, the observed treatment-minus-control
partition is:

| Elapsed time | Gut contrast | Body contrast | Combined contrast |
| ---: | ---: | ---: | ---: |
| 24 h | -182 kJ | -618 kJ | -800 kJ |
| 48 h | -0.182 kJ | approximately -800 kJ | -800 kJ |
| 72 h | -0.000183 kJ | approximately -800 kJ | -800 kJ |

The extra decimal precision is retained only for the small gut remainders.
The unrounded body value remains the exact complement to `-800 kJ`.
In whole kilojoules, the treatment body reserve closes at
`9382, 9200, 9200 kJ`. Its `-182 kJ` change on the first
return-to-reference day is matched by a `+182 kJ` gut-stock change, so it is a
change in partition rather than another combined-system loss.

## Consequences

Return-to-reference forcing stops any further external prescribed-input
difference between the two sequences; it does not replace the missing
`800 kJ`. The numerical gut-state contrast rapidly contracts because the
existing gut recurrence releases a fixed fraction of opening stock each hour.
That numerical realignment is neither body-energy restoration nor
whole-system restoration.

The result is conditional on the declared schedules, common balanced periodic
initial state, fixed `0.25 h^-1` release fraction, exact carry-over, and the
current deterministic, linear, lossless accounting model. It establishes a
stock-partition identity under those assumptions, not an animal response.

The retained source-controlled reproduction client is:

```text
experiments/rebuild-011-one-day-prescribed-input-shortfall.R
```

## Limits And Next Gate

Goal 011 adds a deliberately fixed three-day evidence sequence, not a
configurable horizon or production sequence runner. The labels
`return_to_reference` and return-to-reference forcing describe resumption of
the balanced prescribed schedule only.

At Goal 011 closeout, Goal 012 had not yet been approved and Goal 011 did not
select its scientific question, mechanism, duration, or evidence design.
