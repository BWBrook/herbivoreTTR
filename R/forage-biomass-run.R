#' Run the forage-biomass ledger for one day
#'
#' Apply 24 prescribed one-hour forage growth-and-loss transitions and derive a
#' daily stock-flow summary.
#'
#' @param initial_state A forage-biomass state created by
#'   [new_forage_biomass_state()].
#' @param schedule A 24-row schedule created by
#'   [new_forage_growth_loss_schedule()].
#'
#' @return A plain list containing a 24-row `hourly` data frame and a one-row
#'   `daily` data frame.
#' @export
run_forage_biomass_day <- function(initial_state, schedule) {
  .validate_forage_biomass_state(initial_state)
  .validate_forage_growth_loss_schedule(schedule)

  hour_of_day <- as.integer(schedule$hour_of_day)
  growth_kg_dm_ha_h <- as.double(
    schedule$prescribed_forage_growth_kg_dm_ha_h
  )
  loss_kg_dm_ha_h <- as.double(
    schedule$prescribed_forage_background_loss_kg_dm_ha_h
  )
  hourly <- data.frame(
    hour_of_day = hour_of_day,
    time_start_h = as.double(hour_of_day),
    time_end_h = as.double(hour_of_day + 1L),
    forage_biomass_start_kg_dm_ha = numeric(24L),
    prescribed_forage_growth_kg_dm_ha_h = growth_kg_dm_ha_h,
    prescribed_forage_background_loss_kg_dm_ha_h = loss_kg_dm_ha_h,
    net_forage_biomass_rate_kg_dm_ha_h = numeric(24L),
    prescribed_forage_growth_kg_dm_ha = numeric(24L),
    prescribed_forage_background_loss_kg_dm_ha = numeric(24L),
    forage_biomass_change_kg_dm_ha = numeric(24L),
    forage_biomass_end_kg_dm_ha = numeric(24L),
    forage_biomass_balance_residual_kg_dm_ha = numeric(24L)
  )

  current_biomass_kg_dm_ha <- as.double(
    initial_state$forage_biomass_kg_dm_ha
  )
  for (row_index in seq_len(24L)) {
    transition <- .step_forage_biomass_core(
      current_biomass_kg_dm_ha,
      growth_kg_dm_ha_h[[row_index]],
      loss_kg_dm_ha_h[[row_index]]
    )
    hourly$forage_biomass_start_kg_dm_ha[[row_index]] <-
      current_biomass_kg_dm_ha
    hourly$net_forage_biomass_rate_kg_dm_ha_h[[row_index]] <-
      transition$fluxes$net_forage_biomass_rate_kg_dm_ha_h
    hourly$prescribed_forage_growth_kg_dm_ha[[row_index]] <-
      transition$fluxes$prescribed_forage_growth_kg_dm_ha
    hourly$prescribed_forage_background_loss_kg_dm_ha[[row_index]] <-
      transition$fluxes$prescribed_forage_background_loss_kg_dm_ha
    hourly$forage_biomass_change_kg_dm_ha[[row_index]] <-
      transition$fluxes$forage_biomass_change_kg_dm_ha
    hourly$forage_biomass_end_kg_dm_ha[[row_index]] <-
      transition$state$forage_biomass_kg_dm_ha
    hourly$forage_biomass_balance_residual_kg_dm_ha[[row_index]] <-
      transition$fluxes$forage_biomass_balance_residual_kg_dm_ha
    current_biomass_kg_dm_ha <- transition$state$forage_biomass_kg_dm_ha
  }

  forage_biomass_initial_kg_dm_ha <-
    hourly$forage_biomass_start_kg_dm_ha[[1L]]
  total_prescribed_forage_growth_kg_dm_ha <-
    sum(hourly$prescribed_forage_growth_kg_dm_ha)
  total_prescribed_forage_background_loss_kg_dm_ha <-
    sum(hourly$prescribed_forage_background_loss_kg_dm_ha)
  expected_forage_biomass_change_kg_dm_ha <-
    total_prescribed_forage_growth_kg_dm_ha -
      total_prescribed_forage_background_loss_kg_dm_ha
  forage_biomass_final_kg_dm_ha <-
    hourly$forage_biomass_end_kg_dm_ha[[24L]]
  observed_forage_biomass_change_kg_dm_ha <-
    forage_biomass_final_kg_dm_ha - forage_biomass_initial_kg_dm_ha
  forage_biomass_balance_residual_kg_dm_ha <-
    observed_forage_biomass_change_kg_dm_ha -
      expected_forage_biomass_change_kg_dm_ha

  arithmetic <- c(
    total_prescribed_forage_growth_kg_dm_ha,
    total_prescribed_forage_background_loss_kg_dm_ha,
    expected_forage_biomass_change_kg_dm_ha,
    forage_biomass_final_kg_dm_ha,
    observed_forage_biomass_change_kg_dm_ha,
    forage_biomass_balance_residual_kg_dm_ha
  )
  if (any(!is.finite(arithmetic))) {
    stop("The daily forage-biomass accounting must remain finite.", call. = FALSE)
  }
  tolerance <- .forage_biomass_tolerance(
    forage_biomass_initial_kg_dm_ha,
    forage_biomass_final_kg_dm_ha,
    total_prescribed_forage_growth_kg_dm_ha,
    total_prescribed_forage_background_loss_kg_dm_ha
  )
  if (abs(forage_biomass_balance_residual_kg_dm_ha) > tolerance) {
    stop("The daily forage-biomass balance does not close.", call. = FALSE)
  }

  daily <- data.frame(
    forage_biomass_initial_kg_dm_ha = forage_biomass_initial_kg_dm_ha,
    total_prescribed_forage_growth_kg_dm_ha =
      total_prescribed_forage_growth_kg_dm_ha,
    total_prescribed_forage_background_loss_kg_dm_ha =
      total_prescribed_forage_background_loss_kg_dm_ha,
    expected_forage_biomass_change_kg_dm_ha =
      expected_forage_biomass_change_kg_dm_ha,
    observed_forage_biomass_change_kg_dm_ha =
      observed_forage_biomass_change_kg_dm_ha,
    forage_biomass_final_kg_dm_ha = forage_biomass_final_kg_dm_ha,
    forage_biomass_balance_residual_kg_dm_ha =
      forage_biomass_balance_residual_kg_dm_ha
  )

  list(hourly = hourly, daily = daily)
}
