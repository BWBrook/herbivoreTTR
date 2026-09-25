# 0061 — Area-supported spatial grazing with responsive plants

2026-09-06. The approved three-stage programme establishes a conservative
synthetic landscape capability and an interpretable chronic-condition study.
The mathematical and experimental contract is in the
[spatial specification](../spatial-grazing-specification.md); the separate
[TTR assessment](../plant-model-assessment.md) explains the plant-model choice.

## Decision and evidence

Use one focal animal with area-bearing forage supports, explicit XY geometry,
fractional travel/feeding time, and biomass-dependent plant production plus
senescence. Retain the inherited linear plant and fixed-route experiments as
scientific nulls. Do not promote the new local cyclic grazing rule as calibrated
behaviour. It is a fixed, transparent rule for examining the spatial system.

The predeclared deterministic study comprises 16 factorial branches and five
structural controls. Each planned run has 60 baseline days, 84 treatment days
and 60 recovery days. Total forage area is fixed within a run (.08 or .04 ha);
production multiplier, water-trip duration and expenditure change at treatment
onset and reset for recovery. The outputs support the following finite-horizon
conclusions, conditional on the synthetic acquisition and movement rules:

| Habitat / treatment | Result |
| --- | --- |
| .08 ha, unchanged growth | All four water-access combinations complete 204 days. |
| .04 ha, unchanged growth, zero extra water expenditure | Energy-reserve domain exit on day 152 or 153 under the declared acquisition and movement rules, even without reduced plant production. |
| .04 ha, unchanged growth, 900 kJ water trips | Exit on day 135 or 136. |
| .08 ha, growth multiplier .6 | Exit on day 119 with zero trip expenditure, or day 115 with 900 kJ trips, at either tested duration. |
| .04 ha, growth multiplier .6 | Exit on day 89 with zero trip expenditure, or day 86 with 900 kJ trips. |

These are first infeasible hourly transitions, not mortality predictions. State
and all ledgers stop before the offending transition. The primary treatment
starts on day 61, so a day-115 exit occurs during treatment day 55.

The .08-ha unchanged-growth runs finish recovery within about 59 kJ of their
own baseline endpoint (less than .15% of the 40,000-kJ initial reserve). Final
28-day treatment slopes range from approximately -2.82 to +3.56 kJ/day. These
small signed slopes also change across the 28/56-day windows (the 56-day
values are all positive, approximately .15 to 1.97 kJ/day). They depend on
feeding/trip phase and do not support ranking the
water-duration options. At .04 ha with unchanged growth and zero water cost,
late treatment slopes are approximately -1,099 and -1,090 kJ/day before the
subsequent exits. No late-treatment slope or recovery estimate is assigned to
a run that did not reach the requisite endpoint.

Minimum body water across all 21 runs is about 25.82 kg, above the declared
24-kg interpretation boundary. This establishes an energy-side domain exit in
these scenarios; it does not imply physiological dehydration is unimportant in
other environments or that the water policy is optimal.

## Mechanism and structural limits

The severe .08-ha scenario (growth .6, trip 3 h / 900 kJ) exits on day 115 under
the local rule and day 133 under the informed four-hour current-stock score.
The comparator spends less time cycling among poorly rewarding patches, but
also changes its baseline trajectory. It is an alternative policy throughout
the run, not an intervention applied to an identical state on day 61 and not
a perfect or globally optimal strategy.

In the same severe setting, homogeneous plants exit on day 114. Sixteen
supports at fixed total forage area exit on day 116 with periodic geometry and
day 115 with bounded geometry. The four-support periodic/bounded control is
exactly identical because every coordinate separation is at most half a domain
width. This is a geometry null, not evidence that boundaries never matter.
Subdivision conserves area and plant mass but changes ecological feeding
supports, visit order and travel; it is structural sensitivity, not numerical
convergence. Coordinate supports do not model shape, within-patch search,
barriers, local competition or a fixed-area feeding footprint.

Standing forage remains at exit: the severe local scenario retains roughly
39 kg DM across .08 ha. Total biomass alone therefore does not identify usable
hourly energy supply. Plant forcing reduces renewal and acquisition, while the
local departure rule can amplify movement when all patches offer low returns.
The informed result shows that policy contributes to the timing; the severe
forcing remains limiting under both tested rules. A claim that the exits are
caused by plant production alone would exceed these controls.

Phase means from stopped runs cover different windows and must not be compared
as matched treatment effects. Within each area, the local-policy growth and water-treatment branches share
baseline history; area itself is an enduring habitat-support factor from day 1.
Explicit exit times provide the primary finite-horizon contrasts. The 28/56-day slope sensitivity is descriptive
for branches reaching the complete treatment endpoint; the runs do not establish
asymptotic equilibria. Sixty baseline days are a shared elapsed period, not a
claim that all vegetation stocks have equilibrated.

## Verification and stopping point

The integration reproduces the accepted abundant stationary energy reference.
Plant checks cover equilibrium, absorbing zero, no-growth exponential decay,
reduced-production analytical recovery, half-step state and flux agreement,
and area-weighted equivalent subdivision. Movement checks cover metric wrapping,
fractional feeding time, multihour water travel, one source encounter, and
return to origin. Area removal cannot exceed accessible mass. An infeasible
energy proposal leaves the entire opening record untouched.

Across the 21 trajectories, the largest independently computed hourly
residuals are 3.5e-14 kg DM for landscape forage, 3.7e-12 kJ for combined gut/body
energy, and 3.2e-15 kg for body water. Final-source reproduction exactly matches all 21 daily trajectories. The full
test suite and external `R CMD build` / `R CMD check --no-manual` pass with
Status OK (no errors, warnings or notes). Independent scientific review found no material implementation defect and
accepted the conditional interpretation after replacing a finite-horizon
"unsustainable" claim with the observed domain exit, and clarifying that shared
baselines apply within each area rather than across the enduring area contrast.
Generated ledgers and plots remain under ignored `outputs/spatial-grazing-061/`;
retained scripts regenerate them without writing unless explicitly asked.

This programme stops with a useful synthetic landscape, not a species model or
publication-ready empirical claim. The next valuable scientific discussion is
which vegetation and habitat structures the recovered case studies require,
and whether the animal should search a fixed physical feeding footprint within
supports. Those decisions should precede additional behavioural tuning or a
TTR physiology implementation. Population modelling remains a separate layer.
