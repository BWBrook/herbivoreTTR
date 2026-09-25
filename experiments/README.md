# Experiments

## Current encounter/policy sensitivity (063)

`feeding-access-sensitivity.R` wraps the unchanged 062 model in the frozen
90-branch design. Five search rates apply from day 1; policy comparisons share
each rate/layout's experienced day-60 baseline. It checks conservation, bounds
and 14 exact historical overlaps. `feeding-access-sensitivity-figures.R` renders
the three-page figure only when given a path. See
[Decision 0063](../docs/decisions/0063-encounter-and-policy-sensitivity.md),
[the design](../docs/feeding-access-sensitivity-specification.md), and
[the analytical ratios](../docs/feeding-access-ratios.md).

From the project root, using the installed project package:

```r
source("experiments/feeding-access-sensitivity.R")
result <- run_feeding_access_sensitivity(cores = 3)
# Optional explicit output; generated evidence remains ignored.
write_feeding_access_sensitivity_outputs(result, "outputs/feeding-access-063",
  "outputs/feeding-access-063/encounter-policy-sensitivity.pdf")
```

The default historical comparison reads `outputs/feeding-access-062/study.rds`.
If that cache is unavailable, `check_reference=FALSE` permits reproduction
without the historical comparison; conservation, bounds and matched-state
checks still run. Direct script execution prints results and writes nothing.

## Retained diagnostic clients

The active experiments are compact, no-write scientific clients of the
installed package:

- `herbivore-core-reference.R` checks the neutral reference, energy
  conservation, and gut transition order.
- `herbivore-core-appetite-forage.R` checks appetite recovery, a binding
  forage ceiling, and repeated lower-quality forage.
- `herbivore-core-implicit-patches.R` checks implicit patch order, movement
  costs, patch-specific food quality, and feeding-duration response.
- `forage-stock-conservation.R` checks isolated standing-biomass accounting
  under balanced turnover, net gain, and net loss.
- `forage-turnover-reference.R` checks positive equilibrium and analytic,
  monotonic recovery from matched low and high standing biomass.
- `forage-availability-boundary.R` maps those turnover trajectories through a
  fixed residual threshold without consumption or depletion.
- `nonspatial-coupled-reference.R` checks density-scaled forage removal, a
  binding residual boundary, and the minimum period-24 coupled reference.
- `nonspatial-animal-load-pulse.R` compares a temporary density pulse with a
  constant-density control and checks depletion, limitation, and recovery.
- `explicit-known-route-movement.R` checks patch-location change, one lost
  feeding hour, incremental movement expenditure, and the accepted Goal 024
  combined outcomes.
- `explicit-prescribed-itinerary.R` checks exact all-stay reduction and one
  two-move round trip with contextual feeding-time loss and energy accounting.
- `explicit-static-patch-acquisition.R` reverses adequate and limited patch
  order under matched travel to check static capacity selection and response.
- `explicit-known-patch-choice.R` checks one feeding-bout stay-versus-move score
  against both prescribed full-model counterfactuals.
- `prescribed-water-source-excursion.R` compares the same two-leg water-source
  trip outside and inside feeding hours, separating route expenditure from
  lost feeding opportunity without adding water physiology.
- `body-water-reference.R` checks isolated deficit, neutral, and surplus
  body-water accounting under fixed ordinary loss.
- `spatial-water-source-benefit.R` adds one stationary drinking hour to the
  accepted two-leg trip while retaining its energy and feeding-time contrasts.
- `hydration-controlled-water-visits.R` applies one daily-opening thirst
  trigger to a familiar source and compares forage water, ordinary loss, route
  cost, and a no-source critical-water positive control.
- `water-constrained-patch-choice.R` composes that trigger with the accepted
  experience-based two-forage-patch system, checks exact water-disabled
  reduction, and exposes water-access stress through separate water, movement,
  forage, and energy accounts.
- `prescribed-evaporative-loss-regimes.R` branches isolated and coupled systems
  after one common baseline into zero, clustered, repeated, diffuse dose-
  matched, and sustained forcing, then compares source travel, hydration,
  energy debt, and recovery without imposing predicted outcome directions.
- `causal-hydration-response.R` compares the frozen daily-opening controller
  with one hourly causal familiar-source response across the same five forcing
  regimes, including prefix identity, late deferral, feeding displacement, and
  an explicit sustained energy boundary.
- `temperature-anticipatory-drinking.R` compares the reactive null with a
  recent-experience 08:00 top-up rule under equal-dose temperature cycles and
  an unannounced phase shift. It checks hourly execution equivalence and
  causality, then reports common-hour costs and bounded slope/memory sensitivity.
- `cost-aware-drinking.R` compares both existing drinking policies with one
  cost-per-refill gate. Prescribed timing/cost controls separate expenditure
  from feeding overlap; 44 branches expose benefit and failure across the same
  temperature histories and bounded slope, memory, and opportunity valuation.
  It checks causal information, thirst priority, and independent stock balances.
- `water-route-expenditure.R` varies source-route expenditure alone across
  five levels, two forage systems, four temperature histories, and three
  drinking policies. Common preconditioning isolates the access intervention;
  per-cost and across-cost common horizons separate policy contrasts from
  termination. Zero-cost trips retain their duration and feeding interruption.
- `spatial-patch-depletion-renewal.R` applies common turnover to two dynamic
  patch stocks and checks local depletion, release, renewal, one fixed transfer,
  and conserved animal-forage accounting.
- `spatial-resource-aware-choice.R` compares full stay and move counterfactuals
  once under mild and severe depletion, separating a perfect-information
  resource benchmark from the biomass-blind static choice.
- `spatial-resource-aware-switch-boundary.R` varies occupied-patch opening
  biomass alone to locate and decompose the oracle's single stay-move boundary.
- `spatial-myopic-resource-choice.R` compares one opening-state intake-rate cue
  with that oracle, localizing premature movement and its realized energy cost.
- `spatial-experienced-adequacy-choice.R` compares the rejected two-day revisit
  clock with one accepted experience-based rule. Last and best patch returns
  recover over elapsed absence, while current adequacy and accumulated energetic
  shortfall prevent premature return and resolve small chronic deficits. Exact
  day-60/day-62 checkpoints, a 305-day baseline, a seven-case one-factor
  acceptance set, and one explicit low-supply stress protect the conclusion.
- `explicit-patch-food-quality.R` holds movement and acquisition limitation
  absent while checking that adequate and lower-quality all-stay patches reduce
  exactly to their accepted non-spatial physiological references.
- `spatial-food-quality-choice-boundary.R` varies current-patch energy density
  alone and compares the minimal patch-quality score with matched full-day stay
  and move counterfactuals, reporting both switch boundaries and realized
  regret.
- `herbivore-core-fixtures.R` supplies the shared physiological reference.
- `water-constrained-fixtures.R` supplies the accepted experiment-level patch,
  memory, thirst, and continuation driver.
- `isolated-hydration-fixtures.R` supplies the matched non-depleting forage
  client, and `reactive-water-visit-fixtures.R` supplies the causal trip planner.
- `hydration-hourly-transition.R` composes public hourly transitions on actual
  state. `temperature-hydration-fixtures.R` supplies the environmental histories,
  experience-based drinking comparisons, independent account checks, and
  common-horizon summaries.

The herbivore and coupled diagnostics source only shared fixture helpers; the
isolated forage diagnostics are independent. No diagnostic sources another
diagnostic, writes output files, or replays the chronological development arc.
Install the package before running them; commands are given in the repository
README.

The former `rebuild-*` scripts were development evidence. Their accepted
conclusions remain in `docs/decisions/`, and their exact source remains in Git
through commit `ab063ce`.

## Area-supported spatial grazing (061)

After `R CMD INSTALL .`, run `Rscript experiments/spatial-grazing-validation.R`
for the integration controls or `Rscript experiments/spatial-grazing-study.R`
for the 16-branch factorial plus five structural controls. The study returns
complete hourly/daily records and explicitly records domain exits. Sourcing
these files defines functions and writes nothing.

For an optional local review artifact:

```r
source("experiments/spatial-grazing-study.R")
source("experiments/spatial-grazing-figures.R")
result <- run_spatial_grazing_study(progress = TRUE)
# Choose an existing local output directory; generated evidence stays out of Git.
plot_spatial_grazing_study(result, "outputs/spatial-grazing-061/condition-and-supply.pdf")
```

The figure shades treatment days 61-144; crosses mark model-domain exits, not
biological deaths. Phase means from stopped runs have different observation
horizons and must not be treated as matched causal contrasts. See
[Decision 0061](../docs/decisions/0061-area-supported-spatial-grazing.md).

## Physical feeding support and access (062)

Use the project-root R session/renv library after `R CMD INSTALL .`.
`Rscript experiments/feeding-access-validation.R` runs memory, integration and
fixed-field refinement controls. `Rscript experiments/feeding-access-study.R`
runs the original frozen 53-branch study and prints compact results. Neither
command writes evidence files. Optional parallel execution and rendering:

```r
source("experiments/feeding-access-study.R")
source("experiments/feeding-access-recovery-followup.R")
source("experiments/feeding-access-figures.R")
result <- run_feeding_access_study(cores = 3L, progress = TRUE)
followup <- run_feeding_access_recovery_followup(result)
# Supply an existing output directory; these explicit calls write PDFs.
plot_feeding_access_study(result, "outputs/feeding-access-062/feeding-support-and-recovery.pdf")
plot_feeding_access_followup(result, followup, "outputs/feeding-access-062/recovery-followup.pdf")
```

The seven-day follow-up is deliberately separate: its dose was declared only
after the original 28-day pulse failed to recover. The main figure shades
days61–88 more darkly and days89–144 lightly. Growth-pulse treatment ends day88,
sustained treatment ends day144; water-access changes reset after day144.
Crosses mark domain exits, not deaths. Pooled-search and zero-transit effects
are not pure component subtractions or upper access bounds. See
[Decision0062](../docs/decisions/0062-physical-feeding-support-and-access.md).

`Rscript --vanilla` bypasses project renv activation; it requires an explicit
path to the intended installed library. The retained runners themselves do not
change library paths or install packages.
