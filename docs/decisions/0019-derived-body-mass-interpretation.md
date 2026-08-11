# Decision 0019: Derived Body-Mass Interpretation

Date: 2026-08-09

Status: implemented for ecological review

## Context

The body-energy reserve was physically named but had no mass interpretation.
Its `10,000 kJ` reference value was inherited from an arithmetic demonstration
and caused the strongest Goal 018 treatment to hit the non-negative reserve
boundary before the diagnostic horizon ended. Barry judged the implied reserve
to be too small for the first synthetic animal and preferred an interpretable
5% labile-reserve reference without yet adding mass feedback.

## Decision

Use a synthetic 40 kg reference animal consisting of:

- 38 kg fixed structural body mass;
- 2 kg labile reserve tissue; and
- an effective reserve-tissue energy density of `20,000 kJ kg^-1`.

The corresponding reference body-energy reserve is `40,000 kJ`. Body energy
remains the only dynamic stock. Derive, but do not store or feed back:

```text
reserve_tissue_mass_kg = body_energy_reserve_kj / 20,000

total_body_mass_kg = 38 + reserve_tissue_mass_kg
```

Expose one plain parameter record and one pure vectorized converter. Change the
current appetite-reference chain from Goal 013 onward to `40,000 kJ`; retain
Goals 002-012 as their original historical arithmetic fixtures.

## Verification And Observations

A paired Goal 013 recovery and strong Goal 018 recurrence run shifts both
actual and reference body energy by exactly `30,000 kJ`. Every relative
appetite, realized-intake, gut, and body-energy trajectory agrees at the
declared machine-precision scale. The equations are translation invariant;
minor bit-level differences arise only from floating-point arithmetic.

Goals 013-018 retain their accepted relative results. All nine Goal 018
scenarios now complete 48 days. Under two-day recurrence, minimum derived total
mass is approximately `39.97`, `39.92`, and `39.48 kg` for `400`, `800`, and
`1,200 kJ` events. The strongest treatment finishes at approximately
`39.50 kg`, while its final complete cycle still loses exactly `400 kJ` at
maximum recovery capacity. The earlier day-47 boundary disappears without any
change to the relative trajectory, confirming it was an arbitrary consequence
of the old energy-coordinate origin.

## Interpretation

The converter makes energy debt legible in physical units while preserving the
model's current simplicity. It is a stock interpretation, not another stock-
flow process. The selected density represents an effective labile reserve
mixture; `2 kg` is not asserted to be measured adipose mass, and the 5% fraction
is a synthetic starting scale rather than a calibrated macropod estimate.

## Limits And Stop Boundary

Mass does not affect maintenance, routine activity, appetite feedback, maximum
intake, gut capacity, forage acquisition, or any other transition. Structural
mass is fixed. Derived total mass includes only modeled structural and reserve
tissue; physical gut contents are excluded because the gut stock is an energy
account, not ingestible mass. There is no tissue partitioning, composition-
dependent energy density, growth, reproduction, hydration, thermoregulation,
viability threshold, empirical calibration, vegetation, or space.

Stop after the pure conversion, coordinate-invariance proof, corrected Goal 018
interpretation, and compact review evidence. Goal 020 requires a separate
scientific decision.

The retained no-write reproduction client is:

```text
```

Generated tables and the diagnostic panel remain disposable under the ignored
Goal 019 output directory.
