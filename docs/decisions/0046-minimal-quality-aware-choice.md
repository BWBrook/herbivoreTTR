# Decision 0046: Minimal Quality-Aware Choice

Date: 2026-08-24

Status: accepted

## Question

Can the existing transparent feeding-bout helper use each patch's declared
metabolizable-energy density directly, and how closely does that deliberately
simple rule reproduce the Goal 045 full-model quality oracle?

## Implementation

`choose_known_patch_for_feeding_bout()` now reads acquisition capacity and
metabolizable-energy density for both the current and destination patches from
the landscape. Its duplicate common `food_parameters` argument has been
removed. No compatibility path is retained.

For fixed expected dry-matter demand `d`, remaining feeding opportunity `H`,
one-hour route duration `T`, patch capacities `C`, patch densities `E`, and
route expenditure `M`:

```text
stay score = min(d, C[current]) * H * E[current]

move score = min(d, C[destination]) * max(0, H - T)
             * E[destination] - M
```

The helper still moves only for a strictly greater score and stays on ties. It
does not simulate appetite, gut release, body reserve, or realized future
intake.

## Evidence

The accepted Goal 045 grid is unchanged: current-patch density varies from
`4,000` to `10,000 kJ kg DM^-1` in `100 kJ kg DM^-1` steps, the destination
stays at `10,000`, acquisition capacity is `0.025 kg DM h^-1` in both patches,
and the hour-0 route costs `900 kJ` and one feeding hour.

| Decision | Last move | First stay |
| --- | ---: | ---: |
| Minimal quality-aware helper | 6,500 kJ kg DM^-1 | 6,600 kJ kg DM^-1 |
| Full appetite-energy oracle | 7,300 kJ kg DM^-1 | 7,400 kJ kg DM^-1 |

The helper and oracle agree from `4,000` through `6,500` and from `7,400`
through `10,000 kJ kg DM^-1`. From `6,600` through `7,300`, the helper stays
while the oracle moves. Its largest realized regret is `168 kJ`, at `6,600`.
At the accepted `8,000` versus `10,000` contrast, both stay and regret is zero.

The helper's move score is `20 kJ` greater at `6,500` and `12 kJ` lower at
`6,600`, establishing its bracket directly. Focused tests protect separate
patch-density lookup, both scores, the switch, and tie-to-stay behavior. Every
full-model counterfactual retains exact energy closure.

## Interpretation

The result is expected and green. The helper captures the correct direction of
quality preference and is conservative about moving. It switches earlier than
the oracle because fixed reference demand underestimates the stronger later
appetite compensation induced by movement expenditure: across this grid it
underestimates the move option more than the stay option.

This bounded disagreement is preferable to silently treating patch quality as
common, and it remains an interpretable operational null. It does not justify
adding anticipation or a full-model forecast to the animal's decision rule.
The threshold and regret are synthetic, one-day, reference-state results, not
empirical behavioral claims.
