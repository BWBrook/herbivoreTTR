source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
reference_density_animals_ha <- 10
pulse_density_animals_ha <- 50
reference_days <- 7L
pulse_days <- 60L
recovery_days <- 60L
total_days <- reference_days + pulse_days + recovery_days
residual_threshold_kg_dm_ha <- 500
equilibrium_biomass_kg_dm_ha <- 1000
turnover_fraction_h <- 0.001

turnover <- herbivoreTTR::new_forage_turnover_parameters(
  equilibrium_biomass_kg_dm_ha,
  turnover_fraction_h
)

new_coupling <- function(density_animals_ha) {
  herbivoreTTR::new_nonspatial_coupling_parameters(
    density_animals_ha,
    residual_threshold_kg_dm_ha
  )
}

run_coupled_phase <- function(opening, density_animals_ha, number_of_days) {
  herbivoreTTR::run_nonspatial_coupled_energy_days(
    initial_gut_state = opening$gut,
    initial_body_state = opening$body,
    initial_forage_state = opening$forage,
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    food_parameters = fixture$food,
    appetite_parameters = fixture$appetite,
    forage_turnover_parameters = turnover,
    coupling_parameters = new_coupling(density_animals_ha),
    appetite_reference_schedule = fixture$appetite_reference,
    forage_acquisition_ceiling_schedule = fixture$nonlimiting_forage,
    routine_activity_schedule = fixture$activity,
    number_of_days = number_of_days
  )
}

closing_state <- function(result) {
  last_day <- result$daily[nrow(result$daily), , drop = FALSE]
  list(
    gut = herbivoreTTR::new_gut_energy_state(
      last_day$gut_available_energy_final_kj[[1L]]
    ),
    body = herbivoreTTR::new_body_energy_state(
      last_day$body_energy_reserve_final_kj[[1L]]
    ),
    forage = herbivoreTTR::new_forage_biomass_state(
      last_day$forage_biomass_final_kg_dm_ha[[1L]]
    )
  )
}

number_phase <- function(result, phase, first_day) {
  day_offset <- first_day - 1L
  result$hourly$simulation_day <-
    result$hourly$simulation_day + day_offset
  result$hourly$time_start_h <- result$hourly$time_start_h + 24 * day_offset
  result$hourly$time_end_h <- result$hourly$time_end_h + 24 * day_offset
  result$hourly$phase <- phase
  result$daily$simulation_day <- result$daily$simulation_day + day_offset
  result$daily$phase <- phase
  result
}

retention <- 1 - turnover_fraction_h
hourly_increment <-
  turnover_fraction_h * equilibrium_biomass_kg_dm_ha -
    reference_density_animals_ha * fixture$reference_intake_kg_dm_h
periodic_opening_kg_dm_ha <-
  sum(retention^(23:0) * hourly_increment) /
    (1 - retention^24)
opening <- list(
  gut = fixture$opening_gut,
  body = fixture$opening_body,
  forage = herbivoreTTR::new_forage_biomass_state(
    periodic_opening_kg_dm_ha
  )
)

reference_phase <- run_coupled_phase(
  opening,
  reference_density_animals_ha,
  reference_days
)
pulse_phase <- run_coupled_phase(
  closing_state(reference_phase),
  pulse_density_animals_ha,
  pulse_days
)
recovery_phase <- run_coupled_phase(
  closing_state(pulse_phase),
  reference_density_animals_ha,
  recovery_days
)

reference_phase <- number_phase(reference_phase, "reference", 1L)
pulse_phase <- number_phase(
  pulse_phase,
  "load pulse",
  reference_days + 1L
)
recovery_phase <- number_phase(
  recovery_phase,
  "recovery",
  reference_days + pulse_days + 1L
)
treatment <- list(
  hourly = rbind(
    reference_phase$hourly,
    pulse_phase$hourly,
    recovery_phase$hourly
  ),
  daily = rbind(
    reference_phase$daily,
    pulse_phase$daily,
    recovery_phase$daily
  )
)
row.names(treatment$hourly) <- NULL
row.names(treatment$daily) <- NULL

control <- run_coupled_phase(
  opening,
  reference_density_animals_ha,
  total_days
)
phase_by_day <- rep(
  c("reference", "load pulse", "recovery"),
  c(reference_days, pulse_days, recovery_days)
)
control$daily$phase <- phase_by_day
control$hourly$phase <- rep(phase_by_day, each = 24L)

comparison_columns <- c(
  "forage_biomass_initial_kg_dm_ha",
  "forage_biomass_final_kg_dm_ha",
  "realized_dry_matter_intake_kg_dm",
  "gut_available_energy_final_kj",
  "body_energy_reserve_final_kj"
)
for (column in comparison_columns) {
  assert_that(
    near(
      treatment$daily[[column]][seq_len(reference_days)],
      control$daily[[column]][seq_len(reference_days)]
    ),
    paste("pre-pulse treatment-control identity for", column)
  )
}

assert_that(
  near(
    control$daily$forage_biomass_initial_kg_dm_ha,
    rep(periodic_opening_kg_dm_ha, total_days)
  ) &&
    near(
      control$daily$forage_biomass_final_kg_dm_ha,
      rep(periodic_opening_kg_dm_ha, total_days)
    ) &&
    near(
      control$daily$realized_dry_matter_intake_kg_dm,
      rep(0.32, total_days)
    ) &&
    near(
      control$daily$body_energy_reserve_final_kj,
      rep(40000, total_days)
    ) &&
    all(control$daily$forage_stock_ceiling_active_hours == 0L),
  "constant-density control remains on the period-24 reference"
)

pulse_rows <- treatment$daily$phase == "load pulse"
recovery_rows <- treatment$daily$phase == "recovery"
reference_end <- treatment$daily[reference_days, , drop = FALSE]
pulse_end <- treatment$daily[reference_days + pulse_days, , drop = FALSE]
recovery_end <- treatment$daily[total_days, , drop = FALSE]

assert_that(
  pulse_end$forage_biomass_final_kg_dm_ha <
    reference_end$forage_biomass_final_kg_dm_ha &&
    any(treatment$daily$forage_stock_ceiling_active_hours[pulse_rows] > 0L),
  "load pulse depletes forage and activates the stock ceiling"
)
assert_that(
  min(treatment$daily$realized_dry_matter_intake_kg_dm[pulse_rows]) < 0.32 &&
    min(treatment$daily$body_energy_reserve_final_kj[pulse_rows]) < 40000,
  "stock limitation reduces intake and body-energy reserve"
)
assert_that(
  recovery_end$forage_biomass_final_kg_dm_ha >
    pulse_end$forage_biomass_final_kg_dm_ha &&
    recovery_end$body_energy_reserve_final_kj >
      pulse_end$body_energy_reserve_final_kj &&
    abs(
      recovery_end$forage_biomass_final_kg_dm_ha -
        control$daily$forage_biomass_final_kg_dm_ha[[total_days]]
    ) < abs(
      pulse_end$forage_biomass_final_kg_dm_ha -
        control$daily$forage_biomass_final_kg_dm_ha[[total_days]]
    ) &&
    all(tail(
      treatment$daily$forage_stock_ceiling_active_hours[recovery_rows],
      7L
    ) == 0L),
  "forage and animal state recover directionally after load release"
)

all_hourly <- rbind(control$hourly, treatment$hourly)
assert_that(
  max(abs(all_hourly$forage_biomass_balance_residual_kg_dm_ha)) < 1e-10 &&
    max(abs(
      all_hourly$herbivore_forage_coupling_residual_kg_dm_ha
    )) < 1e-10 &&
    max(abs(all_hourly$system_energy_balance_residual_kj)) < 1e-8,
  "dry-matter and energy balances across control and treatment"
)

summarize_phase <- function(phase) {
  rows <- treatment$daily$phase == phase
  phase_data <- treatment$daily[rows, , drop = FALSE]
  data.frame(
    phase = phase,
    days = nrow(phase_data),
    density_animals_ha = unique(phase_data$herbivore_density_animals_ha),
    forage_start_kg_dm_ha = round(
      phase_data$forage_biomass_initial_kg_dm_ha[[1L]],
      1
    ),
    forage_minimum_kg_dm_ha = round(
      min(phase_data$forage_biomass_final_kg_dm_ha),
      1
    ),
    forage_end_kg_dm_ha = round(
      phase_data$forage_biomass_final_kg_dm_ha[[nrow(phase_data)]],
      1
    ),
    mean_daily_intake_kg_dm = round(
      mean(phase_data$realized_dry_matter_intake_kg_dm),
      3
    ),
    stock_limited_hours = sum(
      phase_data$forage_stock_ceiling_active_hours
    ),
    body_start_kj = round(
      phase_data$body_energy_reserve_initial_kj[[1L]]
    ),
    body_minimum_kj = round(
      min(phase_data$body_energy_reserve_final_kj)
    ),
    body_end_kj = round(
      phase_data$body_energy_reserve_final_kj[[nrow(phase_data)]]
    )
  )
}

phase_summary <- do.call(
  rbind,
  lapply(c("reference", "load pulse", "recovery"), summarize_phase)
)
row.names(phase_summary) <- NULL

reference_forage_end <-
  control$daily$forage_biomass_final_kg_dm_ha[[total_days]]
reference_body_end <- control$daily$body_energy_reserve_final_kj[[total_days]]
forage_recovery_fraction <-
  (recovery_end$forage_biomass_final_kg_dm_ha -
    pulse_end$forage_biomass_final_kg_dm_ha) /
  (reference_forage_end - pulse_end$forage_biomass_final_kg_dm_ha)
body_recovery_fraction <-
  (recovery_end$body_energy_reserve_final_kj -
    pulse_end$body_energy_reserve_final_kj) /
  (reference_body_end - pulse_end$body_energy_reserve_final_kj)
limited_days <- treatment$daily$simulation_day[
  treatment$daily$forage_stock_ceiling_active_hours > 0L
]

recovery_summary <- data.frame(
  first_stock_limited_day = min(limited_days),
  stock_limited_days = length(limited_days),
  minimum_daily_intake_kg_dm = round(
    min(treatment$daily$realized_dry_matter_intake_kg_dm),
    3
  ),
  minimum_body_reserve_kj = round(
    min(treatment$daily$body_energy_reserve_final_kj)
  ),
  forage_recovery_percent = round(100 * forage_recovery_fraction, 1),
  body_recovery_percent = round(100 * body_recovery_fraction, 1),
  end_forage_below_reference_kg_dm_ha = round(
    reference_forage_end - recovery_end$forage_biomass_final_kg_dm_ha,
    1
  ),
  end_body_below_reference_kj = round(
    reference_body_end - recovery_end$body_energy_reserve_final_kj
  )
)

cat("Controlled animal-load pulse diagnostic passed.\n\n")
cat("Treatment phases:\n")
print(phase_summary, row.names = FALSE)
cat("\nLimitation and recovery:\n")
print(recovery_summary, row.names = FALSE)
