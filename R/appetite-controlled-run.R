#' Run repeated appetite-controlled gut and body-energy days
#'
#' Repeat one fixed 24-hour appetite reference and routine-activity schedule,
#' calculate an appetite target from opening gut and body state each hour, cap
#' acquisition with one external non-depleting forage schedule, and advance the
#' existing gut and body-energy transitions with exact state carry-over.
#'
#' @param initial_gut_state A gut-energy state record created by
#'   [new_gut_energy_state()].
#' @param initial_body_state A body-energy state record created by
#'   [new_body_energy_state()].
#' @param gut_parameters A gut-energy parameter record created by
#'   [new_gut_energy_parameters()].
#' @param body_parameters A body-energy parameter record created by
#'   [new_body_energy_parameters()].
#' @param food_parameters A food-energy parameter record created by
#'   [new_food_energy_parameters()].
#' @param appetite_parameters An appetite-control parameter record created by
#'   [new_appetite_control_parameters()].
#' @param appetite_reference_schedule A 24-row schedule created by
#'   [new_appetite_reference_schedule()].
#' @param forage_acquisition_ceiling_schedule A 24-row schedule created by
#'   [new_forage_acquisition_ceiling_schedule()].
#' @param routine_activity_schedule A 24-row schedule created by
#'   [new_routine_activity_expenditure_schedule()].
#' @param number_of_days One finite whole numeric value from 1 to
#'   `.Machine$integer.max`.
#'
#' @return A plain list containing a `24 * number_of_days`-row `hourly` ledger
#'   and a `number_of_days`-row `daily` summary.
#' @export
run_appetite_controlled_energy_days <- function(
  initial_gut_state,
  initial_body_state,
  gut_parameters,
  body_parameters,
  food_parameters,
  appetite_parameters,
  appetite_reference_schedule,
  forage_acquisition_ceiling_schedule,
  routine_activity_schedule,
  number_of_days
) {
  .validate_gut_energy_state(initial_gut_state)
  .validate_body_energy_state(initial_body_state)
  .validate_gut_energy_parameters(gut_parameters)
  .validate_body_energy_parameters(body_parameters)
  .validate_food_energy_parameters(food_parameters)
  .validate_appetite_control_parameters(appetite_parameters)
  .validate_appetite_reference_schedule(appetite_reference_schedule)
  .validate_forage_acquisition_ceiling_schedule(
    forage_acquisition_ceiling_schedule
  )
  .validate_routine_activity_expenditure_schedule(
    routine_activity_schedule
  )
  number_of_days <- .validate_number_of_simulation_days(number_of_days)

  initial_gut_energy_kj <- as.double(initial_gut_state$gut_available_energy_kj)
  initial_body_energy_kj <- as.double(initial_body_state$body_energy_reserve_kj)
  gut_release_fraction_h <- as.double(gut_parameters$gut_release_fraction_h)
  maintenance_expenditure_kj_h <- as.double(
    body_parameters$maintenance_expenditure_kj_h
  )
  energy_density_kj_kg_dm <- as.double(
    food_parameters$metabolizable_energy_density_kj_kg_dm
  )
  maximum_intake_kg_dm_h <- as.double(
    appetite_parameters$maximum_dry_matter_intake_kg_dm_h
  )
  body_feedback_fraction_h <- as.double(
    appetite_parameters$body_energy_feedback_fraction_h
  )
  gut_feedback_fraction_h <- as.double(
    appetite_parameters$gut_energy_feedback_fraction_h
  )
  hour_of_day <- as.integer(appetite_reference_schedule$hour_of_day)
  feeding_opportunity_open <- as.logical(
    appetite_reference_schedule$feeding_opportunity_open
  )
  reference_intake_kg_dm_h <- as.double(
    appetite_reference_schedule$reference_dry_matter_intake_kg_dm_h
  )
  reference_body_energy_kj <- as.double(
    appetite_reference_schedule$reference_body_energy_reserve_kj
  )
  reference_gut_energy_kj <- as.double(
    appetite_reference_schedule$reference_gut_available_energy_kj
  )
  forage_acquisition_ceiling_kg_dm_h <- as.double(
    forage_acquisition_ceiling_schedule$forage_acquisition_ceiling_kg_dm_h
  )
  routine_activity_kj_h <- as.double(
    routine_activity_schedule$prescribed_routine_activity_expenditure_kj_h
  )

  .validate_appetite_reference_maximum(
    reference_intake_kg_dm_h,
    maximum_intake_kg_dm_h,
    paste0(
      "appetite_reference_schedule$",
      "reference_dry_matter_intake_kg_dm_h"
    )
  )

  day_results <- vector("list", number_of_days)
  current_gut_energy_kj <- initial_gut_energy_kj
  current_body_energy_kj <- initial_body_energy_kj

  for (simulation_day in seq_len(number_of_days)) {
    day_result <- .run_appetite_controlled_energy_day_prevalidated(
      current_gut_energy_kj,
      current_body_energy_kj,
      gut_release_fraction_h,
      maintenance_expenditure_kj_h,
      energy_density_kj_kg_dm,
      maximum_intake_kg_dm_h,
      body_feedback_fraction_h,
      gut_feedback_fraction_h,
      hour_of_day,
      feeding_opportunity_open,
      reference_intake_kg_dm_h,
      reference_body_energy_kj,
      reference_gut_energy_kj,
      forage_acquisition_ceiling_kg_dm_h,
      routine_activity_kj_h
    )
    time_offset_h <- as.double(simulation_day - 1L) * 24
    day_result$hourly$time_start_h <-
      day_result$hourly$time_start_h + time_offset_h
    day_result$hourly$time_end_h <-
      day_result$hourly$time_end_h + time_offset_h
    day_result$hourly <- data.frame(
      simulation_day = rep.int(as.integer(simulation_day), 24L),
      day_result$hourly,
      check.names = FALSE
    )
    day_result$daily <- data.frame(
      simulation_day = as.integer(simulation_day),
      day_result$daily,
      check.names = FALSE
    )
    day_results[[simulation_day]] <- day_result
    current_gut_energy_kj <-
      day_result$daily$gut_available_energy_final_kj[[1L]]
    current_body_energy_kj <-
      day_result$daily$body_energy_reserve_final_kj[[1L]]
  }

  hourly <- do.call(rbind, lapply(day_results, `[[`, "hourly"))
  daily <- do.call(rbind, lapply(day_results, `[[`, "daily"))
  row.names(hourly) <- NULL
  row.names(daily) <- NULL

  list(hourly = hourly, daily = daily)
}

.validate_number_of_simulation_days <- function(value) {
  if (
    !.is_whole_number(value) ||
      length(value) != 1L ||
      as.double(value) < 1 ||
      as.double(value) > .Machine$integer.max
  ) {
    stop(
      paste0(
        "`number_of_days` must be one finite whole numeric value from 1 ",
        "to `.Machine$integer.max`."
      ),
      call. = FALSE
    )
  }

  as.integer(value)
}

.run_appetite_controlled_energy_day_prevalidated <- function(
  initial_gut_energy_kj,
  initial_body_energy_kj,
  gut_release_fraction_h,
  maintenance_expenditure_kj_h,
  energy_density_kj_kg_dm,
  maximum_intake_kg_dm_h,
  body_feedback_fraction_h,
  gut_feedback_fraction_h,
  hour_of_day,
  feeding_opportunity_open,
  reference_intake_kg_dm_h,
  reference_body_energy_kj,
  reference_gut_energy_kj,
  forage_acquisition_ceiling_kg_dm_h,
  routine_activity_kj_h
) {
  hourly <- data.frame(
    hour_of_day = hour_of_day,
    time_start_h = as.double(hour_of_day),
    time_end_h = as.double(hour_of_day + 1L),
    feeding_opportunity_open = feeding_opportunity_open,
    reference_dry_matter_intake_kg_dm_h = reference_intake_kg_dm_h,
    maximum_dry_matter_intake_kg_dm_h = rep(
      maximum_intake_kg_dm_h,
      24L
    ),
    reference_ingested_available_energy_kj_h =
      reference_intake_kg_dm_h * energy_density_kj_kg_dm,
    body_energy_deviation_from_reference_kj = numeric(24L),
    body_energy_feedback_kj_h = numeric(24L),
    gut_energy_deviation_from_reference_kj = numeric(24L),
    gut_energy_feedback_kj_h = numeric(24L),
    unconstrained_ingested_available_energy_kj_h = numeric(24L),
    unconstrained_dry_matter_intake_kg_dm_h = numeric(24L),
    appetite_target_dry_matter_intake_kg_dm_h = numeric(24L),
    appetite_target_ingested_available_energy_kj_h = numeric(24L),
    lower_intake_bound_active = logical(24L),
    upper_intake_bound_active = logical(24L),
    forage_acquisition_ceiling_kg_dm_h =
      forage_acquisition_ceiling_kg_dm_h,
    forage_acquisition_ceiling_active = logical(24L),
    realized_dry_matter_intake_kg_dm_h = numeric(24L),
    realized_ingested_available_energy_kj_h = numeric(24L),
    gut_available_energy_start_kj = numeric(24L),
    gut_release_fraction_h = rep(gut_release_fraction_h, 24L),
    assimilated_energy_kj_h = numeric(24L),
    realized_ingested_available_energy_kj = numeric(24L),
    assimilated_energy_kj = numeric(24L),
    gut_energy_change_kj = numeric(24L),
    gut_available_energy_end_kj = numeric(24L),
    gut_energy_balance_residual_kj = numeric(24L),
    body_energy_reserve_start_kj = numeric(24L),
    maintenance_expenditure_kj_h = rep(
      maintenance_expenditure_kj_h,
      24L
    ),
    prescribed_routine_activity_expenditure_kj_h =
      routine_activity_kj_h,
    net_body_energy_rate_kj_h = numeric(24L),
    maintenance_expenditure_kj = numeric(24L),
    prescribed_routine_activity_expenditure_kj = numeric(24L),
    body_energy_change_kj = numeric(24L),
    body_energy_reserve_end_kj = numeric(24L),
    body_energy_balance_residual_kj = numeric(24L),
    total_system_energy_start_kj = numeric(24L),
    total_system_energy_end_kj = numeric(24L),
    system_energy_balance_residual_kj = numeric(24L)
  )

  current_gut_energy_kj <- initial_gut_energy_kj
  current_body_energy_kj <- initial_body_energy_kj

  for (row_index in seq_len(24L)) {
    control <- .calculate_appetite_target_core(
      current_gut_energy_kj,
      current_body_energy_kj,
      energy_density_kj_kg_dm,
      maximum_intake_kg_dm_h,
      body_feedback_fraction_h,
      gut_feedback_fraction_h,
      feeding_opportunity_open[[row_index]],
      reference_intake_kg_dm_h[[row_index]],
      reference_body_energy_kj[[row_index]],
      reference_gut_energy_kj[[row_index]]
    )
    appetite_target_kg_dm_h <-
      control$appetite_target_dry_matter_intake_kg_dm_h
    forage_ceiling_kg_dm_h <-
      forage_acquisition_ceiling_kg_dm_h[[row_index]]
    forage_ceiling_active <-
      appetite_target_kg_dm_h > forage_ceiling_kg_dm_h
    realized_intake_kg_dm_h <- min(
      appetite_target_kg_dm_h,
      forage_ceiling_kg_dm_h
    )
    realized_intake_energy_kj_h <-
      realized_intake_kg_dm_h * energy_density_kj_kg_dm
    transition <- .step_gut_body_energy_core(
      current_gut_energy_kj,
      current_body_energy_kj,
      gut_release_fraction_h,
      maintenance_expenditure_kj_h,
      realized_intake_energy_kj_h,
      routine_activity_kj_h[[row_index]]
    )
    gut_transition <- transition$gut
    body_transition <- transition$body
    gut_energy_start_kj <- transition$system$gut_energy_start_kj
    body_energy_start_kj <- transition$system$body_energy_start_kj
    gut_energy_end_kj <-
      gut_transition$state$gut_available_energy_kj
    body_energy_end_kj <-
      body_transition$state$body_energy_reserve_kj
    realized_ingested_energy_kj <-
      gut_transition$fluxes$prescribed_ingested_available_energy_kj
    assimilated_energy_kj <-
      gut_transition$fluxes$assimilated_energy_kj
    maintenance_energy_kj <-
      body_transition$fluxes$maintenance_expenditure_kj
    routine_activity_energy_kj <-
      body_transition$fluxes$
        prescribed_routine_activity_expenditure_kj
    total_system_energy_start_kj <- transition$system$total_energy_start_kj
    total_system_energy_end_kj <- transition$system$total_energy_end_kj
    system_energy_balance_residual_kj <-
      transition$system$energy_balance_residual_kj

    controller_names <- names(control)
    for (field_name in controller_names) {
      hourly[[field_name]][[row_index]] <- control[[field_name]]
    }
    hourly$forage_acquisition_ceiling_active[[row_index]] <-
      forage_ceiling_active
    hourly$realized_dry_matter_intake_kg_dm_h[[row_index]] <-
      realized_intake_kg_dm_h
    hourly$realized_ingested_available_energy_kj_h[[row_index]] <-
      realized_intake_energy_kj_h
    hourly$gut_available_energy_start_kj[[row_index]] <-
      gut_energy_start_kj
    hourly$assimilated_energy_kj_h[[row_index]] <-
      gut_transition$fluxes$assimilated_energy_kj_h
    hourly$realized_ingested_available_energy_kj[[row_index]] <-
      realized_ingested_energy_kj
    hourly$assimilated_energy_kj[[row_index]] <- assimilated_energy_kj
    hourly$gut_energy_change_kj[[row_index]] <-
      gut_transition$fluxes$gut_energy_change_kj
    hourly$gut_available_energy_end_kj[[row_index]] <- gut_energy_end_kj
    hourly$gut_energy_balance_residual_kj[[row_index]] <-
      gut_transition$fluxes$gut_energy_balance_residual_kj
    hourly$body_energy_reserve_start_kj[[row_index]] <-
      body_energy_start_kj
    hourly$net_body_energy_rate_kj_h[[row_index]] <-
      body_transition$fluxes$net_body_energy_rate_kj_h
    hourly$maintenance_expenditure_kj[[row_index]] <-
      maintenance_energy_kj
    hourly$prescribed_routine_activity_expenditure_kj[[row_index]] <-
      routine_activity_energy_kj
    hourly$body_energy_change_kj[[row_index]] <-
      body_transition$fluxes$body_energy_change_kj
    hourly$body_energy_reserve_end_kj[[row_index]] <-
      body_energy_end_kj
    hourly$body_energy_balance_residual_kj[[row_index]] <-
      body_transition$fluxes$energy_balance_residual_kj
    hourly$total_system_energy_start_kj[[row_index]] <-
      total_system_energy_start_kj
    hourly$total_system_energy_end_kj[[row_index]] <-
      total_system_energy_end_kj
    hourly$system_energy_balance_residual_kj[[row_index]] <-
      system_energy_balance_residual_kj

    current_gut_energy_kj <- gut_energy_end_kj
    current_body_energy_kj <- body_energy_end_kj
  }

  daily <- .summarize_appetite_controlled_energy_day(
    hourly,
    reference_gut_energy_kj[[1L]],
    reference_body_energy_kj[[1L]]
  )

  list(hourly = hourly, daily = daily)
}

.summarize_appetite_controlled_energy_day <- function(
  hourly,
  next_day_reference_gut_energy_kj,
  next_day_reference_body_energy_kj
) {
  accounting_hourly <- hourly
  accounting_hourly$prescribed_ingested_available_energy_kj <-
    accounting_hourly$realized_ingested_available_energy_kj
  accounting <- .summarize_gut_body_energy_day(accounting_hourly)
  names(accounting)[
    names(accounting) == "total_prescribed_ingested_available_energy_kj"
  ] <- "total_realized_ingested_available_energy_kj"

  gut_deviation_final_kj <-
    accounting$gut_available_energy_final_kj -
      next_day_reference_gut_energy_kj
  body_deviation_final_kj <-
    accounting$body_energy_reserve_final_kj -
      next_day_reference_body_energy_kj
  combined_deviation_final_kj <-
    gut_deviation_final_kj + body_deviation_final_kj

  data.frame(
    reference_dry_matter_intake_kg_dm =
      sum(hourly$reference_dry_matter_intake_kg_dm_h),
    appetite_target_dry_matter_intake_kg_dm =
      sum(hourly$appetite_target_dry_matter_intake_kg_dm_h),
    realized_dry_matter_intake_kg_dm =
      sum(hourly$realized_dry_matter_intake_kg_dm_h),
    total_reference_ingested_available_energy_kj =
      sum(hourly$reference_ingested_available_energy_kj_h),
    total_appetite_target_ingested_available_energy_kj =
      sum(hourly$appetite_target_ingested_available_energy_kj_h),
    lower_intake_bound_hours = as.integer(
      sum(hourly$lower_intake_bound_active)
    ),
    upper_intake_bound_hours = as.integer(
      sum(hourly$upper_intake_bound_active)
    ),
    forage_acquisition_ceiling_active_hours = as.integer(
      sum(hourly$forage_acquisition_ceiling_active)
    ),
    accounting,
    gut_energy_deviation_from_reference_final_kj =
      gut_deviation_final_kj,
    body_energy_deviation_from_reference_final_kj =
      body_deviation_final_kj,
    combined_energy_deviation_from_reference_final_kj =
      combined_deviation_final_kj,
    check.names = FALSE
  )
}
