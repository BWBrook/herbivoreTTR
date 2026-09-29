# Decision 0065: red-kangaroo budget and acquisition benchmark

Date: 29 September 2026. Barry approved the red-kangaroo work; Astra recorded
the exact approval in correspondence 56, message 774. The
[comparison specification](../red-kangaroo-benchmark-specification.md) and
study records were committed in `564765a` before the new calculations. The
papers and published fitted curve had already been read.

## Accepted scope and result

Retain separate empirical records for the Fowlers Gap autumn budget and
Kinchega spring graze-down. Munn's daily accounts reproduce the corrected
energy-derived intake, but rule out the synthetic food-water yield under the
central steady-budget assumptions. Short's reconstruction exposes substantial
scatter and observation dependence: the primary acquisition comparison does
not closely reproduce its individual plotted points, and changing biomass
timestamp changes the apparent response. Neither comparison identifies a
unique hourly search coefficient or residual.

These are daily accounting and shared-stock acquisition clients of the
existing package, not a complete dynamic red-kangaroo physiology fixture.
The synthetic reference, package processes and frozen 061–064 experiments
are unchanged. Ash plant structure, departure-memory changes and multi-season
chronic-decline tests remain separate scientific choices.

## Munn: closure is not independent validation

| Quantity | Published DE conversion | Assumed ME:DE = 0.9 |
| --- | ---: | ---: |
| Available energy used in accounting (kJ/kg DM) | 9,400 | 8,460 |
| Derived intake (g DM/day) | 518.3 | 575.9 |
| Food water at synthetic yield 3.28 (kg/day) | 1.700 | 1.889 |
| Maximum food-water yield if other inputs are zero (kg/kg DM) | 2.894 | 2.605 |
| Maximum yield with illustrative metabolic water 0.15 kg/day | 2.605 | 2.344 |

Both cases reproduce total FMR of 4,872 kJ/day by construction. The first
matches the 2011 corrigendum's 518 ± 39 g/day, which was itself derived from
FMR and diet energy. It does not measure ME:DE = 1 or independently validate
intake. Predicted BMR is 2,141 kJ/day, leaving 2,731 kJ/day of unresolved
nonbasal expenditure; do not add movement to FMR again. Mean intake per
observed active harvesting hour is about 50 or 55 g DM/h, not an hourly
appetite ceiling. The product of mean mass and water fraction is 15.74 kg,
not a dehydration threshold or body-water capacity estimate.

At mean turnover 1.5 kg/day, synthetic food water alone exceeds measured
total turnover in both energy cases. The full water table reports drinking
required to close each budget, retaining negative values as infeasible
combinations. It does not hide excess input in an elimination term. Actual
food moisture, drinking and metabolic water are not separately identified.

The declared mean ± one-SE corners give intakes 447–604 g/day under DE
conversion and 497–671 g/day with ME:DE = 0.9. One DE corner can accommodate
yield 3.28 with zero metabolic water; none of the ME corners can. These are
deterministic sensitivity combinations, not probabilities, joint confidence
limits or bounds on all animals/diets. Printed DE is 9,400 kJ/kg, whereas
18,000 × 0.521 gives 9,378; this small rounding distinction is reported.

Seven introduced kangaroos and seven sheep imply about 1.66% removal from
the initial 7,040-kg enclosure stock over eight days using corrected published
intakes. Applying the 0.9 energy ratio to both species raises this to 1.85%;
changing only the kangaroo conversion while holding sheep intake fixed gives
1.71%. These conditional whole-stock fractions justify the first nonlimiting
accounting approximation, not a claim about the size of the selected edible
fraction or individual competition.

## Short: response depends on how vegetation loss is observed

The [source reconstruction](../../references/short-1985-digitization.md)
retains all 12 visible Fig. 4 points: five from yard 1 and seven from yard 2.
They are already smoothed stock-loss estimates, not direct instantaneous
intakes or twelve independent replicates. Reading allowances of ±10 kg DM/ha
and ±20 g DM/animal/day cover digitization only. Dates and the vegetation
timestamp paired with each point cannot be recovered.

Separately, Fig. 1(c) shows combined pasture and bluebush falling from about
588/610 to 79/98 kg DM/ha in yards 1/2 between plotted days 1 and 12. These
component sums support strong trial depletion; they do not distinguish
ingestion, trampling, growth or rejected stock and are not joined to Fig. 4.

The primary model uses two consumers per 400-m2 yard, a declared daily cap
of 709 g DM/animal and effective daily search exposure
`S = (0.709 / 84) * 10000 = 84.4047619 m2/day`. This uses the published curve's
low-density slope, conditionally on no edible residual or rejected offset.
It is not an observed hourly q, and Munn's harvesting hours are not imported
across seasons to manufacture one. The capped minimum differs structurally
from Short's inverted exponential even before stock-loss averaging.

The declared four-day response windows include shared depletion, adjacent
two-day stock-loss estimates and one smoothing operation. With primary
settings (R=J=0, no net plant flux), descriptive discrepancies are:

| Curve or biomass pairing | RMSE, all points (g DM/animal/day) | Yard 1 | Yard 2 |
| --- | ---: | ---: | ---: |
| Primary midpoint V2 | 224.5 | 194.3 | 243.7 |
| Opening V0 sensitivity | 188.9 | 205.5 | 176.0 |
| Closing V4 sensitivity | 239.4 | 223.2 | 250.3 |
| Endpoint-weighted sensitivity | 222.6 | 190.0 | 243.3 |
| Published fitted curve, in-sample reference | 197.9 | 204.8 | 192.9 |
| Separate R=200 control, midpoint | 466.2 | 547.5 | 398.1 |

All 12 central x values lie inside these loci's support. No primary midpoint
prediction overlaps a point's digitization rectangle, including both x and y
allowances. This is not a biological rejection test: uncertainty in the
original stock measurements, trampling correction, growth and smoothing is
larger and unquantified. Several plotted estimates exceed the published
709-g asymptote; it is a fitted scenario cap, not an observed upper bound.
The smaller error under opening pairing does not authorise selecting that
unrecorded observation convention.

Across the 36 declared midpoint sensitivities (18 acquisition settings with
two rejected offsets), descriptive RMSE spans roughly 192–366 g/day, excluding
the separate R=200 control. These comparisons do not select a preferred nuisance setting.
A constant net plant flux of ±2.5 kg/ha/day shifts the stock-loss estimator
by ∓50 g/animal/day when stock does not bound loss, even though it also
changes true ingestion. R=20 and J=84 are stress values, not source-estimated
bounds. No additional search or growth scenarios were run to improve fit.

Most decisively for identifiability, the matched no-growth cases
`(R,J)=(0,84)` and `(20,64)` give the same response over common combined-stock
support: maximum disagreement is about 1.2e-12 g/animal/day. Short's combined
vegetation response cannot distinguish an edible unavailable residual from a
constant rejected offset within this representation. The separate R=200
control illustrates why the synthetic threshold cannot be transferred
uncritically: it predicts no intake at combined stocks at or below 200 when
J=0 and net plant flux is zero. Short supplies no established 20–100-kg/ha
replacement interval.

## Verification and reproducibility

The hourly-to-half-hour comparison changes primary biomass by at most
0.1371 kg DM/ha and smoothed intake by 0.6855 g DM/animal/day, well below the
separate x/y digitization allowances. Numerical precision is not the dominant
uncertainty. The largest hourly stock-account residual is about 1.4e-14
kg DM/ha. No-growth stock loss equals ingestion; growth/loss, nonnegative
stocks, residual protection, density scaling, observation transforms and
offset invariance are explicitly checked.

The final run passed 16 accounting/integration checks and 15 Short numerical
checks. Targeted package record/conversion and shared-stock tests passed;
89 retained R files parsed and `git diff --check` passed. The declaration and
Fig. 4 input hashes are unchanged, and the frozen 064 source/input hashes
still match. There was no package boundary change requiring a release gate.

Independent review reproduced the budgets, errors, aliasing and observation
identities, checked the source readings and inspected both PDF pages. It
also retained vertical duplicate-x segments in a separate geometric check:
all 1,344 point/curve digitization-overlap decisions matched the implementation.
That qualification applies to this frozen input/grid; changed observations
would need the same geometry check. Implementation errors in search-unit
conversion, two-dimensional reading allowances and step-refinement units were
corrected before the final run; no scientific setting was altered to improve
agreement. No consequential audit finding remains at the declared scope.

The no-write entry point is `experiments/red-kangaroo-benchmark.R`; sourcing
it and calling `run_red_kangaroo_benchmark()` returns records, tables and
checks. Optional explicit output uses `write_red_kangaroo_benchmark_outputs`.
The review PDF, tables and RDS remain in ignored `outputs/red-kangaroo-065/`.
The source PDF stays local and is not redistributed.

The accepted stopping point is a reproducible, qualified benchmark. These
data do not validate memory, drought recovery, chronic decline or viability.
The next plant proposal must be judged separately on the Ash observation
contract and the information available from two experimental blocks.
