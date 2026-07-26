# Decision 0004: Dry-Matter Metabolizable-Energy Bridge

Date: 2026-07-26

Status: accepted

## Context

Goal 003 accepts a prescribed available-energy schedule directly into the
one-pool gut buffer. The next bounded question was whether that input could be
expressed in ecological food units without changing the accepted gut-body model
or implying digestive mechanisms that are not implemented.

Dry-matter mass and energy density require an explicit interpretation. Offered
or wet forage would require availability, water content, selection, and realized
intake processes. Gross or digestible energy followed by an efficiency would
require an explicit loss boundary. Neither process belongs in this goal.

## Decision

Represent food upstream of the existing gut schedule with:

- one exact fixed-parameter record containing the strictly positive
  `metabolizable_energy_density_kj_kg_dm`; and
- one exact 24-row schedule containing `hour_of_day` and the non-negative
  `prescribed_dry_matter_intake_kg_dm_h`.

Dry matter is prescribed ingestion in kg DM h^-1, not food offered, vegetation
availability, wet or as-fed mass, or modeled foraging behavior. The density is
already metabolizable energy in kJ kg^-1 DM and is constant within a daily run.
It collapses every unmodelled step between dry matter and model-available
energy; no digestive loss or efficiency is applied.

Use one pure converter:

```text
prescribed_ingested_available_energy_kj_h =
  prescribed_dry_matter_intake_kg_dm_h *
  metabolizable_energy_density_kj_kg_dm
```

The product is the accounting equivalent entering the existing
`gut_available_energy_kj` pool. The converter returns the exact accepted Goal
003 schedule and does not advance state or call the gut-body runner. The caller
retains the parameter record, dry-matter schedule, converted energy schedule,
and downstream result as separate inspectable objects.

Inputs and converted rates remain doubles with no rounding in model objects.
Human-facing energy stocks and amounts are normally displayed as whole
kilojoules; rates retain decimals when they convey temporal structure.

## Rejected Alternatives

- Extending the Goal 003 schedule with dry-matter and density columns was
  rejected because it would change an accepted public schema and mix prescribed
  mass with derived energy.
- Adding a food-gut-body runner was rejected because it would only convert and
  forward existing objects while hiding the intermediate schedule behind a
  redundant public entry point.
- Adding a dry-matter gut stock was rejected because one fixed density makes it
  algebraically redundant with the energy stock and would introduce unsupported
  initial-mass and mass-flow semantics.
- Adding gross energy, digestibility, assimilation efficiency, or explicit
  losses was rejected for this goal because each would introduce a digestive
  mechanism rather than a controlled accounting bridge.

## Consequences

Goal 003 timing, state, transitions, runner, ledgers, and accounting remain
unchanged. Goal 004 adds no dynamic state and no feedback from gut or body state
to prescribed intake.

Downstream dynamics depend only on the product of intake and density. Scaling
one by a positive constant and the other by its reciprocal produces the same
energy schedule and downstream trajectory. Intake and density are therefore
structurally non-identifiable from this model's energy outputs. This is an
accounting equivalence, not evidence that different foods or feeding regimes
are biologically interchangeable.

The fixed densities and intake schedules used in demonstrations are synthetic
arithmetic fixtures, not food measurements, macropod intake estimates, or
calibrated biological parameters.

## Stop Boundary

Stop after strict food records, the pure conversion, exact analytical fixtures,
and unchanged downstream composition are documented and tested. Do not add wet
or offered forage, variable food quality, multiple foods, digestive loss or
efficiency, dry-matter gut state, capacity, feeding decisions, plants, empirical
calibration, or a new runner under this decision.
