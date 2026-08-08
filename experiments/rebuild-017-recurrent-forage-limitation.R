arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-016-forage-acquisition-ceiling.R")

require_goal017 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 017 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

experiment_days <- 48L
event_deficit_kj <- 800
effective_recovery_threshold_kj <- 0.10 * event_deficit_kj
settling_cycle_threshold_kj <- 0.01 * event_deficit_kj

scenario_event_days <- list(
  unlimited_control = integer(),
  isolated_event = 1L,
  every_8_days = seq.int(1L, experiment_days, by = 8L),
  every_4_days = seq.int(1L, experiment_days, by = 4L),
  every_2_days = seq.int(1L, experiment_days, by = 2L)
)

run_recurrence_scenario <- function(scenario_id, event_days) {
  current_gut_state <- reference_opening_gut_state
  current_body_state <- reference_opening_body_state
  day_results <- vector("list", experiment_days)

  for (simulation_day in seq_len(experiment_days)) {
    limited_forage_day <- simulation_day %in% event_days
    ceiling_schedule <- if (limited_forage_day) {
      binding_forage_acquisition_ceiling_schedule
    } else {
      nonlimiting_forage_acquisition_ceiling_schedule
    }
    result <- herbivoreTTR::run_appetite_controlled_energy_days(
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
    )

    daily <- result$daily
    require_goal017(
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
      simulation_day = as.integer(simulation_day),
      limited_forage_day = limited_forage_day,
      opening_combined_energy_deviation_kj =
        opening_combined_deviation_kj,
      appetite_target_dry_matter_intake_kg_dm =
        daily$appetite_target_dry_matter_intake_kg_dm,
      realized_dry_matter_intake_kg_dm =
        daily$realized_dry_matter_intake_kg_dm,
      appetite_target_minus_realized_kg_dm =
        daily$appetite_target_dry_matter_intake_kg_dm -
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
  }

  daily <- do.call(rbind, day_results)
  row.names(daily) <- NULL
  daily
}

daily_results <- do.call(
  rbind,
  lapply(names(scenario_event_days), function(scenario_id) {
    run_recurrence_scenario(
      scenario_id,
      scenario_event_days[[scenario_id]]
    )
  })
)
row.names(daily_results) <- NULL

build_event_cycles <- function(scenario_id, event_days) {
  if (!length(event_days)) {
    return(NULL)
  }
  scenario_daily <- daily_results[
    daily_results$scenario_id == scenario_id,
    ,
    drop = FALSE
  ]
  event_rows <- match(event_days, scenario_daily$simulation_day)
  recurrent_interval_days <- if (grepl("^every_", scenario_id)) {
    as.integer(sub("every_([0-9]+)_days", "\\1", scenario_id))
  } else {
    NA_integer_
  }
  next_event_days <- if (is.na(recurrent_interval_days)) {
    rep(NA_integer_, length(event_days))
  } else {
    event_days + recurrent_interval_days
  }
  next_event_rows <- match(next_event_days, scenario_daily$simulation_day)
  post_event_deviation_kj <-
    scenario_daily$combined_energy_deviation_final_kj[event_rows]
  next_pre_event_deviation_kj <- rep(NA_real_, length(event_days))
  has_next_event <- !is.na(next_event_rows)
  next_pre_event_deviation_kj[has_next_event] <-
    scenario_daily$opening_combined_energy_deviation_kj[
      next_event_rows[has_next_event]
    ]
  horizon_boundary <-
    !is.na(next_event_days) & next_event_days == experiment_days + 1L
  next_pre_event_deviation_kj[horizon_boundary] <- tail(
    scenario_daily$combined_energy_deviation_final_kj,
    1L
  )

  recovery_before_next_event_kj <-
    next_pre_event_deviation_kj - post_event_deviation_kj

  data.frame(
    scenario_id = scenario_id,
    event_number = seq_along(event_days),
    event_day = as.integer(event_days),
    next_event_day = next_event_days,
    pre_event_combined_energy_deviation_kj =
      scenario_daily$opening_combined_energy_deviation_kj[event_rows],
    post_event_combined_energy_deviation_kj = post_event_deviation_kj,
    event_energy_change_kj =
      scenario_daily$observed_total_system_energy_change_kj[event_rows],
    recovery_before_next_event_kj = recovery_before_next_event_kj,
    recovery_fraction_of_event_loss =
      recovery_before_next_event_kj / event_deficit_kj,
    next_pre_event_combined_energy_deviation_kj =
      next_pre_event_deviation_kj,
    net_energy_change_over_cycle_kj =
      recovery_before_next_event_kj - event_deficit_kj,
    appetite_target_dry_matter_intake_kg_dm =
      scenario_daily$appetite_target_dry_matter_intake_kg_dm[event_rows],
    realized_dry_matter_intake_kg_dm =
      scenario_daily$realized_dry_matter_intake_kg_dm[event_rows],
    upper_intake_bound_hours =
      scenario_daily$upper_intake_bound_hours[event_rows],
    forage_acquisition_ceiling_active_hours =
      scenario_daily$forage_acquisition_ceiling_active_hours[event_rows]
  )
}

event_cycles <- do.call(
  rbind,
  lapply(names(scenario_event_days), function(scenario_id) {
    build_event_cycles(
      scenario_id,
      scenario_event_days[[scenario_id]]
    )
  })
)
row.names(event_cycles) <- NULL

classify_recurrent_pattern <- function(scenario_id, event_days) {
  if (scenario_id == "unlimited_control") {
    return("reference maintained")
  }
  scenario_daily <- daily_results[
    daily_results$scenario_id == scenario_id,
    ,
    drop = FALSE
  ]
  if (scenario_id == "isolated_event") {
    recovered <- which(
      scenario_daily$simulation_day > event_days[[1L]] &
        abs(scenario_daily$combined_energy_deviation_final_kj) <=
          effective_recovery_threshold_kj
    )
    if (length(recovered)) {
      return("isolated event recovered")
    }
    return("isolated event not recovered within horizon")
  }

  cycles <- event_cycles[
    event_cycles$scenario_id == scenario_id &
      !is.na(event_cycles$next_event_day),
    ,
    drop = FALSE
  ]
  if (all(
    abs(cycles$next_pre_event_combined_energy_deviation_kj) <=
      effective_recovery_threshold_kj
  )) {
    return("effective inter-event recovery")
  }
  final_cycle_changes <- tail(
    cycles$net_energy_change_over_cycle_kj,
    2L
  )
  if (
    length(final_cycle_changes) == 2L &&
      all(abs(final_cycle_changes) <= settling_cycle_threshold_kj)
  ) {
    return("apparently settling depressed cycle")
  }
  "energy debt still accumulating over 48 days"
}

scenario_summary <- do.call(
  rbind,
  lapply(names(scenario_event_days), function(scenario_id) {
    event_days <- scenario_event_days[[scenario_id]]
    scenario_daily <- daily_results[
      daily_results$scenario_id == scenario_id,
      ,
      drop = FALSE
    ]
    cycles <- event_cycles[event_cycles$scenario_id == scenario_id, , drop = FALSE]
    completed_cycles <- cycles[!is.na(cycles$next_event_day), , drop = FALSE]
    recovered_days <- which(
      scenario_daily$simulation_day > 1L &
        abs(scenario_daily$combined_energy_deviation_final_kj) <=
          effective_recovery_threshold_kj
    )
    days_to_90_percent_recovery <- if (
      scenario_id == "isolated_event" && length(recovered_days)
    ) {
      recovered_days[[1L]] - 1L
    } else {
      NA_integer_
    }
    data.frame(
      scenario_id = scenario_id,
      recurrence_interval_days = if (grepl("^every_", scenario_id)) {
        as.integer(sub("every_([0-9]+)_days", "\\1", scenario_id))
      } else {
        NA_integer_
      },
      number_of_limited_days = length(event_days),
      final_combined_energy_deviation_kj =
        tail(scenario_daily$combined_energy_deviation_final_kj, 1L),
      minimum_combined_energy_deviation_kj =
        min(scenario_daily$combined_energy_deviation_final_kj),
      final_body_energy_deviation_kj =
        tail(scenario_daily$body_energy_deviation_final_kj, 1L),
      maximum_daily_appetite_target_kg_dm =
        max(scenario_daily$appetite_target_dry_matter_intake_kg_dm),
      maximum_daily_realized_intake_kg_dm =
        max(scenario_daily$realized_dry_matter_intake_kg_dm),
      total_upper_intake_bound_hours =
        sum(scenario_daily$upper_intake_bound_hours),
      days_to_90_percent_recovery_after_isolated_event =
        days_to_90_percent_recovery,
      final_completed_cycle_recovery_fraction = if (nrow(completed_cycles)) {
        tail(completed_cycles$recovery_fraction_of_event_loss, 1L)
      } else {
        NA_real_
      },
      final_completed_cycle_net_energy_change_kj = if (nrow(completed_cycles)) {
        tail(completed_cycles$net_energy_change_over_cycle_kj, 1L)
      } else {
        NA_real_
      },
      observed_pattern = classify_recurrent_pattern(scenario_id, event_days)
    )
  })
)
row.names(scenario_summary) <- NULL

control_daily <- daily_results[
  daily_results$scenario_id == "unlimited_control",
  ,
  drop = FALSE
]
limited_daily <- daily_results[daily_results$limited_forage_day, , drop = FALSE]
nonlimited_daily <- daily_results[!daily_results$limited_forage_day, , drop = FALSE]
first_event_rows <- daily_results[
  daily_results$simulation_day == 1L &
    daily_results$scenario_id != "unlimited_control",
  ,
  drop = FALSE
]
first_event_fields <- c(
  "appetite_target_dry_matter_intake_kg_dm",
  "realized_dry_matter_intake_kg_dm",
  "observed_total_system_energy_change_kj",
  "gut_energy_deviation_final_kj",
  "body_energy_deviation_final_kj",
  "combined_energy_deviation_final_kj"
)

require_goal017(
  near(
    control_daily$combined_energy_deviation_final_kj,
    0,
    scale = 10000
  ) &&
    !any(control_daily$forage_acquisition_ceiling_active_hours > 0L),
  "unlimited control remains on the accepted reference"
)
require_goal017(
  all(vapply(
    first_event_rows[first_event_fields],
    function(values) near(values, values[[1L]], scale = 10000),
    logical(1L)
  )),
  "all event treatments share one identical first limited day"
)
require_goal017(
  near(
    limited_daily$observed_total_system_energy_change_kj,
    -event_deficit_kj,
    scale = 10000
  ) &&
    near(limited_daily$realized_dry_matter_intake_kg_dm, 0.24) &&
    all(limited_daily$forage_acquisition_ceiling_active_hours == 16L),
  "every limited day retains the exact Goal 016 forcing consequence"
)
require_goal017(
  !any(nonlimited_daily$forage_acquisition_ceiling_active_hours > 0L),
  "the accepted non-binding ceiling remains inactive on recovery days"
)
require_goal017(
  all(
    abs(daily_results$gut_energy_balance_residual_kj) <=
      100 * .Machine$double.eps * 10000
  ) &&
    all(
      abs(daily_results$body_energy_balance_residual_kj) <=
        100 * .Machine$double.eps * 10000
    ) &&
    all(
      abs(daily_results$system_energy_balance_residual_kj) <=
        100 * .Machine$double.eps * 10000
    ),
  "daily gut, body, and whole-system accounting closure"
)
require_goal017(
  all(daily_results$body_energy_deviation_final_kj > -10000),
  "body reserve remains positive throughout the declared horizon"
)

goal017_diagnostics <- list(
  design = data.frame(
    scenario_id = names(scenario_event_days),
    event_days = vapply(
      scenario_event_days,
      function(days) paste(days, collapse = ","),
      character(1L)
    )
  ),
  daily = daily_results,
  event_cycles = event_cycles,
  summary = scenario_summary
)

cat("Goal 017 diagnostics passed.\n")
for (summary_row in seq_len(nrow(scenario_summary))) {
  cat(sprintf(
    paste0(
      "  %s: final %+.0f kJ; minimum %+.0f kJ; maximum target ",
      "%.3f kg DM; upper bound %d h; %s.\n"
    ),
    scenario_summary$scenario_id[[summary_row]],
    scenario_summary$final_combined_energy_deviation_kj[[summary_row]],
    scenario_summary$minimum_combined_energy_deviation_kj[[summary_row]],
    scenario_summary$maximum_daily_appetite_target_kg_dm[[summary_row]],
    scenario_summary$total_upper_intake_bound_hours[[summary_row]],
    scenario_summary$observed_pattern[[summary_row]]
  ))
}
