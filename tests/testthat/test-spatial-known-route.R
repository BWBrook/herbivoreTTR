test_that("known-route landscapes are plain directed records", {
  landscape <- new_known_route_landscape(
    patch_id = c("patch_a", "patch_b"),
    forage_acquisition_ceiling_kg_dm_h = c(0.025, 0.015),
    route_origin_patch_id = c("patch_a", "patch_b"),
    route_destination_patch_id = c("patch_b", "patch_a"),
    incremental_movement_expenditure_kj = c(100, 120),
    metabolizable_energy_density_kj_kg_dm = c(10000, 8000)
  )

  expect_identical(names(landscape), c("patches", "routes"))
  expect_identical(landscape$patches$patch_id, c("patch_a", "patch_b"))
  expect_identical(
    landscape$patches$forage_acquisition_ceiling_kg_dm_h,
    c(0.025, 0.015)
  )
  expect_identical(
    landscape$patches$metabolizable_energy_density_kj_kg_dm,
    c(10000, 8000)
  )
  expect_identical(
    landscape$routes$travel_duration_h,
    c(1, 1)
  )
  expect_identical(
    landscape$routes$incremental_movement_expenditure_kj,
    c(100, 120)
  )
  expect_identical(new_patch_location_state("patch_a"), list(
    patch_id = "patch_a"
  ))
})

test_that("landscape construction rejects inconsistent routes", {
  expect_error(
    new_known_route_landscape(
      c("patch_a", "patch_a"),
      c(0.025, 0.025),
      "patch_a",
      "patch_a",
      100,
      c(10000, 10000)
    ),
    "unique"
  )
  expect_error(
    new_known_route_landscape(
      c("patch_a", "patch_b"),
      c(0.025, 0.025),
      "patch_a",
      "patch_c",
      100,
      c(10000, 10000)
    ),
    "endpoint"
  )
  expect_error(
    new_known_route_landscape(
      c("patch_a", "patch_b"),
      c(0.025, 0.025),
      "patch_a",
      "patch_a",
      100,
      c(10000, 10000)
    ),
    "different patches"
  )
  expect_error(
    new_known_route_landscape(
      c("patch_a", "patch_b"),
      c(0.025, 0.025),
      c("patch_a", "patch_a"),
      c("patch_b", "patch_b"),
      c(100, 100),
      c(10000, 10000)
    ),
    "must be unique"
  )
  expect_error(
    new_known_route_landscape(
      c("patch_a", "patch_b"),
      c(0.025, 0.025),
      "patch_a",
      "patch_b",
      -1,
      c(10000, 10000)
    ),
    "non-negative"
  )
  expect_error(
    new_known_route_landscape(
      c("patch_a", "patch_b"),
      0.025,
      "patch_a",
      "patch_b",
      100,
      c(10000, 10000)
    ),
    "per patch"
  )
  expect_error(
    new_known_route_landscape(
      c("patch_a", "patch_b"),
      c(0.025, -0.001),
      "patch_a",
      "patch_b",
      100,
      c(10000, 10000)
    ),
    "non-negative"
  )
  expect_error(
    new_known_route_landscape(
      c("patch_a", "patch_b"),
      c(0.025, 0.025),
      "patch_a",
      "patch_b",
      100,
      10000
    ),
    "per patch"
  )
  expect_error(
    new_known_route_landscape(
      c("patch_a", "patch_b"),
      c(0.025, 0.025),
      "patch_a",
      "patch_b",
      100,
      c(10000, 0)
    ),
    "strictly positive"
  )
})

test_that("one-hour movement changes location and exposes both costs", {
  landscape <- new_known_route_landscape(
    patch_id = c("patch_a", "patch_b"),
    forage_acquisition_ceiling_kg_dm_h = c(0.025, 0.015),
    route_origin_patch_id = c("patch_a", "patch_b"),
    route_destination_patch_id = c("patch_b", "patch_a"),
    incremental_movement_expenditure_kj = c(100, 120),
    metabolizable_energy_density_kj_kg_dm = c(10000, 8000)
  )
  result <- step_known_route_movement(
    new_patch_location_state("patch_a"),
    landscape,
    "patch_b"
  )

  expect_identical(result$state, list(patch_id = "patch_b"))
  expect_identical(result$fluxes$origin_patch_id, "patch_a")
  expect_identical(result$fluxes$destination_patch_id, "patch_b")
  expect_identical(result$fluxes$travel_duration_h, 1)
  expect_true(result$fluxes$feeding_suspended_during_travel)
  expect_identical(
    result$fluxes$incremental_movement_expenditure_kj_h,
    100
  )
  expect_identical(
    result$fluxes$incremental_movement_expenditure_kj,
    100
  )

  expect_error(
    step_known_route_movement(
      new_patch_location_state("missing"),
      landscape,
      "patch_b"
    ),
    "opening location"
  )
  expect_error(
    step_known_route_movement(
      new_patch_location_state("patch_a"),
      landscape,
      "missing"
    ),
    "destination"
  )

  one_way <- new_known_route_landscape(
    c("patch_a", "patch_b"),
    c(0.025, 0.015),
    "patch_a",
    "patch_b",
    100,
    c(10000, 8000)
  )
  expect_error(
    step_known_route_movement(
      new_patch_location_state("patch_b"),
      one_way,
      "patch_a"
    ),
    "No unique known route"
  )

  invalid_duration <- landscape
  invalid_duration$routes$travel_duration_h[[1L]] <- 2
  expect_error(
    step_known_route_movement(
      new_patch_location_state("patch_a"),
      invalid_duration,
      "patch_b"
    ),
    "duration `1 h`"
  )
})
