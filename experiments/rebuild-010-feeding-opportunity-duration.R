arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

require_that <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 010 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

near <- function(observed, expected, scale = NULL) {
  observed <- as.double(observed)
  expected <- as.double(expected)
  if (is.null(scale)) {
    scale <- pmax(1, abs(observed), abs(expected))
  } else {
    scale <- pmax(1, as.double(scale))
  }
  length(observed) == length(expected) &&
    length(scale) %in% c(1L, length(observed)) &&
    all(is.finite(observed)) &&
    all(is.finite(expected)) &&
    all(is.finite(scale)) &&
    all(abs(observed - expected) <= 100 * .Machine$double.eps * scale)
}

gut_boundaries_kj <- function(result) {
  c(
    result$hourly$gut_available_energy_start_kj[[1L]],
    result$hourly$gut_available_energy_end_kj
  )
}

body_boundaries_kj <- function(result) {
  c(
    result$hourly$body_energy_reserve_start_kj[[1L]],
    result$hourly$body_energy_reserve_end_kj
  )
}

daily_maintenance_kj <- function(result) {
  as.double(tapply(
    result$hourly$maintenance_expenditure_kj,
    result$hourly$measurement_day,
    sum
  ))
}

round_kj_amounts <- function(value) {
  columns <- grep("_kj$", names(value), value = TRUE)
  value[columns] <- lapply(value[columns], round)
  value
}

scenario_ids <- c(
  "prescribed_intake_window_24h",
  "prescribed_intake_window_16h",
  "prescribed_intake_window_12h",
  "prescribed_intake_window_8h"
)
durations_h_d <- c(24L, 16L, 12L, 8L)
names(durations_h_d) <- scenario_ids
hour_of_day <- 0:23
activity_hours <- c(0:7, 16:23)
activity_rates_kj_h <- ifelse(hour_of_day %in% activity_hours, 50, 0)
open_hours <- list(
  prescribed_intake_window_24h = 0:23,
  prescribed_intake_window_16h = c(0:7, 16:23),
  prescribed_intake_window_12h = c(2:7, 16:21),
  prescribed_intake_window_8h = c(4:7, 16:19)
)
window_open <- lapply(
  open_hours,
  function(hours) hour_of_day %in% hours
)

expected_daily_dry_matter_kg_dm <- c(0.48, 0.32, 0.24, 0.16)
expected_daily_energy_kj <- c(4800, 3200, 2400, 1600)
expected_daily_body_change_kj <- c(1600, 0, -800, -1600)
expected_body_closes_kj <- matrix(
  c(
    11600, 13200,
    10000, 10000,
    9200, 8400,
    8400, 6800
  ),
  nrow = 4L,
  byrow = TRUE,
  dimnames = list(scenario_ids, c("day_1", "day_2"))
)
expected_statuses <- c("surplus", "neutral", "deficit", "deficit")
threshold_relations <- c("above", "at", "below", "below")

new_model_run <- function(dry_matter_rates, activity_rates) {
  dry_matter_schedule <-
    herbivoreTTR::new_dry_matter_intake_schedule(
      hour_of_day,
      dry_matter_rates
    )
  energy_schedule <-
    herbivoreTTR::derive_ingested_available_energy_schedule(
      herbivoreTTR::new_food_energy_parameters(10000),
      dry_matter_schedule
    )
  activity_schedule <-
    herbivoreTTR::new_routine_activity_expenditure_schedule(
      hour_of_day,
      activity_rates
    )
  result <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    herbivoreTTR::new_gut_energy_state(0),
    herbivoreTTR::new_body_energy_state(10000),
    herbivoreTTR::new_gut_energy_parameters(0.25),
    herbivoreTTR::new_body_energy_parameters(100),
    energy_schedule,
    activity_schedule,
    100 * .Machine$double.eps,
    100L
  )
  list(
    dry_matter_schedule = dry_matter_schedule,
    energy_schedule = energy_schedule,
    activity_schedule = activity_schedule,
    result = result
  )
}

fixtures <- lapply(scenario_ids, function(scenario_id) {
  open <- window_open[[scenario_id]]
  list(
    scenario_id = scenario_id,
    duration_h_d = durations_h_d[[scenario_id]],
    open = open,
    model = new_model_run(
      as.double(open) * 0.020,
      activity_rates_kj_h
    )
  )
})
names(fixtures) <- scenario_ids

# Direct schedules independently reconstruct the accepted Goal 008 oracles.
oracle_balanced <- new_model_run(
  c(rep(0.020, 8L), rep(0, 8L), rep(0.020, 8L)),
  c(rep(50, 8L), rep(0, 8L), rep(50, 8L))
)
oracle_uncompensated <- new_model_run(
  c(rep(0.015, 8L), rep(0, 8L), rep(0.015, 8L)),
  c(rep(50, 8L), rep(0, 8L), rep(50, 8L))
)

narrow_daily_match <- function(model, oracle) {
  fields <- c(
    "total_prescribed_ingested_available_energy_kj",
    "expected_body_energy_change_kj",
    "observed_body_energy_change_kj",
    "body_energy_reserve_initial_kj",
    "body_energy_reserve_final_kj"
  )
  left <- model$result$daily
  right <- oracle$result$daily
  near(
    sum(model$dry_matter_schedule$prescribed_dry_matter_intake_kg_dm_h),
    sum(oracle$dry_matter_schedule$prescribed_dry_matter_intake_kg_dm_h)
  ) &&
    near(daily_maintenance_kj(model$result), daily_maintenance_kj(oracle$result)) &&
    near(
      left$total_prescribed_routine_activity_expenditure_kj,
      right$total_prescribed_routine_activity_expenditure_kj
    ) &&
    all(vapply(
      fields,
      function(field) near(left[[field]], right[[field]]),
      logical(1L)
    )) &&
    identical(left$body_energy_status, right$body_energy_status)
}

comparisons <- list(
  prescribed_intake_window_16h = list(
    scenario_id = "ecological_activity_prescribed_balance",
    oracle = oracle_balanced
  ),
  prescribed_intake_window_12h = list(
    scenario_id = "ecological_activity_uncompensated",
    oracle = oracle_uncompensated
  )
)
comparison_values <- lapply(scenario_ids, function(scenario_id) {
  if (!scenario_id %in% names(comparisons)) {
    return(list(
      matched_id = NA_character_,
      daily_match = NA,
      trajectory_identical = NA,
      result_identical = NA
    ))
  }
  model <- fixtures[[scenario_id]]$model
  comparison <- comparisons[[scenario_id]]
  list(
    matched_id = comparison$scenario_id,
    daily_match = narrow_daily_match(model, comparison$oracle),
    trajectory_identical = identical(
      body_boundaries_kj(model$result),
      body_boundaries_kj(comparison$oracle$result)
    ),
    result_identical =
      identical(model$result, comparison$oracle$result)
  )
})
names(comparison_values) <- scenario_ids

hourly_prescribed_intake_windows <- do.call(
  rbind,
  lapply(fixtures, function(fixture) {
    data.frame(
      scenario_id = fixture$scenario_id,
      prescribed_intake_window_duration_h_d = fixture$duration_h_d,
      hour_of_day = hour_of_day,
      prescribed_intake_window_open = fixture$open,
      prescribed_dry_matter_intake_kg_dm_h =
        fixture$model$dry_matter_schedule$
          prescribed_dry_matter_intake_kg_dm_h,
      prescribed_ingested_available_energy_kj_h =
        fixture$model$energy_schedule$
          prescribed_ingested_available_energy_kj_h,
      prescribed_routine_activity_expenditure_kj_h =
        fixture$model$activity_schedule$
          prescribed_routine_activity_expenditure_kj_h,
      row.names = NULL
    )
  })
)
row.names(hourly_prescribed_intake_windows) <- NULL

duration_summary <- do.call(
  rbind,
  lapply(seq_along(fixtures), function(index) {
    fixture <- fixtures[[index]]
    open <- fixture$open
    active <- activity_rates_kj_h > 0
    result <- fixture$model$result
    comparison <- comparison_values[[fixture$scenario_id]]
    data.frame(
      scenario_id = fixture$scenario_id,
      prescribed_intake_window_duration_h_d = fixture$duration_h_d,
      closed_prescribed_intake_duration_h_d = sum(!open),
      prescribed_intake_activity_overlap_h_d = sum(open & active),
      activity_without_prescribed_intake_h_d = sum(!open & active),
      prescribed_intake_without_activity_h_d = sum(open & !active),
      threshold_relation = threshold_relations[[index]],
      daily_prescribed_dry_matter_intake_kg_dm =
        sum(fixture$model$dry_matter_schedule$
          prescribed_dry_matter_intake_kg_dm_h),
      daily_prescribed_energy_kj =
        sum(fixture$model$energy_schedule$
          prescribed_ingested_available_energy_kj_h),
      daily_maintenance_expenditure_kj =
        daily_maintenance_kj(result)[[1L]],
      daily_routine_activity_expenditure_kj =
        result$daily$
          total_prescribed_routine_activity_expenditure_kj[[1L]],
      expected_body_energy_change_kj =
        expected_daily_body_change_kj[[index]],
      day_1_body_energy_reserve_final_kj =
        result$daily$body_energy_reserve_final_kj[[1L]],
      day_2_body_energy_reserve_final_kj =
        result$daily$body_energy_reserve_final_kj[[2L]],
      matched_goal008_scenario_id = comparison$matched_id,
      daily_input_and_body_change_match = comparison$daily_match,
      within_day_body_trajectory_identical =
        comparison$trajectory_identical,
      full_result_identical = comparison$result_identical,
      row.names = NULL
    )
  })
)
row.names(duration_summary) <- NULL
duration_summary <- round_kj_amounts(duration_summary)

daily_accounting <- do.call(
  rbind,
  lapply(seq_along(fixtures), function(index) {
    fixture <- fixtures[[index]]
    result <- fixture$model$result
    daily <- result$daily
    data.frame(
      scenario_id = fixture$scenario_id,
      measurement_day = daily$measurement_day,
      prescribed_intake_window_duration_h_d = fixture$duration_h_d,
      daily_prescribed_dry_matter_intake_kg_dm =
        sum(fixture$model$dry_matter_schedule$
          prescribed_dry_matter_intake_kg_dm_h),
      total_prescribed_energy_input_kj =
        daily$total_prescribed_ingested_available_energy_kj,
      total_assimilated_energy_kj = daily$total_assimilated_energy_kj,
      total_maintenance_expenditure_kj = daily_maintenance_kj(result),
      total_routine_activity_expenditure_kj =
        daily$total_prescribed_routine_activity_expenditure_kj,
      expected_body_energy_change_kj =
        expected_daily_body_change_kj[[index]],
      observed_body_energy_change_kj =
        daily$observed_body_energy_change_kj,
      body_energy_reserve_initial_kj =
        daily$body_energy_reserve_initial_kj,
      body_energy_reserve_final_kj =
        daily$body_energy_reserve_final_kj,
      body_energy_status = daily$body_energy_status,
      row.names = NULL
    )
  })
)
row.names(daily_accounting) <- NULL
daily_accounting <- round_kj_amounts(daily_accounting)

hourly_names <- c(
  "scenario_id",
  "prescribed_intake_window_duration_h_d",
  "hour_of_day",
  "prescribed_intake_window_open",
  "prescribed_dry_matter_intake_kg_dm_h",
  "prescribed_ingested_available_energy_kj_h",
  "prescribed_routine_activity_expenditure_kj_h"
)
duration_names <- c(
  "scenario_id",
  "prescribed_intake_window_duration_h_d",
  "closed_prescribed_intake_duration_h_d",
  "prescribed_intake_activity_overlap_h_d",
  "activity_without_prescribed_intake_h_d",
  "prescribed_intake_without_activity_h_d",
  "threshold_relation",
  "daily_prescribed_dry_matter_intake_kg_dm",
  "daily_prescribed_energy_kj",
  "daily_maintenance_expenditure_kj",
  "daily_routine_activity_expenditure_kj",
  "expected_body_energy_change_kj",
  "day_1_body_energy_reserve_final_kj",
  "day_2_body_energy_reserve_final_kj",
  "matched_goal008_scenario_id",
  "daily_input_and_body_change_match",
  "within_day_body_trajectory_identical",
  "full_result_identical"
)
daily_names <- c(
  "scenario_id",
  "measurement_day",
  "prescribed_intake_window_duration_h_d",
  "daily_prescribed_dry_matter_intake_kg_dm",
  "total_prescribed_energy_input_kj",
  "total_assimilated_energy_kj",
  "total_maintenance_expenditure_kj",
  "total_routine_activity_expenditure_kj",
  "expected_body_energy_change_kj",
  "observed_body_energy_change_kj",
  "body_energy_reserve_initial_kj",
  "body_energy_reserve_final_kj",
  "body_energy_status"
)

require_that(
  identical(names(hourly_prescribed_intake_windows), hourly_names) &&
    identical(dim(hourly_prescribed_intake_windows), c(96L, 7L)),
  "table 1 schema and dimensions"
)
require_that(
  identical(names(duration_summary), duration_names) &&
    identical(dim(duration_summary), c(4L, 18L)),
  "table 2 schema and dimensions"
)
require_that(
  identical(names(daily_accounting), daily_names) &&
    identical(dim(daily_accounting), c(8L, 13L)),
  "table 3 schema and dimensions"
)
require_that(
  identical(duration_summary$scenario_id, scenario_ids) &&
    identical(
      duration_summary$prescribed_intake_window_duration_h_d,
      unname(durations_h_d)
    ) &&
    identical(
      hourly_prescribed_intake_windows$scenario_id,
      rep(scenario_ids, each = 24L)
    ) &&
    identical(
      hourly_prescribed_intake_windows$hour_of_day,
      rep(hour_of_day, 4L)
    ) &&
    identical(
      daily_accounting$scenario_id,
      rep(scenario_ids, each = 2L)
    ) &&
    identical(daily_accounting$measurement_day, rep(1:2, 4L)),
  "table ordering"
)

for (index in seq_along(fixtures)) {
  fixture <- fixtures[[index]]
  model <- fixture$model
  result <- model$result
  convergence <- result$convergence
  tolerance <- tail(
    convergence$realized_convergence_tolerance_kj,
    1L
  )
  stocks <- unlist(
    result$hourly[c(
      "gut_available_energy_start_kj",
      "gut_available_energy_end_kj",
      "body_energy_reserve_start_kj",
      "body_energy_reserve_end_kj"
    )],
    use.names = FALSE
  )

  require_that(
    identical(
      as.integer(which(fixture$open) - 1L),
      open_hours[[fixture$scenario_id]]
    ) &&
      identical(
        model$dry_matter_schedule$
          prescribed_dry_matter_intake_kg_dm_h,
        as.double(fixture$open) * 0.020
      ) &&
      identical(
        model$energy_schedule$
          prescribed_ingested_available_energy_kj_h,
        as.double(fixture$open) * 200
      ) &&
      identical(
        model$activity_schedule$
          prescribed_routine_activity_expenditure_kj_h,
        activity_rates_kj_h
      ),
    paste(fixture$scenario_id, "fixed schedules")
  )
  require_that(
    isTRUE(tail(convergence$converged, 1L)) &&
      is.finite(tolerance) &&
      tolerance > 0 &&
      abs(tail(convergence$cycle_boundary_change_kj, 1L)) <= tolerance &&
      tail(
        convergence$
          max_abs_previous_day_trajectory_difference_kj,
        1L
      ) <= tolerance,
    paste(fixture$scenario_id, "periodic-gut convergence")
  )
  require_that(
    identical(
      result$hourly$gut_available_energy_start_kj[[25L]],
      result$hourly$gut_available_energy_end_kj[[24L]]
    ) &&
      identical(
        result$hourly$body_energy_reserve_start_kj[[25L]],
        result$hourly$body_energy_reserve_end_kj[[24L]]
      ) &&
      identical(
        result$daily$gut_available_energy_initial_kj[[2L]],
        result$daily$gut_available_energy_final_kj[[1L]]
      ) &&
      identical(
        result$daily$body_energy_reserve_initial_kj[[2L]],
        result$daily$body_energy_reserve_final_kj[[1L]]
      ),
    paste(fixture$scenario_id, "measurement-day carry-over")
  )
  require_that(
    all(is.finite(stocks)) &&
      all(stocks >= 0) &&
      near(
        result$daily$total_prescribed_ingested_available_energy_kj,
        rep(expected_daily_energy_kj[[index]], 2L)
      ) &&
      near(
        result$daily$total_assimilated_energy_kj,
        rep(expected_daily_energy_kj[[index]], 2L)
      ) &&
      near(daily_maintenance_kj(result), rep(2400, 2L)) &&
      near(
        result$daily$
          total_prescribed_routine_activity_expenditure_kj,
        rep(800, 2L)
      ) &&
      near(
        result$daily$observed_body_energy_change_kj,
        rep(expected_daily_body_change_kj[[index]], 2L),
        scale = pmax(
          1,
          result$daily$body_energy_reserve_initial_kj,
          result$daily$body_energy_reserve_final_kj,
          expected_daily_energy_kj[[index]]
        )
      ) &&
      near(
        result$daily$body_energy_reserve_final_kj,
        expected_body_closes_kj[fixture$scenario_id, ]
      ) &&
      identical(
        result$daily$body_energy_status,
        rep(expected_statuses[[index]], 2L)
      ),
    paste(fixture$scenario_id, "daily results and finite stocks")
  )
}

require_that(
  near(expected_daily_energy_kj, 200 * durations_h_d) &&
    near(
      expected_daily_body_change_kj,
      200 * durations_h_d - 3200
    ) &&
    identical(3200 / 200, 16),
  "analytical duration relationship and threshold"
)
require_that(
  identical(
    duration_summary$closed_prescribed_intake_duration_h_d,
    c(0L, 8L, 12L, 16L)
  ) &&
    identical(
      duration_summary$prescribed_intake_activity_overlap_h_d,
      c(16L, 16L, 12L, 8L)
    ) &&
    identical(
      duration_summary$activity_without_prescribed_intake_h_d,
      c(0L, 0L, 4L, 8L)
    ) &&
    identical(
      duration_summary$prescribed_intake_without_activity_h_d,
      c(8L, 0L, 0L, 0L)
    ),
  "prescribed-intake and activity overlap"
)
require_that(
  near(
    duration_summary$daily_prescribed_dry_matter_intake_kg_dm,
    expected_daily_dry_matter_kg_dm
  ) &&
    near(duration_summary$daily_prescribed_energy_kj, expected_daily_energy_kj) &&
    near(
      duration_summary$expected_body_energy_change_kj,
      expected_daily_body_change_kj
    ),
  "duration summary accounting"
)

fixture_16h <- fixtures$prescribed_intake_window_16h$model
fixture_12h <- fixtures$prescribed_intake_window_12h$model
require_that(
  identical(fixture_16h$result, oracle_balanced$result),
  "16-hour exact Goal 008 balanced identity"
)
require_that(
  narrow_daily_match(fixture_12h, oracle_uncompensated),
  "12-hour selected Goal 008 uncompensated daily match"
)
require_that(
  !identical(
    fixture_12h$dry_matter_schedule,
    oracle_uncompensated$dry_matter_schedule
  ) &&
    !near(
      gut_boundaries_kj(fixture_12h$result),
      gut_boundaries_kj(oracle_uncompensated$result)
    ) &&
    !near(
      body_boundaries_kj(fixture_12h$result),
      body_boundaries_kj(oracle_uncompensated$result)
    ) &&
    !identical(fixture_12h$result, oracle_uncompensated$result),
  "12-hour schedule, trajectories, and full result differ"
)
require_that(
  identical(
    duration_summary$matched_goal008_scenario_id,
    c(
      NA_character_,
      "ecological_activity_prescribed_balance",
      "ecological_activity_uncompensated",
      NA_character_
    )
  ) &&
    identical(
      duration_summary$daily_input_and_body_change_match,
      c(NA, TRUE, TRUE, NA)
    ) &&
    identical(
      duration_summary$within_day_body_trajectory_identical,
      c(NA, TRUE, FALSE, NA)
    ) &&
    identical(
      duration_summary$full_result_identical,
      c(NA, TRUE, FALSE, NA)
    ),
  "declared Goal 008 comparison semantics"
)

interpretation_boundaries <- c(
  daily_relation =
    "Daily accounting varies with fixed-rate prescribed-window duration.",
  trajectory_scope =
    "Within-day trajectories are conditional on declared clock placement.",
  evidence_limit =
    paste0(
      "Open hours prescribe ingestion; this screen establishes no ",
      "behaviour, empirical capacity, compensation, or viability."
    )
)

goal010_evidence <- list(
  scenario_ids = scenario_ids,
  durations_h_d = durations_h_d,
  hour_of_day = hour_of_day,
  activity_hours = activity_hours,
  open_hours = open_hours,
  fixtures = fixtures,
  oracle_balanced = oracle_balanced,
  oracle_uncompensated = oracle_uncompensated,
  hourly_prescribed_intake_windows =
    hourly_prescribed_intake_windows,
  duration_summary = duration_summary,
  daily_accounting = daily_accounting,
  neutrality_threshold_h_d = 16,
  interpretation_boundaries = interpretation_boundaries
)

cat("Rebuild Goal 010: feeding-opportunity duration\n\n")
print(
  duration_summary[c(
    "scenario_id",
    "prescribed_intake_window_duration_h_d",
    "prescribed_intake_activity_overlap_h_d",
    "activity_without_prescribed_intake_h_d",
    "prescribed_intake_without_activity_h_d",
    "daily_prescribed_energy_kj",
    "expected_body_energy_change_kj",
    "threshold_relation"
  )],
  row.names = FALSE
)
cat(
  "\nDaily accounting follows duration at the fixed prescribed rate; ",
  "within-day trajectories remain conditional on clock placement.\n",
  sep = ""
)
cat(
  "Open hours prescribe ingestion and imply no behaviour, empirical ",
  "capacity, compensation, viability, or literal continuous feeding.\n",
  sep = ""
)
cat("All Goal 010 in-memory assertions passed; no files were written.\n")
