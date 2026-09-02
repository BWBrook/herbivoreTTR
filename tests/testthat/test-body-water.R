test_that("body-water records retain physical units and boundaries", {
  expect_identical(
    new_body_water_state(28),
    list(body_water_kg = 28)
  )
  expect_identical(
    new_body_water_parameters(28, 24, 0.065),
    list(
      normal_body_water_kg = 28,
      critical_body_water_kg = 24,
      ordinary_water_loss_kg_h = 0.065
    )
  )
  schedule <- new_body_water_schedule(
    0:23,
    rep(0.065, 24L),
    rep(0, 24L),
    rep(0, 24L)
  )
  expect_equal(nrow(schedule), 24L)
  expect_type(schedule$prescribed_food_derived_water_kg_h, "double")

  expect_error(new_body_water_state(-1), "non-negative")
  expect_error(new_body_water_parameters(28, 28, 0.065), "below")
  expect_error(
    new_body_water_schedule(
      1:24,
      rep(0, 24L),
      rep(0, 24L),
      rep(0, 24L)
    ),
    "0:23"
  )
  expect_error(
    new_body_water_schedule(
      0:23,
      rep(0, 24L),
      rep(0, 24L),
      c(-0.1, rep(0, 23L))
    ),
    "non-negative"
  )
})

test_that("hourly water arithmetic fills, spills, and closes", {
  parameters <- new_body_water_parameters(28, 24, 0.05)
  fill <- step_body_water(
    new_body_water_state(27),
    parameters,
    data.frame(
      hour_of_day = 0L,
      prescribed_food_derived_water_kg_h = 0.1,
      available_drinking_water_kg_h = 2,
      prescribed_incremental_evaporative_water_loss_kg_h = 0
    )
  )
  expect_equal(fill$fluxes$realized_drinking_water_kg, 0.95)
  expect_equal(fill$state$body_water_kg, 28)
  expect_equal(fill$fluxes$body_water_balance_residual_kg, 0)

  spill <- step_body_water(
    new_body_water_state(28),
    parameters,
    data.frame(
      hour_of_day = 1L,
      prescribed_food_derived_water_kg_h = 0.2,
      available_drinking_water_kg_h = 0,
      prescribed_incremental_evaporative_water_loss_kg_h = 0
    )
  )
  expect_equal(spill$fluxes$excess_water_elimination_kg, 0.15)
  expect_equal(spill$state$body_water_kg, 28)

  critical <- step_body_water(
    new_body_water_state(24.05),
    new_body_water_parameters(28, 24, 0.1),
    data.frame(
      hour_of_day = 2L,
      prescribed_food_derived_water_kg_h = 0,
      available_drinking_water_kg_h = 0,
      prescribed_incremental_evaporative_water_loss_kg_h = 0
    )
  )
  expect_true(critical$fluxes$body_water_below_critical)
  expect_error(
    step_body_water(
      new_body_water_state(0.01),
      new_body_water_parameters(28, 24, 0.1),
      data.frame(
        hour_of_day = 2L,
        prescribed_food_derived_water_kg_h = 0,
        available_drinking_water_kg_h = 0,
        prescribed_incremental_evaporative_water_loss_kg_h = 0
      )
    ),
    "negative"
  )
})

test_that("the isolated daily water reference is exactly repeatable", {
  parameters <- new_body_water_parameters(28, 24, 1.56 / 24)
  neutral <- run_body_water_day(
    new_body_water_state(28),
    parameters,
    new_body_water_schedule(
      0:23,
      rep(1.56 / 24, 24L),
      rep(0, 24L),
      rep(0, 24L)
    )
  )
  deficit <- run_body_water_day(
    new_body_water_state(28),
    parameters,
    new_body_water_schedule(
      0:23,
      rep(0, 24L),
      rep(0, 24L),
      rep(0, 24L)
    )
  )

  expect_equal(neutral$daily$body_water_final_kg, 28)
  expect_equal(neutral$daily$expected_body_water_change_kg, 0)
  expect_equal(neutral$daily$observed_body_water_change_kg, 0)
  expect_true(abs(neutral$daily$body_water_balance_residual_kg) < 1e-12)
  expect_true(
    max(abs(neutral$hourly$body_water_balance_residual_kg)) < 1e-12
  )
  expect_equal(deficit$daily$body_water_final_kg, 26.44)
  expect_equal(deficit$daily$total_ordinary_water_loss_kg, 1.56)
  expect_equal(
    deficit$daily$expected_body_water_change_kg,
    deficit$daily$observed_body_water_change_kg
  )
})

test_that("prescribed incremental evaporation is a separate exact loss", {
  parameters <- new_body_water_parameters(28, 24, 0)
  zero <- run_body_water_day(
    new_body_water_state(28),
    parameters,
    new_body_water_schedule(
      0:23,
      rep(0, 24L),
      rep(0, 24L),
      rep(0, 24L)
    )
  )
  forced <- run_body_water_day(
    new_body_water_state(28),
    parameters,
    new_body_water_schedule(
      0:23,
      rep(0, 24L),
      rep(0, 24L),
      c(0.2, rep(0, 23L))
    )
  )

  expect_equal(zero$daily$body_water_final_kg, 28)
  expect_equal(
    forced$daily$total_incremental_evaporative_water_loss_kg,
    0.2
  )
  expect_equal(forced$daily$body_water_final_kg, 27.8)
  expect_equal(
    zero$daily$body_water_final_kg - forced$daily$body_water_final_kg,
    0.2
  )
  expect_true(abs(forced$daily$body_water_balance_residual_kg) < 1e-12)
})
