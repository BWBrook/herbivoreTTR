if (!requireNamespace("herbivoreTTR", quietly = TRUE)) {
  stop(
    "Install herbivoreTTR before running the forage diagnostic.",
    call. = FALSE
  )
}

near <- function(observed, expected, tolerance = 1e-9) {
  scale <- pmax(1, abs(observed), abs(expected))
  all(abs(observed - expected) <= tolerance * scale)
}

scenarios <- data.frame(
  treatment = c("balanced_turnover", "net_gain", "net_loss"),
  growth_kg_dm_ha_h = c(2, 2, 1),
  loss_kg_dm_ha_h = c(2, 1, 2),
  expected_change_kg_dm_ha = c(0, 24, -24)
)

summary_rows <- lapply(seq_len(nrow(scenarios)), function(index) {
  scenario <- scenarios[index, , drop = FALSE]
  result <- herbivoreTTR::run_forage_biomass_day(
    initial_state = herbivoreTTR::new_forage_biomass_state(1000),
    schedule = herbivoreTTR::new_forage_growth_loss_schedule(
      hour_of_day = 0:23,
      prescribed_forage_growth_kg_dm_ha_h =
        rep(scenario$growth_kg_dm_ha_h, 24L),
      prescribed_forage_background_loss_kg_dm_ha_h =
        rep(scenario$loss_kg_dm_ha_h, 24L)
    )
  )

  data.frame(
    treatment = scenario$treatment,
    initial_kg_dm_ha = result$daily$forage_biomass_initial_kg_dm_ha,
    growth_kg_dm_ha =
      result$daily$total_prescribed_forage_growth_kg_dm_ha,
    loss_kg_dm_ha =
      result$daily$total_prescribed_forage_background_loss_kg_dm_ha,
    expected_change_kg_dm_ha =
      result$daily$expected_forage_biomass_change_kg_dm_ha,
    observed_change_kg_dm_ha =
      result$daily$observed_forage_biomass_change_kg_dm_ha,
    final_kg_dm_ha = result$daily$forage_biomass_final_kg_dm_ha,
    residual_kg_dm_ha =
      result$daily$forage_biomass_balance_residual_kg_dm_ha
  )
})
summary <- do.call(rbind, summary_rows)
row.names(summary) <- NULL

if (
  !near(
    summary$observed_change_kg_dm_ha,
    scenarios$expected_change_kg_dm_ha
  ) ||
    !near(summary$residual_kg_dm_ha, 0) ||
    !identical(summary$final_kg_dm_ha, c(1000, 1024, 976))
) {
  stop("Forage stock-and-flow diagnostic failed.", call. = FALSE)
}

cat("Isolated forage stock-and-flow diagnostic passed.\n")
display <- summary
names(display) <- c(
  "treatment",
  "initial",
  "growth",
  "loss",
  "expected_change",
  "observed_change",
  "final",
  "residual"
)
cat("All biomass quantities are kg DM ha^-1.\n")
print(display, row.names = FALSE)
