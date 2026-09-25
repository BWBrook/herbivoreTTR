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

## Next review boundary

Ask Fable to assess the bounded intervention and the corrected evidence mapping.
Then specify coherent animal/plant and observation contracts for the two
anchors, including the residual/search relationship and a justified grazed
initialization. Retrieving Short's full methods is necessary before using its
fitted coefficients. No further clock/encounter sweep, empirical fitting,
additional physiology, plant compartments or manuscript publication follows
automatically from this repair.
