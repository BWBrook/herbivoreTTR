#' Create a prescribed daily patch itinerary
#'
#' Create the patch occupied by the focal animal at each closing hourly
#' boundary of one 24-hour day. A change from the opening patch is interpreted
#' by [run_prescribed_spatial_energy_day()] as movement along one declared
#' known route; an unchanged patch is a stay.
#'
#' @param hour_of_day Numeric vector equal to `0:23`, in order.
#' @param prescribed_closing_patch_id Character vector of 24 non-empty patch
#'   identifiers. Landscape membership is checked by the spatial runner.
#'
#' @return A canonical base data frame with 24 rows and two columns.
#' @export
new_prescribed_patch_itinerary <- function(
  hour_of_day,
  prescribed_closing_patch_id
) {
  .validate_prescribed_patch_itinerary_fields(
    hour_of_day,
    prescribed_closing_patch_id
  )

  data.frame(
    hour_of_day = as.integer(hour_of_day),
    prescribed_closing_patch_id = as.character(
      prescribed_closing_patch_id
    )
  )
}

#' Run one prescribed spatial herbivore-energy day
#'
#' Carry explicit patch location through one prescribed 24-hour itinerary.
#' A patch change uses the declared one-hour known route, closes feeding during
#' that interval, and adds route expenditure to ordinary routine activity.
#' Patch identity selects one static non-depleting forage-acquisition ceiling
#' and one metabolizable-energy density.
#'
#' @param initial_location_state A patch-location state created by
#'   [new_patch_location_state()].
#' @param landscape A known-route landscape created by
#'   [new_known_route_landscape()].
#' @param itinerary A 24-row itinerary created by
#'   [new_prescribed_patch_itinerary()].
#' @param initial_gut_state A gut-energy state record created by
#'   [new_gut_energy_state()].
#' @param initial_body_state A body-energy state record created by
#'   [new_body_energy_state()].
#' @param gut_parameters A gut-energy parameter record created by
#'   [new_gut_energy_parameters()].
#' @param body_parameters A body-energy parameter record created by
#'   [new_body_energy_parameters()].
#' @param appetite_parameters An appetite-control parameter record created by
#'   [new_appetite_control_parameters()].
#' @param appetite_reference_schedule A 24-row schedule created by
#'   [new_appetite_reference_schedule()].
#' @param routine_activity_schedule A 24-row schedule created by
#'   [new_routine_activity_expenditure_schedule()].
#'
#' @return A plain list containing a 24-row `hourly` ledger and one-row `daily`
#'   summary.
#' @export
run_prescribed_spatial_energy_day <- function(
  initial_location_state,
  landscape,
  itinerary,
  initial_gut_state,
  initial_body_state,
  gut_parameters,
  body_parameters,
  appetite_parameters,
  appetite_reference_schedule,
  routine_activity_schedule
) {
  .validate_patch_location_state(initial_location_state)
  .validate_known_route_landscape(landscape)
  .validate_prescribed_patch_itinerary(itinerary)
  .validate_gut_energy_state(initial_gut_state)
  .validate_body_energy_state(initial_body_state)
  .validate_gut_energy_parameters(gut_parameters)
  .validate_body_energy_parameters(body_parameters)
  .validate_appetite_control_parameters(appetite_parameters)
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
  moving <- spatial_hourly$spatial_action == "move"

  effective_reference_intake_kg_dm_h <- as.double(
    appetite_reference_schedule$reference_dry_matter_intake_kg_dm_h
  )
  effective_reference_intake_kg_dm_h[moving] <- 0
  effective_forage_ceiling_kg_dm_h <-
    spatial_hourly$opening_patch_forage_acquisition_ceiling_kg_dm_h
  effective_forage_ceiling_kg_dm_h[moving] <- 0
  effective_activity_kj_h <- baseline_activity_kj_h +
    spatial_hourly$incremental_movement_expenditure_kj_h

  energy <- .run_appetite_controlled_energy_day_prevalidated(
    as.double(initial_gut_state$gut_available_energy_kj),
    as.double(initial_body_state$body_energy_reserve_kj),
    as.double(gut_parameters$gut_release_fraction_h),
    as.double(body_parameters$maintenance_expenditure_kj_h),
    spatial_hourly$opening_patch_metabolizable_energy_density_kj_kg_dm,
    as.double(appetite_parameters$maximum_dry_matter_intake_kg_dm_h),
    as.double(appetite_parameters$body_energy_feedback_fraction_h),
    as.double(appetite_parameters$gut_energy_feedback_fraction_h),
    as.integer(itinerary$hour_of_day),
    baseline_feeding_open & !moving,
    effective_reference_intake_kg_dm_h,
    as.double(appetite_reference_schedule$reference_body_energy_reserve_kj),
    as.double(appetite_reference_schedule$reference_gut_available_energy_kj),
    effective_forage_ceiling_kg_dm_h,
    effective_activity_kj_h
  )
  energy$hourly <- data.frame(
    simulation_day = rep.int(1L, 24L),
    energy$hourly,
    check.names = FALSE
  )
  energy$daily <- data.frame(
    simulation_day = 1L,
    energy$daily,
    check.names = FALSE
  )

  hourly <- data.frame(
    simulation_day = energy$hourly$simulation_day,
    spatial_hourly,
    energy$hourly[
      setdiff(names(energy$hourly), c("simulation_day", "hour_of_day"))
    ],
    check.names = FALSE
  )
  row.names(hourly) <- NULL

  energy_daily <- energy$daily[
    setdiff(names(energy$daily), "simulation_day")
  ]
  daily <- data.frame(
    simulation_day = 1L,
    initial_patch_id = spatial_hourly$opening_patch_id[[1L]],
    final_patch_id = spatial_hourly$closing_patch_id[[24L]],
    movement_hours = as.integer(sum(moving)),
    total_travel_duration_h = sum(spatial_hourly$travel_duration_h),
    feeding_time_lost_h = sum(spatial_hourly$feeding_time_lost_h),
    total_baseline_routine_activity_expenditure_kj =
      sum(spatial_hourly$
        baseline_prescribed_routine_activity_expenditure_kj_h),
    total_incremental_movement_expenditure_kj = sum(
      spatial_hourly$incremental_movement_expenditure_kj
    ),
    energy_daily,
    check.names = FALSE
  )
  row.names(daily) <- NULL

  list(hourly = hourly, daily = daily)
}

.run_prescribed_patch_itinerary_prevalidated <- function(
  initial_location_state,
  landscape,
  itinerary,
  baseline_feeding_open,
  baseline_activity_kj_h
) {
  rows <- vector("list", 24L)
  current_patch_id <- initial_location_state$patch_id

  for (row_index in seq_len(24L)) {
    closing_patch_id <- itinerary$prescribed_closing_patch_id[[row_index]]
    moving <- closing_patch_id != current_patch_id

    if (moving) {
      movement <- step_known_route_movement(
        list(patch_id = current_patch_id),
        landscape,
        closing_patch_id
      )
      travel_duration_h <- movement$fluxes$travel_duration_h
      feeding_suspended <-
        movement$fluxes$feeding_suspended_during_travel
      incremental_expenditure_kj_h <-
        movement$fluxes$incremental_movement_expenditure_kj_h
      incremental_expenditure_kj <-
        movement$fluxes$incremental_movement_expenditure_kj
    } else {
      travel_duration_h <- 0
      feeding_suspended <- FALSE
      incremental_expenditure_kj_h <- 0
      incremental_expenditure_kj <- 0
    }

    patch_index <- match(current_patch_id, landscape$patches$patch_id)
    opening_patch_acquisition_ceiling_kg_dm_h <-
      landscape$patches$forage_acquisition_ceiling_kg_dm_h[[patch_index]]
    opening_patch_energy_density_kj_kg_dm <-
      landscape$patches$metabolizable_energy_density_kj_kg_dm[[patch_index]]

    rows[[row_index]] <- data.frame(
      hour_of_day = itinerary$hour_of_day[[row_index]],
      opening_patch_id = current_patch_id,
      spatial_action = if (moving) "move" else "stay",
      closing_patch_id = closing_patch_id,
      opening_patch_forage_acquisition_ceiling_kg_dm_h =
        opening_patch_acquisition_ceiling_kg_dm_h,
      opening_patch_metabolizable_energy_density_kj_kg_dm =
        opening_patch_energy_density_kj_kg_dm,
      travel_duration_h = travel_duration_h,
      baseline_feeding_opportunity_open =
        baseline_feeding_open[[row_index]],
      feeding_suspended_during_travel = feeding_suspended,
      feeding_time_lost_h = as.double(
        feeding_suspended && baseline_feeding_open[[row_index]]
      ),
      baseline_prescribed_routine_activity_expenditure_kj_h =
        baseline_activity_kj_h[[row_index]],
      incremental_movement_expenditure_kj_h =
        incremental_expenditure_kj_h,
      incremental_movement_expenditure_kj = incremental_expenditure_kj,
      stringsAsFactors = FALSE
    )
    current_patch_id <- closing_patch_id
  }

  hourly <- do.call(rbind, rows)
  row.names(hourly) <- NULL
  hourly
}

.validate_prescribed_patch_itinerary <- function(itinerary) {
  expected_names <- c("hour_of_day", "prescribed_closing_patch_id")
  if (
    !is.data.frame(itinerary) ||
      !.has_exact_named_fields(itinerary, expected_names)
  ) {
    stop(
      paste0(
        "`itinerary` must contain only `hour_of_day` and ",
        "`prescribed_closing_patch_id`."
      ),
      call. = FALSE
    )
  }
  .validate_prescribed_patch_itinerary_fields(
    itinerary$hour_of_day,
    itinerary$prescribed_closing_patch_id
  )

  invisible(NULL)
}

.validate_prescribed_patch_itinerary_fields <- function(
  hour_of_day,
  prescribed_closing_patch_id
) {
  if (!.is_hour_of_day_schedule(hour_of_day)) {
    stop("`hour_of_day` must equal integer `0:23`, in order.", call. = FALSE)
  }
  .validate_patch_ids(
    prescribed_closing_patch_id,
    "prescribed_closing_patch_id",
    minimum_length = 24L,
    require_unique = FALSE
  )
  if (length(prescribed_closing_patch_id) != 24L) {
    stop(
      "`prescribed_closing_patch_id` must contain exactly 24 values.",
      call. = FALSE
    )
  }

  invisible(NULL)
}
