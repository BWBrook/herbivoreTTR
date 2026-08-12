#' Create a forage-biomass state
#'
#' Create the dynamic state record for homogeneous standing edible forage.
#'
#' @param forage_biomass_kg_dm_ha Finite, non-negative numeric scalar giving
#'   standing forage biomass density in kilograms dry matter per hectare.
#'
#' @return A plain named list containing `forage_biomass_kg_dm_ha`.
#' @export
new_forage_biomass_state <- function(forage_biomass_kg_dm_ha) {
  .validate_nonnegative_numeric_scalar(
    forage_biomass_kg_dm_ha,
    "forage_biomass_kg_dm_ha"
  )

  list(forage_biomass_kg_dm_ha = as.double(forage_biomass_kg_dm_ha))
}
#' Create a prescribed forage growth-and-loss schedule
#'
#' Create independent prescribed growth and non-herbivore background-loss
#' rates for each of the 24 one-hour intervals in a day. These rates are
#' accounting inputs, not an endogenous plant-growth model.
#'
#' @param hour_of_day Numeric vector equal to `0:23`, in order.
#' @param prescribed_forage_growth_kg_dm_ha_h Finite, non-negative numeric
#'   vector of 24 growth rates in kilograms dry matter per hectare per hour.
#' @param prescribed_forage_background_loss_kg_dm_ha_h Finite, non-negative
#'   numeric vector of 24 non-herbivore loss rates in kilograms dry matter per
#'   hectare per hour.
#'
#' @return A base data frame containing the hour and both prescribed rates.
#' @export
new_forage_growth_loss_schedule <- function(
  hour_of_day,
  prescribed_forage_growth_kg_dm_ha_h,
  prescribed_forage_background_loss_kg_dm_ha_h
) {
  .validate_forage_growth_loss_schedule_fields(
    hour_of_day,
    prescribed_forage_growth_kg_dm_ha_h,
    prescribed_forage_background_loss_kg_dm_ha_h
  )

  data.frame(
    hour_of_day = as.integer(hour_of_day),
    prescribed_forage_growth_kg_dm_ha_h =
      as.double(prescribed_forage_growth_kg_dm_ha_h),
    prescribed_forage_background_loss_kg_dm_ha_h =
      as.double(prescribed_forage_background_loss_kg_dm_ha_h)
  )
}

.validate_forage_biomass_state <- function(state) {
  if (!.has_exact_named_fields(state, "forage_biomass_kg_dm_ha")) {
    stop(
      "`state` must contain only `forage_biomass_kg_dm_ha`.",
      call. = FALSE
    )
  }

  .validate_nonnegative_numeric_scalar(
    state$forage_biomass_kg_dm_ha,
    "state$forage_biomass_kg_dm_ha"
  )
}

.validate_forage_growth_loss_schedule_fields <- function(
  hour_of_day,
  prescribed_forage_growth_kg_dm_ha_h,
  prescribed_forage_background_loss_kg_dm_ha_h
) {
  if (!.is_hour_of_day_schedule(hour_of_day)) {
    stop(
      "`hour_of_day` must contain the ordered whole numeric values `0:23`.",
      call. = FALSE
    )
  }

  .validate_forage_rate_schedule(
    prescribed_forage_growth_kg_dm_ha_h,
    "prescribed_forage_growth_kg_dm_ha_h"
  )
  .validate_forage_rate_schedule(
    prescribed_forage_background_loss_kg_dm_ha_h,
    "prescribed_forage_background_loss_kg_dm_ha_h"
  )

  invisible(NULL)
}

.validate_forage_rate_schedule <- function(value, field_name) {
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

.validate_forage_growth_loss_schedule <- function(schedule) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_forage_growth_kg_dm_ha_h",
    "prescribed_forage_background_loss_kg_dm_ha_h"
  )
  if (
    !is.data.frame(schedule) ||
      nrow(schedule) != 24L ||
      !.has_exact_named_fields(schedule, expected_names)
  ) {
    stop(
      paste0(
        "`schedule` must be a 24-row data frame containing only ",
        "`hour_of_day`, `prescribed_forage_growth_kg_dm_ha_h`, and ",
        "`prescribed_forage_background_loss_kg_dm_ha_h`."
      ),
      call. = FALSE
    )
  }

  .validate_forage_growth_loss_schedule_fields(
    schedule$hour_of_day,
    schedule$prescribed_forage_growth_kg_dm_ha_h,
    schedule$prescribed_forage_background_loss_kg_dm_ha_h
  )

  invisible(NULL)
}
