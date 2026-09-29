# Study-specific empirical inputs for the approved red-kangaroo benchmark.
# These are not a complete dynamic physiology fixture. See
# docs/red-kangaroo-benchmark-specification.md for provenance and assumptions.
red_kangaroo_anchor_records <- function() {
  list(
    munn = list(
      context = "Fowlers Gap, April 2007; mature dry female red kangaroo",
      mass_kg = 23.6,
      mass_se_kg = 0.8,
      field_expenditure_kj_day = 4872,
      field_expenditure_se_kj_day = 364,
      predicted_basal_expenditure_kj_day = 2141,
      predicted_basal_expenditure_se_kj_day = 52,
      gross_energy_kj_kg_dm = 18000,
      apparent_dm_digestibility = 0.521,
      apparent_dm_digestibility_se = 0.039,
      printed_digestible_energy_kj_kg_dm = 9400,
      corrected_derived_intake_kg_dm_day = 0.518,
      corrected_derived_intake_se_kg_dm_day = 0.039,
      body_water_fraction = 0.667,
      body_water_fraction_se = 0.005,
      water_turnover_kg_day = 1.5,
      water_turnover_se_kg_day = 0.1,
      active_harvesting_h_day = 10.4,
      enclosure_area_ha = 16,
      standing_stock_kg_dm_ha = 440,
      kangaroos_introduced = 7L,
      sheep_introduced = 7L,
      kangaroos_analyzed = 6L,
      sheep_analyzed = 5L,
      corrected_sheep_intake_kg_dm_day = 1.572,
      maximum_measurement_interval_day = 8
    ),
    short = list(
      context = "Kinchega, spring; adult female red kangaroos",
      mass_kg = 25.6,
      yard_area_ha = 0.04,
      animals_per_yard = 2L,
      yards = 2L,
      observation_interval_day = 2,
      smoothing_intervals = 2L,
      fitted_asymptote_kg_dm_day = 0.709,
      fitted_density_scale_kg_dm_ha = 84
    ),
    assumptions = list(
      me_de_ratios = c(1, 0.9),
      food_water_yields_kg_kg_dm = c(0, 0.5, 1, 1.5, 2, 2.5, 3.28),
      metabolic_water_kg_day = c(0, 0.15),
      steady_mean_body_energy = TRUE,
      steady_mean_body_water = TRUE
    )
  )
}
