#' Create forage-turnover parameters
#'
#' Create the fixed parameters for a constant-production, proportional-loss
#' forage reference with a declared positive equilibrium.
#'
#' @param equilibrium_forage_biomass_kg_dm_ha Finite, strictly positive
#'   equilibrium standing forage biomass in kilograms dry matter per hectare.
#' @param forage_turnover_fraction_h Finite numeric scalar in `(0, 1]` giving
#'   the fraction of equilibrium production and current biomass loss per hour.
#'
#' @return A plain named list containing the equilibrium biomass and turnover
#'   fraction.
#' @export
new_forage_turnover_parameters <- function(
  equilibrium_forage_biomass_kg_dm_ha,
  forage_turnover_fraction_h
) {
  .validate_forage_turnover_parameter_values(
    equilibrium_forage_biomass_kg_dm_ha,
    forage_turnover_fraction_h
  )

  list(
    equilibrium_forage_biomass_kg_dm_ha =
      as.double(equilibrium_forage_biomass_kg_dm_ha),
    forage_turnover_fraction_h = as.double(forage_turnover_fraction_h)
  )
}

#' Advance the forage-turnover reference by one hour
#'
#' Add constant production equal to turnover fraction times equilibrium
#' biomass, and remove the same fraction of opening standing biomass.
#'
#' @param state A forage-biomass state created by
#'   [new_forage_biomass_state()].
#' @param parameters Forage-turnover parameters created by
#'   [new_forage_turnover_parameters()].
#'
#' @return A plain list containing the closing `state` and one-hour `fluxes`.
#' @export
step_forage_turnover <- function(state, parameters) {
  .validate_forage_biomass_state(state)
  .validate_forage_turnover_parameters(parameters)

  .step_forage_turnover_core(
    as.double(state$forage_biomass_kg_dm_ha),
    as.double(parameters$equilibrium_forage_biomass_kg_dm_ha),
    as.double(parameters$forage_turnover_fraction_h)
  )
}

.step_forage_turnover_core <- function(
  forage_biomass_start_kg_dm_ha,
  equilibrium_forage_biomass_kg_dm_ha,
  forage_turnover_fraction_h
) {
  forage_growth_kg_dm_ha_h <-
    forage_turnover_fraction_h * equilibrium_forage_biomass_kg_dm_ha
  forage_background_loss_kg_dm_ha_h <-
    forage_turnover_fraction_h * forage_biomass_start_kg_dm_ha
  transition <- .step_forage_biomass_core(
    forage_biomass_start_kg_dm_ha,
    forage_growth_kg_dm_ha_h,
    forage_background_loss_kg_dm_ha_h
  )

  list(
    state = transition$state,
    fluxes = list(
      forage_growth_kg_dm_ha_h = forage_growth_kg_dm_ha_h,
      forage_background_loss_kg_dm_ha_h =
        forage_background_loss_kg_dm_ha_h,
      net_forage_biomass_rate_kg_dm_ha_h =
        transition$fluxes$net_forage_biomass_rate_kg_dm_ha_h,
      forage_growth_kg_dm_ha =
        transition$fluxes$prescribed_forage_growth_kg_dm_ha,
      forage_background_loss_kg_dm_ha =
        transition$fluxes$prescribed_forage_background_loss_kg_dm_ha,
      forage_biomass_change_kg_dm_ha =
        transition$fluxes$forage_biomass_change_kg_dm_ha,
      forage_biomass_balance_residual_kg_dm_ha =
        transition$fluxes$forage_biomass_balance_residual_kg_dm_ha
    )
  )
}

#' Run the forage-turnover reference for repeated days
#'
#' Apply the constant-production, proportional-loss forage transition for each
#' hour of one or more continuous 24-hour days.
#'
#' @param initial_state A forage-biomass state created by
#'   [new_forage_biomass_state()].
#' @param parameters Forage-turnover parameters created by
#'   [new_forage_turnover_parameters()].
#' @param number_of_days One finite whole numeric value from 1 to
#'   `.Machine$integer.max`.
#'
#' @return A plain list containing a `24 * number_of_days`-row `hourly` ledger
#'   and a `number_of_days`-row `daily` summary.
#' @export
run_forage_turnover_days <- function(
  initial_state,
  parameters,
  number_of_days
) {
  .validate_forage_biomass_state(initial_state)
  .validate_forage_turnover_parameters(parameters)
  number_of_days <- .validate_number_of_simulation_days(number_of_days)

  equilibrium_biomass_kg_dm_ha <- as.double(
    parameters$equilibrium_forage_biomass_kg_dm_ha
  )
  turnover_fraction_h <- as.double(parameters$forage_turnover_fraction_h)
  current_biomass_kg_dm_ha <- as.double(
    initial_state$forage_biomass_kg_dm_ha
  )
  day_results <- vector("list", number_of_days)

  for (simulation_day in seq_len(number_of_days)) {
    day_result <- .run_forage_turnover_day_prevalidated(
      current_biomass_kg_dm_ha,
      equilibrium_biomass_kg_dm_ha,
      turnover_fraction_h,
      simulation_day
    )
    day_results[[simulation_day]] <- day_result
    current_biomass_kg_dm_ha <-
      day_result$daily$forage_biomass_final_kg_dm_ha[[1L]]
  }

  hourly <- do.call(rbind, lapply(day_results, `[[`, "hourly"))
  daily <- do.call(rbind, lapply(day_results, `[[`, "daily"))
  row.names(hourly) <- NULL
  row.names(daily) <- NULL

  list(hourly = hourly, daily = daily)
}

.run_forage_turnover_day_prevalidated <- function(
  initial_biomass_kg_dm_ha,
  equilibrium_biomass_kg_dm_ha,
  turnover_fraction_h,
  simulation_day
) {
  hour_of_day <- 0:23
  time_offset_h <- 24 * (simulation_day - 1L)
  hourly <- data.frame(
    simulation_day = rep.int(simulation_day, 24L),
    hour_of_day = hour_of_day,
    time_start_h = as.double(time_offset_h + hour_of_day),
    time_end_h = as.double(time_offset_h + hour_of_day + 1L),
    forage_biomass_start_kg_dm_ha = numeric(24L),
    forage_growth_kg_dm_ha_h = numeric(24L),
    forage_background_loss_kg_dm_ha_h = numeric(24L),
    net_forage_biomass_rate_kg_dm_ha_h = numeric(24L),
    forage_growth_kg_dm_ha = numeric(24L),
    forage_background_loss_kg_dm_ha = numeric(24L),
    forage_biomass_change_kg_dm_ha = numeric(24L),
    forage_biomass_end_kg_dm_ha = numeric(24L),
    forage_biomass_balance_residual_kg_dm_ha = numeric(24L)
  )

  current_biomass_kg_dm_ha <- initial_biomass_kg_dm_ha
  for (row_index in seq_len(24L)) {
    transition <- .step_forage_turnover_core(
      current_biomass_kg_dm_ha,
      equilibrium_biomass_kg_dm_ha,
      turnover_fraction_h
    )
    hourly$forage_biomass_start_kg_dm_ha[[row_index]] <-
      current_biomass_kg_dm_ha
    for (field_name in names(transition$fluxes)) {
      hourly[[field_name]][[row_index]] <- transition$fluxes[[field_name]]
    }
    hourly$forage_biomass_end_kg_dm_ha[[row_index]] <-
      transition$state$forage_biomass_kg_dm_ha
    current_biomass_kg_dm_ha <- transition$state$forage_biomass_kg_dm_ha
  }

  initial_biomass_kg_dm_ha <-
    hourly$forage_biomass_start_kg_dm_ha[[1L]]
  final_biomass_kg_dm_ha <- hourly$forage_biomass_end_kg_dm_ha[[24L]]
  total_growth_kg_dm_ha <- sum(hourly$forage_growth_kg_dm_ha)
  total_background_loss_kg_dm_ha <-
    sum(hourly$forage_background_loss_kg_dm_ha)
  expected_change_kg_dm_ha <-
    total_growth_kg_dm_ha - total_background_loss_kg_dm_ha
  observed_change_kg_dm_ha <-
    final_biomass_kg_dm_ha - initial_biomass_kg_dm_ha
  balance_residual_kg_dm_ha <-
    observed_change_kg_dm_ha - expected_change_kg_dm_ha
  tolerance <- .forage_biomass_tolerance(
    initial_biomass_kg_dm_ha,
    final_biomass_kg_dm_ha,
    total_growth_kg_dm_ha,
    total_background_loss_kg_dm_ha
  )
  if (abs(balance_residual_kg_dm_ha) > tolerance) {
    stop("The daily forage-turnover balance does not close.", call. = FALSE)
  }

  daily <- data.frame(
    simulation_day = simulation_day,
    equilibrium_forage_biomass_kg_dm_ha = equilibrium_biomass_kg_dm_ha,
    forage_biomass_initial_kg_dm_ha = initial_biomass_kg_dm_ha,
    total_forage_growth_kg_dm_ha = total_growth_kg_dm_ha,
    total_forage_background_loss_kg_dm_ha =
      total_background_loss_kg_dm_ha,
    expected_forage_biomass_change_kg_dm_ha = expected_change_kg_dm_ha,
    observed_forage_biomass_change_kg_dm_ha = observed_change_kg_dm_ha,
    forage_biomass_final_kg_dm_ha = final_biomass_kg_dm_ha,
    forage_biomass_deviation_initial_kg_dm_ha =
      initial_biomass_kg_dm_ha - equilibrium_biomass_kg_dm_ha,
    forage_biomass_deviation_final_kg_dm_ha =
      final_biomass_kg_dm_ha - equilibrium_biomass_kg_dm_ha,
    forage_biomass_balance_residual_kg_dm_ha = balance_residual_kg_dm_ha
  )

  list(hourly = hourly, daily = daily)
}

.validate_forage_turnover_parameters <- function(parameters) {
  expected_names <- c(
    "equilibrium_forage_biomass_kg_dm_ha",
    "forage_turnover_fraction_h"
  )
  if (!.has_exact_named_fields(parameters, expected_names)) {
    stop(
      paste0(
        "`parameters` must contain only ",
        "`equilibrium_forage_biomass_kg_dm_ha` and ",
        "`forage_turnover_fraction_h`."
      ),
      call. = FALSE
    )
  }

  .validate_forage_turnover_parameter_values(
    parameters$equilibrium_forage_biomass_kg_dm_ha,
    parameters$forage_turnover_fraction_h
  )
}

.validate_forage_turnover_parameter_values <- function(
  equilibrium_forage_biomass_kg_dm_ha,
  forage_turnover_fraction_h
) {
  if (
    !.is_numeric_vector(equilibrium_forage_biomass_kg_dm_ha) ||
      length(equilibrium_forage_biomass_kg_dm_ha) != 1L ||
      !is.finite(as.double(equilibrium_forage_biomass_kg_dm_ha)) ||
      as.double(equilibrium_forage_biomass_kg_dm_ha) <= 0
  ) {
    stop(
      paste0(
        "`equilibrium_forage_biomass_kg_dm_ha` must be one finite, ",
        "strictly positive numeric value."
      ),
      call. = FALSE
    )
  }
  if (
    !.is_numeric_vector(forage_turnover_fraction_h) ||
      length(forage_turnover_fraction_h) != 1L ||
      !is.finite(as.double(forage_turnover_fraction_h)) ||
      as.double(forage_turnover_fraction_h) <= 0 ||
      as.double(forage_turnover_fraction_h) > 1
  ) {
    stop(
      "`forage_turnover_fraction_h` must be one finite value in (0, 1].",
      call. = FALSE
    )
  }

  invisible(NULL)
}
