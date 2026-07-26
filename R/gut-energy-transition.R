#' Advance the gut-energy buffer by one hour
#'
#' Release a fixed fraction of opening gut energy, then add the current
#' hour's prescribed ingested available energy. Energy ingested in the current
#' hour cannot be assimilated until a later transition.
#'
#' @param state A plain gut-energy state record created by
#'   [new_gut_energy_state()].
#' @param parameters A plain gut-energy parameter record created by
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

  gut_available_energy_start_kj <- state$gut_available_energy_kj
  prescribed_ingested_available_energy_kj <-
    input_row$prescribed_ingested_available_energy_kj_h
  assimilated_energy_kj_h <-
    parameters$gut_release_fraction_h * gut_available_energy_start_kj
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
  if (!.is_exact_plain_named_list(state, "gut_available_energy_kj")) {
    stop(
      "`state` must be a plain list containing only `gut_available_energy_kj`.",
      call. = FALSE
    )
  }

  .validate_nonnegative_numeric_scalar(
    state$gut_available_energy_kj,
    "state$gut_available_energy_kj"
  )
}

.validate_gut_energy_parameters <- function(parameters) {
  if (!.is_exact_plain_named_list(parameters, "gut_release_fraction_h")) {
    stop(
      paste0(
        "`parameters` must be a plain list containing only ",
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
    !identical(class(input_row), "data.frame") ||
      !identical(dim(input_row), c(1L, 2L)) ||
      !identical(names(input_row), expected_names) ||
      !identical(
        names(attributes(input_row)),
        c("names", "row.names", "class")
      )
  ) {
    stop(
      paste0(
        "`input_row` must be exactly one row from an ingested ",
        "available-energy schedule."
      ),
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
    input_row$prescribed_ingested_available_energy_kj_h,
    "input_row$prescribed_ingested_available_energy_kj_h"
  )
  if (typeof(input_row$prescribed_ingested_available_energy_kj_h) != "double") {
    stop(
      paste0(
        "`input_row$prescribed_ingested_available_energy_kj_h` must retain ",
        "double storage from the schedule constructor."
      ),
      call. = FALSE
    )
  }
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
