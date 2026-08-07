#' Advance the gut-energy buffer by one hour
#'
#' Release a fixed fraction of opening gut energy, then add the current
#' hour's prescribed ingested available energy. Energy ingested in the current
#' hour cannot be assimilated until a later transition.
#'
#' @param state A gut-energy state record created by
#'   [new_gut_energy_state()].
#' @param parameters A gut-energy parameter record created by
#'   [new_gut_energy_parameters()].
#' @param input_row Exactly one row from a validated schedule created by
#'   [new_ingested_available_energy_schedule()].
#'
#' @return A plain list containing the closing `state` and the one-hour
#'   `fluxes`.
#' @export
step_gut_energy <- function(state, parameters, input_row) {
  .validate_gut_energy_state(state)
  .validate_gut_energy_parameters(parameters)
  .validate_ingested_available_energy_input_row(input_row)

  .step_gut_energy_core(
    as.double(state$gut_available_energy_kj),
    as.double(parameters$gut_release_fraction_h),
    as.double(input_row$prescribed_ingested_available_energy_kj_h)
  )
}

.step_gut_energy_core <- function(
  gut_available_energy_start_kj,
  gut_release_fraction_h,
  prescribed_ingested_available_energy_kj_h
) {
  prescribed_ingested_available_energy_kj <-
    prescribed_ingested_available_energy_kj_h
  assimilated_energy_kj_h <-
    gut_release_fraction_h * gut_available_energy_start_kj
  assimilated_energy_kj <- assimilated_energy_kj_h
  gut_energy_change_kj <-
    prescribed_ingested_available_energy_kj - assimilated_energy_kj
  gut_available_energy_end_kj <-
    gut_available_energy_start_kj + gut_energy_change_kj

  arithmetic <- c(
    prescribed_ingested_available_energy_kj,
    assimilated_energy_kj_h,
    assimilated_energy_kj,
    gut_energy_change_kj,
    gut_available_energy_end_kj
  )
  if (any(!is.finite(arithmetic))) {
    stop("The proposed gut-energy transition must remain finite.", call. = FALSE)
  }
  if (gut_available_energy_end_kj < 0) {
    stop("The proposed closing gut-energy stock is negative.", call. = FALSE)
  }

  gut_energy_balance_residual_kj <-
    (gut_available_energy_end_kj - gut_available_energy_start_kj) -
      (
        prescribed_ingested_available_energy_kj -
          assimilated_energy_kj
      )
  if (!is.finite(gut_energy_balance_residual_kj)) {
    stop("The hourly gut-energy balance residual must be finite.", call. = FALSE)
  }
  tolerance <- .gut_energy_tolerance(
    gut_available_energy_start_kj,
    gut_available_energy_end_kj,
    prescribed_ingested_available_energy_kj,
    assimilated_energy_kj
  )
  if (abs(gut_energy_balance_residual_kj) > tolerance) {
    stop("The hourly gut-energy balance does not close.", call. = FALSE)
  }

  list(
    state = list(
      gut_available_energy_kj = gut_available_energy_end_kj
    ),
    fluxes = list(
      prescribed_ingested_available_energy_kj =
        prescribed_ingested_available_energy_kj,
      assimilated_energy_kj_h = assimilated_energy_kj_h,
      assimilated_energy_kj = assimilated_energy_kj,
      gut_energy_change_kj = gut_energy_change_kj,
      gut_energy_balance_residual_kj = gut_energy_balance_residual_kj
    )
  )
}

.validate_gut_energy_state <- function(state) {
  if (!.has_exact_named_fields(state, "gut_available_energy_kj")) {
    stop(
      "`state` must contain only `gut_available_energy_kj`.",
      call. = FALSE
    )
  }

  .validate_nonnegative_numeric_scalar(
    state$gut_available_energy_kj,
    "state$gut_available_energy_kj"
  )
}

.validate_gut_energy_parameters <- function(parameters) {
  if (!.has_exact_named_fields(parameters, "gut_release_fraction_h")) {
    stop(
      paste0(
        "`parameters` must contain only ",
        "`gut_release_fraction_h`."
      ),
      call. = FALSE
    )
  }

  .validate_gut_release_fraction(parameters$gut_release_fraction_h)
}

.validate_ingested_available_energy_input_row <- function(input_row) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_ingested_available_energy_kj_h"
  )
  if (
    !is.data.frame(input_row) ||
      nrow(input_row) != 1L ||
      !.has_exact_named_fields(input_row, expected_names)
  ) {
    stop(
      paste0(
        "`input_row` must be a one-row data frame containing only ",
        "`hour_of_day` and ",
        "`prescribed_ingested_available_energy_kj_h`."
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
    input_row$prescribed_ingested_available_energy_kj_h,
    "input_row$prescribed_ingested_available_energy_kj_h"
  )
}

.gut_energy_tolerance <- function(
  opening_gut_energy_kj,
  closing_gut_energy_kj,
  prescribed_ingested_available_energy_kj,
  assimilated_energy_kj
) {
  scale <- max(
    1,
    abs(opening_gut_energy_kj),
    abs(closing_gut_energy_kj),
    abs(prescribed_ingested_available_energy_kj),
    abs(assimilated_energy_kj)
  )
  if (!is.finite(scale)) {
    stop("The gut-energy accounting scale must be finite.", call. = FALSE)
  }

  tolerance <- 100 * .Machine$double.eps * scale
  if (!is.finite(tolerance)) {
    stop("The gut-energy accounting tolerance must be finite.", call. = FALSE)
  }

  tolerance
}
