# Area-supported spatial grazing specification

Approved by Barry Brook on 2026-09-06 and implemented in the spatial grazing
programme recorded in Decision 0061. The study concerns chronic condition in
one focal animal, with responsive area-supported vegetation and independently
varied habitat supply, plant forcing, water-trip time and expenditure. Species
calibration, plant carbon/nitrogen physiology, populations and publication remain
outside this contract.

## Project context

Barry reports that the original project aimed to couple a herbivore model to
a DGVM developed by Steve Higgins' group. Delays led to use of a Thornley
transport-resistance surrogate. A postdoctoral C++ implementation was later
translated into R by Barry using earlier GPT models; the present clean rebuild
is approximately the third incarnation. This is attributed project history,
not independently recovered evidence. Barry's principal expertise is herbivore
demography; plant model choices need explicit assumptions and external scrutiny.

Three empirical case studies were identified previously, but their identities
and data were not found in a bounded search of this repository and reachable
Git history. Barry will look for the original material. A synthetic methods
paper followed by empirical applications, or a combined paper, remain open
publication options.

## Frozen scientific contract

One animal removes exactly its own dry-matter intake. Each forage patch has an
explicit support area in hectares, centroid coordinates in metres, a standing
biomass density and an unavailable residual. The surrounding rectangular domain
may contain nonforage matrix. Patch support is a biological assumption; adding
centroids is not a neutral numerical refinement. Geometry uses Euclidean
straight-line distance, with minimum-image displacement for the periodic
control. This models traversable matrix, not obstacles or least-cost routes.
Travel time is distance / speed; feeding can use the remaining fraction of an
hour. Travel continues across hourly boundaries. Routine expenditure remains
on the accepted clock; incremental travel expenditure is added separately.

The plant equation is dB/dt = r f B (1-B/K) - s B, with 0<=B<=K and prescribed
0<=f<=1. The exact autonomous solution is used within each hour, including
integrated gross production and senescence. Growth precedes grazing; animal
removal cannot penetrate the residual. Zero biomass is absorbing (no seed bank
or recruitment). Environmental forcing affects gross growth, not forage quality
or moisture. This is a generic responsive edible-biomass model, not TTR plant
physiology. At r=.002/h, s=.001/h, K=2000 kg DM/ha, the ungrazed equilibrium is
1000 kg DM/ha and local relaxation rate .001/h, matching the inherited linear
null locally while permitting biomass-dependent recovery.

A fixed causal grazing rule stays while local acquisition can supply the
reference .020 kg DM/h, and otherwise visits the next patch in a fixed cyclic
order. It sees current local biomass only. A diagnostic comparator sees all
current patch biomasses and scores four-hour intake opportunity minus travel
expenditure. Neither rule predicts growth or future forcing, and the comparator
is not a globally optimal strategy. Acquisition is .030 * min(1,
max(B-200,0)/500) kg DM/h, then bounded by appetite and available mass.

Water lies off domain. A familiar excursion returns to its departure patch,
with prescribed round-trip duration and expenditure. Drinking occurs when the
source is reached halfway through the journey, without a separate handling
interval. Hourly body-water accounting retains the existing end-step convention.
The reactive rule departs when opening water <=26 kg, at most once per day.
Water trips take precedence over new grazing moves; an ongoing journey completes
first. Water costs do not alter physiology or water loss rates.

## Experiment frozen before execution

The primary deterministic factorial uses four supports in a 100 x 100 m domain.
The left/right halves have K=1600/2400 kg DM/ha (same mean K=2000),
and start at their ungrazed equilibria K/2. The animal starts on the left.
This is prescribed spatial productivity heterogeneity, with constant food quality,
with 60 baseline days, 84 treatment days and 60 recovery days. Total forage area
is .08 or .04 ha (fixed throughout each run; an enduring habitat contrast, not
an instantaneous biomass deletion). Growth multiplier during treatment is 1 or
.6; it is 1 otherwise. Water round-trip time during treatment is .5 or 3 h and
expenditure is 0 or 900 kJ. Baseline and recovery use .5 h and zero expenditure.
The design has 16 branches; contrasts at each habitat level separate time,
expenditure and growth. Synthetic food/water and animal parameters retain the
accepted reference. Forage travel speed is 40 m/h and incremental cost 1 kJ/m.

Report phase means and end changes in body energy, minimum water, intake,
plant production/senescence, landscape biomass, movement and water-trip time,
expenditure and stop times. Chronic decline is the last-28-day treatment daily
energy slope; recovery is end-recovery energy relative to the branch's final
baseline day. If reserve would become negative, stop before that transition and
report a model-domain exit; do not interpret this as death or truncate the
energy ledger. Check 28-day sensitivity to separate transient from chronic loss.

Controls: plant equilibrium, drought, zero biomass, conservative grazing,
area-weighted equivalent subdivision, exact plant half-step agreement,
geometric wrapping and fractional/multihour travel; an abundant stationary
zero-cost run must reproduce the accepted energy reference. Integrated checks
cover both topologies, the informed comparator and altered patch subdivision
at fixed total area. The latter is structural sensitivity, not presumed
trajectory invariance. All balances must close independently. Complete the
full package release gate because new public plant/area primitives are added.
Expected directions are hypotheses, not software pass criteria. Stop after a
coherent interpretation, one independent audit and repair, and reproducible
no-write experiments; do not tune to produce an attractive result.

Structural controls use the full-area severe treatment (f=.6, trip=3 h,
cost=900 kJ): bounded topology, informed policy, homogeneous K, and a 4x4
subdivision under both topologies. A 2x2 centre grid has identical pairwise
distances under these topologies, so that comparison is an exact null control.
