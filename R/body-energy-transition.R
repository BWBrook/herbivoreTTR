#' Advance the body-energy ledger by one hour
#'
#' Apply one fixed one-hour transition to a body-energy state using prescribed
#' already-assimilated energy, fixed maintenance expenditure, and prescribed
#' routine-activity expenditure.
#'
#' @param state A body-energy state record created by
#'   [new_body_energy_state()].
#' @param parameters A body-energy parameter record created by
#'   [new_body_energy_parameters()].
#' @param input_row Exactly one row from a validated schedule created by
#'   [new_assimilated_energy_schedule()].
#' @param activity_row Exactly one row from a validated schedule created by
#'   [new_routine_activity_expenditure_schedule()]. Its `hour_of_day` must
#'   match `input_row`.
#'
#' @return A plain list containing the closing `state` and the one-hour
#'   `fluxes`. A proposed negative closing reserve raises an error.
#' @export
step_body_energy <- function(state, parameters, input_row, activity_row) {
  .validate_body_energy_state(state)
  .validate_body_energy_parameters(parameters)
  .validate_assimilated_energy_input_row(input_row)
  .validate_routine_activity_expenditure_input_row(activity_row)
  if (
    as.double(input_row$hour_of_day) !=
      as.double(activity_row$hour_of_day)
  ) {
    stop(
      "`activity_row$hour_of_day` must match `input_row$hour_of_day`.",
      call. = FALSE
    )
  }

  .step_body_energy_core(
    as.double(state$body_energy_reserve_kj),
    as.double(parameters$maintenance_expenditure_kj_h),
    as.double(input_row$prescribed_assimilated_energy_kj_h),
    as.double(
      activity_row$prescribed_routine_activity_expenditure_kj_h
    )
  )
}

.step_body_energy_core <- function(
  body_energy_reserve_start_kj,
  maintenance_expenditure_kj_h,
  prescribed_assimilated_energy_kj_h,
  prescribed_routine_activity_expenditure_kj_h
) {
  prescribed_assimilated_energy_kj <-
    prescribed_assimilated_energy_kj_h
  maintenance_expenditure_kj <-
    maintenance_expenditure_kj_h
  prescribed_routine_activity_expenditure_kj <-
    prescribed_routine_activity_expenditure_kj_h
  net_body_energy_rate_kj_h <-
    prescribed_assimilated_energy_kj_h -
      maintenance_expenditure_kj_h -
      prescribed_routine_activity_expenditure_kj_h
  body_energy_change_kj <-
    prescribed_assimilated_energy_kj -
      maintenance_expenditure_kj -
      prescribed_routine_activity_expenditure_kj
  body_energy_reserve_end_kj <-
    body_energy_reserve_start_kj + body_energy_change_kj

  if (!is.finite(body_energy_reserve_end_kj)) {
    stop("The proposed closing body-energy reserve must be finite.", call. = FALSE)
  }
  if (body_energy_reserve_end_kj < 0) {
    stop("The proposed closing body-energy reserve is negative.", call. = FALSE)
  }

  energy_balance_residual_kj <-
    (body_energy_reserve_end_kj - body_energy_reserve_start_kj) -
      body_energy_change_kj
  if (!is.finite(energy_balance_residual_kj)) {
    stop("The hourly body-energy balance residual must be finite.", call. = FALSE)
  }
  tolerance <- .body_energy_tolerance(
    body_energy_reserve_start_kj,
    body_energy_reserve_end_kj,
    prescribed_assimilated_energy_kj,
    maintenance_expenditure_kj,
    prescribed_routine_activity_expenditure_kj
  )
  if (abs(energy_balance_residual_kj) > tolerance) {
    stop("The hourly body-energy balance does not close.", call. = FALSE)
  }

  list(
    state = list(body_energy_reserve_kj = body_energy_reserve_end_kj),
    fluxes = list(
      prescribed_assimilated_energy_kj =
        prescribed_assimilated_energy_kj,
      maintenance_expenditure_kj = maintenance_expenditure_kj,
      prescribed_routine_activity_expenditure_kj =
        prescribed_routine_activity_expenditure_kj,
      net_body_energy_rate_kj_h = net_body_energy_rate_kj_h,
      body_energy_change_kj = body_energy_change_kj,
      energy_balance_residual_kj = energy_balance_residual_kj
    )
  )
}

.validate_body_energy_state <- function(state) {
  if (
    !.has_exact_named_fields(state, "body_energy_reserve_kj")
  ) {
    stop(
      "`state` must contain only `body_energy_reserve_kj`.",
      call. = FALSE
    )
  }

  .validate_nonnegative_numeric_scalar(
    state$body_energy_reserve_kj,
    "state$body_energy_reserve_kj"
  )
}

.validate_body_energy_parameters <- function(parameters) {
  if (
    !.has_exact_named_fields(
      parameters,
      "maintenance_expenditure_kj_h"
    )
  ) {
    stop(
      paste0(
        "`parameters` must contain only ",
        "`maintenance_expenditure_kj_h`."
      ),
      call. = FALSE
    )
  }

  .validate_nonnegative_numeric_scalar(
    parameters$maintenance_expenditure_kj_h,
    "parameters$maintenance_expenditure_kj_h"
  )
}

.validate_assimilated_energy_input_row <- function(input_row) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_assimilated_energy_kj_h"
  )
  if (
    !is.data.frame(input_row) ||
      nrow(input_row) != 1L ||
      !.has_exact_named_fields(input_row, expected_names)
  ) {
    stop(
      paste0(
        "`input_row` must be a one-row data frame containing only ",
        "`hour_of_day` and `prescribed_assimilated_energy_kj_h`."
      ),
      call. = FALSE
    )
  }

  if (
    !.is_hour_of_day_scalar(input_row$hour_of_day)
  ) {
    stop(
      "`input_row$hour_of_day` must be one whole numeric value from 0 to 23.",
      call. = FALSE
    )
  }

  .validate_nonnegative_numeric_scalar(
    input_row$prescribed_assimilated_energy_kj_h,
    "input_row$prescribed_assimilated_energy_kj_h"
  )
}

.body_energy_tolerance <- function(
  opening_reserve_kj,
  closing_reserve_kj,
  prescribed_assimilated_energy_amounts_kj,
  maintenance_expenditure_amounts_kj,
  prescribed_routine_activity_expenditure_amounts_kj
) {
  scale <- max(
    1,
    abs(opening_reserve_kj),
    abs(closing_reserve_kj),
    sum(abs(prescribed_assimilated_energy_amounts_kj)),
    sum(abs(maintenance_expenditure_amounts_kj)),
    sum(abs(prescribed_routine_activity_expenditure_amounts_kj))
  )
  if (!is.finite(scale)) {
    stop("The body-energy accounting scale must be finite.", call. = FALSE)
  }

  tolerance <- 100 * .Machine$double.eps * scale
  if (!is.finite(tolerance)) {
    stop("The body-energy accounting tolerance must be finite.", call. = FALSE)
  }

  tolerance
}
