# Experiments

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
