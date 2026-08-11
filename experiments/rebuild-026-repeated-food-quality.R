arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-025-patch-food-energy-density.R")

require_goal026 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 026 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

goal026_days <- 10L
goal026_design <- data.frame(
  arm_id = c("adequate_quality", "lower_quality"),
  metabolizable_energy_density_kj_kg_dm = c(10000, 8000),
  stringsAsFactors = FALSE
)

run_repeated_quality <- function(energy_density_kj_kg_dm) {
  herbivoreTTR::run_appetite_controlled_energy_days(
    initial_gut_state = reference_opening_gut_state,
    initial_body_state = reference_opening_body_state,
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    food_parameters = herbivoreTTR::new_food_energy_parameters(
      energy_density_kj_kg_dm
    ),
    appetite_parameters = appetite_parameters,
    appetite_reference_schedule = appetite_reference_schedule,
    forage_acquisition_ceiling_schedule =
      nonlimiting_forage_acquisition_ceiling_schedule,
    routine_activity_schedule = routine_activity_schedule,
    number_of_days = goal026_days
  )
}

goal026_results <- lapply(
  goal026_design$metabolizable_energy_density_kj_kg_dm,
  run_repeated_quality
)
names(goal026_results) <- goal026_design$arm_id

build_goal026_daily <- function(arm_id, energy_density_kj_kg_dm, result) {
  daily <- result$daily
  opening_combined_deviation_kj <-
    daily$gut_available_energy_initial_kj -
      reference_opening_gut_energy_kj +
      daily$body_energy_reserve_initial_kj -
      reference_opening_body_energy_kj
  closing_combined_deviation_kj <-
    daily$combined_energy_deviation_from_reference_final_kj
  daily_change_kj <- daily$observed_total_system_energy_change_kj

  data.frame(
    arm_id = arm_id,
    simulation_day = daily$simulation_day,
    metabolizable_energy_density_kj_kg_dm = energy_density_kj_kg_dm,
    opening_combined_energy_deviation_kj =
      opening_combined_deviation_kj,
    appetite_target_dry_matter_intake_kg_dm =
      daily$appetite_target_dry_matter_intake_kg_dm,
    realized_dry_matter_intake_kg_dm =
      daily$realized_dry_matter_intake_kg_dm,
    realized_ingested_available_energy_kj =
      daily$total_realized_ingested_available_energy_kj,
    daily_combined_energy_change_kj = daily_change_kj,
    daily_energy_shortfall_kj = pmax(0, -daily_change_kj),
    gut_energy_deviation_final_kj =
      daily$gut_energy_deviation_from_reference_final_kj,
    body_energy_deviation_final_kj =
      daily$body_energy_deviation_from_reference_final_kj,
    combined_energy_deviation_final_kj =
      closing_combined_deviation_kj,
    cumulative_energy_deficit_kj =
      pmax(0, -closing_combined_deviation_kj),
    lower_intake_bound_hours = daily$lower_intake_bound_hours,
    upper_intake_bound_hours = daily$upper_intake_bound_hours,
    forage_acquisition_ceiling_active_hours =
      daily$forage_acquisition_ceiling_active_hours,
    routine_activity_expenditure_kj =
      daily$total_prescribed_routine_activity_expenditure_kj,
    gut_energy_balance_residual_kj =
      daily$gut_energy_balance_residual_kj,
    body_energy_balance_residual_kj =
      daily$body_energy_balance_residual_kj,
    system_energy_balance_residual_kj =
      daily$system_energy_balance_residual_kj,
    body_energy_reserve_final_kj =
      daily$body_energy_reserve_final_kj,
    stringsAsFactors = FALSE
  )
}

goal026_daily <- do.call(
  rbind,
  lapply(seq_len(nrow(goal026_design)), function(row_index) {
    arm_id <- goal026_design$arm_id[[row_index]]
    build_goal026_daily(
      arm_id,
      goal026_design$metabolizable_energy_density_kj_kg_dm[[row_index]],
      goal026_results[[arm_id]]
    )
  })
)
row.names(goal026_daily) <- NULL

lower_daily <- goal026_daily[
  goal026_daily$arm_id == "lower_quality",
  ,
  drop = FALSE
]
day_one_shortfall_kj <- lower_daily$daily_energy_shortfall_kj[[1L]]
day_ten_shortfall_kj <- lower_daily$daily_energy_shortfall_kj[[goal026_days]]
day_ten_recovery_fraction <-
  (day_one_shortfall_kj - day_ten_shortfall_kj) /
    day_one_shortfall_kj
recovery_threshold_kj <- 0.10 * day_one_shortfall_kj
threshold_days <- lower_daily$simulation_day[
  lower_daily$daily_energy_shortfall_kj <= recovery_threshold_kj
]
first_90_percent_recovery_day <- if (length(threshold_days)) {
  threshold_days[[1L]]
} else {
  NA_integer_
}

goal026_assessment <- data.frame(
  day_one_daily_shortfall_kj = day_one_shortfall_kj,
  day_ten_daily_shortfall_kj = day_ten_shortfall_kj,
  day_ten_recovery_fraction = day_ten_recovery_fraction,
  recovery_target_fraction = 0.90,
  recovery_target_met = day_ten_recovery_fraction >= 0.90,
  first_90_percent_recovery_day = first_90_percent_recovery_day,
  day_ten_upper_intake_bound_hours =
    lower_daily$upper_intake_bound_hours[[goal026_days]],
  day_ten_acquisition_ceiling_active_hours =
    lower_daily$forage_acquisition_ceiling_active_hours[[goal026_days]],
  stringsAsFactors = FALSE
)

adequate_result <- goal026_results$adequate_quality
canonical_hourly <- balanced_appetite_control$hourly
hourly_identity_fields <- setdiff(
  names(canonical_hourly),
  c("simulation_day", "time_start_h", "time_end_h")
)
adequate_hourly_identity <- vapply(seq_len(goal026_days), function(day_index) {
  day_rows <- adequate_result$hourly$simulation_day == day_index
  identical(
    as.list(adequate_result$hourly[day_rows, hourly_identity_fields]),
    as.list(canonical_hourly[, hourly_identity_fields])
  )
}, logical(1L))
canonical_daily <- balanced_appetite_control$daily
daily_identity_fields <- setdiff(names(canonical_daily), "simulation_day")
adequate_daily_identity <- vapply(seq_len(goal026_days), function(day_index) {
  day_row <- adequate_result$daily$simulation_day == day_index
  identical(
    as.list(adequate_result$daily[day_row, daily_identity_fields]),
    as.list(canonical_daily[, daily_identity_fields])
  )
}, logical(1L))
require_goal026(
  all(adequate_hourly_identity) && all(adequate_daily_identity),
  "exact repeated adequate-quality reference identity"
)

lower_day_one <- lower_daily[lower_daily$simulation_day == 1L, ]
goal025_lower <- goal025_daily[goal025_daily$arm_id == "lower_then_lower", ]
require_goal026(
  near(
    lower_day_one$realized_dry_matter_intake_kg_dm,
    goal025_lower$realized_dry_matter_intake_kg_dm,
    scale = 1
  ) &&
    near(
      lower_day_one$realized_ingested_available_energy_kj,
      goal025_lower$realized_ingested_available_energy_kj,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      lower_day_one$combined_energy_deviation_final_kj,
      goal025_lower$combined_energy_deviation_final_kj,
      scale = reference_opening_body_energy_kj
    ) &&
    identical(
      lower_day_one$upper_intake_bound_hours,
      goal025_lower$upper_intake_bound_hours
    ),
  "exact Goal 025 homogeneous lower-quality day-one identity"
)

carryover_identity <- vapply(goal026_results, function(result) {
  daily <- result$daily
  identical(
    unname(daily$gut_available_energy_initial_kj[-1L]),
    unname(daily$gut_available_energy_final_kj[-goal026_days])
  ) &&
    identical(
      unname(daily$body_energy_reserve_initial_kj[-1L]),
      unname(daily$body_energy_reserve_final_kj[-goal026_days])
    )
}, logical(1L))
require_goal026(all(carryover_identity), "exact daily state carry-over")

require_goal026(
  all(goal026_daily$forage_acquisition_ceiling_active_hours == 0L) &&
    all(goal026_daily$lower_intake_bound_hours == 0L) &&
    all(goal026_daily$upper_intake_bound_hours >= 0L) &&
    all(goal026_daily$upper_intake_bound_hours <= 16L) &&
    all(goal026_daily$routine_activity_expenditure_kj == 800) &&
    all(goal026_daily$body_energy_reserve_final_kj > 0),
  "non-limiting acquisition, valid bounds, activity, and positive reserve"
)
require_goal026(
  near(
    goal026_daily$gut_energy_balance_residual_kj,
    0,
    scale = reference_opening_body_energy_kj
  ) &&
    near(
      goal026_daily$body_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      goal026_daily$system_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    is.finite(day_ten_recovery_fraction),
  "closed accounting and finite recovery assessment"
)

goal026_diagnostics <- list(
  design = goal026_design,
  results = goal026_results,
  daily = goal026_daily,
  assessment = goal026_assessment
)

adequate_day_ten <- goal026_daily[
  goal026_daily$arm_id == "adequate_quality" &
    goal026_daily$simulation_day == goal026_days,
  ,
  drop = FALSE
]
lower_day_ten <- lower_daily[lower_daily$simulation_day == goal026_days, ]
recovery_day_label <- if (is.na(first_90_percent_recovery_day)) {
  "not reached"
} else {
  as.character(first_90_percent_recovery_day)
}

cat("Goal 026 diagnostics passed.\n")
cat(sprintf(
  paste0(
    "  Adequate day 10: realized %.3f kg DM; energy %.0f kJ; ",
    "daily %+.0f kJ; combined %+.0f kJ.\n"
  ),
  adequate_day_ten$realized_dry_matter_intake_kg_dm,
  adequate_day_ten$realized_ingested_available_energy_kj,
  adequate_day_ten$daily_combined_energy_change_kj,
  adequate_day_ten$combined_energy_deviation_final_kj
))
cat(sprintf(
  paste0(
    "  Lower day 1 -> 10: realized %.3f -> %.3f kg DM; ",
    "daily change %+.0f -> %+.0f kJ; cumulative deficit %.0f kJ.\n"
  ),
  lower_day_one$realized_dry_matter_intake_kg_dm,
  lower_day_ten$realized_dry_matter_intake_kg_dm,
  lower_day_one$daily_combined_energy_change_kj,
  lower_day_ten$daily_combined_energy_change_kj,
  lower_day_ten$cumulative_energy_deficit_kj
))
cat(sprintf(
  paste0(
    "  Day-10 recovery %.1f%%; 90%% threshold %s on day %s; ",
    "upper bound %d h; acquisition ceiling %d h.\n"
  ),
  100 * day_ten_recovery_fraction,
  if (goal026_assessment$recovery_target_met) "met" else "not met",
  recovery_day_label,
  lower_day_ten$upper_intake_bound_hours,
  lower_day_ten$forage_acquisition_ceiling_active_hours
))
