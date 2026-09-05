source("experiments/water-constrained-fixtures.R")

isolated_forage_patch_id <- "forage_patch"
isolated_water_source_patch_id <- "water_source"

new_isolated_hydration_landscape <- function() {
  herbivoreTTR::new_known_route_landscape(
    patch_id = c(isolated_forage_patch_id, isolated_water_source_patch_id),
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

new_isolated_hydration_context <- function() {
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

new_isolated_hydration_itinerary <- function(visit_water) {
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

run_isolated_hydration_days <- function(
  regime,
  number_of_days,
  initial_context = NULL,
  incremental_evaporative_loss_kg_day = rep(0, number_of_days),
  water_visit_policy = c("hourly_reactive", "daily_opening")
) {
  water_visit_policy <- match.arg(water_visit_policy)
  context <- if (is.null(initial_context)) {
    new_isolated_hydration_context()
  } else {
    initial_context
  }
  initial_simulation_day <- context$simulation_day
  state <- context$state
  landscape <- new_isolated_hydration_landscape()
  daily_rows <- vector("list", number_of_days)
  completed_days <- 0L
  terminal_day <- NA_integer_
  terminal_reason <- NA_character_

  for (local_day in seq_len(number_of_days)) {
    simulation_day <- initial_simulation_day + local_day
    opening_water_kg <- state$water$body_water_kg
    opening_thirst_triggered <- opening_water_kg <=
      water_constrained_thirst_trigger_body_water_kg
    incremental_loss_hourly <- new_daily_evaporative_loss_schedule(
      incremental_evaporative_loss_kg_day[[local_day]]
    )
    day_error <- NULL
    day <- tryCatch({
      run_energy <- function(itinerary) {
        herbivoreTTR::run_prescribed_spatial_energy_day(
          initial_location_state = state$location,
          landscape = landscape,
          itinerary = itinerary,
          initial_gut_state = state$gut,
          initial_body_state = state$body,
          gut_parameters = water_constrained_fixture$gut,
          body_parameters = water_constrained_fixture$body,
          appetite_parameters = water_constrained_fixture$appetite,
          appetite_reference_schedule =
            water_constrained_fixture$appetite_reference,
          routine_activity_schedule = water_constrained_fixture$activity
        )
      }
      base_itinerary <- new_isolated_hydration_itinerary(FALSE)
      if (water_visit_policy == "daily_opening") {
        water_visit <- opening_thirst_triggered
        itinerary <- new_isolated_hydration_itinerary(water_visit)
        visit_plan <- list(
          itinerary = itinerary,
          thirst_detected = opening_thirst_triggered,
          thirst_detected_at_opening = opening_thirst_triggered,
          detection_time_h = if (opening_thirst_triggered) 0L else NA_integer_,
          water_visit = water_visit,
          visit_deferred = FALSE,
          departure_hour = if (water_visit) 8L else NA_integer_,
          drinking_hour = if (water_visit) 9L else NA_integer_,
          response_delay_h = if (water_visit) 9L else NA_integer_
        )
        energy <- run_energy(itinerary)
      } else {
        base_energy <- run_energy(base_itinerary)
        visit_plan <- new_reactive_water_visit_plan(
          state$water,
          isolated_water_parameters,
          isolated_water_properties,
          landscape,
          base_energy$hourly,
          incremental_loss_hourly,
          isolated_water_source_patch_id,
          water_constrained_thirst_trigger_body_water_kg
        )
        energy <- if (visit_plan$water_visit) {
          run_energy(visit_plan$itinerary)
        } else {
          base_energy
        }
      }
      water <- herbivoreTTR::run_spatial_body_water_day(
        initial_state = state$water,
        parameters = isolated_water_parameters,
        patch_water_properties = isolated_water_properties,
        spatial_energy_hourly = energy$hourly,
        prescribed_incremental_evaporative_water_loss_kg_h =
          incremental_loss_hourly
      )
      list(energy = energy, water = water, visit_plan = visit_plan)
    }, error = function(error) {
      if (!conditionMessage(error) %in% c(
        "The proposed closing body-energy reserve is negative.",
        "The proposed closing body-water stock is negative."
      )) stop(error)
      day_error <<- conditionMessage(error)
      NULL
    })
    if (is.null(day)) {
      terminal_day <- simulation_day
      terminal_reason <- day_error
      break
    }

    accounts_close <-
      max(abs(day$energy$hourly$system_energy_balance_residual_kj)) < 1e-8 &&
        abs(day$energy$daily$system_energy_balance_residual_kj) < 1e-8 &&
        max(abs(day$water$hourly$body_water_balance_residual_kg)) < 1e-12 &&
        abs(day$water$daily$body_water_balance_residual_kg) < 1e-12
    daily_rows[[local_day]] <- data.frame(
      regime = regime,
      water_visit_policy = water_visit_policy,
      simulation_day = simulation_day,
      opening_body_water_kg = opening_water_kg,
      thirst_triggered = day$visit_plan$thirst_detected,
      thirst_triggered_at_opening =
        day$visit_plan$thirst_detected_at_opening,
      thirst_detection_time_h = day$visit_plan$detection_time_h,
      water_visit = day$visit_plan$water_visit,
      water_visit_deferred = day$visit_plan$visit_deferred,
      water_departure_hour = day$visit_plan$departure_hour,
      drinking_hour = day$visit_plan$drinking_hour,
      water_response_delay_h = day$visit_plan$response_delay_h,
      food_derived_water_kg =
        day$water$daily$total_food_derived_water_kg,
      drinking_water_kg =
        day$water$daily$total_realized_drinking_water_kg,
      ordinary_water_loss_kg =
        day$water$daily$total_ordinary_water_loss_kg,
      incremental_evaporative_water_loss_kg =
        day$water$daily$total_incremental_evaporative_water_loss_kg,
      closing_body_water_kg = day$water$daily$body_water_final_kg,
      minimum_body_water_kg = day$water$daily$minimum_body_water_kg,
      body_water_below_critical =
        day$water$daily$body_water_below_critical,
      realized_intake_kg_dm =
        day$energy$daily$realized_dry_matter_intake_kg_dm,
      feeding_time_lost_h = day$energy$daily$feeding_time_lost_h,
      water_excursion_feeding_opportunity_h = if (
        day$visit_plan$water_visit
      ) {
        sum(water_constrained_fixture$feeding_open[
          day$visit_plan$departure_hour + seq_len(3L)
        ])
      } else {
        0L
      },
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
