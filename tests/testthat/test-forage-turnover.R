test_that("turnover parameters declare a positive stable reference", {
  parameters <- new_forage_turnover_parameters(1000, 0.001)

  expect_identical(parameters, list(
    equilibrium_forage_biomass_kg_dm_ha = 1000,
    forage_turnover_fraction_h = 0.001
  ))
  expect_error(
    new_forage_turnover_parameters(0, 0.001),
    "strictly positive"
  )
  expect_error(new_forage_turnover_parameters(1000, 0), "finite value")
  expect_error(new_forage_turnover_parameters(1000, 1.01), "finite value")
})

test_that("turnover step is neutral at equilibrium and restorative around it", {
  parameters <- new_forage_turnover_parameters(1000, 0.001)
  equilibrium <- step_forage_turnover(
    new_forage_biomass_state(1000),
    parameters
  )
  low <- step_forage_turnover(new_forage_biomass_state(500), parameters)
  high <- step_forage_turnover(new_forage_biomass_state(1500), parameters)

  expect_equal(equilibrium$fluxes$forage_growth_kg_dm_ha_h, 1)
  expect_equal(equilibrium$fluxes$forage_background_loss_kg_dm_ha_h, 1)
  expect_equal(equilibrium$state$forage_biomass_kg_dm_ha, 1000)
  expect_equal(low$state$forage_biomass_kg_dm_ha, 500.5)
  expect_equal(high$state$forage_biomass_kg_dm_ha, 1499.5)
  expect_equal(
    low$state$forage_biomass_kg_dm_ha +
      high$state$forage_biomass_kg_dm_ha,
    2000
  )
  expect_equal(
    c(
      equilibrium$fluxes$forage_biomass_balance_residual_kg_dm_ha,
      low$fluxes$forage_biomass_balance_residual_kg_dm_ha,
      high$fluxes$forage_biomass_balance_residual_kg_dm_ha
    ),
    c(0, 0, 0)
  )
})

test_that("repeated turnover matches analytic monotonic recovery", {
  parameters <- new_forage_turnover_parameters(1000, 0.001)
  low <- run_forage_turnover_days(
    new_forage_biomass_state(500),
    parameters,
    180
  )
  equilibrium <- run_forage_turnover_days(
    new_forage_biomass_state(1000),
    parameters,
    180
  )
  high <- run_forage_turnover_days(
    new_forage_biomass_state(1500),
    parameters,
    180
  )
  hour <- seq_len(nrow(low$hourly))
  expected_low <- 1000 - 500 * 0.999^hour
  expected_high <- 1000 + 500 * 0.999^hour

  expect_equal(low$hourly$forage_biomass_end_kg_dm_ha, expected_low)
  expect_equal(high$hourly$forage_biomass_end_kg_dm_ha, expected_high)
  expect_true(all(diff(low$hourly$forage_biomass_end_kg_dm_ha) > 0))
  expect_true(all(diff(high$hourly$forage_biomass_end_kg_dm_ha) < 0))
  expect_lte(max(low$hourly$forage_biomass_end_kg_dm_ha), 1000)
  expect_gte(min(high$hourly$forage_biomass_end_kg_dm_ha), 1000)
  expect_equal(
    low$hourly$forage_biomass_end_kg_dm_ha +
      high$hourly$forage_biomass_end_kg_dm_ha,
    rep(2000, length(hour))
  )
  expect_equal(
    equilibrium$daily$forage_biomass_final_kg_dm_ha,
    rep(1000, 180L)
  )
  expect_equal(
    equilibrium$daily$total_forage_growth_kg_dm_ha,
    rep(24, 180L)
  )
  expect_equal(
    low$daily$forage_biomass_initial_kg_dm_ha[-1L],
    head(low$daily$forage_biomass_final_kg_dm_ha, -1L)
  )
  expect_true(
    max(abs(low$hourly$forage_biomass_balance_residual_kg_dm_ha)) < 1e-10
  )
  expect_true(
    max(abs(low$daily$forage_biomass_balance_residual_kg_dm_ha)) < 1e-10
  )
})
