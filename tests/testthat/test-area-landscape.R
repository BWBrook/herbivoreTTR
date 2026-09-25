area_test_landscape <- function(
  x_m = c(20, 180),
  y_m = c(20, 180),
  area_ha = c(1, 1),
  residual_kg_dm_ha = c(20, 20),
  boundary = "bounded"
) {
  new_area_landscape(
    data.frame(
      patch_id = c("a", "b"),
      x_m = x_m,
      y_m = y_m,
      area_ha = area_ha,
      residual_kg_dm_ha = residual_kg_dm_ha,
      stringsAsFactors = FALSE
    ),
    domain_width_m = 200,
    domain_height_m = 200,
    boundary = boundary
  )
}

test_that("area landscapes are exact plain records", {
  landscape <- area_test_landscape()

  expect_identical(
    names(landscape),
    c("patches", "domain_width_m", "domain_height_m", "boundary")
  )
  expect_identical(
    names(landscape$patches),
    c("patch_id", "x_m", "y_m", "area_ha", "residual_kg_dm_ha")
  )
  expect_identical(landscape$patches$patch_id, c("a", "b"))
  expect_identical(landscape$domain_width_m, 200)
  expect_identical(landscape$domain_height_m, 200)
  expect_identical(landscape$boundary, "bounded")
})

test_that("area landscape validation rejects malformed dimensions and patches", {
  valid <- data.frame(
    patch_id = c("a", "b"),
    x_m = c(1, 9),
    y_m = c(1, 9),
    area_ha = c(1, 1),
    residual_kg_dm_ha = c(20, 20),
    stringsAsFactors = FALSE
  )

  expect_error(
    new_area_landscape(valid[, c("patch_id", "x_m", "y_m", "area_ha")], 10, 10, "bounded"),
    "containing only"
  )
  expect_error(
    new_area_landscape(valid, 0, 10, "bounded"),
    "strictly positive"
  )
  expect_error(
    new_area_landscape(valid, 10, 10, "open"),
    "periodic.*bounded"
  )
  expect_error(
    new_area_landscape(
      transform(valid, x_m = 10),
      10,
      10,
      "bounded"
    ),
    "strictly below"
  )
  expect_error(
    new_area_landscape(
      transform(valid, area_ha = c(0, 1)),
      10,
      10,
      "bounded"
    ),
    "strictly positive"
  )
  expect_error(
    new_area_landscape(
      transform(valid, area_ha = c(1, 1.1)),
      10,
      10,
      "bounded"
    ),
    "Total",
    fixed = TRUE
  )
  expect_error(
    new_area_landscape(
      transform(valid, patch_id = c("a", "a")),
      10,
      10,
      "bounded"
    ),
    "unique"
  )
})

test_that("bounded and periodic distances use the declared geometry", {
  bounded <- area_test_landscape()
  periodic <- area_test_landscape(boundary = "periodic")

  expect_equal(landscape_distance_m(bounded, "a", "b"), sqrt(51200))
  expect_equal(landscape_distance_m(periodic, "a", "b"), sqrt(3200))
  expect_identical(landscape_distance_m(periodic, "a", "a"), 0)
  expect_error(
    landscape_distance_m(bounded, "missing", "a"),
    "present"
  )
  expect_error(
    landscape_distance_m(bounded, c("a", "b"), "a"),
    "one identifier"
  )
})

test_that("area forage removal converts density to mass and stops at residual", {
  landscape <- area_test_landscape(area_ha = c(2, 1))
  biomass <- c(100, 80)
  result <- remove_area_forage(biomass, landscape, "a", 120)

  expect_equal(result$fluxes$requested_intake_kg_dm, 120)
  expect_equal(result$fluxes$realized_intake_kg_dm, 120)
  expect_equal(result$fluxes$removal_kg_dm, c(120, 0))
  expect_equal(result$fluxes$balance_residual_kg_dm, 0)
  expect_equal(result$state, c(40, 80))
  expect_equal(biomass, c(100, 80))

  capped <- remove_area_forage(biomass, landscape, "a", 1000)
  expect_equal(capped$fluxes$realized_intake_kg_dm, 160)
  expect_equal(capped$fluxes$removal_kg_dm, c(160, 0))
  expect_equal(capped$fluxes$balance_residual_kg_dm, 0)
  expect_equal(capped$state, c(20, 80))

  below_residual <- remove_area_forage(c(10, 80), landscape, "a", 10)
  expect_equal(below_residual$fluxes$realized_intake_kg_dm, 0)
  expect_equal(below_residual$fluxes$balance_residual_kg_dm, 0)
  expect_equal(below_residual$state, c(10, 80))
})

test_that("same-density support scales stock by area without a density multiplier", {
  one_hectare <- area_test_landscape(area_ha = c(1, 1))
  two_hectare <- area_test_landscape(area_ha = c(2, 1))

  one <- remove_area_forage(c(100, 100), one_hectare, "a", 80)
  two <- remove_area_forage(c(100, 100), two_hectare, "a", 160)

  expect_equal(one$fluxes$realized_intake_kg_dm * 2,
               two$fluxes$realized_intake_kg_dm)
  expect_equal(one$state[[1L]], two$state[[1L]])
  expect_equal(one$fluxes$removal_kg_dm[[2L]], 0)
})

test_that("area forage removal validates inputs and is repeatable", {
  landscape <- area_test_landscape()
  expect_error(
    remove_area_forage(c(100), landscape, "a", 1),
    "per landscape patch"
  )
  expect_error(
    remove_area_forage(c(100, -1), landscape, "a", 1),
    "non-negative"
  )
  expect_error(
    remove_area_forage(c(100, 100), landscape, "missing", 1),
    "present"
  )
  expect_error(
    remove_area_forage(c(100, 100), landscape, "a", -1),
    "non-negative"
  )

  first <- remove_area_forage(c(100, 100), landscape, "a", 30)
  second <- remove_area_forage(c(100, 100), landscape, "a", 30)
  expect_identical(first, second)
  expect_identical(landscape$patches$area_ha, c(1, 1))
})
