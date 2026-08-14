source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
density_animals_ha <- 10
residual_threshold_kg_dm_ha <- 500
equilibrium_biomass_kg_dm_ha <- 1000
turnover_fraction_h <- 0.001
coupling <- herbivoreTTR::new_nonspatial_coupling_parameters(
  density_animals_ha,
  residual_threshold_kg_dm_ha
)

removal_only <- herbivoreTTR::step_forage_herbivory(
  herbivoreTTR::new_forage_biomass_state(1000),
  coupling,
  0.02
)
binding <- herbivoreTTR::step_forage_herbivory(
  herbivoreTTR::new_forage_biomass_state(500.1),
  coupling,
  0.02
)

assert_that(
  near(removal_only$fluxes$herbivory_removal_kg_dm_ha, 0.2) &&
    near(removal_only$state$forage_biomass_kg_dm_ha, 999.8) &&
    !removal_only$fluxes$forage_stock_ceiling_active,
  "removal-only density scaling"
)
assert_that(
  near(binding$fluxes$realized_dry_matter_intake_kg_dm, 0.01) &&
    near(binding$state$forage_biomass_kg_dm_ha, 500) &&
    binding$fluxes$forage_stock_ceiling_active,
  "binding accessibility boundary"
)

retention <- 1 - turnover_fraction_h
hourly_increment <-
  turnover_fraction_h * equilibrium_biomass_kg_dm_ha -
    density_animals_ha * fixture$reference_intake_kg_dm_h
periodic_opening_kg_dm_ha <-
  sum(retention^(23:0) * hourly_increment) /
    (1 - retention^24)

reference <- herbivoreTTR::run_nonspatial_coupled_energy_days(
  initial_gut_state = fixture$opening_gut,
  initial_body_state = fixture$opening_body,
  initial_forage_state = herbivoreTTR::new_forage_biomass_state(
    periodic_opening_kg_dm_ha
  ),
  gut_parameters = fixture$gut,
  body_parameters = fixture$body,
  food_parameters = fixture$food,
  appetite_parameters = fixture$appetite,
  forage_turnover_parameters =
    herbivoreTTR::new_forage_turnover_parameters(
      equilibrium_biomass_kg_dm_ha,
      turnover_fraction_h
    ),
  coupling_parameters = coupling,
  appetite_reference_schedule = fixture$appetite_reference,
  forage_acquisition_ceiling_schedule = fixture$nonlimiting_forage,
  routine_activity_schedule = fixture$activity,
  number_of_days = 2L
)
day_1 <- reference$hourly[
  reference$hourly$simulation_day == 1L,
  ,
  drop = FALSE
]
day_2 <- reference$hourly[
  reference$hourly$simulation_day == 2L,
  ,
  drop = FALSE
]

assert_that(
  near(
    day_1$forage_biomass_start_kg_dm_ha,
    day_2$forage_biomass_start_kg_dm_ha,
    tolerance = 1e-10
  ),
  "period-24 forage trajectory"
)
assert_that(
  near(reference$daily$realized_dry_matter_intake_kg_dm, c(0.32, 0.32)) &&
    near(reference$daily$total_herbivory_removal_kg_dm_ha, c(3.2, 3.2)) &&
    near(reference$daily$observed_total_system_energy_change_kj, c(0, 0)) &&
    all(reference$daily$forage_stock_ceiling_active_hours == 0L),
  "neutral non-binding coupled reference"
)
assert_that(
  max(abs(reference$hourly$forage_biomass_balance_residual_kg_dm_ha)) <
    1e-10 &&
    max(abs(
      reference$hourly$herbivore_forage_coupling_residual_kg_dm_ha
    )) < 1e-10 &&
    max(abs(reference$hourly$system_energy_balance_residual_kj)) < 1e-8,
  "coupled dry-matter and energy conservation"
)

checkpoint_summary <- data.frame(
  checkpoint = c("removal only", "binding boundary"),
  candidate_intake_kg_dm = c(0.02, 0.02),
  realized_intake_kg_dm = c(
    removal_only$fluxes$realized_dry_matter_intake_kg_dm,
    binding$fluxes$realized_dry_matter_intake_kg_dm
  ),
  removal_kg_dm_ha = c(
    removal_only$fluxes$herbivory_removal_kg_dm_ha,
    binding$fluxes$herbivory_removal_kg_dm_ha
  ),
  closing_biomass_kg_dm_ha = c(
    removal_only$state$forage_biomass_kg_dm_ha,
    binding$state$forage_biomass_kg_dm_ha
  )
)
reference_summary <- data.frame(
  density_animals_ha = density_animals_ha,
  mean_forage_biomass_kg_dm_ha = round(
    mean(day_1$forage_biomass_start_kg_dm_ha),
    1
  ),
  minimum_forage_biomass_kg_dm_ha = round(
    min(day_1$forage_biomass_start_kg_dm_ha),
    1
  ),
  maximum_forage_biomass_kg_dm_ha = round(
    max(day_1$forage_biomass_start_kg_dm_ha),
    1
  ),
  daily_per_animal_intake_kg_dm =
    reference$daily$realized_dry_matter_intake_kg_dm[[1L]],
  daily_removal_kg_dm_ha =
    reference$daily$total_herbivory_removal_kg_dm_ha[[1L]],
  daily_animal_energy_change_kj = round(
    reference$daily$observed_total_system_energy_change_kj[[1L]]
  )
)

cat("Minimum non-spatial coupled-reference diagnostic passed.\n")
print(checkpoint_summary, row.names = FALSE)
cat("\nPeriod-24 constant coupled reference:\n")
print(reference_summary, row.names = FALSE)
