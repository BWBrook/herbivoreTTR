arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

hourly_schema <- c(
  "hour_of_day",
  "time_start_h",
  "time_end_h",
  "gut_available_energy_start_kj",
  "prescribed_ingested_available_energy_kj_h",
  "gut_release_fraction_h",
  "assimilated_energy_kj_h",
  "prescribed_ingested_available_energy_kj",
  "assimilated_energy_kj",
  "gut_energy_change_kj",
  "gut_available_energy_end_kj",
  "gut_energy_balance_residual_kj",
  "body_energy_reserve_start_kj",
  "maintenance_expenditure_kj_h",
  "maintenance_expenditure_kj",
  "body_energy_change_kj",
  "body_energy_reserve_end_kj",
  "body_energy_balance_residual_kj",
  "total_system_energy_start_kj",
  "total_system_energy_end_kj",
  "system_energy_balance_residual_kj"
)

daily_schema <- c(
  "gut_available_energy_initial_kj",
  "total_prescribed_ingested_available_energy_kj",
  "total_assimilated_energy_kj",
  "expected_gut_energy_change_kj",
  "observed_gut_energy_change_kj",
  "gut_available_energy_final_kj",
  "gut_energy_balance_residual_kj",
  "body_energy_reserve_initial_kj",
  "total_maintenance_expenditure_kj",
  "expected_body_energy_change_kj",
  "observed_body_energy_change_kj",
  "body_energy_reserve_final_kj",
  "body_energy_balance_residual_kj",
  "total_system_energy_initial_kj",
  "expected_total_system_energy_change_kj",
  "observed_total_system_energy_change_kj",
  "total_system_energy_final_kj",
  "system_energy_balance_residual_kj",
  "body_energy_status"
)

accounting_tolerance <- function(...) {
  values <- unlist(list(...), use.names = FALSE)
  100 * .Machine$double.eps * max(1, abs(values))
}

assert_close <- function(actual, expected, label) {
  tolerance <- accounting_tolerance(actual, expected)
  if (
    length(actual) != length(expected) ||
      any(!is.finite(actual)) ||
      any(!is.finite(expected)) ||
      any(abs(actual - expected) > tolerance)
  ) {
    stop(sprintf("Analytical assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

assert_result_contract <- function(result, scenario_id) {
  if (
    !identical(names(result), c("hourly", "daily")) ||
      !identical(dim(result$hourly), c(24L, length(hourly_schema))) ||
      !identical(names(result$hourly), hourly_schema) ||
      !identical(dim(result$daily), c(1L, length(daily_schema))) ||
      !identical(names(result$daily), daily_schema)
  ) {
    stop(
      sprintf("Output schema assertion failed for `%s`.", scenario_id),
      call. = FALSE
    )
  }

  hourly <- result$hourly
  daily <- result$daily
  hourly_gut_tolerance <- 100 * .Machine$double.eps * pmax(
    1,
    abs(hourly$gut_available_energy_start_kj),
    abs(hourly$gut_available_energy_end_kj),
    abs(hourly$prescribed_ingested_available_energy_kj),
    abs(hourly$assimilated_energy_kj)
  )
  hourly_body_tolerance <- 100 * .Machine$double.eps * pmax(
    1,
    abs(hourly$body_energy_reserve_start_kj),
    abs(hourly$body_energy_reserve_end_kj),
    abs(hourly$assimilated_energy_kj),
    abs(hourly$maintenance_expenditure_kj)
  )
  hourly_system_tolerance <- 100 * .Machine$double.eps * pmax(
    1,
    abs(hourly$gut_available_energy_start_kj),
    abs(hourly$gut_available_energy_end_kj),
    abs(hourly$body_energy_reserve_start_kj),
    abs(hourly$body_energy_reserve_end_kj),
    abs(hourly$prescribed_ingested_available_energy_kj),
    abs(hourly$assimilated_energy_kj),
    abs(hourly$maintenance_expenditure_kj)
  )

  if (
    any(abs(hourly$gut_energy_balance_residual_kj) > hourly_gut_tolerance) ||
      any(
        abs(hourly$body_energy_balance_residual_kj) >
          hourly_body_tolerance
      ) ||
      any(
        abs(hourly$system_energy_balance_residual_kj) >
          hourly_system_tolerance
      )
  ) {
    stop(
      sprintf("Hourly accounting assertion failed for `%s`.", scenario_id),
      call. = FALSE
    )
  }

  daily_gut_tolerance <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj))
  )
  daily_body_tolerance <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )
  daily_system_tolerance <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )

  if (
    abs(daily$gut_energy_balance_residual_kj) > daily_gut_tolerance ||
      abs(daily$body_energy_balance_residual_kj) > daily_body_tolerance ||
      abs(daily$system_energy_balance_residual_kj) >
        daily_system_tolerance
  ) {
    stop(
      sprintf("Daily accounting assertion failed for `%s`.", scenario_id),
      call. = FALSE
    )
  }

  invisible(NULL)
}

run_fixture <- function(initial_gut_energy_kj, ingestion_kj_h, maintenance_kj_h) {
  herbivoreTTR::run_gut_body_energy_day(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(
      initial_gut_energy_kj
    ),
    initial_body_state = herbivoreTTR::new_body_energy_state(5000),
    gut_parameters = herbivoreTTR::new_gut_energy_parameters(0.25),
    body_parameters = herbivoreTTR::new_body_energy_parameters(
      maintenance_kj_h
    ),
    schedule = herbivoreTTR::new_ingested_available_energy_schedule(
      hour_of_day = 0:23,
      prescribed_ingested_available_energy_kj_h = ingestion_kj_h
    )
  )
}

fixtures <- list(
  equilibrium = run_fixture(
    initial_gut_energy_kj = 400,
    ingestion_kj_h = rep(100, 24L),
    maintenance_kj_h = 100
  ),
  empty_start = run_fixture(
    initial_gut_energy_kj = 0,
    ingestion_kj_h = rep(100, 24L),
    maintenance_kj_h = 100
  ),
  pulse = run_fixture(
    initial_gut_energy_kj = 0,
    ingestion_kj_h = c(400, rep(0, 23L)),
    maintenance_kj_h = 0
  )
)

invisible(Map(assert_result_contract, fixtures, names(fixtures)))

equilibrium <- fixtures$equilibrium
assert_close(
  equilibrium$hourly$gut_available_energy_start_kj,
  rep(400, 24L),
  "equilibrium opening gut stock"
)
assert_close(
  equilibrium$hourly$gut_available_energy_end_kj,
  rep(400, 24L),
  "equilibrium closing gut stock"
)
assert_close(
  equilibrium$hourly$assimilated_energy_kj_h,
  rep(100, 24L),
  "equilibrium assimilation"
)
assert_close(
  equilibrium$hourly$body_energy_reserve_end_kj,
  rep(5000, 24L),
  "equilibrium body reserve"
)
stopifnot(identical(equilibrium$daily$body_energy_status, "neutral"))

empty_start <- fixtures$empty_start
elapsed_start_h <- empty_start$hourly$time_start_h
elapsed_end_h <- empty_start$hourly$time_end_h
expected_empty_start_gut_kj <- 400 * (1 - 0.75^elapsed_start_h)
expected_empty_end_gut_kj <- 400 * (1 - 0.75^elapsed_end_h)
assert_close(
  empty_start$hourly$gut_available_energy_start_kj,
  expected_empty_start_gut_kj,
  "empty-start opening recurrence"
)
assert_close(
  empty_start$hourly$gut_available_energy_end_kj,
  expected_empty_end_gut_kj,
  "empty-start closing recurrence"
)
assert_close(
  empty_start$hourly$body_energy_reserve_end_kj,
  5000 - expected_empty_end_gut_kj,
  "empty-start body-gut complement"
)
assert_close(
  empty_start$daily$gut_available_energy_final_kj,
  400 * (1 - 0.75^24),
  "empty-start final gut stock"
)
assert_close(
  empty_start$daily$body_energy_reserve_final_kj,
  5000 - 400 * (1 - 0.75^24),
  "empty-start final body reserve"
)
assert_close(
  empty_start$daily$total_system_energy_final_kj,
  5000,
  "empty-start final combined energy"
)
stopifnot(identical(empty_start$daily$body_energy_status, "deficit"))

pulse <- fixtures$pulse
expected_pulse_gut_start_kj <- c(0, 400 * 0.75^(0:22))
expected_pulse_gut_end_kj <- 400 * 0.75^c(0, 1:23)
expected_pulse_assimilation_kj_h <- c(0, 100 * 0.75^(0:22))
assert_close(
  pulse$hourly$gut_available_energy_start_kj,
  expected_pulse_gut_start_kj,
  "pulse opening gut stock"
)
assert_close(
  pulse$hourly$gut_available_energy_end_kj,
  expected_pulse_gut_end_kj,
  "pulse closing gut stock"
)
assert_close(
  pulse$hourly$assimilated_energy_kj_h,
  expected_pulse_assimilation_kj_h,
  "pulse geometric assimilation"
)
assert_close(
  pulse$hourly$assimilated_energy_kj_h[1:4],
  c(0, 100, 75, 56.25),
  "pulse delay checkpoints"
)
assert_close(
  pulse$hourly$total_system_energy_end_kj,
  rep(5400, 24L),
  "pulse combined energy"
)
stopifnot(identical(pulse$daily$body_energy_status, "surplus"))

daily_summary <- do.call(
  rbind,
  lapply(names(fixtures), function(scenario_id) {
    data.frame(
      scenario_id = scenario_id,
      fixtures[[scenario_id]]$daily[
        ,
        c(
          "gut_available_energy_final_kj",
          "body_energy_reserve_final_kj",
          "total_system_energy_final_kj",
          "body_energy_status"
        ),
        drop = FALSE
      ],
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
)
row.names(daily_summary) <- NULL

checkpoint_hours <- c(0L, 1L, 2L, 3L, 6L, 12L, 18L, 23L)
hourly_summary <- do.call(
  rbind,
  lapply(names(fixtures), function(scenario_id) {
    hourly <- fixtures[[scenario_id]]$hourly
    data.frame(
      scenario_id = scenario_id,
      hourly[
        hourly$hour_of_day %in% checkpoint_hours,
        c(
          "hour_of_day",
          "prescribed_ingested_available_energy_kj_h",
          "assimilated_energy_kj_h",
          "gut_available_energy_end_kj",
          "body_energy_reserve_end_kj"
        ),
        drop = FALSE
      ],
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
)
row.names(hourly_summary) <- NULL

cat("SYNTHETIC GOAL 003 FIXTURES: analytical checks passed\n\n")
cat("Daily summary (all energies in kJ):\n")
write.table(
  daily_summary,
  file = "",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)
cat("\nSelected hourly checkpoints (rates in kJ h^-1; stocks in kJ):\n")
write.table(
  hourly_summary,
  file = "",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)
