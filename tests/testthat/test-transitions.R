test_that("gut release uses opening stock before current ingestion", {
  result <- step_gut_energy(
    new_gut_energy_state(400),
    new_gut_energy_parameters(0.25),
    data.frame(
      hour_of_day = 0L,
      prescribed_ingested_available_energy_kj_h = 100
    )
  )

  expect_equal(result$fluxes$assimilated_energy_kj, 100)
  expect_equal(result$state$gut_available_energy_kj, 400)
  expect_equal(result$fluxes$gut_energy_balance_residual_kj, 0)
})

test_that("body transition applies maintenance and activity once", {
  result <- step_body_energy(
    new_body_energy_state(5000),
    new_body_energy_parameters(100),
    data.frame(
      hour_of_day = 0L,
      prescribed_assimilated_energy_kj_h = 180
    ),
    data.frame(
      hour_of_day = 0L,
      prescribed_routine_activity_expenditure_kj_h = 50
    )
  )

  expect_equal(result$fluxes$body_energy_change_kj, 30)
  expect_equal(result$state$body_energy_reserve_kj, 5030)
  expect_equal(result$fluxes$energy_balance_residual_kj, 0)
  expect_error(
    step_body_energy(
      new_body_energy_state(10),
      new_body_energy_parameters(100),
      data.frame(
        hour_of_day = 0L,
        prescribed_assimilated_energy_kj_h = 0
      ),
      data.frame(
        hour_of_day = 0L,
        prescribed_routine_activity_expenditure_kj_h = 0
      )
    ),
    "negative"
  )
})

test_that("coupled day conserves energy and carries hourly state", {
  hour <- 0:23
  result <- run_gut_body_energy_day(
    initial_gut_state = new_gut_energy_state(400),
    initial_body_state = new_body_energy_state(5000),
    gut_parameters = new_gut_energy_parameters(0.25),
    body_parameters = new_body_energy_parameters(100),
    schedule = new_ingested_available_energy_schedule(
      hour,
      rep(100, 24L)
    ),
    routine_activity_schedule =
      new_routine_activity_expenditure_schedule(hour, rep(0, 24L))
  )

  expect_equal(nrow(result$hourly), 24L)
  expect_equal(
    result$hourly$gut_available_energy_start_kj[-1L],
    head(result$hourly$gut_available_energy_end_kj, -1L)
  )
  expect_equal(
    result$hourly$body_energy_reserve_start_kj[-1L],
    head(result$hourly$body_energy_reserve_end_kj, -1L)
  )
  expect_true(max(abs(result$hourly$system_energy_balance_residual_kj)) < 1e-8)
  expect_true(abs(result$daily$system_energy_balance_residual_kj) < 1e-8)
  expect_equal(result$daily$observed_total_system_energy_change_kj, 0)
})

test_that("body-only day remains an isolated component diagnostic", {
  hour <- 0:23
  result <- run_body_energy_day(
    new_body_energy_state(5000),
    new_body_energy_parameters(100),
    new_assimilated_energy_schedule(hour, rep(150, 24L)),
    new_routine_activity_expenditure_schedule(hour, rep(50, 24L))
  )
  expect_equal(result$daily$observed_body_energy_change_kj, 0)
  expect_identical(result$daily$energy_status, "neutral")
})
