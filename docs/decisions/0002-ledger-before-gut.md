# Decision 0002: Ledger Before Gut

Date: 2026-07-16

Status: accepted

## Context

The first executable model layer needed to establish the meaning of an hourly
state transition and prove that body-energy accounting closes. Implementing
controlled food, gut storage, passage, and assimilation at the same time would
combine that accounting question with digestive stock-flow and delay.

## Decision

Implement the body-energy ledger first. For 24 fixed one-hour transitions,
prescribed energy that is already assimilated enters one physical reserve and
constant maintenance expenditure leaves it. Record every opening and closing
reserve, rate, one-hour amount, body-energy change, and accounting residual,
then derive the daily summary from the hourly ledger.

Keep `body_mass_ref_kg = 50` as experiment metadata only because no approved
equation depends on mass. Demonstrate exact neutral, deficit, and surplus
fixtures without introducing food or gut calculations.

## Why

- Every transition and daily outcome can be calculated independently.
- Hourly opening/closing continuity and accounting residuals can be tested
  without digestive storage or timing obscuring failures.
- Already-assimilated energy provides one explicit boundary at which a later
  gut/assimilation layer can connect.
- Direct maintenance in kJ h^-1 avoids silently choosing an allometric or
  empirical parameterization.

## Consequences

Goal 002 establishes arithmetic closure, accounting semantics, and functional
interfaces only. It does not establish empirical realism, a viable animal, an
ecological equilibrium, or an empirical claim about macropods. Its scenario
values are deterministic fixtures, not calibrated estimates.

Controlled food and a one-pool gut/assimilation stock-flow system become the
next separately discussed and approved, unimplemented layer. Activity, dynamic
body mass, and all later physiological and ecological layers remain after it.

## Stop Boundary

Stop after the reviewed hourly and daily body-energy ledgers and the three thin
demonstration scenarios. Do not add food mass or quality, gut state or capacity,
passage, digestion, assimilation calculations, activity, dynamic body mass,
calibration, or coupling under this decision.
