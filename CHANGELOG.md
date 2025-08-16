# Changelog

All notable changes in this module are documented here.

## Module 0 – Baseline Hygiene & Consistency

- geom: unify toroidal distance fn and usage
  - Added roxygen-documented `calc_toroidal_distance(x1, y1, x2, y2, plot_width, plot_height)` in `R/utils.R`.
  - Ensured distance checks in behaviour use the toroidal function (replaced `calc_distance` in `R/herbivore_step.R`).

- constants: fix CONSTANTS$ typos
  - Replaced misspelled `CONSTANT$...` with `CONSTANTS$...` in `R/select_new_plant.R` and `R/make_foraging_decision.R`.

- behaviour: standardise herbivore_step signature and calls
  - Standardised `herbivore_step()` to `(herbivore, plants)`; all scalars now accessed via `herbivore` fields or `CONSTANTS`.
  - Updated call to `get_plants_within_range(herbivore, plants)` to avoid passing unused scalars.
  - Unified distance calculations to `calc_toroidal_distance`.

- docs: update unit comments; utils small tidy
  - Added concise roxygen note to `calc_toroidal_distance()`; ensured `select_randomly()` uses `sample(vec, 1, replace = FALSE)`.
  - Reviewed `init_herbivore()` field comments for unit clarity (g for gut/intakes/water; kJ for energy).

Notes:
- TTR-related functions were not modified per scope.
- Behavioural logic unchanged aside from signature standardisation and deterministic distance geometry.

## Module 2 – TTR Helpers & Resistances

- ttr_forcing: implement pure helpers (trap1, trap2, monod, calc_SWforcer)
  - Vectorized, bounded [0,1], guards for zero-width and zero denominators.
- ttr_resistance: implement resistances (calc_RsC, calc_RrC, calc_RdC, calc_RsN, calc_RrN, calc_RdN)
  - Guard Ms/Mr/Md <= 0 by returning capped large values (finite) to mimic limiting behavior without Inf/NaN.
  - Ensure non-negative, unitless outputs; vectorized across inputs.
- tests: add comprehensive unit tests for helpers and resistances
  - Verify bounds, vectorization, and robustness for zero-mass/edge cases.

Rationale: Provide numerically robust, deterministic math primitives used by TTR while matching C++ shape and avoiding NaN/Inf.

## Hygiene Pass – Loading safety and naming consistency

- constants: fix self-reference in `CONSTANTS` (compute `PLANTS_PER_PLOT` after list construction) to avoid "object not found" on source.
- utils/behaviour: standardize defence biomass column to `bdef` across functions (`calc_plant_tastiness`, `select_new_plant`, `herbivore_eat`).
- dplyr usage: replace unqualified `%>%`, `filter`, `mutate`, `rowwise`, `ungroup` with `dplyr::`-qualified calls.
- packages: remove top-level installation/attach side-effects from `R/packages.R`; provide `ensure_packages_installed()` and `lib()` helpers only.
- options: wrap global side-effects into `init_project_options()` in `R/options.R` (no auto-execution).
- main script: move `R/main.R` to `inst/scripts/main.R` to keep package load path clean.
- tests: add `tests/testthat/test_hygiene.R` to validate constants derivation, helper availability, and tastiness computation with `bdef`.

## Module 3 — TTR Transport, Uptake, Growth, and RHS

- Implemented pure, rowwise functions matching C++ logic:
  - ttr_transport: `calc_tauC`, `calc_tauN`, `calc_tauCd`, `calc_tauNd` with guards for zero masses and zero total resistance (return 0 to avoid division errors).
  - ttr_uptake_growth: `calc_UC`, `calc_UN`, `sf`, `calc_Gs`, `calc_Gr`, `calc_Gd`, and ODE RHS terms `calc_dCs_dt`, `calc_dCr_dt`, `calc_dCd_dt`, `calc_dNs_dt`, `calc_dNr_dt`, `calc_dNd_dt`.
  - Functions ensure finite outputs and respect kg/day semantics per C++.
- Added tests verifying finiteness, boundedness, vectorization, and correct sign behavior for toy cases.
  - `tests/testthat/test_ttr_transport_growth.R`.

Rationale: Complete core TTR math with robust guards, mirroring the reference C++ while ensuring safe numeric behavior for zero/edge cases.
