arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

new_fixture <- function(scenario_id, intake_rates_kg_dm_h) {
  food_parameters <- herbivoreTTR::new_food_energy_parameters(10000)
  dry_matter_schedule <- herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day = 0:23,
    prescribed_dry_matter_intake_kg_dm_h = intake_rates_kg_dm_h
  )
  energy_schedule <-
    herbivoreTTR::derive_ingested_available_energy_schedule(
      food_parameters,
      dry_matter_schedule
    )
  result <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(0),
    measurement_body_state = herbivoreTTR::new_body_energy_state(10000),
    gut_parameters = herbivoreTTR::new_gut_energy_parameters(0.25),
    body_parameters = herbivoreTTR::new_body_energy_parameters(100),
    schedule = energy_schedule,
    gut_convergence_relative_tolerance = 100 * .Machine$double.eps,
    max_burn_in_days = 100L
  )

  list(
    scenario_id = scenario_id,
    dry_matter_schedule = dry_matter_schedule,
    energy_schedule = energy_schedule,
    result = result
  )
}

day_hourly <- function(result, measurement_day) {
  rows <- result$hourly$measurement_day == measurement_day
  result$hourly[rows, , drop = FALSE]
}

day_daily <- function(result, measurement_day) {
  rows <- result$daily$measurement_day == measurement_day
  result$daily[rows, , drop = FALSE]
}

gut_boundaries_kj <- function(hourly) {
  c(
    hourly$gut_available_energy_start_kj[[1L]],
    hourly$gut_available_energy_end_kj
  )
}

daily_tolerances <- function(result, measurement_day) {
  hourly <- day_hourly(result, measurement_day)
  daily <- day_daily(result, measurement_day)
  cycle_tolerance_kj <- tail(
    result$convergence$realized_convergence_tolerance_kj,
    1L
  )
  gut_ledger_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj))
  )
  body_ledger_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )

  c(
    cycle_tolerance_kj = cycle_tolerance_kj,
    gut_ledger_tolerance_kj = gut_ledger_tolerance_kj,
    assimilation_total_tolerance_kj =
      cycle_tolerance_kj + gut_ledger_tolerance_kj,
    body_ledger_tolerance_kj = body_ledger_tolerance_kj,
    body_neutrality_tolerance_kj =
      cycle_tolerance_kj +
        gut_ledger_tolerance_kj +
        body_ledger_tolerance_kj
  )
}

assert_close <- function(actual, expected, tolerance, label) {
  if (
    length(actual) != length(expected) ||
      length(tolerance) != 1L ||
      !is.finite(tolerance) ||
      tolerance < 0 ||
      any(!is.finite(actual)) ||
      any(!is.finite(expected)) ||
      any(abs(actual - expected) > tolerance)
  ) {
    stop(sprintf("Analytical assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

assert_result_contract <- function(fixture) {
  result <- fixture$result
  expected_convergence_names <- c(
    "burn_in_day",
    "gut_available_energy_initial_kj",
    "gut_available_energy_final_kj",
    "cycle_boundary_change_kj",
    "max_abs_previous_day_trajectory_difference_kj",
    "realized_convergence_tolerance_kj",
    "converged"
  )
  if (
    !identical(names(result), c("convergence", "hourly", "daily")) ||
      !identical(names(result$convergence), expected_convergence_names) ||
      nrow(result$convergence) < 2L ||
      !identical(tail(result$convergence$converged, 1L), TRUE) ||
      any(head(result$convergence$converged, -1L)) ||
      !identical(dim(result$hourly), c(48L, 22L)) ||
      !identical(result$hourly$measurement_day, rep(1:2, each = 24L)) ||
      !identical(dim(result$daily), c(2L, 20L)) ||
      !identical(result$daily$measurement_day, 1:2)
  ) {
    stop(
      sprintf("Result contract failed for `%s`.", fixture$scenario_id),
      call. = FALSE
    )
  }

  final_tolerance_kj <- tail(
    result$convergence$realized_convergence_tolerance_kj,
    1L
  )
  final_cycle_change_kj <- tail(
    result$convergence$cycle_boundary_change_kj,
    1L
  )
  final_trajectory_difference_kj <- tail(
    result$convergence$
      max_abs_previous_day_trajectory_difference_kj,
    1L
  )
  if (
    !is.finite(final_tolerance_kj) ||
      final_tolerance_kj <= 0 ||
      !is.finite(final_cycle_change_kj) ||
      !is.finite(final_trajectory_difference_kj) ||
      abs(final_cycle_change_kj) > final_tolerance_kj ||
      final_trajectory_difference_kj > final_tolerance_kj
  ) {
    stop(
      sprintf("Convergence assertion failed for `%s`.", fixture$scenario_id),
      call. = FALSE
    )
  }

  day_1 <- day_hourly(result, 1L)
  day_2 <- day_hourly(result, 2L)
  assert_close(
    gut_boundaries_kj(day_2),
    gut_boundaries_kj(day_1),
    final_tolerance_kj,
    paste(fixture$scenario_id, "measured gut-cycle repetition")
  )
  if (
    !identical(
      day_1$gut_available_energy_end_kj[[24L]],
      day_2$gut_available_energy_start_kj[[1L]]
    ) ||
      !identical(
        day_1$body_energy_reserve_end_kj[[24L]],
        day_2$body_energy_reserve_start_kj[[1L]]
      ) ||
      any(day_1$body_energy_reserve_start_kj < 0) ||
      any(day_1$body_energy_reserve_end_kj < 0) ||
      any(day_2$body_energy_reserve_start_kj < 0) ||
      any(day_2$body_energy_reserve_end_kj < 0)
  ) {
    stop(
      sprintf(
        "Carry-over or body-path feasibility failed for `%s`.",
        fixture$scenario_id
      ),
      call. = FALSE
    )
  }

  for (measurement_day in 1:2) {
    hourly <- day_hourly(result, measurement_day)
    daily <- day_daily(result, measurement_day)
    opening_gut_state <- herbivoreTTR::new_gut_energy_state(
      hourly$gut_available_energy_start_kj[[1L]]
    )
    opening_body_state <- herbivoreTTR::new_body_energy_state(
      hourly$body_energy_reserve_start_kj[[1L]]
    )
    direct <- herbivoreTTR::run_gut_body_energy_day(
      initial_gut_state = opening_gut_state,
      initial_body_state = opening_body_state,
      gut_parameters = herbivoreTTR::new_gut_energy_parameters(0.25),
      body_parameters = herbivoreTTR::new_body_energy_parameters(100),
      schedule = fixture$energy_schedule
    )
    measured_hourly <- hourly[
      setdiff(names(hourly), "measurement_day")
    ]
    measured_daily <- daily[
      setdiff(names(daily), "measurement_day")
    ]
    row.names(measured_hourly) <- seq_len(24L)
    row.names(measured_daily) <- 1L
    if (
      !identical(measured_hourly, direct$hourly) ||
        !identical(measured_daily, direct$daily)
    ) {
      stop(
        sprintf(
          "Direct one-day reduction failed for `%s`, day %d.",
          fixture$scenario_id,
          measurement_day
        ),
        call. = FALSE
      )
    }
  }

  invisible(NULL)
}

fixtures <- list(
  zero = new_fixture("zero", rep(0, 24L)),
  constant = new_fixture("constant", rep(0.010, 24L)),
  concentrated_late = new_fixture(
    "concentrated_late",
    c(rep(0, 18L), rep(0.040, 6L))
  )
)
invisible(lapply(fixtures, assert_result_contract))

dry_matter_total_tolerance <- 100 * .Machine$double.eps
assert_close(
  sum(
    fixtures$constant$dry_matter_schedule$
      prescribed_dry_matter_intake_kg_dm_h
  ),
  0.24,
  dry_matter_total_tolerance,
  "constant daily dry-matter intake"
)
assert_close(
  sum(
    fixtures$concentrated_late$dry_matter_schedule$
      prescribed_dry_matter_intake_kg_dm_h
  ),
  0.24,
  dry_matter_total_tolerance,
  "concentrated daily dry-matter intake"
)

zero_daily <- fixtures$zero$result$daily
if (
  !identical(
    zero_daily$total_prescribed_ingested_available_energy_kj,
    rep(0, 2L)
  ) ||
    !identical(zero_daily$total_assimilated_energy_kj, rep(0, 2L)) ||
    !identical(
      zero_daily$total_maintenance_expenditure_kj,
      rep(2400, 2L)
    ) ||
    !identical(
      zero_daily$observed_body_energy_change_kj,
      rep(-2400, 2L)
    )
) {
  stop("The zero-intake deficit fixture failed.", call. = FALSE)
}

for (scenario_id in c("constant", "concentrated_late")) {
  result <- fixtures[[scenario_id]]$result
  if (
    !identical(
      result$daily$total_prescribed_ingested_available_energy_kj,
      rep(2400, 2L)
    ) ||
      !identical(
        result$daily$total_maintenance_expenditure_kj,
        rep(2400, 2L)
      )
  ) {
    stop(
      sprintf("Exact daily forcing failed for `%s`.", scenario_id),
      call. = FALSE
    )
  }

  for (measurement_day in 1:2) {
    daily <- day_daily(result, measurement_day)
    tolerance <- daily_tolerances(result, measurement_day)
    assert_close(
      daily$gut_available_energy_final_kj,
      daily$gut_available_energy_initial_kj,
      tolerance[["cycle_tolerance_kj"]],
      paste(scenario_id, "daily gut-cycle closure")
    )
    assert_close(
      daily$total_assimilated_energy_kj,
      daily$total_prescribed_ingested_available_energy_kj,
      tolerance[["assimilation_total_tolerance_kj"]],
      paste(scenario_id, "daily assimilation")
    )
    assert_close(
      daily$observed_body_energy_change_kj,
      0,
      tolerance[["body_neutrality_tolerance_kj"]],
      paste(scenario_id, "daily body neutrality")
    )
  }
}

constant_result <- fixtures$constant$result
concentrated_result <- fixtures$concentrated_late$result
for (measurement_day in 1:2) {
  constant_daily <- day_daily(constant_result, measurement_day)
  concentrated_daily <- day_daily(concentrated_result, measurement_day)
  constant_tolerance <- daily_tolerances(
    constant_result,
    measurement_day
  )
  concentrated_tolerance <- daily_tolerances(
    concentrated_result,
    measurement_day
  )
  if (
    !identical(
      constant_daily$total_prescribed_ingested_available_energy_kj,
      concentrated_daily$total_prescribed_ingested_available_energy_kj
    ) ||
      !identical(
        constant_daily$total_maintenance_expenditure_kj,
        concentrated_daily$total_maintenance_expenditure_kj
      )
  ) {
    stop("Timing-equivalent prescribed daily totals differ.", call. = FALSE)
  }
  assert_close(
    constant_daily$total_assimilated_energy_kj,
    concentrated_daily$total_assimilated_energy_kj,
    constant_tolerance[["assimilation_total_tolerance_kj"]] +
      concentrated_tolerance[["assimilation_total_tolerance_kj"]],
    "timing-equivalent daily assimilation"
  )
  assert_close(
    constant_daily$observed_gut_energy_change_kj,
    concentrated_daily$observed_gut_energy_change_kj,
    constant_tolerance[["cycle_tolerance_kj"]] +
      concentrated_tolerance[["cycle_tolerance_kj"]],
    "timing-equivalent daily gut change"
  )
  assert_close(
    constant_daily$observed_body_energy_change_kj,
    concentrated_daily$observed_body_energy_change_kj,
    constant_tolerance[["body_neutrality_tolerance_kj"]] +
      concentrated_tolerance[["body_neutrality_tolerance_kj"]],
    "timing-equivalent daily body change"
  )
}

constant_hourly <- day_hourly(constant_result, 1L)
concentrated_hourly <- day_hourly(concentrated_result, 1L)
if (
  max(abs(
    constant_hourly$gut_available_energy_start_kj -
      concentrated_hourly$gut_available_energy_start_kj
  )) <= tail(
    constant_result$convergence$realized_convergence_tolerance_kj,
    1L
  ) +
    tail(
      concentrated_result$convergence$
        realized_convergence_tolerance_kj,
      1L
    ) ||
    identical(
      constant_hourly$assimilated_energy_kj_h,
      concentrated_hourly$assimilated_energy_kj_h
    ) ||
    identical(
      constant_hourly$body_energy_reserve_end_kj,
      concentrated_hourly$body_energy_reserve_end_kj
    )
) {
  stop("The timing fixtures do not have distinct hourly paths.", call. = FALSE)
}

format_whole_kj <- function(value) {
  rounded <- round(value)
  rounded[rounded == 0] <- 0
  sprintf("%.0f", rounded)
}

convergence_summary <- do.call(
  rbind,
  lapply(fixtures, function(fixture) {
    final <- tail(fixture$result$convergence, 1L)
    data.frame(
      scenario_id = fixture$scenario_id,
      burn_in_days = nrow(fixture$result$convergence),
      final_trajectory_difference_kj = sprintf(
        "%.3e",
        final$max_abs_previous_day_trajectory_difference_kj
      ),
      final_cycle_boundary_change_kj = sprintf(
        "%.3e",
        final$cycle_boundary_change_kj
      ),
      realized_tolerance_kj = sprintf(
        "%.3e",
        final$realized_convergence_tolerance_kj
      ),
      stringsAsFactors = FALSE
    )
  })
)
row.names(convergence_summary) <- NULL

daily_summary <- do.call(
  rbind,
  lapply(fixtures, function(fixture) {
    daily <- fixture$result$daily
    data.frame(
      scenario_id = fixture$scenario_id,
      measurement_day = daily$measurement_day,
      ingested_kj = format_whole_kj(
        daily$total_prescribed_ingested_available_energy_kj
      ),
      assimilated_kj = format_whole_kj(
        daily$total_assimilated_energy_kj
      ),
      maintenance_kj = format_whole_kj(
        daily$total_maintenance_expenditure_kj
      ),
      body_change_kj = format_whole_kj(
        daily$observed_body_energy_change_kj
      ),
      body_final_kj = format_whole_kj(daily$body_energy_reserve_final_kj),
      stringsAsFactors = FALSE
    )
  })
)
row.names(daily_summary) <- NULL

checkpoint_hours <- c(0L, 18L, 23L, 24L, 42L, 47L)
checkpoint_summary <- do.call(
  rbind,
  lapply(fixtures, function(fixture) {
    hourly <- fixture$result$hourly
    elapsed_hour_start_h <-
      24L * (hourly$measurement_day - 1L) + hourly$hour_of_day
    rows <- elapsed_hour_start_h %in% checkpoint_hours
    data.frame(
      scenario_id = fixture$scenario_id,
      elapsed_hour_start_h = elapsed_hour_start_h[rows],
      ingested_kj_h = format(
        hourly$prescribed_ingested_available_energy_kj_h[rows],
        trim = TRUE,
        scientific = FALSE
      ),
      assimilated_kj_h = format(
        round(hourly$assimilated_energy_kj_h[rows], 3L),
        trim = TRUE,
        scientific = FALSE
      ),
      gut_start_kj = format_whole_kj(
        hourly$gut_available_energy_start_kj[rows]
      ),
      body_start_kj = format_whole_kj(
        hourly$body_energy_reserve_start_kj[rows]
      ),
      stringsAsFactors = FALSE
    )
  })
)
row.names(checkpoint_summary) <- NULL

cat("GOAL 005 REPEATED-DAY REFERENCE CYCLE: checks passed\n\n")
cat("Convergence diagnostics (synthetic; numerical values in kJ):\n")
write.table(
  convergence_summary,
  file = "",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)
cat("\nMeasured daily energy summary (whole kJ):\n")
write.table(
  daily_summary,
  file = "",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)
cat(
  paste0(
    "\nSelected day-boundary and feeding-window checkpoints ",
    "(stocks in whole kJ; rates in kJ h^-1):\n"
  )
)
write.table(
  checkpoint_summary,
  file = "",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)
cat(
  paste0(
    "\nConstant and concentrated schedules: 0.24 kg DM and 2400 kJ ",
    "per day; daily equivalence passed within numerical tolerances ",
    "after both body paths were verified feasible.\n"
  )
)
