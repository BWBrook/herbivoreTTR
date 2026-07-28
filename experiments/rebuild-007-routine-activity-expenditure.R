arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

scenario_ids <- c(
  "zero_routine_activity",
  "four_hour_routine_activity_pulse"
)

activity_rates <- list(
  zero_routine_activity = rep(0, 24L),
  four_hour_routine_activity_pulse = c(
    rep(0, 8L),
    rep(50, 4L),
    rep(0, 12L)
  )
)

day_rows <- function(result, table, day) {
  value <- result[[table]]
  value[value$measurement_day == day, , drop = FALSE]
}

gut_boundaries_kj <- function(hourly) {
  c(
    hourly$gut_available_energy_start_kj[[1L]],
    hourly$gut_available_energy_end_kj
  )
}

body_boundaries_kj <- function(hourly) {
  c(
    hourly$body_energy_reserve_start_kj[[1L]],
    hourly$body_energy_reserve_end_kj
  )
}

gut_columns <- c(
  "measurement_day",
  "hour_of_day",
  "gut_available_energy_start_kj",
  "prescribed_ingested_available_energy_kj_h",
  "gut_release_fraction_h",
  "assimilated_energy_kj_h",
  "prescribed_ingested_available_energy_kj",
  "assimilated_energy_kj",
  "gut_energy_change_kj",
  "gut_available_energy_end_kj",
  "gut_energy_balance_residual_kj"
)

canonical_equal <- function(left, right) {
  row.names(left) <- NULL
  row.names(right) <- NULL
  identical(left, right)
}

new_fixture <- function(scenario_id) {
  dry_matter_schedule <- herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day = 0:23,
    prescribed_dry_matter_intake_kg_dm_h = rep(0.010, 24L)
  )
  energy_schedule <- herbivoreTTR::derive_ingested_available_energy_schedule(
    herbivoreTTR::new_food_energy_parameters(10000),
    dry_matter_schedule
  )
  routine_activity_schedule <-
    herbivoreTTR::new_routine_activity_expenditure_schedule(
      hour_of_day = 0:23,
      prescribed_routine_activity_expenditure_kj_h =
        activity_rates[[scenario_id]]
    )
  result <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(0),
    measurement_body_state = herbivoreTTR::new_body_energy_state(10000),
    gut_parameters = herbivoreTTR::new_gut_energy_parameters(0.25),
    body_parameters = herbivoreTTR::new_body_energy_parameters(100),
    schedule = energy_schedule,
    routine_activity_schedule = routine_activity_schedule,
    gut_convergence_relative_tolerance =
      100 * .Machine$double.eps,
    max_burn_in_days = 100L
  )

  list(
    scenario_id = scenario_id,
    dry_matter_schedule = dry_matter_schedule,
    energy_schedule = energy_schedule,
    routine_activity_schedule = routine_activity_schedule,
    result = result
  )
}

fixtures <- lapply(scenario_ids, new_fixture)
names(fixtures) <- scenario_ids
zero <- fixtures$zero_routine_activity
pulse <- fixtures$four_hour_routine_activity_pulse

validate_fixture <- function(fixture) {
  result <- fixture$result
  activity <- fixture$routine_activity_schedule$
    prescribed_routine_activity_expenditure_kj_h

  stopifnot(
    identical(fixture$dry_matter_schedule$hour_of_day, 0:23),
    identical(
      fixture$dry_matter_schedule$
        prescribed_dry_matter_intake_kg_dm_h,
      rep(0.010, 24L)
    ),
    identical(
      fixture$energy_schedule$
        prescribed_ingested_available_energy_kj_h,
      rep(100, 24L)
    ),
    identical(fixture$routine_activity_schedule$hour_of_day, 0:23),
    identical(activity, activity_rates[[fixture$scenario_id]]),
    identical(result$convergence$burn_in_day, seq_len(7L)),
    identical(result$convergence$converged, c(rep(FALSE, 6L), TRUE)),
    identical(dim(result$hourly), c(48L, 25L)),
    identical(dim(result$daily), c(2L, 21L)),
    identical(
      result$hourly$prescribed_routine_activity_expenditure_kj_h,
      rep(activity, 2L)
    ),
    identical(
      result$hourly$prescribed_routine_activity_expenditure_kj,
      rep(activity, 2L)
    ),
    identical(
      result$daily$total_prescribed_ingested_available_energy_kj,
      c(2400, 2400)
    ),
    identical(
      result$daily$total_maintenance_expenditure_kj,
      c(2400, 2400)
    ),
    identical(
      result$daily$total_prescribed_routine_activity_expenditure_kj,
      rep(sum(activity), 2L)
    ),
    identical(
      result$hourly$gut_available_energy_start_kj[-1L],
      head(result$hourly$gut_available_energy_end_kj, -1L)
    ),
    identical(
      result$hourly$body_energy_reserve_start_kj[-1L],
      head(result$hourly$body_energy_reserve_end_kj, -1L)
    ),
    canonical_equal(
      day_rows(result, "hourly", 1L)[setdiff(gut_columns, "measurement_day")],
      day_rows(result, "hourly", 2L)[setdiff(gut_columns, "measurement_day")]
    )
  )

  for (day in 1:2) {
    hourly <- day_rows(result, "hourly", day)
    daily <- day_rows(result, "daily", day)
    expected_gut_change <-
      sum(hourly$prescribed_ingested_available_energy_kj) -
        sum(hourly$assimilated_energy_kj)
    observed_gut_change <- daily$gut_available_energy_final_kj -
      daily$gut_available_energy_initial_kj
    expected_body_change <- sum(hourly$assimilated_energy_kj) -
      sum(hourly$maintenance_expenditure_kj) -
      sum(hourly$prescribed_routine_activity_expenditure_kj)
    expected_system_change <-
      sum(hourly$prescribed_ingested_available_energy_kj) -
        sum(hourly$maintenance_expenditure_kj) -
        sum(hourly$prescribed_routine_activity_expenditure_kj)
    gut_scale <- max(
      1,
      abs(daily$gut_available_energy_initial_kj),
      abs(daily$gut_available_energy_final_kj),
      sum(abs(hourly$prescribed_ingested_available_energy_kj)),
      sum(abs(hourly$assimilated_energy_kj))
    )
    body_scale <- max(
      1,
      abs(daily$body_energy_reserve_initial_kj),
      abs(daily$body_energy_reserve_final_kj),
      sum(abs(hourly$assimilated_energy_kj)),
      sum(abs(hourly$maintenance_expenditure_kj)),
      sum(abs(hourly$prescribed_routine_activity_expenditure_kj))
    )
    system_scale <- max(
      1,
      abs(daily$total_system_energy_initial_kj),
      abs(daily$total_system_energy_final_kj),
      sum(abs(hourly$prescribed_ingested_available_energy_kj)),
      sum(abs(hourly$assimilated_energy_kj)),
      sum(abs(hourly$maintenance_expenditure_kj)),
      sum(abs(hourly$prescribed_routine_activity_expenditure_kj))
    )

    stopifnot(
      identical(daily$expected_gut_energy_change_kj, expected_gut_change),
      identical(daily$observed_gut_energy_change_kj, observed_gut_change),
      abs(
        daily$gut_energy_balance_residual_kj -
          (observed_gut_change - expected_gut_change)
      ) <= 100 * .Machine$double.eps * gut_scale,
      abs(daily$gut_energy_balance_residual_kj) <=
        100 * .Machine$double.eps * gut_scale,
      identical(daily$expected_body_energy_change_kj, expected_body_change),
      abs(daily$body_energy_balance_residual_kj) <=
        100 * .Machine$double.eps * body_scale,
      identical(
        daily$expected_total_system_energy_change_kj,
        expected_system_change
      ),
      abs(daily$system_energy_balance_residual_kj) <=
        100 * .Machine$double.eps * system_scale,
      all(body_boundaries_kj(hourly) >= 0)
    )
  }

  invisible(NULL)
}

invisible(lapply(fixtures, validate_fixture))

stopifnot(
  identical(pulse$result$convergence, zero$result$convergence),
  identical(pulse$result$hourly[gut_columns], zero$result$hourly[gut_columns]),
  identical(
    pulse$result$hourly$net_body_energy_rate_kj_h -
      zero$result$hourly$net_body_energy_rate_kj_h,
    rep(c(rep(0, 8L), rep(-50, 4L), rep(0, 12L)), 2L)
  ),
  identical(
    pulse$result$hourly$body_energy_change_kj -
      zero$result$hourly$body_energy_change_kj,
    rep(c(rep(0, 8L), rep(-50, 4L), rep(0, 12L)), 2L)
  ),
  identical(
    pulse$result$daily$observed_body_energy_change_kj -
      zero$result$daily$observed_body_energy_change_kj,
    c(-200, -200)
  ),
  identical(
    pulse$result$daily$body_energy_reserve_final_kj -
      zero$result$daily$body_energy_reserve_final_kj,
    c(-200, -400)
  ),
  identical(zero$result$daily$body_energy_reserve_final_kj, c(10000, 10000)),
  identical(pulse$result$daily$body_energy_reserve_final_kj, c(9800, 9600)),
  identical(
    pulse$result$hourly$body_energy_reserve_start_kj[c(9L, 33L)],
    c(10000, 9800)
  ),
  identical(
    pulse$result$hourly$body_energy_reserve_end_kj[c(12L, 36L)],
    c(9800, 9600)
  )
)

schedule_summary <- data.frame(
  scenario_id = scenario_ids,
  active_intervals = vapply(
    activity_rates,
    function(value) sum(value > 0),
    integer(1L)
  ),
  daily_routine_activity_kj = vapply(activity_rates, sum, numeric(1L))
)

daily_summary <- do.call(rbind, lapply(fixtures, function(fixture) {
  data.frame(
    scenario_id = fixture$scenario_id,
    measurement_day = fixture$result$daily$measurement_day,
    routine_activity_kj =
      fixture$result$daily$
        total_prescribed_routine_activity_expenditure_kj,
    body_change_kj =
      fixture$result$daily$observed_body_energy_change_kj,
    body_reserve_final_kj =
      fixture$result$daily$body_energy_reserve_final_kj
  )
}))

counterfactual_summary <- data.frame(
  measurement_day = 1:2,
  gut_boundary_max_abs_difference_kj = vapply(1:2, function(day) {
    max(abs(
      gut_boundaries_kj(day_rows(pulse$result, "hourly", day)) -
        gut_boundaries_kj(day_rows(zero$result, "hourly", day))
    ))
  }, numeric(1L)),
  body_change_difference_kj =
    pulse$result$daily$observed_body_energy_change_kj -
      zero$result$daily$observed_body_energy_change_kj,
  body_reserve_close_difference_kj =
    pulse$result$daily$body_energy_reserve_final_kj -
      zero$result$daily$body_energy_reserve_final_kj
)

print_whole_kj <- function(value) {
  printable <- value
  numeric_columns <- vapply(printable, is.numeric, logical(1L))
  printable[numeric_columns] <- lapply(
    printable[numeric_columns],
    function(column) as.integer(round(column))
  )
  print(printable, row.names = FALSE)
}

cat("Rebuild Goal 007: prescribed routine-activity diagnostic\n\n")
cat("Schedule summary\n")
print_whole_kj(schedule_summary)
cat("\nConvergence: both scenarios first converge on burn-in day 7.\n\n")
cat("Measured daily summary (whole kJ)\n")
print_whole_kj(daily_summary)
cat("\nPulse minus zero counterfactual (whole kJ)\n")
print_whole_kj(counterfactual_summary)
cat("\nAll Goal 007 in-memory assertions passed; no files were written.\n")
