# Decision 0008: Ecological Activity And Intake Balance

Date: 2026-07-30

Status: accepted

## Context

Goal 006 established `ecological_day_resting` as a synthetic ecological
prescribed-intake reference with no routine activity. Goal 007 then added a
separate prescribed routine-activity expenditure input without changing gut
dynamics. The next bounded question was whether those accepted interfaces could
separate the body-energy effect of a night-spanning activity schedule from the
effect of an explicitly higher prescribed intake.

This is an evidence-only question under the existing periodic, linear,
lossless, unlimited accounting system. It is not a question about feeding
behavior, achievable intake, adaptive compensation, or empirical physiology.

## Decision

Retain the permanent `mathematical_continuous` fixture as the arithmetic,
convergence, accounting, and regression diagnostic. Retain
`ecological_day_resting` as the zero-activity ecological comparator. Use
`ecological_activity_prescribed_balance` as the normal synthetic ecological
accounting reference for later discussion, with
`ecological_activity_uncompensated` as its activity-only counterfactual.

All three ecological scenarios prescribe intake during hours `0:7` and
`16:23`, and close intake during hours `8:15`. The two activity scenarios
prescribe activity over the same 16 non-rest intervals and zero activity during
the eight-hour rest block.

The exact scenarios are:

```text
ecological_day_resting
  active intake = 0.015 kg DM h^-1 = 150 kJ h^-1
  active routine activity = 0 kJ h^-1
  daily dry matter / gut input / activity = 0.24 kg DM / 2400 kJ / 0 kJ

ecological_activity_uncompensated
  active intake = 0.015 kg DM h^-1 = 150 kJ h^-1
  active routine activity = 50 kJ h^-1
  daily dry matter / gut input / activity = 0.24 kg DM / 2400 kJ / 800 kJ

ecological_activity_prescribed_balance
  active intake = 0.020 kg DM h^-1 = 200 kJ h^-1
  active routine activity = 50 kJ h^-1
  daily dry matter / gut input / activity = 0.32 kg DM / 3200 kJ / 800 kJ
```

The fixtures compose the existing public constructors and
`run_gut_body_energy_reference_cycle()` directly. Goal 008 changes no package
function, equation, transition order, API, record, schema, validator,
dependency, or caller.

## Observed Evidence

The retained no-write experiment verifies the following numerical
observations:

- all three gut cycles first converge on burn-in day 7;
- daily prescribed input, assimilation, and routine activity are respectively
  `2400 / 2400 / 0 kJ`, `2400 / 2400 / 800 kJ`, and
  `3200 / 3200 / 800 kJ`;
- observed daily body-energy change is approximately `0 kJ`, `-800 kJ`, and
  `0 kJ` for the baseline, uncompensated, and prescribed-balance scenarios;
- body reserve closes measured days 1 and 2 at approximately
  `10000 / 10000 kJ`, `9200 / 8400 kJ`, and `10000 / 10000 kJ`,
  respectively;
- the baseline and uncompensated convergence and gut ledgers match exactly in
  memory;
- the balanced gut-boundary and assimilation paths follow the predicted `4/3`
  scaling, with a maximum in-memory absolute deviation of approximately
  `1.14e-13 kJ`; and
- the baseline-minus-uncompensated body-reserve contrasts at
  `0, 8, 16, 24, 32, 40, 48 h` are exactly
  `0, 400, 400, 800, 1200, 1200, 1600 kJ`.

These are observations from synthetic fixtures under the current model
contract. The exact baseline/uncompensated gut match identifies the imposed
activity effect independently of gut dynamics. The verified `4/3` scaling is
the expected consequence of multiplying prescribed gut input by `4/3` in the
unchanged linear gut recurrence.

## Consequences

The balanced fixture provides a useful normal reference because its prescribed
daily input of `3200 kJ` equals the current `2400 kJ` maintenance amount plus
the prescribed `800 kJ` activity amount, and the measured body ledger closes
approximately neutrally. This is an accounting interpretation, not evidence of
a biological equilibrium.

The zero-activity ecological comparator remains necessary to isolate the
activity effect. The mathematical continuous fixture remains necessary for
simple arithmetic and regression diagnosis. Equal daily closes do not make the
baseline and balanced fixtures equivalent: their within-day gut,
assimilation, net body-rate, and body-reserve trajectories differ.

No variable-dictionary update is required because Goal 008 adds no variable,
field, record, or schema. The retained source-controlled reproduction client is:

```text
```

## Limits And Next Gate

The balanced rate of `200 kJ h^-1` and its daily equivalent of
`0.32 kg DM d^-1` are externally prescribed. Goal 008 does not show that an
animal can ingest that amount within the stated intervals. Prescribed balance
is not behavior, voluntary or adaptive compensation, biological equilibrium,
viability, an empirical maintenance or activity estimate, or empirical
physiology.

Goal 009 remains a discussion and approval gate for finite feeding opportunity
or intake limits. Goal 008 neither designs nor authorizes that layer.
