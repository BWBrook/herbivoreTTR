#' Advance the body-energy ledger by one hour
#'
#' Apply one fixed one-hour transition to a body-energy state using prescribed
#' already-assimilated energy and fixed maintenance expenditure.
#'
#' @param state A plain body-energy state record created by
#'   [new_body_energy_state()].
#' @param parameters A plain body-energy parameter record created by
#'   [new_body_energy_parameters()].
#' @param input_row Exactly one row from a validated schedule created by
#'   [new_assimilated_energy_schedule()].
#'
#' @return A plain list containing the closing `state` and the one-hour
#'   `fluxes`. A proposed negative closing reserve raises an error.
#' @export
step_body_energy <- function(state, parameters, input_row) {
  .validate_body_energy_state(state)
  .validate_body_energy_parameters(parameters)
  .validate_assimilated_energy_input_row(input_row)

  body_energy_reserve_start_kj <- state$body_energy_reserve_kj
  prescribed_assimilated_energy_kj <-
    input_row$prescribed_assimilated_energy_kj_h
  maintenance_expenditure_kj <-
    parameters$maintenance_expenditure_kj_h
  net_body_energy_rate_kj_h <-
    input_row$prescribed_assimilated_energy_kj_h -
      parameters$maintenance_expenditure_kj_h
  body_energy_change_kj <-
    prescribed_assimilated_energy_kj - maintenance_expenditure_kj
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
    maintenance_expenditure_kj
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
      net_body_energy_rate_kj_h = net_body_energy_rate_kj_h,
      body_energy_change_kj = body_energy_change_kj,
      energy_balance_residual_kj = energy_balance_residual_kj
    )
  )
}

.validate_body_energy_state <- function(state) {
  if (
    !.is_exact_plain_named_list(state, "body_energy_reserve_kj")
  ) {
    stop(
      "`state` must be a plain list containing only `body_energy_reserve_kj`.",
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
    !.is_exact_plain_named_list(
      parameters,
      "maintenance_expenditure_kj_h"
    )
  ) {
    stop(
      paste0(
        "`parameters` must be a plain list containing only ",
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
    !identical(class(input_row), "data.frame") ||
      !identical(dim(input_row), c(1L, 2L)) ||
      !identical(names(input_row), expected_names)
  ) {
    stop(
      "`input_row` must be exactly one row from an assimilated-energy schedule.",
      call. = FALSE
    )
  }

  if (
    typeof(input_row$hour_of_day) != "integer" ||
      !is.null(attributes(input_row$hour_of_day)) ||
      is.na(input_row$hour_of_day) ||
      input_row$hour_of_day < 0L ||
      input_row$hour_of_day > 23L
  ) {
    stop("`input_row$hour_of_day` must be an integer from 0 to 23.", call. = FALSE)
  }

  .validate_nonnegative_numeric_scalar(
    input_row$prescribed_assimilated_energy_kj_h,
    "input_row$prescribed_assimilated_energy_kj_h"
  )
  if (typeof(input_row$prescribed_assimilated_energy_kj_h) != "double") {
    stop(
      paste0(
        "`input_row$prescribed_assimilated_energy_kj_h` must retain double ",
        "storage from the schedule constructor."
      ),
      call. = FALSE
    )
  }
}

.is_exact_plain_named_list <- function(value, expected_names) {
  identical(typeof(value), "list") &&
    identical(attributes(value), list(names = expected_names))
}

.body_energy_tolerance <- function(
  opening_reserve_kj,
  closing_reserve_kj,
  prescribed_assimilated_energy_amounts_kj,
  maintenance_expenditure_amounts_kj
) {
  scale <- max(
    1,
    abs(opening_reserve_kj),
    abs(closing_reserve_kj),
    sum(abs(prescribed_assimilated_energy_amounts_kj)),
    sum(abs(maintenance_expenditure_amounts_kj))
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
