#' Create appetite-control parameters
#'
#' Create the fixed parameters for a bounded hourly intake controller. The two
#' feedback fractions convert deviations from reference body and gut energy in
#' kilojoules to signed adjustments in available-energy intake rate in
#' kilojoules per hour.
#'
#' @param maximum_dry_matter_intake_kg_dm_h Finite, strictly positive
#'   physiological maximum for the appetite target in kilograms dry matter per
#'   hour.
#' @param body_energy_feedback_fraction_h Finite, non-negative hourly feedback
#'   fraction applied to body-energy deviation from reference.
#' @param gut_energy_feedback_fraction_h Finite, non-negative hourly feedback
#'   fraction applied to gut-energy deviation from reference.
#'
#' @return A plain named list containing the three appetite-control parameters.
#' @export
new_appetite_control_parameters <- function(
  maximum_dry_matter_intake_kg_dm_h,
  body_energy_feedback_fraction_h,
  gut_energy_feedback_fraction_h
) {
  .validate_positive_numeric_scalar(
    maximum_dry_matter_intake_kg_dm_h,
    "maximum_dry_matter_intake_kg_dm_h"
  )
  .validate_nonnegative_numeric_scalar(
    body_energy_feedback_fraction_h,
    "body_energy_feedback_fraction_h"
  )
  .validate_nonnegative_numeric_scalar(
    gut_energy_feedback_fraction_h,
    "gut_energy_feedback_fraction_h"
  )

  list(
    maximum_dry_matter_intake_kg_dm_h =
      as.double(maximum_dry_matter_intake_kg_dm_h),
    body_energy_feedback_fraction_h =
      as.double(body_energy_feedback_fraction_h),
    gut_energy_feedback_fraction_h =
      as.double(gut_energy_feedback_fraction_h)
  )
}

#' Create an appetite reference schedule
#'
#' Create the 24-hour feeding-opportunity, reference-intake, and opening-state
#' trajectory used by the hourly appetite controller. Reference intake must be
#' zero whenever the appetite target is closed.
#'
#' @param hour_of_day Numeric vector equal to `0:23`, in order.
#' @param feeding_opportunity_open Logical vector of 24 values identifying
#'   hours in which a positive appetite target is permitted.
#' @param reference_dry_matter_intake_kg_dm_h Finite, non-negative numeric
#'   vector of 24 reference intake rates in kilograms dry matter per hour.
#' @param reference_body_energy_reserve_kj Finite, non-negative numeric vector
#'   of 24 reference opening body-energy reserves in kilojoules.
#' @param reference_gut_available_energy_kj Finite, non-negative numeric vector
#'   of 24 reference opening gut-energy stocks in kilojoules.
#'
#' @return A canonical base data frame with 24 rows and five columns.
#' @export
new_appetite_reference_schedule <- function(
  hour_of_day,
  feeding_opportunity_open,
  reference_dry_matter_intake_kg_dm_h,
  reference_body_energy_reserve_kj,
  reference_gut_available_energy_kj
) {
  .validate_appetite_reference_schedule_fields(
    hour_of_day,
    feeding_opportunity_open,
    reference_dry_matter_intake_kg_dm_h,
    reference_body_energy_reserve_kj,
    reference_gut_available_energy_kj
  )

  data.frame(
    hour_of_day = as.integer(hour_of_day),
    feeding_opportunity_open =
      as.logical(feeding_opportunity_open),
    reference_dry_matter_intake_kg_dm_h =
      as.double(reference_dry_matter_intake_kg_dm_h),
    reference_body_energy_reserve_kj =
      as.double(reference_body_energy_reserve_kj),
    reference_gut_available_energy_kj =
      as.double(reference_gut_available_energy_kj)
  )
}

#' Calculate an appetite-controlled hourly intake target
#'
#' Add signed body- and gut-energy feedback to a reference intake rate, convert
#' between available energy and dry matter using one fixed metabolizable-energy
#' density, enforce lower and upper intake bounds, and close intake when feeding
#' opportunity is unavailable. Positive state deviations suppress the target;
#' negative deviations increase it. Environmental forage constraints are not
#' applied here.
#'
#' @param gut_state A gut-energy state record created by
#'   [new_gut_energy_state()].
#' @param body_state A body-energy state record created by
#'   [new_body_energy_state()].
#' @param food_parameters A food-energy parameter record created by
#'   [new_food_energy_parameters()].
#' @param appetite_parameters An appetite-control parameter record created by
#'   [new_appetite_control_parameters()].
#' @param reference_row Exactly one row from an appetite reference schedule
#'   created by [new_appetite_reference_schedule()].
#'
#' @return A plain named list containing the reference rate, signed state
#'   deviations and feedbacks, unconstrained rate, appetite target, and active
#'   physiological-bound indicators.
#' @export
calculate_appetite_target <- function(
  gut_state,
  body_state,
  food_parameters,
  appetite_parameters,
  reference_row
) {
  .validate_gut_energy_state(gut_state)
  .validate_body_energy_state(body_state)
  .validate_food_energy_parameters(food_parameters)
  .validate_appetite_control_parameters(appetite_parameters)
  .validate_appetite_reference_row(reference_row)

  gut_energy_kj <- as.double(gut_state$gut_available_energy_kj)
  body_energy_kj <- as.double(body_state$body_energy_reserve_kj)
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
  feeding_opportunity_open <- as.logical(reference_row$feeding_opportunity_open)
  reference_intake_kg_dm_h <- as.double(
    reference_row$reference_dry_matter_intake_kg_dm_h
  )
  reference_body_energy_kj <- as.double(reference_row$reference_body_energy_reserve_kj)
  reference_gut_energy_kj <- as.double(reference_row$reference_gut_available_energy_kj)

  .validate_appetite_reference_maximum(
    reference_intake_kg_dm_h,
    maximum_intake_kg_dm_h,
    "reference_row$reference_dry_matter_intake_kg_dm_h"
  )

  .calculate_appetite_target_core(
    gut_energy_kj,
    body_energy_kj,
    energy_density_kj_kg_dm,
    maximum_intake_kg_dm_h,
    body_feedback_fraction_h,
    gut_feedback_fraction_h,
    feeding_opportunity_open,
    reference_intake_kg_dm_h,
    reference_body_energy_kj,
    reference_gut_energy_kj
  )
}

.calculate_appetite_target_core <- function(
  gut_energy_kj,
  body_energy_kj,
  energy_density_kj_kg_dm,
  maximum_intake_kg_dm_h,
  body_feedback_fraction_h,
  gut_feedback_fraction_h,
  feeding_opportunity_open,
  reference_intake_kg_dm_h,
  reference_body_energy_kj,
  reference_gut_energy_kj
) {
  reference_energy_kj_h <-
    reference_intake_kg_dm_h * energy_density_kj_kg_dm
  body_deviation_kj <- body_energy_kj - reference_body_energy_kj
  body_feedback_kj_h <-
    -body_feedback_fraction_h * body_deviation_kj
  gut_deviation_kj <- gut_energy_kj - reference_gut_energy_kj
  gut_feedback_kj_h <-
    -gut_feedback_fraction_h * gut_deviation_kj
  unconstrained_energy_kj_h <-
    reference_energy_kj_h + body_feedback_kj_h + gut_feedback_kj_h
  unconstrained_intake_kg_dm_h <-
    unconstrained_energy_kj_h / energy_density_kj_kg_dm

  arithmetic <- c(
    reference_energy_kj_h,
    body_deviation_kj,
    body_feedback_kj_h,
    gut_deviation_kj,
    gut_feedback_kj_h,
    unconstrained_energy_kj_h,
    unconstrained_intake_kg_dm_h
  )
  if (any(!is.finite(arithmetic))) {
    stop("Appetite-control arithmetic must remain finite.", call. = FALSE)
  }

  lower_bound_active <-
    feeding_opportunity_open && unconstrained_intake_kg_dm_h < 0
  upper_bound_active <-
    feeding_opportunity_open &&
      unconstrained_intake_kg_dm_h > maximum_intake_kg_dm_h
  appetite_target_kg_dm_h <- if (feeding_opportunity_open) {
    min(
      maximum_intake_kg_dm_h,
      max(0, unconstrained_intake_kg_dm_h)
    )
  } else {
    0
  }
  appetite_target_energy_kj_h <-
    appetite_target_kg_dm_h * energy_density_kj_kg_dm

  list(
    feeding_opportunity_open = feeding_opportunity_open,
    reference_dry_matter_intake_kg_dm_h = reference_intake_kg_dm_h,
    maximum_dry_matter_intake_kg_dm_h = maximum_intake_kg_dm_h,
    reference_ingested_available_energy_kj_h = reference_energy_kj_h,
    body_energy_deviation_from_reference_kj = body_deviation_kj,
    body_energy_feedback_kj_h = body_feedback_kj_h,
    gut_energy_deviation_from_reference_kj = gut_deviation_kj,
    gut_energy_feedback_kj_h = gut_feedback_kj_h,
    unconstrained_ingested_available_energy_kj_h =
      unconstrained_energy_kj_h,
    unconstrained_dry_matter_intake_kg_dm_h =
      unconstrained_intake_kg_dm_h,
    appetite_target_dry_matter_intake_kg_dm_h =
      appetite_target_kg_dm_h,
    appetite_target_ingested_available_energy_kj_h =
      appetite_target_energy_kj_h,
    lower_intake_bound_active = lower_bound_active,
    upper_intake_bound_active = upper_bound_active
  )
}

.validate_appetite_reference_maximum <- function(
  reference_intake_kg_dm_h,
  maximum_intake_kg_dm_h,
  field_name
) {
  if (any(reference_intake_kg_dm_h > maximum_intake_kg_dm_h)) {
    stop(
      sprintf(
        "`%s` must not exceed the declared maximum intake rate.",
        field_name
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_appetite_control_parameters <- function(parameters) {
  expected_names <- c(
    "maximum_dry_matter_intake_kg_dm_h",
    "body_energy_feedback_fraction_h",
    "gut_energy_feedback_fraction_h"
  )
  if (!.has_exact_named_fields(parameters, expected_names)) {
    stop(
      "`appetite_parameters` must contain only the three appetite parameters.",
      call. = FALSE
    )
  }

  .validate_positive_numeric_scalar(
    parameters$maximum_dry_matter_intake_kg_dm_h,
    "appetite_parameters$maximum_dry_matter_intake_kg_dm_h"
  )
  .validate_nonnegative_numeric_scalar(
    parameters$body_energy_feedback_fraction_h,
    "appetite_parameters$body_energy_feedback_fraction_h"
  )
  .validate_nonnegative_numeric_scalar(
    parameters$gut_energy_feedback_fraction_h,
    "appetite_parameters$gut_energy_feedback_fraction_h"
  )

  invisible(NULL)
}

.validate_appetite_reference_schedule_fields <- function(
  hour_of_day,
  feeding_opportunity_open,
  reference_dry_matter_intake_kg_dm_h,
  reference_body_energy_reserve_kj,
  reference_gut_available_energy_kj
) {
  if (!.is_hour_of_day_schedule(hour_of_day)) {
    stop(
      "`hour_of_day` must contain the ordered whole numeric values `0:23`.",
      call. = FALSE
    )
  }
  if (
    !is.logical(feeding_opportunity_open) ||
      !is.null(dim(feeding_opportunity_open)) ||
      length(feeding_opportunity_open) != 24L ||
      anyNA(feeding_opportunity_open)
  ) {
    stop(
      "`feeding_opportunity_open` must contain 24 non-missing logical values.",
      call. = FALSE
    )
  }

  .validate_nonnegative_daily_numeric_vector(
    reference_dry_matter_intake_kg_dm_h,
    "reference_dry_matter_intake_kg_dm_h"
  )
  .validate_nonnegative_daily_numeric_vector(
    reference_body_energy_reserve_kj,
    "reference_body_energy_reserve_kj"
  )
  .validate_nonnegative_daily_numeric_vector(
    reference_gut_available_energy_kj,
    "reference_gut_available_energy_kj"
  )

  opportunity <- as.logical(feeding_opportunity_open)
  reference_intake <- as.double(reference_dry_matter_intake_kg_dm_h)
  if (any(!opportunity & reference_intake != 0)) {
    stop(
      "Reference dry-matter intake must be zero when feeding opportunity is closed.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_appetite_reference_schedule <- function(schedule) {
  expected_names <- c(
    "hour_of_day",
    "feeding_opportunity_open",
    "reference_dry_matter_intake_kg_dm_h",
    "reference_body_energy_reserve_kj",
    "reference_gut_available_energy_kj"
  )
  if (
    !is.data.frame(schedule) ||
      nrow(schedule) != 24L ||
      !.has_exact_named_fields(schedule, expected_names)
  ) {
    stop(
      paste0(
        "`appetite_reference_schedule` must be a 24-row data frame ",
        "containing only the five appetite-reference fields."
      ),
      call. = FALSE
    )
  }

  .validate_appetite_reference_schedule_fields(
    schedule$hour_of_day,
    schedule$feeding_opportunity_open,
    schedule$reference_dry_matter_intake_kg_dm_h,
    schedule$reference_body_energy_reserve_kj,
    schedule$reference_gut_available_energy_kj
  )

  invisible(NULL)
}

.validate_appetite_reference_row <- function(reference_row) {
  expected_names <- c(
    "hour_of_day",
    "feeding_opportunity_open",
    "reference_dry_matter_intake_kg_dm_h",
    "reference_body_energy_reserve_kj",
    "reference_gut_available_energy_kj"
  )
  if (
    !is.data.frame(reference_row) ||
      nrow(reference_row) != 1L ||
      !.has_exact_named_fields(reference_row, expected_names)
  ) {
    stop(
      "`reference_row` must be exactly one row from an appetite reference schedule.",
      call. = FALSE
    )
  }
  if (!.is_hour_of_day_scalar(reference_row$hour_of_day)) {
    stop(
      "`reference_row$hour_of_day` must be one whole numeric value from 0 to 23.",
      call. = FALSE
    )
  }
  if (
    !is.logical(reference_row$feeding_opportunity_open) ||
      length(reference_row$feeding_opportunity_open) != 1L ||
      is.na(reference_row$feeding_opportunity_open)
  ) {
    stop(
      "`reference_row$feeding_opportunity_open` must be one non-missing logical value.",
      call. = FALSE
    )
  }

  .validate_nonnegative_numeric_scalar(
    reference_row$reference_dry_matter_intake_kg_dm_h,
    "reference_row$reference_dry_matter_intake_kg_dm_h"
  )
  .validate_nonnegative_numeric_scalar(
    reference_row$reference_body_energy_reserve_kj,
    "reference_row$reference_body_energy_reserve_kj"
  )
  .validate_nonnegative_numeric_scalar(
    reference_row$reference_gut_available_energy_kj,
    "reference_row$reference_gut_available_energy_kj"
  )
  if (
    !as.logical(reference_row$feeding_opportunity_open) &&
      as.double(reference_row$reference_dry_matter_intake_kg_dm_h) != 0
  ) {
    stop(
      "Reference dry-matter intake must be zero when feeding opportunity is closed.",
      call. = FALSE
    )
  }

  invisible(NULL)
}
