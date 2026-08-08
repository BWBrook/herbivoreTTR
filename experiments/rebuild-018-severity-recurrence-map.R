arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-017-recurrent-forage-limitation.R")

require_goal018 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 018 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

severity_design <- data.frame(
  severity_id = c("mild_400", "central_800", "strong_1200"),
  forage_ceiling_kg_dm_h = c(0.0175, 0.0150, 0.0125),
  event_loss_kj = c(400, 800, 1200)
)
recurrence_intervals_days <- c(8L, 4L, 2L)
experiment_days_goal018 <- 48L
reference_feeding_rate_kg_dm_h <- 0.020
feeding_hours_per_day <- sum(feeding_opportunity_open)
body_reserve_boundary_message <-
  "The proposed closing body-energy reserve is negative."
reference_daily_expenditure_kj <-
  24 * body_parameters$maintenance_expenditure_kj_h +
    sum(activity_rates_kj_h)
maximum_nonlimited_daily_input_kj <-
  feeding_hours_per_day *
    appetite_parameters$maximum_dry_matter_intake_kg_dm_h *
    food_parameters$metabolizable_energy_density_kj_kg_dm
maximum_nonlimited_daily_surplus_kj <-
  maximum_nonlimited_daily_input_kj - reference_daily_expenditure_kj

analytical_event_losses_kj <-
  feeding_hours_per_day *
    (
      reference_feeding_rate_kg_dm_h -
        severity_design$forage_ceiling_kg_dm_h
    ) *
    food_parameters$metabolizable_energy_density_kj_kg_dm
require_goal018(
  near(analytical_event_losses_kj, severity_design$event_loss_kj),
  "declared severity levels have exact analytical event losses"
)

make_limited_ceiling_schedule <- function(forage_ceiling_kg_dm_h) {
  herbivoreTTR::new_forage_acquisition_ceiling_schedule(
    hour_of_day,
    as.double(feeding_opportunity_open) * forage_ceiling_kg_dm_h
  )
}

run_severity_recurrence_scenario <- function(
  severity_id,
  forage_ceiling_kg_dm_h,
  event_loss_kj,
  recurrence_interval_days
) {
  scenario_id <- sprintf(
    "%s_every_%d_days",
    severity_id,
    recurrence_interval_days
  )
  limited_schedule <- make_limited_ceiling_schedule(
    forage_ceiling_kg_dm_h
  )
  current_gut_state <- reference_opening_gut_state
  current_body_state <- reference_opening_body_state
  day_results <- vector("list", experiment_days_goal018)
  boundary_day <- NA_integer_
  completed_days <- 0L

  for (simulation_day in seq_len(experiment_days_goal018)) {
    limited_forage_day <-
      (simulation_day - 1L) %% recurrence_interval_days == 0L
    ceiling_schedule <- if (limited_forage_day) {
      limited_schedule
    } else {
      nonlimiting_forage_acquisition_ceiling_schedule
    }
    result <- tryCatch(
      herbivoreTTR::run_appetite_controlled_energy_days(
        initial_gut_state = current_gut_state,
        initial_body_state = current_body_state,
        gut_parameters = gut_parameters,
        body_parameters = body_parameters,
        food_parameters = food_parameters,
        appetite_parameters = appetite_parameters,
        appetite_reference_schedule = appetite_reference_schedule,
        forage_acquisition_ceiling_schedule = ceiling_schedule,
        routine_activity_schedule = routine_activity_schedule,
        number_of_days = 1L
      ),
      error = function(error) error
    )
    if (inherits(result, "error")) {
      if (!identical(conditionMessage(result), body_reserve_boundary_message)) {
        stop(result)
      }
      boundary_day <- as.integer(simulation_day)
      break
    }

    daily <- result$daily
    require_goal018(
      identical(
        daily$gut_available_energy_initial_kj,
        current_gut_state$gut_available_energy_kj
      ) &&
        identical(
          daily$body_energy_reserve_initial_kj,
          current_body_state$body_energy_reserve_kj
        ),
      sprintf("exact state carry-over into %s day %d", scenario_id, simulation_day)
    )
    opening_combined_deviation_kj <-
      daily$gut_available_energy_initial_kj -
        reference_opening_gut_energy_kj +
        daily$body_energy_reserve_initial_kj -
        reference_opening_body_energy_kj
    day_results[[simulation_day]] <- data.frame(
      scenario_id = scenario_id,
      severity_id = severity_id,
      event_loss_kj = event_loss_kj,
      forage_ceiling_kg_dm_h = forage_ceiling_kg_dm_h,
      recurrence_interval_days = recurrence_interval_days,
      simulation_day = as.integer(simulation_day),
      limited_forage_day = limited_forage_day,
      opening_combined_energy_deviation_kj =
        opening_combined_deviation_kj,
      appetite_target_dry_matter_intake_kg_dm =
        daily$appetite_target_dry_matter_intake_kg_dm,
      realized_dry_matter_intake_kg_dm =
        daily$realized_dry_matter_intake_kg_dm,
      upper_intake_bound_hours = daily$upper_intake_bound_hours,
      forage_acquisition_ceiling_active_hours =
        daily$forage_acquisition_ceiling_active_hours,
      observed_total_system_energy_change_kj =
        daily$observed_total_system_energy_change_kj,
      gut_energy_deviation_final_kj =
        daily$gut_energy_deviation_from_reference_final_kj,
      body_energy_deviation_final_kj =
        daily$body_energy_deviation_from_reference_final_kj,
      body_energy_reserve_final_kj =
        daily$body_energy_reserve_final_kj,
      combined_energy_deviation_final_kj =
        daily$combined_energy_deviation_from_reference_final_kj,
      gut_energy_balance_residual_kj =
        daily$gut_energy_balance_residual_kj,
      body_energy_balance_residual_kj =
        daily$body_energy_balance_residual_kj,
      system_energy_balance_residual_kj =
        daily$system_energy_balance_residual_kj
    )

    current_gut_state <- herbivoreTTR::new_gut_energy_state(
      daily$gut_available_energy_final_kj
    )
    current_body_state <- herbivoreTTR::new_body_energy_state(
      daily$body_energy_reserve_final_kj
    )
    completed_days <- as.integer(simulation_day)
  }

  day_results <- day_results[seq_len(completed_days)]
  daily <- do.call(rbind, day_results)
  row.names(daily) <- NULL
  list(
    daily = daily,
    boundary_day = boundary_day,
    completed_days = completed_days
  )
}

factorial_design <- merge(
  severity_design,
  data.frame(recurrence_interval_days = recurrence_intervals_days),
  by = NULL,
  sort = FALSE
)
factorial_design <- factorial_design[
  order(
    match(factorial_design$severity_id, severity_design$severity_id),
    match(
      factorial_design$recurrence_interval_days,
      recurrence_intervals_days
    )
  ),
  ,
  drop = FALSE
]
row.names(factorial_design) <- NULL

scenario_results <- lapply(seq_len(nrow(factorial_design)), function(index) {
  do.call(
    run_severity_recurrence_scenario,
    as.list(factorial_design[index, , drop = FALSE])
  )
})
severity_daily_results <- do.call(
  rbind,
  lapply(scenario_results, `[[`, "daily")
)
row.names(severity_daily_results) <- NULL

build_goal018_cycles <- function(scenario_result) {
  daily <- scenario_result$daily
  interval_days <- daily$recurrence_interval_days[[1L]]
  event_rows <- which(daily$limited_forage_day)
  event_days <- daily$simulation_day[event_rows]
  next_event_days <- event_days + interval_days
  next_event_rows <- match(next_event_days, daily$simulation_day)
  next_pre_event_deviation_kj <- rep(NA_real_, length(event_rows))
  within_completed_days <- !is.na(next_event_rows)
  next_pre_event_deviation_kj[within_completed_days] <-
    daily$opening_combined_energy_deviation_kj[
      next_event_rows[within_completed_days]
    ]
  next_boundary <-
    next_event_days == scenario_result$completed_days + 1L &
      (
        scenario_result$completed_days == experiment_days_goal018 ||
          !is.na(scenario_result$boundary_day)
      )
  if (length(next_boundary) && any(next_boundary)) {
    next_pre_event_deviation_kj[next_boundary] <- tail(
      daily$combined_energy_deviation_final_kj,
      1L
    )
  }
  post_event_deviation_kj <-
    daily$combined_energy_deviation_final_kj[event_rows]
  recovery_before_next_event_kj <-
    next_pre_event_deviation_kj - post_event_deviation_kj

  data.frame(
    scenario_id = daily$scenario_id[[1L]],
    severity_id = daily$severity_id[[1L]],
    event_loss_kj = daily$event_loss_kj[[1L]],
    recurrence_interval_days = interval_days,
    event_number = seq_along(event_rows),
    event_day = event_days,
    next_scheduled_event_day = next_event_days,
    pre_event_combined_energy_deviation_kj =
      daily$opening_combined_energy_deviation_kj[event_rows],
    post_event_combined_energy_deviation_kj = post_event_deviation_kj,
    recovery_before_next_event_kj = recovery_before_next_event_kj,
    recovery_fraction_of_event_loss =
      recovery_before_next_event_kj / daily$event_loss_kj[[1L]],
    next_pre_event_combined_energy_deviation_kj =
      next_pre_event_deviation_kj,
    net_energy_change_over_cycle_kj =
      recovery_before_next_event_kj - daily$event_loss_kj[[1L]],
    appetite_target_dry_matter_intake_kg_dm =
      daily$appetite_target_dry_matter_intake_kg_dm[event_rows],
    realized_dry_matter_intake_kg_dm =
      daily$realized_dry_matter_intake_kg_dm[event_rows],
    upper_intake_bound_hours = daily$upper_intake_bound_hours[event_rows]
  )
}

severity_event_cycles <- do.call(
  rbind,
  lapply(scenario_results, build_goal018_cycles)
)
row.names(severity_event_cycles) <- NULL

classify_goal018_pattern <- function(scenario_result, cycles) {
  if (!is.na(scenario_result$boundary_day)) {
    return("positive body-reserve boundary reached")
  }
  event_loss_kj <- cycles$event_loss_kj[[1L]]
  complete_cycles <- cycles[!is.na(cycles$recovery_before_next_event_kj), ]
  if (all(
    abs(complete_cycles$next_pre_event_combined_energy_deviation_kj) <=
      0.10 * event_loss_kj
  )) {
    return("effective inter-event recovery")
  }
  final_cycle_changes <- tail(
    complete_cycles$net_energy_change_over_cycle_kj,
    2L
  )
  if (
    length(final_cycle_changes) == 2L &&
      all(abs(final_cycle_changes) <= 0.01 * event_loss_kj)
  ) {
    return("apparently settling depressed cycle")
  }
  "energy debt still accumulating over completed horizon"
}

scenario_summaries <- lapply(seq_along(scenario_results), function(index) {
  result <- scenario_results[[index]]
  daily <- result$daily
  cycles <- severity_event_cycles[
    severity_event_cycles$scenario_id == daily$scenario_id[[1L]],
    ,
    drop = FALSE
  ]
  complete_cycles <- cycles[!is.na(cycles$recovery_before_next_event_kj), ]
  data.frame(
    scenario_id = daily$scenario_id[[1L]],
    severity_id = daily$severity_id[[1L]],
    event_loss_kj = daily$event_loss_kj[[1L]],
    forage_ceiling_kg_dm_h = daily$forage_ceiling_kg_dm_h[[1L]],
    recurrence_interval_days = daily$recurrence_interval_days[[1L]],
    completed_days = result$completed_days,
    boundary_day = result$boundary_day,
    completed_limited_days = sum(daily$limited_forage_day),
    maximum_attainable_cycle_energy_margin_kj =
      (daily$recurrence_interval_days[[1L]] - 1L) *
        maximum_nonlimited_daily_surplus_kj -
        daily$event_loss_kj[[1L]],
    final_valid_combined_energy_deviation_kj =
      tail(daily$combined_energy_deviation_final_kj, 1L),
    minimum_completed_combined_energy_deviation_kj =
      min(daily$combined_energy_deviation_final_kj),
    final_valid_body_energy_reserve_kj =
      tail(daily$body_energy_reserve_final_kj, 1L),
    minimum_completed_body_energy_reserve_kj =
      min(daily$body_energy_reserve_final_kj),
    maximum_daily_appetite_target_kg_dm =
      max(daily$appetite_target_dry_matter_intake_kg_dm),
    total_upper_intake_bound_hours = sum(daily$upper_intake_bound_hours),
    final_complete_cycle_recovery_fraction =
      tail(complete_cycles$recovery_fraction_of_event_loss, 1L),
    final_complete_cycle_net_energy_change_kj =
      tail(complete_cycles$net_energy_change_over_cycle_kj, 1L),
    observed_pattern = classify_goal018_pattern(result, cycles)
  )
})
severity_recurrence_summary <- do.call(rbind, scenario_summaries)
row.names(severity_recurrence_summary) <- NULL

limited_days <- severity_daily_results[
  severity_daily_results$limited_forage_day,
  ,
  drop = FALSE
]
nonlimited_days <- severity_daily_results[
  !severity_daily_results$limited_forage_day,
  ,
  drop = FALSE
]
require_goal018(
  near(
    limited_days$observed_total_system_energy_change_kj,
    -limited_days$event_loss_kj,
    scale = 10000
  ) &&
    near(
      limited_days$realized_dry_matter_intake_kg_dm,
      16 * limited_days$forage_ceiling_kg_dm_h
    ) &&
    all(limited_days$forage_acquisition_ceiling_active_hours == 16L),
  "every completed event retains its exact analytical consequence"
)
require_goal018(
  near(reference_daily_expenditure_kj, 3200) &&
    near(maximum_nonlimited_daily_input_kj, 4000) &&
    near(maximum_nonlimited_daily_surplus_kj, 800),
  "accepted reference retains an exact 800-kJ maximum recovery-day surplus"
)
require_goal018(
  !any(nonlimited_days$forage_acquisition_ceiling_active_hours > 0L),
  "non-limited recovery days retain the accepted non-binding ceiling"
)
require_goal018(
  all(severity_daily_results$body_energy_reserve_final_kj > 0) &&
    near(
      severity_daily_results$gut_energy_balance_residual_kj,
      0,
      scale = 10000
    ) &&
    near(
      severity_daily_results$body_energy_balance_residual_kj,
      0,
      scale = 10000
    ) &&
    near(
      severity_daily_results$system_energy_balance_residual_kj,
      0,
      scale = 10000
    ),
  "positive completed reserves and exact energy-accounting closure"
)

goal017_to_goal018_fields <- c(
  "simulation_day",
  "limited_forage_day",
  "opening_combined_energy_deviation_kj",
  "appetite_target_dry_matter_intake_kg_dm",
  "realized_dry_matter_intake_kg_dm",
  "upper_intake_bound_hours",
  "forage_acquisition_ceiling_active_hours",
  "observed_total_system_energy_change_kj",
  "gut_energy_deviation_final_kj",
  "body_energy_deviation_final_kj",
  "combined_energy_deviation_final_kj"
)
central_identity <- vapply(recurrence_intervals_days, function(interval_days) {
  goal017_id <- sprintf("every_%d_days", interval_days)
  goal018_id <- sprintf("central_800_every_%d_days", interval_days)
  goal017_rows <- daily_results[
    daily_results$scenario_id == goal017_id,
    goal017_to_goal018_fields,
    drop = FALSE
  ]
  goal018_rows <- severity_daily_results[
    severity_daily_results$scenario_id == goal018_id,
    goal017_to_goal018_fields,
    drop = FALSE
  ]
  row.names(goal017_rows) <- NULL
  row.names(goal018_rows) <- NULL
  identical(goal017_rows, goal018_rows)
}, logical(1L))
require_goal018(
  all(central_identity),
  "central severity reproduces all Goal 017 recurrence trajectories exactly"
)

goal018_diagnostics <- list(
  design = factorial_design,
  daily = severity_daily_results,
  event_cycles = severity_event_cycles,
  summary = severity_recurrence_summary
)

cat("Goal 018 diagnostics passed.\n")
for (summary_row in seq_len(nrow(severity_recurrence_summary))) {
  cat(sprintf(
    paste0(
      "  %s: %d/%d days; final valid %+.0f kJ; reserve %.0f kJ; ",
      "upper bound %d h; %s.\n"
    ),
    severity_recurrence_summary$scenario_id[[summary_row]],
    severity_recurrence_summary$completed_days[[summary_row]],
    experiment_days_goal018,
    severity_recurrence_summary$
      final_valid_combined_energy_deviation_kj[[summary_row]],
    severity_recurrence_summary$
      final_valid_body_energy_reserve_kj[[summary_row]],
    severity_recurrence_summary$total_upper_intake_bound_hours[[summary_row]],
    severity_recurrence_summary$observed_pattern[[summary_row]]
  ))
}
