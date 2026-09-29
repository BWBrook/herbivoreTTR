# No-write daily accounting. This does not simulate a physiological trajectory.
source("experiments/red-kangaroo-records.R")

run_red_kangaroo_budget <- function() {
  records <- red_kangaroo_anchor_records()
  m <- records$munn
  assumptions <- records$assumptions
  energy <- do.call(rbind, lapply(assumptions$me_de_ratios, function(ratio) {
    me <- ratio * m$printed_digestible_energy_kj_kg_dm
    intake <- m$field_expenditure_kj_day / me
    # Uniform hourly bookkeeping only: no observed within-day pattern is implied.
    converted <- herbivoreTTR::derive_ingested_available_energy_schedule(
      herbivoreTTR::new_food_energy_parameters(me),
      herbivoreTTR::new_dry_matter_intake_schedule(0:23, rep(intake / 24, 24))
    )
    ingested <- sum(converted$prescribed_ingested_available_energy_kj_h)
    stock <- m$enclosure_area_ha * m$standing_stock_kg_dm_ha
    removal <- m$maximum_measurement_interval_day * (
      m$kangaroos_introduced * intake +
        m$sheep_introduced * m$corrected_sheep_intake_kg_dm_day
    )
    data.frame(
      energy_case = if (ratio == 1) "published_DE_conversion" else "assumed_ME_DE_0.9",
      me_de_ratio = ratio,
      bookkeeping_energy_kj_kg_dm = me,
      derived_intake_kg_dm_day = intake,
      energy_input_kj_day = ingested,
      total_expenditure_kj_day = m$field_expenditure_kj_day,
      energy_balance_residual_kj_day = ingested - m$field_expenditure_kj_day,
      predicted_basal_kj_day = m$predicted_basal_expenditure_kj_day,
      unresolved_nonbasal_kj_day = m$field_expenditure_kj_day -
        m$predicted_basal_expenditure_kj_day,
      body_water_product_of_means_kg = m$mass_kg * m$body_water_fraction,
      average_per_active_hour_intake_kg_dm_h = intake / m$active_harvesting_h_day,
      enclosure_removal_fraction_sheep_at_published_intake = removal / stock,
      enclosure_removal_fraction_common_energy_ratio =
        m$maximum_measurement_interval_day * (m$kangaroos_introduced * intake +
          m$sheep_introduced * m$corrected_sheep_intake_kg_dm_day / ratio) / stock,
      implied_food_water_kg_day_at_synthetic_yield = intake * 3.28,
      maximum_food_water_yield_if_no_other_input_kg_kg_dm =
        m$water_turnover_kg_day / intake,
      stringsAsFactors = FALSE
    )
  }))
  water <- do.call(rbind, lapply(seq_len(nrow(energy)), function(i) {
    grid <- expand.grid(
      food_water_yield_kg_kg_dm = assumptions$food_water_yields_kg_kg_dm,
      metabolic_water_kg_day = assumptions$metabolic_water_kg_day,
      KEEP.OUT.ATTRS = FALSE
    )
    food <- grid$food_water_yield_kg_kg_dm * energy$derived_intake_kg_dm_day[[i]]
    required_drinking <- m$water_turnover_kg_day - food -
      grid$metabolic_water_kg_day
    data.frame(
      energy_case = energy$energy_case[[i]], grid,
      food_water_kg_day = food,
      turnover_kg_day = m$water_turnover_kg_day,
      required_drinking_water_kg_day = required_drinking,
      feasible_nonnegative_drinking = required_drinking >= 0,
      excess_input_before_drinking_kg_day = pmax(0, -required_drinking),
      closure_residual_if_signed_drinking_kg_day = food +
        grid$metabolic_water_kg_day + required_drinking - m$water_turnover_kg_day,
      stringsAsFactors = FALSE
    )
  }))
  # A negative required drink is an infeasible combination, not water elimination
  # that can be hidden while still claiming the measured total turnover.
  rounding <- data.frame(
    printed_de_kj_kg_dm = m$printed_digestible_energy_kj_kg_dm,
    gross_times_digestibility_kj_kg_dm = m$gross_energy_kj_kg_dm *
      m$apparent_dm_digestibility,
    intake_from_unrounded_de_kg_dm_day = m$field_expenditure_kj_day /
      (m$gross_energy_kj_kg_dm * m$apparent_dm_digestibility)
  )
  corners <- expand.grid(
    field_expenditure_kj_day = m$field_expenditure_kj_day +
      c(-1, 1) * m$field_expenditure_se_kj_day,
    apparent_dm_digestibility = m$apparent_dm_digestibility +
      c(-1, 1) * m$apparent_dm_digestibility_se,
    me_de_ratio = assumptions$me_de_ratios,
    turnover_kg_day = m$water_turnover_kg_day +
      c(-1, 1) * m$water_turnover_se_kg_day,
    KEEP.OUT.ATTRS = FALSE
  )
  corners$bookkeeping_energy_kj_kg_dm <- m$gross_energy_kj_kg_dm *
    corners$apparent_dm_digestibility * corners$me_de_ratio
  corners$derived_intake_kg_dm_day <- corners$field_expenditure_kj_day /
    corners$bookkeeping_energy_kj_kg_dm
  corners$maximum_food_yield_no_other_input_kg_kg_dm <-
    corners$turnover_kg_day / corners$derived_intake_kg_dm_day
  corners$maximum_food_yield_metabolic_015_kg_kg_dm <-
    (corners$turnover_kg_day - 0.15) / corners$derived_intake_kg_dm_day
  corners$synthetic_yield_feasible_without_metabolic_water <-
    3.28 <= corners$maximum_food_yield_no_other_input_kg_kg_dm
  list(records = records, energy = energy, water = water,
    rounding = rounding, sensitivity_corners = corners)
}

if (sys.nframe() == 0L) {
  result <- run_red_kangaroo_budget()
  print(result$energy, row.names = FALSE)
  print(result$water, row.names = FALSE)
}
