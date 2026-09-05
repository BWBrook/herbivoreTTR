source("experiments/temperature-hydration-fixtures.R")

check_near <- function(observed, expected, tolerance = 1e-9) {
  if (length(expected) == 1L) expected <- rep(expected, length(observed))
  stopifnot(near(observed, expected, tolerance))
}

check_hydration_accounts <- function(run) {
  x <- run$hourly
  stopifnot(nrow(x) > 0L)
  check_near(x$system_energy_balance_residual_kj, 0, tolerance = 1e-8)
  check_near(x$body_water_balance_residual_kg, 0, tolerance = 1e-12)
  check_near(x$max_forage_balance_residual_kg_dm_ha, 0, tolerance = 1e-10)
  check_near(x$herbivore_forage_coupling_residual_kg_dm_ha, 0, tolerance = 1e-10)
  stopifnot(all(x$body_energy_reserve_end_kj >= 0),
    all(x$body_water_end_kg >= 0), all(x$body_water_end_kg <= 28 + 1e-12),
    all(tapply(x$water_departure, x$day, sum) <= 1L))
  for (field in c("body_energy_reserve", "gut_available_energy")) {
    check_near(head(x[[paste0(field, "_end_kj")]], -1),
      tail(x[[paste0(field, "_start_kj")]], -1))
  }
  check_near(head(x$body_water_end_kg, -1), tail(x$body_water_start_kg, -1))
  start <- run$initial_context$state
  net_input <- sum(x$realized_ingested_available_energy_kj -
    x$maintenance_expenditure_kj - x$prescribed_routine_activity_expenditure_kj -
    x$incremental_movement_expenditure_kj)
  check_near(tail(x$body_energy_reserve_end_kj + x$gut_available_energy_end_kj, 1) -
    start$body$body_energy_reserve_kj - start$gut$gut_available_energy_kj,
    net_input, tolerance = 1e-7)
  check_near(tail(x$body_water_end_kg, 1) - start$water$body_water_kg,
    sum(x$food_derived_water_kg + x$realized_drinking_water_kg -
      x$ordinary_water_loss_kg - x$incremental_evaporative_water_loss_kg -
      x$excess_water_elimination_kg), tolerance = 1e-10)
  departures <- which(x$water_departure)
  for (i in departures[departures + 2L <= nrow(x)]) {
    trip <- x[i + 0:2, ]
    stopifnot(identical(trip$spatial_action, c("move", "stay", "move")),
      trip$closing_patch_id[[3L]] == trip$opening_patch_id[[1L]])
    check_near(sum(trip$incremental_movement_expenditure_kj), 1800)
  }
  invisible(TRUE)
}

check_hydration_prescribed_equivalence <- function(kind, water_trip) {
  system <- new_hydration_system(kind)
  state <- new_hydration_context(kind)$state
  state$water <- herbivoreTTR::new_body_water_state(26)
  itinerary <- if (kind == "isolated")
    new_isolated_hydration_itinerary(water_trip) else
    new_water_constrained_itinerary("patch_a", "patch_b", "move", water_trip)
  arguments <- list(initial_location_state = state$location,
    landscape = system$landscape, itinerary = itinerary,
    initial_gut_state = state$gut, initial_body_state = state$body,
    gut_parameters = system$fixture$gut, body_parameters = system$fixture$body,
    appetite_parameters = system$fixture$appetite,
    appetite_reference_schedule = system$fixture$appetite_reference,
    routine_activity_schedule = system$fixture$activity)
  if (kind == "coupled") {
    arguments$initial_spatial_forage_state <- state$forage_state
    arguments$forage_turnover_parameters <- system$forage_parameters
    arguments$coupling_parameters <- system$coupling_parameters
  }
  energy <- do.call(if (kind == "isolated")
    herbivoreTTR::run_prescribed_spatial_energy_day else
    herbivoreTTR::run_prescribed_spatial_coupled_energy_day, arguments)
  loss <- hydration_evaporation_kg_h(hydration_temperature_cycle_c())
  water <- herbivoreTTR::run_spatial_body_water_day(state$water,
    system$water_parameters, system$water_properties, energy$hourly, loss)
  rows <- vector("list", 24L)
  for (i in seq_len(24L)) {
    step <- hydration_step_hour(state, system, itinerary$prescribed_closing_patch_id[[i]],
      i - 1L, loss[[i]])
    state <- step$context
    rows[[i]] <- step$hourly
  }
  x <- do.call(rbind, rows)
  check_near(x$realized_dry_matter_intake_kg_dm,
    energy$hourly$realized_dry_matter_intake_kg_dm_h)
  for (field in c("gut_available_energy_end_kj", "body_energy_reserve_end_kj",
    "incremental_movement_expenditure_kj")) check_near(x[[field]], energy$hourly[[field]])
  check_near(x$body_water_end_kg, water$hourly$body_water_end_kg)
  if (kind == "coupled") check_near(state$forage_state$forage_biomass_kg_dm_ha,
    energy$final_state$forage$forage_biomass_kg_dm_ha)
  invisible(TRUE)
}

for (kind in c("isolated", "coupled")) {
  for (trip in c(FALSE, TRUE)) check_hydration_prescribed_equivalence(kind, trip)
}
check_near(hydration_evaporation_kg_h(c(24, 30)), c(0, 0))
check_near(sum(hydration_evaporation_kg_h(hydration_temperature_cycle_c())), 0.44)
check_near(sum(hydration_evaporation_kg_h(hydration_temperature_cycle_c(20))), 0.44)
check_near(hydration_evaporation_kg_h(hydration_temperature_cycle_c(), 0), rep(0, 24))
forecast <- hydration_anticipatory_decision(27, rep(0.05, 48))
check_near(forecast$projected_body_water_kg, 25.75)
stopifnot(forecast$depart,
  !hydration_anticipatory_decision(27, rep(0.05, 23))$depart)

# Deliberately extreme unit probe: a later impossible no-trip water day must
# not stop a feasible earlier observed-thirst response. This is not a scenario.
probe_system <- new_hydration_system("isolated")
probe_system$water_parameters <- herbivoreTTR::new_body_water_parameters(28, 0, 1.4)
probe <- run_temperature_hydration(probe_system, matrix(30, 1, 24))
stopifnot(is.null(probe$terminal), nrow(probe$hourly) == 24L,
  any(probe$hourly$water_departure))
no_trip <- new_hydration_context("isolated")$state
no_trip_error <- tryCatch({
  for (hour in 0:23) no_trip <- hydration_step_hour(no_trip, probe_system,
    "forage_patch", hour, 0)$context
  NA_character_
}, error = conditionMessage)
stopifnot(identical(no_trip_error,
  "The proposed closing body-water stock is negative."))

preconditions <- list()
for (kind in c("isolated", "coupled")) {
  preconditions[[kind]] <- run_temperature_hydration(new_hydration_system(kind),
    matrix(30, 60L, 24L))
  check_hydration_accounts(preconditions[[kind]])
  stopifnot(is.null(preconditions[[kind]]$terminal))
  previous <- if (kind == "isolated") run_isolated_hydration_days("control", 60L)
    else run_water_constrained_closed_loop(list(scenario = "control",
      scenario_role = "reduction", water_layer_active = TRUE,
      water_movement_expenditure_per_leg_kj = 900,
      food_water_yield_kg_water_kg_dm = 3.28, daily_ordinary_water_loss_kg = 1.56), 60L)
  new <- preconditions[[kind]]$daily
  check_near(new$closing_body_energy_reserve_kj, previous$closing_body_energy_reserve_kj)
  check_near(new$closing_body_water_kg, previous$closing_body_water_kg)
  stopifnot(identical(as.logical(new$water_trips), previous$water_visit))
}

past <- preconditions$isolated$final_context
future_a <- matrix(30, 1L, 24L)
future_b <- future_a
future_b[1L, 11:24] <- 36
a <- run_temperature_hydration(new_hydration_system("isolated"), future_a,
  "anticipatory", past)
b <- run_temperature_hydration(new_hydration_system("isolated"), future_b,
  "anticipatory", past)
stopifnot(identical(a$hourly[1:10, ], b$hourly[1:10, ]))

hydration_runs <- list()
hydration_comparisons <- list()
run_pair <- function(kind, history, slope = 1, memory = 24L) {
  pair <- list()
  for (policy in c("reactive", "anticipatory")) {
    key <- paste(kind, history, slope, if (policy == "reactive") 24L else memory,
      policy, sep = "/")
    if (is.null(hydration_runs[[key]])) {
      run <- run_temperature_hydration(new_hydration_system(kind),
        hydration_temperature_history(history), policy,
        preconditions[[kind]]$final_context, slope, memory)
      check_hydration_accounts(run)
      hydration_runs[[key]] <<- run
      message(key, ": ", nrow(run$hourly), " completed hours")
    }
    pair[[policy]] <- hydration_runs[[key]]
  }
  summary <- hydration_pair_summary(pair$reactive, pair$anticipatory)
  check_near(summary$combined_energy_advantage_kj,
    summary$intake_energy_difference_kj - summary$movement_cost_difference_kj,
    tolerance = 1e-7)
  cbind(system = kind, history = history, slope_multiplier = slope,
    memory_hours = memory, summary)
}
for (kind in c("isolated", "coupled")) {
  for (history in c("null", "midday", "evening", "phase_shift")) {
    key <- paste(kind, history, sep = "/")
    hydration_comparisons[[key]] <- run_pair(kind, history)
  }
}
for (history in c("midday", "phase_shift")) {
  for (slope in c(0.5, 1.5)) hydration_comparisons[[paste(history, slope)]] <-
    run_pair("coupled", history, slope)
  for (memory in c(12L, 48L)) hydration_comparisons[[paste(history, memory)]] <-
    run_pair("coupled", history, memory = memory)
}
hydration_comparisons <- do.call(rbind, hydration_comparisons)
row.names(hydration_comparisons) <- NULL
display <- hydration_comparisons[, c("system", "history", "slope_multiplier",
  "memory_hours", "common_hours", "reactive_trips", "anticipatory_trips",
  "body_energy_advantage_kj")]
display$body_energy_advantage_kj <- round(display$body_energy_advantage_kj)
print(display, row.names = FALSE)
cat("Temperature and anticipatory-drinking checks passed. Benefits are not test gates.\n")
