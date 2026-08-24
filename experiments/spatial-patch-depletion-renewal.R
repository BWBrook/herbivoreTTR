source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
patch_ids <- c("patch_a", "patch_b")
landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = patch_ids,
  forage_acquisition_ceiling_kg_dm_h = c(0.025, 0.025),
  route_origin_patch_id = c("patch_a", "patch_b"),
  route_destination_patch_id = c("patch_b", "patch_a"),
  incremental_movement_expenditure_kj = c(900, 900),
  metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
)
turnover <- herbivoreTTR::new_forage_turnover_parameters(1000, 0.001)
coupling <- herbivoreTTR::new_nonspatial_coupling_parameters(10, 500)

location <- herbivoreTTR::new_patch_location_state("patch_a")
gut <- fixture$opening_gut
body <- fixture$opening_body
forage <- herbivoreTTR::new_spatial_forage_biomass_state(
  patch_ids,
  c(1000, 1000)
)

daily_results <- vector("list", 61L)
patch_daily_results <- vector("list", 61L)
patch_hourly_results <- vector("list", 61L)

for (simulation_day in seq_len(61L)) {
  closing_patch_id <- if (simulation_day <= 30L) {
    rep("patch_a", 24L)
  } else if (simulation_day == 31L) {
    ifelse(fixture$hour_of_day < 8L, "patch_a", "patch_b")
  } else {
    rep("patch_b", 24L)
  }

  result <- herbivoreTTR::run_prescribed_spatial_coupled_energy_day(
    initial_location_state = location,
    landscape = landscape,
    itinerary = herbivoreTTR::new_prescribed_patch_itinerary(
      fixture$hour_of_day,
      closing_patch_id
    ),
    initial_gut_state = gut,
    initial_body_state = body,
    initial_spatial_forage_state = forage,
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    appetite_parameters = fixture$appetite,
    forage_turnover_parameters = turnover,
    coupling_parameters = coupling,
    appetite_reference_schedule = fixture$appetite_reference,
    routine_activity_schedule = fixture$activity
  )
  result$daily$simulation_day <- simulation_day
  result$patch_daily$simulation_day <- simulation_day
  result$patch_hourly$simulation_day <- simulation_day
  daily_results[[simulation_day]] <- result$daily
  patch_daily_results[[simulation_day]] <- result$patch_daily
  patch_hourly_results[[simulation_day]] <- result$patch_hourly

  location <- result$final_state$location
  gut <- result$final_state$gut
  body <- result$final_state$body
  forage <- result$final_state$forage
}

daily <- do.call(rbind, daily_results)
patch_daily <- do.call(rbind, patch_daily_results)
patch_hourly <- do.call(rbind, patch_hourly_results)
row.names(daily) <- NULL
row.names(patch_daily) <- NULL
row.names(patch_hourly) <- NULL

patch_trajectory <- function(patch_id) {
  patch_daily[patch_daily$patch_id == patch_id, , drop = FALSE]
}
patch_a <- patch_trajectory("patch_a")
patch_b <- patch_trajectory("patch_b")

assert_that(
  identical(patch_b$forage_biomass_final_kg_dm_ha[1:30], rep(1000, 30L)),
  "unoccupied patch B remains exactly at equilibrium during phase 1"
)
assert_that(
  all(diff(patch_a$forage_biomass_final_kg_dm_ha[1:30]) < 0) &&
    min(patch_a$forage_biomass_final_kg_dm_ha) > 500,
  "occupied patch A declines daily without reaching the residual threshold"
)
assert_that(
  all(diff(patch_a$forage_biomass_final_kg_dm_ha[31:61]) > 0) &&
    all(diff(patch_b$forage_biomass_final_kg_dm_ha[31:61]) < 0),
  "released patch A renews while occupied patch B declines"
)
assert_that(
  identical(which(daily$movement_hours > 0), 31L) &&
    identical(daily$movement_hours[[31L]], 1L) &&
    near(daily$total_incremental_movement_expenditure_kj[[31L]], 900) &&
    near(daily$feeding_time_lost_h[[31L]], 0),
  "the transfer is one closed-hour 900 kJ movement"
)
assert_that(
  sum(daily$forage_stock_ceiling_active_hours) == 0L,
  "the diagnostic remains free of stock limitation"
)
assert_that(
  max(abs(patch_hourly$forage_biomass_balance_residual_kg_dm_ha)) < 1e-10 &&
    max(abs(patch_daily$forage_biomass_balance_residual_kg_dm_ha)) < 1e-10 &&
    max(abs(daily$herbivore_forage_coupling_residual_kg_dm_ha)) < 1e-10 &&
    max(abs(daily$system_energy_balance_residual_kj)) < 1e-8,
  "patch, coupling, and animal-energy balances close"
)

checkpoint_days <- c(30L, 31L, 61L)
checkpoints <- data.frame(
  checkpoint = c("opening", "end_day_30", "end_transfer_day", "end_day_61"),
  patch_a_biomass_kg_dm_ha = c(
    1000,
    patch_a$forage_biomass_final_kg_dm_ha[checkpoint_days]
  ),
  patch_b_biomass_kg_dm_ha = c(
    1000,
    patch_b$forage_biomass_final_kg_dm_ha[checkpoint_days]
  ),
  row.names = NULL
)

phase <- cut(
  patch_daily$simulation_day,
  breaks = c(0, 30, 31, 61),
  labels = c("patch_a_occupancy", "transfer", "patch_b_occupancy")
)
patch_phase_keys <- unique(data.frame(
  phase = phase,
  patch_id = patch_daily$patch_id,
  stringsAsFactors = FALSE
))
patch_phase_summary <- do.call(rbind, lapply(
  seq_len(nrow(patch_phase_keys)),
  function(row_index) {
    key <- patch_phase_keys[row_index, ]
    keep <- phase == key$phase & patch_daily$patch_id == key$patch_id
    rows <- patch_daily[keep, , drop = FALSE]
    data.frame(
      phase = as.character(key$phase),
      patch_id = key$patch_id,
      growth_kg_dm_ha = sum(rows$total_forage_growth_kg_dm_ha),
      background_loss_kg_dm_ha =
        sum(rows$total_forage_background_loss_kg_dm_ha),
      herbivory_kg_dm_ha = sum(rows$total_herbivory_removal_kg_dm_ha),
      biomass_change_kg_dm_ha =
        sum(rows$observed_forage_biomass_change_kg_dm_ha),
      balance_residual_kg_dm_ha =
        sum(rows$forage_biomass_balance_residual_kg_dm_ha),
      row.names = NULL
    )
  }
))

animal_phase <- cut(
  daily$simulation_day,
  breaks = c(0, 30, 31, 61),
  labels = c("patch_a_occupancy", "transfer", "patch_b_occupancy")
)
animal_phase_summary <- do.call(rbind, lapply(
  levels(animal_phase),
  function(phase_name) {
    rows <- daily[animal_phase == phase_name, , drop = FALSE]
    data.frame(
      phase = phase_name,
      realized_intake_kg_dm = sum(rows$realized_dry_matter_intake_kg_dm),
      movement_expenditure_kj = round(
        sum(rows$total_incremental_movement_expenditure_kj)
      ),
      combined_energy_change_kj = round(
        sum(rows$observed_total_system_energy_change_kj)
      ),
      stock_limited_hours = sum(rows$forage_stock_ceiling_active_hours),
      row.names = NULL
    )
  }
))

cat("Spatial patch depletion-and-renewal diagnostic passed.\n")
cat("Common turnover and all animal parameters remained fixed for 61 days.\n\n")
cat("Biomass checkpoints (kg DM/ha):\n")
print(transform(
  checkpoints,
  patch_a_biomass_kg_dm_ha = round(patch_a_biomass_kg_dm_ha, 2),
  patch_b_biomass_kg_dm_ha = round(patch_b_biomass_kg_dm_ha, 2)
), row.names = FALSE)
cat("\nPatch phase accounting (kg DM/ha):\n")
print(transform(
  patch_phase_summary,
  growth_kg_dm_ha = round(growth_kg_dm_ha, 2),
  background_loss_kg_dm_ha = round(background_loss_kg_dm_ha, 2),
  herbivory_kg_dm_ha = round(herbivory_kg_dm_ha, 2),
  biomass_change_kg_dm_ha = round(biomass_change_kg_dm_ha, 2),
  balance_residual_kg_dm_ha = signif(balance_residual_kg_dm_ha, 3)
), row.names = FALSE)
cat("\nAnimal phase accounting:\n")
print(animal_phase_summary, row.names = FALSE)
