# Decision 0017: Recurrent Forage Limitation

Date: 2026-08-08

Status: implemented for ecological review

## Context

Goal 016 separated animal-side appetite target from environmentally realized
intake and established one acquisition-limited day with an exact `800 kJ`
combined-system loss. A single event did not show whether the accepted appetite
controller could restore that loss before the same habitat limitation recurred.

## Decision

Retain the Goal 016 limited day unchanged: forage acquisition is capped at
`0.015 kg DM h^-1` during all 16 feeding hours. Retain the non-binding ceiling,
feeding windows, appetite gains and maximum, food energy density, gut release,
maintenance, routine activity, and period-24 reference unchanged.

Over a common 48-day horizon, compare an unlimited control, one isolated event,
and the limited day recurring every 8, 4, or 2 days. All event treatments share
the same limited day on day 1 and differ only in recurrence; the unlimited
control has none. The evidence client sequences one-day calls to the canonical
appetite runner with exact state carry-over; recurrence remains outside the
package API.

Effective inter-event recovery requires at least 90% of each `800 kJ` event
loss to be restored before the next event. A non-recovered treatment is called
an apparently settling depressed cycle only when each of its last two complete
cycles changes post-event debt by no more than `8 kJ`, or 1% of one event loss.
Otherwise, energy debt is described as still accumulating over the observed
horizon.

## Observations

The unlimited control remains on the reference, and the isolated event recovers
90% of its combined energy loss in four days before approaching zero. Every
limited day retains the exact Goal 016 result: `0.240 kg DM` realized, all 16
feeding hours acquisition-limited, and `-800 kJ` combined-system change.

With 8-day recurrence, the system effectively recovers between events. After
the transient first cycle, combined deviation is approximately `-6 kJ` before
and `-806 kJ` after each limited day. The physiological maximum is never active.

With 4-day recurrence, the trajectory settles into a shallow depressed cycle
at approximately `-107 kJ` before and `-907 kJ` after each event. Inter-event
recovery converges to `800 kJ`, but the 90% criterion is not met before every
event. The physiological maximum is active for 22 hourly transitions over the
48 days.

With 2-day recurrence, energy debt deepens substantially before approaching a
much lower cycle. By the final event, combined deviation is approximately
`-1060 kJ` before and `-1860 kJ` after limitation; the following recovery day
closes at `-1064 kJ`. Final complete-cycle recovery is approximately `796 kJ`,
or 99.6% of the event loss, leaving a further `4 kJ` deepening. The physiological
maximum is active for 582 hourly transitions, and maximum daily appetite target
approaches the 16-hour limit at `0.400 kg DM`.

All gut, body, and whole-system accounts close, state continuity is exact, and
body reserve remains positive throughout the declared horizon.

## Interpretation

Recurrence alone produces three interpretable synthetic regimes: effective
recovery, a shallow persistent debt cycle, and a much deeper capacity-limited
debt cycle. The severe treatment's cycle-to-cycle loss shrinks strongly rather
than remaining constant, so the 48-day evidence supports an approaching
depressed cycle, not unbounded decline.

This is a useful coupling result. A fixed environmental shortfall evokes a
larger appetite target as debt deepens, while the event-day acquisition ceiling
still fixes realized intake. Between events, the non-binding environment allows
compensatory intake until appetite feedback and the physiological maximum shape
the emerging cycle.

## Limits And Next Gate

The recurrence schedule is deterministic, severity is fixed, and the
classification thresholds are diagnostic conventions. Forty-eight days shows
finite-horizon approach, not an analytically proven equilibrium. Combined
energy debt is not body-mass loss, starvation, mortality, population decline,
or an empirical viability threshold.

Goal 018 now implements the separately approved small severity-by-recurrence
map. See Decision 0018 for the robust recurrence regimes and the resulting
capacity boundary. Vegetation and space remain outside both goals.

The retained no-write reproduction client is:

```text
```

Generated tables and the diagnostic panel remain disposable under the ignored
Goal 017 output directory.
