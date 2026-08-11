source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
reference <- run_appetite_days(fixture)
binding_forage <- herbivoreTTR::new_forage_acquisition_ceiling_schedule(
  fixture$hour_of_day,
  as.double(fixture$feeding_open) * 0.015
)
limited <- run_appetite_days(fixture, forage = binding_forage)

assert_that(
  identical(limited$daily$forage_acquisition_ceiling_active_hours, 16L) &&
    near(limited$daily$realized_dry_matter_intake_kg_dm, 0.24) &&
    near(limited$daily$observed_total_system_energy_change_kj, -800),
  "binding forage ceiling produces the analytical 800 kJ deficit"
)
assert_that(
  limited$daily$appetite_target_dry_matter_intake_kg_dm >
    limited$daily$realized_dry_matter_intake_kg_dm,
  "appetite demand remains distinct from realized intake"
)

recovery <- run_appetite_days(
  fixture,
  number_of_days = 9L,
  initial_gut = herbivoreTTR::new_gut_energy_state(
    limited$daily$gut_available_energy_final_kj
  ),
  initial_body = herbivoreTTR::new_body_energy_state(
    limited$daily$body_energy_reserve_final_kj
  )
)
assert_that(
  recovery$daily$combined_energy_deviation_from_reference_final_kj[[1L]] > -800 &&
    abs(tail(
      recovery$daily$combined_energy_deviation_from_reference_final_kj,
      1L
    )) < 2,
  "deficit-responsive appetite restores the reference trajectory"
)

lower_quality <- run_appetite_days(
  fixture,
  number_of_days = 10L,
  food = herbivoreTTR::new_food_energy_parameters(8000)
)
assert_that(
  near(
    lower_quality$daily$combined_energy_deviation_from_reference_final_kj[[10L]],
    -799,
    tolerance = 2e-3
  ) &&
    abs(lower_quality$daily$observed_total_system_energy_change_kj[[10L]]) < 2,
  "reactive appetite nearly balances daily lower-quality intake without repaying debt"
)

appetite_forage_summary <- data.frame(
  scenario = c(
    "reference",
    "binding_forage_day",
    "recovery_day_9",
    "lower_quality_day_10"
  ),
  realized_intake_kg_dm = c(
    reference$daily$realized_dry_matter_intake_kg_dm,
    limited$daily$realized_dry_matter_intake_kg_dm,
    recovery$daily$realized_dry_matter_intake_kg_dm[[9L]],
    lower_quality$daily$realized_dry_matter_intake_kg_dm[[10L]]
  ),
  combined_deviation_kj = round(c(
    reference$daily$combined_energy_deviation_from_reference_final_kj,
    limited$daily$combined_energy_deviation_from_reference_final_kj,
    recovery$daily$combined_energy_deviation_from_reference_final_kj[[9L]],
    lower_quality$daily$combined_energy_deviation_from_reference_final_kj[[10L]]
  ))
)

cat("Herbivore-core appetite and forage diagnostic passed.\n")
print(appetite_forage_summary, row.names = FALSE)
