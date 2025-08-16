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

## Module 4 — TTR Orchestrator: transport_resistance()

- Implemented full per-day TTR update in `R/ttr_daily.R`:
  - Computes environmental forcing from `conditions` via `calc_SWforcer`, `trap2`, `monod`.
  - Calculates resistances (shoot/root), transport (tauC, tauN), uptake (UC/UN), and growth (Gs/Gr) with robust guards.
  - Applies litter losses with phenology switch; updates C/N pools and structural masses; updates `bleaf`, `bstem`, `bdef`, `brepr`, and `broot`, and recomputes `ms`.
  - Defence transport/growth/pools are disabled to mirror the C++ code path.
- Added TTR constants to `R/constants.R` mirroring C++ (K_LITTER, K_M_LITTER, G_*, K_*, PI_*, Q_SCP, TR_*, FRACTION_*, TEMP_* envelopes, PHENO_SWITCH, ACCEL_LEAF_LOSS).
- Tests: `tests/testthat/test_ttr_daily.R` ensures finiteness and non-negativity of masses after one-day update on a toy case.
  - `tests/testthat/test_ttr_wire.R` verifies `run_daily_herbivore_simulation()` calls the orchestrator by asserting new columns (`uc`, `gs`) are present with non-negative masses.

Rationale: Wire together the previously implemented pure functions to perform a daily plant update consistent with the reference C++ algorithm.

## Module 5 — Herbivore–Plant Interface Fixes (Units & Behaviour)

- Units: Standardised kg↔g conversions at the interface:
  - `herbivore_eat()` now decrements plant masses in kg and pushes intakes to gut vectors in grams; updates `gut_content` accordingly.
  - Capacity checks use gut in g; available capacity converted to kg for intake calculations.
- Behaviour: Finalised step logic and filters:
  - `herbivore_step()` delegates consumption to `herbivore_eat()`, enforces capacity tolerance, and adds ~10% re-target probability while moving.
  - `get_plants_within_range()` enforces browse height constraint for browsers (`LEAF_HEIGHT * height <= BROWSE_HEIGHT`).
- Tests: Added `tests/testthat/test_module5_interface.R` covering kg↔g consistency, browser filter, and step consumption bounds.

Rationale: Ensure consistent units across herbivore–plant interactions and align behaviour with specification while maintaining deterministic operation.

## Module 6 — Daily Loop Integration (Spin-up, Orchestration)

- Added `CONSTANTS$HERBIVORY` control and integrated a spin-up gate in `run_daily_herbivore_simulation()`:
  - Runs `transport_resistance()` every day before any herbivory.
  - Skips the minute-by-minute herbivory loop during spin-up days (SPIN_UP_LENGTH × days_in_year) or when HERBIVORY == 0.
  - Preserves existing temperature-scaled water requirement logic after minute loops.
- Tests:
  - `tests/testthat/test_spinup_integration.R` demonstrates no intake/movement during spin-up and observable intake plus plant mass reduction post spin up (under no-growth conditions).

Rationale: Cleanly orchestrate plant growth and herbivory with a controllable spin-up phase, matching the original model sequencing.

## Module 7 — Constants Audit for TTR (Add & Document)

- Added missing TTR constants to `R/constants.R` with inline unit documentation:
  `K_LITTER`, `K_M_LITTER`, `G_SHOOT`, `G_ROOT`, `G_DEFENCE`, `K_C`, `K_N`, `K_M`,
  `PI_C`, `PI_N`, `Q_SCP`, `TR_C`, `TR_N`, `FRACTION_C`, `FRACTION_N`, `PHENO_SWITCH`,
  `ACCEL_LEAF_LOSS`, `INIT_SW`, `INIT_N`, `TEMP_GROWTH_1..4`, `TEMP_PHOTO_1..4`.
- Confirmed usage in TTR functions (`ttr_daily.R`, `ttr_uptake_growth.R`, `ttr_transport.R`).
- Tests: `tests/testthat/test_constants_audit.R` asserts presence and numeric finiteness.

Rationale: Ensure R implementation mirrors C++ constants with clear units, preventing missing-constant errors and aiding maintainability.

## Module 8 — Output Writers for Parity (Optional)

- Added `R/io_write.R` with:
  - `write_plants_daily(plants, day, year, path)` producing semicolon-delimited CSV with exact header order: `Year;Day;Plant;VegType;Height;BLeaf;BStem;BDef;Ms;Ns;Cs;Mr;Cr;Nr`.
  - `write_herbivores_daily(herbivore, day, year, path)` with exact header order: `Year;Day;HerbType;Mass;xcor;ycor;DailyDistMoved;DailyPEI;DailyNPEI;DailyDMI;DailyForageWater;TotalDMI;WaterBalance;EnergyBalance`.
  - Strict validation: required columns present, all values finite, no NA/Inf/NaN; overwrite files; UTF-8; headers always included.
- Tests: `tests/testthat/test_io_write.R` verifies headers, delimiters, finiteness, and error on invalid input.

Rationale: Enable diff-style parity checks between R and reference C++ outputs.

## Module 9 — Tests & Smoke Validation

- Added smoke and regression tests under `tests/testthat/`:
  - Helper/math coverage already present (bounds, finiteness, zero-mass guards).
  - Interface test ensures a single-minute eat event reduces plant mass by Δ kg and increases gut by Δ×1000 g.
  - Daily run tests for 1 day and 7 days: energy/water balances finite; plant biomass non-negative; pools remain finite and bounded.
  - Spin-up vs post-spin-up behaviour validated.

Rationale: Provide a minimal, fast harness to catch regressions while wiring the model.

## DevOps — renv + pak bootstrap and DESCRIPTION newline

- Fix: ensure DESCRIPTION ends with a newline to silence renv::status() warning.
- Configure renv autoloader to prefer pak as the package manager by setting
  `options(renv.config.pak.enabled = TRUE)` and `RENV_CONFIG_PAK_ENABLED=TRUE` in `renv/activate.R`.

Rationale: Improve developer experience by removing spurious warnings and enabling fast installs via pak.

## Docs — Closure Tests Protocol

- Added `docs/closure_tests.md` outlining unit sanity, integration, and determinism tests for validating parity with the C++ implementation.

Rationale: Provide a concise, versioned protocol for end-to-end verification and future regression triage.

## Docs — Developer Quickstart

- Added `docs/README-dev.md` with a compact guide for renv bootstrap, running tests, executing the minimal {targets} pipeline, and producing parity CSVs.

Rationale: Help collaborators get productive quickly with consistent, reproducible project workflows.
