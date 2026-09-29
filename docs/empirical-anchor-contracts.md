# Observation contracts for the two empirical anchors

Revised after Fable's review on 27–29 September 2026. Barry approved the bounded
red-kangaroo accounting/acquisition work on 29 September; its executable
scope and fixed comparisons are in the
[065 specification](red-kangaroo-benchmark-specification.md), and the completed
result is in [Decision 0065](decisions/0065-red-kangaroo-budget-and-acquisition.md).
The Ash plant, full dynamic animal physiology and multi-season comparison
remain separate proposals. Methods and printed-page locators are in the
[evidence assessment](empirical-anchor-evidence.md).

The proposed sequence is **Munn daily budget closure, Short pooled-yard
acquisition, then a separately specified Ash plant comparison**. The first two
can begin with prescribed food availability and the existing intake/stock
accounting. They do not require a new regeneration state, spatial competitor
behaviour or memory rule. A complete dynamic species fixture still needs
declared assumptions for quantities these studies did not measure.

The principal question is whether the model can reproduce the quantities the
studies observed. Agreement at these scales would establish conditional
compatibility, not validated memory, chronic decline or extinction risk.

## Red kangaroos: keep the study contexts separate

Kinchega's spring graze-down and Fowlers Gap's autumn metabolic study involve
different diets, animals, areas and observation windows. Use documented
study-specific records within one species, not one mixture of their averages.

| Evidence | Context and observation | Use and limits |
| --- | --- | --- |
| Munn 2009/2010 | Mature dry females; 16-ha shared enclosure; 2–10 April 2007; doubly labelled water (DLW), body water, diet and scan-defined harvesting time | First budget comparison. FMR analyses used six kangaroos/five sheep; 2010 reports seven introduced per species. One forage field. |
| Munn 2010 + 2011 corrigendum | Corrected energy-derived gross DM requirement of 518 ± 39 g/day | Computed from FMR and diet energy; not independent observed intake. A DE-to-ME conversion is a further assumption. |
| Short 1985, pp. 436–442, 444 | Two adult females per 400-m2 yard, two yards; mean mass 25.6 kg; spring; unrestricted water | Second comparison: two-day vegetation-loss intake estimator and its descriptive curve, not individual instantaneous encounters. |
| Munn 2013 | Free-living mature dry females, another autumn/year and diet | Candidate comparison withheld from numerical fitting, though already read. GPS distance is not searched area. |
| Munn 2016 | Western grey kangaroos, late summer; full-sample and selected-subset results differ | Cross-species context and an explicit published energy-conversion assumption; not red-kangaroo parameter measurements. |

### First comparison: Munn energy and water closure

Begin with a daily accounting benchmark under a declared nonlimiting-food
assumption. It does not need individual competitors or a spatial foraging
controller. The principal review output is a table separating measurements,
derived quantities and assumptions, with energy and water balances. Do not
call reproducing a derived intake an independent validation.

| Quantity | Proposed source record or calculation | Interpretation |
| --- | --- | --- |
| Animal | Mature, non-pregnant, non-lactating female; 23.6 ± 0.8 kg mean mass | The matched 2007 study context. |
| Total energy expenditure | FMR 4,872 ± 364 kJ/day | Sum of included expenditure over the DLW interval; includes movement and other activity exactly once. |
| Basal reference | Table 1 predicted BMR 2,141 ± 52 kJ/day, using the paper's 200 × mass^0.75 relation | Not measured field maintenance. FMR minus this mean is 2,731 kJ/day of unresolved nonbasal expenditure, not identified locomotion cost. |
| Diet energy | DE 9.4 kJ/g ingested DM; candidate ME:DE ratio 0.9 gives ME 8.46 kJ/g | The 0.9 ratio is assumed in Munn 2016, not measured for these red kangaroos. |
| Derived gross DM requirement | 518 g/day under the published DE conversion; 576 g/day under the candidate ME conversion | Conditional alternatives, not two independent observations or a new corrigendum. |
| Body water | 66.7 ± 0.5% of mass; product of reported means gives about 15.7 kg | Does not establish dehydration thresholds, reserve size or a mortality boundary. |
| Water turnover | 1.5 ± 0.1 L/day | Interval turnover, not a measurement of ordinary loss alone. |
| Active food harvesting | About 10.4 h/day from scans | Includes searching, cropping, chewing and movement between food patches. Water-directed travel is separately classified. |

Do not silently substitute the different red-kangaroo BMR normalization
printed in the 2016 paper for the 2009 table. Nor should BMR be equated with
field maintenance: it supplies a basal reference, while the allocation of the
remaining expenditure is unresolved. Calibrating the total to FMR precludes
counting that same total as an independent prediction.

The initial 16-ha stock is approximately 7,040 kg DM. Seven kangaroos at
0.518–0.576 kg/day plus seven sheep at the corrected 1.572 kg/day remove about
1.66–1.71% of that total in eight days. Applying the assumed 0.9 energy ratio
to both species instead raises the upper comparison to 1.85%. This supports
a simple nonlimiting-food benchmark. It does not measure availability of the selectively eaten fraction:
if that fraction were one tenth of standing stock, the same removal would be
about 17% of it. Preserve the consumer-count discrepancy as provenance; it
need not block this first accounting task. A later depletion or acquisition
test must represent shared removal at its observation scale.

At these conditional intakes the synthetic food-water yield of 3.28 kg/kg DM
supplies 1.70–1.89 kg/day, already exceeding the reported mean turnover.
Under an approximately steady water pool, compare food water, drinking water
and metabolic water with the same interval's losses. With neither drinking
nor metabolic water, the corresponding upper food-water yields are
2.60–2.89 kg/kg DM. Illustratively assigning 0.15 kg/day to metabolic water
lowers them to 2.34–2.60. These are bounds from mean accounting under stated
assumptions, not measured moisture values or uncertainty intervals. Fable's
0.15-kg metabolic term remains an illustrative assumption, not an adopted
physiology parameter; drinking would tighten these bounds.

Keep food-derived and metabolic water distinct in that accounting. The
current dynamic water input is explicitly named food-derived water and has
no separate metabolic-water flux. Any later aggregation must define its
meaning and timing, including oxidation of body reserves, rather than
silently relabelling the food-moisture parameter.

An imposed feeding schedule can examine budget closure without adding a
handling mechanism. It must distinguish active harvesting from available
opportunity. Using 10.4 h as a food-activity total and then subtracting the
same between-food-patch travel again would double count time. The daily
benchmark need not invent within-day timing, gut turnover, appetite feedback,
body-energy capacity or critical hydration thresholds. A later dynamic
fixture must label those as independently sourced or synthetic assumptions.

The existing synthetic animal stays a separate reference: its 400-g/day
maximum and 28-kg water pool do not match this context. Short's 709-g/day
spring asymptote is also not a measured autumn Munn appetite cap. Use it only
as a declared cross-context sensitivity if a dynamic fixture later needs one.

### Second comparison: Short pooled-yard acquisition

Use one shared 400-m2 stock with two consumers (50 animals/ha), repeated for
the two yards. No individual movement or recovery forecast is needed.
The candidate observation operator is

`1000 * (A_ha * (V_start - V_end) - estimated_trampling_kg) / (N * interval_days)`

in g DM/animal/day, followed by the reported running two-point smoothing.
Map `V` to measured combined pasture and shrub stock, including material
rejected by the animals. Keep edible stock and fine/sparse ungrazeable residue
distinct from that observation. Adjacent smoothed points and observations
within a yard are dependent; both axes share biomass measurement error.

The methods correct for trampling but describe no plant-growth correction.
Positive growth during the interval makes corrected stock loss underestimate
ingestion; other uncorrected stock losses can act in the opposite direction.
Declare bounded spring production and nonfeeding losses as nuisance
assumptions. The low-density limb matters for encounter inference, but the
relative bias need not be largest there: that depends on the density response
of growth and the measurement error. Do not infer its size from season alone.

Predeclare opening, midpoint and closing density pairings as sensitivity
analyses; the inspected methods do not resolve the timestamp. Do not choose
one after seeing which fits best. At a constant 100 kg/ha, the descriptive
curve would imply about 49 kg/ha removed over two days at this stocking
density; this scale calculation illustrates why interval depletion matters,
not the actual trajectory of a measured yard. Figure digitization would be
a labelled reconstruction, not recovered raw data.

Short's descriptive curve is
`709 * (1 - exp(-V/84))` g DM/animal/day. Its zero-density slope would
correspond to `q * active_hours = 84.4 m2/day` only with matched edible
biomass, no positive threshold, encounter limitation and negligible interval
distortion. These conditions are not measured here. It is neither a fitted
bound on `q` nor grounds for importing Munn's 10.4 h from another trial.
Short could not distinguish several saturating functional forms.

The proposed 20–100 kg/ha residual interval is **not an empirical bound on
the current model's R**. Below 20 is an upper statement about fine/sparse
normally eaten material, not a lower limit. Low terminal combined biomass
and trial cessation do not identify a hard zero-intake threshold. Include
the observed residue and rejected standing material through their own
observation definitions; retain uncertainty in any inferred edible threshold.

Before fitting, separate parameter-setting observations from comparison
observations and specify tolerances for digitization, stock measurement,
trampling and growth. Compare the full observed response and depletion
history. Report conditional compatibility and identifiable parameter
combinations, not a unique instantaneous search coefficient.

## Northern cattle: specify the Ash comparison before adding structure

Use Ash and McIvor 1998 as a plant experiment with prescribed grazing
exposure. Cattle physiology and cattle search are unnecessary for this
comparison. Retain the two experimental blocks, plot/season treatments,
three steers per plot, 2–8-ha areas and eight-week exposures. Quadrats are
subsamples, not treatment replication.

| Contract item | Proposed treatment |
| --- | --- |
| Exposure | Achieved utilization: early wet 13/22/42%, late wet 10/20/38%, dry 22/42/61%; retain uncertainty in consumption inferred from animal size and growth. |
| Removal | Utilization is consumption divided by consumption plus residual stock, not a fraction of opening biomass removed instantly. Declare cumulative consumption, its timing and uncertainty; dry-season detachment can contaminate apparent utilization. |
| Observation | Map live and dead standing material and carry-over corrections to the paper's production estimator. Species selectivity does not itself identify a complete live/dead offtake schedule. |
| Comparison | Next-season production relative to each season's low-use treatment: early-wet medium/high about 82/61%, late-wet high about 68%, no comparable dry-season reduction. |
| Limits | These patterns are already known and concern two blocks. No comparable reduction is not an established equivalence bound for dry-season effects. |

Fable proposes live stock `G`, dead stock `D` (both kg DM/ha), and a
dimensionless regrowth-potential index `C` in [0,1], with seasonal forcing.
That is a useful candidate, not a uniquely inferred root/crown/reserve model.
A dimensionless capacity that promotes growth without being consumed can be
phenomenological; it is not a mass-accounted reserve pool.

The decisive null should use the **same live/dead representation, forcing,
restart mechanism, removal and observation operator with C fixed at one**.
Compare that with dynamic `C`; a zero-damage, initially unit-capacity
alternative should recover the null. This isolates the value of a changing
legacy state. The historical one-stock model can remain a descriptive
baseline, but comparing it alone with G/D/C confounds capacity with the
new standing-stock and seasonal structures.

Resolve these items in the plant proposal:

- `C * H_G / G` is undefined at zero live biomass. Specify stock-bounded
  removal and boundary behaviour. A proportional removal hazard is one
  candidate, but shared hazards and shared absolute offtake are different
  interventions when model stocks differ; choose and document the exposure.
  Report unmet removal targets rather than silently changing them.
- Multiplying grazing damage by growth forcing makes zero-growth periods
  immune to capacity damage by construction. Treat that phenological
  susceptibility as a hypothesis, with a non-season-gated comparator, not
  evidence supplied by reproducing the dry-season ranking.
- Declare forcing, restart, live/dead removal allocation and initial states
  independently of the next-season ranking wherever evidence permits.
  A senescence-protected floor would itself be a new regeneration assumption.
  Grant equivalent input information and nuisance flexibility to both models.
- Use grazing-year stocks, exclosures and other information to constrain
  ordinary plant processes where possible. Reserve next-season contrasts
  from numerical tuning, while acknowledging that their direction motivated
  the model. With two blocks and several aliased parameters, a successful
  fit cannot identify a unique plant mechanism.
- Predeclare parameter bounds, observation error and the comparison measure.
  A finite unsuccessful search is not proof the null cannot reproduce a
  pattern. Check model discrimination under the available replication before
  interpreting extra fit as evidence for a changing capacity.

The current one-stock prediction remains: identical complete biomass states,
parameters and future inputs give identical future production regardless of
past season. Ash did not state-match plots, so that fact alone is not an
empirical failure. No universal reversal of the observed ranking is proved.

## Later chronic-decline comparison and review boundary

None of these three comparisons tests multi-season kangaroo decline.
Short (p. 444) cites G. Robertson's personal communication: over 3.5 years,
pasture ranged from 9 to 1,090 kg/ha and was below 180 kg/ha for 47% of the
record. This is a useful low-forage regime warning and a data lead, not a
retrieved time series. Pasture excludes the bluebush in Short's combined
vegetation measure; the statistic cannot be equated directly with time at
zero model intake. Duration, ordering, rain, shrub use and animal condition
are needed for a multi-season test, not just the marginal fraction below a
threshold.

A later feasibility assessment should establish which matched forage, rain
and animal-condition records can be obtained before proposing that test.
Reconstruct actual opening conditions for Short and Munn; for a future
disturbance experiment, establish a grazed reference or seasonal cycle where
one exists.

The departure-observation suggestion has its own
[read-only diagnostic](decisions/0064-plant-matched-return-expectation.md).
The last-hour rate is a promising prospective comparison, but replacing the
current daily-mean field also changes departure and accumulated inadequacy.
It does not follow automatically from these empirical contracts. None of the
anchor papers identifies the animal's information set, rain-cue learning or
memory rule.

Barry approved the bounded red-kangaroo budget/acquisition parameterization
alongside the synthetic reference, with the above observation limits. The
G/D/C plant and multi-season comparison remain separate later choices.
Fable's revised Ash proposal is recorded in correspondence 56, message 645;
it needs its own scientific review before implementation.
