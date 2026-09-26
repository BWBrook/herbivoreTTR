# Proposed observation contracts for the two empirical anchors

Draft for scientific review, 26 September 2026. Barry approved the anchor
systems, not the structural changes proposed here. No empirical fit, new
trajectory, plant compartment, shared-consumer process or physiology change
has been implemented. Source details and printed-page locators are in the
[evidence assessment](empirical-anchor-evidence.md).

The principal question is whether a coherent animal–forage model can reproduce
the quantities these studies actually observed. Red kangaroos supply animal
energy/water and acquisition constraints; northern cattle supply a separate
seasonal plant-response test. Agreement would establish compatibility at those
scales, not validated memory, chronic decline, or extinction risk.

## Red kangaroos in arid western NSW

### Study-specific inputs and observations

Keep the Kinchega spring graze-down and Fowlers Gap autumn metabolic studies
as separate experiments within one species. Their diets, populations, season,
area and observation windows must not be combined into one synthetic trial.

| Evidence | Prescribed context or input | Model quantity to compare | Dependence and limits |
| --- | --- | --- | --- |
| Short 1985, pp. 436–442, 444 | Two adult females per 400-m2 yard, two yards; mean mass 25.6 kg; spring; measured opening pasture and shrub stocks; unrestricted water | Two-day vegetation-loss intake estimator per animal, then the reported smoothing and density pairing; descriptive curve `709(1-exp(-V/84))` g/day | Total vegetation `V` includes shrubs. Trampling correction and biomass error affect both axes. Smoothed points and animals within a yard are dependent. No matched feeding-time record. |
| Munn 2009/2010 | Mature dry females; 16-ha shared enclosure; 2–10 April 2007; measured diet/biomass and water access; reported animal masses | Total expenditure over the DLW interval, body-water fraction and turnover, and the 2010 scan-defined harvesting time | FMR analysis n=6 kangaroos/n=5 sheep; 2010 reports seven introduced per species. One shared forage field, not independent landscapes. |
| Munn 2010 + 2011 corrigendum | Diet gross energy and apparent digestibility assumptions, with ME:DE declared separately | Derived gross DM requirement; published corrected value 518 ± 39 g/day under that paper's conversion | Derived from FMR, not an independent intake target. Further energy conversion changes are conditional recalculations. |
| Munn 2013 | Free-living mature dry females, different autumn/year and diet | Interval expenditure, water and GPS-sampled distance | Candidate comparison withheld from numerical fitting, though already read; not unseen evidence. GPS distance is not searched area. |
| Munn 2016 | Western grey, late summer, enclosure and selected-subset distinctions | Cross-species comparison only | Neither the full-sample nor selected-subset FMR may replace red-kangaroo measurements. |

For Short, a candidate observation operator is
`1000 * (A_ha * (V_start - V_end) - estimated_trampling_kg) / (N * interval_days)`
in g DM/animal/day, followed by the published two-point smoothing. This
reproduces a stock-loss estimator, not necessarily true model ingestion when
production, senescence or nonfeeding loss occurs within the interval. Retain
those fluxes separately. The exact density timestamp paired with each intake
interval is not specified in the inspected methods; opening, midpoint or
closing density must not be selected later for best fit. Figure digitization
would be a separate, labelled reconstruction, not recovered raw data.

The low fine/sparse pasture residue and physically present but rejected
vegetation are separate observations. Do not set `R=20` on combined standing
biomass. Short supports a saturating daily response, but explicitly does not
distinguish an Ivlev curve from other saturating forms. Neither its fitted
`1/84` nor GPS distance is an instantaneous search coefficient. A pooled
pen-scale accounting model is a useful first comparator; translating to
physical feeding blocks requires an explicit spatial observation model.

### A coherent animal and information contract

Use one declared mass, reproductive state and diet within each study context.
The current synthetic fixture is not an empirical starting calibration: its
25-g/h intake cap and 16 feeding-opportunity hours allow at most 400 g/day,
below both Short's 709-g/day asymptote and Munn's corrected energy-derived
requirement. Increasing `q` alone cannot overcome that ceiling. Its 28-kg body
water pool is also incompatible with the roughly 15.7 kg implied by the 2009
mean mass and body-water fraction. These are reasons to specify the whole
animal before an encounter fit, not instructions to change the current fixture.

Compare FMR with the sum of modelled maintenance, activity, movement and other
included costs over the isotope interval, exactly once. If FMR calibrates that
sum, the same fitted total cannot also count as independent validation.
Keep gross, digestible and metabolizable diet energy distinct. Munn 2016 uses
an assumed ME:DE ratio of 0.9; applying it to the red-kangaroo 2010 DE density
would imply 8.46 kJ/g ME and about 576 g/day. That is a candidate conversion
assumption, not a measurement or an additional published corrigendum. Its
transferability and uncertainty need resolution before fixing diet ME.

Map isotope water turnover to the model's total water budget over the same
interval, with food/drinking water and any required metabolic-water or other
flux terms identified. Matching one ordinary-loss parameter to 1.5 L/day does
not by itself match turnover. Similarly, Munn's 10.4 h/day includes searching,
moving, cropping and chewing; current `feeding_h` is available opportunity
after travel, not measured active harvesting. Choose a compatible behavioural
observation or a prescribed feeding schedule before using that number. An
explicit handling-time mechanism is one candidate, not compelled by this study.

The information available to a future controller must be listed: local
encounters, elapsed time, observed rain or green flush if justified, and any
remembered residence/depletion. Future rainfall, prescribed forcing and other
animals' unobserved removals remain hidden. Arid growth calls for a
rain-conditioned comparison, not a constant growth law presented as empirical
knowledge. A stationary stochastic climate or seasonal reference is still
possible; rain pulses alone do not prove that no statistical baseline exists.
These papers do not identify a rain-cue learning rule. The current repaired
controller remains a synthetic forecaster with declared baseline parameters.

Represent shared forage explicitly at the observation scale. For Short, the
known two consumers must draw on the same yard stock. For Munn, distinguish
analysis samples from all consumers and represent the unresolved counts or
offtake rather than creating extra forage for the focal animal. An aggregate
consumer demand/removal process may suffice for an initial accounting test;
individual competitor movement is a later option, not an automatic requirement.
Other consumers and forcing errors can both bias forecasts upward, but need
not have identical spatial or temporal signatures. Added memory of depth or
residence duration needs its own definition and evidence; cap agreement alone
does not establish that the current biomass belief is correct.

### Proposed patterns and stopping point

The first comparison should test a nonnegative, saturating observed daily
intake response on Short's scale and an internally consistent energy/water
budget on Munn's scale. Preserve between-study context instead of fitting all
summary values simultaneously. Short's terminal pasture residue, rejected
material and diet switching should each have an explicit observation mapping.
Compare full response shape and depletion history rather than merely a final
reserve or survival endpoint.

Before fitting, freeze which observations set parameters, which are reserved
for comparison, and the uncertainty/tolerance appropriate to digitized curves,
shared measurement errors and reported summaries. Standard errors of animal
means are not uncertainty bounds on the whole ecological system. Until that
mapping is resolved, report qualitative compatibility and identifiable
combinations of `q`, effort and edible stock, not a unique fitted `q` or a
formal empirical-validation pass.

For field disturbance scenarios, choose a grazed reference conditional on the
climate and consumer process and examine its stationarity or seasonal cycle
where such a reference exists. Reproduce study opening conditions when
reconstructing a short experiment: neither Short's pen depletion nor Munn's
recently occupied enclosure should be relabelled a grazed equilibrium.

## Northern cattle as a plant-response anchor

Use Ash and McIvor 1998 as a vegetation experiment with prescribed grazing
exposure. The initial comparison need not implement cattle physiology or
infer cattle search. It should retain two experimental blocks, plot/season
treatments, three steers per plot, 2–8-ha areas and eight-week exposures.
Quadrats are subsamples, not treatment replication.

| Contract item | Proposed treatment |
| --- | --- |
| Grazing exposure | Use achieved utilization: early wet 13/22/42%, late wet 10/20/38%, dry 22/42/61%. Preserve uncertainty in consumption inferred from animal size/growth. |
| Removal operator | Utilization was consumption divided by consumption plus residual stock. Do not implement it as an instantaneous fraction of opening biomass. Specify a within-period offtake schedule and its uncertainty. |
| Forcing and state | Use the observed seasonal/rain context where available; declare missing inputs. Map green forage, senescent standing matter and detachment to the measured standing/production quantities. |
| Comparison target | Next-season production relative to the within-season low-use treatment: early-wet medium/high about 82/61%; late-wet high about 68%; no comparable dry-season reduction. |
| Interpretation | These are observed treatment patterns in a small experiment, not universal equality in dry-season effects or a continuous recovery curve. |

Keep the written one-stock prediction: identical complete biomass states,
parameters and future inputs imply identical future production regardless of
past grazing season. Ash did not state-match its plots, so this property is
not itself a failed empirical test. No universal reversal of its seasonal
ranking has been established. Before simulation, specify the biomass/production
observation operator and forcing, then state the predicted contrasts for the
one-stock null and any proposed alternative. Freeze the comparison before
using its outcomes to choose new structure.

## Structural choices to bring back after review

Separate **edible standing stock**, **material that remains ungrazed**, and
**capacity to regenerate** conceptually in both contracts. A living regrowth
state is a plausible next candidate for the perennial tall-grass legacy, but
Short's residual alone does not identify roots, crowns, tiller condition or a
seed bank as the required implementation. Annual emergence and perennial
regrowth need not be the same process with different phenology.

The synthetic floor protects living `B` from grazing; it is not an explicit
root reserve and does not protect it from senescence. Under the current
ungrazed baseline, recovery from 20 to 500 kg/ha takes 162.2 days, versus
57.8 days from 200. These exact calculations expose sensitivity to the assumed
living stock, not empirical recovery times or proof of a unique plant model.

The next review should narrow two connected choices: the simplest plant state
and observation map that can express the target legacy, and the smallest
shared-consumer representation needed to reproduce each study. Include any
animal rescaling, diet-energy conversion and feeding-time interpretation in
the same concrete proposal. Barry's later structural decision can then concern
named states, units, equations and discriminating comparisons. This draft
stops before those choices are implemented.
