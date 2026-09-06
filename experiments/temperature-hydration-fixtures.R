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

new_hydration_system <- function(kind = c("isolated", "coupled"),
  water_route_cost_multiplier = 1) {
  kind <- match.arg(kind)
  stopifnot(length(water_route_cost_multiplier) == 1L,
    is.finite(water_route_cost_multiplier), water_route_cost_multiplier >= 0)
  scenario <- list(water_movement_expenditure_per_leg_kj = 900,
    food_water_yield_kg_water_kg_dm = 3.28, water_layer_active = TRUE)
  system <- list(
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
  routes <- system$landscape$routes
  water_route <- routes$origin_patch_id == "water_source" |
    routes$destination_patch_id == "water_source"
  system$landscape$routes$incremental_movement_expenditure_kj[water_route] <-
    routes$incremental_movement_expenditure_kj[water_route] *
      water_route_cost_multiplier
  system
}

# Known expenditure of the two actual route legs from the current food patch.
hydration_water_round_trip_cost_kj <- function(system, origin_patch_id) {
  routes <- system$landscape$routes
  outbound <- routes$origin_patch_id == origin_patch_id &
    routes$destination_patch_id == "water_source"
  inbound <- routes$origin_patch_id == "water_source" &
    routes$destination_patch_id == origin_patch_id
  stopifnot(sum(outbound) == 1L, sum(inbound) == 1L,
    all(routes$travel_duration_h[outbound | inbound] == 1))
  sum(routes$incremental_movement_expenditure_kj[outbound | inbound])
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

# Compare the energetic cost per kilogram of refilling at the current 08:00
# decision with the cost after the predicted reactive departure.  The
# histories are completed hourly observations supplied by the caller; no
# future forcing or calendar state enters this pure controller.
hydration_cost_aware_decision <- function(body_water_kg,
  physiological_draw_history_kg, food_energy_history_kj,
  food_opportunity_history_h, memory_hours = 24L,
  opportunity_value_multiplier = 1,
  feeding_open = water_constrained_fixture$feeding_open,
  normal_body_water_kg = 28, drinking_capacity_kg = 10,
  round_trip_cost_kj = 1800) {
  stopifnot(length(body_water_kg) == 1L, is.finite(body_water_kg),
    memory_hours %in% c(12L, 24L, 48L),
    length(opportunity_value_multiplier) == 1L,
    is.finite(opportunity_value_multiplier), opportunity_value_multiplier >= 0,
    length(feeding_open) == 24L, is.logical(feeding_open),
    length(normal_body_water_kg) == 1L, is.finite(normal_body_water_kg),
    length(drinking_capacity_kg) == 1L, is.finite(drinking_capacity_kg),
    drinking_capacity_kg > 0, length(round_trip_cost_kj) == 1L,
    is.finite(round_trip_cost_kj), round_trip_cost_kj >= 0,
    is.numeric(physiological_draw_history_kg),
    is.numeric(food_energy_history_kj),
    is.numeric(food_opportunity_history_h),
    all(is.finite(physiological_draw_history_kg)),
    all(is.finite(food_energy_history_kj)),
    all(is.finite(food_opportunity_history_h)),
    all(food_energy_history_kj >= 0),
    all(food_opportunity_history_h >= 0), all(!is.na(feeding_open)),
    body_water_kg >= 0, body_water_kg <= normal_body_water_kg)
  result <- list(
    depart = FALSE,
    expected_draw_kg_h = NA_real_,
    projected_body_water_kg = NA_real_,
    precaution_trigger = NA,
    current_body_water_kg = body_water_kg,
    expected_food_return_kj_h = NA_real_,
    predicted_crossing_h = NA_integer_,
    predicted_crossing_hour = NA_integer_,
    predicted_departure_hour = NA_integer_,
    predicted_delay_h = NA_integer_,
    refill_now_kg = NA_real_,
    refill_later_kg = NA_real_,
    displaced_opportunities_h = NA_real_,
    cost_now_kj_kg = NA_real_,
    cost_later_kj_kg = NA_real_,
    cost_margin_kj_kg = NA_real_,
    opportunity_multiplier_boundary = NA_real_,
    reason = "insufficient_history"
  )
  history_available <- length(physiological_draw_history_kg) >= memory_hours &&
    length(food_energy_history_kj) >= memory_hours &&
    length(food_opportunity_history_h) >= memory_hours
  if (!history_available) {
    return(result)
  }

  draw <- max(0, mean(tail(physiological_draw_history_kg, memory_hours)))
  food_opportunities <- tail(food_opportunity_history_h, memory_hours)
  food_energy <- tail(food_energy_history_kj, memory_hours)
  opportunity_total <- sum(food_opportunities)
  expected_food_return <- if (opportunity_total > 0) {
    sum(food_energy) / opportunity_total
  } else {
    NA_real_
  }
  projected <- body_water_kg - 25 * draw
  precaution_trigger <- projected < 26
  result$expected_draw_kg_h <- draw
  result$projected_body_water_kg <- projected
  result$precaution_trigger <- precaution_trigger
  result$expected_food_return_kj_h <- expected_food_return
  if (!isTRUE(precaution_trigger)) {
    result$reason <- "no_precaution"
    return(result)
  }
  if (body_water_kg <= 26) {
    result$reason <- "observed_thirst"
    return(result)
  }
  if (!is.finite(expected_food_return)) {
    result$reason <- "zero_opportunity_denominator"
    return(result)
  }
  if (draw <= 0) {
    result$reason <- "no_positive_draw"
    return(result)
  }

  crossing_ratio <- (body_water_kg - 26) / draw
  crossing_tolerance <- 100 * .Machine$double.eps * max(1,
    abs(crossing_ratio))
  nearest_crossing <- round(crossing_ratio)
  crossing_h <- as.integer(if (abs(crossing_ratio - nearest_crossing) <=
    crossing_tolerance) nearest_crossing else ceiling(crossing_ratio))
  delay_h <- if (crossing_h %in% 14:16) 24L else crossing_h
  later_trip_hours <- (8L + delay_h + 0:2) %% 24L
  displaced_h <- sum(feeding_open[later_trip_hours + 1L])
  refill_now <- min(drinking_capacity_kg,
    normal_body_water_kg - body_water_kg + 2 * draw)
  refill_later <- min(drinking_capacity_kg,
    normal_body_water_kg - body_water_kg + (delay_h + 2) * draw)
  stopifnot(refill_now > 0, refill_later > 0)
  cost_now <- round_trip_cost_kj / refill_now
  cost_later <- (round_trip_cost_kj +
    opportunity_value_multiplier * expected_food_return * displaced_h) /
    refill_later
  margin <- cost_later - cost_now
  cost_tolerance <- 100 * .Machine$double.eps * max(1, abs(cost_now),
    abs(cost_later))
  opportunity_multiplier_boundary <- if (displaced_h > 0) {
    round_trip_cost_kj * (refill_later / refill_now - 1) /
      (expected_food_return * displaced_h)
  } else {
    NA_real_
  }
  result$predicted_crossing_h <- crossing_h
  result$predicted_crossing_hour <- (8L + crossing_h) %% 24L
  result$predicted_departure_hour <- (8L + delay_h) %% 24L
  result$predicted_delay_h <- delay_h
  result$refill_now_kg <- refill_now
  result$refill_later_kg <- refill_later
  result$displaced_opportunities_h <- displaced_h
  result$cost_now_kj_kg <- cost_now
  result$cost_later_kj_kg <- cost_later
  result$cost_margin_kj_kg <- margin
  result$opportunity_multiplier_boundary <- opportunity_multiplier_boundary
  result$reason <- if (margin > cost_tolerance) {
    "cost_aware"
  } else if (abs(margin) <= cost_tolerance) {
    "cost_tie"
  } else {
    "reactive_fallback"
  }
  result$depart <- identical(result$reason, "cost_aware")
  result
}

seed_cost_aware_context <- function(precondition) {
  stopifnot(is.list(precondition), is.list(precondition$final_context),
    is.data.frame(precondition$hourly))
  context <- precondition$final_context
  context$food_energy_history_kj <- tail(
    precondition$hourly$realized_ingested_available_energy_kj, 48L)
  context$food_opportunity_history_h <- tail(
    precondition$hourly$food_patch_opportunity_h, 48L)
  context
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
    anticipatory_trips = sum(hourly$water_departure_reason %in%
      c("anticipatory", "cost_aware")),
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
  policy = c("reactive", "anticipatory", "cost_aware"),
  initial_context = NULL, slope_multiplier = 1, memory_hours = 24L,
  opportunity_value_multiplier = 1) {
  policy <- match.arg(policy)
  stopifnot(is.matrix(temperature_c), ncol(temperature_c) == 24L,
    all(is.finite(temperature_c)), is.finite(slope_multiplier),
    length(slope_multiplier) == 1L, slope_multiplier >= 0,
    length(opportunity_value_multiplier) == 1L,
    is.finite(opportunity_value_multiplier), opportunity_value_multiplier >= 0)
  context <- if (is.null(initial_context)) new_hydration_context(system$kind)
    else initial_context
  if (policy == "cost_aware") {
    context$food_energy_history_kj <- if (is.null(context$food_energy_history_kj))
      numeric() else context$food_energy_history_kj
    context$food_opportunity_history_h <- if (
      is.null(context$food_opportunity_history_h)) numeric()
      else context$food_opportunity_history_h
  }
  initial <- context
  rows <- vector("list", length(temperature_c))
  daily <- vector("list", nrow(temperature_c))
  n <- 0L
  completed_days <- 0L
  terminal <- NULL
  decisions <- data.frame()
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
      if (hour == 8L && policy == "cost_aware") {
        forecast <- hydration_cost_aware_decision(
          context$state$water$body_water_kg,
          context$physiological_draw_history_kg,
          context$food_energy_history_kj,
          context$food_opportunity_history_h,
          memory_hours, opportunity_value_multiplier,
          round_trip_cost_kj = hydration_water_round_trip_cost_kj(system,
            if (is.na(trip_origin)) context$state$location$patch_id else trip_origin))
        if (!is.na(reactive_due_hour) && reactive_due_hour == 8L) {
          forecast$depart <- FALSE
          forecast$reason <- "observed_thirst"
        }
      }
      food_move <- hour == 0L && food_plan$selected_action == "move"
      reactive_due <- !is.na(reactive_due_hour) && hour >= reactive_due_hour
      can_depart <- is.na(departure_hour) && hour <= 21L && !food_move
      eligible_for_optional_trip <- can_depart && !reactive_due
      if (can_depart && (reactive_due || forecast$depart)) {
        departure_hour <- hour
        departure_reason <- if (reactive_due) "reactive" else if (
          policy == "cost_aware") "cost_aware" else "anticipatory"
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
      if (policy == "cost_aware") {
        context$food_energy_history_kj <- tail(c(context$food_energy_history_kj,
          row$realized_ingested_available_energy_kj), 48L)
        context$food_opportunity_history_h <- tail(c(
          context$food_opportunity_history_h, row$food_patch_opportunity_h),
          48L)
        if (hour == 8L) {
          decision <- cbind(
            data.frame(day = day, hour_of_day = hour,
              eligible_for_optional_trip = eligible_for_optional_trip,
              optional_departure = isTRUE(row$water_departure) &&
                identical(row$water_departure_reason, "cost_aware")),
            as.data.frame(forecast))
          decisions <- rbind(decisions, decision)
        }
      }
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
  result <- list(hourly = hourly, daily = if (completed_days > 0L)
    do.call(rbind, daily[seq_len(completed_days)]) else data.frame(),
    initial_context = initial, final_context = context, terminal = terminal,
    policy = policy, system = system$kind, memory_hours = memory_hours,
    slope_multiplier = slope_multiplier)
  if (policy == "cost_aware") {
    result$decisions <- decisions
    result$opportunity_value_multiplier <- opportunity_value_multiplier
  }
  result
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

# Reconstruct balances from stocks and physical fluxes, not reported residuals.
check_hydration_accounts <- function(run) {
  x <- run$hourly
  stopifnot(nrow(x) > 0L)
  energy_change <- x$gut_available_energy_end_kj -
    x$gut_available_energy_start_kj + x$body_energy_reserve_end_kj -
    x$body_energy_reserve_start_kj
  net_energy <- x$realized_ingested_available_energy_kj -
    x$maintenance_expenditure_kj -
    x$prescribed_routine_activity_expenditure_kj -
    x$incremental_movement_expenditure_kj
  water_change <- x$body_water_end_kg - x$body_water_start_kg
  net_water <- x$food_derived_water_kg + x$realized_drinking_water_kg -
    x$ordinary_water_loss_kg - x$incremental_evaporative_water_loss_kg -
    x$excess_water_elimination_kg
  stopifnot(max(abs(energy_change - net_energy)) < 1e-8,
    max(abs(water_change - net_water)) < 1e-12,
    abs(sum(energy_change) - sum(net_energy)) < 1e-7,
    all(x$body_water_end_kg <= 28 + 1e-12),
    all(x$body_water_end_kg >= 0), all(x$body_energy_reserve_end_kj >= 0),
    all(tapply(x$water_departure, x$day, sum) <= 1L),
    all(x$realized_dry_matter_intake_kg_dm[x$water_trip_active] == 0))
  for (stock in c("gut_available_energy", "body_energy_reserve", "body_water")) {
    unit <- if (stock == "body_water") "kg" else "kj"
    stopifnot(identical(head(x[[paste(stock, "end", unit, sep = "_")]], -1L),
      tail(x[[paste(stock, "start", unit, sep = "_")]], -1L)))
  }
  if (run$system == "coupled") for (patch in c("patch_a", "patch_b")) {
    end <- x[[paste0(patch, "_biomass_kg_dm_ha")]]
    start <- c(water_constrained_patch_biomass(
      run$initial_context$state$forage_state, patch), head(end, -1L))
    removal <- 50 * x$realized_dry_matter_intake_kg_dm *
      (x$opening_patch_id == patch & x$spatial_action == "stay")
    stopifnot(max(abs(end - (0.999 * start + 1 - removal))) < 1e-10)
  }
  if (!is.null(run$terminal)) stopifnot(run$terminal$reason %in% c(
    "The proposed closing body-energy reserve is negative.",
    "The proposed closing body-water stock is negative.",
    "body water crossed the declared critical boundary"))
}

summarize_hydration_run <- function(run, common_hours) {
  x <- run$hourly[seq_len(common_hours), ]
  departures <- which(x$water_departure)
  complete <- departures[departures + 2L <= common_hours]
  refill <- vapply(complete, function(i)
    sum(x$realized_drinking_water_kg[i + 0:2]), numeric(1L))
  terminal <- run$terminal
  initial_water <- run$initial_context$state$water$body_water_kg
  data.frame(policy = run$policy, common_hours = common_hours,
    completed_hours = nrow(run$hourly), completed_days = nrow(run$daily),
    terminal_day = if (is.null(terminal)) NA_integer_ else terminal$day,
    terminal_hour = if (is.null(terminal)) NA_integer_ else terminal$hour_of_day,
    terminal_reason = if (is.null(terminal)) "none" else terminal$reason,
    recovery_hours = max(0L, nrow(run$hourly) - 84L * 24L),
    minimum_water_full_run_kg = min(initial_water, run$hourly$body_water_end_kg),
    minimum_water_common_kg = min(initial_water, x$body_water_end_kg),
    body_energy_common_kj = tail(x$body_energy_reserve_end_kj, 1L),
    combined_energy_common_kj = tail(x$body_energy_reserve_end_kj +
      x$gut_available_energy_end_kj, 1L),
    intake_energy_kj = sum(x$realized_ingested_available_energy_kj),
    water_movement_kj = sum(x$incremental_movement_expenditure_kj[x$water_trip_active]),
    food_movement_kj = sum(x$incremental_movement_expenditure_kj[x$food_patch_move]),
    trip_starts = length(departures), completed_trips = length(complete),
    in_progress_trips = length(departures) - length(complete),
    mean_completed_refill_kg = if (length(refill)) mean(refill) else NA_real_,
    water_trip_feeding_hours = sum(x$water_trip_active &
      x$hour_of_day %in% c(0:7, 16:23)))
}
