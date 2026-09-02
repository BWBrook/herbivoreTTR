#' Create a body-water state
#'
#' Create the dynamic physical water stock carried by one modeled animal.
#'
#' @param body_water_kg Finite, non-negative numeric scalar giving body water
#'   in kilograms.
#'
#' @return A plain named list containing `body_water_kg`.
#' @export
new_body_water_state <- function(body_water_kg) {
  .validate_nonnegative_numeric_scalar(body_water_kg, "body_water_kg")

  list(body_water_kg = as.double(body_water_kg))
}

#' Create body-water parameters
#'
#' Define a normal body-water stock, a lower interpretation boundary, and one
#' fixed ordinary loss rate. The critical boundary is reported but does not
#' itself alter a transition.
#'
#' @param normal_body_water_kg Finite, strictly positive numeric scalar giving
#'   the upper normal body-water stock in kilograms.
#' @param critical_body_water_kg Finite, non-negative numeric scalar below
#'   `normal_body_water_kg`. Crossing it flags the state as critical.
#' @param ordinary_water_loss_kg_h Finite, non-negative numeric scalar giving
#'   the fixed ordinary water-loss rate in kilograms per hour.
#'
#' @return A plain named parameter record.
#' @export
new_body_water_parameters <- function(
  normal_body_water_kg,
  critical_body_water_kg,
  ordinary_water_loss_kg_h
) {
  .validate_body_water_positive_scalar(
    normal_body_water_kg,
    "normal_body_water_kg"
  )
  .validate_nonnegative_numeric_scalar(
    critical_body_water_kg,
    "critical_body_water_kg"
  )
  .validate_nonnegative_numeric_scalar(
    ordinary_water_loss_kg_h,
    "ordinary_water_loss_kg_h"
  )
  if (as.double(critical_body_water_kg) >= as.double(normal_body_water_kg)) {
    stop(
      "`critical_body_water_kg` must be below `normal_body_water_kg`.",
      call. = FALSE
    )
  }

  list(
    normal_body_water_kg = as.double(normal_body_water_kg),
    critical_body_water_kg = as.double(critical_body_water_kg),
    ordinary_water_loss_kg_h = as.double(ordinary_water_loss_kg_h)
  )
}

#' Create a prescribed body-water input schedule
#'
#' Create food-derived water, water available for drinking, and incremental
#' evaporative loss over one fixed 24-hour day. All fields are hourly rates;
#' each transition lasts one hour.
#'
#' @param hour_of_day Numeric vector equal to `0:23`, in order.
#' @param prescribed_food_derived_water_kg_h Finite, non-negative numeric
#'   vector of 24 food-derived water rates in kilograms per hour.
#' @param available_drinking_water_kg_h Finite, non-negative numeric vector of
#'   24 water-availability rates in kilograms per hour.
#' @param prescribed_incremental_evaporative_water_loss_kg_h Finite,
#'   non-negative numeric vector of 24 incremental evaporative-loss rates in
#'   kilograms per hour.
#'
#' @return A canonical 24-row base data frame.
#' @export
new_body_water_schedule <- function(
  hour_of_day,
  prescribed_food_derived_water_kg_h,
  available_drinking_water_kg_h,
  prescribed_incremental_evaporative_water_loss_kg_h
) {
  .validate_body_water_schedule_fields(
    hour_of_day,
    prescribed_food_derived_water_kg_h,
    available_drinking_water_kg_h,
    prescribed_incremental_evaporative_water_loss_kg_h
  )

  data.frame(
    hour_of_day = as.integer(hour_of_day),
    prescribed_food_derived_water_kg_h = as.double(
      prescribed_food_derived_water_kg_h
    ),
    available_drinking_water_kg_h = as.double(
      available_drinking_water_kg_h
    ),
    prescribed_incremental_evaporative_water_loss_kg_h = as.double(
      prescribed_incremental_evaporative_water_loss_kg_h
    )
  )
}

.validate_body_water_positive_scalar <- function(value, field_name) {
  if (
    !.is_numeric_vector(value) ||
      length(value) != 1L ||
      !is.finite(as.double(value)) ||
      as.double(value) <= 0
  ) {
    stop(
      sprintf("`%s` must be one finite, strictly positive value.", field_name),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_body_water_state <- function(state) {
  if (!.has_exact_named_fields(state, "body_water_kg")) {
    stop("`state` must contain only `body_water_kg`.", call. = FALSE)
  }
  .validate_nonnegative_numeric_scalar(
    state$body_water_kg,
    "state$body_water_kg"
  )

  invisible(NULL)
}

.validate_body_water_parameters <- function(parameters) {
  expected_names <- c(
    "normal_body_water_kg",
    "critical_body_water_kg",
    "ordinary_water_loss_kg_h"
  )
  if (!.has_exact_named_fields(parameters, expected_names)) {
    stop(
      paste0(
        "`parameters` must contain only `normal_body_water_kg`, ",
        "`critical_body_water_kg`, and `ordinary_water_loss_kg_h`."
      ),
      call. = FALSE
    )
  }

  .validate_body_water_positive_scalar(
    parameters$normal_body_water_kg,
    "parameters$normal_body_water_kg"
  )
  .validate_nonnegative_numeric_scalar(
    parameters$critical_body_water_kg,
    "parameters$critical_body_water_kg"
  )
  .validate_nonnegative_numeric_scalar(
    parameters$ordinary_water_loss_kg_h,
    "parameters$ordinary_water_loss_kg_h"
  )
  if (
    as.double(parameters$critical_body_water_kg) >=
      as.double(parameters$normal_body_water_kg)
  ) {
    stop(
      paste0(
        "`parameters$critical_body_water_kg` must be below ",
        "`parameters$normal_body_water_kg`."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_body_water_schedule_fields <- function(
  hour_of_day,
  prescribed_food_derived_water_kg_h,
  available_drinking_water_kg_h,
  prescribed_incremental_evaporative_water_loss_kg_h
) {
  if (!.is_hour_of_day_schedule(hour_of_day)) {
    stop("`hour_of_day` must equal integer `0:23`, in order.", call. = FALSE)
  }
  .validate_body_water_schedule_vector(
    prescribed_food_derived_water_kg_h,
    "prescribed_food_derived_water_kg_h"
  )
  .validate_body_water_schedule_vector(
    available_drinking_water_kg_h,
    "available_drinking_water_kg_h"
  )
  .validate_body_water_schedule_vector(
    prescribed_incremental_evaporative_water_loss_kg_h,
    "prescribed_incremental_evaporative_water_loss_kg_h"
  )

  invisible(NULL)
}

.validate_body_water_schedule_vector <- function(value, field_name) {
  if (
    !.is_numeric_vector(value) ||
      length(value) != 24L ||
      any(!is.finite(as.double(value))) ||
      any(as.double(value) < 0)
  ) {
    stop(
      sprintf(
        "`%s` must contain 24 finite, non-negative numeric values.",
        field_name
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_body_water_schedule <- function(schedule) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_food_derived_water_kg_h",
    "available_drinking_water_kg_h",
    "prescribed_incremental_evaporative_water_loss_kg_h"
  )
  if (
    !is.data.frame(schedule) ||
      !.has_exact_named_fields(schedule, expected_names)
  ) {
    stop(
      paste0(
        "`schedule` must contain only `hour_of_day`, ",
        "`prescribed_food_derived_water_kg_h`, ",
        "`available_drinking_water_kg_h`, and ",
        "`prescribed_incremental_evaporative_water_loss_kg_h`."
      ),
      call. = FALSE
    )
  }
  .validate_body_water_schedule_fields(
    schedule$hour_of_day,
    schedule$prescribed_food_derived_water_kg_h,
    schedule$available_drinking_water_kg_h,
    schedule$prescribed_incremental_evaporative_water_loss_kg_h
  )

  invisible(NULL)
}

.validate_body_water_input_row <- function(input_row) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_food_derived_water_kg_h",
    "available_drinking_water_kg_h",
    "prescribed_incremental_evaporative_water_loss_kg_h"
  )
  if (
    !is.data.frame(input_row) ||
      nrow(input_row) != 1L ||
      !.has_exact_named_fields(input_row, expected_names)
  ) {
    stop(
      "`input_row` must be exactly one row from a body-water schedule.",
      call. = FALSE
    )
  }
  if (!.is_hour_of_day_scalar(input_row$hour_of_day)) {
    stop(
      "`input_row$hour_of_day` must be one whole value from 0 to 23.",
      call. = FALSE
    )
  }
  .validate_nonnegative_numeric_scalar(
    input_row$prescribed_food_derived_water_kg_h,
    "input_row$prescribed_food_derived_water_kg_h"
  )
  .validate_nonnegative_numeric_scalar(
    input_row$available_drinking_water_kg_h,
    "input_row$available_drinking_water_kg_h"
  )
  .validate_nonnegative_numeric_scalar(
    input_row$prescribed_incremental_evaporative_water_loss_kg_h,
    "input_row$prescribed_incremental_evaporative_water_loss_kg_h"
  )

  invisible(NULL)
}
