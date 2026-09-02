source("experiments/water-constrained-fixtures.R")

precondition_days <- 60L
treatment_days <- 84L
recovery_days <- 42L
branch_days <- treatment_days + recovery_days
event_increment_kg_day <- 0.44
regime_names <- c(
  "control",
  "clustered",
  "repeated",
  "diffuse_dose_control",
  "sustained"
)

new_regime_calendar <- function(regime) {
  calendar <- rep(0, branch_days)
  if (regime == "clustered") {
    calendar[36:49] <- event_increment_kg_day
  } else if (regime == "repeated") {
    event_days <- unlist(lapply(
      c(1L, 13L, 25L, 37L, 49L, 61L, 73L),
      function(start_day) start_day + 0:1
    ))
    calendar[event_days] <- event_increment_kg_day
  } else if (regime == "diffuse_dose_control") {
    calendar[seq_len(treatment_days)] <-
      event_increment_kg_day * 14 / treatment_days
  } else if (regime == "sustained") {
    calendar[seq_len(treatment_days)] <- event_increment_kg_day
  } else if (regime != "control") {
    stop("Unknown prescribed evaporative-loss regime.")
  }
  calendar
}

forcing_calendars <- setNames(
  lapply(regime_names, new_regime_calendar),
  regime_names
)

isolated_forage_patch_id <- "forage_patch"
isolated_water_source_patch_id <- "water_source"

new_isolated_landscape <- function() {
  herbivoreTTR::new_known_route_landscape(
    patch_id = c(
      isolated_forage_patch_id,
      isolated_water_source_patch_id
    ),
    forage_acquisition_ceiling_kg_dm_h = c(0.025, 0),
    route_origin_patch_id = c(
      isolated_forage_patch_id,
      isolated_water_source_patch_id
    ),
    route_destination_patch_id = c(
      isolated_water_source_patch_id,
      isolated_forage_patch_id
    ),
    incremental_movement_expenditure_kj = rep(900, 2L),
    metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
  )
}

isolated_water_properties <- herbivoreTTR::new_patch_water_properties(
  patch_id = c(isolated_forage_patch_id, isolated_water_source_patch_id),
  food_derived_water_yield_kg_water_kg_dm = c(3.28, 0),
  drinking_water_availability_kg_h = c(0, 10)
)
isolated_water_parameters <- herbivoreTTR::new_body_water_parameters(
  28,
  24,
  1.56 / 24
)

new_isolated_context <- function() {
  list(
    simulation_day = 0L,
    state = list(
      location = herbivoreTTR::new_patch_location_state(
        isolated_forage_patch_id
      ),
      gut = water_constrained_fixture$opening_gut,
      body = water_constrained_fixture$opening_body,
      water = herbivoreTTR::new_body_water_state(28)
    )
  )
}

new_isolated_itinerary <- function(visit_water) {
  closing_patch_id <- rep(isolated_forage_patch_id, 24L)
  if (visit_water) {
    closing_patch_id[
      water_constrained_fixture$hour_of_day %in% c(8L, 9L)
    ] <- isolated_water_source_patch_id
  }
  herbivoreTTR::new_prescribed_patch_itinerary(
    water_constrained_fixture$hour_of_day,
    closing_patch_id
  )
}

run_isolated_days <- function(
  regime,
  number_of_days,
  initial_context = NULL,
  incremental_evaporative_loss_kg_day = rep(0, number_of_days)
) {
  context <- if (is.null(initial_context)) {
    new_isolated_context()
  } else {
    initial_context
  }
  initial_simulation_day <- context$simulation_day
  state <- context$state
  landscape <- new_isolated_landscape()
  daily_rows <- vector("list", number_of_days)
  completed_days <- 0L
  terminal_day <- NA_integer_
  terminal_reason <- NA_character_

  for (local_day in seq_len(number_of_days)) {
    simulation_day <- initial_simulation_day + local_day
    opening_water_kg <- state$water$body_water_kg
    thirst_triggered <- opening_water_kg <= 26
    incremental_loss_hourly <- new_daily_evaporative_loss_schedule(
      incremental_evaporative_loss_kg_day[[local_day]]
    )
    day_error <- NULL
    day <- tryCatch({
      energy <- herbivoreTTR::run_prescribed_spatial_energy_day(
        initial_location_state = state$location,
        landscape = landscape,
        itinerary = new_isolated_itinerary(thirst_triggered),
        initial_gut_state = state$gut,
        initial_body_state = state$body,
        gut_parameters = water_constrained_fixture$gut,
        body_parameters = water_constrained_fixture$body,
        appetite_parameters = water_constrained_fixture$appetite,
        appetite_reference_schedule =
          water_constrained_fixture$appetite_reference,
        routine_activity_schedule = water_constrained_fixture$activity
      )
      water <- herbivoreTTR::run_spatial_body_water_day(
        initial_state = state$water,
        parameters = isolated_water_parameters,
        patch_water_properties = isolated_water_properties,
        spatial_energy_hourly = energy$hourly,
        prescribed_incremental_evaporative_water_loss_kg_h =
          incremental_loss_hourly
      )
      list(energy = energy, water = water)
    }, error = function(error) {
      day_error <<- conditionMessage(error)
      NULL
    })
    if (is.null(day)) {
      terminal_day <- simulation_day
      terminal_reason <- day_error
      break
    }

    accounts_close <-
      max(abs(
        day$energy$hourly$system_energy_balance_residual_kj
      )) < 1e-8 &&
        abs(day$energy$daily$system_energy_balance_residual_kj) < 1e-8 &&
        max(abs(
          day$water$hourly$body_water_balance_residual_kg
        )) < 1e-12 &&
        abs(day$water$daily$body_water_balance_residual_kg) < 1e-12
    daily_rows[[local_day]] <- data.frame(
      regime = regime,
      simulation_day = simulation_day,
      opening_body_water_kg = opening_water_kg,
      thirst_triggered = thirst_triggered,
      water_visit = thirst_triggered,
      food_derived_water_kg =
        day$water$daily$total_food_derived_water_kg,
      drinking_water_kg =
        day$water$daily$total_realized_drinking_water_kg,
      ordinary_water_loss_kg =
        day$water$daily$total_ordinary_water_loss_kg,
      incremental_evaporative_water_loss_kg =
        day$water$daily$total_incremental_evaporative_water_loss_kg,
      closing_body_water_kg = day$water$daily$body_water_final_kg,
      body_water_below_critical =
        day$water$daily$body_water_below_critical,
      realized_intake_kg_dm =
        day$energy$daily$realized_dry_matter_intake_kg_dm,
      movement_expenditure_kj =
        day$energy$daily$total_incremental_movement_expenditure_kj,
      closing_body_energy_reserve_kj =
        day$energy$daily$body_energy_reserve_final_kj,
      accounts_close = accounts_close,
      row.names = NULL
    )
    state <- list(
      location = herbivoreTTR::new_patch_location_state(
        day$energy$daily$final_patch_id
      ),
      gut = herbivoreTTR::new_gut_energy_state(
        day$energy$daily$gut_available_energy_final_kj
      ),
      body = herbivoreTTR::new_body_energy_state(
        day$energy$daily$body_energy_reserve_final_kj
      ),
      water = day$water$final_state
    )
    completed_days <- local_day
    if (day$water$daily$body_water_below_critical) {
      terminal_day <- simulation_day
      terminal_reason <-
        "body water crossed the declared critical boundary"
      break
    }
  }

  result <- if (completed_days > 0L) {
    do.call(rbind, daily_rows[seq_len(completed_days)])
  } else {
    data.frame()
  }
  attr(result, "completed_days") <- completed_days
  attr(result, "terminal_day") <- terminal_day
  attr(result, "terminal_reason") <- terminal_reason
  attr(result, "final_context") <- list(
    simulation_day = initial_simulation_day + completed_days,
    state = state
  )
  result
}

summarize_regime_runs <- function(runs) {
  control <- runs$control
  do.call(rbind, lapply(regime_names, function(regime) {
    run <- runs[[regime]]
    completed_days <- attr(run, "completed_days")
    treatment_end <- min(treatment_days, completed_days)
    energy_debt_treatment_end_kj <- if (treatment_end == treatment_days) {
      control$closing_body_energy_reserve_kj[[treatment_days]] -
        run$closing_body_energy_reserve_kj[[treatment_days]]
    } else {
      NA_real_
    }
    energy_debt_recovery_end_kj <- if (completed_days == branch_days) {
      tail(control$closing_body_energy_reserve_kj, 1L) -
        tail(run$closing_body_energy_reserve_kj, 1L)
    } else {
      NA_real_
    }
    food_patch_switches <- if ("food_patch_action" %in% names(run)) {
      sum(run$food_patch_action == "move")
    } else {
      NA_integer_
    }
    control_food_patch_switches <- if (
      "food_patch_action" %in% names(control)
    ) {
      sum(control$food_patch_action == "move")
    } else {
      NA_integer_
    }
    water_visits <- sum(run$water_visit)
    control_water_visits <- sum(control$water_visit)

    data.frame(
      regime = regime,
      completed_days = completed_days,
      terminal_day = attr(run, "terminal_day"),
      forcing_days = sum(
        run$incremental_evaporative_water_loss_kg > 0
      ),
      incremental_evaporative_water_loss_kg = sum(
        run$incremental_evaporative_water_loss_kg
      ),
      water_visits = water_visits,
      additional_water_visits =
        water_visits - control_water_visits,
      water_source_travel_expenditure_kj = water_visits * 1800,
      additional_water_source_travel_expenditure_kj =
        (water_visits - control_water_visits) * 1800,
      food_patch_switches = food_patch_switches,
      additional_food_patch_switches =
        food_patch_switches - control_food_patch_switches,
      movement_expenditure_kj = sum(run$movement_expenditure_kj),
      additional_movement_expenditure_kj =
        sum(run$movement_expenditure_kj) -
          sum(control$movement_expenditure_kj),
      minimum_body_water_kg = min(run$closing_body_water_kg),
      minimum_body_energy_reserve_kj = min(
        run$closing_body_energy_reserve_kj
      ),
      energy_debt_treatment_end_kj = energy_debt_treatment_end_kj,
      energy_debt_recovery_end_kj = energy_debt_recovery_end_kj,
      energy_debt_recovered_kj =
        energy_debt_treatment_end_kj - energy_debt_recovery_end_kj,
      critical_water_crossed = any(run$body_water_below_critical),
      all_accounts_close = all(run$accounts_close),
      row.names = NULL
    )
  }))
}

isolated_precondition <- run_isolated_days(
  "common_baseline",
  precondition_days
)
isolated_context <- attr(isolated_precondition, "final_context")
isolated_runs <- setNames(lapply(regime_names, function(regime) {
  run_isolated_days(
    regime,
    branch_days,
    isolated_context,
    forcing_calendars[[regime]]
  )
}), regime_names)
isolated_summary <- summarize_regime_runs(isolated_runs)

integrated_baseline_scenario <- data.frame(
  scenario = "common_baseline",
  scenario_role = "precondition",
  water_layer_active = TRUE,
  food_water_yield_kg_water_kg_dm = 3.28,
  daily_ordinary_water_loss_kg = 1.56,
  water_movement_expenditure_per_leg_kj = 900,
  stringsAsFactors = FALSE
)
integrated_precondition <- run_water_constrained_closed_loop(
  integrated_baseline_scenario,
  precondition_days
)
integrated_context <- attr(integrated_precondition, "final_context")
integrated_runs <- setNames(lapply(regime_names, function(regime) {
  scenario <- integrated_baseline_scenario
  scenario$scenario <- regime
  scenario$scenario_role <- "prescribed_evaporative_regime"
  run_water_constrained_closed_loop(
    scenario,
    branch_days,
    integrated_context,
    forcing_calendars[[regime]]
  )
}), regime_names)
integrated_summary <- summarize_regime_runs(integrated_runs)

matched_dose_regimes <- c(
  "clustered",
  "repeated",
  "diffuse_dose_control"
)
matched_dose_kg <- event_increment_kg_day * 14
assert_that(
  near(
    vapply(
      forcing_calendars[matched_dose_regimes],
      sum,
      numeric(1L)
    ),
    rep(matched_dose_kg, length(matched_dose_regimes))
  ) &&
    all(forcing_calendars$control == 0) &&
    identical(
      vapply(
        forcing_calendars,
        function(calendar) sum(calendar > 0),
        integer(1L)
      ),
      c(
        control = 0L,
        clustered = 14L,
        repeated = 14L,
        diffuse_dose_control = 84L,
        sustained = 84L
      )
    ) &&
    all(forcing_calendars$sustained[seq_len(treatment_days)] ==
      event_increment_kg_day) &&
    all(vapply(
      forcing_calendars,
      function(calendar) all(calendar[(treatment_days + 1L):branch_days] == 0),
      logical(1L)
    )),
  "the five predeclared forcing calendars have the intended doses and recovery"
)
assert_that(
  attr(isolated_precondition, "completed_days") == precondition_days &&
    attr(integrated_precondition, "completed_days") == precondition_days &&
    all(isolated_precondition$accounts_close) &&
    all(integrated_precondition$accounts_close),
  "both systems complete one common 60-day precondition with closed accounts"
)
assert_that(
  all(isolated_summary$all_accounts_close) &&
    all(integrated_summary$all_accounts_close) &&
    near(
      isolated_summary$incremental_evaporative_water_loss_kg,
      vapply(forcing_calendars, sum, numeric(1L))
    ) &&
    near(
      integrated_summary$incremental_evaporative_water_loss_kg,
      vapply(forcing_calendars, sum, numeric(1L))
    ) &&
    isolated_summary$incremental_evaporative_water_loss_kg[
      isolated_summary$regime == "control"
    ] == 0 &&
    integrated_summary$incremental_evaporative_water_loss_kg[
      integrated_summary$regime == "control"
    ] == 0,
  paste0(
    "the branched treatments apply their exact doses, preserve separate ",
    "closed accounts, and retain an exact zero control"
  )
)

cat("Prescribed evaporative-loss regime diagnostic passed.\n")
cat("\nIsolated non-depleting forage system:\n")
print(transform(
  isolated_summary,
  incremental_evaporative_water_loss_kg =
    round(incremental_evaporative_water_loss_kg, 2),
  water_source_travel_expenditure_kj =
    round(water_source_travel_expenditure_kj),
  additional_water_source_travel_expenditure_kj =
    round(additional_water_source_travel_expenditure_kj),
  movement_expenditure_kj = round(movement_expenditure_kj),
  additional_movement_expenditure_kj =
    round(additional_movement_expenditure_kj),
  minimum_body_water_kg = round(minimum_body_water_kg, 2),
  minimum_body_energy_reserve_kj = round(minimum_body_energy_reserve_kj),
  energy_debt_treatment_end_kj = round(energy_debt_treatment_end_kj),
  energy_debt_recovery_end_kj = round(energy_debt_recovery_end_kj),
  energy_debt_recovered_kj = round(energy_debt_recovered_kj)
), row.names = FALSE)
cat("\nAccepted water-constrained patch system:\n")
print(transform(
  integrated_summary,
  incremental_evaporative_water_loss_kg =
    round(incremental_evaporative_water_loss_kg, 2),
  water_source_travel_expenditure_kj =
    round(water_source_travel_expenditure_kj),
  additional_water_source_travel_expenditure_kj =
    round(additional_water_source_travel_expenditure_kj),
  movement_expenditure_kj = round(movement_expenditure_kj),
  additional_movement_expenditure_kj =
    round(additional_movement_expenditure_kj),
  minimum_body_water_kg = round(minimum_body_water_kg, 2),
  minimum_body_energy_reserve_kj = round(minimum_body_energy_reserve_kj),
  energy_debt_treatment_end_kj = round(energy_debt_treatment_end_kj),
  energy_debt_recovery_end_kj = round(energy_debt_recovery_end_kj),
  energy_debt_recovered_kj = round(energy_debt_recovered_kj)
), row.names = FALSE)
