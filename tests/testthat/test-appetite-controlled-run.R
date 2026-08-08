.appetite_runner_fixture <- function(number_of_days = 3L) {
  hour_of_day <- 0:23
  feeding_opportunity_open <- hour_of_day %in% c(0:7, 16:23)
  reference_dry_matter_intake_kg_dm_h <-
    as.double(feeding_opportunity_open) * 0.020
  food_parameters <- herbivoreTTR::new_food_energy_parameters(10000)
  gut_parameters <- herbivoreTTR::new_gut_energy_parameters(0.25)
  body_parameters <- herbivoreTTR::new_body_energy_parameters(100)
  appetite_parameters <- herbivoreTTR::new_appetite_control_parameters(
    maximum_dry_matter_intake_kg_dm_h = 0.025,
    body_energy_feedback_fraction_h = 0.05,
    gut_energy_feedback_fraction_h = 0.10
  )
  dry_matter_schedule <- herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day,
    reference_dry_matter_intake_kg_dm_h
  )
  energy_schedule <- herbivoreTTR::derive_ingested_available_energy_schedule(
    food_parameters,
    dry_matter_schedule
  )
  routine_activity_schedule <-
    herbivoreTTR::new_routine_activity_expenditure_schedule(
      hour_of_day,
      as.double(feeding_opportunity_open) * 50
    )
  reference_cycle <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(0),
    measurement_body_state = herbivoreTTR::new_body_energy_state(10000),
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    schedule = energy_schedule,
    routine_activity_schedule = routine_activity_schedule,
    gut_convergence_relative_tolerance = 100 * .Machine$double.eps,
    max_burn_in_days = 100L
  )
  reference_hourly <- reference_cycle$hourly[
    reference_cycle$hourly$measurement_day == 1L,
    ,
    drop = FALSE
  ]
  row.names(reference_hourly) <- NULL
  appetite_reference_schedule <-
    herbivoreTTR::new_appetite_reference_schedule(
      hour_of_day = hour_of_day,
      feeding_opportunity_open = feeding_opportunity_open,
      reference_dry_matter_intake_kg_dm_h =
        reference_dry_matter_intake_kg_dm_h,
      reference_body_energy_reserve_kj =
        reference_hourly$body_energy_reserve_start_kj,
      reference_gut_available_energy_kj =
        reference_hourly$gut_available_energy_start_kj
    )
  forage_acquisition_ceiling_schedule <-
    herbivoreTTR::new_forage_acquisition_ceiling_schedule(
      hour_of_day,
      rep(0.025, 24L)
    )

  list(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(
      reference_hourly$gut_available_energy_start_kj[[1L]]
    ),
    initial_body_state = herbivoreTTR::new_body_energy_state(
      reference_hourly$body_energy_reserve_start_kj[[1L]]
    ),
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    food_parameters = food_parameters,
    appetite_parameters = appetite_parameters,
    appetite_reference_schedule = appetite_reference_schedule,
    forage_acquisition_ceiling_schedule =
      forage_acquisition_ceiling_schedule,
    routine_activity_schedule = routine_activity_schedule,
    number_of_days = number_of_days,
    reference_hourly = reference_hourly
  )
}

.run_appetite_fixture <- function(fixture) {
  do.call(
    herbivoreTTR::run_appetite_controlled_energy_days,
    fixture[names(fixture) != "reference_hourly"]
  )
}

.appetite_runner_hourly_columns <- c(
  "simulation_day",
  "hour_of_day",
  "time_start_h",
  "time_end_h",
  "feeding_opportunity_open",
  "reference_dry_matter_intake_kg_dm_h",
  "maximum_dry_matter_intake_kg_dm_h",
  "reference_ingested_available_energy_kj_h",
  "body_energy_deviation_from_reference_kj",
  "body_energy_feedback_kj_h",
  "gut_energy_deviation_from_reference_kj",
  "gut_energy_feedback_kj_h",
  "unconstrained_ingested_available_energy_kj_h",
  "unconstrained_dry_matter_intake_kg_dm_h",
  "appetite_target_dry_matter_intake_kg_dm_h",
  "appetite_target_ingested_available_energy_kj_h",
  "lower_intake_bound_active",
  "upper_intake_bound_active",
  "forage_acquisition_ceiling_kg_dm_h",
  "forage_acquisition_ceiling_active",
  "realized_dry_matter_intake_kg_dm_h",
  "realized_ingested_available_energy_kj_h",
  "gut_available_energy_start_kj",
  "gut_release_fraction_h",
  "assimilated_energy_kj_h",
  "realized_ingested_available_energy_kj",
  "assimilated_energy_kj",
  "gut_energy_change_kj",
  "gut_available_energy_end_kj",
  "gut_energy_balance_residual_kj",
  "body_energy_reserve_start_kj",
  "maintenance_expenditure_kj_h",
  "prescribed_routine_activity_expenditure_kj_h",
  "net_body_energy_rate_kj_h",
  "maintenance_expenditure_kj",
  "prescribed_routine_activity_expenditure_kj",
  "body_energy_change_kj",
  "body_energy_reserve_end_kj",
  "body_energy_balance_residual_kj",
  "total_system_energy_start_kj",
  "total_system_energy_end_kj",
  "system_energy_balance_residual_kj"
)

.appetite_runner_daily_columns <- c(
  "simulation_day",
  "reference_dry_matter_intake_kg_dm",
  "appetite_target_dry_matter_intake_kg_dm",
  "realized_dry_matter_intake_kg_dm",
  "total_reference_ingested_available_energy_kj",
  "total_appetite_target_ingested_available_energy_kj",
  "lower_intake_bound_hours",
  "upper_intake_bound_hours",
  "forage_acquisition_ceiling_active_hours",
  "gut_available_energy_initial_kj",
  "total_realized_ingested_available_energy_kj",
  "total_assimilated_energy_kj",
  "expected_gut_energy_change_kj",
  "observed_gut_energy_change_kj",
  "gut_available_energy_final_kj",
  "gut_energy_balance_residual_kj",
  "body_energy_reserve_initial_kj",
  "total_maintenance_expenditure_kj",
  "total_prescribed_routine_activity_expenditure_kj",
  "expected_body_energy_change_kj",
  "observed_body_energy_change_kj",
  "body_energy_reserve_final_kj",
  "body_energy_balance_residual_kj",
  "total_system_energy_initial_kj",
  "expected_total_system_energy_change_kj",
  "observed_total_system_energy_change_kj",
  "total_system_energy_final_kj",
  "system_energy_balance_residual_kj",
  "body_energy_status",
  "gut_energy_deviation_from_reference_final_kj",
  "body_energy_deviation_from_reference_final_kj",
  "combined_energy_deviation_from_reference_final_kj"
)

test_that("appetite-controlled runner has one exact canonical schema", {
  fixture <- .appetite_runner_fixture(number_of_days = 2L)
  result <- .run_appetite_fixture(fixture)

  expect_identical(
    names(formals(herbivoreTTR::run_appetite_controlled_energy_days)),
    c(
      "initial_gut_state",
      "initial_body_state",
      "gut_parameters",
      "body_parameters",
      "food_parameters",
      "appetite_parameters",
      "appetite_reference_schedule",
      "forage_acquisition_ceiling_schedule",
      "routine_activity_schedule",
      "number_of_days"
    )
  )
  expect_identical(names(result), c("hourly", "daily"))
  expect_identical(dim(result$hourly), c(48L, 42L))
  expect_identical(dim(result$daily), c(2L, 32L))
  expect_identical(names(result$hourly), .appetite_runner_hourly_columns)
  expect_identical(names(result$daily), .appetite_runner_daily_columns)
  expect_identical(result$hourly$simulation_day, rep(1:2, each = 24L))
  expect_identical(result$daily$simulation_day, 1:2)
  expect_identical(result$hourly$time_start_h, as.double(0:47))
  expect_identical(result$hourly$time_end_h, as.double(1:48))
})

test_that("balanced reference repeats numerically with exact state continuity", {
  fixture <- .appetite_runner_fixture(number_of_days = 3L)
  result <- .run_appetite_fixture(fixture)
  reference <- fixture$reference_hourly

  expect_equal(
    result$hourly$realized_dry_matter_intake_kg_dm_h,
    rep(reference$prescribed_ingested_available_energy_kj_h / 10000, 3L),
    tolerance = 1e-12
  )
  expect_equal(
    result$hourly$appetite_target_dry_matter_intake_kg_dm_h,
    result$hourly$realized_dry_matter_intake_kg_dm_h,
    tolerance = 1e-12
  )
  expect_false(any(result$hourly$forage_acquisition_ceiling_active))
  expect_equal(
    result$hourly$gut_available_energy_start_kj,
    rep(reference$gut_available_energy_start_kj, 3L),
    tolerance = 1e-12
  )
  expect_equal(
    result$hourly$gut_available_energy_end_kj,
    rep(reference$gut_available_energy_end_kj, 3L),
    tolerance = 1e-12
  )
  expect_equal(
    result$hourly$body_energy_reserve_start_kj,
    rep(reference$body_energy_reserve_start_kj, 3L),
    tolerance = 1e-12
  )
  expect_equal(
    result$hourly$body_energy_reserve_end_kj,
    rep(reference$body_energy_reserve_end_kj, 3L),
    tolerance = 1e-12
  )
  expect_lt(max(abs(result$hourly$body_energy_feedback_kj_h)), 1e-10)
  expect_lt(max(abs(result$hourly$gut_energy_feedback_kj_h)), 1e-10)
  expect_identical(
    result$hourly$gut_available_energy_end_kj[-72L],
    result$hourly$gut_available_energy_start_kj[-1L]
  )
  expect_identical(
    result$hourly$body_energy_reserve_end_kj[-72L],
    result$hourly$body_energy_reserve_start_kj[-1L]
  )
  expect_lt(
    max(abs(result$daily$observed_total_system_energy_change_kj)),
    1e-10
  )
  expect_lt(
    max(abs(
      result$daily$combined_energy_deviation_from_reference_final_kj
    )),
    1e-10
  )
  expect_lt(
    max(abs(result$hourly$gut_energy_balance_residual_kj)),
    1e-10
  )
  expect_lt(
    max(abs(result$hourly$body_energy_balance_residual_kj)),
    1e-10
  )
  expect_lt(
    max(abs(result$hourly$system_energy_balance_residual_kj)),
    1e-10
  )
})

test_that("binding forage ceiling limits acquisition without changing demand", {
  fixture <- .appetite_runner_fixture(number_of_days = 1L)
  opportunity <-
    fixture$appetite_reference_schedule$feeding_opportunity_open
  fixture$forage_acquisition_ceiling_schedule <-
    herbivoreTTR::new_forage_acquisition_ceiling_schedule(
      0:23,
      as.double(opportunity) * 0.015
    )
  result <- .run_appetite_fixture(fixture)

  expect_identical(
    result$hourly$forage_acquisition_ceiling_active,
    opportunity
  )
  expect_true(all(
    result$hourly$appetite_target_dry_matter_intake_kg_dm_h[opportunity] >
      result$hourly$realized_dry_matter_intake_kg_dm_h[opportunity]
  ))
  expect_identical(
    result$hourly$realized_dry_matter_intake_kg_dm_h[opportunity],
    rep(0.015, 16L)
  )
  expect_identical(
    result$hourly$realized_dry_matter_intake_kg_dm_h[!opportunity],
    rep(0, 8L)
  )
  expect_equal(result$daily$realized_dry_matter_intake_kg_dm, 0.24)
  expect_equal(
    result$daily$total_realized_ingested_available_energy_kj,
    2400
  )
  expect_identical(
    result$daily$forage_acquisition_ceiling_active_hours,
    16L
  )
  expect_gt(
    result$daily$appetite_target_dry_matter_intake_kg_dm,
    result$daily$realized_dry_matter_intake_kg_dm
  )
  expect_equal(
    result$daily$observed_total_system_energy_change_kj,
    -800,
    tolerance = 1e-10
  )
  expect_equal(
    result$daily$combined_energy_deviation_from_reference_final_kj,
    -800,
    tolerance = 1e-10
  )
  expect_lt(max(abs(result$hourly$system_energy_balance_residual_kj)), 1e-10)
})

test_that("runner exactly reproduces the accepted nine-day recovery", {
  fixture <- .appetite_runner_fixture(number_of_days = 9L)
  hour_of_day <- fixture$appetite_reference_schedule$hour_of_day
  shortfall_energy_schedule <-
    herbivoreTTR::derive_ingested_available_energy_schedule(
      fixture$food_parameters,
      herbivoreTTR::new_dry_matter_intake_schedule(
        hour_of_day,
        as.double(
          fixture$appetite_reference_schedule$feeding_opportunity_open
        ) * 0.015
      )
    )
  shortfall <- herbivoreTTR::run_gut_body_energy_day(
    initial_gut_state = fixture$initial_gut_state,
    initial_body_state = fixture$initial_body_state,
    gut_parameters = fixture$gut_parameters,
    body_parameters = fixture$body_parameters,
    schedule = shortfall_energy_schedule,
    routine_activity_schedule = fixture$routine_activity_schedule
  )
  fixture$initial_gut_state <- herbivoreTTR::new_gut_energy_state(
    shortfall$daily$gut_available_energy_final_kj
  )
  fixture$initial_body_state <- herbivoreTTR::new_body_energy_state(
    shortfall$daily$body_energy_reserve_final_kj
  )
  result <- .run_appetite_fixture(fixture)

  expect_equal(
    result$daily$realized_dry_matter_intake_kg_dm,
    c(
      0.362786487415867,
      0.338584159468865,
      0.329302973559338,
      0.324657330819324,
      0.322331591208275,
      0.321167260341500,
      0.320584363459600,
      0.320292548834887,
      0.320146458200607
    ),
    tolerance = 1e-12
  )
  expect_equal(
    result$daily$body_energy_deviation_from_reference_final_kj,
    c(-439, -220, -110, -55, -28, -14, -7, -3, -2),
    tolerance = 0.51
  )
  expect_equal(
    result$daily$combined_energy_deviation_from_reference_final_kj,
    c(-372, -186, -93, -47, -23, -12, -6, -3, -1),
    tolerance = 0.51
  )
  expect_true(all(result$daily$body_energy_deviation_from_reference_final_kj < 0))
  expect_true(all(diff(
    result$daily$body_energy_deviation_from_reference_final_kj
  ) > 0))
})

test_that("runner validates once-facing inputs and does not mutate them", {
  fixture <- .appetite_runner_fixture(
    number_of_days = structure(2, provenance = "accepted metadata")
  )
  before <- serialize(fixture, NULL)
  result <- .run_appetite_fixture(fixture)

  expect_identical(result$daily$simulation_day, 1:2)
  expect_identical(serialize(fixture, NULL), before)

  for (bad_days in list(0, 1.5, Inf, .Machine$integer.max + 1)) {
    invalid <- fixture
    invalid$number_of_days <- bad_days
    expect_error(
      .run_appetite_fixture(invalid),
      "number_of_days"
    )
  }

  invalid_maximum <- fixture
  invalid_maximum$appetite_parameters <-
    herbivoreTTR::new_appetite_control_parameters(0.015, 0.05, 0.10)
  expect_error(
    .run_appetite_fixture(invalid_maximum),
    "must not exceed"
  )

  invalid_body <- fixture
  invalid_body$initial_gut_state <- herbivoreTTR::new_gut_energy_state(0)
  invalid_body$initial_body_state <- herbivoreTTR::new_body_energy_state(1)
  expect_error(
    .run_appetite_fixture(invalid_body),
    "closing body-energy reserve is negative"
  )
})
