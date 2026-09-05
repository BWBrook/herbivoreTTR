test_landscape <- function(
  forage_acquisition_ceiling_kg_dm_h = c(0.025, 0.025),
  metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
) {
  new_known_route_landscape(
    patch_id = c("patch_a", "patch_b"),
    forage_acquisition_ceiling_kg_dm_h =
      forage_acquisition_ceiling_kg_dm_h,
    route_origin_patch_id = c("patch_a", "patch_b"),
    route_destination_patch_id = c("patch_b", "patch_a"),
    incremental_movement_expenditure_kj = c(100, 100),
    metabolizable_energy_density_kj_kg_dm =
      metabolizable_energy_density_kj_kg_dm
  )
}

test_spatial_day <- function(
  fixture,
  closing_patch_id,
  landscape = test_landscape(),
  initial_patch_id = "patch_a"
) {
  run_prescribed_spatial_energy_day(
    initial_location_state = new_patch_location_state(initial_patch_id),
    landscape = landscape,
    itinerary = new_prescribed_patch_itinerary(
      fixture$hour_of_day,
      closing_patch_id
    ),
    initial_gut_state = fixture$opening_gut,
    initial_body_state = fixture$opening_body,
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    appetite_parameters = fixture$appetite,
    appetite_reference_schedule = fixture$appetite_reference,
    routine_activity_schedule = fixture$activity
  )
}

test_that("prescribed itineraries are canonical closing-boundary records", {
  itinerary <- new_prescribed_patch_itinerary(0:23, rep("patch_a", 24L))

  expect_identical(
    names(itinerary),
    c("hour_of_day", "prescribed_closing_patch_id")
  )
  expect_identical(itinerary$hour_of_day, 0:23)
  expect_identical(
    itinerary$prescribed_closing_patch_id,
    rep("patch_a", 24L)
  )

  expect_error(
    new_prescribed_patch_itinerary(1:24, rep("patch_a", 24L)),
    "0:23"
  )
  expect_error(
    new_prescribed_patch_itinerary(0:23, rep("", 24L)),
    "non-empty"
  )
  expect_error(
    new_prescribed_patch_itinerary(0:23, rep("patch_a", 23L)),
    "at least 24"
  )
})

test_that("an all-stay itinerary uses its patch food-energy density", {
  fixture <- core_test_fixture()
  landscape <- test_landscape(
    metabolizable_energy_density_kj_kg_dm = c(10000, 8000)
  )
  adequate <- test_spatial_day(
    fixture,
    rep("patch_a", 24L),
    landscape,
    "patch_a"
  )
  lower <- test_spatial_day(
    fixture,
    rep("patch_b", 24L),
    landscape,
    "patch_b"
  )
  lower_reference <- run_core_test_days(
    fixture,
    food = new_food_energy_parameters(8000)
  )

  expect_identical(
    lower$hourly[names(lower_reference$hourly)],
    lower_reference$hourly
  )
  expect_identical(
    lower$daily[names(lower_reference$daily)],
    lower_reference$daily
  )
  expect_identical(
    adequate$hourly$metabolizable_energy_density_kj_kg_dm,
    rep(10000, 24L)
  )
  expect_identical(
    lower$hourly$metabolizable_energy_density_kj_kg_dm,
    rep(8000, 24L)
  )
  expect_identical(
    c(adequate$daily$movement_hours, lower$daily$movement_hours),
    c(0L, 0L)
  )
})

test_that("an all-stay itinerary reduces exactly to the appetite reference", {
  fixture <- core_test_fixture()
  reference <- run_core_test_days(fixture)
  spatial <- test_spatial_day(fixture, rep("patch_a", 24L))

  expect_identical(
    spatial$hourly[names(reference$hourly)],
    reference$hourly
  )
  expect_identical(
    spatial$daily[names(reference$daily)],
    reference$daily
  )
  expect_true(all(spatial$hourly$spatial_action == "stay"))
  expect_true(all(spatial$hourly$opening_patch_id == "patch_a"))
  expect_true(all(spatial$hourly$closing_patch_id == "patch_a"))
  expect_identical(spatial$daily$movement_hours, 0L)
  expect_identical(spatial$daily$total_travel_duration_h, 0)
  expect_identical(spatial$daily$feeding_time_lost_h, 0)
  expect_identical(
    spatial$daily$total_incremental_movement_expenditure_kj,
    0
  )
})

test_that("spatial days reject a reference above the declared intake maximum", {
  fixture <- core_test_fixture()
  fixture$appetite$maximum_dry_matter_intake_kg_dm_h <- 0.015

  expect_error(
    test_spatial_day(fixture, rep("patch_a", 24L)),
    "must not exceed the declared maximum intake rate"
  )
})

test_that("a prescribed round trip separates travel from feeding time lost", {
  fixture <- core_test_fixture()
  closing_patch_id <- rep("patch_a", 24L)
  closing_patch_id[fixture$hour_of_day %in% 8:15] <- "patch_b"
  result <- test_spatial_day(fixture, closing_patch_id)
  moving <- result$hourly$spatial_action == "move"

  expect_identical(result$hourly$hour_of_day[moving], c(8L, 16L))
  expect_identical(
    result$hourly$opening_patch_id[moving],
    c("patch_a", "patch_b")
  )
  expect_identical(
    result$hourly$closing_patch_id[moving],
    c("patch_b", "patch_a")
  )
  expect_identical(result$hourly$closing_patch_id, closing_patch_id)
  expect_identical(
    result$hourly$feeding_time_lost_h[moving],
    c(0, 1)
  )
  expect_true(all(result$hourly$feeding_suspended_during_travel[moving]))
  expect_identical(result$daily$initial_patch_id, "patch_a")
  expect_identical(result$daily$final_patch_id, "patch_a")
  expect_identical(result$daily$movement_hours, 2L)
  expect_identical(result$daily$total_travel_duration_h, 2)
  expect_identical(result$daily$feeding_time_lost_h, 1)
  expect_identical(
    result$daily$total_baseline_routine_activity_expenditure_kj,
    800
  )
  expect_identical(
    result$daily$total_incremental_movement_expenditure_kj,
    200
  )
  expect_identical(
    result$daily$total_prescribed_routine_activity_expenditure_kj,
    1000
  )
  expect_true(test_near(
    result$daily$realized_dry_matter_intake_kg_dm,
    0.3134940654218749
  ))
  expect_true(test_near(
    result$daily$observed_total_system_energy_change_kj,
    -265.05934578125
  ))
  expect_true(max(abs(result$hourly$system_energy_balance_residual_kj)) < 1e-9)
  expect_true(abs(result$daily$system_energy_balance_residual_kj) < 1e-9)
})

test_that("static patch capacity exposes feeding-window order", {
  fixture <- core_test_fixture()
  landscape <- new_known_route_landscape(
    patch_id = c("limited_patch", "adequate_patch"),
    forage_acquisition_ceiling_kg_dm_h = c(0.015, 0.025),
    route_origin_patch_id = c("limited_patch", "adequate_patch"),
    route_destination_patch_id = c("adequate_patch", "limited_patch"),
    incremental_movement_expenditure_kj = c(100, 100),
    metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
  )
  run_order <- function(initial_patch_id, destination_patch_id) {
    closing_patch_id <- rep(initial_patch_id, 24L)
    closing_patch_id[fixture$hour_of_day >= 16L] <- destination_patch_id
    test_spatial_day(
      fixture,
      closing_patch_id,
      landscape,
      initial_patch_id
    )
  }
  cases <- list(
    limited_to_adequate = run_order("limited_patch", "adequate_patch"),
    adequate_to_limited = run_order("adequate_patch", "limited_patch")
  )

  for (result in cases) {
    moving <- result$hourly$spatial_action == "move"
    expect_identical(result$hourly$hour_of_day[moving], 16L)
    expect_identical(
      result$hourly$forage_acquisition_ceiling_kg_dm_h[moving],
      0
    )
    expect_identical(
      result$hourly$forage_acquisition_ceiling_kg_dm_h[!moving],
      result$hourly$
        opening_patch_forage_acquisition_ceiling_kg_dm_h[!moving]
    )
    expect_identical(result$daily$movement_hours, 1L)
    expect_identical(result$daily$total_travel_duration_h, 1)
    expect_identical(result$daily$feeding_time_lost_h, 1)
    expect_identical(
      result$daily$total_incremental_movement_expenditure_kj,
      100
    )
    expect_identical(
      result$daily$total_prescribed_routine_activity_expenditure_kj,
      900
    )
    expect_true(max(abs(result$hourly$system_energy_balance_residual_kj)) < 1e-9)
    expect_true(abs(result$daily$system_energy_balance_residual_kj) < 1e-9)
  }

  expect_identical(
    cases$limited_to_adequate$hourly$
      opening_patch_forage_acquisition_ceiling_kg_dm_h[1:8],
    rep(0.015, 8L)
  )
  expect_identical(
    cases$limited_to_adequate$hourly$
      opening_patch_forage_acquisition_ceiling_kg_dm_h[18:24],
    rep(0.025, 7L)
  )
  expect_identical(
    cases$adequate_to_limited$hourly$
      opening_patch_forage_acquisition_ceiling_kg_dm_h[1:8],
    rep(0.025, 8L)
  )
  expect_identical(
    cases$adequate_to_limited$hourly$
      opening_patch_forage_acquisition_ceiling_kg_dm_h[18:24],
    rep(0.015, 7L)
  )
  expect_gt(
    cases$limited_to_adequate$daily$realized_dry_matter_intake_kg_dm,
    cases$adequate_to_limited$daily$realized_dry_matter_intake_kg_dm
  )
  expect_true(test_near(
    cases$limited_to_adequate$daily$realized_dry_matter_intake_kg_dm,
    0.2819046613644086
  ))
  expect_true(test_near(
    cases$limited_to_adequate$daily$observed_total_system_energy_change_kj,
    -480.953386355914
  ))
  expect_true(test_near(
    cases$adequate_to_limited$daily$realized_dry_matter_intake_kg_dm,
    0.265
  ))
  expect_true(test_near(
    cases$adequate_to_limited$daily$observed_total_system_energy_change_kj,
    -650
  ))
})

test_that("spatial days reject unknown locations and impossible switches", {
  fixture <- core_test_fixture()
  itinerary <- new_prescribed_patch_itinerary(0:23, rep("patch_a", 24L))
  arguments <- list(
    initial_location_state = new_patch_location_state("patch_a"),
    landscape = test_landscape(),
    itinerary = itinerary,
    initial_gut_state = fixture$opening_gut,
    initial_body_state = fixture$opening_body,
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    appetite_parameters = fixture$appetite,
    appetite_reference_schedule = fixture$appetite_reference,
    routine_activity_schedule = fixture$activity
  )

  unknown_initial <- arguments
  unknown_initial$initial_location_state <- new_patch_location_state("missing")
  expect_error(
    do.call(run_prescribed_spatial_energy_day, unknown_initial),
    "initial location"
  )

  unknown_itinerary <- arguments
  unknown_itinerary$itinerary <- new_prescribed_patch_itinerary(
    0:23,
    c(rep("patch_a", 23L), "missing")
  )
  expect_error(
    do.call(run_prescribed_spatial_energy_day, unknown_itinerary),
    "Every prescribed closing patch"
  )

  one_way <- arguments
  one_way$landscape <- new_known_route_landscape(
    c("patch_a", "patch_b"),
    c(0.025, 0.025),
    "patch_a",
    "patch_b",
    100,
    c(10000, 10000)
  )
  one_way$itinerary <- new_prescribed_patch_itinerary(
    0:23,
    c(rep("patch_b", 12L), rep("patch_a", 12L))
  )
  expect_error(
    do.call(run_prescribed_spatial_energy_day, one_way),
    "No unique known route"
  )
})
