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
- `spatial-daily-myopic-choice.R` applies that cue once daily under a low-load
  reference and matched 305-day pressure treatments, comparing equal patch
  quality with one lower-quality patch for switching, oracle regret,
  physiological state, and animal-forage accounting.
- `explicit-patch-food-quality.R` holds movement and acquisition limitation
  absent while checking that adequate and lower-quality all-stay patches reduce
  exactly to their accepted non-spatial physiological references.
- `spatial-food-quality-choice-boundary.R` varies current-patch energy density
  alone and compares the minimal patch-quality score with matched full-day stay
  and move counterfactuals, reporting both switch boundaries and realized
  regret.
- `herbivore-core-fixtures.R` supplies their shared synthetic reference.

The herbivore and coupled diagnostics source only the fixture helper; the
isolated forage diagnostics are independent. No diagnostic sources another
diagnostic, writes output files, or replays the chronological development arc.
Install the package before running them; commands are given in the repository
README.

The former `rebuild-*` scripts were development evidence. Their accepted
conclusions remain in `docs/decisions/`, and their exact source remains in Git
through commit `ab063ce`.
