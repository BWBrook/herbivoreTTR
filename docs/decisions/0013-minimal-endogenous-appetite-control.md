# Decision 0013: Minimal Endogenous Appetite Control

Date: 2026-08-08

Status: implemented for ecological review

## Context

Goals 011 and 012 separated two accounting facts. Returning to balanced
prescribed forcing after a one-day shortfall prevents further whole-system loss
but cannot replace the missing `800 kJ`; an externally prescribed
`0.025 kg DM h^-1` pulse can replace it but says nothing about appetite. The
next approved question is whether a minimal state-dependent intake controller
can preserve the balanced reference and respond coherently to that shortfall.

## Decision

Add one pure hourly controller with three fixed parameters and one 24-hour
reference schedule. For current opening body energy `B`, gut energy `G`, and
hour-matched reference states `B_ref` and `G_ref`:

```text
body_deviation_kj = B - B_ref
gut_deviation_kj  = G - G_ref

unconstrained_energy_kj_h =
  reference_energy_kj_h
  - body_feedback_fraction_h * body_deviation_kj
  - gut_feedback_fraction_h  * gut_deviation_kj
```

Convert the unconstrained energy rate to dry matter using the existing fixed
metabolizable-energy density. During an open feeding opportunity, bound it to
zero and the declared maximum intake rate; during a closed opportunity,
realized intake is zero. The signed equation lets either state increase intake
when below reference and suppress intake when above reference.

The first diagnostic retains the accepted reference intake of
`0.020 kg DM h^-1` during hours `0:7` and `16:23`, the `8:15` closure, and the
synthetic maximum of `0.025 kg DM h^-1`. It sets the body and gut feedback
fractions to `0.05 h^-1` and `0.10 h^-1`, respectively. These correspond to
transparent 20-hour and 10-hour response timescales; they are not fitted or
empirically inferred physiological values.

Expose only:

- `new_appetite_control_parameters()`;
- `new_appetite_reference_schedule()`; and
- `calculate_appetite_controlled_intake()`.

Keep `run_gut_body_energy_day()` as the prescribed-input control. The fixed
Goal 013 experiment composes the new controller with the existing public gut
and body transitions. Do not add a generalized appetite-controlled or
multi-day production runner in this goal.

## Observations

At every hour of the exact balanced period-24 trajectory, both state deviations
and both feedback contributions are exactly zero. Realized dry-matter and
available-energy rates, gut stocks, and body reserves are identical to the
accepted prescribed reference.

The treatment begins with the established `0.015 kg DM h^-1` shortfall day,
creating closing gut, body, and combined-system deviations that round to
`-182`, `-618`, and `-800 kJ`. With the controller active on days 2 through 10,
daily realized dry-matter intake is:

```text
0.3628, 0.3386, 0.3293, 0.3247, 0.3223,
0.3212, 0.3206, 0.3203, 0.3201 kg DM
```

The corresponding closing body deviations round to:

```text
-439, -220, -110, -55, -28, -14, -7, -3, -2 kJ
```

The body reserve remains below reference and approaches it monotonically. The
combined-system deviation approaches zero from below and is approximately
`-1 kJ` at day 10. No recovery hour reaches either intake-rate bound, and all
closed hours retain exactly zero realized intake.

In the isolated open-hour probe, adding `200 kJ` to gut energy while holding
body energy at reference produces zero body feedback, `-20 kJ h^-1` gut
feedback, and a realized rate of `180 kJ h^-1` or `0.018 kg DM h^-1`. Combining
that gut state with a `500 kJ` body deficit adds `+25 kJ h^-1` body feedback,
giving a net rate of `205 kJ h^-1`.

All experiment assertions and gut, body, and combined-system accounting checks
pass. Presentation tables round kJ quantities to whole numbers; calculations
retain full numeric precision.

## Interpretation

The compressed controller supplies the intended qualitative division of
labour. Body-energy deviation provides a slow persistent drive after the
shortfall. Gut-energy deviation responds more rapidly and changes sign as the
gut moves from depleted to above-reference during catch-up feeding, braking the
body signal without causing body-reserve overshoot.

This establishes a stable semi-synthetic homeostatic mechanism under one
declared perturbation. It does not establish that the chosen gains, maximum
rate, reference trajectory, or recovery time are realistic for a kangaroo or
other herbivore.

## Limits And Next Gate

`gut_available_energy_kj` is an assimilable-energy stock, not rumen or stomach
volume, dry-matter fill, or a measured satiation signal. Its use here is a
post-ingestive satiation proxy. The controller also uses an hour-specific
periodic reference, not endocrine states, explicit meals, learning, food
choice, forage encounter, or plant limitation.

The next layer remains unapproved. Ecological review should decide whether the
highest-value next goal is a bounded sensitivity test of the controller gains
and perturbation size, promotion into a canonical repeated-day runner, or a
different physiological increment.

The retained no-write reproduction client is:

```text
experiments/rebuild-013-minimal-endogenous-appetite-control.R
```

Generated review tables and the diagnostic panel remain disposable under the
ignored Goal 013 output directory.
