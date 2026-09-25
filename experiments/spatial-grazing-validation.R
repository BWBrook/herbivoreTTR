# Run after installing current package. No files are written.
source("experiments/spatial-grazing-fixtures.R")

validate_spatial_grazing <- function() {
  # Independent long-horizon analytical reduced-production control.
  b <- 1000
  gross <- senescence <- 0
  for (h in seq_len(84 * 24)) {
    p <- herbivoreTTR::step_responsive_forage(b, 2000, .002, .001, .6)
    b <- p$state
    gross <- gross + p$fluxes$growth_kg_dm_ha
    senescence <- senescence + p$fluxes$senescence_kg_dm_ha
  }
  equilibrium <- 2000 * (1 - .001 / (.002 * .6))
  expected <- equilibrium / (1 + (equilibrium / 1000 - 1) *
    exp(-(.002 * .6 - .001) * 84 * 24))
  assert_that(near(b, expected) && near(b - 1000, gross - senescence),
    "84-day reduced-production trajectory and cumulative fluxes")
  responsive <- herbivoreTTR::step_responsive_forage(100, 2000, .002, .001)
  linear <- herbivoreTTR::step_forage_turnover(
    herbivoreTTR::new_forage_biomass_state(100),
    herbivoreTTR::new_forage_turnover_parameters(1000, .001))
  assert_that(responsive$state < linear$state$forage_biomass_kg_dm_ha &&
    responsive$state > 100, "low-biomass renewal differs from constant-production null")

  system <- new_spatial_grazing_system(total_area_ha = 1, grid_side = 1,
    heterogeneous = FALSE)
  stationary <- run_spatial_grazing(system, phase_days = c(2, 2, 2),
    stationary = TRUE)
  ref <- run_appetite_days(system$fixture, number_of_days = 6)
  assert_that(near(stationary$hourly$body_energy_kj,
    ref$hourly$body_energy_reserve_end_kj), "abundant stationary reference")
  assert_that(max(abs(stationary$hourly$energy_balance_kj)) < 1e-8,
    "combined gut-body energy conservation")
  assert_that(max(abs(stationary$hourly$plant_balance_kg_dm)) < 1e-9,
    "landscape forage-intake conservation")
  assert_that(max(abs(stationary$hourly$water_balance_kg)) < 1e-10,
    "body water conservation")

  state <- new_spatial_grazing_state(system)
  state$journey <- list(kind = "water", total_h = 3,
    remaining_h = 3, total_cost_kj = 900, destination = "p1")
  steps <- vector("list", 3)
  for (i in 1:3) {
    steps[[i]] <- spatial_travel_hour(state)
    state <- steps[[i]]$state
  }
  assert_that(is.null(state$journey) && state$patch_id == "p1",
    "water return to origin")
  assert_that(sum(vapply(steps, `[[`, numeric(1), "time_h")) == 3 &&
    sum(vapply(steps, `[[`, numeric(1), "expenditure_kj")) == 900,
    "multihour travel duration and expenditure")
  assert_that(identical(vapply(steps, `[[`, numeric(1), "drinking_available_kg"),
    c(0, 10, 0)), "water available only at source encounter")
  state$journey <- list(kind = "forage", total_h = .25,
    remaining_h = .25, total_cost_kj = 40, destination = "p1")
  fractional <- step_spatial_grazing_hour(state, system, 0, 1,
    stationary = TRUE)
  assert_that(near(fractional$hourly$feeding_h, .75) &&
    near(fractional$hourly$intake_kg_dm, .75 * .020),
    "fractional travel leaves fractional feeding opportunity")

  # An infeasible transition must leave the whole opening record untouched.
  state <- new_spatial_grazing_state(system)
  state$body$body_energy_reserve_kj <- 0
  state$gut$gut_available_energy_kj <- 0
  stopped <- step_spatial_grazing_hour(state, system, 8, 1, stationary = TRUE)
  assert_that(stopped$stopped && identical(stopped$state, state),
    "atomic model-domain exit without artificial reserve floor")
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  validate_spatial_grazing()
  cat("Spatial grazing integration controls passed.\n")
}
