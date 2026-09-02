source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
forage_patch_id <- "forage_patch"
water_source_patch_id <- "water_source"
movement_expenditure_per_leg_kj <- 900
normal_body_water_kg <- 28
critical_body_water_kg <- 24
initial_body_water_kg <- 26
food_water_yield_kg_water_kg_dm <- 3.28

landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = c(forage_patch_id, water_source_patch_id),
  forage_acquisition_ceiling_kg_dm_h = c(0.025, 0),
  route_origin_patch_id = c(forage_patch_id, water_source_patch_id),
  route_destination_patch_id = c(water_source_patch_id, forage_patch_id),
  incremental_movement_expenditure_kj = rep(
    movement_expenditure_per_leg_kj,
    2L
  ),
  metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
)
water_properties <- herbivoreTTR::new_patch_water_properties(
  patch_id = c(forage_patch_id, water_source_patch_id),
  food_derived_water_yield_kg_water_kg_dm = c(
    food_water_yield_kg_water_kg_dm,
    0
  ),
  drinking_water_availability_kg_h = c(0, 10)
)
water_parameters <- herbivoreTTR::new_body_water_parameters(
  normal_body_water_kg,
  critical_body_water_kg,
  1.56 / 24
)

run_itinerary <- function(closing_patch_id) {
  energy <- herbivoreTTR::run_prescribed_spatial_energy_day(
    initial_location_state = herbivoreTTR::new_patch_location_state(
      forage_patch_id
    ),
    landscape = landscape,
    itinerary = herbivoreTTR::new_prescribed_patch_itinerary(
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
  water <- herbivoreTTR::run_spatial_body_water_day(
    herbivoreTTR::new_body_water_state(initial_body_water_kg),
    water_parameters,
    water_properties,
    energy$hourly,
    rep(0, 24L)
  )
  list(energy = energy, water = water)
}

no_excursion <- rep(forage_patch_id, 24L)
off_window_excursion <- no_excursion
off_window_excursion[fixture$hour_of_day %in% c(8L, 9L)] <-
  water_source_patch_id
within_window_excursion <- no_excursion
within_window_excursion[fixture$hour_of_day %in% c(6L, 7L)] <-
  water_source_patch_id

cases <- list(
  no_excursion = run_itinerary(no_excursion),
  off_window_excursion = run_itinerary(off_window_excursion),
  within_window_excursion = run_itinerary(within_window_excursion)
)

summary_table <- do.call(rbind, lapply(names(cases), function(case_name) {
  case <- cases[[case_name]]
  feeding_unavailable <- with(
    case$energy$hourly,
    baseline_feeding_opportunity_open &
      (spatial_action == "move" | opening_patch_id == water_source_patch_id)
  )
  data.frame(
    treatment = case_name,
    movement_hours = case$energy$daily$movement_hours,
    feeding_opportunity_unavailable_h = sum(feeding_unavailable),
    movement_expenditure_kj =
      case$energy$daily$total_incremental_movement_expenditure_kj,
    realized_intake_kg_dm =
      case$energy$daily$realized_dry_matter_intake_kg_dm,
    combined_energy_change_kj =
      case$energy$daily$observed_total_system_energy_change_kj,
    food_derived_water_kg =
      case$water$daily$total_food_derived_water_kg,
    drinking_water_kg =
      case$water$daily$total_realized_drinking_water_kg,
    body_water_change_kg =
      case$water$daily$observed_body_water_change_kg,
    closing_body_water_kg = case$water$daily$body_water_final_kg,
    energy_balance_residual_kj =
      case$energy$daily$system_energy_balance_residual_kj,
    water_balance_residual_kg =
      case$water$daily$body_water_balance_residual_kg,
    row.names = NULL
  )
}))

assert_that(
  identical(summary_table$movement_hours, c(0L, 2L, 2L)) &&
    identical(summary_table$feeding_opportunity_unavailable_h, c(0L, 0L, 2L)) &&
    near(summary_table$movement_expenditure_kj, c(0, 1800, 1800)),
  "the three-hour visit separates travel from zero versus two unavailable feeding hours"
)
assert_that(
  near(summary_table$drinking_water_kg[[1L]], 0) &&
    all(summary_table$drinking_water_kg[-1L] > 0) &&
    all(summary_table$closing_body_water_kg[-1L] >
      summary_table$closing_body_water_kg[[1L]]),
  "stationary source access adds a hydration benefit"
)
assert_that(
  max(abs(summary_table$energy_balance_residual_kj)) < 1e-8 &&
    max(abs(summary_table$water_balance_residual_kg)) < 1e-12,
  "energy and water accounts close independently"
)

cat("Spatial water-source benefit diagnostic passed.\n")
print(transform(
  summary_table[, c(
    "treatment",
    "movement_hours",
    "feeding_opportunity_unavailable_h",
    "movement_expenditure_kj",
    "realized_intake_kg_dm",
    "combined_energy_change_kj",
    "food_derived_water_kg",
    "drinking_water_kg",
    "closing_body_water_kg"
  )],
  movement_expenditure_kj = round(movement_expenditure_kj),
  combined_energy_change_kj = round(combined_energy_change_kj),
  food_derived_water_kg = round(food_derived_water_kg, 2),
  drinking_water_kg = round(drinking_water_kg, 2),
  closing_body_water_kg = round(closing_body_water_kg, 2)
), row.names = FALSE)
