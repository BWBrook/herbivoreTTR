# Decision 0010: Prescribed Intake Window Duration

Date: 2026-07-31

Status: accepted

## Context

Goal 008 established `ecological_activity_prescribed_balance` by prescribing
`0.020 kg DM h^-1`, equivalent to `200 kJ h^-1` at the fixed fixture density,
over the 16-hour activity window. Goal 009 then showed that the same rate is the
conditional synthetic ceiling threshold for that fixed 16-hour geometry.
Neither goal tested how the daily accounting changes when the number of
prescribed-intake hours changes.

The approved next question is therefore an evidence-only duration screen under
the unchanged periodic, linear, lossless system. It is not a production
opportunity mechanism, voluntary feeding model, generic duration effect, or
test of empirical intake capacity.

## Decision

Keep production code, interfaces, state, and schemas unchanged. In evidence
clients only, define `prescribed_intake_window_open` for four declared clock
geometries and construct ordinary prescribed intake schedules from it. An open
one-hour interval is fully used at the fixed prescribed rate of
`0.020 kg DM h^-1`, or `200 kJ h^-1`; a closed interval prescribes zero intake.
The formal evidence variable is therefore a prescribed intake window, not
unused access or an animal's opportunity to choose whether or how much to eat.

Hold maintenance at `100 kJ h^-1` for all 24 hours and routine activity at
`50 kJ h^-1` in hours `16:23` and `0:7`, with zero routine activity in hours
`8:15`. Hold food-energy density at `10000 kJ kg^-1 DM`, gut release at
`0.25 h^-1`, and the measurement protocol unchanged. Use exactly:

| Scenario | Open hours | Duration | Daily intake | Daily energy | Expected daily body change | Expected day 1 / day 2 close |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `prescribed_intake_window_24h` | `0:23` | 24 h d^-1 | 0.48 kg DM | 4800 kJ | +1600 kJ | 11600 / 13200 kJ |
| `prescribed_intake_window_16h` | `16:23`, `0:7` | 16 h d^-1 | 0.32 kg DM | 3200 kJ | 0 kJ | 10000 / 10000 kJ |
| `prescribed_intake_window_12h` | `16:21`, `2:7` | 12 h d^-1 | 0.24 kg DM | 2400 kJ | -800 kJ | 9200 / 8400 kJ |
| `prescribed_intake_window_8h` | `16:19`, `4:7` | 8 h d^-1 | 0.16 kg DM | 1600 kJ | -1600 kJ | 8400 / 6800 kJ |

The 16-, 12-, and 8-hour fixtures retain equal evening and morning arms while
progressively removing central-night prescribed-intake hours from within the
fixed activity window. The 24-hour comparator additionally opens the
activity-off interval `[08:00, 16:00)`. Duration therefore isolates the clean
daily accounting relation across these fixtures, while within-day gut and body
trajectories remain conditional on the declared clock placement.

## Expected And Observed Evidence Contract

For prescribed intake window duration `H`:

```text
daily prescribed energy(H) = 200 kJ h^-1 * H
daily expenditure = 24 * 100 + 16 * 50 = 3200 kJ
expected daily body-energy change(H) = 200 * H - 3200 kJ
neutrality threshold = 16 h d^-1
```

These equations supply the expected daily values. The observed evidence
contract requires the package daily results to reproduce changes of
`+1600, 0, -800, -1600 kJ` for `H = 24, 16, 12, 8`, respectively, with the
whole-kilojoule closes declared above and within the existing scale-aware
numerical tolerance. The retained evidence must also verify periodic-gut
convergence, two-day carry-over, finite non-negative stocks, exact schedules,
and the prescribed-intake/activity overlaps.

The complete 16-hour result must be exactly identical to the accepted Goal 008
`ecological_activity_prescribed_balance` result. For the 12-hour fixture, the
declared match to Goal 008 `ecological_activity_uncompensated` is limited to
daily intake, prescribed energy, maintenance, routine-activity expenditure,
body-energy change, status, and closing body reserve. Its hourly intake pattern,
periodic gut state, within-day trajectories, and complete result are not
identical. No Goal 008 oracle is declared for the 24- or 8-hour fixture.

## Consequences

Under the fixed rate and fixed expenditure schedule, daily prescribed input
increases linearly with the number of open prescribed-intake intervals and
balances daily expenditure at 16 hours. This is a daily accounting property of
the declared synthetic system, not evidence for a generic biological response
to prescribed intake window duration.

The 24-hour fixture is an operational arithmetic null, not a claim of literal
continuous feeding. The 16-hour fixture remains the accepted normal synthetic
ecological accounting reference. The restricted fixtures are evidence
comparators, not production configurations or inferred behaviors.

All prescribed-intake-window, overlap, threshold, comparison, and identity
fields remain confined to experiments and ignored review tables. They do not
enter package state, forcing records, result schemas, constructors, or
validators.

## Limits And Next Gate

The screen does not establish voluntary intake, appetite, behavioral use of an
opportunity, forage availability, gut capacity, a feasible or empirical intake
rate, an empirical feeding limit, biological equilibrium, viability, or
species realism. It does not separate duration from clock placement for
within-day trajectories and does not authorize a duration-by-rate surface,
redistribution, compensation, carry-over, or feedback.

Goal 011 remains unapproved. Goal 010 neither recommends nor implements a
production opportunity mechanism, and no later mechanism or empirical layer
begins without a separately approved goal.
