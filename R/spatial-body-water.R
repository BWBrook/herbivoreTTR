#' Create patch-specific water properties
#'
#' Define the effective water obtained per kilogram dry matter consumed in
#' each patch and the water available for drinking during one stationary hour.
#' Positive drinking availability identifies a known drinking source.
#'
#' @param patch_id Unique non-empty patch identifiers.
#' @param food_derived_water_yield_kg_water_kg_dm Finite, non-negative water
#'   yield per kilogram dry matter consumed in each patch.
#' @param drinking_water_availability_kg_h Finite, non-negative drinking-water
#'   availability in each patch, in kilograms per hour.
#'
#' @return A canonical base data frame.
#' @export
new_patch_water_properties <- function(
  patch_id,
  food_derived_water_yield_kg_water_kg_dm,
  drinking_water_availability_kg_h
) {
  .validate_patch_ids(patch_id, "patch_id", minimum_length = 1L)
  .validate_patch_water_vector(
    food_derived_water_yield_kg_water_kg_dm,
    length(patch_id),
    "food_derived_water_yield_kg_water_kg_dm"
  )
  .validate_patch_water_vector(
    drinking_water_availability_kg_h,
    length(patch_id),
    "drinking_water_availability_kg_h"
  )

  data.frame(
    patch_id = as.character(patch_id),
    food_derived_water_yield_kg_water_kg_dm = as.double(
      food_derived_water_yield_kg_water_kg_dm
    ),
    drinking_water_availability_kg_h = as.double(
      drinking_water_availability_kg_h
    ),
    stringsAsFactors = FALSE
  )
}

#' Derive one body-water day from a spatial energy ledger
#'
#' Couple realized dry-matter intake and stationary access to a known drinking
#' source to the independent body-water stock. Movement never permits drinking.
#' The supplied energy ledger is not modified.
#'
#' @param initial_state A body-water state created by
#'   [new_body_water_state()].
#' @param parameters Body-water parameters created by
#'   [new_body_water_parameters()].
#' @param patch_water_properties Patch properties created by
#'   [new_patch_water_properties()].
#' @param spatial_energy_hourly A 24-row hourly ledger from a spatial energy
#'   runner containing `hour_of_day`, `opening_patch_id`, `spatial_action`, and
#'   `realized_dry_matter_intake_kg_dm_h`.
#' @param prescribed_incremental_evaporative_water_loss_kg_h Finite,
#'   non-negative numeric vector of 24 incremental evaporative-loss rates in
#'   kilograms per hour.
#'
#' @return A plain list containing hourly and daily water ledgers plus the
#'   final state.
#' @export
run_spatial_body_water_day <- function(
  initial_state,
  parameters,
  patch_water_properties,
  spatial_energy_hourly,
  prescribed_incremental_evaporative_water_loss_kg_h
) {
  .validate_body_water_state(initial_state)
  .validate_body_water_parameters(parameters)
  .validate_patch_water_properties(patch_water_properties)
  .validate_spatial_energy_water_surface(spatial_energy_hourly)
  .validate_nonnegative_daily_numeric_vector(
    prescribed_incremental_evaporative_water_loss_kg_h,
    "prescribed_incremental_evaporative_water_loss_kg_h"
  )
  if (
    as.double(initial_state$body_water_kg) >
      as.double(parameters$normal_body_water_kg)
  ) {
    stop("The initial body-water stock exceeds its normal level.", call. = FALSE)
  }
  if (!all(
    spatial_energy_hourly$opening_patch_id %in%
      patch_water_properties$patch_id
  )) {
    stop(
      "Every opening spatial patch must have declared water properties.",
      call. = FALSE
    )
  }

  property_index <- match(
    spatial_energy_hourly$opening_patch_id,
    patch_water_properties$patch_id
  )
  food_water_yield <- patch_water_properties$
    food_derived_water_yield_kg_water_kg_dm[property_index]
  food_derived_water_kg_h <-
    as.double(spatial_energy_hourly$realized_dry_matter_intake_kg_dm_h) *
      food_water_yield
  drinking_water_availability_kg_h <- patch_water_properties$
    drinking_water_availability_kg_h[property_index]
  drinking_water_availability_kg_h[
    spatial_energy_hourly$spatial_action != "stay"
  ] <- 0
  schedule <- new_body_water_schedule(
    spatial_energy_hourly$hour_of_day,
    food_derived_water_kg_h,
    drinking_water_availability_kg_h,
    prescribed_incremental_evaporative_water_loss_kg_h
  )
  result <- run_body_water_day(initial_state, parameters, schedule)

  result$hourly <- data.frame(
    hour_of_day = result$hourly$hour_of_day,
    opening_patch_id = spatial_energy_hourly$opening_patch_id,
    spatial_action = spatial_energy_hourly$spatial_action,
    food_derived_water_yield_kg_water_kg_dm = food_water_yield,
    result$hourly[setdiff(names(result$hourly), "hour_of_day")],
    check.names = FALSE
  )
  result$daily$drinking_hours <- sum(
    result$hourly$realized_drinking_water_kg > 0
  )
  result
}

.validate_patch_water_vector <- function(value, patch_count, field_name) {
  if (
    !.is_numeric_vector(value) ||
      length(value) != patch_count ||
      any(!is.finite(as.double(value))) ||
      any(as.double(value) < 0)
  ) {
    stop(
      sprintf(
        "`%s` must contain one finite, non-negative value per patch.",
        field_name
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

.validate_patch_water_properties <- function(properties) {
  expected_names <- c(
    "patch_id",
    "food_derived_water_yield_kg_water_kg_dm",
    "drinking_water_availability_kg_h"
  )
  if (
    !is.data.frame(properties) ||
      !.has_exact_named_fields(properties, expected_names)
  ) {
    stop(
      paste0(
        "`patch_water_properties` must contain only `patch_id`, ",
        "`food_derived_water_yield_kg_water_kg_dm`, and ",
        "`drinking_water_availability_kg_h`."
      ),
      call. = FALSE
    )
  }
  .validate_patch_ids(
    properties$patch_id,
    "patch_water_properties$patch_id",
    minimum_length = 1L
  )
  .validate_patch_water_vector(
    properties$food_derived_water_yield_kg_water_kg_dm,
    nrow(properties),
    "patch_water_properties$food_derived_water_yield_kg_water_kg_dm"
  )
  .validate_patch_water_vector(
    properties$drinking_water_availability_kg_h,
    nrow(properties),
    "patch_water_properties$drinking_water_availability_kg_h"
  )

  invisible(NULL)
}

.validate_spatial_energy_water_surface <- function(hourly) {
  required_names <- c(
    "hour_of_day",
    "opening_patch_id",
    "spatial_action",
    "realized_dry_matter_intake_kg_dm_h"
  )
  if (
    !is.data.frame(hourly) ||
      nrow(hourly) != 24L ||
      !all(required_names %in% names(hourly))
  ) {
    stop(
      paste0(
        "`spatial_energy_hourly` must be a 24-row ledger containing ",
        "`hour_of_day`, `opening_patch_id`, `spatial_action`, and ",
        "`realized_dry_matter_intake_kg_dm_h`."
      ),
      call. = FALSE
    )
  }
  if (!.is_hour_of_day_schedule(hourly$hour_of_day)) {
    stop(
      "`spatial_energy_hourly$hour_of_day` must equal integer `0:23`.",
      call. = FALSE
    )
  }
  .validate_patch_ids(
    hourly$opening_patch_id,
    "spatial_energy_hourly$opening_patch_id",
    minimum_length = 24L,
    require_unique = FALSE
  )
  valid_actions <- is.character(hourly$spatial_action) &&
    !is.object(hourly$spatial_action) &&
    length(hourly$spatial_action) == 24L &&
    !anyNA(hourly$spatial_action) &&
    all(hourly$spatial_action %in% c("stay", "move"))
  if (!valid_actions) {
    stop(
      "`spatial_energy_hourly$spatial_action` must contain `stay` or `move`.",
      call. = FALSE
    )
  }
  .validate_nonnegative_daily_numeric_vector(
    hourly$realized_dry_matter_intake_kg_dm_h,
    "spatial_energy_hourly$realized_dry_matter_intake_kg_dm_h"
  )

  invisible(NULL)
}
