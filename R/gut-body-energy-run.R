#' Run the coupled gut and body-energy ledgers for one day
#'
#' Apply 24 fixed one-hour gut transitions, pass each hour's released energy
#' into the existing body-energy transition, and derive daily gut, body, and
#' whole-system energy summaries from the resulting hourly ledger.
#'
#' @param initial_gut_state A plain gut-energy state record created by
#'   [new_gut_energy_state()].
#' @param initial_body_state A plain body-energy state record created by
#'   [new_body_energy_state()].
#' @param gut_parameters A plain gut-energy parameter record created by
#'   [new_gut_energy_parameters()].
#' @param body_parameters A plain body-energy parameter record created by
#'   [new_body_energy_parameters()].
#' @param schedule A 24-row prescribed ingestion schedule created by
#'   [new_ingested_available_energy_schedule()].
#' @param routine_activity_schedule A 24-row schedule created by
#'   [new_routine_activity_expenditure_schedule()].
#'
#' @return A plain list containing a 24-row `hourly` data frame and a one-row
#'   `daily` data frame.
#' @export
run_gut_body_energy_day <- function(
  initial_gut_state,
  initial_body_state,
  gut_parameters,
  body_parameters,
  schedule,
  routine_activity_schedule
) {
  .validate_gut_energy_state(initial_gut_state)
  .validate_body_energy_state(initial_body_state)
  .validate_gut_energy_parameters(gut_parameters)
  .validate_body_energy_parameters(body_parameters)
  .validate_ingested_available_energy_schedule(schedule)
  .validate_routine_activity_expenditure_schedule(
    routine_activity_schedule
  )

  hourly <- data.frame(
    hour_of_day = schedule$hour_of_day,
    time_start_h = as.numeric(schedule$hour_of_day),
    time_end_h = as.numeric(schedule$hour_of_day + 1L),
    gut_available_energy_start_kj = numeric(24L),
    prescribed_ingested_available_energy_kj_h =
      schedule$prescribed_ingested_available_energy_kj_h,
    gut_release_fraction_h = rep(
      gut_parameters$gut_release_fraction_h,
      24L
    ),
    assimilated_energy_kj_h = numeric(24L),
    prescribed_ingested_available_energy_kj = numeric(24L),
    assimilated_energy_kj = numeric(24L),
    gut_energy_change_kj = numeric(24L),
    gut_available_energy_end_kj = numeric(24L),
    gut_energy_balance_residual_kj = numeric(24L),
    body_energy_reserve_start_kj = numeric(24L),
    maintenance_expenditure_kj_h = rep(
      body_parameters$maintenance_expenditure_kj_h,
      24L
    ),
    prescribed_routine_activity_expenditure_kj_h =
      routine_activity_schedule$
        prescribed_routine_activity_expenditure_kj_h,
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

  current_gut_state <- initial_gut_state
  current_body_state <- initial_body_state

  for (row_index in seq_len(24L)) {
    gut_available_energy_start_kj <-
      current_gut_state$gut_available_energy_kj
    body_energy_reserve_start_kj <-
      current_body_state$body_energy_reserve_kj
    gut_transition <- step_gut_energy(
      current_gut_state,
      gut_parameters,
      schedule[row_index, , drop = FALSE]
    )
    assimilated_energy_input <- data.frame(
      hour_of_day = schedule$hour_of_day[[row_index]],
      prescribed_assimilated_energy_kj_h = as.double(
        gut_transition$fluxes$assimilated_energy_kj_h
      )
    )
    body_transition <- step_body_energy(
      current_body_state,
      body_parameters,
      assimilated_energy_input,
      routine_activity_schedule[row_index, , drop = FALSE]
    )

    gut_available_energy_end_kj <-
      gut_transition$state$gut_available_energy_kj
    body_energy_reserve_end_kj <-
      body_transition$state$body_energy_reserve_kj
    prescribed_ingested_available_energy_kj <-
      gut_transition$fluxes$prescribed_ingested_available_energy_kj
    assimilated_energy_kj <-
      gut_transition$fluxes$assimilated_energy_kj
    maintenance_expenditure_kj <-
      body_transition$fluxes$maintenance_expenditure_kj
    prescribed_routine_activity_expenditure_kj <-
      body_transition$fluxes$
        prescribed_routine_activity_expenditure_kj
    total_system_energy_start_kj <-
      gut_available_energy_start_kj + body_energy_reserve_start_kj
    total_system_energy_end_kj <-
      gut_available_energy_end_kj + body_energy_reserve_end_kj
    system_energy_balance_residual_kj <-
      (
        total_system_energy_end_kj -
          total_system_energy_start_kj
      ) - (
        prescribed_ingested_available_energy_kj -
          maintenance_expenditure_kj -
          prescribed_routine_activity_expenditure_kj
      )

    system_arithmetic <- c(
      total_system_energy_start_kj,
      total_system_energy_end_kj,
      system_energy_balance_residual_kj
    )
    if (any(!is.finite(system_arithmetic))) {
      stop(
        "The hourly whole-system energy accounting must remain finite.",
        call. = FALSE
      )
    }
    system_tolerance <- .gut_body_hourly_system_tolerance(
      gut_available_energy_start_kj,
      gut_available_energy_end_kj,
      body_energy_reserve_start_kj,
      body_energy_reserve_end_kj,
      prescribed_ingested_available_energy_kj,
      assimilated_energy_kj,
      maintenance_expenditure_kj,
      prescribed_routine_activity_expenditure_kj
    )
    if (abs(system_energy_balance_residual_kj) > system_tolerance) {
      stop(
        "The hourly whole-system energy balance does not close.",
        call. = FALSE
      )
    }

    hourly$gut_available_energy_start_kj[[row_index]] <-
      gut_available_energy_start_kj
    hourly$assimilated_energy_kj_h[[row_index]] <-
      gut_transition$fluxes$assimilated_energy_kj_h
    hourly$prescribed_ingested_available_energy_kj[[row_index]] <-
      prescribed_ingested_available_energy_kj
    hourly$assimilated_energy_kj[[row_index]] <-
      assimilated_energy_kj
    hourly$gut_energy_change_kj[[row_index]] <-
      gut_transition$fluxes$gut_energy_change_kj
    hourly$gut_available_energy_end_kj[[row_index]] <-
      gut_available_energy_end_kj
    hourly$gut_energy_balance_residual_kj[[row_index]] <-
      gut_transition$fluxes$gut_energy_balance_residual_kj
    hourly$body_energy_reserve_start_kj[[row_index]] <-
      body_energy_reserve_start_kj
    hourly$maintenance_expenditure_kj[[row_index]] <-
      maintenance_expenditure_kj
    hourly$net_body_energy_rate_kj_h[[row_index]] <-
      body_transition$fluxes$net_body_energy_rate_kj_h
    hourly$prescribed_routine_activity_expenditure_kj[[row_index]] <-
      prescribed_routine_activity_expenditure_kj
    hourly$body_energy_change_kj[[row_index]] <-
      body_transition$fluxes$body_energy_change_kj
    hourly$body_energy_reserve_end_kj[[row_index]] <-
      body_energy_reserve_end_kj
    hourly$body_energy_balance_residual_kj[[row_index]] <-
      body_transition$fluxes$energy_balance_residual_kj
    hourly$total_system_energy_start_kj[[row_index]] <-
      total_system_energy_start_kj
    hourly$total_system_energy_end_kj[[row_index]] <-
      total_system_energy_end_kj
    hourly$system_energy_balance_residual_kj[[row_index]] <-
      system_energy_balance_residual_kj

    current_gut_state <- gut_transition$state
    current_body_state <- body_transition$state
  }

  daily <- .summarize_gut_body_energy_day(hourly)

  list(hourly = hourly, daily = daily)
}

.summarize_gut_body_energy_day <- function(hourly) {
  gut_available_energy_initial_kj <-
    hourly$gut_available_energy_start_kj[[1L]]
  gut_available_energy_final_kj <-
    hourly$gut_available_energy_end_kj[[24L]]
  body_energy_reserve_initial_kj <-
    hourly$body_energy_reserve_start_kj[[1L]]
  body_energy_reserve_final_kj <-
    hourly$body_energy_reserve_end_kj[[24L]]
  total_prescribed_ingested_available_energy_kj <-
    sum(hourly$prescribed_ingested_available_energy_kj)
  total_assimilated_energy_kj <-
    sum(hourly$assimilated_energy_kj)
  total_maintenance_expenditure_kj <-
    sum(hourly$maintenance_expenditure_kj)
  total_prescribed_routine_activity_expenditure_kj <-
    sum(hourly$prescribed_routine_activity_expenditure_kj)
  total_system_energy_initial_kj <-
    hourly$total_system_energy_start_kj[[1L]]
  total_system_energy_final_kj <-
    hourly$total_system_energy_end_kj[[24L]]

  totals <- c(
    total_prescribed_ingested_available_energy_kj,
    total_assimilated_energy_kj,
    total_maintenance_expenditure_kj,
    total_prescribed_routine_activity_expenditure_kj,
    total_system_energy_initial_kj,
    total_system_energy_final_kj
  )
  if (any(!is.finite(totals))) {
    stop("The daily gut-body energy totals must be finite.", call. = FALSE)
  }

  expected_gut_energy_change_kj <-
    total_prescribed_ingested_available_energy_kj -
      total_assimilated_energy_kj
  observed_gut_energy_change_kj <-
    gut_available_energy_final_kj -
      gut_available_energy_initial_kj
  gut_energy_balance_residual_kj <-
    observed_gut_energy_change_kj -
      expected_gut_energy_change_kj
  expected_body_energy_change_kj <-
    total_assimilated_energy_kj -
      total_maintenance_expenditure_kj -
      total_prescribed_routine_activity_expenditure_kj
  observed_body_energy_change_kj <-
    body_energy_reserve_final_kj -
      body_energy_reserve_initial_kj
  body_energy_balance_residual_kj <-
    observed_body_energy_change_kj -
      expected_body_energy_change_kj
  expected_total_system_energy_change_kj <-
    total_prescribed_ingested_available_energy_kj -
      total_maintenance_expenditure_kj -
      total_prescribed_routine_activity_expenditure_kj
  observed_total_system_energy_change_kj <-
    total_system_energy_final_kj -
      total_system_energy_initial_kj
  system_energy_balance_residual_kj <-
    observed_total_system_energy_change_kj -
      expected_total_system_energy_change_kj

  daily_arithmetic <- c(
    expected_gut_energy_change_kj,
    observed_gut_energy_change_kj,
    gut_energy_balance_residual_kj,
    expected_body_energy_change_kj,
    observed_body_energy_change_kj,
    body_energy_balance_residual_kj,
    expected_total_system_energy_change_kj,
    observed_total_system_energy_change_kj,
    system_energy_balance_residual_kj
  )
  if (any(!is.finite(daily_arithmetic))) {
    stop("The daily gut-body energy accounting must be finite.", call. = FALSE)
  }

  gut_tolerance <- .gut_body_daily_gut_tolerance(
    gut_available_energy_initial_kj,
    gut_available_energy_final_kj,
    hourly$prescribed_ingested_available_energy_kj,
    hourly$assimilated_energy_kj
  )
  body_tolerance <- .body_energy_tolerance(
    body_energy_reserve_initial_kj,
    body_energy_reserve_final_kj,
    hourly$assimilated_energy_kj,
    hourly$maintenance_expenditure_kj,
    hourly$prescribed_routine_activity_expenditure_kj
  )
  system_tolerance <- .gut_body_daily_system_tolerance(
    gut_available_energy_initial_kj,
    gut_available_energy_final_kj,
    body_energy_reserve_initial_kj,
    body_energy_reserve_final_kj,
    hourly$prescribed_ingested_available_energy_kj,
    hourly$assimilated_energy_kj,
    hourly$maintenance_expenditure_kj,
    hourly$prescribed_routine_activity_expenditure_kj
  )

  if (abs(gut_energy_balance_residual_kj) > gut_tolerance) {
    stop("The daily gut-energy balance does not close.", call. = FALSE)
  }
  if (abs(body_energy_balance_residual_kj) > body_tolerance) {
    stop("The daily body-energy balance does not close.", call. = FALSE)
  }
  if (abs(system_energy_balance_residual_kj) > system_tolerance) {
    stop(
      "The daily whole-system energy balance does not close.",
      call. = FALSE
    )
  }

  body_energy_status <- if (
    abs(observed_body_energy_change_kj) <= body_tolerance
  ) {
    "neutral"
  } else if (observed_body_energy_change_kj < -body_tolerance) {
    "deficit"
  } else {
    "surplus"
  }

  data.frame(
    gut_available_energy_initial_kj =
      gut_available_energy_initial_kj,
    total_prescribed_ingested_available_energy_kj =
      total_prescribed_ingested_available_energy_kj,
    total_assimilated_energy_kj =
      total_assimilated_energy_kj,
    expected_gut_energy_change_kj =
      expected_gut_energy_change_kj,
    observed_gut_energy_change_kj =
      observed_gut_energy_change_kj,
    gut_available_energy_final_kj =
      gut_available_energy_final_kj,
    gut_energy_balance_residual_kj =
      gut_energy_balance_residual_kj,
    body_energy_reserve_initial_kj =
      body_energy_reserve_initial_kj,
    total_maintenance_expenditure_kj =
      total_maintenance_expenditure_kj,
    total_prescribed_routine_activity_expenditure_kj =
      total_prescribed_routine_activity_expenditure_kj,
    expected_body_energy_change_kj =
      expected_body_energy_change_kj,
    observed_body_energy_change_kj =
      observed_body_energy_change_kj,
    body_energy_reserve_final_kj =
      body_energy_reserve_final_kj,
    body_energy_balance_residual_kj =
      body_energy_balance_residual_kj,
    total_system_energy_initial_kj =
      total_system_energy_initial_kj,
    expected_total_system_energy_change_kj =
      expected_total_system_energy_change_kj,
    observed_total_system_energy_change_kj =
      observed_total_system_energy_change_kj,
    total_system_energy_final_kj =
      total_system_energy_final_kj,
    system_energy_balance_residual_kj =
      system_energy_balance_residual_kj,
    body_energy_status = body_energy_status
  )
}

.validate_ingested_available_energy_schedule <- function(schedule) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_ingested_available_energy_kj_h"
  )
  if (
    !identical(class(schedule), "data.frame") ||
      !identical(dim(schedule), c(24L, 2L)) ||
      !identical(names(schedule), expected_names) ||
      !identical(
        names(attributes(schedule)),
        c("names", "class", "row.names")
      )
  ) {
    stop(
      paste0(
        "`schedule` must be the exact 24-row ingested ",
        "available-energy data frame."
      ),
      call. = FALSE
    )
  }

  .validate_ingested_available_energy_schedule_fields(
    schedule$hour_of_day,
    schedule$prescribed_ingested_available_energy_kj_h
  )
  if (
    typeof(schedule$prescribed_ingested_available_energy_kj_h) !=
      "double"
  ) {
    stop(
      paste0(
        "`schedule$prescribed_ingested_available_energy_kj_h` must retain ",
        "double storage from the schedule constructor."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.gut_body_hourly_system_tolerance <- function(
  gut_energy_start_kj,
  gut_energy_end_kj,
  body_energy_start_kj,
  body_energy_end_kj,
  prescribed_ingested_available_energy_kj,
  assimilated_energy_kj,
  maintenance_expenditure_kj,
  prescribed_routine_activity_expenditure_kj
) {
  scale <- max(
    1,
    abs(gut_energy_start_kj),
    abs(gut_energy_end_kj),
    abs(body_energy_start_kj),
    abs(body_energy_end_kj),
    abs(prescribed_ingested_available_energy_kj),
    abs(assimilated_energy_kj),
    abs(maintenance_expenditure_kj),
    abs(prescribed_routine_activity_expenditure_kj)
  )
  if (!is.finite(scale)) {
    stop(
      "The hourly whole-system energy accounting scale must be finite.",
      call. = FALSE
    )
  }

  tolerance <- 100 * .Machine$double.eps * scale
  if (!is.finite(tolerance)) {
    stop(
      "The hourly whole-system energy tolerance must be finite.",
      call. = FALSE
    )
  }

  tolerance
}

.gut_body_daily_gut_tolerance <- function(
  opening_gut_energy_kj,
  closing_gut_energy_kj,
  prescribed_ingested_available_energy_amounts_kj,
  assimilated_energy_amounts_kj
) {
  scale <- max(
    1,
    abs(opening_gut_energy_kj),
    abs(closing_gut_energy_kj),
    sum(abs(prescribed_ingested_available_energy_amounts_kj)),
    sum(abs(assimilated_energy_amounts_kj))
  )
  if (!is.finite(scale)) {
    stop(
      "The daily gut-energy accounting scale must be finite.",
      call. = FALSE
    )
  }

  tolerance <- 100 * .Machine$double.eps * scale
  if (!is.finite(tolerance)) {
    stop(
      "The daily gut-energy accounting tolerance must be finite.",
      call. = FALSE
    )
  }

  tolerance
}

.gut_body_daily_system_tolerance <- function(
  opening_gut_energy_kj,
  closing_gut_energy_kj,
  opening_body_energy_kj,
  closing_body_energy_kj,
  prescribed_ingested_available_energy_amounts_kj,
  assimilated_energy_amounts_kj,
  maintenance_expenditure_amounts_kj,
  prescribed_routine_activity_expenditure_amounts_kj
) {
  scale <- max(
    1,
    abs(opening_gut_energy_kj),
    abs(closing_gut_energy_kj),
    abs(opening_body_energy_kj),
    abs(closing_body_energy_kj),
    sum(abs(prescribed_ingested_available_energy_amounts_kj)),
    sum(abs(assimilated_energy_amounts_kj)),
    sum(abs(maintenance_expenditure_amounts_kj)),
    sum(abs(prescribed_routine_activity_expenditure_amounts_kj))
  )
  if (!is.finite(scale)) {
    stop(
      "The daily whole-system energy accounting scale must be finite.",
      call. = FALSE
    )
  }

  tolerance <- 100 * .Machine$double.eps * scale
  if (!is.finite(tolerance)) {
    stop(
      "The daily whole-system energy tolerance must be finite.",
      call. = FALSE
    )
  }

  tolerance
}
