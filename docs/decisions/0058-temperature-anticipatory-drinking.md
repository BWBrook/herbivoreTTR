# Decision 0058: Temperature And Anticipatory Drinking

Date: 2026-09-05

Status: accepted environmental interface and completed policy comparison;
anticipation retained as a fallible comparator, not a general improvement

## Question And Contract

Can recent physiological experience improve the energetic cost of maintaining
hydration without granting the animal future environmental knowledge?

Barry approved one autonomous tranche, including review and publication. The
comparison was frozen before treatment results. Package physiology and its
parameters remain unchanged. Temperature enters only through an experiment-
level incremental evaporative-loss function:

```text
temperature_c = 30 + 6*cos(2*pi*(hour_of_day - peak_hour)/24)
extra_water_loss_kg_h = slope_kg_h_c * max(temperature_c - 30, 0)
```

The slope is fixed once at approximately `0.00965 kg h^-1 C^-1`, giving
`0.44 kg` per canonical warm day. It is not recalibrated across treatments.
The synthetic cycle spans `24-36 C`; the zero-extra-loss reference is `30 C`.
This is a controlled temperature-response approximation, not a calibrated
thermal physiology or heat-balance model. Loss is action independent. Moving
at a cooler hour therefore provides no direct thermal saving in this tranche.

Both systems share the accepted gut, appetite, activity, body energy and water,
feeding opportunity, route costs, and source capacity. The isolated system has
adequate non-depleting forage. The coupled system retains the accepted renewing
food patches, local herbivory, and experienced-adequacy food-choice rule.

## Information And Execution

The reactive operational null is unchanged: observe the `26 kg` thirst
threshold, take the earliest feasible three-hour out/drink/return trip, allow
at most one trip per day, and defer a crossing too late to complete it. Thirst
already present at midnight retains the established 08:00 departure convention.
Each movement leg costs `900 kJ`. Fixed feeding opportunity remains hours
`0:7` and `16:23`; this is not an explicit sleep model.

The candidate adds one decision at 08:00. It takes the mean physiological
non-drinking draw over the last 24 completed rolling hours:

```text
physiological_draw_kg = ordinary_loss_kg + extra_loss_kg - food_water_kg
projected_water_kg = current_water_kg - 25*max(0, mean_recent_draw_kg_h)
```

If projected water is below `26 kg`, depart at 08:00 today; otherwise retain
reactive fallback. The 25-hour horizon reaches next morning's source arrival
at 09:00, including the outward travel hour, not the end of its drinking
interval. Drinking and overflow are excluded from the remembered draw. Memory
is seeded solely by realized shared preconditioning and contains no forcing
calendar, future forage state, or simulated counterfactual. Access to exact
historical physiological components is itself a synthetic information
assumption, not an established sensory mechanism.

This scalar predicts an endpoint, not a within-day trough or threshold-crossing
time. It tests the complete precautionary 08:00 rule, not separate effects of
memory, the preferred clock hour, or anticipation in general.

The new experiment composes existing public hourly transitions on actual state.
The previous diagnostic's full hypothetical no-trip day remains historical
comparison code, but is not used here: its later invalid state must not prevent
an earlier feasible intervention. The hourly composition reproduces prescribed
day runners and the 60-day reactive baseline in both systems. Food memory still
counts only stationary open opportunities in food patches.

## Frozen Experiment

Each system receives one common 60-day zero-extra-loss reactive precondition,
then branches into 84 treatment days and 42 recovery days. Primary histories:

1. Zero extra loss throughout.
2. Repeated warm days peaking at 14:00.
3. The same integrated dose shifted to a 20:00 peak.
4. An unannounced 14:00-to-20:00 shift after treatment day 42.

Onset and recovery are also unannounced. The secondary one-factor sensitivity
uses coupled midday and phase-shift histories: slope multipliers `0.5` and
`1.5` for both policies, and memory windows `12` and `48 h` for anticipation.
Matching primary reactive controls are reused. There are 28 unique branches;
all started from their system's identical complete preconditioned state.
There was no post-result policy or parameter rescue tuning.

## Results

The primary coupled comparisons below use the last hour both policies actually
completed. Body-energy advantage is anticipation minus reactive. Failed proposed
transitions are not applied, and partial days remain visible in hourly output.

| History | Common hours | Body-energy advantage | Reactive / anticipatory trip starts | Failed transition, reactive / anticipatory |
| --- | ---: | ---: | ---: | --- |
| Zero extra loss | 3,024 | -281 kJ | 19 / 19 | none / none |
| Midday peak | 1,458 | -8,264 kJ | 21 / 25 | day 73, 15:00 / day 61, 18:00 |
| Evening peak | 1,810 | +4,273 kJ | 26 / 26 | day 76, 10:00 / day 79, 14:00 |
| Phase shift | 1,640 | -1,541 kJ | 23 / 26 | day 70, 18:00 / day 69, 08:00 |

All primary hourly boundary water minima exceed `25.6 kg`. All terminals are
rejected negative-energy transitions, not critical dehydration or inferred
mortality. None of the three warm primary coupled pairs reaches recovery, so
they do not establish recovery performance or a general long-run policy rank.
Treatment day numbers here exclude the 60-day precondition.

At the common midpoint horizon, anticipation starts four additional trips.
Its completed round trips obtain `1.87 kg` per refill against `2.31 kg` for
reactive trips. Added intake is only `186 kJ` against `8,100 kJ` extra realized
movement, leaving combined gut-plus-body energy `7,914 kJ` lower. The remaining
body-only difference is gut storage. One reactive return leg is still pending
at this common horizon, accounting for `900 kJ` of the observed movement
difference; no future cost is silently charged.

Evening anticipation has the same number of trip starts and displaces zero
feeding opportunities versus `26 h` reactively. Added intake is `5,173 kJ`,
against `900 kJ` extra realized movement because one reactive return is pending
at the endpoint. Combined energy is therefore `4,273 kJ` higher. This delays,
but does not eliminate, the energy boundary. Under the phase shift, `3,859 kJ`
extra intake cannot repay `5,400 kJ` extra travel.

All eight primary isolated branches complete 126 days. They can compensate
much more of the travel cost through intake, but anticipation is not uniformly
benign there either. Midday anticipation ultimately displaces `50 h` of feeding
opportunity versus `8 h` reactively: its subsequent reactive fallback trips
shift timing. The shifted-history candidate ends `1,366 kJ` below reactive.
The policy therefore cannot be described simply as moving trips out of feeding.

The sensitivity results are likewise conditional:

- At half slope, midpoint anticipation completes all 126 days whereas reactive
  fails at day 88, 00:00; its common-hour body reserve is `4,284 kJ` higher.
  Under the half-slope phase shift both complete, but anticipation ends
  `3,080 kJ` lower.
- At 1.5 times slope, both policies fail at day 27, 21:00. The two histories
  have not yet diverged, so their identical result says nothing about response
  to the later phase shift.
- The 12-hour estimate never triggers anticipation in these cases and exactly
  reproduces reactive trajectories. Estimated draw is sometimes positive,
  but the projected stock stays above the trigger. The 48-hour estimate gives
  the same primary action and state trajectories as 24 hours.

## Interpretation And Decision

Recent experience permits genuinely causal anticipation, but early hydration
top-ups have a fixed-cost trade-off: smaller refills can require more expensive
trips. Their subsequent effects on thirst timing, feeding, and food-patch state
mean that benefits depend on phase and demand. Equal cumulative water loss does
not imply equivalent energetic consequences. These are observed synthetic
policy contrasts; extrapolation to real animal behavior remains an inference.

Accept the temperature interface and completed experiment. Retain the reactive
null and the explicitly fallible anticipatory comparator; do not silently
replace the default with the candidate. Its mixed performance is an answered
scientific question, not a reason for open-ended tuning within this goal.

The highest-value next tranche is cost-aware source-trip timing: evaluate a
causal, bounded deferral/anticipation rule that accounts for refill size and
feeding opportunity, against both existing comparators. Keep physics and
environmental histories fixed, define its information and safety boundaries
before implementation, and test benefits and failure limits as one complete
comparison. This is a proposal, not authority to start Goal 059.

## Verification And Evidence

The retained no-write client is `experiments/temperature-anticipatory-drinking.R`.
It checks matched prescribed paths, zero forcing, equal-dose phase shifts,
baseline reduction, future-blind action prefixes, the 25-hour forecast,
feasible early intervention despite a later impossible no-trip day, stock
carry, trip semantics, and independent energy/water/forage conservation.
Predicted policy benefit is deliberately not an acceptance assertion.

The paired mechanism table closes combined-energy differences as additional
intake minus additional movement at a common completed horizon. Mean refill is
computed from completed round trips only; in-progress trips are separately
counted and all their realized costs remain in the energy comparison.

Generated hourly results, summary CSV, figures, and validation logs remain
ignored under `outputs/goal-058/`. Source and this compact decision record are
retained in Git. Independent scientific/code review found no blocking issue
and confirmed the conditional-policy interpretation.

Release checks passed: all retained R parsed, full testthat suite, all 27
diagnostics (the new comparison plus 26 previous clients), external package
build, and `R CMD check --no-manual` with no errors, warnings, or notes.
After the reporting-only completed-trip correction, cached hourly evidence and
common-horizon summaries were rechecked without rerunning unchanged physics.

## Deliberate Deferrals

Heat balance, humidity, radiation, body temperature, activity-dependent water
loss, thermal movement costs, renal response, feeding/sleep rescheduling,
dynamic plant moisture, multiple sources, empirical calibration, mortality,
and population viability remain outside this tranche.
