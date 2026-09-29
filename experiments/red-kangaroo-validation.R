# Checks the empirical accounting and the declared observation contract.
# These checks establish numerical consistency, not biological validation.
validate_red_kangaroo_benchmark <- function(budget, short) {
  e <- budget$energy
  w <- budget$water
  m <- budget$records$munn
  r <- short$response_loci
  transforms <- short$response_transforms
  no_flux <- r[r$net_plant_flux_kg_dm_ha_day == 0, ]
  # Net plant change must remain visible in a stock-loss intake estimator.
  stock_loss_identity <- r$smoothed_stock_loss_g_dm_animal_day -
    (1000 * r$total_intake_kg_dm_animal / 4 -
      1000 * r$total_net_plant_change_kg_dm_ha / (50 * 4))
  rejected_offset <- transforms[transforms$j_offset_kg_dm_ha == 84, ]
  expected_pairing <- with(transforms, ifelse(x_pairing == "opening", V0_kg_dm_ha,
    ifelse(x_pairing == "midpoint", V2_kg_dm_ha,
      ifelse(x_pairing == "closing", V4_kg_dm_ha,
        (V0_kg_dm_ha + 2 * V2_kg_dm_ha + V4_kg_dm_ha) / 4))))
  synthetic_water <- w[w$food_water_yield_kg_kg_dm == 3.28, ]
  primary_id <- "S1.0_R0_phi0.0"
  checks <- data.frame(
    check = c("Munn energy closes", "Munn corrected intake reproduced",
      "FMR partition counted once", "Water identity including signed infeasible drinks",
      "Negative required drink is infeasible", "Synthetic water yield fails central cases",
      "Declared corner count", "Declared Short scenarios and stocks",
      "Daily search exposure conversion", "Two adjacent intervals smoothed once",
      "Plant flux preserved in observation estimator", "No-flux stock loss equals ingestion",
      "All biomass timestamp transforms", "Rejected offset changes observation only",
      "Endpoint-weighted locus is primary only", "Short numerical controls"),
    pass = c(
      all(abs(e$energy_balance_residual_kj_day) < 1e-8),
      abs(e$derived_intake_kg_dm_day[e$me_de_ratio == 1] -
        m$corrected_derived_intake_kg_dm_day) < 0.0005,
      all(abs(e$predicted_basal_kj_day + e$unresolved_nonbasal_kj_day -
        m$field_expenditure_kj_day) < 1e-8),
      all(abs(w$closure_residual_if_signed_drinking_kg_day) < 1e-10),
      identical(w$feasible_nonnegative_drinking,
        w$required_drinking_water_kg_day >= 0),
      all(!synthetic_water$feasible_nonnegative_drinking),
      nrow(budget$sensitivity_corners) == 16L,
      nrow(short$scenario_design) == 18L && nrow(r) == 18L * 141L &&
        identical(short$initial_stocks_kg_dm_ha, seq(0, 700, by = 5)),
      all(abs(short$scenario_design$search_area_m2_day /
        short$scenario_design$search_multiplier - 0.709 / 84 * 10000) < 1e-12),
      all(abs(r$smoothed_stock_loss_g_dm_animal_day -
        (r$interval_stock_loss_1_g_dm_animal_day +
          r$interval_stock_loss_2_g_dm_animal_day) / 2) < 1e-10),
      max(abs(stock_loss_identity)) < 1e-9,
      max(abs(no_flux$stock_loss_minus_ingestion_g_dm_animal_day)) < 1e-9,
      max(abs(transforms$model_x_combined_vegetation_kg_dm_ha -
        expected_pairing - transforms$j_offset_kg_dm_ha)) < 1e-10,
      all(rejected_offset$j_offset_kg_dm_ha == 84) &&
        max(abs(rejected_offset$smoothed_stock_loss_g_dm_animal_day -
          r$smoothed_stock_loss_g_dm_animal_day[match(paste(rejected_offset$scenario_id,
            rejected_offset$initial_biomass_kg_dm_ha),
            paste(r$scenario_id, r$initial_biomass_kg_dm_ha))])) < 1e-10,
      all(transforms$scenario_id[transforms$x_pairing == "endpoint_weighted"] == primary_id),
      all(short$checks$pass)
    ), stringsAsFactors = FALSE
  )
  if (!all(checks$pass)) stop(paste("Benchmark checks failed:",
    paste(checks$check[!checks$pass], collapse = "; ")), call. = FALSE)
  checks
}
