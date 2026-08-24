choice_test_landscape <- function(
  capacities = c(limited_patch = 0.015, adequate_patch = 0.025),
  movement_cost_kj = 100,
  energy_densities = rep(10000, length(capacities))
) {
  new_known_route_landscape(
    patch_id = names(capacities),
    forage_acquisition_ceiling_kg_dm_h = unname(capacities),
    route_origin_patch_id = rev(names(capacities)),
    route_destination_patch_id = names(capacities),
    incremental_movement_expenditure_kj = rep(movement_cost_kj, 2L),
    metabolizable_energy_density_kj_kg_dm = energy_densities
  )
}

test_that("known-patch choice scores a fixed remaining feeding bout", {
  landscape <- choice_test_landscape()

  limited <- choose_known_patch_for_feeding_bout(
    new_patch_location_state("limited_patch"),
    landscape,
    "adequate_patch",
    expected_dry_matter_demand_kg_dm_h = 0.020,
    remaining_feeding_opportunity_h = 8
  )
  adequate <- choose_known_patch_for_feeding_bout(
    new_patch_location_state("adequate_patch"),
    landscape,
    "limited_patch",
    expected_dry_matter_demand_kg_dm_h = 0.020,
    remaining_feeding_opportunity_h = 8
  )

  expect_true(test_near(limited$stay_expected_dry_matter_intake_kg_dm, 0.12))
  expect_true(test_near(limited$move_expected_dry_matter_intake_kg_dm, 0.14))
  expect_true(test_near(limited$stay_feeding_bout_score_kj, 1200))
  expect_true(test_near(limited$move_feeding_bout_score_kj, 1300))
  expect_true(test_near(limited$move_score_advantage_kj, 100))
  expect_identical(limited$selected_action, "move")
  expect_identical(limited$selected_patch_id, "adequate_patch")

  expect_true(test_near(adequate$stay_expected_dry_matter_intake_kg_dm, 0.16))
  expect_true(test_near(adequate$move_expected_dry_matter_intake_kg_dm, 0.105))
  expect_true(test_near(adequate$stay_feeding_bout_score_kj, 1600))
  expect_true(test_near(adequate$move_feeding_bout_score_kj, 950))
  expect_true(test_near(adequate$move_score_advantage_kj, -650))
  expect_identical(adequate$selected_action, "stay")
  expect_identical(adequate$selected_patch_id, "adequate_patch")
})

test_that("known-patch choice scores each patch's food-energy density", {
  landscape <- choice_test_landscape(
    capacities = c(current_patch = 0.025, destination_patch = 0.025),
    movement_cost_kj = 900,
    energy_densities = c(6500, 10000)
  )
  moving <- choose_known_patch_for_feeding_bout(
    new_patch_location_state("current_patch"),
    landscape,
    "destination_patch",
    expected_dry_matter_demand_kg_dm_h = 0.020,
    remaining_feeding_opportunity_h = 16
  )
  landscape$patches$metabolizable_energy_density_kj_kg_dm[[1L]] <- 6600
  staying <- choose_known_patch_for_feeding_bout(
    new_patch_location_state("current_patch"),
    landscape,
    "destination_patch",
    expected_dry_matter_demand_kg_dm_h = 0.020,
    remaining_feeding_opportunity_h = 16
  )

  expect_identical(
    moving$current_patch_metabolizable_energy_density_kj_kg_dm,
    6500
  )
  expect_identical(
    moving$destination_patch_metabolizable_energy_density_kj_kg_dm,
    10000
  )
  expect_true(test_near(moving$stay_feeding_bout_score_kj, 2080))
  expect_true(test_near(moving$move_feeding_bout_score_kj, 2100))
  expect_true(test_near(moving$move_score_advantage_kj, 20))
  expect_identical(moving$selected_action, "move")
  expect_true(test_near(staying$stay_feeding_bout_score_kj, 2112))
  expect_true(test_near(staying$move_feeding_bout_score_kj, 2100))
  expect_true(test_near(staying$move_score_advantage_kj, -12))
  expect_identical(staying$selected_action, "stay")
})

test_that("known-patch choice stays on ties and validates its decision horizon", {
  landscape <- choice_test_landscape(
    capacities = c(current_patch = 0.015, destination_patch = 0.020),
    movement_cost_kj = 0
  )
  arguments <- list(
    state = new_patch_location_state("current_patch"),
    landscape = landscape,
    destination_patch_id = "destination_patch",
    expected_dry_matter_demand_kg_dm_h = 0.020,
    remaining_feeding_opportunity_h = 4
  )
  tied <- do.call(choose_known_patch_for_feeding_bout, arguments)

  expect_true(test_near(tied$stay_feeding_bout_score_kj, 600))
  expect_true(test_near(tied$move_feeding_bout_score_kj, 600))
  expect_true(test_near(tied$move_score_advantage_kj, 0))
  expect_identical(tied$selected_action, "stay")

  invalid_horizon <- arguments
  invalid_horizon$remaining_feeding_opportunity_h <- 0
  expect_error(
    do.call(choose_known_patch_for_feeding_bout, invalid_horizon),
    "from 1 to 24"
  )
  invalid_demand <- arguments
  invalid_demand$expected_dry_matter_demand_kg_dm_h <- -0.01
  expect_error(
    do.call(choose_known_patch_for_feeding_bout, invalid_demand),
    "non-negative"
  )
})
