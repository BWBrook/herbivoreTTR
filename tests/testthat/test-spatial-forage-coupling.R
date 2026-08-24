spatial_coupled_test_landscape <- function(
  route_cost_kj = 900,
  energy_density_kj_kg_dm = c(10000, 10000)
) {
  new_known_route_landscape(
    patch_id = c("patch_a", "patch_b"),
    forage_acquisition_ceiling_kg_dm_h = c(0.025, 0.025),
    route_origin_patch_id = c("patch_a", "patch_b"),
    route_destination_patch_id = c("patch_b", "patch_a"),
    incremental_movement_expenditure_kj = rep(route_cost_kj, 2L),
    metabolizable_energy_density_kj_kg_dm = energy_density_kj_kg_dm
  )
}

run_spatial_coupled_test_days <- function(
  fixture,
  number_of_days,
  closing_patch_id,
  initial_forage = c(1000, 1000),
  landscape = spatial_coupled_test_landscape()
) {
  location <- new_patch_location_state("patch_a")
  gut <- fixture$opening_gut
  body <- fixture$opening_body
  forage <- new_spatial_forage_biomass_state(
    c("patch_a", "patch_b"),
    initial_forage
  )
  results <- vector("list", number_of_days)

  for (simulation_day in seq_len(number_of_days)) {
    result <- run_prescribed_spatial_coupled_energy_day(
      initial_location_state = location,
      landscape = landscape,
      itinerary = new_prescribed_patch_itinerary(
        fixture$hour_of_day,
        closing_patch_id
      ),
      initial_gut_state = gut,
      initial_body_state = body,
      initial_spatial_forage_state = forage,
      gut_parameters = fixture$gut,
      body_parameters = fixture$body,
      appetite_parameters = fixture$appetite,
      forage_turnover_parameters = new_forage_turnover_parameters(1000, 0.001),
      coupling_parameters = new_nonspatial_coupling_parameters(10, 500),
      appetite_reference_schedule = fixture$appetite_reference,
      routine_activity_schedule = fixture$activity
    )
    result$hourly$simulation_day <- as.integer(simulation_day)
    result$hourly$time_start_h <-
      result$hourly$time_start_h + 24 * (simulation_day - 1L)
    result$hourly$time_end_h <-
      result$hourly$time_end_h + 24 * (simulation_day - 1L)
    result$daily$simulation_day <- as.integer(simulation_day)
    result$patch_hourly$simulation_day <- as.integer(simulation_day)
    result$patch_daily$simulation_day <- as.integer(simulation_day)
    results[[simulation_day]] <- result

    location <- result$final_state$location
    gut <- result$final_state$gut
    body <- result$final_state$body
    forage <- result$final_state$forage
  }

  list(
    hourly = do.call(rbind, lapply(results, `[[`, "hourly")),
    daily = do.call(rbind, lapply(results, `[[`, "daily")),
    patch_hourly = do.call(rbind, lapply(results, `[[`, "patch_hourly")),
    patch_daily = do.call(rbind, lapply(results, `[[`, "patch_daily")),
    final_state = results[[number_of_days]]$final_state
  )
}

test_that("spatial forage states are canonical dynamic patch records", {
  state <- new_spatial_forage_biomass_state(
    c("patch_b", "patch_a"),
    c(800, 1000)
  )

  expect_s3_class(state, "data.frame")
  expect_identical(
    names(state),
    c("patch_id", "forage_biomass_kg_dm_ha")
  )
  expect_identical(state$patch_id, c("patch_b", "patch_a"))
  expect_identical(state$forage_biomass_kg_dm_ha, c(800, 1000))
  expect_error(
    new_spatial_forage_biomass_state(c("patch_a", "patch_a"), c(1, 2)),
    "unique"
  )
  expect_error(
    new_spatial_forage_biomass_state(c("patch_a", "patch_b"), 1),
    "one finite"
  )
  expect_error(
    new_spatial_forage_biomass_state("patch_a", -1),
    "non-negative"
  )
})

test_that("all-stay spatial coupling reduces exactly to accepted models", {
  fixture <- core_test_fixture()
  coupling <- new_nonspatial_coupling_parameters(10, 500)
  turnover <- new_forage_turnover_parameters(1000, 0.001)
  spatial <- run_spatial_coupled_test_days(
    fixture,
    number_of_days = 2L,
    closing_patch_id = rep("patch_a", 24L)
  )
  nonspatial <- run_nonspatial_coupled_energy_days(
    initial_gut_state = fixture$opening_gut,
    initial_body_state = fixture$opening_body,
    initial_forage_state = new_forage_biomass_state(1000),
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    food_parameters = fixture$food,
    appetite_parameters = fixture$appetite,
    forage_turnover_parameters = turnover,
    coupling_parameters = coupling,
    appetite_reference_schedule = fixture$appetite_reference,
    forage_acquisition_ceiling_schedule = fixture$forage,
    routine_activity_schedule = fixture$activity,
    number_of_days = 2L
  )
  standalone <- run_forage_turnover_days(
    new_forage_biomass_state(1000),
    turnover,
    2L
  )

  row.names(spatial$hourly) <- NULL
  row.names(spatial$patch_hourly) <- NULL
  expect_identical(
    spatial$hourly[names(nonspatial$hourly)],
    nonspatial$hourly
  )

  occupied <- spatial$patch_hourly[
    spatial$patch_hourly$patch_id == "patch_a",
    ,
    drop = FALSE
  ]
  row.names(occupied) <- NULL
  occupied_fields <- c(
    "simulation_day",
    "hour_of_day",
    "forage_biomass_start_kg_dm_ha",
    "forage_growth_kg_dm_ha_h",
    "forage_background_loss_kg_dm_ha_h",
    "forage_growth_kg_dm_ha",
    "forage_background_loss_kg_dm_ha",
    "forage_biomass_before_herbivory_kg_dm_ha",
    "herbivory_removal_kg_dm_ha",
    "forage_biomass_end_kg_dm_ha",
    "forage_biomass_balance_residual_kg_dm_ha"
  )
  expect_identical(
    occupied[occupied_fields],
    nonspatial$hourly[occupied_fields]
  )

  unoccupied <- spatial$patch_hourly[
    spatial$patch_hourly$patch_id == "patch_b",
    ,
    drop = FALSE
  ]
  row.names(unoccupied) <- NULL
  turnover_fields <- c(
    "simulation_day",
    "hour_of_day",
    "forage_biomass_start_kg_dm_ha",
    "forage_growth_kg_dm_ha_h",
    "forage_background_loss_kg_dm_ha_h",
    "forage_growth_kg_dm_ha",
    "forage_background_loss_kg_dm_ha",
    "forage_biomass_end_kg_dm_ha",
    "forage_biomass_balance_residual_kg_dm_ha"
  )
  expect_identical(
    unoccupied[turnover_fields],
    standalone$hourly[turnover_fields]
  )
  expect_true(all(unoccupied$herbivory_removal_kg_dm_ha == 0))
})

test_that("spatial coupling uses the opening patch energy density", {
  fixture <- core_test_fixture()
  landscape <- spatial_coupled_test_landscape(
    energy_density_kj_kg_dm = c(8000, 10000)
  )
  spatial <- run_spatial_coupled_test_days(
    fixture,
    number_of_days = 1L,
    closing_patch_id = rep("patch_a", 24L),
    landscape = landscape
  )
  nonspatial <- run_nonspatial_coupled_energy_days(
    initial_gut_state = fixture$opening_gut,
    initial_body_state = fixture$opening_body,
    initial_forage_state = new_forage_biomass_state(1000),
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    food_parameters = new_food_energy_parameters(8000),
    appetite_parameters = fixture$appetite,
    forage_turnover_parameters = new_forage_turnover_parameters(1000, 0.001),
    coupling_parameters = new_nonspatial_coupling_parameters(10, 500),
    appetite_reference_schedule = fixture$appetite_reference,
    forage_acquisition_ceiling_schedule = fixture$forage,
    routine_activity_schedule = fixture$activity,
    number_of_days = 1L
  )

  row.names(spatial$hourly) <- NULL
  expect_identical(
    spatial$hourly[names(nonspatial$hourly)],
    nonspatial$hourly
  )
  expect_identical(
    spatial$hourly$metabolizable_energy_density_kj_kg_dm,
    rep(8000, 24L)
  )
})

test_that("herbivory is local, absent in transit, and fully conserved", {
  fixture <- core_test_fixture()
  closing_patch_id <- rep("patch_b", 24L)
  closing_patch_id[fixture$hour_of_day < 8L] <- "patch_a"
  result <- run_spatial_coupled_test_days(
    fixture,
    number_of_days = 1L,
    closing_patch_id = closing_patch_id
  )

  moving <- result$hourly$spatial_action == "move"
  expect_identical(result$hourly$hour_of_day[moving], 8L)
  expect_identical(result$daily$movement_hours, 1L)
  expect_identical(result$daily$total_incremental_movement_expenditure_kj, 900)
  expect_identical(result$daily$feeding_time_lost_h, 0)
  expect_true(all(result$hourly$realized_dry_matter_intake_kg_dm[moving] == 0))
  expect_true(all(
    result$patch_hourly$herbivory_removal_kg_dm_ha[
      result$patch_hourly$hour_of_day == 8L
    ] == 0
  ))
  expect_true(all(
    result$patch_hourly$herbivory_removal_kg_dm_ha[
      !result$patch_hourly$occupied_stay
    ] == 0
  ))

  removal_by_hour <- tapply(
    result$patch_hourly$herbivory_removal_kg_dm_ha,
    result$patch_hourly$hour_of_day,
    sum
  )
  expect_equal(
    as.vector(removal_by_hour),
    10 * result$hourly$realized_dry_matter_intake_kg_dm,
    tolerance = 1e-12
  )
  expect_lt(
    max(abs(result$patch_hourly$forage_biomass_balance_residual_kg_dm_ha)),
    1e-10
  )
  expect_lt(
    max(abs(result$patch_daily$forage_biomass_balance_residual_kg_dm_ha)),
    1e-10
  )
  expect_lt(max(abs(result$hourly$system_energy_balance_residual_kj)), 1e-8)
  expect_lt(abs(result$daily$system_energy_balance_residual_kj), 1e-8)
  expect_identical(result$final_state$location, new_patch_location_state("patch_b"))
  expect_identical(
    result$final_state$forage$patch_id,
    c("patch_a", "patch_b")
  )
  expect_equal(
    result$final_state$forage$forage_biomass_kg_dm_ha,
    result$patch_daily$forage_biomass_final_kg_dm_ha
  )
})

test_that("spatial coupling requires the exact landscape patch set", {
  fixture <- core_test_fixture()
  arguments <- list(
    initial_location_state = new_patch_location_state("patch_a"),
    landscape = spatial_coupled_test_landscape(),
    itinerary = new_prescribed_patch_itinerary(0:23, rep("patch_a", 24L)),
    initial_gut_state = fixture$opening_gut,
    initial_body_state = fixture$opening_body,
    initial_spatial_forage_state = new_spatial_forage_biomass_state(
      "patch_a",
      1000
    ),
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    appetite_parameters = fixture$appetite,
    forage_turnover_parameters = new_forage_turnover_parameters(1000, 0.001),
    coupling_parameters = new_nonspatial_coupling_parameters(10, 500),
    appetite_reference_schedule = fixture$appetite_reference,
    routine_activity_schedule = fixture$activity
  )

  expect_error(
    do.call(run_prescribed_spatial_coupled_energy_day, arguments),
    "exactly the landscape patch set"
  )

  arguments$initial_spatial_forage_state <-
    new_spatial_forage_biomass_state(
      c("patch_b", "patch_a"),
      c(1000, 1000)
    )
  result <- do.call(run_prescribed_spatial_coupled_energy_day, arguments)
  expect_identical(
    result$final_state$forage$patch_id,
    c("patch_a", "patch_b")
  )
})
