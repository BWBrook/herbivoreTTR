#' Create a spatial forage-biomass state
#'
#' Create one dynamic standing-forage stock for every named patch. Static
#' landscape properties remain in the landscape record; this state contains
#' patch identity and biomass only.
#'
#' @param patch_id Character vector of unique, non-empty patch identifiers.
#' @param forage_biomass_kg_dm_ha Finite, non-negative numeric vector giving
#'   standing forage biomass density for each patch, in kilograms dry matter
#'   per hectare.
#'
#' @return A canonical base data frame containing `patch_id` and
#'   `forage_biomass_kg_dm_ha`.
#' @export
new_spatial_forage_biomass_state <- function(
  patch_id,
  forage_biomass_kg_dm_ha
) {
  .validate_spatial_forage_biomass_fields(
    patch_id,
    forage_biomass_kg_dm_ha
  )

  data.frame(
    patch_id = as.character(patch_id),
    forage_biomass_kg_dm_ha = as.double(forage_biomass_kg_dm_ha),
    stringsAsFactors = FALSE
  )
}

#' Run one prescribed spatial herbivore-forage day
#'
#' Apply autonomous forage turnover to every patch, then remove forage from
#' the occupied opening patch only when the prescribed itinerary stays in that
#' patch. Known-route movement suspends feeding and adds route expenditure.
#' Gut, body, location, and all patch stocks are carried through 24 hourly
#' transitions.
#'
#' @param initial_location_state A patch-location state created by
#'   [new_patch_location_state()].
#' @param landscape A known-route landscape created by
#'   [new_known_route_landscape()].
#' @param itinerary A 24-row itinerary created by
#'   [new_prescribed_patch_itinerary()].
#' @param initial_gut_state A gut-energy state created by
#'   [new_gut_energy_state()].
#' @param initial_body_state A body-energy state created by
#'   [new_body_energy_state()].
#' @param initial_spatial_forage_state A spatial forage-biomass state created
#'   by [new_spatial_forage_biomass_state()].
#' @param gut_parameters Gut-energy parameters created by
#'   [new_gut_energy_parameters()].
#' @param body_parameters Body-energy parameters created by
#'   [new_body_energy_parameters()].
#' @param appetite_parameters Appetite-control parameters created by
#'   [new_appetite_control_parameters()].
#' @param forage_turnover_parameters Common forage-turnover parameters created
#'   by [new_forage_turnover_parameters()].
#' @param coupling_parameters Herbivore-density and residual-threshold
#'   parameters created by [new_nonspatial_coupling_parameters()].
#' @param appetite_reference_schedule A 24-row schedule created by
#'   [new_appetite_reference_schedule()].
#' @param routine_activity_schedule A 24-row schedule created by
#'   [new_routine_activity_expenditure_schedule()].
#'
#' @return A plain list containing 24-row animal-location `hourly` and one-row
#'   `daily` ledgers, long-form `patch_hourly` and `patch_daily` forage ledgers,
#'   and a composable `final_state`.
#' @export
run_prescribed_spatial_coupled_energy_day <- function(
  initial_location_state,
  landscape,
  itinerary,
  initial_gut_state,
  initial_body_state,
  initial_spatial_forage_state,
  gut_parameters,
  body_parameters,
  appetite_parameters,
  forage_turnover_parameters,
  coupling_parameters,
  appetite_reference_schedule,
  routine_activity_schedule
) {
  .validate_patch_location_state(initial_location_state)
  .validate_known_route_landscape(landscape)
  .validate_prescribed_patch_itinerary(itinerary)
  .validate_gut_energy_state(initial_gut_state)
  .validate_body_energy_state(initial_body_state)
  .validate_spatial_forage_biomass_state(initial_spatial_forage_state)
  .validate_gut_energy_parameters(gut_parameters)
  .validate_body_energy_parameters(body_parameters)
  .validate_appetite_control_parameters(appetite_parameters)
  .validate_forage_turnover_parameters(forage_turnover_parameters)
  .validate_nonspatial_coupling_parameters(coupling_parameters)
  .validate_appetite_reference_schedule(appetite_reference_schedule)
  .validate_routine_activity_expenditure_schedule(
    routine_activity_schedule
  )

  patch_ids <- landscape$patches$patch_id
  if (!(initial_location_state$patch_id %in% patch_ids)) {
    stop("The initial location is not present in `landscape`.", call. = FALSE)
  }
  if (!all(itinerary$prescribed_closing_patch_id %in% patch_ids)) {
    stop(
      "Every prescribed closing patch must be present in `landscape`.",
      call. = FALSE
    )
  }
  if (!setequal(initial_spatial_forage_state$patch_id, patch_ids)) {
    stop(
      "The spatial forage state must contain exactly the landscape patch set.",
      call. = FALSE
    )
  }

  state_order <- match(patch_ids, initial_spatial_forage_state$patch_id)
  current_forage_biomass_kg_dm_ha <- as.double(
    initial_spatial_forage_state$forage_biomass_kg_dm_ha[state_order]
  )
  current_gut_energy_kj <- as.double(
    initial_gut_state$gut_available_energy_kj
  )
  current_body_energy_kj <- as.double(
    initial_body_state$body_energy_reserve_kj
  )

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

  baseline_feeding_open <- as.logical(
    appetite_reference_schedule$feeding_opportunity_open
  )
  baseline_activity_kj_h <- as.double(
    routine_activity_schedule$
      prescribed_routine_activity_expenditure_kj_h
  )
  spatial_hourly <- .run_prescribed_patch_itinerary_prevalidated(
    initial_location_state,
    landscape,
    itinerary,
    baseline_feeding_open,
    baseline_activity_kj_h
  )

  fixed <- list(
    gut_release_fraction_h = as.double(
      gut_parameters$gut_release_fraction_h
    ),
    maintenance_expenditure_kj_h = as.double(
      body_parameters$maintenance_expenditure_kj_h
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
    reference_intake_kg_dm_h = reference_intake_kg_dm_h,
    reference_body_energy_kj = as.double(
      appetite_reference_schedule$reference_body_energy_reserve_kj
    ),
    reference_gut_energy_kj = as.double(
      appetite_reference_schedule$reference_gut_available_energy_kj
    )
  )

  hour_rows <- vector("list", 24L)
  patch_rows <- vector("list", 24L)

  for (row_index in seq_len(24L)) {
    spatial <- spatial_hourly[row_index, , drop = FALSE]
    moving <- spatial$spatial_action[[1L]] == "move"
    opening_patch_index <- match(spatial$opening_patch_id[[1L]], patch_ids)

    turnover <- lapply(current_forage_biomass_kg_dm_ha, function(biomass) {
      .step_forage_turnover_core(
        biomass,
        fixed$equilibrium_forage_biomass_kg_dm_ha,
        fixed$forage_turnover_fraction_h
      )
    })
    forage_before_herbivory_kg_dm_ha <- vapply(
      turnover,
      function(x) x$state$forage_biomass_kg_dm_ha,
      numeric(1L)
    )
    forage_growth_kg_dm_ha_h <- vapply(
      turnover,
      function(x) x$fluxes$forage_growth_kg_dm_ha_h,
      numeric(1L)
    )
    forage_background_loss_kg_dm_ha_h <- vapply(
      turnover,
      function(x) x$fluxes$forage_background_loss_kg_dm_ha_h,
      numeric(1L)
    )
    forage_growth_kg_dm_ha <- vapply(
      turnover,
      function(x) x$fluxes$forage_growth_kg_dm_ha,
      numeric(1L)
    )
    forage_background_loss_kg_dm_ha <- vapply(
      turnover,
      function(x) x$fluxes$forage_background_loss_kg_dm_ha,
      numeric(1L)
    )

    effective_feeding_open <-
      baseline_feeding_open[[row_index]] && !moving
    effective_reference_intake_kg_dm_h <-
      schedules$reference_intake_kg_dm_h[[row_index]]
    if (moving) {
      effective_reference_intake_kg_dm_h <- 0
    }
    external_ceiling_kg_dm_h <-
      spatial$opening_patch_forage_acquisition_ceiling_kg_dm_h[[1L]]
    if (moving) {
      external_ceiling_kg_dm_h <- 0
    }
    effective_activity_kj_h <-
      baseline_activity_kj_h[[row_index]] +
        spatial$incremental_movement_expenditure_kj_h[[1L]]
    fixed$energy_density_kj_kg_dm <-
      spatial$opening_patch_metabolizable_energy_density_kj_kg_dm[[1L]]
    step <- .step_post_turnover_coupled_energy_core(
      forage_before_herbivory_kg_dm_ha[[opening_patch_index]],
      current_gut_energy_kj,
      current_body_energy_kj,
      fixed,
      effective_feeding_open,
      effective_reference_intake_kg_dm_h,
      schedules$reference_body_energy_kj[[row_index]],
      schedules$reference_gut_energy_kj[[row_index]],
      external_ceiling_kg_dm_h,
      effective_activity_kj_h
    )
    forage_end_kg_dm_ha <- forage_before_herbivory_kg_dm_ha
    forage_end_kg_dm_ha[[opening_patch_index]] <-
      step$state$forage_biomass_kg_dm_ha
    herbivory_removal_kg_dm_ha <- numeric(length(patch_ids))
    herbivory_removal_kg_dm_ha[[opening_patch_index]] <-
      step$fluxes$herbivory_removal_kg_dm_ha

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
    if (any(abs(forage_balance_residual_kg_dm_ha) > forage_tolerance)) {
      stop("An hourly spatial forage balance does not close.", call. = FALSE)
    }

    coupling_residual_kg_dm_ha <-
      sum(herbivory_removal_kg_dm_ha) -
        fixed$herbivore_density_animals_ha *
          step$intake_ledger$realized_dry_matter_intake_kg_dm
    if (abs(coupling_residual_kg_dm_ha) > forage_tolerance) {
      stop(
        "The hourly spatial herbivore-forage coupling does not close.",
        call. = FALSE
      )
    }

    hour_rows[[row_index]] <- data.frame(
      simulation_day = 1L,
      spatial,
      time_start_h = as.double(spatial$hour_of_day[[1L]]),
      time_end_h = as.double(spatial$hour_of_day[[1L]] + 1L),
      forage_biomass_start_kg_dm_ha =
        current_forage_biomass_kg_dm_ha[[opening_patch_index]],
      forage_growth_kg_dm_ha_h =
        forage_growth_kg_dm_ha_h[[opening_patch_index]],
      forage_background_loss_kg_dm_ha_h =
        forage_background_loss_kg_dm_ha_h[[opening_patch_index]],
      forage_growth_kg_dm_ha =
        forage_growth_kg_dm_ha[[opening_patch_index]],
      forage_background_loss_kg_dm_ha =
        forage_background_loss_kg_dm_ha[[opening_patch_index]],
      forage_biomass_before_herbivory_kg_dm_ha =
        forage_before_herbivory_kg_dm_ha[[opening_patch_index]],
      metabolizable_energy_density_kj_kg_dm =
        fixed$energy_density_kj_kg_dm,
      step$intake_ledger,
      forage_biomass_end_kg_dm_ha =
        forage_end_kg_dm_ha[[opening_patch_index]],
      forage_biomass_balance_residual_kg_dm_ha =
        forage_balance_residual_kg_dm_ha[[opening_patch_index]],
      herbivore_forage_coupling_residual_kg_dm_ha =
        coupling_residual_kg_dm_ha,
      step$energy_ledger,
      check.names = FALSE
    )

    accessible_forage_biomass_kg_dm_ha <- pmax(
      0,
      forage_before_herbivory_kg_dm_ha - fixed$residual_threshold_kg_dm_ha
    )
    patch_stock_ceiling_active <- rep(FALSE, length(patch_ids))
    patch_stock_ceiling_active[[opening_patch_index]] <-
      step$intake_ledger$forage_stock_ceiling_active
    patch_rows[[row_index]] <- data.frame(
      simulation_day = 1L,
      hour_of_day = spatial$hour_of_day[[1L]],
      patch_id = patch_ids,
      occupied_at_opening = patch_ids == spatial$opening_patch_id[[1L]],
      occupied_stay =
        (patch_ids == spatial$opening_patch_id[[1L]]) & !moving,
      forage_biomass_start_kg_dm_ha =
        current_forage_biomass_kg_dm_ha,
      forage_growth_kg_dm_ha_h = forage_growth_kg_dm_ha_h,
      forage_background_loss_kg_dm_ha_h =
        forage_background_loss_kg_dm_ha_h,
      forage_growth_kg_dm_ha = forage_growth_kg_dm_ha,
      forage_background_loss_kg_dm_ha =
        forage_background_loss_kg_dm_ha,
      forage_biomass_before_herbivory_kg_dm_ha =
        forage_before_herbivory_kg_dm_ha,
      accessible_forage_biomass_kg_dm_ha =
        accessible_forage_biomass_kg_dm_ha,
      herbivory_removal_kg_dm_ha = herbivory_removal_kg_dm_ha,
      forage_stock_ceiling_active = patch_stock_ceiling_active,
      forage_biomass_end_kg_dm_ha = forage_end_kg_dm_ha,
      forage_biomass_balance_residual_kg_dm_ha =
        forage_balance_residual_kg_dm_ha,
      stringsAsFactors = FALSE
    )

    current_forage_biomass_kg_dm_ha <- forage_end_kg_dm_ha
    current_gut_energy_kj <- step$state$gut_available_energy_kj
    current_body_energy_kj <- step$state$body_energy_reserve_kj
  }

  hourly <- do.call(rbind, hour_rows)
  patch_hourly <- do.call(rbind, patch_rows)
  row.names(hourly) <- NULL
  row.names(patch_hourly) <- NULL

  animal_daily <- .summarize_appetite_controlled_energy_day(
    hourly,
    schedules$reference_gut_energy_kj[[1L]],
    schedules$reference_body_energy_kj[[1L]]
  )
  moving <- spatial_hourly$spatial_action == "move"
  daily <- data.frame(
    simulation_day = 1L,
    initial_patch_id = spatial_hourly$opening_patch_id[[1L]],
    final_patch_id = spatial_hourly$closing_patch_id[[24L]],
    movement_hours = as.integer(sum(moving)),
    total_travel_duration_h = sum(spatial_hourly$travel_duration_h),
    feeding_time_lost_h = sum(spatial_hourly$feeding_time_lost_h),
    total_baseline_routine_activity_expenditure_kj = sum(
      spatial_hourly$
        baseline_prescribed_routine_activity_expenditure_kj_h
    ),
    total_incremental_movement_expenditure_kj = sum(
      spatial_hourly$incremental_movement_expenditure_kj
    ),
    forage_stock_ceiling_active_hours = as.integer(
      sum(hourly$forage_stock_ceiling_active)
    ),
    herbivore_forage_coupling_residual_kg_dm_ha =
      sum(patch_hourly$herbivory_removal_kg_dm_ha) -
        fixed$herbivore_density_animals_ha *
          sum(hourly$realized_dry_matter_intake_kg_dm),
    animal_daily,
    check.names = FALSE
  )
  row.names(daily) <- NULL

  patch_daily_rows <- lapply(patch_ids, function(patch_id) {
    patch <- patch_hourly[patch_hourly$patch_id == patch_id, , drop = FALSE]
    initial_biomass <- patch$forage_biomass_start_kg_dm_ha[[1L]]
    final_biomass <- patch$forage_biomass_end_kg_dm_ha[[24L]]
    total_growth <- sum(patch$forage_growth_kg_dm_ha)
    total_background_loss <- sum(
      patch$forage_background_loss_kg_dm_ha
    )
    total_herbivory <- sum(patch$herbivory_removal_kg_dm_ha)
    expected_change <- total_growth - total_background_loss - total_herbivory
    observed_change <- final_biomass - initial_biomass
    balance_residual <- observed_change - expected_change
    tolerance <- .forage_biomass_tolerance(
      initial_biomass,
      final_biomass,
      total_growth,
      total_background_loss,
      total_herbivory
    )
    if (abs(balance_residual) > tolerance) {
      stop("A daily spatial forage balance does not close.", call. = FALSE)
    }

    data.frame(
      simulation_day = 1L,
      patch_id = patch_id,
      occupied_opening_hours = as.integer(sum(patch$occupied_at_opening)),
      occupied_stay_hours = as.integer(sum(patch$occupied_stay)),
      forage_biomass_initial_kg_dm_ha = initial_biomass,
      total_forage_growth_kg_dm_ha = total_growth,
      total_forage_background_loss_kg_dm_ha = total_background_loss,
      total_herbivory_removal_kg_dm_ha = total_herbivory,
      expected_forage_biomass_change_kg_dm_ha = expected_change,
      observed_forage_biomass_change_kg_dm_ha = observed_change,
      forage_biomass_final_kg_dm_ha = final_biomass,
      forage_biomass_balance_residual_kg_dm_ha = balance_residual,
      forage_stock_ceiling_active_hours = as.integer(
        sum(patch$forage_stock_ceiling_active)
      ),
      stringsAsFactors = FALSE
    )
  })
  patch_daily <- do.call(rbind, patch_daily_rows)
  row.names(patch_daily) <- NULL

  list(
    hourly = hourly,
    daily = daily,
    patch_hourly = patch_hourly,
    patch_daily = patch_daily,
    final_state = list(
      location = new_patch_location_state(
        spatial_hourly$closing_patch_id[[24L]]
      ),
      gut = new_gut_energy_state(current_gut_energy_kj),
      body = new_body_energy_state(current_body_energy_kj),
      forage = new_spatial_forage_biomass_state(
        patch_ids,
        current_forage_biomass_kg_dm_ha
      )
    )
  )
}

.validate_spatial_forage_biomass_state <- function(state) {
  expected_names <- c("patch_id", "forage_biomass_kg_dm_ha")
  if (
    !is.data.frame(state) ||
      !.has_exact_named_fields(state, expected_names)
  ) {
    stop(
      paste0(
        "`state` must be a data frame containing only `patch_id` and ",
        "`forage_biomass_kg_dm_ha`."
      ),
      call. = FALSE
    )
  }
  .validate_spatial_forage_biomass_fields(
    state$patch_id,
    state$forage_biomass_kg_dm_ha
  )

  invisible(NULL)
}

.validate_spatial_forage_biomass_fields <- function(
  patch_id,
  forage_biomass_kg_dm_ha
) {
  .validate_patch_ids(patch_id, "patch_id", minimum_length = 1L)
  if (
    !.is_numeric_vector(forage_biomass_kg_dm_ha) ||
      length(forage_biomass_kg_dm_ha) != length(patch_id) ||
      any(!is.finite(as.double(forage_biomass_kg_dm_ha))) ||
      any(as.double(forage_biomass_kg_dm_ha) < 0)
  ) {
    stop(
      paste0(
        "`forage_biomass_kg_dm_ha` must contain one finite, non-negative ",
        "numeric value per patch."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}
