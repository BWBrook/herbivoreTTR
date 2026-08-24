source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
energy_density_kj_kg_dm <- c(
  adequate_patch = 10000,
  lower_quality_patch = 8000
)
landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = names(energy_density_kj_kg_dm),
  forage_acquisition_ceiling_kg_dm_h = c(0.025, 0.025),
  route_origin_patch_id = names(energy_density_kj_kg_dm),
  route_destination_patch_id = rev(names(energy_density_kj_kg_dm)),
  incremental_movement_expenditure_kj = c(0, 0),
  metabolizable_energy_density_kj_kg_dm = energy_density_kj_kg_dm
)

run_patch <- function(patch_id) {
  herbivoreTTR::run_prescribed_spatial_energy_day(
    initial_location_state = herbivoreTTR::new_patch_location_state(patch_id),
    landscape = landscape,
    itinerary = herbivoreTTR::new_prescribed_patch_itinerary(
      fixture$hour_of_day,
      rep(patch_id, 24L)
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

spatial_cases <- setNames(
  lapply(names(energy_density_kj_kg_dm), run_patch),
  names(energy_density_kj_kg_dm)
)
core_cases <- lapply(
  energy_density_kj_kg_dm,
  function(energy_density) {
    run_appetite_days(
      fixture,
      food = herbivoreTTR::new_food_energy_parameters(energy_density)
    )
  }
)

for (patch_id in names(spatial_cases)) {
  spatial <- spatial_cases[[patch_id]]
  core <- core_cases[[patch_id]]

  assert_that(
    identical(spatial$hourly[names(core$hourly)], core$hourly) &&
      identical(spatial$daily[names(core$daily)], core$daily),
    paste(patch_id, "all-stay exact reduction")
  )
  assert_that(
    all(spatial$hourly$spatial_action == "stay") &&
      identical(spatial$daily$movement_hours, 0L) &&
      near(spatial$daily$total_travel_duration_h, 0) &&
      near(spatial$daily$feeding_time_lost_h, 0) &&
      near(spatial$daily$total_incremental_movement_expenditure_kj, 0),
    paste(patch_id, "movement exclusion")
  )
  assert_that(
    all(!spatial$hourly$forage_acquisition_ceiling_active) &&
      all(spatial$hourly$metabolizable_energy_density_kj_kg_dm ==
        energy_density_kj_kg_dm[[patch_id]]),
    paste(patch_id, "nonlimiting acquisition and patch energy density")
  )
  assert_that(
    max(abs(spatial$hourly$system_energy_balance_residual_kj)) < 1e-9 &&
      abs(spatial$daily$system_energy_balance_residual_kj) < 1e-9,
    paste(patch_id, "energy accounting")
  )
}

adequate <- spatial_cases$adequate_patch$daily
lower <- spatial_cases$lower_quality_patch$daily
assert_that(
  near(adequate$realized_dry_matter_intake_kg_dm, 0.32) &&
    near(adequate$total_realized_ingested_available_energy_kj, 3200) &&
    near(adequate$observed_total_system_energy_change_kj, 0),
  "adequate-patch neutral reference"
)
assert_that(
  near(lower$realized_dry_matter_intake_kg_dm, 0.3484966, 1e-6) &&
    near(lower$total_realized_ingested_available_energy_kj, 2787.973, 1e-6) &&
    near(lower$observed_total_system_energy_change_kj, -412.0268, 1e-6),
  "lower-quality appetite and energy response"
)

summary_table <- data.frame(
  patch_id = names(spatial_cases),
  metabolizable_energy_density_kj_kg_dm = energy_density_kj_kg_dm,
  realized_intake_kg_dm = vapply(
    spatial_cases,
    function(result) result$daily$realized_dry_matter_intake_kg_dm,
    numeric(1L)
  ),
  realized_ingested_energy_kj = round(vapply(
    spatial_cases,
    function(result) {
      result$daily$total_realized_ingested_available_energy_kj
    },
    numeric(1L)
  )),
  combined_energy_change_kj = round(vapply(
    spatial_cases,
    function(result) result$daily$observed_total_system_energy_change_kj,
    numeric(1L)
  )),
  row.names = NULL
)

cat("Explicit patch food-quality diagnostic passed.\n")
print(summary_table, row.names = FALSE)
