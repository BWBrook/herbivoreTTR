test_that("reference cycle produces a neutral carried trajectory", {
  fixture <- core_test_fixture()
  reference <- run_core_test_days(fixture, days = 2L)

  expect_true(tail(fixture$reference_cycle$convergence$converged, 1L))
  expect_equal(reference$daily$observed_total_system_energy_change_kj, c(0, 0))
  expect_true(
    max(abs(reference$daily$combined_energy_deviation_from_reference_final_kj)) <
      1e-8
  )
  expect_equal(
    reference$daily$gut_available_energy_initial_kj[[2L]],
    reference$daily$gut_available_energy_final_kj[[1L]]
  )
  expect_equal(
    reference$daily$body_energy_reserve_initial_kj[[2L]],
    reference$daily$body_energy_reserve_final_kj[[1L]]
  )
})

test_that("appetite responds directionally and respects opportunity and bounds", {
  fixture <- core_test_fixture()
  open_row <- fixture$appetite_reference[1L, , drop = FALSE]
  reference <- calculate_appetite_target(
    fixture$opening_gut,
    fixture$opening_body,
    fixture$food,
    fixture$appetite,
    open_row
  )
  deficit <- calculate_appetite_target(
    fixture$opening_gut,
    new_body_energy_state(39200),
    fixture$food,
    fixture$appetite,
    open_row
  )
  closed <- calculate_appetite_target(
    fixture$opening_gut,
    fixture$opening_body,
    fixture$food,
    fixture$appetite,
    fixture$appetite_reference[9L, , drop = FALSE]
  )

  expect_equal(reference$appetite_target_dry_matter_intake_kg_dm_h, 0.02)
  expect_gt(
    deficit$appetite_target_dry_matter_intake_kg_dm_h,
    reference$appetite_target_dry_matter_intake_kg_dm_h
  )
  expect_lte(deficit$appetite_target_dry_matter_intake_kg_dm_h, 0.025)
  expect_equal(closed$appetite_target_dry_matter_intake_kg_dm_h, 0)
})

test_that("forage limitation separates demand from realized intake", {
  fixture <- core_test_fixture()
  binding <- new_forage_acquisition_ceiling_schedule(
    fixture$hour_of_day,
    as.double(fixture$feeding_open) * 0.015
  )
  result <- run_core_test_days(fixture, forage = binding)

  expect_identical(result$daily$forage_acquisition_ceiling_active_hours, 16L)
  expect_gt(
    result$daily$appetite_target_dry_matter_intake_kg_dm,
    result$daily$realized_dry_matter_intake_kg_dm
  )
  expect_equal(result$daily$realized_dry_matter_intake_kg_dm, 0.24)
  expect_true(test_near(
    result$daily$observed_total_system_energy_change_kj,
    -800
  ))
})

test_that("lower-quality compensation balances rate without repaying debt", {
  fixture <- core_test_fixture()
  result <- run_core_test_days(
    fixture,
    days = 10L,
    food = new_food_energy_parameters(8000)
  )

  expect_true(test_near(
    result$daily$combined_energy_deviation_from_reference_final_kj[[10L]],
    -799,
    tolerance = 2e-3
  ))
  expect_lt(abs(result$daily$observed_total_system_energy_change_kj[[10L]]), 2)
  expect_gt(
    result$daily$realized_dry_matter_intake_kg_dm[[10L]],
    result$daily$realized_dry_matter_intake_kg_dm[[1L]]
  )
})
