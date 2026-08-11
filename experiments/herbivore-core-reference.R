source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
reference <- run_appetite_days(fixture)

assert_that(
  near(reference$daily$observed_total_system_energy_change_kj, 0) &&
    near(reference$daily$combined_energy_deviation_from_reference_final_kj, 0),
  "neutral reference energy balance"
)
assert_that(
  near(reference$daily$realized_dry_matter_intake_kg_dm, 0.32) &&
    near(reference$daily$total_realized_ingested_available_energy_kj, 3200) &&
    near(reference$daily$total_prescribed_routine_activity_expenditure_kj, 800),
  "reference intake and expenditure"
)
assert_that(
  max(abs(reference$hourly$system_energy_balance_residual_kj)) < 1e-8,
  "hourly whole-system conservation"
)

gut_probe <- herbivoreTTR::step_gut_energy(
  herbivoreTTR::new_gut_energy_state(400),
  fixture$gut,
  data.frame(
    hour_of_day = 0L,
    prescribed_ingested_available_energy_kj_h = 100
  )
)
assert_that(
  near(gut_probe$fluxes$assimilated_energy_kj, 100) &&
    near(gut_probe$state$gut_available_energy_kj, 400),
  "release from opening gut stock before current intake"
)

reference_summary <- data.frame(
  daily_intake_kg_dm = reference$daily$realized_dry_matter_intake_kg_dm,
  daily_input_kj = reference$daily$total_realized_ingested_available_energy_kj,
  maintenance_kj = reference$daily$total_maintenance_expenditure_kj,
  routine_activity_kj =
    reference$daily$total_prescribed_routine_activity_expenditure_kj,
  daily_system_change_kj =
    round(reference$daily$observed_total_system_energy_change_kj),
  burn_in_days = tail(
    fixture$reference_cycle$convergence$burn_in_day,
    1L
  )
)

cat("Herbivore-core reference diagnostic passed.\n")
print(reference_summary, row.names = FALSE)
