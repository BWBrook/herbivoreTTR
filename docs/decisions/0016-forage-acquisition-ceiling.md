# Decision 0016: Separate Appetite Target From Forage Acquisition

Date: 2026-08-08

Status: implemented for ecological review

## Context

Goal 015 supplied one canonical repeated-day appetite runner, but the appetite
controller's bounded output was still called realized intake. That name
implicitly assumed unlimited food: whenever the animal attempted to eat, the
environment supplied the requested amount. Habitat limitation cannot be
represented coherently until animal-side demand and environment-side
acquisition are distinct.

## Decision

Rename the pure controller boundary to `calculate_appetite_target()` and its
bounded outputs to `appetite_target_*`. The feeding-opportunity gate and
physiological maximum remain animal-side constraints on that target. No
compatibility alias is retained.

Add `new_forage_acquisition_ceiling_schedule()` as one explicit 24-hour record
of finite, non-negative acquisition-rate ceilings in kg DM h^-1. For every
hour:

```text
realized intake = min(appetite target, forage-acquisition ceiling)
```

Only realized intake is converted to available energy and added to the gut.
The ceiling is an exogenous rate, not a forage stock: it has no depletion,
renewal, biomass, plant process, spatial position, or encounter mechanism.

Require the ceiling schedule in `run_appetite_controlled_energy_days()`. The
same appetite reference, forage ceiling, and routine-activity schedules repeat
on every simulated day. The hourly ledger distinguishes target, ceiling,
binding status, and realized intake; the daily summary distinguishes target and
realized totals and counts binding hours.

## Observations

A non-binding ceiling of `0.025 kg DM h^-1`, equal to the existing
physiological maximum, reproduces the accepted Goal 013–015 trajectories. The
Goal 013 recovery still ends near `-2 kJ` body and `-1 kJ` combined deviation,
and all 27 Goal 014 scenarios retain their accepted recovery classifications.

In the matched binding case, the ceiling is `0.015 kg DM h^-1` during all 16
open feeding hours and zero while feeding is closed. Starting on the accepted
reference, the controller requests `0.359 kg DM` over the day but the
environment permits exactly `0.240 kg DM`, or `2400 kJ`. The ceiling binds in
all 16 feeding hours and the combined gut-plus-body system closes exactly
`800 kJ` below reference. Appetite therefore responds to the developing
deficit but cannot overcome the external acquisition limit.

## Interpretation

This is the minimal coupling boundary needed to ask habitat-limitation
questions without pretending that imposed intake is animal choice. It remains
diagnostically simple: the animal determines a target, the environment caps
acquisition, and the established stock-flow physiology records the consequence.

## Limits And Next Gate

The ceiling is deterministic, non-spatial, non-depleting, and repeated
identically each day. It does not identify whether limitation arises from
biomass, quality, accessibility, encounter rate, handling time, competition, or
behavior.

Goal 017 now implements the separately approved recurrence experiment while
holding limitation severity fixed. See Decision 0017 for the resulting
effective-recovery and depressed-cycle regimes. It remains non-spatial and uses
no plant state.

The retained no-write reproduction client is:

```text
```
