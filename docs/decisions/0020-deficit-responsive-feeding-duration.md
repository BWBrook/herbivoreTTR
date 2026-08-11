# Decision 0020: Deficit-Responsive Feeding Duration

Date: 2026-08-09

Status: accepted as evidence; not promoted into production

## Context

The accepted appetite controller changes intake rate within a fixed 16-hour
feeding opportunity. Goal 020 asks whether opening body-energy deficit can also
control how long the synthetic animal feeds, without changing that controller,
the forage-acquisition rate, or any dynamic state.

## Decision

Retain the once-daily duration rule as a coherent evidence-only mechanism:

```text
opening body deficit = max(0, 40,000 - opening body reserve)
extension pairs = min(2, floor(opening body deficit / 300))
```

The first pair opens hours 08:00-09:00 and 15:00-16:00; the second opens
09:00-10:00 and 14:00-15:00. Each pair therefore adds two feeding hours while
preserving the central 10:00-14:00 rest block. Added hours retain the accepted
`0.020 kg DM h^-1` reference rate, `0.025 kg DM h^-1` physiological maximum and
non-limiting acquisition ceiling, and cost `50 kJ h^-1` in routine activity.
The schedule is selected once at day opening.

Keep this rule inside the Goal 020 experiment. Do not yet promote it to a
package scheduler or interpret its `300 kJ` threshold as an empirical trait.

## Verification And Observations

At the exact reference state the rule adds no hours and reproduces the accepted
trajectory exactly. After the common `800 kJ` shortfall, the opening body stock
is `618 kJ` below reference because the remaining deficit is held in the gut.
The enabled animal therefore recruits both pairs on recovery day 1 and none on
days 2-9.

The four added hours increase day-1 realized intake from approximately `0.363`
to `0.421 kg DM` and add exactly `200 kJ` of routine-activity expenditure. The
combined energy deviation closes at approximately `-372 kJ` under fixed
duration and `+7 kJ` under the duration response. Ninety-percent recovery is
reached on day 1 rather than day 4. Neither the appetite bounds nor the
forage-acquisition ceiling bind. Gut, body, and whole-system accounting close,
state carry-over is exact, and the fixed-duration arm exactly reproduces Goal
013.

The enabled trajectory crosses the reference by less than `7 kJ` combined and
less than `2 kJ` in body reserve before converging to effectively zero. This is
negligible relative to the `40,000 kJ` reserve and triggers no further extension;
it is reported rather than tuned away.

## Interpretation

Opening body deficit can act as a slow signal for feeding duration while the
existing body-plus-gut controller retains fast within-hour appetite and
satiation feedback. The discrete rule accelerates recovery without persistent
extra feeding or numerical pathology in this isolated diagnostic. It does not
show that real herbivores use these thresholds or hours.

## Limits And Stop Boundary

This is one deterministic shortfall at one synthetic parameterization. There
is no threshold sensitivity screen, recurrence treatment, stochasticity,
sleep physiology, movement, forage depletion, spatial choice, dynamic
vegetation, empirical calibration, or generalized day scheduler. Feeding
duration changes alone; acquisition-rate response remains unimplemented.

The retained no-write client is:

```text
```

Generated evidence remains disposable under the ignored Goal 020 output
directory. Any production promotion or acquisition-rate response requires a
separate approved goal.
