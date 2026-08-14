#' Create non-spatial coupling parameters
#'
#' Create the fixed scaling and forage-residual parameters for one
#' representative herbivore physiology coupled to homogeneous forage.
#'
#' @param herbivore_density_animals_ha One finite, strictly positive numeric
#'   value giving the aggregate number of represented animals per hectare.
#' @param residual_unavailable_forage_threshold_kg_dm_ha One finite,
#'   non-negative numeric value giving the standing-forage threshold unavailable
#'   for herbivore acquisition in kilograms dry matter per hectare.
#'
#' @return A plain named list containing herbivore density and the residual
#'   forage threshold.
#' @export
new_nonspatial_coupling_parameters <- function(
  herbivore_density_animals_ha,
  residual_unavailable_forage_threshold_kg_dm_ha
) {
  .validate_positive_herbivore_density(herbivore_density_animals_ha)
  .validate_nonnegative_numeric_scalar(
    residual_unavailable_forage_threshold_kg_dm_ha,
    "residual_unavailable_forage_threshold_kg_dm_ha"
  )

  list(
    herbivore_density_animals_ha =
      as.double(herbivore_density_animals_ha),
    residual_unavailable_forage_threshold_kg_dm_ha = as.double(
      residual_unavailable_forage_threshold_kg_dm_ha
    )
  )
}

#' Remove accessible forage for representative-animal intake
#'
#' Scale one candidate one-hour dry-matter intake per represented animal by
#' herbivore density, cap it by forage biomass above the residual threshold,
#' and remove the realized amount from standing forage. This pure step contains
#' no plant growth, background loss, or animal-energy transition.
#'
#' @param state A forage-biomass state created by
#'   [new_forage_biomass_state()].
#' @param parameters Non-spatial coupling parameters created by
#'   [new_nonspatial_coupling_parameters()].
#' @param candidate_dry_matter_intake_kg_dm One finite, non-negative numeric
#'   value giving candidate dry-matter intake per represented animal during the
#'   one-hour interval, in kilograms dry matter.
#'
#' @return A plain list containing the closing forage `state` and coupling
#'   `fluxes`.
#' @export
step_forage_herbivory <- function(
  state,
  parameters,
  candidate_dry_matter_intake_kg_dm
) {
  .validate_forage_biomass_state(state)
  .validate_nonspatial_coupling_parameters(parameters)
  .validate_nonnegative_numeric_scalar(
    candidate_dry_matter_intake_kg_dm,
    "candidate_dry_matter_intake_kg_dm"
  )

  .step_forage_herbivory_core(
    as.double(state$forage_biomass_kg_dm_ha),
    as.double(parameters$herbivore_density_animals_ha),
    as.double(
      parameters$residual_unavailable_forage_threshold_kg_dm_ha
    ),
    as.double(candidate_dry_matter_intake_kg_dm)
  )
}

.step_forage_herbivory_core <- function(
  forage_biomass_start_kg_dm_ha,
  herbivore_density_animals_ha,
  residual_unavailable_forage_threshold_kg_dm_ha,
  candidate_dry_matter_intake_kg_dm
) {
  accessible_forage_biomass_kg_dm_ha <- max(
    0,
    forage_biomass_start_kg_dm_ha -
      residual_unavailable_forage_threshold_kg_dm_ha
  )
  accessible_forage_per_animal_kg_dm <-
    accessible_forage_biomass_kg_dm_ha /
      herbivore_density_animals_ha
  realized_dry_matter_intake_kg_dm <- min(
    candidate_dry_matter_intake_kg_dm,
    accessible_forage_per_animal_kg_dm
  )
  herbivory_removal_kg_dm_ha <-
    realized_dry_matter_intake_kg_dm *
      herbivore_density_animals_ha
  forage_biomass_end_kg_dm_ha <-
    forage_biomass_start_kg_dm_ha - herbivory_removal_kg_dm_ha
  forage_herbivory_balance_residual_kg_dm_ha <-
    (forage_biomass_end_kg_dm_ha - forage_biomass_start_kg_dm_ha) +
      herbivory_removal_kg_dm_ha
  herbivore_forage_coupling_residual_kg_dm_ha <-
    herbivory_removal_kg_dm_ha -
      realized_dry_matter_intake_kg_dm *
        herbivore_density_animals_ha

  arithmetic <- c(
    accessible_forage_biomass_kg_dm_ha,
    accessible_forage_per_animal_kg_dm,
    realized_dry_matter_intake_kg_dm,
    herbivory_removal_kg_dm_ha,
    forage_biomass_end_kg_dm_ha,
    forage_herbivory_balance_residual_kg_dm_ha,
    herbivore_forage_coupling_residual_kg_dm_ha
  )
  if (any(!is.finite(arithmetic))) {
    stop("Forage-herbivory coupling must remain finite.", call. = FALSE)
  }
  tolerance <- .forage_biomass_tolerance(
    forage_biomass_start_kg_dm_ha,
    forage_biomass_end_kg_dm_ha,
    herbivory_removal_kg_dm_ha
  )
  if (forage_biomass_end_kg_dm_ha < 0) {
    stop("Herbivory produced negative forage biomass.", call. = FALSE)
  }
  if (abs(forage_herbivory_balance_residual_kg_dm_ha) > tolerance) {
    stop("The forage-herbivory balance does not close.", call. = FALSE)
  }
  if (abs(herbivore_forage_coupling_residual_kg_dm_ha) > tolerance) {
    stop("The herbivore-forage coupling balance does not close.", call. = FALSE)
  }

  list(
    state = list(forage_biomass_kg_dm_ha = forage_biomass_end_kg_dm_ha),
    fluxes = list(
      accessible_forage_biomass_kg_dm_ha =
        accessible_forage_biomass_kg_dm_ha,
      accessible_forage_per_animal_kg_dm =
        accessible_forage_per_animal_kg_dm,
      candidate_dry_matter_intake_kg_dm =
        candidate_dry_matter_intake_kg_dm,
      forage_stock_ceiling_active =
        candidate_dry_matter_intake_kg_dm >
          accessible_forage_per_animal_kg_dm,
      realized_dry_matter_intake_kg_dm =
        realized_dry_matter_intake_kg_dm,
      herbivory_removal_kg_dm_ha = herbivory_removal_kg_dm_ha,
      forage_herbivory_balance_residual_kg_dm_ha =
        forage_herbivory_balance_residual_kg_dm_ha,
      herbivore_forage_coupling_residual_kg_dm_ha =
        herbivore_forage_coupling_residual_kg_dm_ha
    )
  )
}

#' Run repeated non-spatial coupled herbivore-forage days
#'
#' Couple the accepted appetite-controlled herbivore to the constant-turnover
#' forage reference. Autonomous forage turnover is applied first each hour;
#' candidate intake is then capped by forage above the residual threshold and
#' the realized amount both enters the gut and leaves standing forage.
#'
#' @param initial_gut_state A gut-energy state record created by
#'   [new_gut_energy_state()].
#' @param initial_body_state A body-energy state record created by
#'   [new_body_energy_state()].
#' @param initial_forage_state A forage-biomass state created by
#'   [new_forage_biomass_state()].
#' @param gut_parameters A gut-energy parameter record created by
#'   [new_gut_energy_parameters()].
#' @param body_parameters A body-energy parameter record created by
#'   [new_body_energy_parameters()].
#' @param food_parameters A food-energy parameter record created by
#'   [new_food_energy_parameters()].
#' @param appetite_parameters An appetite-control parameter record created by
#'   [new_appetite_control_parameters()].
#' @param forage_turnover_parameters Forage-turnover parameters created by
#'   [new_forage_turnover_parameters()].
#' @param coupling_parameters Non-spatial coupling parameters created by
#'   [new_nonspatial_coupling_parameters()].
#' @param appetite_reference_schedule A 24-row schedule created by
#'   [new_appetite_reference_schedule()].
#' @param forage_acquisition_ceiling_schedule A 24-row schedule created by
#'   [new_forage_acquisition_ceiling_schedule()].
#' @param routine_activity_schedule A 24-row schedule created by
#'   [new_routine_activity_expenditure_schedule()].
#' @param number_of_days One finite whole numeric value from 1 to
#'   `.Machine$integer.max`.
#'
#' @return A plain list containing a `24 * number_of_days`-row `hourly` ledger
#'   and a `number_of_days`-row `daily` summary.
#' @export
run_nonspatial_coupled_energy_days <- function(
  initial_gut_state,
  initial_body_state,
  initial_forage_state,
  gut_parameters,
  body_parameters,
  food_parameters,
  appetite_parameters,
  forage_turnover_parameters,
  coupling_parameters,
  appetite_reference_schedule,
  forage_acquisition_ceiling_schedule,
  routine_activity_schedule,
  number_of_days
) {
  .validate_gut_energy_state(initial_gut_state)
  .validate_body_energy_state(initial_body_state)
  .validate_forage_biomass_state(initial_forage_state)
  .validate_gut_energy_parameters(gut_parameters)
  .validate_body_energy_parameters(body_parameters)
  .validate_food_energy_parameters(food_parameters)
  .validate_appetite_control_parameters(appetite_parameters)
  .validate_forage_turnover_parameters(forage_turnover_parameters)
  .validate_nonspatial_coupling_parameters(coupling_parameters)
  .validate_appetite_reference_schedule(appetite_reference_schedule)
  .validate_forage_acquisition_ceiling_schedule(
    forage_acquisition_ceiling_schedule
  )
  .validate_routine_activity_expenditure_schedule(
    routine_activity_schedule
  )
  number_of_days <- .validate_number_of_simulation_days(number_of_days)

  reference_intake_kg_dm_h <- as.double(
    appetite_reference_schedule$reference_dry_matter_intake_kg_dm_h
  )
  maximum_intake_kg_dm_h <- as.double(
    appetite_parameters$maximum_dry_matter_intake_kg_dm_h
  )
  .validate_appetite_reference_maximum(
    reference_intake_kg_dm_h,
    maximum_intake_kg_dm_h,
    paste0(
      "appetite_reference_schedule$",
      "reference_dry_matter_intake_kg_dm_h"
    )
  )

  fixed <- list(
    gut_release_fraction_h = as.double(
      gut_parameters$gut_release_fraction_h
    ),
    maintenance_expenditure_kj_h = as.double(
      body_parameters$maintenance_expenditure_kj_h
    ),
    energy_density_kj_kg_dm = as.double(
      food_parameters$metabolizable_energy_density_kj_kg_dm
    ),
    maximum_intake_kg_dm_h = maximum_intake_kg_dm_h,
    body_feedback_fraction_h = as.double(
      appetite_parameters$body_energy_feedback_fraction_h
    ),
    gut_feedback_fraction_h = as.double(
      appetite_parameters$gut_energy_feedback_fraction_h
    ),
    equilibrium_forage_biomass_kg_dm_ha = as.double(
      forage_turnover_parameters$equilibrium_forage_biomass_kg_dm_ha
    ),
    forage_turnover_fraction_h = as.double(
      forage_turnover_parameters$forage_turnover_fraction_h
    ),
    herbivore_density_animals_ha = as.double(
      coupling_parameters$herbivore_density_animals_ha
    ),
    residual_threshold_kg_dm_ha = as.double(
      coupling_parameters$
        residual_unavailable_forage_threshold_kg_dm_ha
    )
  )
  schedules <- list(
    hour_of_day = as.integer(appetite_reference_schedule$hour_of_day),
    feeding_opportunity_open = as.logical(
      appetite_reference_schedule$feeding_opportunity_open
    ),
    reference_intake_kg_dm_h = reference_intake_kg_dm_h,
    reference_body_energy_kj = as.double(
      appetite_reference_schedule$reference_body_energy_reserve_kj
    ),
    reference_gut_energy_kj = as.double(
      appetite_reference_schedule$reference_gut_available_energy_kj
    ),
    forage_acquisition_ceiling_kg_dm_h = as.double(
      forage_acquisition_ceiling_schedule$
        forage_acquisition_ceiling_kg_dm_h
    ),
    routine_activity_kj_h = as.double(
      routine_activity_schedule$
        prescribed_routine_activity_expenditure_kj_h
    )
  )

  current_gut_energy_kj <- as.double(
    initial_gut_state$gut_available_energy_kj
  )
  current_body_energy_kj <- as.double(
    initial_body_state$body_energy_reserve_kj
  )
  current_forage_biomass_kg_dm_ha <- as.double(
    initial_forage_state$forage_biomass_kg_dm_ha
  )
  day_results <- vector("list", number_of_days)

  for (simulation_day in seq_len(number_of_days)) {
    day_result <- .run_nonspatial_coupled_day_prevalidated(
      current_gut_energy_kj,
      current_body_energy_kj,
      current_forage_biomass_kg_dm_ha,
      fixed,
      schedules,
      simulation_day
    )
    day_results[[simulation_day]] <- day_result
    current_gut_energy_kj <-
      day_result$daily$gut_available_energy_final_kj[[1L]]
    current_body_energy_kj <-
      day_result$daily$body_energy_reserve_final_kj[[1L]]
    current_forage_biomass_kg_dm_ha <-
      day_result$daily$forage_biomass_final_kg_dm_ha[[1L]]
  }

  hourly <- do.call(rbind, lapply(day_results, `[[`, "hourly"))
  daily <- do.call(rbind, lapply(day_results, `[[`, "daily"))
  row.names(hourly) <- NULL
  row.names(daily) <- NULL

  list(hourly = hourly, daily = daily)
}

.run_nonspatial_coupled_day_prevalidated <- function(
  initial_gut_energy_kj,
  initial_body_energy_kj,
  initial_forage_biomass_kg_dm_ha,
  fixed,
  schedules,
  simulation_day
) {
  hour_rows <- vector("list", 24L)
  current_gut_energy_kj <- initial_gut_energy_kj
  current_body_energy_kj <- initial_body_energy_kj
  current_forage_biomass_kg_dm_ha <- initial_forage_biomass_kg_dm_ha
  time_offset_h <- 24 * (simulation_day - 1L)

  for (row_index in seq_len(24L)) {
    turnover <- .step_forage_turnover_core(
      current_forage_biomass_kg_dm_ha,
      fixed$equilibrium_forage_biomass_kg_dm_ha,
      fixed$forage_turnover_fraction_h
    )
    forage_before_herbivory_kg_dm_ha <-
      turnover$state$forage_biomass_kg_dm_ha
    control <- .calculate_appetite_target_core(
      current_gut_energy_kj,
      current_body_energy_kj,
      fixed$energy_density_kj_kg_dm,
      fixed$maximum_intake_kg_dm_h,
      fixed$body_feedback_fraction_h,
      fixed$gut_feedback_fraction_h,
      schedules$feeding_opportunity_open[[row_index]],
      schedules$reference_intake_kg_dm_h[[row_index]],
      schedules$reference_body_energy_kj[[row_index]],
      schedules$reference_gut_energy_kj[[row_index]]
    )
    appetite_target_kg_dm_h <-
      control$appetite_target_dry_matter_intake_kg_dm_h
    external_ceiling_kg_dm_h <-
      schedules$forage_acquisition_ceiling_kg_dm_h[[row_index]]
    rate_limited_intake_kg_dm_h <- min(
      appetite_target_kg_dm_h,
      external_ceiling_kg_dm_h
    )
    rate_limited_intake_kg_dm <- rate_limited_intake_kg_dm_h
    herbivory <- .step_forage_herbivory_core(
      forage_before_herbivory_kg_dm_ha,
      fixed$herbivore_density_animals_ha,
      fixed$residual_threshold_kg_dm_ha,
      rate_limited_intake_kg_dm
    )
    realized_intake_kg_dm <-
      herbivory$fluxes$realized_dry_matter_intake_kg_dm
    realized_intake_kg_dm_h <- realized_intake_kg_dm
    realized_intake_energy_kj_h <-
      realized_intake_kg_dm_h * fixed$energy_density_kj_kg_dm
    energy <- .step_gut_body_energy_core(
      current_gut_energy_kj,
      current_body_energy_kj,
      fixed$gut_release_fraction_h,
      fixed$maintenance_expenditure_kj_h,
      realized_intake_energy_kj_h,
      schedules$routine_activity_kj_h[[row_index]]
    )

    forage_end_kg_dm_ha <-
      herbivory$state$forage_biomass_kg_dm_ha
    forage_growth_kg_dm_ha <-
      turnover$fluxes$forage_growth_kg_dm_ha
    forage_background_loss_kg_dm_ha <-
      turnover$fluxes$forage_background_loss_kg_dm_ha
    herbivory_removal_kg_dm_ha <-
      herbivory$fluxes$herbivory_removal_kg_dm_ha
    forage_balance_residual_kg_dm_ha <-
      (forage_end_kg_dm_ha - current_forage_biomass_kg_dm_ha) -
        (
          forage_growth_kg_dm_ha -
            forage_background_loss_kg_dm_ha -
            herbivory_removal_kg_dm_ha
        )
    forage_tolerance <- .forage_biomass_tolerance(
      current_forage_biomass_kg_dm_ha,
      forage_end_kg_dm_ha,
      forage_growth_kg_dm_ha,
      forage_background_loss_kg_dm_ha,
      herbivory_removal_kg_dm_ha
    )
    if (abs(forage_balance_residual_kg_dm_ha) > forage_tolerance) {
      stop("The hourly coupled forage balance does not close.", call. = FALSE)
    }

    gut <- energy$gut
    body <- energy$body
    hour_of_day <- schedules$hour_of_day[[row_index]]
    hour_rows[[row_index]] <- data.frame(
      simulation_day = as.integer(simulation_day),
      hour_of_day = hour_of_day,
      time_start_h = as.double(time_offset_h + hour_of_day),
      time_end_h = as.double(time_offset_h + hour_of_day + 1L),
      forage_biomass_start_kg_dm_ha =
        current_forage_biomass_kg_dm_ha,
      forage_growth_kg_dm_ha_h =
        turnover$fluxes$forage_growth_kg_dm_ha_h,
      forage_background_loss_kg_dm_ha_h =
        turnover$fluxes$forage_background_loss_kg_dm_ha_h,
      forage_growth_kg_dm_ha = forage_growth_kg_dm_ha,
      forage_background_loss_kg_dm_ha =
        forage_background_loss_kg_dm_ha,
      forage_biomass_before_herbivory_kg_dm_ha =
        forage_before_herbivory_kg_dm_ha,
      herbivore_density_animals_ha =
        fixed$herbivore_density_animals_ha,
      residual_unavailable_forage_threshold_kg_dm_ha =
        fixed$residual_threshold_kg_dm_ha,
      accessible_forage_biomass_kg_dm_ha =
        herbivory$fluxes$accessible_forage_biomass_kg_dm_ha,
      accessible_forage_per_animal_kg_dm =
        herbivory$fluxes$accessible_forage_per_animal_kg_dm,
      control,
      forage_acquisition_ceiling_kg_dm_h = external_ceiling_kg_dm_h,
      forage_acquisition_ceiling_active =
        appetite_target_kg_dm_h > external_ceiling_kg_dm_h,
      rate_limited_dry_matter_intake_kg_dm_h =
        rate_limited_intake_kg_dm_h,
      rate_limited_dry_matter_intake_kg_dm =
        rate_limited_intake_kg_dm,
      forage_stock_ceiling_active =
        herbivory$fluxes$forage_stock_ceiling_active,
      realized_dry_matter_intake_kg_dm_h =
        realized_intake_kg_dm_h,
      realized_dry_matter_intake_kg_dm =
        realized_intake_kg_dm,
      herbivory_removal_kg_dm_ha = herbivory_removal_kg_dm_ha,
      forage_biomass_end_kg_dm_ha = forage_end_kg_dm_ha,
      forage_biomass_balance_residual_kg_dm_ha =
        forage_balance_residual_kg_dm_ha,
      herbivore_forage_coupling_residual_kg_dm_ha =
        herbivory$fluxes$herbivore_forage_coupling_residual_kg_dm_ha,
      realized_ingested_available_energy_kj_h =
        realized_intake_energy_kj_h,
      gut_available_energy_start_kj =
        energy$system$gut_energy_start_kj,
      gut_release_fraction_h = fixed$gut_release_fraction_h,
      assimilated_energy_kj_h = gut$fluxes$assimilated_energy_kj_h,
      realized_ingested_available_energy_kj =
        gut$fluxes$prescribed_ingested_available_energy_kj,
      assimilated_energy_kj = gut$fluxes$assimilated_energy_kj,
      gut_energy_change_kj = gut$fluxes$gut_energy_change_kj,
      gut_available_energy_end_kj = gut$state$gut_available_energy_kj,
      gut_energy_balance_residual_kj =
        gut$fluxes$gut_energy_balance_residual_kj,
      body_energy_reserve_start_kj =
        energy$system$body_energy_start_kj,
      maintenance_expenditure_kj_h =
        fixed$maintenance_expenditure_kj_h,
      prescribed_routine_activity_expenditure_kj_h =
        schedules$routine_activity_kj_h[[row_index]],
      net_body_energy_rate_kj_h =
        body$fluxes$net_body_energy_rate_kj_h,
      maintenance_expenditure_kj =
        body$fluxes$maintenance_expenditure_kj,
      prescribed_routine_activity_expenditure_kj =
        body$fluxes$prescribed_routine_activity_expenditure_kj,
      body_energy_change_kj = body$fluxes$body_energy_change_kj,
      body_energy_reserve_end_kj =
        body$state$body_energy_reserve_kj,
      body_energy_balance_residual_kj =
        body$fluxes$energy_balance_residual_kj,
      total_system_energy_start_kj =
        energy$system$total_energy_start_kj,
      total_system_energy_end_kj =
        energy$system$total_energy_end_kj,
      system_energy_balance_residual_kj =
        energy$system$energy_balance_residual_kj,
      check.names = FALSE
    )

    current_forage_biomass_kg_dm_ha <- forage_end_kg_dm_ha
    current_gut_energy_kj <- gut$state$gut_available_energy_kj
    current_body_energy_kj <- body$state$body_energy_reserve_kj
  }

  hourly <- do.call(rbind, hour_rows)
  row.names(hourly) <- NULL
  daily <- .summarize_nonspatial_coupled_day(
    hourly,
    schedules$reference_gut_energy_kj[[1L]],
    schedules$reference_body_energy_kj[[1L]],
    fixed$herbivore_density_animals_ha
  )
  daily <- data.frame(
    simulation_day = as.integer(simulation_day),
    daily,
    check.names = FALSE
  )

  list(hourly = hourly, daily = daily)
}

.summarize_nonspatial_coupled_day <- function(
  hourly,
  next_day_reference_gut_energy_kj,
  next_day_reference_body_energy_kj,
  herbivore_density_animals_ha
) {
  animal <- .summarize_appetite_controlled_energy_day(
    hourly,
    next_day_reference_gut_energy_kj,
    next_day_reference_body_energy_kj
  )
  forage_initial_kg_dm_ha <-
    hourly$forage_biomass_start_kg_dm_ha[[1L]]
  forage_final_kg_dm_ha <-
    hourly$forage_biomass_end_kg_dm_ha[[24L]]
  total_growth_kg_dm_ha <- sum(hourly$forage_growth_kg_dm_ha)
  total_background_loss_kg_dm_ha <-
    sum(hourly$forage_background_loss_kg_dm_ha)
  total_herbivory_removal_kg_dm_ha <-
    sum(hourly$herbivory_removal_kg_dm_ha)
  expected_change_kg_dm_ha <-
    total_growth_kg_dm_ha -
      total_background_loss_kg_dm_ha -
      total_herbivory_removal_kg_dm_ha
  observed_change_kg_dm_ha <-
    forage_final_kg_dm_ha - forage_initial_kg_dm_ha
  forage_balance_residual_kg_dm_ha <-
    observed_change_kg_dm_ha - expected_change_kg_dm_ha
  coupling_residual_kg_dm_ha <-
    total_herbivory_removal_kg_dm_ha -
      herbivore_density_animals_ha *
        sum(hourly$realized_dry_matter_intake_kg_dm)
  tolerance <- .forage_biomass_tolerance(
    forage_initial_kg_dm_ha,
    forage_final_kg_dm_ha,
    total_growth_kg_dm_ha,
    total_background_loss_kg_dm_ha,
    total_herbivory_removal_kg_dm_ha
  )
  if (abs(forage_balance_residual_kg_dm_ha) > tolerance) {
    stop("The daily coupled forage balance does not close.", call. = FALSE)
  }
  if (abs(coupling_residual_kg_dm_ha) > tolerance) {
    stop("The daily herbivore-forage coupling does not close.", call. = FALSE)
  }

  data.frame(
    herbivore_density_animals_ha = herbivore_density_animals_ha,
    forage_biomass_initial_kg_dm_ha = forage_initial_kg_dm_ha,
    total_forage_growth_kg_dm_ha = total_growth_kg_dm_ha,
    total_forage_background_loss_kg_dm_ha =
      total_background_loss_kg_dm_ha,
    total_herbivory_removal_kg_dm_ha =
      total_herbivory_removal_kg_dm_ha,
    expected_forage_biomass_change_kg_dm_ha =
      expected_change_kg_dm_ha,
    observed_forage_biomass_change_kg_dm_ha =
      observed_change_kg_dm_ha,
    forage_biomass_final_kg_dm_ha = forage_final_kg_dm_ha,
    forage_biomass_balance_residual_kg_dm_ha =
      forage_balance_residual_kg_dm_ha,
    herbivore_forage_coupling_residual_kg_dm_ha =
      coupling_residual_kg_dm_ha,
    forage_stock_ceiling_active_hours = as.integer(
      sum(hourly$forage_stock_ceiling_active)
    ),
    minimum_accessible_forage_biomass_kg_dm_ha = min(
      hourly$accessible_forage_biomass_kg_dm_ha
    ),
    animal,
    check.names = FALSE
  )
}

.validate_nonspatial_coupling_parameters <- function(parameters) {
  expected_names <- c(
    "herbivore_density_animals_ha",
    "residual_unavailable_forage_threshold_kg_dm_ha"
  )
  if (!.has_exact_named_fields(parameters, expected_names)) {
    stop(
      paste0(
        "`parameters` must contain only `herbivore_density_animals_ha` ",
        "and `residual_unavailable_forage_threshold_kg_dm_ha`."
      ),
      call. = FALSE
    )
  }

  .validate_positive_herbivore_density(
    parameters$herbivore_density_animals_ha
  )
  .validate_nonnegative_numeric_scalar(
    parameters$residual_unavailable_forage_threshold_kg_dm_ha,
    "parameters$residual_unavailable_forage_threshold_kg_dm_ha"
  )
  invisible(NULL)
}

.validate_positive_herbivore_density <- function(value) {
  if (
    !.is_numeric_vector(value) ||
      length(value) != 1L ||
      !is.finite(as.double(value)) ||
      as.double(value) <= 0
  ) {
    stop(
      paste0(
        "`herbivore_density_animals_ha` must be one finite, strictly ",
        "positive numeric value."
      ),
      call. = FALSE
    )
  }
  invisible(NULL)
}
