#' Advance forage biomass by one hour
#'
#' Apply one prescribed growth input and one prescribed non-herbivore
#' background loss to homogeneous standing forage biomass.
#'
#' @param state A forage-biomass state created by
#'   [new_forage_biomass_state()].
#' @param input_row Exactly one row from a schedule created by
#'   [new_forage_growth_loss_schedule()].
#'
#' @return A plain list containing the closing `state` and one-hour `fluxes`.
#'   A proposed negative closing stock raises an error.
#' @export
step_forage_biomass <- function(state, input_row) {
  .validate_forage_biomass_state(state)
  .validate_forage_growth_loss_input_row(input_row)

  .step_forage_biomass_core(
    as.double(state$forage_biomass_kg_dm_ha),
    as.double(input_row$prescribed_forage_growth_kg_dm_ha_h),
    as.double(input_row$prescribed_forage_background_loss_kg_dm_ha_h)
  )
}
.step_forage_biomass_core <- function(
  forage_biomass_start_kg_dm_ha,
  prescribed_forage_growth_kg_dm_ha_h,
  prescribed_forage_background_loss_kg_dm_ha_h
) {
  net_forage_biomass_rate_kg_dm_ha_h <-
    prescribed_forage_growth_kg_dm_ha_h -
      prescribed_forage_background_loss_kg_dm_ha_h
  prescribed_forage_growth_kg_dm_ha <-
    prescribed_forage_growth_kg_dm_ha_h
  prescribed_forage_background_loss_kg_dm_ha <-
    prescribed_forage_background_loss_kg_dm_ha_h
  forage_biomass_change_kg_dm_ha <-
    prescribed_forage_growth_kg_dm_ha -
      prescribed_forage_background_loss_kg_dm_ha
  forage_biomass_end_kg_dm_ha <-
    forage_biomass_start_kg_dm_ha + forage_biomass_change_kg_dm_ha

  arithmetic <- c(
    net_forage_biomass_rate_kg_dm_ha_h,
    prescribed_forage_growth_kg_dm_ha,
    prescribed_forage_background_loss_kg_dm_ha,
    forage_biomass_change_kg_dm_ha,
    forage_biomass_end_kg_dm_ha
  )
  if (any(!is.finite(arithmetic))) {
    stop("The proposed forage-biomass transition must remain finite.", call. = FALSE)
  }
  if (forage_biomass_end_kg_dm_ha < 0) {
    stop("The proposed closing forage-biomass stock is negative.", call. = FALSE)
  }

  forage_biomass_balance_residual_kg_dm_ha <-
    (forage_biomass_end_kg_dm_ha - forage_biomass_start_kg_dm_ha) -
      (
        prescribed_forage_growth_kg_dm_ha -
          prescribed_forage_background_loss_kg_dm_ha
      )
  tolerance <- .forage_biomass_tolerance(
    forage_biomass_start_kg_dm_ha,
    forage_biomass_end_kg_dm_ha,
    prescribed_forage_growth_kg_dm_ha,
    prescribed_forage_background_loss_kg_dm_ha
  )
  if (abs(forage_biomass_balance_residual_kg_dm_ha) > tolerance) {
    stop("The hourly forage-biomass balance does not close.", call. = FALSE)
  }

  list(
    state = list(forage_biomass_kg_dm_ha = forage_biomass_end_kg_dm_ha),
    fluxes = list(
      prescribed_forage_growth_kg_dm_ha_h =
        prescribed_forage_growth_kg_dm_ha_h,
      prescribed_forage_background_loss_kg_dm_ha_h =
        prescribed_forage_background_loss_kg_dm_ha_h,
      net_forage_biomass_rate_kg_dm_ha_h =
        net_forage_biomass_rate_kg_dm_ha_h,
      prescribed_forage_growth_kg_dm_ha =
        prescribed_forage_growth_kg_dm_ha,
      prescribed_forage_background_loss_kg_dm_ha =
        prescribed_forage_background_loss_kg_dm_ha,
      forage_biomass_change_kg_dm_ha = forage_biomass_change_kg_dm_ha,
      forage_biomass_balance_residual_kg_dm_ha =
        forage_biomass_balance_residual_kg_dm_ha
    )
  )
}

.validate_forage_growth_loss_input_row <- function(input_row) {
  expected_names <- c(
    "hour_of_day",
    "prescribed_forage_growth_kg_dm_ha_h",
    "prescribed_forage_background_loss_kg_dm_ha_h"
  )
  if (
    !is.data.frame(input_row) ||
      nrow(input_row) != 1L ||
      !.has_exact_named_fields(input_row, expected_names)
  ) {
    stop(
      paste0(
        "`input_row` must be a one-row data frame containing only ",
        "`hour_of_day`, `prescribed_forage_growth_kg_dm_ha_h`, and ",
        "`prescribed_forage_background_loss_kg_dm_ha_h`."
      ),
      call. = FALSE
    )
  }
  if (!.is_hour_of_day_scalar(input_row$hour_of_day)) {
    stop(
      "`input_row$hour_of_day` must be one whole numeric value from 0 to 23.",
      call. = FALSE
    )
  }
  .validate_nonnegative_numeric_scalar(
    input_row$prescribed_forage_growth_kg_dm_ha_h,
    "input_row$prescribed_forage_growth_kg_dm_ha_h"
  )
  .validate_nonnegative_numeric_scalar(
    input_row$prescribed_forage_background_loss_kg_dm_ha_h,
    "input_row$prescribed_forage_background_loss_kg_dm_ha_h"
  )
}

.forage_biomass_tolerance <- function(...) {
  values <- c(...)
  scale <- max(1, abs(values))
  if (!is.finite(scale)) {
    stop("The forage-biomass accounting scale must be finite.", call. = FALSE)
  }

  100 * .Machine$double.eps * scale
}
