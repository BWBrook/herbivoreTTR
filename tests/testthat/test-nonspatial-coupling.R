periodic_coupled_forage_opening <- function(
  equilibrium_biomass_kg_dm_ha,
  turnover_fraction_h,
  herbivore_density_animals_ha,
  realized_intake_kg_dm_h
) {
  retention <- 1 - turnover_fraction_h
  hourly_increment <-
    turnover_fraction_h * equilibrium_biomass_kg_dm_ha -
      herbivore_density_animals_ha * realized_intake_kg_dm_h

  sum(retention^(23:0) * hourly_increment) /
    (1 - retention^24)
}

run_coupled_test_days <- function(
  fixture,
  initial_forage_biomass_kg_dm_ha,
  coupling_parameters,
  forage = fixture$forage,
  days = 1L
) {
  run_nonspatial_coupled_energy_days(
    initial_gut_state = fixture$opening_gut,
    initial_body_state = fixture$opening_body,
    initial_forage_state = new_forage_biomass_state(
      initial_forage_biomass_kg_dm_ha
    ),
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    food_parameters = fixture$food,
    appetite_parameters = fixture$appetite,
    forage_turnover_parameters = new_forage_turnover_parameters(
      1000,
      0.001
    ),
    coupling_parameters = coupling_parameters,
    appetite_reference_schedule = fixture$appetite_reference,
    forage_acquisition_ceiling_schedule = forage,
    routine_activity_schedule = fixture$activity,
    number_of_days = days
  )
}

test_that("coupling parameters declare a positive per-hectare animal load", {
  parameters <- new_nonspatial_coupling_parameters(10, 500)

  expect_identical(parameters, list(
    herbivore_density_animals_ha = 10,
    residual_unavailable_forage_threshold_kg_dm_ha = 500
  ))
  expect_error(
    new_nonspatial_coupling_parameters(0, 500),
    "strictly positive"
  )
  expect_error(
    new_nonspatial_coupling_parameters(10, -1),
    "non-negative"
  )
})

test_that("removal-only scaling conserves dry matter exactly", {
  parameters <- new_nonspatial_coupling_parameters(10, 500)
  result <- step_forage_herbivory(
    new_forage_biomass_state(1000),
    parameters,
    0.02
  )

  expect_equal(result$fluxes$accessible_forage_biomass_kg_dm_ha, 500)
  expect_equal(result$fluxes$accessible_forage_per_animal_kg_dm, 50)
  expect_false(result$fluxes$forage_stock_ceiling_active)
  expect_equal(result$fluxes$realized_dry_matter_intake_kg_dm, 0.02)
  expect_equal(result$fluxes$herbivory_removal_kg_dm_ha, 0.2)
  expect_equal(result$state$forage_biomass_kg_dm_ha, 999.8)
  expect_equal(
    result$fluxes$forage_herbivory_balance_residual_kg_dm_ha,
    0
  )
  expect_equal(
    result$fluxes$herbivore_forage_coupling_residual_kg_dm_ha,
    0
  )
})

test_that("accessible stock caps intake without removing the residual", {
  parameters <- new_nonspatial_coupling_parameters(10, 500)
  binding <- step_forage_herbivory(
    new_forage_biomass_state(500.1),
    parameters,
    0.02
  )
  below <- step_forage_herbivory(
    new_forage_biomass_state(400),
    parameters,
    0.02
  )

  expect_true(binding$fluxes$forage_stock_ceiling_active)
  expect_equal(
    binding$fluxes$realized_dry_matter_intake_kg_dm,
    0.01
  )
  expect_equal(binding$fluxes$herbivory_removal_kg_dm_ha, 0.1)
  expect_equal(binding$state$forage_biomass_kg_dm_ha, 500)
  expect_true(below$fluxes$forage_stock_ceiling_active)
  expect_equal(below$fluxes$realized_dry_matter_intake_kg_dm, 0)
  expect_equal(below$state$forage_biomass_kg_dm_ha, 400)
  expect_error(
    step_forage_herbivory(
      new_forage_biomass_state(1000),
      parameters,
      -0.01
    ),
    "non-negative"
  )
})

test_that("zero intake reduces exactly to standalone forage turnover", {
  fixture <- core_test_fixture()
  coupling <- new_nonspatial_coupling_parameters(10, 500)
  closed <- new_forage_acquisition_ceiling_schedule(
    fixture$hour_of_day,
    rep(0, 24L)
  )
  coupled <- run_coupled_test_days(
    fixture,
    initial_forage_biomass_kg_dm_ha = 750,
    coupling_parameters = coupling,
    forage = closed,
    days = 2L
  )
  standalone <- run_forage_turnover_days(
    new_forage_biomass_state(750),
    new_forage_turnover_parameters(1000, 0.001),
    2L
  )

  expect_equal(
    coupled$hourly$forage_biomass_end_kg_dm_ha,
    standalone$hourly$forage_biomass_end_kg_dm_ha
  )
  expect_equal(coupled$daily$total_herbivory_removal_kg_dm_ha, c(0, 0))
  expect_equal(coupled$daily$forage_stock_ceiling_active_hours, c(0L, 0L))
})

test_that("constant coupled reference repeats over consecutive days", {
  fixture <- core_test_fixture()
  density <- 10
  coupling <- new_nonspatial_coupling_parameters(density, 500)
  periodic_opening <- periodic_coupled_forage_opening(
    equilibrium_biomass_kg_dm_ha = 1000,
    turnover_fraction_h = 0.001,
    herbivore_density_animals_ha = density,
    realized_intake_kg_dm_h = fixture$reference_rate
  )
  result <- run_coupled_test_days(
    fixture,
    initial_forage_biomass_kg_dm_ha = periodic_opening,
    coupling_parameters = coupling,
    days = 2L
  )
  day_1 <- result$hourly[result$hourly$simulation_day == 1L, ]
  day_2 <- result$hourly[result$hourly$simulation_day == 2L, ]

  expect_equal(
    day_1$forage_biomass_start_kg_dm_ha,
    day_2$forage_biomass_start_kg_dm_ha,
    tolerance = 1e-10
  )
  expect_equal(
    result$daily$forage_biomass_initial_kg_dm_ha,
    result$daily$forage_biomass_final_kg_dm_ha,
    tolerance = 1e-10
  )
  expect_equal(
    result$daily$realized_dry_matter_intake_kg_dm,
    c(0.32, 0.32)
  )
  expect_equal(result$daily$total_herbivory_removal_kg_dm_ha, c(3.2, 3.2))
  expect_equal(
    result$daily$observed_total_system_energy_change_kj,
    c(0, 0),
    tolerance = 1e-8
  )
  expect_identical(result$daily$body_energy_status, c("neutral", "neutral"))
  expect_equal(result$daily$forage_stock_ceiling_active_hours, c(0L, 0L))
  expect_equal(
    mean(day_1$forage_biomass_start_kg_dm_ha),
    1000 - 3.2 / (24 * 0.001),
    tolerance = 1e-10
  )
  expect_true(
    max(abs(result$hourly$forage_biomass_balance_residual_kg_dm_ha)) <
      1e-10
  )
  expect_true(
    max(abs(result$hourly$herbivore_forage_coupling_residual_kg_dm_ha)) <
      1e-10
  )
  expect_true(
    max(abs(result$hourly$system_energy_balance_residual_kj)) < 1e-8
  )
})
