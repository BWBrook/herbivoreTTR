# Active Surface

## Product Promise

`herbivoreTTR` is a small functional R package for transparent hourly
accounting from prescribed or appetite-controlled dry-matter intake to
metabolizable energy, gut energy, and body-energy reserve. Its current user is
Barry Brook. The package exists to make scientific assumptions, units,
transition order, and energy conservation inspectable while the model is
rebuilt in deliberate layers. It can also translate body-energy output into a
derived labile reserve and total body mass without changing the dynamics.

## Stage Status

The minimal herbivore-core development arc is closed through Goal 027. The
package boundary remains the compact functional animal described below;
duration response, variable quality, implicit patches, and movement remain
no-write evidence clients rather than generalized runtime machinery.

The next development arc is an isolated plant-forage stock-flow model. The
five stage contracts are indexed in [`docs/roadmap.md`](roadmap.md) and stored
under [`docs/arcs/`](arcs/). Protein, water, thermoregulation, composition, and
other richer animal processes are important deferred extensions, not rejected
features or prerequisites for the first forage stock.

## Canonical Active Flow

```text
prescribed dry-matter schedule
  -> fixed metabolizable-energy conversion
  -> prescribed available-energy schedule
  -> hourly gut stock: release from opening stock, then add current intake
  -> assimilated-energy flux
  -> hourly body reserve: assimilation - maintenance - prescribed activity
  -> hourly ledger and daily summary
```

`run_gut_body_energy_day()` is the canonical one-day coupled path. The
reference-cycle runner supplies a controlled periodic gut starting state and
two carried measurement days for diagnostic comparisons.

`calculate_appetite_target()` is a separate pure animal-side boundary:

```text
reference intake + signed body feedback + signed gut feedback
  -> zero and maximum bounds + feeding-opportunity gate
  -> appetite-target dry-matter and available-energy rates
```

The environment-side boundary is deliberately smaller:

```text
min(appetite target, forage-acquisition ceiling)
  -> realized dry-matter and available-energy intake rates
```

The ceiling is an external rate schedule, not a forage stock. It has no
depletion, renewal, plant process, or spatial state.

`run_appetite_controlled_energy_days()` is the canonical repeated fixed-day
path. It repeats one appetite reference and routine-activity schedule, then
calculates appetite target, applies one repeated forage ceiling, and calls the
gut and body scalar cores in that order for each hour. Closing stocks carry
exactly; reference periodicity is assessed numerically and is never imposed by
clamping. Experiments call this runner rather than carrying a second multi-day
model loop.

`derive_body_mass_from_energy_reserve()` is downstream of both runtime paths:

```text
body-energy reserve / effective reserve-tissue density
  -> labile reserve-tissue mass
  -> plus fixed structural mass
  -> total body mass
```

It is a read-only interpretation. No derived mass is stored or fed back.

Goal 014's fixed sensitivity client varies only the two synthetic feedback
fractions and one-day deficit size. It is evidence about controller behaviour,
not another runtime path or an empirical parameter-selection procedure.

Public boundaries validate numeric inputs by semantic value and return the
canonical plain records and schemas. Day, reference, and appetite-controlled
runners validate once, then call private scalar cores or the prevalidated
coupled-day helper. Public hourly steps remain the validated entry points for
direct callers.

## Protected Scientific Invariants

- Every quantity has an explicit unit and dry-matter basis where relevant.
- Dynamic stocks and prescribed inputs remain finite and non-negative.
- A body transition that would produce a negative reserve fails explicitly.
- Gut release is calculated from opening gut stock; current-hour intake enters
  the stock only after that release.
- Gut, body, and combined-system energy identities close within scale-aware
  floating-point tolerance.
- Assimilation transfers energy between modeled stocks and therefore cancels
  from the combined-system balance.
- Closing stocks carry exactly into the next modeled interval or day unless a
  declared reference design explicitly resets them.
- Synthetic balance, convergence, and shortfall results remain conditional on
  their prescribed schedules and are not interpreted as behavior, viability,
  or empirical physiology.
- Appetite target equals the reference rate when both stocks equal their
  hour-specific references, is zero when opportunity is closed, and remains
  within its declared physiological bounds.
- Realized intake is the smaller of appetite target and the external forage-
  acquisition ceiling; only realized intake enters the gut.
- The repeated appetite-controlled runner uses one fixed 24-hour reference and
  fixed forage and activity schedules; it does not encode day-specific forcing
  or events.
- Derived reserve-tissue and total mass are deterministic functions of body-
  energy reserve and fixed conversion parameters; they do not alter a
  transition.

## Surface Dispositions

| Surface | Disposition | Reason |
| --- | --- | --- |
| `R/`, package metadata, and dependencies | Retain | They implement the current scientific contract. |
| Core conservation and scenario tests | Retain now; simplify only when a distinct failure class is duplicated | Scientific invariants require direct protection. |
| No-write experiment clients | Retain | They reproduce accepted synthetic calculations without creating a second model. |
| `docs/decisions/` and current model docs | Retain | They record accepted scientific conclusions and the live contract. |
| Closed goal packets | Delete | Git preserves their execution history; they are not part of the active product. |
| Review-pack publishers and bulk receipt machinery | Delete | They duplicate validation and have no current runtime consumer. |
| Semantic validation and validate-once runner internals | Retain | Public boundaries validate direct callers; validated loops use scalar cores without changing equations or schemas. |
| Isolated forage biomass stock-flow | Next stage, pending authorization | It is the smallest new subsystem needed before homogeneous coupling. |
| Protein, water, thermoregulation, mass-dependent energetics, depletion, spatial coupling, and richer physiology | Defer | Each layer must answer a separately approved scientific question. |
| Compatibility adapters for obsolete paths | Delete or decline | There is one private current user and no supported legacy contract. |

## Proportional Validation

### Fast Change Gate

Use for ordinary model and documentation changes:

1. Parse retained R files.
2. Run focused tests for the affected scientific behavior and invariants.
3. Run `git diff --check` and inspect the exact diff.

### Explicit Release Gate

Use when publishing a package boundary or accepted model foundation:

1. Run the full test suite once.
2. Build the package externally in a temporary directory.
3. Run `R CMD check --no-manual` on the built package.
4. Independently inspect the decision-relevant result or artefact named by the
   scientific question.

Do not repeat either gate without a distinct named risk that existing evidence
cannot address.

## Stopping Rule

A tranche is complete when its prespecified scientific question or
architectural outcome is satisfied, protected invariants pass the proportional
gate, and remaining work is unlikely to change the decision. Residual
uncertainty is reported openly. Additional polish, receipts, permutations, or
defensive machinery are not reasons to continue by themselves.
