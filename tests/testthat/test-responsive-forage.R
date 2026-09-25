test_that("responsive forage is stationary at its positive equilibrium", {
  result <- step_responsive_forage(
    biomass_kg_dm_ha = 1000,
    production_saturation_biomass_kg_dm_ha = 2000,
    growth_rate_h = 0.002,
    senescence_rate_h = 0.001
  )

  expect_identical(result$state, 1000)
  expect_equal(result$fluxes$growth_kg_dm_ha, 1)
  expect_equal(result$fluxes$senescence_kg_dm_ha, 1)
  expect_identical(result$fluxes$balance_residual_kg_dm_ha, 0)
})

test_that("drought is exponential senescence and zero biomass is absorbing", {
  drought <- step_responsive_forage(
    biomass_kg_dm_ha = 1000,
    production_saturation_biomass_kg_dm_ha = 2000,
    growth_rate_h = 0,
    senescence_rate_h = 0.001,
    duration_h = 0.5
  )
  expected_biomass <- 1000 * exp(-0.001 * 0.5)

  expect_equal(drought$state, expected_biomass)
  expect_equal(
    drought$fluxes$senescence_kg_dm_ha,
    1000 - expected_biomass
  )
  expect_equal(drought$fluxes$growth_kg_dm_ha, 0, tolerance = 1e-12)

  zero <- step_responsive_forage(
    biomass_kg_dm_ha = c(0, 0),
    production_saturation_biomass_kg_dm_ha = c(1, 2000),
    growth_rate_h = 0.002,
    senescence_rate_h = 0.001,
    growth_multiplier = c(0, 1)
  )
  expect_identical(zero$state, c(0, 0))
  expect_identical(zero$fluxes$growth_kg_dm_ha, c(0, 0))
  expect_identical(zero$fluxes$senescence_kg_dm_ha, c(0, 0))
})

test_that("positive growth recovers low biomass while zero stays at zero", {
  low <- step_responsive_forage(
    biomass_kg_dm_ha = c(100, 0),
    production_saturation_biomass_kg_dm_ha = c(1000, 1000),
    growth_rate_h = 0.002,
    senescence_rate_h = 0.001
  )

  expect_gt(low$state[[1L]], 100)
  expect_identical(low$state[[2L]], 0)
  expect_equal(low$fluxes$growth_kg_dm_ha[[2L]], 0)
})

test_that("stock-flow balance closes and semigroup composition is exact", {
  one_hour <- step_responsive_forage(
    biomass_kg_dm_ha = 700,
    production_saturation_biomass_kg_dm_ha = 2000,
    growth_rate_h = 0.002,
    senescence_rate_h = 0.001
  )
  half_hour <- step_responsive_forage(
    biomass_kg_dm_ha = 700,
    production_saturation_biomass_kg_dm_ha = 2000,
    growth_rate_h = 0.002,
    senescence_rate_h = 0.001,
    duration_h = 0.5
  )
  two_half_hours <- step_responsive_forage(
    biomass_kg_dm_ha = half_hour$state,
    production_saturation_biomass_kg_dm_ha = 2000,
    growth_rate_h = 0.002,
    senescence_rate_h = 0.001,
    duration_h = 0.5
  )

  expect_equal(two_half_hours$state, one_hour$state, tolerance = 1e-12)
  expect_equal(
    one_hour$fluxes$balance_residual_kg_dm_ha,
    0
  )
  expect_equal(
    two_half_hours$fluxes$balance_residual_kg_dm_ha,
    0
  )
  expect_equal(
    one_hour$state - 700,
    one_hour$fluxes$growth_kg_dm_ha -
      one_hour$fluxes$senescence_kg_dm_ha
  )
})

test_that("subdividing homogeneous area preserves weighted stock and flux", {
  biomass <- c(600, 600)
  area_ha <- c(2, 3)
  result <- step_responsive_forage(
    biomass_kg_dm_ha = biomass,
    production_saturation_biomass_kg_dm_ha = c(1800, 1800),
    growth_rate_h = 0.002,
    senescence_rate_h = 0.001
  )
  aggregate <- step_responsive_forage(
    biomass_kg_dm_ha = 600,
    production_saturation_biomass_kg_dm_ha = 1800,
    growth_rate_h = 0.002,
    senescence_rate_h = 0.001
  )

  expect_equal(
    sum(result$state * area_ha),
    aggregate$state * sum(area_ha)
  )
  expect_equal(
    sum(result$fluxes$growth_kg_dm_ha * area_ha),
    aggregate$fluxes$growth_kg_dm_ha * sum(area_ha)
  )
  expect_equal(
    sum(result$fluxes$senescence_kg_dm_ha * area_ha),
    aggregate$fluxes$senescence_kg_dm_ha * sum(area_ha)
  )
})

test_that("responsive forage validates vectors, rates, multiplier, and duration", {
  valid <- list(
    biomass_kg_dm_ha = 100,
    production_saturation_biomass_kg_dm_ha = 1000,
    growth_rate_h = 0.002,
    senescence_rate_h = 0.001
  )

  expect_error(
    do.call(step_responsive_forage, modifyList(valid, list(biomass_kg_dm_ha = c(100, 200)))),
    "production_saturation_biomass"
  )
  expect_error(
    do.call(step_responsive_forage, modifyList(valid, list(biomass_kg_dm_ha = 1100))),
    "at least as large"
  )
  expect_error(
    do.call(step_responsive_forage, modifyList(valid, list(production_saturation_biomass_kg_dm_ha = 0))),
    "strictly positive"
  )
  expect_error(
    do.call(step_responsive_forage, modifyList(valid, list(growth_rate_h = c(0, 0.1)))),
    "growth_rate_h"
  )
  expect_error(
    do.call(step_responsive_forage, modifyList(valid, list(senescence_rate_h = 1.1))),
    "senescence_rate_h"
  )
  expect_error(
    do.call(step_responsive_forage, modifyList(valid, list(growth_multiplier = c(1, 0.5, 0.2)))),
    "growth_multiplier"
  )
  expect_error(
    do.call(step_responsive_forage, modifyList(valid, list(growth_multiplier = NA_real_))),
    "growth_multiplier"
  )
  expect_error(
    do.call(step_responsive_forage, modifyList(valid, list(duration_h = 0))),
    "duration_h"
  )
  expect_error(
    do.call(step_responsive_forage, modifyList(valid, list(duration_h = 1.1))),
    "duration_h"
  )
  expect_error(
    do.call(step_responsive_forage, modifyList(valid, list(biomass_kg_dm_ha = NA_real_))),
    "biomass_kg_dm_ha"
  )
})

test_that("zero net relative growth has the rational decay limit", {
  result <- step_responsive_forage(1000, 2000, .001, .001)
  expect_equal(result$state, 1000 / (1 + .001 / 2000 * 1000))
  expect_equal(result$fluxes$senescence_kg_dm_ha,
    .001 * log1p(.001 / 2000 * 1000) / (.001 / 2000))
})

test_that("reduced production preserves integrated fluxes across half steps", {
  one <- step_responsive_forage(1000, 2000, .002, .001, .6)
  first <- step_responsive_forage(1000, 2000, .002, .001, .6, .5)
  second <- step_responsive_forage(first$state, 2000, .002, .001, .6, .5)
  expect_equal(one$fluxes$growth_kg_dm_ha,
    first$fluxes$growth_kg_dm_ha + second$fluxes$growth_kg_dm_ha,
    tolerance = 1e-10)
  expect_equal(one$fluxes$senescence_kg_dm_ha,
    first$fluxes$senescence_kg_dm_ha + second$fluxes$senescence_kg_dm_ha,
    tolerance = 1e-10)
})
