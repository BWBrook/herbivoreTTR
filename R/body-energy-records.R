#' Create a body-energy state
#'
#' Create the dynamic state record for the maintenance-only body-energy
#' ledger.
#'
#' @param body_energy_reserve_kj Finite, non-negative numeric scalar giving
#'   body-energy reserve in kilojoules.
#'
#' @return A plain named list containing `body_energy_reserve_kj`.
#' @export
new_body_energy_state <- function(body_energy_reserve_kj) {
  .validate_nonnegative_numeric_scalar(
    body_energy_reserve_kj,
    "body_energy_reserve_kj"
  )

  list(
    body_energy_reserve_kj = as.double(unclass(body_energy_reserve_kj))
  )
}

#' Create body-energy parameters
#'
#' Create the fixed parameter record for the maintenance-only body-energy
#' ledger.
#'
#' @param maintenance_expenditure_kj_h Finite, non-negative numeric scalar
#'   giving the maintenance expenditure rate in kilojoules per hour.
#'
#' @return A plain named list containing `maintenance_expenditure_kj_h`.
#' @export
new_body_energy_parameters <- function(maintenance_expenditure_kj_h) {
  .validate_nonnegative_numeric_scalar(
    maintenance_expenditure_kj_h,
    "maintenance_expenditure_kj_h"
  )

  list(
    maintenance_expenditure_kj_h =
      as.double(unclass(maintenance_expenditure_kj_h))
  )
}

#' Create an assimilated-energy schedule
#'
#' Create the prescribed already-assimilated energy input for each of the 24
#' one-hour intervals in a day.
#'
#' @param hour_of_day Integer vector equal to `0:23`, in order.
#' @param prescribed_assimilated_energy_kj_h Finite, non-negative numeric
#'   vector of 24 prescribed assimilated-energy rates in kilojoules per hour.
#'
#' @return A base data frame with 24 rows and the columns `hour_of_day` and
#'   `prescribed_assimilated_energy_kj_h`.
#' @export
new_assimilated_energy_schedule <- function(
  hour_of_day,
  prescribed_assimilated_energy_kj_h
) {
  .validate_assimilated_energy_schedule_fields(
    hour_of_day,
    prescribed_assimilated_energy_kj_h
  )

  data.frame(
    hour_of_day = as.integer(unclass(hour_of_day)),
    prescribed_assimilated_energy_kj_h =
      as.double(unclass(prescribed_assimilated_energy_kj_h))
  )
}

.validate_nonnegative_numeric_scalar <- function(value, field_name) {
  if (
    !.is_semantic_numeric_vector(value) ||
      length(value) != 1L ||
      !is.finite(as.double(unclass(value))) ||
      as.double(unclass(value)) < 0
  ) {
    stop(
      sprintf("`%s` must be one finite, non-negative numeric value.", field_name),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.is_semantic_numeric_vector <- function(value) {
  typeof(value) %in% c("integer", "double") &&
    !is.factor(value) &&
    is.null(dim(value))
}

.has_exact_named_fields <- function(value, required_names) {
  is.list(value) &&
    length(value) == length(required_names) &&
    !anyDuplicated(names(value)) &&
    setequal(names(value), required_names)
}

.is_whole_number <- function(value) {
  .is_semantic_numeric_vector(value) &&
    all(is.finite(value)) &&
    all(value == floor(value))
}

.is_hour_of_day_schedule <- function(value) {
  .is_whole_number(value) &&
    length(value) == 24L &&
    all(as.double(unclass(value)) == 0:23)
}

.is_hour_of_day_scalar <- function(value) {
  .is_whole_number(value) &&
    length(value) == 1L &&
    as.double(unclass(value)) >= 0 &&
    as.double(unclass(value)) <= 23
}

.is_bare_numeric_vector <- function(value) {
  .is_semantic_numeric_vector(value)
}

.validate_assimilated_energy_schedule_fields <- function(
  hour_of_day,
  prescribed_assimilated_energy_kj_h
) {
  if (!.is_hour_of_day_schedule(hour_of_day)) {
    stop(
      "`hour_of_day` must contain the ordered whole numeric values `0:23`.",
      call. = FALSE
    )
  }

  if (
    !.is_semantic_numeric_vector(prescribed_assimilated_energy_kj_h) ||
      length(prescribed_assimilated_energy_kj_h) != 24L ||
      any(!is.finite(as.double(unclass(
        prescribed_assimilated_energy_kj_h
      )))) ||
      any(as.double(unclass(prescribed_assimilated_energy_kj_h)) < 0)
  ) {
    stop(
      paste0(
        "`prescribed_assimilated_energy_kj_h` must contain 24 finite, ",
        "non-negative numeric values."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}
