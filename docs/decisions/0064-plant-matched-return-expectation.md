# Decision 0064: plant-matched return expectation and empirical anchors

Date: 25 September 2026. Barry authorised the recovery repair, red-kangaroo
and cattle anchors, and commit/push in response to Fable's thread 56 review.
The [064 specification](../feeding-access-recovery-specification.md) was fixed
before repair trajectories. Original 061–063 source is preserved in `d610ae9`.

## Decision

Replace the inherited finite two-day last-to-best recovery with baseline
plant propagation of a return-equivalent density proxy. Retain historical
best as a cap, all other behavioural choices and the actual plant/animal
equations. The two-day forecast remains explicitly selected by the frozen
062/063 experiments and their short-pulse follow-up; direct physical-support
runs use the repaired forecast.

With complete absent days a, the forecast is
`min(best, q max(Phi_baseline(24a, R + last/q) - R, 0))`.
The plant equation, units and declared prior knowledge are in the specification.
This is a model of expectation, not inferred biomass: observed daily returns
are appetite-censored and include depletion. Actual forcing and unvisited
stocks remain hidden. The animal knows baseline plant parameters as a
synthetic prior; no claim of measured or learned animal knowledge is made.

A fixed replacement such as 15 days was rejected before trajectory evaluation.
It approximates the reference 200-to-250 passage (14.246 days), but repeats the
same defect for other coefficients and starting returns. At q=.3, the baseline
equilibrium return is only 240, so 250 is not attainable. During f=.6, a
baseline-based expectation can still be overoptimistic. Neither forecast is
an empirical model of memory, and the repair is not selected by survival.

## Matched comparison

Five predeclared old/repaired pairs branch from identical original day-60
states: three undisturbed layouts at q=.6, and continuous near-water sustained
disturbance at q=3 and 5. Existing informed runs supply four contextual
comparators. The comparison isolates the forecast intervention after day 60;
it does not compare lifetime behavioural traits or grazed equilibria.

All five repaired paths complete day 228. The four selected historical exits
are removed, while the continuous undisturbed control still completes.

| q | Layout and growth | Old-rule exit | Repaired day-228 reserve (kJ) | Change from day 60 (kJ) | Final 28-day slope (kJ/day) |
| ---: | --- | --- | ---: | ---: | ---: |
| .6 | continuous, unchanged | completes | 39,988 | +42 | +0.75 |
| .6 | clustered, unchanged | day 197, hour 23 | 39,853 | −93 | −0.32 |
| .6 | fragmented, unchanged | day 194, hour 16 | 39,914 | −5 | −3.50 |
| 3 | continuous, sustained reduction | day 205, hour 13 | 39,525 | −179 | −0.43 |
| 5 | continuous, sustained reduction | day 150, hour 5 | 39,727 | −196 | −47.23 |

In the clustered/fragmented reference cases, stations fed on increase from four
to eight. The median complete absence before a revisit rises from 3 days to
19.5/20 days; median first-day return rises from 176/178 to 207/214 kJ per
feeding-opportunity hour. No repaired revisit in these two trajectories has
first-day return below 200. These are descriptive statistics over each path's
observed post-day-60 revisits, with different exit horizons and selected visits;
zero-intake observations are retained. They are not unbiased regrowth estimates.

At the old paths' final observed hours, the repaired clustered/fragmented
animals have acquired 3.93/3.74 kg more dry matter since branching and spent
210/495 kJ on forage travel, versus 940/3,165 kJ with the old rule. This is a
change in coupled movement, depletion and regrowth, not an additive attribution
of their separate effects.

The two high-search repairs also expand feeding to eight stations and complete,
but 57%/55% of their selected revisits still return below 200. Baseline plant
knowledge remains optimistic during drought. The q=5 final reserve trend is
negative despite near-baseline terminal condition, so neither completion nor
the near-baseline endpoint establishes a stable grazed attractor. Reserves
cycle within that window; its negative fitted slope does not establish
monotonic chronic decline either. The result
supports Fable's causal diagnosis in these four failed examples; it does not
establish that every experienced-policy failure in the 90-branch grid has the
same sufficient explanation. No further scenarios were added after results.

## Verification and reproducibility

All five historical replays reproduce their original full hourly ledgers and
exit times exactly. The repaired and available informed branches share exact
initial states and day-60 prefixes. All 14 reported trajectories satisfy the
existing cumulative intake and combined-energy bounds and independent account
checks: maximum residuals are 3.76e-12 kJ for energy, 3.33e-14 kg DM for plants,
and 3.11e-15 kg for water. Minimum water exceeds 25.93 kg throughout.

Targeted checks cover exact propagation against repeated plant transitions,
positive/zero/negative linear coefficients, zero-age identity, day-opening
indexing, unattainable caps, above-equilibrium decline, invalid priors and
purity. Existing policy/integration/refinement checks pass. An independent
core audit confirms no unvisited-state or forcing leak and verifies historical
calls. The 54 installed exported function definitions match retained package
source. The release gate for the accumulated package foundation passed 441
tests and external `R CMD build`/`R CMD check --no-manual` with Status OK;
064 changes only experimental composition and documentation.

Independent final review also reproduces all 519 revisit rows and the common-
horizon totals, confirms the day-60 origin of the bounds, and finds no material
provenance or interpretation defect. No further trajectory run was needed.

The no-write runner is `experiments/feeding-access-recovery-repair.R`; the
optional plotting function is in `experiments/feeding-access-recovery-figures.R`.
Ignored `outputs/recovery-clock-064/` contains `repair.rds`, summary/revisit/
common-horizon tables, source/input checksums, audit notes and the one-page
`recovery-expectation.pdf`. Original 062/063 caches were not overwritten.

## Empirical and interpretive decisions

The [anchor assessment](../empirical-anchor-evidence.md) records red kangaroos
in arid western NSW and cattle in northern tall grass as complementary
systems. Animal and plant assumptions should be chosen together for each;
parameters must not be pooled into another incoherent synthetic organism.
The current animal's energy and water scales remain synthetic and unchanged.

Munn et al. (2010) has a formal 2011 corrigendum: inferred gross intake is
518 ± 39 g DM/day for the sampled red kangaroos, not the original 994.
Field metabolic rate already includes activity, so it cannot be used as
maintenance before adding movement costs again. Short (1985) reports an
ungrazable residual below 20 kg/ha in its arid graze-down context, challenging
200 as an empirical red-kangaroo residual. Neither supplies a direct estimate
of this model's instantaneous search coefficient; edible stock, area support,
feeding time and observation processes still need explicit alignment.

The one-block supply ratio gives an integer **necessary support bound**:
at least six 100-m² blocks for indefinite baseline reference demand, before
access/travel losses. It does not construct a sufficient rotation. Four or
five blocks are inadequate indefinitely, but finite opening stocks and body
reserves can delay failure. Under f=.6 all eight blocks renew at most 9.6% of
reference demand.

The [plant assessment](../plant-model-assessment.md) records the Ash prediction
before implementation: identical complete biomass states and future inputs
give identical future production, regardless of grazing history. The current
one-stock model cannot retain a separate root/crown legacy after state matching.
Ash's design does not directly test that matched-state contrast or uniquely
identify the necessary compartments. A reversal under every conceivable
seasonal forcing is not established. No Ash simulation or plant compartments
were added. Future disturbance studies need a declared grazed reference
trajectory and a stability/periodicity check where that reference exists.

## Review addendum: opening potential and depletion, 26 September 2026

Fable accepted the bounded intervention and split the high-search revisits by
forcing phase (correspondence 56, messages 556–558). A read-only reconstruction
from the existing cache reproduces that table but corrects the inference that
the forecast becomes exact after forcing. Equal medians at the 250-kJ/h cap
hide substantial disagreement on individual revisits.

Here opening potential is `min(250, 10000 * encounter_ceiling / feeding_h)`
in the first **full** feeding hour at the revisited station, matching Fable's
definition. Every such visit first has a partial feeding opportunity at hour
0; the first full hour is hour 1. Potential is neither actual appetite nor
the day's mean return.

| q | Phase | Revisits | First-day return below 200 | Median forecast / opening potential / first-day return (kJ/h) | Forecast equals capped opening potential |
| ---: | --- | ---: | ---: | --- | ---: |
| 3 | days 61–144, forced | 15 | 14 | 250 / 106 / 88 | 1 |
| 5 | days 61–144, forced | 14 | 14 | 250 / 107 / 79 | 0 |
| 3 | days 145–228, after forcing | 29 | 11 | 250 / 250 / 210 | 17 |
| 5 | days 145–228, after forcing | 26 | 8 | 250 / 250 / 228 | 20 |

Of the 19 inadequate post-forcing revisits, five open below 200, twelve open
between 200 and 250, and two open at the cap. The latter fourteen lose enough
encounter capacity during the day to fall below 200; all fourteen also finish
with encounter potential below 200. Forecast overprediction co-occurs in
seventeen of the nineteen cases, including the twelve that open adequate but
below 250. Thus depletion matters, but it is not the sole explanation of an
otherwise exact forecast. The two cap-agreement cases are q=5 on days 208 and
219. Using the first positive feeding opportunity instead of the first full
hour gives 18/29 and 20/26 capped agreements, preserving the conclusion.

Eleven of the 55 post-forcing returns have absences crossing the forcing
boundary, so arrival after day 144 alone does not isolate baseline regrowth.
Even for the 44 returns whose previous observation is after day 144, the
return-equivalent starting proxy exceeds reconstructed last-observed-day
closing biomass in every case: median excess 11.34 kg DM/ha at q=3 and 8.54
at q=5. Propagation over the same complete absent days leaves median uncapped
return overprediction of 37.9/53.0 kJ/h at the next pre-day-opening state.
This is the already-declared limitation of converting a daily realised mean,
which averages over depletion and may be appetite-censored, into an endpoint
proxy. Exact plant propagation does not make that proxy an exact state estimate.

Independent calculation covered all 84 repaired high-search revisits, matched
the recorded forecasts within 1e-8 kJ/h, and reconstructed block stocks from
the cached hourly intake/forcing ledger with aggregate forage-mass discrepancy
below 1e-9 kg. No behavioural or physiological trajectory was rerun or changed.
The reproducible R calculation and per-visit tables are in ignored
`outputs/recovery-clock-064/phase-review-20260926/` (`audit-phase-claim.R`).

## Review addendum: last-hour observation, 27 September 2026

Fable proposed using the last full feeding-hour rate instead of the daily
mean (correspondence 56, message 571). A read-only diagnostic of the two
repaired high-search paths supports testing that proposal. It does not
establish the result of changing the controller: all observations below are
computed along the existing trajectories.

All 100 recorded forage departures at q=3/5 follow an encounter-limited last
full feeding hour. That is selected evidence; many ordinary day endings are
appetite-limited. The daily departure decision occurs at hour 0 after plant
growth, using memory updated at the previous hour 23. Thus this is generally
a previous-evening observation, not an instantaneous marginal-value departure
rule. One departure follows a partial hour-23 water excursion and feeding,
making hour 22 the last full feeding hour despite a newer partial observation.

For the 44 revisits whose preceding observation occurred after forcing, the
candidate proxy is closer to the true final biomass of that preceding day
in every case:

| q (m2/h) | Revisits | Median daily-mean proxy excess (kg DM/ha) | Median last-full-hour proxy excess (kg DM/ha) |
| ---: | ---: | ---: | ---: |
| 3 | 24 | 11.34 | 1.51 |
| 5 | 20 | 8.54 | 1.07 |

The reference here is the reconstructed stock after hour 23, including the
partial final hour when present. Even an uncensored hourly rate identifies
the stock before that hour's intake, not after it. For an encounter-limited
full hour on the 100-m2 block at the fixture's 10,000-kJ/kg food ME,
`c = q * (B_open - R)` kJ/h, so `R + c/q` recovers opening biomass;
grazing then reduces density by `c/100` kg DM/ha.
This explains the remaining positive bias without a new trajectory.

Using the existing complete-absent-day clock, the candidate's median uncapped
return error at the hour-0 choice remains +4.38/+5.70 kJ/h for those q=3/5
post-forcing observations. During forcing the corresponding errors are
+219/+337 kJ/h, and for absences crossing the forcing boundary +165/+166.
An observation change cannot reveal hidden drought. As a numerical control,
propagating true final stock for `24 * complete_absent_days + 1` plant
transitions recovers the post-forcing choice state to numerical precision;
the extra transition is choice-day hour 0. Any new observation contract must
state both its sampling time and its propagation clock.

The current `last_return` field also controls current-station adequacy,
historical best and accumulated inadequacy. On five q=3 and ten q=5
post-forcing days, the daily mean is at least 200 kJ/h while the candidate
last-full-hour rate is below 200. Replacing the scalar would open departure
gates that the current rule leaves closed. The cached calculation therefore
cannot predict resulting movement or reserve trajectories.

Recommendation: a separate prospective observation comparison, fixing the
daily adequacy/deficit calculation while distinguishing it from the remembered
endpoint observation. Compare the daily mean, latest duration-normalised
rate and an endpoint-corrected diagnostic with explicit information
requirements. Predeclare historical-best semantics, timing and censoring;
do not describe the candidate as exact recovery, an optimal giving-up rule
or a proven behavioural repair. No anchor comparison currently needs it.

The calculation and compact outputs are in ignored
`outputs/anchor-review-20260927/departure-review/`
(`audit-departure-rate.R`, `diagnostic-summary.csv`, `diagnostic-note.md`).
The block reconstruction agrees with cached total forage to below 1e-9 kg;
input hashes are recorded there. Source, the frozen 064 specification and
all cached trajectories are unchanged.

## Next review boundary

All three requested full texts have now been supplied and read. The updated
[source assessment](../empirical-anchor-evidence.md) and
[proposed observation contracts](../empirical-anchor-contracts.md) now recommend
Munn daily budget closure, Short pooled-yard acquisition and then a separate
Ash plant comparison. The latter should compare fixed and dynamic regrowth
capacity within the same live/dead stock representation, with exposure and
boundary behaviour resolved before approval. No further
clock/encounter sweep, empirical fitting, additional physiology, plant
compartments or manuscript publication follows automatically from this repair.
