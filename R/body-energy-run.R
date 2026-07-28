#' Run the body-energy ledger for one day
#'
#' Apply 24 fixed one-hour body-energy transitions and derive a daily energy
#' summary from the resulting hourly ledger.
#'
#' @param initial_state A plain body-energy state record created by
#'   [new_body_energy_state()].
#' @param parameters A plain body-energy parameter record created by
#'   [new_body_energy_parameters()].
#' @param schedule A 24-row schedule created by
#'   [new_assimilated_energy_schedule()].
#' @param routine_activity_schedule A 24-row schedule created by
#'   [new_routine_activity_expenditure_schedule()].
#'
#' @return A plain list containing a 24-row `hourly` data frame and a one-row
#'   `daily` data frame.
#' @export
run_body_energy_day <- function(
  initial_state,
  parameters,
  schedule,
  routine_activity_schedule
) {
  .validate_body_energy_state(initial_state)
  .validate_body_energy_parameters(parameters)
  .validate_assimilated_energy_schedule(schedule)
  .validate_routine_activity_expenditure_schedule(
    routine_activity_schedule
  )

  hourly <- data.frame(
    hour_of_day = schedule$hour_of_day,
    time_start_h = as.numeric(schedule$hour_of_day),
    time_end_h = as.numeric(schedule$hour_of_day + 1L),
    body_energy_reserve_start_kj = numeric(24),
    prescribed_assimilated_energy_kj_h =
      schedule$prescribed_assimilated_energy_kj_h,
    maintenance_expenditure_kj_h = rep(
      parameters$maintenance_expenditure_kj_h,
      24
    ),
    prescribed_routine_activity_expenditure_kj_h =
      routine_activity_schedule$
        prescribed_routine_activity_expenditure_kj_h,
    net_body_energy_rate_kj_h = numeric(24),
    prescribed_assimilated_energy_kj = numeric(24),
    maintenance_expenditure_kj = numeric(24),
    prescribed_routine_activity_expenditure_kj = numeric(24),
    body_energy_change_kj = numeric(24),
    body_energy_reserve_end_kj = numeric(24),
    energy_balance_residual_kj = numeric(24)
  )

  current_state <- initial_state
  for (row_index in seq_len(24L)) {
    hourly$body_energy_reserve_start_kj[[row_index]] <-
      current_state$body_energy_reserve_kj
    transition <- step_body_energy(
      current_state,
      parameters,
      schedule[row_index, , drop = FALSE],
      routine_activity_schedule[row_index, , drop = FALSE]
    )
    hourly$net_body_energy_rate_kj_h[[row_index]] <-
      transition$fluxes$net_body_energy_rate_kj_h
    hourly$prescribed_assimilated_energy_kj[[row_index]] <-
      transition$fluxes$prescribed_assimilated_energy_kj
    hourly$maintenance_expenditure_kj[[row_index]] <-
      transition$fluxes$maintenance_expenditure_kj
    hourly$prescribed_routine_activity_expenditure_kj[[row_index]] <-
      transition$fluxes$prescribed_routine_activity_expenditure_kj
    hourly$body_energy_change_kj[[row_index]] <-
      transition$fluxes$body_energy_change_kj
    hourly$body_energy_reserve_end_kj[[row_index]] <-
      transition$state$body_energy_reserve_kj
    hourly$energy_balance_residual_kj[[row_index]] <-
      transition$fluxes$energy_balance_residual_kj
    current_state <- transition$state
  }

  body_energy_reserve_initial_kj <-
    hourly$body_energy_reserve_start_kj[[1L]]
  total_prescribed_assimilated_energy_kj <-
    sum(hourly$prescribed_assimilated_energy_kj)
  total_maintenance_expenditure_kj <-
    sum(hourly$maintenance_expenditure_kj)
  total_prescribed_routine_activity_expenditure_kj <-
    sum(hourly$prescribed_routine_activity_expenditure_kj)
  if (!is.finite(total_prescribed_assimilated_energy_kj)) {
    stop(
      "The daily total prescribed assimilated energy must be finite.",
      call. = FALSE
    )
  }
  if (!is.finite(total_maintenance_expenditure_kj)) {
    stop(
      "The daily total maintenance expenditure must be finite.",
      call. = FALSE
    )
  }
  if (!is.finite(total_prescribed_routine_activity_expenditure_kj)) {
    stop(
      "The daily total prescribed routine-activity expenditure must be finite.",
      call. = FALSE
    )
  }
  expected_body_energy_change_kj <-
    total_prescribed_assimilated_energy_kj -
      total_maintenance_expenditure_kj -
      total_prescribed_routine_activity_expenditure_kj
  if (!is.finite(expected_body_energy_change_kj)) {
    stop("The expected daily body-energy change must be finite.", call. = FALSE)
  }
  body_energy_reserve_final_kj <-
    hourly$body_energy_reserve_end_kj[[24L]]
  observed_body_energy_change_kj <-
    body_energy_reserve_final_kj - body_energy_reserve_initial_kj
  if (!is.finite(observed_body_energy_change_kj)) {
    stop("The observed daily body-energy change must be finite.", call. = FALSE)
  }
  energy_balance_residual_kj <-
    observed_body_energy_change_kj - expected_body_energy_change_kj
  if (!is.finite(energy_balance_residual_kj)) {
    stop("The daily body-energy balance residual must be finite.", call. = FALSE)
  }
  tolerance <- .body_energy_tolerance(
    body_energy_reserve_initial_kj,
    body_energy_reserve_final_kj,
    hourly$prescribed_assimilated_energy_kj,
    hourly$maintenance_expenditure_kj,
    hourly$prescribed_routine_activity_expenditure_kj
  )

  if (abs(energy_balance_residual_kj) > tolerance) {
    stop("The daily body-energy balance does not close.", call. = FALSE)
  }
  energy_status <- if (abs(observed_body_energy_change_kj) <= tolerance) {
    "neutral"
  } else if (observed_body_energy_change_kj < -tolerance) {
    "deficit"
  } else {
    "surplus"
  }

  daily <- data.frame(
    body_energy_reserve_initial_kj = body_energy_reserve_initial_kj,
    total_prescribed_assimilated_energy_kj =
      total_prescribed_assimilated_energy_kj,
    total_maintenance_expenditure_kj =
      total_maintenance_expenditure_kj,
    total_prescribed_routine_activity_expenditure_kj =
      total_prescribed_routine_activity_expenditure_kj,
    expected_body_energy_change_kj = expected_body_energy_change_kj,
    observed_body_energy_change_kj = observed_body_energy_change_kj,
    body_energy_reserve_final_kj = body_energy_reserve_final_kj,
    energy_balance_residual_kj = energy_balance_residual_kj,
    energy_status = energy_status
  )

  list(hourly = hourly, daily = daily)
}

.validate_assimilated_energy_schedule <- function(schedule) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_assimilated_energy_kj_h"
  )
  if (
    !identical(class(schedule), "data.frame") ||
      !identical(dim(schedule), c(24L, 2L)) ||
      !identical(names(schedule), expected_names)
  ) {
    stop(
      "`schedule` must be the exact 24-row assimilated-energy data frame.",
      call. = FALSE
    )
  }

  .validate_assimilated_energy_schedule_fields(
    schedule$hour_of_day,
    schedule$prescribed_assimilated_energy_kj_h
  )
  if (typeof(schedule$prescribed_assimilated_energy_kj_h) != "double") {
    stop(
      paste0(
        "`schedule$prescribed_assimilated_energy_kj_h` must retain double ",
        "storage from the schedule constructor."
      ),
      call. = FALSE
    )
  }
}
