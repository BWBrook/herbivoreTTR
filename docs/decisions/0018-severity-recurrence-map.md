# Decision 0018: Severity-By-Recurrence Map

Date: 2026-08-08

Status: implemented for ecological review

## Context

Goal 017 showed that one fixed `800 kJ` forage-limitation event produced
effective recovery under 8-day recurrence and depressed cycles under 4- and
2-day recurrence. That result did not establish whether the regimes were robust
to event severity or peculiar to the selected `0.015 kg DM h^-1` ceiling.

## Decision

Retain every accepted animal, food-energy, activity, feeding-window, and
reference input. Cross recurrence every 8, 4, and 2 days with feeding-hour
forage ceilings of `0.0175`, `0.0150`, and `0.0125 kg DM h^-1`. Across 16
feeding hours and the fixed `10,000 kJ kg^-1 DM` energy density, these produce
exact daily event losses of `400`, `800`, and `1,200 kJ`.

All event treatments begin on day 1 and run for 48 days unless an existing
body-energy transition rejects a negative closing reserve. Such a scenario
stops at the rejected day and retains its last valid state. No parameter is
changed and no failed transition is bypassed.

Recovery and settling thresholds scale with event loss. Effective recovery
requires at least 90% restoration before every next event. An apparently
settling depressed cycle requires each of its final two complete cycles to
change net energy by no more than 1% of one event loss. A reserve-boundary
encounter is reported separately.

## Observations

All three central-severity trajectories reproduce Goal 017 exactly. Every
completed event realizes its declared ceiling, binds in all 16 feeding hours,
and removes exactly `400`, `800`, or `1,200 kJ`. State continuity and all energy
accounts remain exact.

The resulting map is:

| Event loss | Every 8 days | Every 4 days | Every 2 days |
|---:|---|---|---|
| `400 kJ` | effective recovery | depressed cycle | depressed cycle |
| `800 kJ` | effective recovery | depressed cycle | deep depressed cycle |
| `1,200 kJ` | effective recovery | depressed cycle | reserve boundary on day 47 |

At 8-day recurrence, final pre-event debt is approximately `3`, `6`, and
`9 kJ` for the mild, central, and strong events. The physiological maximum is
active for 0, 0, and 54 hourly transitions, respectively, but all treatments
restore more than 90% before the next event.

At 4-day recurrence, the stable pre-event debts are approximately `53`, `107`,
and `171 kJ`; corresponding post-event debts are `453`, `907`, and `1,371 kJ`.
The physiological maximum is active for 0, 22, and 141 hourly transitions over
48 days.

At 2-day recurrence, the mild event approaches a depressed cycle near `-361`
before and `-761 kJ` after each event without activating the physiological
maximum. The central event approaches the deeper Goal 017 cycle near `-1060`
and `-1860 kJ`, with the maximum active for 582 hourly transitions.

The strong 2-day treatment completes 46 days and rejects day 47. Its last
completed event, on day 45, moves combined deviation from approximately
`-8992` to `-10192 kJ`; the recovery day closes at `-9392 kJ` with `426 kJ` of
body reserve. The lowest completed closing body reserve is `80 kJ`.

## Interpretation

Recurrence controls the broad response regime, while severity controls debt
depth and compensatory-capacity engagement. The map is not a collection of
unexplained numerical outcomes: the existing energy constraints predict the
critical two-day pattern.

The reference system expends `3200 kJ d^-1`. On a non-limited day, the
physiological maximum permits at most `4000 kJ` ingestion, hence an `800 kJ`
maximum daily recovery surplus. Over a two-day cycle:

- the `400 kJ` event leaves `+400 kJ` of attainable cycle headroom, allowing a
  depressed equilibrium below maximum intake;
- the `800 kJ` event has zero headroom, so neutrality is approached only as the
  recovery day approaches maximum intake;
- the `1,200 kJ` event has an unavoidable `-400 kJ` cycle deficit even at
  maximum intake, so reserve depletion must continue within the present model.

This analytical margin explains why the strong treatment reaches the reserve
boundary rather than merely settling more deeply.

## Limits And Next Gate

This is a deterministic 3-by-3 synthetic map, not calibration or a general
sensitivity analysis. The event severities, recurrence intervals, appetite
gains, and physiological maximum are not empirical estimates. Reaching the
positive-reserve boundary means only that the current state transition cannot
continue; it is not a modeled death, starvation threshold, body-mass outcome,
or demographic conclusion.

Goal 019 remains unapproved. The appetite-forage coupling is now sufficiently
understood that the next discussion should choose one genuinely new layer,
rather than expanding this response surface. The leading candidates are an
explicit body-mass/reserve consequence or a static spatial forage environment;
either requires a separate scientific contract.

The retained no-write reproduction client is:

```text
experiments/rebuild-018-severity-recurrence-map.R
```

Generated tables and the diagnostic panel remain disposable under the ignored
Goal 018 output directory.
