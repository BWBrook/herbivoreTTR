source("experiments/herbivore-core-fixtures.R")

water_constrained_fixture <- new_herbivore_core_fixture()
water_constrained_food_patch_ids <- c("patch_a", "patch_b")
water_constrained_source_patch_id <- "water_source"
water_constrained_patch_ids <- c(
  water_constrained_food_patch_ids,
  water_constrained_source_patch_id
)
water_constrained_feeding_opportunity_h <- 16L
water_constrained_planning_horizon_days <- 2L
water_constrained_revisit_recovery_days <- 2L
water_constrained_expected_demand_kg_dm_h <- 0.020
water_constrained_maximum_acquisition_kg_dm_h <- 0.025
water_constrained_adequate_return_kj_feeding_opportunity_h <- 200
water_constrained_herbivore_density_animals_ha <- 50
water_constrained_forage_equilibrium_biomass_kg_dm_ha <- 1000
water_constrained_residual_unavailable_forage_kg_dm_ha <- 500
water_constrained_forage_turnover_fraction_h <- 0.001
water_constrained_normal_body_water_kg <- 28
water_constrained_critical_body_water_kg <- 24
water_constrained_thirst_trigger_body_water_kg <- 26

water_constrained_patch_biomass <- function(forage_state, patch_id) {
  forage_state$forage_biomass_kg_dm_ha[
    forage_state$patch_id == patch_id
  ]
}

new_water_constrained_landscape <- function(scenario) {
  herbivoreTTR::new_known_route_landscape(
    patch_id = water_constrained_patch_ids,
    forage_acquisition_ceiling_kg_dm_h = c(
      water_constrained_maximum_acquisition_kg_dm_h,
      water_constrained_maximum_acquisition_kg_dm_h,
      0
    ),
    route_origin_patch_id = c(
      "patch_a", "patch_b",
      "patch_a", water_constrained_source_patch_id,
      "patch_b", water_constrained_source_patch_id
    ),
    route_destination_patch_id = c(
      "patch_b", "patch_a",
      water_constrained_source_patch_id, "patch_a",
      water_constrained_source_patch_id, "patch_b"
    ),
    incremental_movement_expenditure_kj = c(
      900,
      900,
      rep(scenario$water_movement_expenditure_per_leg_kj, 4L)
    ),
    metabolizable_energy_density_kj_kg_dm = c(8000, 10000, 10000)
  )
}

new_water_constrained_properties <- function(scenario) {
  herbivoreTTR::new_patch_water_properties(
    patch_id = water_constrained_patch_ids,
    food_derived_water_yield_kg_water_kg_dm = c(
      rep(scenario$food_water_yield_kg_water_kg_dm, 2L),
      0
    ),
    drinking_water_availability_kg_h = c(
      0,
      0,
      if (scenario$water_layer_active) 10 else 0
    )
  )
}

recover_water_constrained_expected_return <- function(
  last_return_kj_feeding_opportunity_h,
  best_return_kj_feeding_opportunity_h,
  days_since_visit
) {
  recovery_fraction <- min(
    days_since_visit / water_constrained_revisit_recovery_days,
    1
  )
  last_return_kj_feeding_opportunity_h +
    (
      best_return_kj_feeding_opportunity_h -
        last_return_kj_feeding_opportunity_h
    ) * recovery_fraction
}

choose_water_constrained_food_action <- function(
  opening_patch_id,
  destination_patch_id,
  expected_return_kj_feeding_opportunity_h,
  landscape,
  accumulated_inadequacy_kj
) {
  route_index <- which(
    landscape$routes$origin_patch_id == opening_patch_id &
      landscape$routes$destination_patch_id == destination_patch_id
  )
  travel_duration_h <- landscape$routes$travel_duration_h[[route_index]]
  movement_expenditure_kj <- landscape$routes$
    incremental_movement_expenditure_kj[[route_index]]
  stay_score_kj <-
    expected_return_kj_feeding_opportunity_h[[opening_patch_id]] *
      water_constrained_feeding_opportunity_h *
      water_constrained_planning_horizon_days
  move_score_kj <-
    expected_return_kj_feeding_opportunity_h[[destination_patch_id]] *
      (
        water_constrained_feeding_opportunity_h *
          water_constrained_planning_horizon_days -
          travel_duration_h
      ) -
      movement_expenditure_kj
  move_score_advantage_kj <- move_score_kj - stay_score_kj
  current_return <-
    expected_return_kj_feeding_opportunity_h[[opening_patch_id]]
  current_is_adequate <-
    current_return +
      100 * .Machine$double.eps * max(
        1,
        abs(current_return),
        water_constrained_adequate_return_kj_feeding_opportunity_h
      ) >= water_constrained_adequate_return_kj_feeding_opportunity_h
  adjusted_advantage_kj <-
    move_score_advantage_kj + accumulated_inadequacy_kj
  score_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(c(move_score_advantage_kj, accumulated_inadequacy_kj))
  )
  selected_action <- if (current_is_adequate) {
    "stay"
  } else if (adjusted_advantage_kj > score_tolerance_kj) {
    "move"
  } else {
    "stay"
  }

  list(
    selected_action = selected_action,
    current_return_is_adequate = current_is_adequate,
    move_score_advantage_kj = move_score_advantage_kj,
    deficit_adjusted_move_score_advantage_kj = adjusted_advantage_kj
  )
}

new_water_constrained_itinerary <- function(
  opening_food_patch_id,
  destination_food_patch_id,
  selected_food_action,
  water_visit
) {
  closing_food_patch_id <- if (selected_food_action == "move") {
    destination_food_patch_id
  } else {
    opening_food_patch_id
  }
  closing_patch_id <- rep(closing_food_patch_id, 24L)
  if (water_visit) {
    closing_patch_id[
      water_constrained_fixture$hour_of_day %in% c(8L, 9L)
    ] <- water_constrained_source_patch_id
  }

  herbivoreTTR::new_prescribed_patch_itinerary(
    water_constrained_fixture$hour_of_day,
    closing_patch_id
  )
}

water_constrained_accounts_close <- function(energy, water) {
  max(abs(
    energy$patch_hourly$forage_biomass_balance_residual_kg_dm_ha
  )) < 1e-10 &&
    max(abs(
      energy$patch_daily$forage_biomass_balance_residual_kg_dm_ha
    )) < 1e-10 &&
    abs(energy$daily$herbivore_forage_coupling_residual_kg_dm_ha) < 1e-10 &&
    max(abs(energy$hourly$system_energy_balance_residual_kj)) < 1e-8 &&
    abs(energy$daily$system_energy_balance_residual_kj) < 1e-8 &&
    max(abs(water$hourly$body_water_balance_residual_kg)) < 1e-12 &&
    abs(water$daily$body_water_balance_residual_kg) < 1e-12
}

new_water_constrained_context <- function() {
  energy_densities_kj_kg_dm <- setNames(
    c(8000, 10000),
    water_constrained_food_patch_ids
  )

  list(
    simulation_day = 0L,
    state = list(
      location = herbivoreTTR::new_patch_location_state("patch_a"),
      gut = water_constrained_fixture$opening_gut,
      body = water_constrained_fixture$opening_body,
      water = herbivoreTTR::new_body_water_state(
        water_constrained_normal_body_water_kg
      ),
      forage = herbivoreTTR::new_spatial_forage_biomass_state(
        water_constrained_patch_ids,
        rep(
          water_constrained_forage_equilibrium_biomass_kg_dm_ha,
          length(water_constrained_patch_ids)
        )
      )
    ),
    remembered_return_kj_feeding_opportunity_h =
      water_constrained_expected_demand_kg_dm_h *
        energy_densities_kj_kg_dm,
    best_return_kj_feeding_opportunity_h =
      water_constrained_maximum_acquisition_kg_dm_h *
        energy_densities_kj_kg_dm,
    days_since_visit = setNames(
      rep(0L, length(water_constrained_food_patch_ids)),
      water_constrained_food_patch_ids
    ),
    accumulated_inadequacy_kj = 0
  )
}

new_daily_evaporative_loss_schedule <- function(daily_loss_kg) {
  if (
    !is.numeric(daily_loss_kg) ||
      length(daily_loss_kg) != 1L ||
      !is.finite(daily_loss_kg) ||
      daily_loss_kg < 0
  ) {
    stop("`daily_loss_kg` must be one finite, non-negative value.")
  }
  schedule <- rep(0, 24L)
  event_hours <- water_constrained_fixture$hour_of_day %in% 10:15
  schedule[event_hours] <- daily_loss_kg / sum(event_hours)
  schedule
}

run_water_constrained_closed_loop <- function(
  scenario,
  number_of_days,
  initial_context = NULL,
  prescribed_incremental_evaporative_water_loss_kg_day = rep(
    0,
    number_of_days
  )
) {
  if (
    length(number_of_days) != 1L ||
      !is.numeric(number_of_days) ||
      !is.finite(number_of_days) ||
      number_of_days < 1 ||
      number_of_days != as.integer(number_of_days)
  ) {
    stop("`number_of_days` must be one positive whole number.")
  }
  if (
    !is.numeric(prescribed_incremental_evaporative_water_loss_kg_day) ||
      length(prescribed_incremental_evaporative_water_loss_kg_day) !=
        number_of_days ||
      any(!is.finite(
        prescribed_incremental_evaporative_water_loss_kg_day
      )) ||
      any(prescribed_incremental_evaporative_water_loss_kg_day < 0)
  ) {
    stop(
      paste0(
        "`prescribed_incremental_evaporative_water_loss_kg_day` must ",
        "contain one finite, non-negative value per simulated day."
      )
    )
  }

  context <- if (is.null(initial_context)) {
    new_water_constrained_context()
  } else {
    initial_context
  }
  initial_simulation_day <- context$simulation_day
  state <- context$state
  remembered_return_kj_feeding_opportunity_h <-
    context$remembered_return_kj_feeding_opportunity_h
  best_return_kj_feeding_opportunity_h <-
    context$best_return_kj_feeding_opportunity_h
  days_since_visit <- context$days_since_visit
  accumulated_inadequacy_kj <- context$accumulated_inadequacy_kj

  landscape <- new_water_constrained_landscape(scenario)
  water_properties <- new_water_constrained_properties(scenario)
  water_parameters <- herbivoreTTR::new_body_water_parameters(
    water_constrained_normal_body_water_kg,
    water_constrained_critical_body_water_kg,
    scenario$daily_ordinary_water_loss_kg / 24
  )
  turnover <- herbivoreTTR::new_forage_turnover_parameters(
    water_constrained_forage_equilibrium_biomass_kg_dm_ha,
    water_constrained_forage_turnover_fraction_h
  )
  coupling <- herbivoreTTR::new_nonspatial_coupling_parameters(
    water_constrained_herbivore_density_animals_ha,
    water_constrained_residual_unavailable_forage_kg_dm_ha
  )
  daily_rows <- vector("list", number_of_days)
  completed_days <- 0L
  terminal_day <- NA_integer_
  terminal_reason <- NA_character_

  for (local_day in seq_len(number_of_days)) {
    simulation_day <- initial_simulation_day + local_day
    opening_food_patch_id <- state$location$patch_id
    destination_food_patch_id <- setdiff(
      water_constrained_food_patch_ids,
      opening_food_patch_id
    )
    expected_return <- remembered_return_kj_feeding_opportunity_h
    expected_return[[destination_food_patch_id]] <-
      recover_water_constrained_expected_return(
        remembered_return_kj_feeding_opportunity_h[[
          destination_food_patch_id
        ]],
        best_return_kj_feeding_opportunity_h[[destination_food_patch_id]],
        days_since_visit[[destination_food_patch_id]]
      )
    food_decision <- choose_water_constrained_food_action(
      opening_food_patch_id,
      destination_food_patch_id,
      expected_return,
      landscape,
      accumulated_inadequacy_kj
    )
    thirst_triggered <-
      state$water$body_water_kg <=
        water_constrained_thirst_trigger_body_water_kg
    water_visit <- scenario$water_layer_active && thirst_triggered
    itinerary <- new_water_constrained_itinerary(
      opening_food_patch_id,
      destination_food_patch_id,
      food_decision$selected_action,
      water_visit
    )
    incremental_loss_hourly <- new_daily_evaporative_loss_schedule(
      prescribed_incremental_evaporative_water_loss_kg_day[[local_day]]
    )

    day_error <- NULL
    day <- tryCatch({
      energy <- herbivoreTTR::run_prescribed_spatial_coupled_energy_day(
        initial_location_state = state$location,
        landscape = landscape,
        itinerary = itinerary,
        initial_gut_state = state$gut,
        initial_body_state = state$body,
        initial_spatial_forage_state = state$forage,
        gut_parameters = water_constrained_fixture$gut,
        body_parameters = water_constrained_fixture$body,
        appetite_parameters = water_constrained_fixture$appetite,
        forage_turnover_parameters = turnover,
        coupling_parameters = coupling,
        appetite_reference_schedule =
          water_constrained_fixture$appetite_reference,
        routine_activity_schedule = water_constrained_fixture$activity
      )
      water <- herbivoreTTR::run_spatial_body_water_day(
        state$water,
        water_parameters,
        water_properties,
        energy$hourly,
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

    feeding_opportunity_hours <- sum(
      day$energy$hourly$feeding_opportunity_open
    )
    experienced_return_kj_feeding_opportunity_h <-
      day$energy$daily$total_realized_ingested_available_energy_kj /
        feeding_opportunity_hours
    closing_food_patch_id <- day$energy$final_state$location$patch_id
    remembered_return_kj_feeding_opportunity_h[[closing_food_patch_id]] <-
      experienced_return_kj_feeding_opportunity_h
    best_return_kj_feeding_opportunity_h[[closing_food_patch_id]] <- max(
      best_return_kj_feeding_opportunity_h[[closing_food_patch_id]],
      experienced_return_kj_feeding_opportunity_h
    )
    days_since_visit <- days_since_visit + 1L
    days_since_visit[[closing_food_patch_id]] <- 0L
    if (food_decision$selected_action == "move") {
      accumulated_inadequacy_kj <- 0
    }
    realized_inadequacy_kj <- max(
      water_constrained_adequate_return_kj_feeding_opportunity_h -
        experienced_return_kj_feeding_opportunity_h,
      0
    ) * feeding_opportunity_hours
    if (realized_inadequacy_kj > 0) {
      accumulated_inadequacy_kj <-
        accumulated_inadequacy_kj + realized_inadequacy_kj
    } else {
      accumulated_inadequacy_kj <- 0
    }

    daily_rows[[local_day]] <- data.frame(
      scenario = scenario$scenario,
      scenario_role = scenario$scenario_role,
      simulation_day = simulation_day,
      opening_food_patch_id = opening_food_patch_id,
      closing_food_patch_id = closing_food_patch_id,
      food_patch_action = food_decision$selected_action,
      current_food_return_is_adequate =
        food_decision$current_return_is_adequate,
      experienced_return_kj_feeding_opportunity_h =
        experienced_return_kj_feeding_opportunity_h,
      thirst_triggered = thirst_triggered,
      water_visit = water_visit,
      opening_body_water_kg = state$water$body_water_kg,
      closing_body_water_kg = day$water$daily$body_water_final_kg,
      body_water_below_critical = day$water$daily$body_water_below_critical,
      food_derived_water_kg =
        day$water$daily$total_food_derived_water_kg,
      drinking_water_kg =
        day$water$daily$total_realized_drinking_water_kg,
      ordinary_water_loss_kg =
        day$water$daily$total_ordinary_water_loss_kg,
      incremental_evaporative_water_loss_kg =
        day$water$daily$total_incremental_evaporative_water_loss_kg,
      realized_intake_kg_dm =
        day$energy$daily$realized_dry_matter_intake_kg_dm,
      movement_expenditure_kj =
        day$energy$daily$total_incremental_movement_expenditure_kj,
      closing_body_energy_reserve_kj =
        day$energy$daily$body_energy_reserve_final_kj,
      patch_a_biomass_kg_dm_ha = water_constrained_patch_biomass(
        day$energy$final_state$forage,
        "patch_a"
      ),
      patch_b_biomass_kg_dm_ha = water_constrained_patch_biomass(
        day$energy$final_state$forage,
        "patch_b"
      ),
      accounts_close = water_constrained_accounts_close(
        day$energy,
        day$water
      ),
      row.names = NULL
    )
    state <- list(
      location = day$energy$final_state$location,
      gut = day$energy$final_state$gut,
      body = day$energy$final_state$body,
      water = day$water$final_state,
      forage = day$energy$final_state$forage
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
  final_context <- list(
    simulation_day = initial_simulation_day + completed_days,
    state = state,
    remembered_return_kj_feeding_opportunity_h =
      remembered_return_kj_feeding_opportunity_h,
    best_return_kj_feeding_opportunity_h =
      best_return_kj_feeding_opportunity_h,
    days_since_visit = days_since_visit,
    accumulated_inadequacy_kj = accumulated_inadequacy_kj
  )
  attr(result, "completed_days") <- completed_days
  attr(result, "terminal_day") <- terminal_day
  attr(result, "terminal_reason") <- terminal_reason
  attr(result, "final_context") <- final_context
  result
}

summarize_water_constrained_run <- function(run) {
  food_move_days <- run$simulation_day[run$food_patch_action == "move"]
  water_visit_days <- run$simulation_day[run$water_visit]
  food_return_intervals <- if (length(food_move_days) > 1L) {
    diff(food_move_days)
  } else {
    NA_integer_
  }
  water_visit_intervals <- if (length(water_visit_days) > 1L) {
    diff(water_visit_days)
  } else {
    NA_integer_
  }

  data.frame(
    scenario = run$scenario[[1L]],
    scenario_role = run$scenario_role[[1L]],
    completed_days = attr(run, "completed_days"),
    terminal_day = attr(run, "terminal_day"),
    food_patch_switches = length(food_move_days),
    shortest_food_return_interval_days = if (all(is.na(food_return_intervals))) {
      NA_integer_
    } else {
      min(food_return_intervals)
    },
    water_visits = length(water_visit_days),
    water_visits_per_completed_day =
      length(water_visit_days) / attr(run, "completed_days"),
    shortest_water_visit_interval_days = if (all(is.na(water_visit_intervals))) {
      NA_integer_
    } else {
      min(water_visit_intervals)
    },
    food_derived_water_kg = sum(run$food_derived_water_kg),
    drinking_water_kg = sum(run$drinking_water_kg),
    ordinary_water_loss_kg = sum(run$ordinary_water_loss_kg),
    incremental_evaporative_water_loss_kg = sum(
      run$incremental_evaporative_water_loss_kg
    ),
    movement_expenditure_kj = sum(run$movement_expenditure_kj),
    minimum_body_water_kg = min(run$closing_body_water_kg),
    closing_body_water_kg = tail(run$closing_body_water_kg, 1L),
    minimum_body_energy_reserve_kj = min(
      run$closing_body_energy_reserve_kj
    ),
    closing_body_energy_reserve_kj = tail(
      run$closing_body_energy_reserve_kj,
      1L
    ),
    days_in_patch_a = sum(run$closing_food_patch_id == "patch_a"),
    days_in_patch_b = sum(run$closing_food_patch_id == "patch_b"),
    all_accounts_close = all(run$accounts_close),
    row.names = NULL
  )
}
