source("experiments/isolated-hydration-fixtures.R")
source("experiments/hydration-hourly-transition.R")

hydration_temperature_cycle_c <- function(peak_hour = 14L) {
  30 + 6 * cos(2 * pi * (0:23 - peak_hour) / 24)
}
hydration_evaporation_slope_kg_h_c <-
  0.44 / sum(pmax(hydration_temperature_cycle_c() - 30, 0))

hydration_evaporation_kg_h <- function(temperature_c, slope_multiplier = 1) {
  hydration_evaporation_slope_kg_h_c * slope_multiplier *
    pmax(temperature_c - 30, 0)
}

hydration_temperature_history <- function(history, days = 126L) {
  profile <- matrix(30, nrow = days, ncol = 24L)
  for (day in seq_len(min(84L, days))) {
    if (history != "null") {
      peak <- if (history == "evening" ||
        (history == "phase_shift" && day > 42L)) 20L else 14L
      profile[day, ] <- hydration_temperature_cycle_c(peak)
    }
  }
  profile
}

new_hydration_system <- function(kind = c("isolated", "coupled")) {
  kind <- match.arg(kind)
  scenario <- list(water_movement_expenditure_per_leg_kj = 900,
    food_water_yield_kg_water_kg_dm = 3.28, water_layer_active = TRUE)
  list(
    kind = kind,
    landscape = if (kind == "isolated") new_isolated_hydration_landscape()
      else new_water_constrained_landscape(scenario),
    water_properties = if (kind == "isolated") isolated_water_properties
      else new_water_constrained_properties(scenario),
    water_parameters = isolated_water_parameters,
    fixture = water_constrained_fixture,
    forage_parameters = if (kind == "coupled")
      herbivoreTTR::new_forage_turnover_parameters(1000, 0.001) else NULL,
    coupling_parameters = if (kind == "coupled")
      herbivoreTTR::new_nonspatial_coupling_parameters(50, 500) else NULL
  )
}

new_hydration_context <- function(kind) {
  old <- if (kind == "isolated") new_isolated_hydration_context()
    else new_water_constrained_context()
  old$state$forage_state <- old$state$forage
  old$state$forage <- NULL
  old$physiological_draw_history_kg <- numeric()
  old
}

hydration_food_plan <- function(context, system) {
  opening <- context$state$location$patch_id
  if (system$kind == "isolated") {
    return(list(destination = opening, selected_action = "stay"))
  }
  destination <- setdiff(water_constrained_food_patch_ids, opening)
  expected <- context$remembered_return_kj_feeding_opportunity_h
  expected[[destination]] <- recover_water_constrained_expected_return(
    expected[[destination]],
    context$best_return_kj_feeding_opportunity_h[[destination]],
    context$days_since_visit[[destination]]
  )
  decision <- choose_water_constrained_food_action(opening, destination,
    expected, system$landscape, context$accumulated_inadequacy_kj)
  list(destination = if (decision$selected_action == "move") destination
    else opening, selected_action = decision$selected_action)
}

hydration_update_food_memory <- function(context, hourly, food_action) {
  opportunity_h <- sum(hourly$food_patch_opportunity_h)
  stopifnot(opportunity_h > 0)
  experienced <- sum(hourly$realized_ingested_available_energy_kj) /
    opportunity_h
  patch <- context$state$location$patch_id
  context$remembered_return_kj_feeding_opportunity_h[[patch]] <- experienced
  context$best_return_kj_feeding_opportunity_h[[patch]] <- max(experienced,
    context$best_return_kj_feeding_opportunity_h[[patch]])
  context$days_since_visit <- context$days_since_visit + 1L
  context$days_since_visit[[patch]] <- 0L
  if (food_action == "move") context$accumulated_inadequacy_kj <- 0
  shortfall_kj <- max(200 - experienced, 0) * opportunity_h
  context$accumulated_inadequacy_kj <- if (shortfall_kj > 0)
    context$accumulated_inadequacy_kj + shortfall_kj else 0
  context
}

# Only completed experience enters this scalar endpoint estimate. No calendar
# or future environmental input is accepted by the controller.
hydration_anticipatory_decision <- function(body_water_kg,
  physiological_draw_history_kg, memory_hours = 24L) {
  stopifnot(memory_hours %in% c(12L, 24L, 48L))
  if (length(physiological_draw_history_kg) < memory_hours) {
    return(list(depart = FALSE, expected_draw_kg_h = NA_real_,
      projected_body_water_kg = NA_real_))
  }
  expected <- max(0, mean(tail(physiological_draw_history_kg, memory_hours)))
  projected <- body_water_kg - 25 * expected
  list(depart = projected < 26, expected_draw_kg_h = expected,
    projected_body_water_kg = projected)
}

hydration_daily_summary <- function(hourly) {
  data.frame(
    day = hourly$day[[1L]],
    closing_body_energy_reserve_kj = tail(hourly$body_energy_reserve_end_kj, 1),
    minimum_body_water_kg = min(c(hourly$body_water_start_kg[[1L]],
      hourly$body_water_end_kg)),
    closing_body_water_kg = tail(hourly$body_water_end_kg, 1),
    realized_intake_kg_dm = sum(hourly$realized_dry_matter_intake_kg_dm),
    water_trips = sum(hourly$water_departure),
    anticipatory_trips = sum(hourly$water_departure_reason == "anticipatory"),
    water_trip_feeding_opportunity_h = sum(hourly$water_trip_active &
      water_constrained_fixture$feeding_open),
    drinking_water_kg = sum(hourly$realized_drinking_water_kg),
    movement_expenditure_kj = sum(hourly$incremental_movement_expenditure_kj),
    food_patch_switches = sum(hourly$food_patch_move),
    patch_a_biomass_kg_dm_ha = tail(hourly$patch_a_biomass_kg_dm_ha, 1),
    patch_b_biomass_kg_dm_ha = tail(hourly$patch_b_biomass_kg_dm_ha, 1)
  )
}

run_temperature_hydration <- function(system, temperature_c,
  policy = c("reactive", "anticipatory"), initial_context = NULL,
  slope_multiplier = 1, memory_hours = 24L) {
  policy <- match.arg(policy)
  stopifnot(is.matrix(temperature_c), ncol(temperature_c) == 24L,
    all(is.finite(temperature_c)), is.finite(slope_multiplier),
    length(slope_multiplier) == 1L, slope_multiplier >= 0)
  context <- if (is.null(initial_context)) new_hydration_context(system$kind)
    else initial_context
  initial <- context
  rows <- vector("list", length(temperature_c))
  daily <- vector("list", nrow(temperature_c))
  n <- 0L
  completed_days <- 0L
  terminal <- NULL
  for (day in seq_len(nrow(temperature_c))) {
    food_plan <- hydration_food_plan(context, system)
    midnight_thirst <- context$state$water$body_water_kg <= 26
    reactive_due_hour <- if (midnight_thirst) 8L else NA_integer_
    departure_hour <- NA_integer_
    departure_reason <- "none"
    trip_origin <- NA_character_
    for (hour in 0:23) {
      if (is.na(reactive_due_hour) &&
        context$state$water$body_water_kg <= 26) reactive_due_hour <- hour
      forecast <- list(depart = FALSE, expected_draw_kg_h = NA_real_,
        projected_body_water_kg = NA_real_)
      if (hour == 8L && policy == "anticipatory") {
        forecast <- hydration_anticipatory_decision(
          context$state$water$body_water_kg,
          context$physiological_draw_history_kg, memory_hours)
      }
      food_move <- hour == 0L && food_plan$selected_action == "move"
      can_depart <- is.na(departure_hour) && hour <= 21L && !food_move
      reactive_due <- !is.na(reactive_due_hour) && hour >= reactive_due_hour
      if (can_depart && (reactive_due || forecast$depart)) {
        departure_hour <- hour
        departure_reason <- if (reactive_due) "reactive" else "anticipatory"
        trip_origin <- context$state$location$patch_id
      }
      in_trip <- !is.na(departure_hour) &&
        hour >= departure_hour && hour <= departure_hour + 2L
      destination <- if (in_trip) {
        if (hour < departure_hour + 2L) "water_source" else trip_origin
      } else food_plan$destination
      loss <- hydration_evaporation_kg_h(temperature_c[day, hour + 1L],
        slope_multiplier)
      step <- tryCatch(hydration_step_hour(context$state, system, destination,
        hour, loss), error = function(error) {
        known_boundary <- conditionMessage(error) %in% c(
          "The proposed closing body-energy reserve is negative.",
          "The proposed closing body-water stock is negative.")
        if (!known_boundary) stop(error)
        terminal <<- list(day = day, hour_of_day = hour,
          reason = conditionMessage(error), transition_completed = FALSE)
        NULL
      })
      if (is.null(step)) break
      context$state <- step$context
      row <- step$hourly
      row$day <- day
      row$temperature_c <- temperature_c[day, hour + 1L]
      row$water_departure <- !is.na(departure_hour) && hour == departure_hour
      row$water_departure_reason <- if (row$water_departure)
        departure_reason else "none"
      row$water_trip_active <- in_trip
      row$food_patch_move <- food_move
      row$expected_draw_kg_h <- forecast$expected_draw_kg_h
      row$projected_body_water_kg <- forecast$projected_body_water_kg
      for (patch in c("patch_a", "patch_b")) {
        row[[paste0(patch, "_biomass_kg_dm_ha")]] <- if (
          system$kind == "coupled") water_constrained_patch_biomass(
            context$state$forage_state, patch) else NA_real_
      }
      n <- n + 1L
      rows[[n]] <- row
      context$physiological_draw_history_kg <- tail(c(
        context$physiological_draw_history_kg,
        row$physiological_net_nondrinking_water_draw_kg), 48L)
      if (row$body_water_below_critical) {
        terminal <- list(day = day, hour_of_day = hour,
          reason = "body water crossed the declared critical boundary",
          transition_completed = TRUE)
        break
      }
    }
    if (hour == 23L && !is.null(step) &&
      (is.null(terminal) || terminal$transition_completed)) {
      day_rows <- do.call(rbind, rows[(n - 23L):n])
      daily[[day]] <- hydration_daily_summary(day_rows)
      context$simulation_day <- context$simulation_day + 1L
      if (system$kind == "coupled") context <- hydration_update_food_memory(
        context, day_rows, food_plan$selected_action)
      completed_days <- day
    }
    if (!is.null(terminal)) break
  }
  hourly <- if (n > 0L) do.call(rbind, rows[seq_len(n)]) else data.frame()
  list(hourly = hourly, daily = if (completed_days > 0L)
    do.call(rbind, daily[seq_len(completed_days)]) else data.frame(),
    initial_context = initial, final_context = context, terminal = terminal,
    policy = policy, system = system$kind, memory_hours = memory_hours,
    slope_multiplier = slope_multiplier)
}

hydration_pair_summary <- function(reactive, anticipatory) {
  common_h <- min(nrow(reactive$hourly), nrow(anticipatory$hourly))
  a <- anticipatory$hourly[seq_len(common_h), ]
  r <- reactive$hourly[seq_len(common_h), ]
  difference <- function(field) sum(a[[field]]) - sum(r[[field]])
  completed_trips <- function(x) {
    departures <- which(x$water_departure)
    complete <- departures[departures + 2L <= nrow(x)]
    refill <- vapply(complete, function(i)
      sum(x$realized_drinking_water_kg[i + 0:2]), numeric(1L))
    list(count = length(complete), in_progress = length(departures) - length(complete),
      mean_refill_kg = if (length(refill)) mean(refill) else NA_real_)
  }
  r_trips <- completed_trips(r)
  a_trips <- completed_trips(a)
  data.frame(
    common_hours = common_h,
    reactive_completed_days = nrow(reactive$daily),
    anticipatory_completed_days = nrow(anticipatory$daily),
    reactive_minimum_water_kg = min(c(r$body_water_start_kg[[1L]],
      r$body_water_end_kg)),
    anticipatory_minimum_water_kg = min(c(a$body_water_start_kg[[1L]],
      a$body_water_end_kg)),
    reactive_trips = sum(r$water_departure),
    anticipatory_trips = sum(a$water_departure),
    reactive_completed_trips = r_trips$count,
    anticipatory_completed_trips = a_trips$count,
    reactive_in_progress_trips = r_trips$in_progress,
    anticipatory_in_progress_trips = a_trips$in_progress,
    reactive_drinking_water_per_completed_trip_kg = r_trips$mean_refill_kg,
    anticipatory_drinking_water_per_completed_trip_kg = a_trips$mean_refill_kg,
    body_energy_advantage_kj = tail(a$body_energy_reserve_end_kj, 1) -
      tail(r$body_energy_reserve_end_kj, 1),
    combined_energy_advantage_kj = tail(a$body_energy_reserve_end_kj +
      a$gut_available_energy_end_kj - r$body_energy_reserve_end_kj -
      r$gut_available_energy_end_kj, 1),
    intake_energy_difference_kj = difference("realized_ingested_available_energy_kj"),
    movement_cost_difference_kj = difference("incremental_movement_expenditure_kj"),
    reactive_water_trip_feeding_h = sum(r$water_trip_active &
      rep(water_constrained_fixture$feeding_open, length.out = common_h)),
    anticipatory_water_trip_feeding_h = sum(a$water_trip_active &
      rep(water_constrained_fixture$feeding_open, length.out = common_h))
  )
}
