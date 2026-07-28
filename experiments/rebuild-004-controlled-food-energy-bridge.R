arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

new_bridge <- function(density_kj_kg_dm, intake_rates_kg_dm_h) {
  parameters <- herbivoreTTR::new_food_energy_parameters(
    density_kj_kg_dm
  )
  intake_schedule <- herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day = 0:23,
    prescribed_dry_matter_intake_kg_dm_h = intake_rates_kg_dm_h
  )

  list(
    parameters = parameters,
    intake_schedule = intake_schedule,
    energy_schedule =
      herbivoreTTR::derive_ingested_available_energy_schedule(
        parameters,
        intake_schedule
      )
  )
}

new_manual_energy_schedule <- function(energy_rates_kj_h) {
  herbivoreTTR::new_ingested_available_energy_schedule(
    hour_of_day = 0:23,
    prescribed_ingested_available_energy_kj_h = energy_rates_kj_h
  )
}

run_downstream <- function(
  energy_schedule,
  initial_gut_energy_kj,
  maintenance_expenditure_kj_h
) {
  herbivoreTTR::run_gut_body_energy_day(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(
      initial_gut_energy_kj
    ),
    initial_body_state = herbivoreTTR::new_body_energy_state(5000),
    gut_parameters = herbivoreTTR::new_gut_energy_parameters(0.25),
    body_parameters = herbivoreTTR::new_body_energy_parameters(
      maintenance_expenditure_kj_h
    ),
    schedule = energy_schedule,
    routine_activity_schedule =
      herbivoreTTR::new_routine_activity_expenditure_schedule(
        0:23,
        rep(0, 24L)
      )
  )
}

format_whole_kj <- function(values) {
  sprintf("%.0f", values)
}

format_rate_checkpoints <- function(values) {
  paste(
    format(values, trim = TRUE, scientific = FALSE),
    collapse = "/"
  )
}

zero <- new_bridge(
  density_kj_kg_dm = 10000,
  intake_rates_kg_dm_h = rep(0, 24L)
)
constant <- new_bridge(
  density_kj_kg_dm = 10000,
  intake_rates_kg_dm_h = rep(0.010, 24L)
)
pulse <- new_bridge(
  density_kj_kg_dm = 10000,
  intake_rates_kg_dm_h = c(0.040, rep(0, 23L))
)
factorized_alternative <- new_bridge(
  density_kj_kg_dm = 5000,
  intake_rates_kg_dm_h = rep(0.020, 24L)
)

zero_manual <- new_manual_energy_schedule(rep(0, 24L))
constant_manual <- new_manual_energy_schedule(rep(100, 24L))
pulse_manual <- new_manual_energy_schedule(c(400, rep(0, 23L)))

stopifnot(
  identical(zero$energy_schedule, zero_manual),
  identical(constant$energy_schedule, constant_manual),
  identical(pulse$energy_schedule, pulse_manual),
  !identical(constant$parameters, factorized_alternative$parameters),
  !identical(
    constant$intake_schedule,
    factorized_alternative$intake_schedule
  ),
  identical(
    constant$energy_schedule,
    factorized_alternative$energy_schedule
  )
)

daily_constant_intake_kg_dm <- sum(rep(0.010, 24L))
daily_intake_tolerance <- 100 * .Machine$double.eps * max(
  1,
  abs(daily_constant_intake_kg_dm),
  0.24
)
stopifnot(
  abs(daily_constant_intake_kg_dm - 0.24) <= daily_intake_tolerance,
  identical(
    sum(
      zero$energy_schedule$
        prescribed_ingested_available_energy_kj_h
    ),
    0
  ),
  identical(
    sum(
      constant$energy_schedule$
        prescribed_ingested_available_energy_kj_h
    ),
    2400
  ),
  identical(
    sum(
      pulse$energy_schedule$
        prescribed_ingested_available_energy_kj_h
    ),
    400
  )
)

zero_downstream <- run_downstream(
  zero$energy_schedule,
  initial_gut_energy_kj = 0,
  maintenance_expenditure_kj_h = 0
)
zero_manual_downstream <- run_downstream(
  zero_manual,
  initial_gut_energy_kj = 0,
  maintenance_expenditure_kj_h = 0
)
constant_downstream <- run_downstream(
  constant$energy_schedule,
  initial_gut_energy_kj = 400,
  maintenance_expenditure_kj_h = 100
)
constant_manual_downstream <- run_downstream(
  constant_manual,
  initial_gut_energy_kj = 400,
  maintenance_expenditure_kj_h = 100
)
pulse_downstream <- run_downstream(
  pulse$energy_schedule,
  initial_gut_energy_kj = 0,
  maintenance_expenditure_kj_h = 0
)
pulse_manual_downstream <- run_downstream(
  pulse_manual,
  initial_gut_energy_kj = 0,
  maintenance_expenditure_kj_h = 0
)
factorized_downstream <- run_downstream(
  factorized_alternative$energy_schedule,
  initial_gut_energy_kj = 400,
  maintenance_expenditure_kj_h = 100
)

stopifnot(
  identical(zero_downstream, zero_manual_downstream),
  identical(constant_downstream, constant_manual_downstream),
  identical(pulse_downstream, pulse_manual_downstream),
  identical(factorized_downstream, constant_downstream),
  identical(
    constant_downstream$hourly$gut_available_energy_start_kj,
    rep(400, 24L)
  ),
  identical(
    constant_downstream$hourly$gut_available_energy_end_kj,
    rep(400, 24L)
  ),
  identical(
    constant_downstream$hourly$body_energy_reserve_end_kj,
    rep(5000, 24L)
  ),
  identical(
    pulse_downstream$hourly$assimilated_energy_kj_h[1:4],
    c(0, 100, 75, 56.25)
  )
)

bridges <- list(
  zero = zero,
  constant = constant,
  pulse = pulse,
  factorized_alternative = factorized_alternative
)
conversion_summary <- data.frame(
  scenario_id = names(bridges),
  metabolizable_energy_density_kj_kg_dm = vapply(
    bridges,
    function(bridge) {
      bridge$parameters$metabolizable_energy_density_kj_kg_dm
    },
    numeric(1L)
  ),
  prescribed_dry_matter_total_kg_dm = vapply(
    bridges,
    function(bridge) {
      sum(
        bridge$intake_schedule$
          prescribed_dry_matter_intake_kg_dm_h
      )
    },
    numeric(1L)
  ),
  peak_dry_matter_intake_rate_kg_dm_h = vapply(
    bridges,
    function(bridge) {
      max(
        bridge$intake_schedule$
          prescribed_dry_matter_intake_kg_dm_h
      )
    },
    numeric(1L)
  ),
  peak_available_energy_rate_kj_h = vapply(
    bridges,
    function(bridge) {
      max(
        bridge$energy_schedule$
          prescribed_ingested_available_energy_kj_h
      )
    },
    numeric(1L)
  ),
  derived_available_energy_total_kj = format_whole_kj(vapply(
    bridges,
    function(bridge) {
      sum(
        bridge$energy_schedule$
          prescribed_ingested_available_energy_kj_h
      )
    },
    numeric(1L)
  )),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

downstream_results <- list(
  zero = zero_downstream,
  constant = constant_downstream,
  pulse = pulse_downstream,
  factorized = factorized_downstream
)
downstream_summary <- data.frame(
  comparison_id = c(
    "zero_vs_manual",
    "constant_vs_manual",
    "pulse_vs_manual",
    "factorized_vs_constant"
  ),
  schedule_identical = rep(TRUE, 4L),
  downstream_identical = rep(TRUE, 4L),
  assimilation_rates_h0_to_h3_kj_h = vapply(
    downstream_results,
    function(result) {
      format_rate_checkpoints(
        result$hourly$assimilated_energy_kj_h[1:4]
      )
    },
    character(1L)
  ),
  gut_available_energy_final_kj = format_whole_kj(vapply(
    downstream_results,
    function(result) {
      result$daily$gut_available_energy_final_kj
    },
    numeric(1L)
  )),
  body_energy_reserve_final_kj = format_whole_kj(vapply(
    downstream_results,
    function(result) {
      result$daily$body_energy_reserve_final_kj
    },
    numeric(1L)
  )),
  total_system_energy_final_kj = format_whole_kj(vapply(
    downstream_results,
    function(result) {
      result$daily$total_system_energy_final_kj
    },
    numeric(1L)
  )),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

cat("GOAL 004 FOOD-ENERGY BRIDGE: analytical checks passed\n\n")
cat(
  paste0(
    "Conversion summary (dry matter in kg DM; rates retain temporal ",
    "precision; energy totals in whole kJ):\n"
  )
)
write.table(
  conversion_summary,
  file = "",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)
cat(
  paste0(
    "\nDownstream equivalence summary (assimilation rates h0-h3 in ",
    "kJ h^-1; final stocks in whole kJ):\n"
  )
)
write.table(
  downstream_summary,
  file = "",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)
