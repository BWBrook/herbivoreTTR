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
- `herbivore-core-fixtures.R` supplies their shared synthetic reference.

The herbivore diagnostics source only the fixture helper; the forage diagnostic
is independent. No diagnostic sources another diagnostic, writes output files,
or replays the chronological development arc. Install the package before
running them; commands are given in the repository README.

The former `rebuild-*` scripts were development evidence. Their accepted
conclusions remain in `docs/decisions/`, and their exact source remains in Git
through commit `ab063ce`.
