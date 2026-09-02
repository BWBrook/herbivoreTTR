new_reactive_water_visit_plan <- function(
  initial_water_state,
  water_parameters,
  water_properties,
  landscape,
  base_energy_hourly,
  incremental_evaporative_loss_kg_h,
  water_source_patch_id,
  thirst_trigger_body_water_kg,
  preferred_opening_departure_hour =
    8L
) {
  if (
    !is.numeric(thirst_trigger_body_water_kg) ||
      length(thirst_trigger_body_water_kg) != 1L ||
      !is.finite(thirst_trigger_body_water_kg) ||
      thirst_trigger_body_water_kg < 0 ||
      thirst_trigger_body_water_kg >=
        water_parameters$normal_body_water_kg
  ) {
    stop(
      paste0(
        "`thirst_trigger_body_water_kg` must be one finite, non-negative ",
        "value below normal body water."
      )
    )
  }
  if (
    !is.numeric(preferred_opening_departure_hour) ||
      length(preferred_opening_departure_hour) != 1L ||
      !is.finite(preferred_opening_departure_hour) ||
      preferred_opening_departure_hour !=
        as.integer(preferred_opening_departure_hour) ||
      preferred_opening_departure_hour < 0 ||
      preferred_opening_departure_hour > 21
  ) {
    stop("`preferred_opening_departure_hour` must be one whole hour from 0 to 21.")
  }
  if (
    !is.data.frame(base_energy_hourly) ||
      nrow(base_energy_hourly) != 24L ||
      !all(c(
        "hour_of_day",
        "opening_patch_id",
        "closing_patch_id",
        "spatial_action"
      ) %in% names(base_energy_hourly)) ||
      !identical(as.integer(base_energy_hourly$hour_of_day), 0:23)
  ) {
    stop("`base_energy_hourly` must be one complete spatial energy day.")
  }
  source_index <- match(
    water_source_patch_id,
    water_properties$patch_id
  )
  if (
    is.na(source_index) ||
      water_properties$drinking_water_availability_kg_h[[source_index]] <= 0
  ) {
    stop("`water_source_patch_id` must identify a patch with drinking water.")
  }
  if (
    any(base_energy_hourly$opening_patch_id == water_source_patch_id) ||
      any(base_energy_hourly$closing_patch_id == water_source_patch_id)
  ) {
    stop("The base energy day must not already visit the drinking source.")
  }

  no_visit_water <- herbivoreTTR::run_spatial_body_water_day(
    initial_state = initial_water_state,
    parameters = water_parameters,
    patch_water_properties = water_properties,
    spatial_energy_hourly = base_energy_hourly,
    prescribed_incremental_evaporative_water_loss_kg_h =
      incremental_evaporative_loss_kg_h
  )
  opening_triggered <-
    initial_water_state$body_water_kg <= thirst_trigger_body_water_kg
  crossing_row <- if (opening_triggered) {
    NA_integer_
  } else {
    rows <- which(
      no_visit_water$hourly$body_water_end_kg <=
        thirst_trigger_body_water_kg
    )
    if (length(rows)) rows[[1L]] else NA_integer_
  }
  thirst_detected <- opening_triggered || !is.na(crossing_row)
  detection_time_h <- if (opening_triggered) {
    0L
  } else if (!is.na(crossing_row)) {
    as.integer(no_visit_water$hourly$hour_of_day[[crossing_row]] + 1L)
  } else {
    NA_integer_
  }
  earliest_departure_hour <- if (opening_triggered) {
    as.integer(preferred_opening_departure_hour)
  } else {
    detection_time_h
  }

  base_closing_patch_id <- as.character(base_energy_hourly$closing_patch_id)
  itinerary <- herbivoreTTR::new_prescribed_patch_itinerary(
    base_energy_hourly$hour_of_day,
    base_closing_patch_id
  )
  departure_hour <- NA_integer_
  origin_patch_id <- NA_character_
  if (thirst_detected && earliest_departure_hour <= 21L) {
    for (candidate_hour in seq.int(earliest_departure_hour, 21L)) {
      rows <- candidate_hour + seq_len(3L)
      candidate_origin <-
        base_energy_hourly$opening_patch_id[[rows[[1L]]]]
      stable_stay <-
        all(base_energy_hourly$spatial_action[rows] == "stay") &&
          all(base_energy_hourly$opening_patch_id[rows] == candidate_origin) &&
          all(base_energy_hourly$closing_patch_id[rows] == candidate_origin)
      outward_route <- with(
        landscape$routes,
        origin_patch_id == candidate_origin &
          destination_patch_id == water_source_patch_id
      )
      return_route <- with(
        landscape$routes,
        origin_patch_id == water_source_patch_id &
          destination_patch_id == candidate_origin
      )
      if (stable_stay && sum(outward_route) == 1L && sum(return_route) == 1L) {
        departure_hour <- as.integer(candidate_hour)
        origin_patch_id <- candidate_origin
        break
      }
    }
  }

  water_visit <- !is.na(departure_hour)
  if (water_visit) {
    departure_row <- departure_hour + 1L
    revised_closing_patch_id <- base_closing_patch_id
    revised_closing_patch_id[departure_row + 0:1] <- water_source_patch_id
    revised_closing_patch_id[[departure_row + 2L]] <- origin_patch_id
    itinerary <- herbivoreTTR::new_prescribed_patch_itinerary(
      base_energy_hourly$hour_of_day,
      revised_closing_patch_id
    )
  }
  drinking_hour <- if (water_visit) departure_hour + 1L else NA_integer_
  response_delay_h <- if (water_visit) {
    drinking_hour - detection_time_h
  } else {
    NA_integer_
  }

  list(
    itinerary = itinerary,
    no_visit_water = no_visit_water,
    thirst_detected = thirst_detected,
    thirst_detected_at_opening = opening_triggered,
    detection_time_h = detection_time_h,
    water_visit = water_visit,
    visit_deferred = thirst_detected && !water_visit,
    departure_hour = departure_hour,
    drinking_hour = drinking_hour,
    response_delay_h = response_delay_h
  )
}
