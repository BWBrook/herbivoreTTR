arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-013-minimal-endogenous-appetite-control.R")

require_goal014 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 014 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

body_feedback_grid_h <- c(0.025, 0.050, 0.100)
gut_feedback_grid_h <- c(0.050, 0.100, 0.200)
deficit_grid_kj <- c(400, 800, 1600)
recovery_days <- 14L
reference_daily_intake_kg_dm <-
  sum(reference_dry_matter_rates_kg_dm_h)
reference_daily_energy_kj <-
  sum(reference_energy_schedule$prescribed_ingested_available_energy_kj_h)
food_energy_density_kj_kg_dm <-
  food_parameters$metabolizable_energy_density_kj_kg_dm
open_feeding_hours <- sum(feeding_opportunity_open)

make_shortfall_day <- function(deficit_kj) {
  shortfall_daily_intake_kg_dm <-
    reference_daily_intake_kg_dm -
      deficit_kj / food_energy_density_kj_kg_dm
  shortfall_rate_kg_dm_h <-
    shortfall_daily_intake_kg_dm / open_feeding_hours
  dry_matter_rates_kg_dm_h <-
    as.double(feeding_opportunity_open) * shortfall_rate_kg_dm_h
  dry_matter_schedule <- herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day,
    dry_matter_rates_kg_dm_h
  )
  energy_schedule <-
    herbivoreTTR::derive_ingested_available_energy_schedule(
      food_parameters,
      dry_matter_schedule
    )
  result <- herbivoreTTR::run_gut_body_energy_day(
    initial_gut_state = reference_opening_gut_state,
    initial_body_state = reference_opening_body_state,
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    schedule = energy_schedule,
    routine_activity_schedule = routine_activity_schedule
  )
  combined_deviation_kj <-
    result$daily$gut_available_energy_final_kj -
      reference_opening_gut_energy_kj +
      result$daily$body_energy_reserve_final_kj -
      reference_opening_body_energy_kj

  require_goal014(
    near(combined_deviation_kj, -deficit_kj, scale = 10000),
    sprintf("exact %.0f-kJ shortfall", deficit_kj)
  )

  list(
    result = result,
    dry_matter_rate_kg_dm_h = shortfall_rate_kg_dm_h,
    combined_deviation_kj = combined_deviation_kj
  )
}

reference_identity_holds <- function(controller_parameters) {
  result <- herbivoreTTR::run_appetite_controlled_energy_days(
    initial_gut_state = reference_opening_gut_state,
    initial_body_state = reference_opening_body_state,
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    food_parameters = food_parameters,
    appetite_parameters = controller_parameters,
    appetite_reference_schedule = appetite_reference_schedule,
    forage_acquisition_ceiling_schedule =
      nonlimiting_forage_acquisition_ceiling_schedule,
    routine_activity_schedule = routine_activity_schedule,
    number_of_days = 1L
  )

  identical(
    result$hourly$realized_dry_matter_intake_kg_dm_h,
    reference_dry_matter_rates_kg_dm_h
  ) &&
    identical(
      result$hourly$gut_available_energy_start_kj,
      reference_hourly$gut_available_energy_start_kj
    ) &&
    identical(
      result$hourly$gut_available_energy_end_kj,
      reference_hourly$gut_available_energy_end_kj
    ) &&
    identical(
      result$hourly$body_energy_reserve_start_kj,
      reference_hourly$body_energy_reserve_start_kj
    ) &&
    identical(
      result$hourly$body_energy_reserve_end_kj,
      reference_hourly$body_energy_reserve_end_kj
    ) &&
    all(result$hourly$body_energy_feedback_kj_h == 0) &&
    all(result$hourly$gut_energy_feedback_kj_h == 0)
}

run_sensitivity_scenario <- function(
  body_feedback_fraction_h,
  gut_feedback_fraction_h,
  deficit_kj
) {
  controller_parameters <- herbivoreTTR::new_appetite_control_parameters(
    maximum_dry_matter_intake_kg_dm_h = 0.025,
    body_energy_feedback_fraction_h = body_feedback_fraction_h,
    gut_energy_feedback_fraction_h = gut_feedback_fraction_h
  )
  exact_reference_identity <- reference_identity_holds(controller_parameters)
  shortfall <- make_shortfall_day(deficit_kj)
  recovery <- herbivoreTTR::run_appetite_controlled_energy_days(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(
      shortfall$result$daily$gut_available_energy_final_kj
    ),
    initial_body_state = herbivoreTTR::new_body_energy_state(
      shortfall$result$daily$body_energy_reserve_final_kj
    ),
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    food_parameters = food_parameters,
    appetite_parameters = controller_parameters,
    appetite_reference_schedule = appetite_reference_schedule,
    forage_acquisition_ceiling_schedule =
      nonlimiting_forage_acquisition_ceiling_schedule,
    routine_activity_schedule = routine_activity_schedule,
    number_of_days = recovery_days
  )
  recovery_hourly <- recovery$hourly
  recovery_daily <- data.frame(
    sequence_day = recovery$daily$simulation_day + 1L,
    forcing = "appetite_control",
    realized_dry_matter_intake_kg_dm =
      recovery$daily$realized_dry_matter_intake_kg_dm,
    realized_ingested_available_energy_kj =
      recovery$daily$total_realized_ingested_available_energy_kj,
    extra_energy_vs_reference_kj =
      recovery$daily$total_realized_ingested_available_energy_kj -
        recovery$daily$total_reference_ingested_available_energy_kj,
    gut_deviation_end_kj =
      recovery$daily$gut_energy_deviation_from_reference_final_kj,
    body_deviation_end_kj =
      recovery$daily$body_energy_deviation_from_reference_final_kj,
    combined_deviation_end_kj =
      recovery$daily$combined_energy_deviation_from_reference_final_kj
  )
  row.names(recovery_daily) <- NULL
  recovery_daily$recovery_day <- recovery$daily$simulation_day
  recovery_daily$body_feedback_fraction_h <- body_feedback_fraction_h
  recovery_daily$gut_feedback_fraction_h <- gut_feedback_fraction_h
  recovery_daily$deficit_kj <- deficit_kj

  shortfall_body_deviation_kj <-
    shortfall$result$daily$body_energy_reserve_final_kj -
      reference_opening_body_energy_kj
  body_trajectory_kj <- c(
    shortfall_body_deviation_kj,
    recovery_daily$body_deviation_end_kj
  )
  combined_trajectory_kj <- c(
    -deficit_kj,
    recovery_daily$combined_deviation_end_kj
  )
  numerical_tolerance_kj <- 1e-8
  days_reaching_90_percent <- which(
    abs(recovery_daily$combined_deviation_end_kj) <= 0.10 * deficit_kj
  )
  days_to_90_percent_recovery <- if (length(days_reaching_90_percent)) {
    days_reaching_90_percent[[1L]]
  } else {
    NA_integer_
  }
  exact_closed_hour_gating <- all(
    recovery_hourly$realized_dry_matter_intake_kg_dm_h[
      !recovery_hourly$feeding_opportunity_open
    ] == 0
  )
  intake_bounds_respected <- all(
    recovery_hourly$realized_dry_matter_intake_kg_dm_h >= 0 &
      recovery_hourly$realized_dry_matter_intake_kg_dm_h <= 0.025
  )
  accounting_closes <-
    near(
      recovery_hourly$gut_energy_balance_residual_kj,
      0,
      scale = 10000
    ) &&
    near(
      recovery_hourly$body_energy_balance_residual_kj,
      0,
      scale = 10000
    ) &&
    near(
      recovery_hourly$system_energy_balance_residual_kj,
      0,
      scale = 10000
    )
  body_does_not_deepen <- all(
    diff(body_trajectory_kj) >= -numerical_tolerance_kj
  )
  body_does_not_overshoot <- all(
    body_trajectory_kj <= numerical_tolerance_kj
  )
  stable_recovery <-
    body_does_not_deepen &&
      body_does_not_overshoot &&
      !is.na(days_to_90_percent_recovery)
  mechanically_valid <-
    exact_reference_identity &&
      exact_closed_hour_gating &&
      intake_bounds_respected &&
      accounting_closes

  summary <- data.frame(
    body_feedback_fraction_h = body_feedback_fraction_h,
    body_feedback_timescale_h = if (body_feedback_fraction_h == 0) {
      Inf
    } else {
      1 / body_feedback_fraction_h
    },
    gut_feedback_fraction_h = gut_feedback_fraction_h,
    gut_feedback_timescale_h = if (gut_feedback_fraction_h == 0) {
      Inf
    } else {
      1 / gut_feedback_fraction_h
    },
    deficit_kj = deficit_kj,
    shortfall_intake_kg_dm_h = shortfall$dry_matter_rate_kg_dm_h,
    days_to_90_percent_recovery = days_to_90_percent_recovery,
    final_body_deviation_kj =
      tail(recovery_daily$body_deviation_end_kj, 1L),
    final_gut_deviation_kj =
      tail(recovery_daily$gut_deviation_end_kj, 1L),
    final_combined_deviation_kj =
      tail(recovery_daily$combined_deviation_end_kj, 1L),
    remaining_combined_deficit_percent =
      100 * abs(tail(recovery_daily$combined_deviation_end_kj, 1L)) /
        deficit_kj,
    maximum_body_overshoot_kj = max(0, body_trajectory_kj),
    maximum_combined_overshoot_kj = max(0, combined_trajectory_kj),
    maximum_daily_intake_kg_dm =
      max(recovery_daily$realized_dry_matter_intake_kg_dm),
    upper_intake_bound_hours =
      sum(recovery_hourly$upper_intake_bound_active),
    lower_intake_bound_hours =
      sum(recovery_hourly$lower_intake_bound_active),
    body_recovery_monotonic = body_does_not_deepen,
    exact_reference_identity = exact_reference_identity,
    mechanically_valid = mechanically_valid,
    stable_recovery = stable_recovery
  )

  list(
    summary = summary,
    recovery_daily = recovery_daily,
    recovery_hourly = recovery_hourly
  )
}

factorial_design <- expand.grid(
  body_feedback_fraction_h = body_feedback_grid_h,
  gut_feedback_fraction_h = gut_feedback_grid_h,
  deficit_kj = deficit_grid_kj,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
factorial_results <- lapply(seq_len(nrow(factorial_design)), function(index) {
  do.call(
    run_sensitivity_scenario,
    as.list(factorial_design[index, , drop = FALSE])
  )
})
factorial_summary <- do.call(
  rbind,
  lapply(factorial_results, function(result) result$summary)
)
row.names(factorial_summary) <- NULL

central_daily_trajectories <- do.call(
  rbind,
  lapply(factorial_results, function(result) {
    is_central <-
      result$summary$body_feedback_fraction_h == 0.05 &&
        result$summary$gut_feedback_fraction_h == 0.10
    if (is_central) result$recovery_daily else NULL
  })
)
row.names(central_daily_trajectories) <- NULL

component_design <- data.frame(
  component_case = c("neither", "body_only", "gut_only", "integrated"),
  body_feedback_fraction_h = c(0, 0.05, 0, 0.05),
  gut_feedback_fraction_h = c(0, 0, 0.10, 0.10),
  deficit_kj = rep(800, 4L),
  stringsAsFactors = FALSE
)
component_results <- lapply(seq_len(nrow(component_design)), function(index) {
  do.call(
    run_sensitivity_scenario,
    as.list(component_design[index, 2:4, drop = FALSE])
  )
})
component_summary <- do.call(
  rbind,
  lapply(seq_along(component_results), function(index) {
    result <- component_results[[index]]$summary
    data.frame(
      component_case = component_design$component_case[[index]],
      result,
      deficit_recovered_percent =
        100 * (800 + result$final_combined_deviation_kj) / 800,
      check.names = FALSE
    )
  })
)
row.names(component_summary) <- NULL
component_daily_trajectories <- do.call(
  rbind,
  lapply(seq_along(component_results), function(index) {
    data.frame(
      component_case = component_design$component_case[[index]],
      component_results[[index]]$recovery_daily,
      check.names = FALSE
    )
  })
)
row.names(component_daily_trajectories) <- NULL

gain_pair_summary <- aggregate(
  stable_recovery ~ body_feedback_fraction_h + gut_feedback_fraction_h,
  data = factorial_summary,
  FUN = all
)
names(gain_pair_summary)[[3L]] <- "robust_over_diagnostic_range"

require_goal014(
  nrow(factorial_summary) == 27L &&
    nrow(component_summary) == 4L &&
    nrow(central_daily_trajectories) == 3L * recovery_days,
  "complete prespecified design"
)
require_goal014(
  all(factorial_summary$mechanically_valid) &&
    all(component_summary$mechanically_valid),
  "reference identity, gating, bounds, and energy accounting"
)
require_goal014(
  identical(
    sort(unique(factorial_summary$shortfall_intake_kg_dm_h)),
    c(0.0100, 0.0150, 0.0175)
  ),
  "prespecified shortfall rates"
)

goal014_diagnostics <- list(
  design = factorial_design,
  factorial_summary = factorial_summary,
  gain_pair_summary = gain_pair_summary,
  central_daily_trajectories = central_daily_trajectories,
  component_summary = component_summary,
  component_daily_trajectories = component_daily_trajectories,
  factorial_results = factorial_results,
  component_results = component_results
)

cat(
  sprintf(
    paste0(
      "Goal 014 diagnostics passed: %d/%d scenarios stable; ",
      "%d/%d gain pairs robust; upper bound active in %d scenarios.\n"
    ),
    sum(factorial_summary$stable_recovery),
    nrow(factorial_summary),
    sum(gain_pair_summary$robust_over_diagnostic_range),
    nrow(gain_pair_summary),
    sum(factorial_summary$upper_intake_bound_hours > 0)
  )
)
