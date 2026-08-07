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

  initial_body_energy_kj <-
    as.double(unclass(initial_state$body_energy_reserve_kj))
  maintenance_expenditure_kj_h <-
    as.double(unclass(parameters$maintenance_expenditure_kj_h))
  hour_of_day <- as.integer(unclass(schedule$hour_of_day))
  assimilated_energy_kj_h <- as.double(unclass(
    schedule$prescribed_assimilated_energy_kj_h
  ))
  routine_activity_kj_h <- as.double(unclass(
    routine_activity_schedule$
      prescribed_routine_activity_expenditure_kj_h
  ))

  hourly <- data.frame(
    hour_of_day = hour_of_day,
    time_start_h = as.numeric(hour_of_day),
    time_end_h = as.numeric(hour_of_day + 1L),
    body_energy_reserve_start_kj = numeric(24),
    prescribed_assimilated_energy_kj_h = assimilated_energy_kj_h,
    maintenance_expenditure_kj_h = rep(
      maintenance_expenditure_kj_h,
      24
    ),
    prescribed_routine_activity_expenditure_kj_h = routine_activity_kj_h,
    net_body_energy_rate_kj_h = numeric(24),
    prescribed_assimilated_energy_kj = numeric(24),
    maintenance_expenditure_kj = numeric(24),
    prescribed_routine_activity_expenditure_kj = numeric(24),
    body_energy_change_kj = numeric(24),
    body_energy_reserve_end_kj = numeric(24),
    energy_balance_residual_kj = numeric(24)
  )

  current_body_energy_kj <- initial_body_energy_kj
  for (row_index in seq_len(24L)) {
    hourly$body_energy_reserve_start_kj[[row_index]] <-
      current_body_energy_kj
    transition <- .step_body_energy_core(
      current_body_energy_kj,
      maintenance_expenditure_kj_h,
      assimilated_energy_kj_h[[row_index]],
      routine_activity_kj_h[[row_index]]
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
    current_body_energy_kj <-
      transition$state$body_energy_reserve_kj
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
    !is.data.frame(schedule) ||
      nrow(schedule) != 24L ||
      !.has_exact_named_fields(schedule, expected_names)
  ) {
    stop(
      paste0(
        "`schedule` must be a 24-row data frame containing only ",
        "`hour_of_day` and `prescribed_assimilated_energy_kj_h`."
      ),
      call. = FALSE
    )
  }

  .validate_assimilated_energy_schedule_fields(
    schedule$hour_of_day,
    schedule$prescribed_assimilated_energy_kj_h
  )

  invisible(NULL)
}
