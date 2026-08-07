# Active Surface

## Product Promise

`herbivoreTTR` is a small functional R package for transparent hourly
accounting from prescribed dry-matter intake to metabolizable energy, gut
energy, and body-energy reserve. Its current user is Barry Brook. The package
exists to make scientific assumptions, units, transition order, and energy
conservation inspectable while the model is rebuilt in deliberate layers.

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
two carried measurement days for diagnostic comparisons. Experiments compose
these exported functions; they do not implement another model.

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

## Surface Dispositions

| Surface | Disposition | Reason |
| --- | --- | --- |
| `R/`, package metadata, and dependencies | Retain | They implement the current scientific contract. |
| Core conservation and scenario tests | Retain now; simplify only when a distinct failure class is duplicated | Scientific invariants require direct protection. |
| No-write experiment clients | Retain | They reproduce accepted synthetic calculations without creating a second model. |
| `docs/decisions/` and current model docs | Retain | They record accepted scientific conclusions and the live contract. |
| Closed goal packets | Delete | Git preserves their execution history; they are not part of the active product. |
| Review-pack publishers and bulk receipt machinery | Delete | They duplicate validation and have no current runtime consumer. |
| Exact-schema validation and overlapping runner internals | Simplify in a separate behavior-preserving tranche | They are real design candidates but touch the protected model path. |
| New physiology, behavior, plants, and spatial coupling | Defer | Each layer must answer a separately approved scientific question. |
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
