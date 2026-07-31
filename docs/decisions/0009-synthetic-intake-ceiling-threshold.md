# Decision 0009: Synthetic Intake-Ceiling Threshold

Date: 2026-07-30

Status: accepted

## Context

Goal 008 established `ecological_activity_prescribed_balance` as the normal
synthetic ecological accounting reference. It prescribes
`0.020 kg DM h^-1`, equivalent to `200 kJ h^-1` at the fixed fixture density,
over 16 active intervals. That fixture closes its body ledger approximately
neutrally, but Goal 008 did not test a finite intake ceiling or show that the
prescription is achievable.

The next bounded question was the synthetic hourly ceiling just sufficient to
admit that prescribed accounting balance. This remains an evidence question
under the accepted periodic, linear, lossless system, not a question about an
animal mechanism or realistic feeding behavior.

## Decision

Retain the production package unchanged. In evidence clients only, apply an
elementwise `pmin` prescription:

```text
constrained prescribed intake =
  min(candidate prescribed intake, synthetic hourly ceiling)

curtailed prescribed intake =
  candidate prescribed intake - constrained prescribed intake
```

The candidate is `0.020 kg DM h^-1` in hours `0:7` and `16:23` and zero in
hours `8:15`. The three active-hour ceilings are `0.015`, `0.020`, and
`0.025 kg DM h^-1`, with zero ceiling during the rest block.

Keep the evidence meanings distinct:

- `ceiling_exceeded` means candidate intake is strictly greater than the
  ceiling;
- exact touching means candidate and ceiling are equal and strictly positive;
- unused active-ceiling headroom is the active-interval sum of the positive
  difference between ceiling and constrained intake; and
- curtailment is discarded rather than redistributed, stored, carried, or
  compensated in another interval.

Rest intervals count as neither exceeded nor touching. These quantities
describe prescribed schedules and evidence arithmetic only. They do not add a
package constructor, resolver, variable, state, record, schema, or export.

## Observed Evidence

The declared daily requirement is `2400 kJ` maintenance plus `800 kJ` routine
activity. At `10000 kJ kg^-1 DM` over 16 active one-hour intervals, the exact
threshold is:

```text
3200 kJ / (16 h * 10000 kJ kg^-1 DM)
  = 0.020 kg DM h^-1
  = 200 kJ h^-1
```

The retained experiment and review pack verify:

- at `0.015 kg DM h^-1`, all 16 active intervals exceed the ceiling, none
  touches it, daily candidate/constrained/curtailed intake is
  `0.32 / 0.24 / 0.08 kg DM`, constrained input is `2400 kJ`, and observed
  body change is `-800 kJ` per measured day, closing at `9200` and `8400 kJ`;
- at `0.020 kg DM h^-1`, no interval exceeds the ceiling, all 16 active
  intervals touch it, daily constrained intake is `0.32 kg DM`, curtailed
  intake and unused headroom are zero, constrained input is `3200 kJ`, and
  body reserve closes at `10000 kJ` on both measured days; and
- at `0.025 kg DM h^-1`, no interval exceeds or touches the ceiling, daily
  constrained intake remains `0.32 kg DM`, daily curtailed intake is zero,
  unused active-ceiling headroom is `0.08 kg DM` or `800 kJ`, constrained
  input is `3200 kJ`, and body reserve again closes at `10000 kJ` on both
  measured days.

The below-threshold complete result is exactly identical in memory to Goal 008
`ecological_activity_uncompensated`. The at- and above-threshold complete
results are exactly identical to each other and to Goal 008
`ecological_activity_prescribed_balance`.

## Consequences

Under the declared fixture, `0.020 kg DM h^-1` is the accounting threshold at
which the synthetic ceiling first admits the neutral candidate prescription.
Below it, clipping produces the already accepted lower prescribed schedule.
At or above it, the candidate passes unchanged. A static evidence-only ceiling
therefore creates no downstream behavior beyond selecting a prescribed input
schedule already accepted by the package.

The result is conditional on the 16-hour opportunity convention, fixed density,
maintenance and routine activity, discarded curtailment, and unchanged
periodic, linear, lossless accounting. Changing those assumptions can change
the threshold.

## Limits And Next Gate

The threshold is not an empirical maximum, voluntary intake, appetite, feeding
choice, forage availability, gut capacity, intake redistribution, continuous
feeding claim, production API, or demonstrated achievable rate. The
above-threshold headroom and candidate-to-ceiling ratio are accounting
quantities, not physiological capacity use.

Goal 010 remains unapproved. A later decision may consider promoting a durable
ceiling, varying opportunity duration, or pausing for empirical evidence; Goal
009 does not choose or implement any of those directions.
