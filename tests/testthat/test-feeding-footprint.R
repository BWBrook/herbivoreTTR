test_that("rectangle overlap returns partial, full, touching, and no overlap", {
  cells <- data.frame(
    xmin_m = c(0, 10, 30, 40),
    xmax_m = c(10, 20, 40, 50),
    ymin_m = c(0, 0, 0, 0),
    ymax_m = c(10, 10, 10, 10)
  )
  footprint <- c(xmin_m = 5, xmax_m = 35, ymin_m = 2, ymax_m = 8)

  expect_equal(
    rectangle_overlap_m2(cells, footprint),
    c(30, 60, 30, 0)
  )
})

test_that("rectangle overlap rejects malformed and overlapping cells", {
  valid_cells <- data.frame(
    xmin_m = c(0, 10), xmax_m = c(10, 20),
    ymin_m = c(0, 0), ymax_m = c(10, 10)
  )
  valid_footprint <- c(xmin_m = 0, xmax_m = 1, ymin_m = 0, ymax_m = 1)

  expect_error(
    rectangle_overlap_m2(valid_cells[1:3], valid_footprint),
    "only"
  )
  expect_error(
    rectangle_overlap_m2(
      transform(valid_cells, xmax_m = c(10, 9)),
      valid_footprint
    ),
    "strictly greater"
  )
  expect_error(
    rectangle_overlap_m2(
      data.frame(
        xmin_m = c(0, 5), xmax_m = c(10, 15),
        ymin_m = c(0, 1), ymax_m = c(10, 11)
      ),
      valid_footprint
    ),
    "positive area"
  )
  expect_error(
    rectangle_overlap_m2(valid_cells, c(xmin_m = 0, xmax_m = 1, ymin_m = 0)),
    "exactly"
  )
  expect_error(
    rectangle_overlap_m2(valid_cells, c(xmin_m = 1, xmax_m = 0, ymin_m = 0, ymax_m = 1)),
    "strictly greater"
  )
})

test_that("uniform-density subdivision preserves fixed-footprint grazing", {
  aggregate <- step_footprint_grazing(
    biomass_kg_dm_ha = 1000,
    cell_area_ha = 0.02,
    overlap_area_m2 = 200,
    requested_intake_kg_dm = 3,
    search_area_m2_h = 100,
    feeding_duration_h = 0.5
  )
  subdivided <- step_footprint_grazing(
    biomass_kg_dm_ha = c(1000, 1000),
    cell_area_ha = c(0.01, 0.01),
    overlap_area_m2 = c(100, 100),
    requested_intake_kg_dm = 3,
    search_area_m2_h = 100,
    feeding_duration_h = 0.5
  )

  expect_equal(subdivided$state[[1L]], aggregate$state)
  expect_equal(subdivided$state[[2L]], aggregate$state)
  expect_equal(
    sum(subdivided$fluxes$accessible_mass_kg_dm),
    aggregate$fluxes$accessible_mass_kg_dm
  )
  expect_equal(
    subdivided$fluxes$encounter_ceiling_kg_dm,
    aggregate$fluxes$encounter_ceiling_kg_dm
  )
  expect_equal(
    sum(subdivided$fluxes$removal_kg_dm),
    sum(aggregate$fluxes$removal_kg_dm)
  )
})

test_that("residual and search-duration rules bound encounter and removal", {
  no_residual <- step_footprint_grazing(
    biomass_kg_dm_ha = c(500, 1000),
    cell_area_ha = c(0.01, 0.01),
    overlap_area_m2 = c(100, 100),
    requested_intake_kg_dm = 100,
    search_area_m2_h = 100,
    feeding_duration_h = 0
  )
  half_hour <- step_footprint_grazing(
    biomass_kg_dm_ha = c(500, 1000),
    cell_area_ha = c(0.01, 0.01),
    overlap_area_m2 = c(100, 100),
    requested_intake_kg_dm = 100,
    search_area_m2_h = 100,
    feeding_duration_h = 0.5
  )
  residual <- step_footprint_grazing(
    biomass_kg_dm_ha = c(500, 1000),
    cell_area_ha = c(0.01, 0.01),
    overlap_area_m2 = c(100, 100),
    requested_intake_kg_dm = 100,
    search_area_m2_h = 100,
    feeding_duration_h = 1,
    residual_kg_dm_ha = 800
  )

  expect_equal(no_residual$fluxes$encounter_ceiling_kg_dm, 0)
  expect_equal(no_residual$fluxes$realized_intake_kg_dm, 0)
  expect_equal(no_residual$state, c(500, 1000))
  expect_equal(half_hour$fluxes$encounter_ceiling_kg_dm, 2.75)
  expect_equal(residual$fluxes$accessible_mass_kg_dm, c(0, 2))
  expect_equal(residual$fluxes$encounter_ceiling_kg_dm, 1)
  expect_equal(residual$state, c(500, 900))
})

test_that("requested intake is capped by encountered physical capacity", {
  result <- step_footprint_grazing(
    biomass_kg_dm_ha = c(500, 1000),
    cell_area_ha = c(0.01, 0.01),
    overlap_area_m2 = c(100, 100),
    requested_intake_kg_dm = 100,
    search_area_m2_h = 1000,
    feeding_duration_h = 1
  )

  expect_equal(result$fluxes$encounter_ceiling_kg_dm, 11)
  expect_equal(result$fluxes$realized_intake_kg_dm, 11)
  expect_equal(result$fluxes$removal_kg_dm, c(3, 8))
  expect_equal(result$state, c(200, 200))
  expect_equal(result$fluxes$balance_residual_kg_dm, 0)
})

test_that("footprint grazing validates physical vectors and remains pure", {
  valid <- list(
    biomass_kg_dm_ha = c(500, 1000),
    cell_area_ha = c(0.01, 0.01),
    overlap_area_m2 = c(100, 100),
    requested_intake_kg_dm = 1,
    search_area_m2_h = 100,
    feeding_duration_h = 1
  )
  expect_error(do.call(step_footprint_grazing, modifyList(valid, list(biomass_kg_dm_ha = c(1, 2, 3)))), "per biomass")
  expect_error(do.call(step_footprint_grazing, modifyList(valid, list(cell_area_ha = c(0, 0.01)))), "strictly positive")
  expect_error(do.call(step_footprint_grazing, modifyList(valid, list(overlap_area_m2 = c(101, 100)))), "not exceed")
  expect_error(do.call(step_footprint_grazing, modifyList(valid, list(requested_intake_kg_dm = -1))), "non-negative")
  expect_error(do.call(step_footprint_grazing, modifyList(valid, list(search_area_m2_h = 0))), "strictly positive")
  expect_error(do.call(step_footprint_grazing, modifyList(valid, list(feeding_duration_h = 1.1))), "duration")
  expect_error(do.call(step_footprint_grazing, modifyList(valid, list(residual_kg_dm_ha = -1))), "non-negative")
  expect_error(do.call(step_footprint_grazing, modifyList(valid, list(biomass_kg_dm_ha = NA_real_))), "non-negative")

  opening <- valid$biomass_kg_dm_ha
  first <- do.call(step_footprint_grazing, valid)
  second <- do.call(step_footprint_grazing, valid)
  expect_identical(opening, valid$biomass_kg_dm_ha)
  expect_identical(first, second)
  expect_identical(first$state, as.double(first$state))
  expect_identical(first$fluxes$removal_kg_dm, as.double(first$fluxes$removal_kg_dm))
})
