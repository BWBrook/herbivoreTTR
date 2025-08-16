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
