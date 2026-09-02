test_that("spatial intake and stationary source access drive body water", {
  fixture <- core_test_fixture()
  landscape <- new_known_route_landscape(
    patch_id = c("forage", "water"),
    forage_acquisition_ceiling_kg_dm_h = c(0.025, 0),
    route_origin_patch_id = c("forage", "water"),
    route_destination_patch_id = c("water", "forage"),
    incremental_movement_expenditure_kj = c(900, 900),
    metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
  )
  itinerary <- rep("forage", 24L)
  itinerary[fixture$hour_of_day == 8L] <- "water"
  itinerary[fixture$hour_of_day == 9L] <- "water"
  energy <- run_prescribed_spatial_energy_day(
    initial_location_state = new_patch_location_state("forage"),
    landscape = landscape,
    itinerary = new_prescribed_patch_itinerary(
      fixture$hour_of_day,
      itinerary
    ),
    initial_gut_state = fixture$opening_gut,
    initial_body_state = fixture$opening_body,
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    appetite_parameters = fixture$appetite,
    appetite_reference_schedule = fixture$appetite_reference,
    routine_activity_schedule = fixture$activity
  )
  water <- run_spatial_body_water_day(
    initial_state = new_body_water_state(26),
    parameters = new_body_water_parameters(28, 24, 1.56 / 24),
    patch_water_properties = new_patch_water_properties(
      c("forage", "water"),
      c(3.28, 0),
      c(0, 10)
    ),
    spatial_energy_hourly = energy$hourly
  )

  drinking_rows <- which(water$hourly$realized_drinking_water_kg > 0)
  expect_length(drinking_rows, 1L)
  expect_identical(water$hourly$opening_patch_id[drinking_rows], "water")
  expect_identical(water$hourly$spatial_action[drinking_rows], "stay")
  expect_equal(
    water$daily$total_food_derived_water_kg,
    energy$daily$realized_dry_matter_intake_kg_dm * 3.28
  )
  expect_true(water$daily$total_realized_drinking_water_kg > 0)
  expect_true(abs(water$daily$body_water_balance_residual_kg) < 1e-12)
})

test_that("movement cannot collect water and patch properties are complete", {
  hourly <- data.frame(
    hour_of_day = 0:23,
    opening_patch_id = rep("water", 24L),
    spatial_action = c("move", rep("stay", 23L)),
    realized_dry_matter_intake_kg_dm_h = rep(0, 24L)
  )
  result <- run_spatial_body_water_day(
    new_body_water_state(27),
    new_body_water_parameters(28, 24, 0),
    new_patch_water_properties("water", 0, 1),
    hourly
  )
  expect_equal(result$hourly$realized_drinking_water_kg[[1L]], 0)
  expect_equal(result$hourly$realized_drinking_water_kg[[2L]], 1)

  hourly$opening_patch_id[[24L]] <- "undeclared"
  expect_error(
    run_spatial_body_water_day(
      new_body_water_state(27),
      new_body_water_parameters(28, 24, 0),
      new_patch_water_properties("water", 0, 1),
      hourly
    ),
    "declared water properties"
  )
})
