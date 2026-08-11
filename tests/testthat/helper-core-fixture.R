test_near <- function(observed, expected, tolerance = 1e-9) {
  scale <- pmax(1, abs(observed), abs(expected))
  all(abs(observed - expected) <= tolerance * scale)
}

core_test_fixture <- function() {
  hour_of_day <- 0:23
  feeding_open <- hour_of_day %in% c(0:7, 16:23)
  reference_rate <- as.double(feeding_open) * 0.020
  activity_rate <- as.double(feeding_open) * 50
  food <- new_food_energy_parameters(10000)
  gut <- new_gut_energy_parameters(0.25)
  body <- new_body_energy_parameters(100)
  activity <- new_routine_activity_expenditure_schedule(
    hour_of_day,
    activity_rate
  )
  energy <- derive_ingested_available_energy_schedule(
    food,
    new_dry_matter_intake_schedule(hour_of_day, reference_rate)
  )
  reference_cycle <- run_gut_body_energy_reference_cycle(
    initial_gut_state = new_gut_energy_state(0),
    measurement_body_state = new_body_energy_state(40000),
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

  list(
    hour_of_day = hour_of_day,
    feeding_open = feeding_open,
    reference_rate = reference_rate,
    food = food,
    gut = gut,
    body = body,
    activity = activity,
    appetite = new_appetite_control_parameters(0.025, 0.05, 0.10),
    appetite_reference = new_appetite_reference_schedule(
      hour_of_day,
      feeding_open,
      reference_rate,
      reference_hourly$body_energy_reserve_start_kj,
      reference_hourly$gut_available_energy_start_kj
    ),
    forage = new_forage_acquisition_ceiling_schedule(
      hour_of_day,
      rep(0.025, 24L)
    ),
    opening_gut = new_gut_energy_state(
      reference_hourly$gut_available_energy_start_kj[[1L]]
    ),
    opening_body = new_body_energy_state(40000),
    reference_cycle = reference_cycle
  )
}

run_core_test_days <- function(
  fixture,
  days = 1L,
  food = fixture$food,
  forage = fixture$forage,
  initial_gut = fixture$opening_gut,
  initial_body = fixture$opening_body
) {
  run_appetite_controlled_energy_days(
    initial_gut,
    initial_body,
    fixture$gut,
    fixture$body,
    food,
    fixture$appetite,
    fixture$appetite_reference,
    forage,
    fixture$activity,
    days
  )
}
