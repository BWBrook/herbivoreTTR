# Plant model choice for spatial grazing

Assessed 2026-09-06 against the primary paper and CRAN release source. The
first spatial programme uses a native one-stock edible-biomass process. TTR.PGM
is a candidate for later structural comparison after the empirical vegetation
target is known; it is not a dependency of this implementation.

Higgins et al. (2025), *Methods in Ecology and Evolution* 16, 1599–1608,
[doi:10.1111/2041-210X.70071](https://doi.org/10.1111/2041-210X.70071),
present the transport-resistance plant model. Its six individual-plant states
represent shoot/root structural dry matter and soluble carbon and nitrogen.
Temperature, radiation, carbon dioxide, soil moisture and nitrogen influence
process rates. These mechanisms could support a richer plant comparison, but
also require choices about plant density, edible tissue and defoliation.

The [TTR.PGM 1.0.0 source](https://cran.r-project.org/src/contrib/TTR.PGM_1.0.0.tar.gz)
was inspected without installation or simulation. Its public runner does not
accept an arbitrary opening six-state record or a grazing callback; it
initializes states from one initial-mass scalar. There is no harvest flux.
Direct repeated hourly calls would therefore not implement a valid continuing
plant trajectory. Source modifications would need to expose persistent state,
defoliation and closing-state accounts. The engine also floors negative state
proposals without a balancing flux; a conservative coupling would need explicit
handling of such boundaries. Its time-step argument does not itself rescale all
plant process coefficients, so daily-to-hourly use requires a separate check.
These are code-inspection findings, not empirical tests of the package.

Area aggregation is a scientific choice. Multiplying all six extensive states
by a fixed number of identical plants per hectare requires the model's size
saturation constants to be scaled by the same density. Averaging unequal plants
before applying nonlinear rates does not generally reproduce their summed
response. Treating a single plant run as an area would hide this assumption.
Defoliating structural shoot mass alone would also alter soluble concentrations;
removal of soluble pools and subsequent remobilization require an explicit rule.
Plant C/N state does not itself specify forage metabolizable energy or water.

The chosen minimum is dB/dt=(rf-s)B-(rf/K)B² for edible standing dry matter per
hectare. It introduces biomass-dependent production while retaining auditable
production, senescence and grazing fluxes. K is a production-saturation scale;
the ungrazed equilibrium is K(1-s/(rf)) where rf>s. This distinguishes it from
the inherited constant-production null. The exact continuous autonomous
solution avoids an equilibrium shift from sequential growth/loss integration.

The numerical values are synthetic. Near-equilibrium observations mainly
identify equilibrium and relaxation rate, not r, s and K independently.
An empirical application will need independent production/senescence information
or sufficiently strong perturbations plus recovery data. Reduced-production
forcing is a model intervention, not a validated drought response: the present
model contains no soil-water or plant-nutrient balance.

Barry's historical motivation and unresolved empirical cases are recorded in
the spatial programme record. A later TTR comparison should be driven by those
cases, with explicit tissue removal, area scaling, time-step convergence and
an independently supported forage-quality bridge.

## Empirical follow-up agreed 25 September 2026

Barry selected red kangaroos in arid rangeland and cattle in northern tall
grass as complementary anchors. The [source assessment](empirical-anchor-evidence.md)
separates daily animal energy/intake evidence from Ash and McIvor's seasonal
plant response. Their biology and observation scales must remain explicit
when animal and plant structure are selected together. No Ash simulation or
new plant compartment has been implemented.

The pre-implementation structural prediction is conditional: for two plots
with the same complete standing-biomass state, parameters, future forcing and
removal schedule, this deterministic one-stock model predicts identical future
production regardless of past grazing season. It cannot retain an additional
effect of damage to roots, crowns or tillers once those inputs match. This is
a property of the model; Ash's plots were not an experimental matched-biomass
test, so that study alone does not prove which hidden state is required.

Under a specified near-zero dry-season growth rate, the current stock still
senesces exponentially; after 150–180 days at s=.001/h, about 2.7–1.3% of an
ungrazed opening stock remains. Wet-season recovery near the baseline
equilibrium has a 41.7-day local relaxation time, not a finite erasure time.
These mechanisms motivate concern about the seasonal pattern, but they do not
prove that *every* seasonal forcing or observation scheme reverses the Ash
ranking. The actual forcing, live/dead observation mapping, achieved grazing
exposure and follow-up window must be specified before a stronger ordinal
prediction can be tested. Ash is a cattle/tall-grass challenge, not a universal
acceptance gate for every arid kangaroo plant model.

Future disturbance comparisons should branch from a declared grazed reference
trajectory, after checking its stability or periodicity where it exists. If
the proposed baseline cannot sustain a grazed attractor, report that fact
rather than silently treating 60 days from an ungrazed stock as equilibrium.
The 064 repair deliberately retains the original day-60 transient to isolate
the forecast intervention.
