if (!requireNamespace("herbivoreTTR", quietly = TRUE)) {
  stop(
    "Install herbivoreTTR before running the forage-availability diagnostic.",
    call. = FALSE
  )
}

equilibrium_kg_dm_ha <- 1000
turnover_fraction_h <- 0.001
residual_threshold_kg_dm_ha <- 500
horizon_days <- 180L
reporting_days <- c(0L, 1L, 30L, 90L, 180L)
initial_biomass <- c(low = 500, equilibrium = 1000, high = 1500)
turnover_parameters <- herbivoreTTR::new_forage_turnover_parameters(
  equilibrium_kg_dm_ha,
  turnover_fraction_h
)

trajectory_rows <- lapply(names(initial_biomass), function(scenario) {
  run <- herbivoreTTR::run_forage_turnover_days(
    herbivoreTTR::new_forage_biomass_state(initial_biomass[[scenario]]),
    turnover_parameters,
    horizon_days
  )
  standing <- c(
    initial_biomass[[scenario]],
    run$daily$forage_biomass_final_kg_dm_ha
  )
  availability <- herbivoreTTR::derive_accessible_forage_biomass(
    standing,
    residual_threshold_kg_dm_ha
  )

  data.frame(
    scenario = scenario,
    day = 0:horizon_days,
    standing_biomass_kg_dm_ha = standing,
    accessible_biomass_kg_dm_ha =
      availability$accessible_forage_biomass_kg_dm_ha
  )
})
trajectory <- do.call(rbind, trajectory_rows)
row.names(trajectory) <- NULL

if (
  any(trajectory$accessible_biomass_kg_dm_ha < 0) ||
    any(
      trajectory$accessible_biomass_kg_dm_ha >
        trajectory$standing_biomass_kg_dm_ha
    ) ||
    any(abs(
      trajectory$accessible_biomass_kg_dm_ha -
        pmax(
          0,
          trajectory$standing_biomass_kg_dm_ha -
            residual_threshold_kg_dm_ha
        )
    ) > 1e-10)
) {
  stop("Forage-availability boundary diagnostic failed.", call. = FALSE)
}

display <- trajectory[
  trajectory$day %in% reporting_days,
  c(
    "scenario",
    "day",
    "standing_biomass_kg_dm_ha",
    "accessible_biomass_kg_dm_ha"
  )
]
display$standing_biomass_kg_dm_ha <- round(
  display$standing_biomass_kg_dm_ha,
  1
)
display$accessible_biomass_kg_dm_ha <- round(
  display$accessible_biomass_kg_dm_ha,
  1
)

cat("Standing-to-accessible forage diagnostic passed.\n")
cat(sprintf(
  "Residual unavailable threshold: %.0f kg DM ha^-1.\n",
  residual_threshold_kg_dm_ha
))
print(display, row.names = FALSE)
