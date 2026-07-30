arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

scenario_ids <- c(
  "ecological_day_resting",
  "ecological_activity_uncompensated",
  "ecological_activity_prescribed_balance"
)
active_hours <- c(0:7, 16:23)
dry_matter_rates <- list(
  ecological_day_resting = c(
    rep(0.015, 8L),
    rep(0, 8L),
    rep(0.015, 8L)
  ),
  ecological_activity_uncompensated = c(
    rep(0.015, 8L),
    rep(0, 8L),
    rep(0.015, 8L)
  ),
  ecological_activity_prescribed_balance = c(
    rep(0.020, 8L),
    rep(0, 8L),
    rep(0.020, 8L)
  )
)
energy_rates <- list(
  ecological_day_resting = c(
    rep(150, 8L),
    rep(0, 8L),
    rep(150, 8L)
  ),
  ecological_activity_uncompensated = c(
    rep(150, 8L),
    rep(0, 8L),
    rep(150, 8L)
  ),
  ecological_activity_prescribed_balance = c(
    rep(200, 8L),
    rep(0, 8L),
    rep(200, 8L)
  )
)
activity_rates <- list(
  ecological_day_resting = rep(0, 24L),
  ecological_activity_uncompensated = c(
    rep(50, 8L),
    rep(0, 8L),
    rep(50, 8L)
  ),
  ecological_activity_prescribed_balance = c(
    rep(50, 8L),
    rep(0, 8L),
    rep(50, 8L)
  )
)
gut_fields <- c(
  "measurement_day",
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
  "gut_energy_balance_residual_kj"
)

require_that <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 008 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

near <- function(observed, expected) {
  observed <- as.double(observed)
  expected <- as.double(expected)
  length(observed) == length(expected) &&
    all(is.finite(observed)) &&
    all(is.finite(expected)) &&
    all(
      abs(observed - expected) <=
        100 * .Machine$double.eps *
          pmax(1, abs(observed), abs(expected))
    )
}

day_rows <- function(result, table_name, measurement_day) {
  table <- result[[table_name]]
  table[
    table$measurement_day == measurement_day,
    ,
    drop = FALSE
  ]
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

canonical_equal <- function(left, right) {
  row.names(left) <- NULL
  row.names(right) <- NULL
  identical(left, right)
}

daily_tolerances <- function(result, measurement_day) {
  hourly <- day_rows(result, "hourly", measurement_day)
  daily <- day_rows(result, "daily", measurement_day)
  cycle <- tail(
    result$convergence$realized_convergence_tolerance_kj,
    1L
  )
  gut <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj))
  )
  body <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj)),
    sum(abs(hourly$prescribed_routine_activity_expenditure_kj))
  )
  system <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$total_system_energy_initial_kj),
    abs(daily$total_system_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj)),
    sum(abs(hourly$prescribed_routine_activity_expenditure_kj))
  )

  c(
    cycle = cycle,
    gut = gut,
    assimilation = cycle + gut,
    body_ledger = body,
    body_neutrality = cycle + gut + body,
    system = system
  )
}

new_fixture <- function(scenario_id) {
  dry_matter_schedule <-
    herbivoreTTR::new_dry_matter_intake_schedule(
      hour_of_day = 0:23,
      prescribed_dry_matter_intake_kg_dm_h =
        dry_matter_rates[[scenario_id]]
    )
  energy_schedule <-
    herbivoreTTR::derive_ingested_available_energy_schedule(
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
    measurement_body_state =
      herbivoreTTR::new_body_energy_state(10000),
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

expected_dry_matter_totals <- c(0.24, 0.24, 0.32)
expected_energy_totals <- c(2400, 2400, 3200)
expected_activity_totals <- c(0, 800, 800)
expected_statuses <- list(
  ecological_day_resting = rep("neutral", 2L),
  ecological_activity_uncompensated = rep("deficit", 2L),
  ecological_activity_prescribed_balance = rep("neutral", 2L)
)

validate_fixture <- function(fixture, index) {
  scenario_id <- fixture$scenario_id
  result <- fixture$result
  convergence <- result$convergence
  final_cycle_tolerance <- tail(
    convergence$realized_convergence_tolerance_kj,
    1L
  )
  day_1 <- day_rows(result, "hourly", 1L)
  day_2 <- day_rows(result, "hourly", 2L)
  repeated_gut_fields <- setdiff(
    gut_fields,
    c("measurement_day", "time_start_h", "time_end_h")
  )

  require_that(
    identical(fixture$dry_matter_schedule$hour_of_day, 0:23) &&
      identical(
        fixture$dry_matter_schedule$
          prescribed_dry_matter_intake_kg_dm_h,
        dry_matter_rates[[scenario_id]]
      ) &&
      identical(fixture$energy_schedule$hour_of_day, 0:23) &&
      identical(
        fixture$energy_schedule$
          prescribed_ingested_available_energy_kj_h,
        energy_rates[[scenario_id]]
      ) &&
      identical(
        fixture$routine_activity_schedule$hour_of_day,
        0:23
      ) &&
      identical(
        fixture$routine_activity_schedule$
          prescribed_routine_activity_expenditure_kj_h,
        activity_rates[[scenario_id]]
      ),
    paste(scenario_id, "exact schedules")
  )
  require_that(
    identical(
      as.integer(which(energy_rates[[scenario_id]] > 0) - 1L),
      active_hours
    ) &&
      identical(
        as.integer(which(energy_rates[[scenario_id]] == 0) - 1L),
        8:15
      ),
    paste(scenario_id, "active and rest intervals")
  )
  require_that(
    abs(
      sum(dry_matter_rates[[scenario_id]]) -
        expected_dry_matter_totals[[index]]
    ) <= 100 * .Machine$double.eps &&
      sum(energy_rates[[scenario_id]]) ==
        expected_energy_totals[[index]] &&
      sum(activity_rates[[scenario_id]]) ==
        expected_activity_totals[[index]],
    paste(scenario_id, "daily prescribed totals")
  )
  require_that(
    identical(convergence$burn_in_day, seq_len(7L)) &&
      identical(
        convergence$converged,
        c(rep(FALSE, 6L), TRUE)
      ) &&
      all(is.finite(
        convergence$
          max_abs_previous_day_trajectory_difference_kj[-1L]
      )) &&
      all(is.finite(
        convergence$realized_convergence_tolerance_kj[-1L]
      )) &&
      all(
        convergence$realized_convergence_tolerance_kj[-1L] > 0
      ) &&
      abs(tail(convergence$cycle_boundary_change_kj, 1L)) <=
        final_cycle_tolerance &&
      tail(
        convergence$
          max_abs_previous_day_trajectory_difference_kj,
        1L
      ) <= final_cycle_tolerance,
    paste(scenario_id, "day-7 convergence")
  )
  require_that(
    max(abs(
      gut_boundaries_kj(day_2) - gut_boundaries_kj(day_1)
    )) <= final_cycle_tolerance &&
      canonical_equal(
        day_1[repeated_gut_fields],
        day_2[repeated_gut_fields]
      ),
    paste(scenario_id, "measured gut repetition")
  )
  require_that(
    identical(
      result$hourly$gut_available_energy_start_kj[-1L],
      head(result$hourly$gut_available_energy_end_kj, -1L)
    ) &&
      identical(
        result$hourly$body_energy_reserve_start_kj[-1L],
        head(result$hourly$body_energy_reserve_end_kj, -1L)
      ) &&
      identical(
        result$hourly$total_system_energy_start_kj[-1L],
        head(result$hourly$total_system_energy_end_kj, -1L)
      ),
    paste(scenario_id, "exact state carry-over")
  )
  stock_values <- unlist(
    result$hourly[c(
      "gut_available_energy_start_kj",
      "gut_available_energy_end_kj",
      "body_energy_reserve_start_kj",
      "body_energy_reserve_end_kj"
    )],
    use.names = FALSE
  )
  require_that(
    all(is.finite(stock_values)) &&
      all(stock_values >= 0) &&
      identical(
        result$daily$body_energy_status,
        expected_statuses[[scenario_id]]
      ),
    paste(scenario_id, "stocks and body statuses")
  )

  for (measurement_day in 1:2) {
    hourly <- day_rows(result, "hourly", measurement_day)
    daily <- day_rows(result, "daily", measurement_day)
    tolerance <- daily_tolerances(result, measurement_day)
    gut_expected <-
      sum(hourly$prescribed_ingested_available_energy_kj) -
        sum(hourly$assimilated_energy_kj)
    gut_observed <-
      daily$gut_available_energy_final_kj -
        daily$gut_available_energy_initial_kj
    body_expected <-
      sum(hourly$assimilated_energy_kj) -
        sum(hourly$maintenance_expenditure_kj) -
        sum(hourly$prescribed_routine_activity_expenditure_kj)
    body_observed <-
      daily$body_energy_reserve_final_kj -
        daily$body_energy_reserve_initial_kj
    system_expected <-
      sum(hourly$prescribed_ingested_available_energy_kj) -
        sum(hourly$maintenance_expenditure_kj) -
        sum(hourly$prescribed_routine_activity_expenditure_kj)
    system_observed <-
      daily$total_system_energy_final_kj -
        daily$total_system_energy_initial_kj

    require_that(
      identical(daily$expected_gut_energy_change_kj, gut_expected) &&
        identical(daily$observed_gut_energy_change_kj, gut_observed) &&
        abs(
          daily$gut_energy_balance_residual_kj -
            (gut_observed - gut_expected)
        ) <= tolerance[["gut"]] &&
        abs(daily$gut_energy_balance_residual_kj) <=
          tolerance[["gut"]],
      paste(scenario_id, "day", measurement_day, "gut ledger")
    )
    require_that(
      identical(
        daily$expected_body_energy_change_kj,
        body_expected
      ) &&
        identical(
          daily$observed_body_energy_change_kj,
          body_observed
        ) &&
        abs(
          daily$body_energy_balance_residual_kj -
            (body_observed - body_expected)
        ) <= tolerance[["body_ledger"]] &&
        abs(daily$body_energy_balance_residual_kj) <=
          tolerance[["body_ledger"]],
      paste(scenario_id, "day", measurement_day, "body ledger")
    )
    require_that(
      identical(
        daily$expected_total_system_energy_change_kj,
        system_expected
      ) &&
        identical(
          daily$observed_total_system_energy_change_kj,
          system_observed
        ) &&
        abs(
          daily$system_energy_balance_residual_kj -
            (system_observed - system_expected)
        ) <= tolerance[["system"]] &&
        abs(daily$system_energy_balance_residual_kj) <=
          tolerance[["system"]],
      paste(
        scenario_id,
        "day",
        measurement_day,
        "whole-system ledger"
      )
    )
    require_that(
      abs(daily$observed_gut_energy_change_kj) <=
        tolerance[["cycle"]] &&
        abs(
          daily$total_assimilated_energy_kj -
            daily$total_prescribed_ingested_available_energy_kj
        ) <= tolerance[["assimilation"]],
      paste(scenario_id, "day", measurement_day, "periodic gut")
    )
    if (scenario_id !=
      "ecological_activity_uncompensated") {
      require_that(
        abs(daily$observed_body_energy_change_kj) <=
          tolerance[["body_neutrality"]] &&
          abs(daily$observed_total_system_energy_change_kj) <=
            tolerance[["system"]],
        paste(scenario_id, "day", measurement_day, "neutrality")
      )
    }
  }

  invisible(NULL)
}

invisible(Map(
  validate_fixture,
  fixtures,
  seq_along(fixtures)
))

baseline <- fixtures$ecological_day_resting$result
unbalanced <-
  fixtures$ecological_activity_uncompensated$result
balanced <-
  fixtures$ecological_activity_prescribed_balance$result

require_that(
  identical(unbalanced$convergence, baseline$convergence) &&
    identical(
      unbalanced$hourly[gut_fields],
      baseline$hourly[gut_fields]
    ),
  "activity-only convergence and gut invariance"
)

expected_activity_difference <- rep(
  c(rep(50, 8L), rep(0, 8L), rep(50, 8L)),
  2L
)
require_that(
  near(
    baseline$hourly$net_body_energy_rate_kj_h -
      unbalanced$hourly$net_body_energy_rate_kj_h,
    expected_activity_difference
  ) &&
    near(
      baseline$hourly$body_energy_change_kj -
        unbalanced$hourly$body_energy_change_kj,
      expected_activity_difference
    ) &&
    identical(
      baseline$daily$observed_body_energy_change_kj -
        unbalanced$daily$observed_body_energy_change_kj,
      c(800, 800)
    ) &&
    identical(
      baseline$daily$observed_total_system_energy_change_kj -
        unbalanced$daily$observed_total_system_energy_change_kj,
      c(800, 800)
    ),
  "activity-only hourly and daily effects"
)

landmark_indices <- c(1L, 9L, 17L, 25L, 33L, 41L, 49L)
baseline_boundaries <- body_boundaries_kj(baseline$hourly)
unbalanced_boundaries <- body_boundaries_kj(unbalanced$hourly)
balanced_boundaries <- body_boundaries_kj(balanced$hourly)
require_that(
  identical(
    baseline_boundaries[landmark_indices] -
      unbalanced_boundaries[landmark_indices],
    c(0, 400, 400, 800, 1200, 1200, 1600)
  ) &&
    identical(
      baseline$daily$body_energy_reserve_final_kj -
        unbalanced$daily$body_energy_reserve_final_kj,
      c(800, 1600)
    ),
  "activity-only body-boundary landmarks"
)

require_that(
  identical(
    balanced$hourly$
      prescribed_routine_activity_expenditure_kj_h,
    unbalanced$hourly$
      prescribed_routine_activity_expenditure_kj_h
  ) &&
    identical(
      balanced$hourly$maintenance_expenditure_kj_h,
      unbalanced$hourly$maintenance_expenditure_kj_h
    ) &&
    identical(
      balanced$hourly$
        prescribed_ingested_available_energy_kj_h -
        unbalanced$hourly$
          prescribed_ingested_available_energy_kj_h,
      expected_activity_difference
    ) &&
    identical(
      balanced$daily$
        total_prescribed_ingested_available_energy_kj -
        unbalanced$daily$
          total_prescribed_ingested_available_energy_kj,
      c(800, 800)
    ),
  "added-input prescribed forcing"
)

for (measurement_day in 1:2) {
  balanced_daily <- day_rows(balanced, "daily", measurement_day)
  unbalanced_daily <- day_rows(
    unbalanced,
    "daily",
    measurement_day
  )
  balanced_tolerance <- daily_tolerances(
    balanced,
    measurement_day
  )
  unbalanced_tolerance <- daily_tolerances(
    unbalanced,
    measurement_day
  )

  require_that(
    abs(
      (
        balanced_daily$total_assimilated_energy_kj -
          unbalanced_daily$total_assimilated_energy_kj
      ) - 800
    ) <=
      balanced_tolerance[["assimilation"]] +
        unbalanced_tolerance[["assimilation"]] &&
      abs(
        (
          balanced_daily$observed_body_energy_change_kj -
            unbalanced_daily$observed_body_energy_change_kj
        ) - 800
      ) <=
        balanced_tolerance[["body_neutrality"]] +
          unbalanced_tolerance[["body_neutrality"]] &&
      abs(
        (
          balanced_daily$
            observed_total_system_energy_change_kj -
            unbalanced_daily$
              observed_total_system_energy_change_kj
        ) - 800
      ) <=
        balanced_tolerance[["system"]] +
          unbalanced_tolerance[["system"]] &&
      abs(
        (
          balanced_daily$body_energy_reserve_final_kj -
            unbalanced_daily$body_energy_reserve_final_kj
        ) - 800 * measurement_day
      ) <=
        balanced_tolerance[["body_neutrality"]] +
          unbalanced_tolerance[["body_neutrality"]],
    paste("added-input day", measurement_day, "effects")
  )
}

scaling_components <- list(
  burn_in_initial = list(
    observed =
      balanced$convergence$gut_available_energy_initial_kj,
    baseline =
      baseline$convergence$gut_available_energy_initial_kj
  ),
  burn_in_final = list(
    observed =
      balanced$convergence$gut_available_energy_final_kj,
    baseline =
      baseline$convergence$gut_available_energy_final_kj
  ),
  measured_gut_start = list(
    observed = balanced$hourly$gut_available_energy_start_kj,
    baseline = baseline$hourly$gut_available_energy_start_kj
  ),
  measured_gut_end = list(
    observed = balanced$hourly$gut_available_energy_end_kj,
    baseline = baseline$hourly$gut_available_energy_end_kj
  ),
  measured_assimilation = list(
    observed = balanced$hourly$assimilated_energy_kj,
    baseline = baseline$hourly$assimilated_energy_kj
  )
)
scaling_errors <- vapply(
  scaling_components,
  function(component) {
    predicted <- (4 / 3) * component$baseline
    require_that(
      near(component$observed, predicted),
      "balanced four-thirds gut and assimilation scaling"
    )
    max(abs(component$observed - predicted))
  },
  numeric(1L)
)

expected_net_rate_contrast <-
  baseline$hourly$assimilated_energy_kj_h / 3 -
    balanced$hourly$
      prescribed_routine_activity_expenditure_kj_h
observed_net_rate_contrast <-
  balanced$hourly$net_body_energy_rate_kj_h -
    baseline$hourly$net_body_energy_rate_kj_h
require_that(
  near(observed_net_rate_contrast, expected_net_rate_contrast) &&
    max(abs(observed_net_rate_contrast)) > 0 &&
    max(abs(balanced_boundaries - baseline_boundaries)) > 0,
  "distinct neutral-reference within-day trajectories"
)

schedule_summary <- data.frame(
  scenario_id = scenario_ids,
  active_intake_intervals = vapply(
    energy_rates,
    function(value) sum(value > 0),
    integer(1L)
  ),
  rest_intervals = vapply(
    energy_rates,
    function(value) sum(value == 0),
    integer(1L)
  ),
  daily_dry_matter_kg_dm = vapply(
    dry_matter_rates,
    sum,
    numeric(1L)
  ),
  daily_gut_input_kj = vapply(
    energy_rates,
    sum,
    numeric(1L)
  ),
  daily_routine_activity_kj = vapply(
    activity_rates,
    sum,
    numeric(1L)
  ),
  row.names = NULL
)

convergence_summary <- data.frame(
  scenario_id = scenario_ids,
  first_converged_day = vapply(
    fixtures,
    function(fixture) {
      fixture$result$convergence$burn_in_day[
        which(fixture$result$convergence$converged)[[1L]]
      ]
    },
    integer(1L)
  ),
  cycle_boundary_change_kj = vapply(
    fixtures,
    function(fixture) {
      tail(
        fixture$result$convergence$cycle_boundary_change_kj,
        1L
      )
    },
    numeric(1L)
  ),
  row.names = NULL
)

daily_summary <- do.call(rbind, lapply(fixtures, function(fixture) {
  daily <- fixture$result$daily
  data.frame(
    scenario_id = fixture$scenario_id,
    measurement_day = daily$measurement_day,
    prescribed_gut_input_kj =
      daily$total_prescribed_ingested_available_energy_kj,
    assimilated_energy_kj = daily$total_assimilated_energy_kj,
    routine_activity_kj =
      daily$
        total_prescribed_routine_activity_expenditure_kj,
    observed_body_change_kj =
      daily$observed_body_energy_change_kj,
    body_reserve_final_kj =
      daily$body_energy_reserve_final_kj,
    body_energy_status = daily$body_energy_status,
    row.names = NULL
  )
}))
row.names(daily_summary) <- NULL

boundary_summary <- data.frame(
  time_h = c(0, 8, 16, 24, 32, 40, 48),
  ecological_day_resting_kj =
    baseline_boundaries[landmark_indices],
  ecological_activity_uncompensated_kj =
    unbalanced_boundaries[landmark_indices],
  ecological_activity_prescribed_balance_kj =
    balanced_boundaries[landmark_indices],
  baseline_minus_uncompensated_kj =
    baseline_boundaries[landmark_indices] -
      unbalanced_boundaries[landmark_indices],
  row.names = NULL
)

scaling_summary <- data.frame(
  component = names(scaling_errors),
  expected_multiplier = rep(4 / 3, length(scaling_errors)),
  max_absolute_error_kj = unname(scaling_errors),
  row.names = NULL
)

counterfactual_summary <- data.frame(
  measurement_day = 1:2,
  activity_effect_body_change_kj =
    baseline$daily$observed_body_energy_change_kj -
      unbalanced$daily$observed_body_energy_change_kj,
  activity_effect_body_close_kj =
    baseline$daily$body_energy_reserve_final_kj -
      unbalanced$daily$body_energy_reserve_final_kj,
  added_input_assimilation_kj =
    balanced$daily$total_assimilated_energy_kj -
      unbalanced$daily$total_assimilated_energy_kj,
  added_input_body_change_kj =
    balanced$daily$observed_body_energy_change_kj -
      unbalanced$daily$observed_body_energy_change_kj,
  added_input_body_close_kj =
    balanced$daily$body_energy_reserve_final_kj -
      unbalanced$daily$body_energy_reserve_final_kj,
  row.names = NULL
)

print_summary <- function(value) {
  printable <- value
  amount_columns <- grep("_kj$", names(printable), value = TRUE)
  printable[amount_columns] <- lapply(
    printable[amount_columns],
    function(column) as.integer(round(column))
  )
  print(printable, row.names = FALSE, digits = 7)
}

cat("Rebuild Goal 008: prescribed activity and intake balance\n\n")
cat("Prescribed schedule summary\n")
print_summary(schedule_summary)
cat("\nGut convergence summary\n")
print_summary(convergence_summary)
cat("\nMeasured daily summary (stocks and amounts in whole kJ)\n")
print_summary(daily_summary)
cat("\nContinuous body-boundary summary (whole kJ)\n")
print_summary(boundary_summary)
cat("\nFour-thirds scaling summary\n")
print_summary(scaling_summary)
cat("\nCounterfactual summary (whole kJ)\n")
print_summary(counterfactual_summary)
cat(
  "\nThe balanced fixture is a prescribed accounting construction; ",
  "no feeding behavior, intake feasibility, or ecological equilibrium ",
  "is inferred.\n",
  sep = ""
)
cat("All Goal 008 in-memory assertions passed; no files were written.\n")
