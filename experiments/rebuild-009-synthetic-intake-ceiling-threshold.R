arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

require_that <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 009 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

near <- function(observed, expected, scale = NULL) {
  observed <- as.double(observed)
  expected <- as.double(expected)
  if (length(observed) != length(expected) ||
      any(!is.finite(observed)) || any(!is.finite(expected))) {
    return(FALSE)
  }
  if (is.null(scale)) {
    scale <- pmax(1, abs(observed), abs(expected))
  } else {
    scale <- pmax(1, as.double(scale))
  }
  length(scale) %in% c(1L, length(observed)) &&
    all(is.finite(scale)) &&
    all(abs(observed - expected) <= 100 * .Machine$double.eps * scale)
}

body_boundaries_kj <- function(hourly) {
  c(hourly$body_energy_reserve_start_kj[[1L]], hourly$body_energy_reserve_end_kj)
}

day_rows <- function(result, table_name, measurement_day) {
  value <- result[[table_name]][result[[table_name]]$measurement_day == measurement_day, , drop = FALSE]
  row.names(value) <- NULL
  value
}

canonical_equal <- function(left, right) {
  row.names(left) <- NULL
  row.names(right) <- NULL
  identical(left, right)
}

round_kj_amounts <- function(value) {
  amount_columns <- grep("_kj$", names(value), value = TRUE)
  value[amount_columns] <- lapply(value[amount_columns], round)
  value
}

clip_prescription <- function(candidate_kg_dm_h, ceiling_kg_dm_h) {
  require_that(length(candidate_kg_dm_h) == length(ceiling_kg_dm_h), "aligned clipping vectors")
  require_that(all(is.finite(candidate_kg_dm_h)) && all(candidate_kg_dm_h >= 0), "finite non-negative candidate")
  require_that(all(is.finite(ceiling_kg_dm_h)) && all(ceiling_kg_dm_h >= 0), "finite non-negative ceiling")
  pmin(candidate_kg_dm_h, ceiling_kg_dm_h)
}

scenario_ids <- c(
  "intake_ceiling_below_threshold",
  "intake_ceiling_at_threshold",
  "intake_ceiling_above_threshold"
)
active_hours <- c(0:7, 16:23)
rest_hours <- 8:15
hour_of_day <- 0:23
candidate_rates <- c(rep(0.020, 8L), rep(0, 8L), rep(0.020, 8L))
ceiling_rates <- list(
  intake_ceiling_below_threshold = c(rep(0.015, 8L), rep(0, 8L), rep(0.015, 8L)),
  intake_ceiling_at_threshold = c(rep(0.020, 8L), rep(0, 8L), rep(0.020, 8L)),
  intake_ceiling_above_threshold = c(rep(0.025, 8L), rep(0, 8L), rep(0.025, 8L))
)
ceiling_active_kg_dm_h <- c(0.015, 0.020, 0.025)
threshold_relation <- c("below", "at", "above")
oracle_scenario_ids <- c(
  ecological_activity_uncompensated = "ecological_activity_uncompensated",
  ecological_activity_prescribed_balance = "ecological_activity_prescribed_balance"
)

food_parameters <- herbivoreTTR::new_food_energy_parameters(10000)
candidate_schedule <- herbivoreTTR::new_dry_matter_intake_schedule(
  hour_of_day = hour_of_day,
  prescribed_dry_matter_intake_kg_dm_h = candidate_rates
)
candidate_energy_schedule <- herbivoreTTR::derive_ingested_available_energy_schedule(
  food_parameters,
  candidate_schedule
)
activity_rates <- c(rep(50, 8L), rep(0, 8L), rep(50, 8L))
activity_schedule <- herbivoreTTR::new_routine_activity_expenditure_schedule(
  hour_of_day = hour_of_day,
  prescribed_routine_activity_expenditure_kj_h = activity_rates
)

new_result <- function(dry_matter_rates) {
  schedule <- herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day = hour_of_day,
    prescribed_dry_matter_intake_kg_dm_h = dry_matter_rates
  )
  energy <- herbivoreTTR::derive_ingested_available_energy_schedule(
    food_parameters,
    schedule
  )
  result <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(0),
    measurement_body_state = herbivoreTTR::new_body_energy_state(10000),
    gut_parameters = herbivoreTTR::new_gut_energy_parameters(0.25),
    body_parameters = herbivoreTTR::new_body_energy_parameters(100),
    schedule = energy,
    routine_activity_schedule = activity_schedule,
    gut_convergence_relative_tolerance = 100 * .Machine$double.eps,
    max_burn_in_days = 100L
  )
  list(dry_matter_schedule = schedule, energy_schedule = energy, result = result)
}

fixtures <- lapply(seq_along(scenario_ids), function(index) {
  scenario_id <- scenario_ids[[index]]
  candidate <- candidate_rates
  ceiling <- ceiling_rates[[scenario_id]]
  constrained <- clip_prescription(candidate, ceiling)
  curtailed <- candidate - constrained
  list(
    scenario_id = scenario_id,
    ceiling_kg_dm_h = ceiling,
    constrained_kg_dm_h = constrained,
    curtailed_kg_dm_h = curtailed,
    ceiling_exceeded = candidate > ceiling,
    model = new_result(constrained)
  )
})
names(fixtures) <- scenario_ids

oracle_uncompensated <- new_result(c(rep(0.015, 8L), rep(0, 8L), rep(0.015, 8L)))
oracle_balanced <- new_result(candidate_rates)

threshold_daily_required_kj <- 24 * 100 + 16 * 50
threshold_active_ceiling_kg_dm_h <- threshold_daily_required_kj / (16 * 10000)
require_that(identical(threshold_daily_required_kj, 3200), "daily threshold requirement")
require_that(near(threshold_active_ceiling_kg_dm_h, 0.020), "analytical threshold reconstruction")

hourly_screen <- do.call(rbind, lapply(fixtures, function(fixture) {
  data.frame(
    scenario_id = fixture$scenario_id,
    hour_of_day = hour_of_day,
    candidate_prescribed_dry_matter_intake_kg_dm_h = candidate_rates,
    synthetic_intake_ceiling_kg_dm_h = fixture$ceiling_kg_dm_h,
    constrained_prescribed_dry_matter_intake_kg_dm_h = fixture$constrained_kg_dm_h,
    curtailed_prescribed_dry_matter_intake_kg_dm_h = fixture$curtailed_kg_dm_h,
    ceiling_exceeded = fixture$ceiling_exceeded,
    row.names = NULL
  )
}))
row.names(hourly_screen) <- NULL

threshold_summary <- do.call(rbind, lapply(seq_along(fixtures), function(index) {
  fixture <- fixtures[[index]]
  ceiling <- fixture$ceiling_kg_dm_h
  constrained <- fixture$constrained_kg_dm_h
  data.frame(
    scenario_id = fixture$scenario_id,
    active_ceiling_kg_dm_h = ceiling_active_kg_dm_h[[index]],
    active_ceiling_energy_equivalent_kj_h = ceiling_active_kg_dm_h[[index]] * 10000,
    threshold_multiple = ceiling_active_kg_dm_h[[index]] / threshold_active_ceiling_kg_dm_h,
    threshold_relation = threshold_relation[[index]],
    curtailed_active_intervals = sum(fixture$curtailed_kg_dm_h[active_hours + 1L] > 0),
    touching_active_intervals = sum(
      candidate_rates[active_hours + 1L] == ceiling[active_hours + 1L] &
        candidate_rates[active_hours + 1L] > 0
    ),
    daily_candidate_intake_kg_dm = sum(candidate_rates),
    daily_ceiling_capacity_kg_dm = sum(ceiling),
    daily_constrained_intake_kg_dm = sum(constrained),
    daily_curtailed_intake_kg_dm = sum(fixture$curtailed_kg_dm_h),
    daily_constrained_energy_kj = sum(constrained) * 10000,
    daily_energy_shortfall_kj = threshold_daily_required_kj - sum(constrained) * 10000,
    daily_unused_ceiling_headroom_kg_dm = sum(pmax(ceiling[active_hours + 1L] - constrained[active_hours + 1L], 0)),
    daily_unused_ceiling_headroom_kj = sum(pmax(ceiling[active_hours + 1L] - constrained[active_hours + 1L], 0)) * 10000,
    row.names = NULL
  )
}))
row.names(threshold_summary) <- NULL
threshold_summary <- round_kj_amounts(threshold_summary)

daily_accounting <- do.call(rbind, lapply(fixtures, function(fixture) {
  daily <- fixture$model$result$daily
  oracle <- if (fixture$scenario_id == scenario_ids[[1L]]) oracle_scenario_ids[[1L]] else oracle_scenario_ids[[2L]]
  data.frame(
    scenario_id = fixture$scenario_id,
    measurement_day = daily$measurement_day,
    daily_candidate_intake_kg_dm = sum(candidate_rates),
    daily_constrained_intake_kg_dm = sum(fixture$constrained_kg_dm_h),
    daily_curtailed_intake_kg_dm = sum(fixture$curtailed_kg_dm_h),
    total_constrained_energy_input_kj = daily$total_prescribed_ingested_available_energy_kj,
    total_assimilated_energy_kj = daily$total_assimilated_energy_kj,
    total_maintenance_expenditure_kj = vapply(seq_len(nrow(daily)), function(i) sum(day_rows(fixture$model$result, "hourly", daily$measurement_day[[i]])$maintenance_expenditure_kj), numeric(1L)),
    total_routine_activity_expenditure_kj = daily$total_prescribed_routine_activity_expenditure_kj,
    observed_body_energy_change_kj = daily$observed_body_energy_change_kj,
    body_energy_reserve_final_kj = daily$body_energy_reserve_final_kj,
    body_energy_status = daily$body_energy_status,
    goal008_oracle_scenario_id = oracle,
    exact_oracle_identity = rep(identical(fixture$model$result, if (oracle == oracle_scenario_ids[[1L]]) oracle_uncompensated$result else oracle_balanced$result), nrow(daily)),
    row.names = NULL
  )
}))
row.names(daily_accounting) <- NULL
daily_accounting <- round_kj_amounts(daily_accounting)

# Core schedule, accounting, stock, and exact-oracle assertions.
require_that(identical(candidate_schedule$hour_of_day, hour_of_day), "candidate hour labels")
require_that(identical(as.integer(which(candidate_rates > 0) - 1L), active_hours), "16 active candidate intervals")
require_that(identical(as.integer(which(candidate_rates == 0) - 1L), rest_hours), "rest closure")
require_that(all(is.finite(as.matrix(hourly_screen[, 3:6]))) && all(as.matrix(hourly_screen[, 3:6]) >= 0), "finite non-negative schedules")
require_that(identical(hourly_screen$ceiling_exceeded, hourly_screen$curtailed_prescribed_dry_matter_intake_kg_dm_h > 0), "ceiling exceedance definition")
require_that(identical(fixtures[[1L]]$model$result, oracle_uncompensated$result), "below exact Goal 008 identity")
require_that(identical(fixtures[[2L]]$model$result, oracle_balanced$result), "at exact Goal 008 identity")
require_that(identical(fixtures[[3L]]$model$result, oracle_balanced$result), "above exact Goal 008 identity")
require_that(identical(fixtures[[2L]]$model$result, fixtures[[3L]]$model$result), "at/above result identity")
require_that(!identical(body_boundaries_kj(fixtures[[1L]]$model$result$hourly), body_boundaries_kj(fixtures[[2L]]$model$result$hourly)), "below trajectory differs")
require_that(identical(body_boundaries_kj(fixtures[[2L]]$model$result$hourly), body_boundaries_kj(fixtures[[3L]]$model$result$hourly)), "at/above trajectories identical")
require_that(identical(threshold_summary$curtailed_active_intervals, c(16L, 0L, 0L)), "curtailed interval counts")
require_that(identical(threshold_summary$touching_active_intervals, c(0L, 16L, 0L)), "touching interval counts")
require_that(near(threshold_summary$daily_constrained_energy_kj, c(2400, 3200, 3200)), "daily constrained energy")
require_that(near(threshold_summary$daily_energy_shortfall_kj, c(800, 0, 0)), "daily energy shortfall")
require_that(near(threshold_summary$daily_unused_ceiling_headroom_kj, c(0, 0, 800)), "daily active headroom")
require_that(identical(daily_accounting$body_energy_status, rep(c("deficit", "deficit", "neutral", "neutral", "neutral", "neutral"), 1L)), "body statuses")
require_that(identical(daily_accounting$exact_oracle_identity, rep(TRUE, 6L)), "daily oracle identities")
require_that(near(daily_accounting$body_energy_reserve_final_kj, c(9200, 8400, 10000, 10000, 10000, 10000)), "body reserve closes")

goal009_evidence <- list(
  scenario_ids = scenario_ids,
  active_hours = active_hours,
  rest_hours = rest_hours,
  candidate_rates = candidate_rates,
  ceiling_rates = ceiling_rates,
  fixtures = fixtures,
  oracle_uncompensated = oracle_uncompensated,
  oracle_balanced = oracle_balanced,
  hourly_screen = hourly_screen,
  threshold_summary = threshold_summary,
  daily_accounting = daily_accounting,
  threshold_daily_required_kj = threshold_daily_required_kj,
  threshold_active_ceiling_kg_dm_h = threshold_active_ceiling_kg_dm_h
)

print_summary <- function(value) {
  printable <- value
  amount_columns <- grep("_kj$", names(printable), value = TRUE)
  printable[amount_columns] <- lapply(printable[amount_columns], function(column) round(column))
  print(printable, row.names = FALSE, digits = 7)
}

cat("Rebuild Goal 009: synthetic intake-ceiling threshold\n\n")
cat("Analytical threshold (whole kJ where applicable)\n")
print_summary(data.frame(
  daily_required_kj = threshold_daily_required_kj,
  active_threshold_kg_dm_h = threshold_active_ceiling_kg_dm_h,
  active_threshold_energy_kj_h = threshold_active_ceiling_kg_dm_h * 10000,
  row.names = NULL
))
cat("\nRepresentative hourly clipping (active hour 0; rest hour 8)\n")
print_summary(hourly_screen[
  hourly_screen$hour_of_day %in% c(0L, 8L),
  c(
    "scenario_id",
    "hour_of_day",
    "candidate_prescribed_dry_matter_intake_kg_dm_h",
    "synthetic_intake_ceiling_kg_dm_h",
    "constrained_prescribed_dry_matter_intake_kg_dm_h",
    "curtailed_prescribed_dry_matter_intake_kg_dm_h",
    "ceiling_exceeded"
  )
])
cat("\nDaily threshold summary\n")
print_summary(threshold_summary)
cat("\nDaily downstream outcomes (whole kJ)\n")
print_summary(daily_accounting)
cat("\nCeiling is an evidence-only client-side clipping prescription; curtailed intake is discarded and no physiological or behavioural capacity is inferred.\n")
cat("All Goal 009 in-memory assertions passed; no files were written.\n")
