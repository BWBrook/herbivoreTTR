near <- function(observed, expected, tolerance = 1e-9) {
  scale <- pmax(1, abs(observed), abs(expected))
  length(observed) == length(expected) &&
    all(is.finite(observed)) &&
    all(is.finite(expected)) &&
    all(abs(observed - expected) <= tolerance * scale)
}

assert_that <- function(condition, label) {
  if (!isTRUE(condition)) {
    stop(sprintf("Herbivore-core diagnostic failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

new_herbivore_core_fixture <- function() {
  if (!requireNamespace("herbivoreTTR", quietly = TRUE)) {
    stop(
      "Install herbivoreTTR before running the retained experiments.",
      call. = FALSE
    )
  }

  hour_of_day <- 0:23
  feeding_hours <- c(0:7, 16:23)
  feeding_open <- hour_of_day %in% feeding_hours
  reference_intake_kg_dm_h <- as.double(feeding_open) * 0.020
  activity_kj_h <- as.double(feeding_open) * 50

  food <- herbivoreTTR::new_food_energy_parameters(10000)
  gut <- herbivoreTTR::new_gut_energy_parameters(0.25)
  body <- herbivoreTTR::new_body_energy_parameters(100)
  appetite <- herbivoreTTR::new_appetite_control_parameters(
    maximum_dry_matter_intake_kg_dm_h = 0.025,
    body_energy_feedback_fraction_h = 0.05,
    gut_energy_feedback_fraction_h = 0.10
  )
  activity <- herbivoreTTR::new_routine_activity_expenditure_schedule(
    hour_of_day,
    activity_kj_h
  )
  dry_matter <- herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day,
    reference_intake_kg_dm_h
  )
  energy <- herbivoreTTR::derive_ingested_available_energy_schedule(
    food,
    dry_matter
  )
  reference_cycle <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(0),
    measurement_body_state = herbivoreTTR::new_body_energy_state(40000),
    gut_parameters = gut,
    body_parameters = body,
    schedule = energy,
    routine_activity_schedule = activity,
    gut_convergence_relative_tolerance = 100 * .Machine$double.eps,
    max_burn_in_days = 100L
  )
  reference_hourly <- reference_cycle$hourly[
    reference_cycle$hourly$measurement_day == 1L,
    ,
    drop = FALSE
  ]
  row.names(reference_hourly) <- NULL

  appetite_reference <- herbivoreTTR::new_appetite_reference_schedule(
    hour_of_day = hour_of_day,
    feeding_opportunity_open = feeding_open,
    reference_dry_matter_intake_kg_dm_h = reference_intake_kg_dm_h,
    reference_body_energy_reserve_kj =
      reference_hourly$body_energy_reserve_start_kj,
    reference_gut_available_energy_kj =
      reference_hourly$gut_available_energy_start_kj
  )
  nonlimiting_forage <-
    herbivoreTTR::new_forage_acquisition_ceiling_schedule(
      hour_of_day,
      rep(0.025, 24L)
    )

  list(
    hour_of_day = hour_of_day,
    feeding_hours = feeding_hours,
    feeding_open = feeding_open,
    reference_intake_kg_dm_h = reference_intake_kg_dm_h,
    activity_kj_h = activity_kj_h,
    food = food,
    gut = gut,
    body = body,
    appetite = appetite,
    activity = activity,
    reference_cycle = reference_cycle,
    reference_hourly = reference_hourly,
    appetite_reference = appetite_reference,
    nonlimiting_forage = nonlimiting_forage,
    opening_gut = herbivoreTTR::new_gut_energy_state(
      reference_hourly$gut_available_energy_start_kj[[1L]]
    ),
    opening_body = herbivoreTTR::new_body_energy_state(40000)
  )
}

run_appetite_days <- function(
  fixture,
  number_of_days = 1L,
  initial_gut = fixture$opening_gut,
  initial_body = fixture$opening_body,
  food = fixture$food,
  appetite_reference = fixture$appetite_reference,
  forage = fixture$nonlimiting_forage,
  activity = fixture$activity
) {
  herbivoreTTR::run_appetite_controlled_energy_days(
    initial_gut_state = initial_gut,
    initial_body_state = initial_body,
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    food_parameters = food,
    appetite_parameters = fixture$appetite,
    appetite_reference_schedule = appetite_reference,
    forage_acquisition_ceiling_schedule = forage,
    routine_activity_schedule = activity,
    number_of_days = number_of_days
  )
}
