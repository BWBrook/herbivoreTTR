if (!requireNamespace("herbivoreTTR", quietly = TRUE)) {
  stop(
    "Install herbivoreTTR before running the forage-turnover diagnostic.",
    call. = FALSE
  )
}

equilibrium_kg_dm_ha <- 1000
turnover_fraction_h <- 0.001
horizon_days <- 180L
reporting_days <- c(0L, 1L, 30L, 90L, 180L)
initial_biomass <- c(low = 500, equilibrium = 1000, high = 1500)
parameters <- herbivoreTTR::new_forage_turnover_parameters(
  equilibrium_kg_dm_ha,
  turnover_fraction_h
)

runs <- lapply(initial_biomass, function(opening_biomass) {
  herbivoreTTR::run_forage_turnover_days(
    herbivoreTTR::new_forage_biomass_state(opening_biomass),
    parameters,
    horizon_days
  )
})

trajectory_rows <- lapply(names(runs), function(scenario) {
  run <- runs[[scenario]]
  numerical <- c(
    initial_biomass[[scenario]],
    run$daily$forage_biomass_final_kg_dm_ha
  )
  day <- 0:horizon_days
  analytic <- equilibrium_kg_dm_ha +
    (initial_biomass[[scenario]] - equilibrium_kg_dm_ha) *
      (1 - turnover_fraction_h)^(24 * day)

  data.frame(
    scenario = scenario,
    day = day,
    biomass_kg_dm_ha = numerical,
    analytic_kg_dm_ha = analytic,
    deviation_kg_dm_ha = numerical - equilibrium_kg_dm_ha,
    absolute_error_kg_dm_ha = abs(numerical - analytic)
  )
})
trajectory <- do.call(rbind, trajectory_rows)
row.names(trajectory) <- NULL

low_hourly <- runs$low$hourly$forage_biomass_end_kg_dm_ha
high_hourly <- runs$high$hourly$forage_biomass_end_kg_dm_ha
equilibrium_hourly <- runs$equilibrium$hourly$forage_biomass_end_kg_dm_ha
all_residuals <- unlist(lapply(
  runs,
  function(run) run$hourly$forage_biomass_balance_residual_kg_dm_ha
))

if (
  max(trajectory$absolute_error_kg_dm_ha) > 1e-8 ||
    any(diff(low_hourly) <= 0) ||
    any(diff(high_hourly) >= 0) ||
    max(low_hourly) > equilibrium_kg_dm_ha ||
    min(high_hourly) < equilibrium_kg_dm_ha ||
    max(abs(low_hourly + high_hourly - 2 * equilibrium_kg_dm_ha)) > 1e-8 ||
    max(abs(equilibrium_hourly - equilibrium_kg_dm_ha)) > 1e-8 ||
    max(abs(all_residuals)) > 1e-10
) {
  stop("Forage-turnover reference diagnostic failed.", call. = FALSE)
}

display <- trajectory[
  trajectory$day %in% reporting_days,
  c("scenario", "day", "biomass_kg_dm_ha", "deviation_kg_dm_ha")
]
display$biomass_kg_dm_ha <- round(display$biomass_kg_dm_ha, 1)
display$deviation_kg_dm_ha <- round(display$deviation_kg_dm_ha, 1)

cat("Isolated forage-turnover reference diagnostic passed.\n")
cat("Biomass and deviations are kg DM ha^-1.\n")
print(display, row.names = FALSE)
cat(sprintf(
  "\nEquilibrium growth and loss: %.0f kg DM ha^-1 d^-1 each.\n",
  24 * turnover_fraction_h * equilibrium_kg_dm_ha
))
cat(sprintf(
  "Day-180 remaining perturbation: %.1f%%.\n",
  100 * (1 - turnover_fraction_h)^(24 * horizon_days)
))
