arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-019-derived-body-mass.R")

require_goal020 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 020 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

recovery_days_goal020 <- 9L
extension_pair_threshold_kj <- 300
maximum_extension_pairs <- 2L
extension_hour_pairs <- list(
  c(8L, 15L),
  c(9L, 14L)
)
central_rest_hours <- 10:13
reference_feeding_rate_kg_dm_h <- 0.020
feeding_activity_rate_kj_h <- 50
initial_shortfall_kj <- 800

calculate_duration_decision <- function(opening_body_energy_kj) {
  opening_body_deficit_kj <- max(
    0,
    reference_opening_body_energy_kj - opening_body_energy_kj
  )
  indicated_extension_pairs <- min(
    maximum_extension_pairs,
    as.integer(floor(
      opening_body_deficit_kj / extension_pair_threshold_kj
    ))
  )
  indicated_extension_hours <- if (indicated_extension_pairs == 0L) {
    integer()
  } else {
    unlist(
      extension_hour_pairs[seq_len(indicated_extension_pairs)],
      use.names = FALSE
    )
  }

  list(
    opening_body_deficit_kj = opening_body_deficit_kj,
    indicated_extension_pairs = indicated_extension_pairs,
    indicated_extension_hours = indicated_extension_hours
  )
}

make_duration_schedules <- function(applied_extension_pairs) {
  applied_extension_hours <- if (applied_extension_pairs == 0L) {
    integer()
  } else {
    unlist(
      extension_hour_pairs[seq_len(applied_extension_pairs)],
      use.names = FALSE
    )
  }
  effective_feeding_opportunity <-
    feeding_opportunity_open |
      hour_of_day %in% applied_extension_hours
  effective_reference_intake_kg_dm_h <-
    reference_dry_matter_rates_kg_dm_h
  effective_reference_intake_kg_dm_h[
    hour_of_day %in% applied_extension_hours
  ] <- reference_feeding_rate_kg_dm_h
  effective_activity_kj_h <- activity_rates_kj_h
  effective_activity_kj_h[
    hour_of_day %in% applied_extension_hours
  ] <- feeding_activity_rate_kj_h

  list(
    applied_extension_hours = applied_extension_hours,
    appetite_reference_schedule =
      herbivoreTTR::new_appetite_reference_schedule(
        hour_of_day = hour_of_day,
        feeding_opportunity_open = effective_feeding_opportunity,
        reference_dry_matter_intake_kg_dm_h =
          effective_reference_intake_kg_dm_h,
        reference_body_energy_reserve_kj =
          appetite_reference_schedule$reference_body_energy_reserve_kj,
        reference_gut_available_energy_kj =
          appetite_reference_schedule$reference_gut_available_energy_kj
      ),
    routine_activity_schedule =
      herbivoreTTR::new_routine_activity_expenditure_schedule(
        hour_of_day,
        effective_activity_kj_h
      )
  )
}

reference_decision <- calculate_duration_decision(
  reference_opening_body_energy_kj
)
reference_schedules <- make_duration_schedules(
  reference_decision$indicated_extension_pairs
)
reference_identity <- herbivoreTTR::run_appetite_controlled_energy_days(
  initial_gut_state = reference_opening_gut_state,
  initial_body_state = reference_opening_body_state,
  gut_parameters = gut_parameters,
  body_parameters = body_parameters,
  food_parameters = food_parameters,
  appetite_parameters = appetite_parameters,
  appetite_reference_schedule =
    reference_schedules$appetite_reference_schedule,
  forage_acquisition_ceiling_schedule =
    nonlimiting_forage_acquisition_ceiling_schedule,
  routine_activity_schedule = reference_schedules$routine_activity_schedule,
  number_of_days = 1L
)
require_goal020(
  identical(reference_decision$indicated_extension_pairs, 0L) &&
    identical(reference_schedules$applied_extension_hours, integer()) &&
    identical(
      reference_schedules$appetite_reference_schedule,
      appetite_reference_schedule
    ) &&
    identical(
      reference_schedules$routine_activity_schedule,
      routine_activity_schedule
    ) &&
    identical(reference_identity, balanced_appetite_control),
  "exact zero-extension reference identity"
)

run_goal020_recovery <- function(duration_enabled) {
  arm_id <- if (duration_enabled) {
    "duration_enabled"
  } else {
    "duration_disabled"
  }
  current_gut_state <- herbivoreTTR::new_gut_energy_state(
    shortfall_day$daily$gut_available_energy_final_kj
  )
  current_body_state <- herbivoreTTR::new_body_energy_state(
    shortfall_day$daily$body_energy_reserve_final_kj
  )
  day_results <- vector("list", recovery_days_goal020)
  decision_results <- vector("list", recovery_days_goal020)

  for (recovery_day in seq_len(recovery_days_goal020)) {
    decision <- calculate_duration_decision(
      current_body_state$body_energy_reserve_kj
    )
    applied_extension_pairs <- if (duration_enabled) {
      decision$indicated_extension_pairs
    } else {
      0L
    }
    schedules <- make_duration_schedules(applied_extension_pairs)
    result <- herbivoreTTR::run_appetite_controlled_energy_days(
      initial_gut_state = current_gut_state,
      initial_body_state = current_body_state,
      gut_parameters = gut_parameters,
      body_parameters = body_parameters,
      food_parameters = food_parameters,
      appetite_parameters = appetite_parameters,
      appetite_reference_schedule = schedules$appetite_reference_schedule,
      forage_acquisition_ceiling_schedule =
        nonlimiting_forage_acquisition_ceiling_schedule,
      routine_activity_schedule = schedules$routine_activity_schedule,
      number_of_days = 1L
    )

    require_goal020(
      identical(
        result$daily$gut_available_energy_initial_kj,
        current_gut_state$gut_available_energy_kj
      ) &&
        identical(
          result$daily$body_energy_reserve_initial_kj,
          current_body_state$body_energy_reserve_kj
        ),
      sprintf("exact state carry-over into %s day %d", arm_id, recovery_day)
    )
    require_goal020(
      identical(
        result$hourly$hour_of_day[
          result$hourly$feeding_opportunity_open &
            !feeding_opportunity_open
        ],
        sort(schedules$applied_extension_hours)
      ) &&
        all(
          result$hourly$feeding_opportunity_open[
            result$hourly$hour_of_day %in% central_rest_hours
          ] == FALSE
        ) &&
        all(
          result$hourly$reference_dry_matter_intake_kg_dm_h[
            result$hourly$feeding_opportunity_open
          ] == reference_feeding_rate_kg_dm_h
        ) &&
        all(
          result$hourly$maximum_dry_matter_intake_kg_dm_h == 0.025
        ) &&
        all(
          result$hourly$forage_acquisition_ceiling_kg_dm_h == 0.025
        ) &&
        all(
          result$hourly$prescribed_routine_activity_expenditure_kj_h[
            result$hourly$hour_of_day %in%
              schedules$applied_extension_hours
          ] == feeding_activity_rate_kj_h
        ),
      sprintf(
        "unchanged rates and central rest in %s day %d",
        arm_id,
        recovery_day
      )
    )

    expected_total_activity_kj <-
      sum(activity_rates_kj_h) +
        length(schedules$applied_extension_hours) *
          feeding_activity_rate_kj_h
    require_goal020(
      identical(
        result$daily$total_prescribed_routine_activity_expenditure_kj,
        expected_total_activity_kj
      ) &&
        near(result$hourly$gut_energy_balance_residual_kj, 0, scale = 40000) &&
        near(result$hourly$body_energy_balance_residual_kj, 0, scale = 40000) &&
        near(result$hourly$system_energy_balance_residual_kj, 0, scale = 40000),
      sprintf(
        "activity charge and energy closure in %s day %d",
        arm_id,
        recovery_day
      )
    )

    time_offset_h <- as.double(recovery_day - 1L) * 24
    result$hourly$simulation_day <- as.integer(recovery_day)
    result$hourly$time_start_h <-
      result$hourly$time_start_h + time_offset_h
    result$hourly$time_end_h <-
      result$hourly$time_end_h + time_offset_h
    result$daily$simulation_day <- as.integer(recovery_day)
    day_results[[recovery_day]] <- result
    decision_results[[recovery_day]] <- data.frame(
      arm_id = arm_id,
      recovery_day = as.integer(recovery_day),
      opening_body_energy_reserve_kj =
        current_body_state$body_energy_reserve_kj,
      opening_body_deficit_kj = decision$opening_body_deficit_kj,
      indicated_extension_pairs = decision$indicated_extension_pairs,
      indicated_extra_feeding_hours =
        2L * decision$indicated_extension_pairs,
      applied_extension_pairs = applied_extension_pairs,
      applied_extra_feeding_hours =
        2L * applied_extension_pairs,
      applied_extension_hour_labels = if (
        length(schedules$applied_extension_hours) == 0L
      ) {
        "none"
      } else {
        paste(sort(schedules$applied_extension_hours), collapse = ",")
      },
      total_feeding_opportunity_hours =
        sum(result$hourly$feeding_opportunity_open),
      incremental_activity_expenditure_kj =
        length(schedules$applied_extension_hours) *
          feeding_activity_rate_kj_h
    )

    current_gut_state <- herbivoreTTR::new_gut_energy_state(
      result$daily$gut_available_energy_final_kj
    )
    current_body_state <- herbivoreTTR::new_body_energy_state(
      result$daily$body_energy_reserve_final_kj
    )
  }

  hourly <- do.call(rbind, lapply(day_results, `[[`, "hourly"))
  daily <- do.call(rbind, lapply(day_results, `[[`, "daily"))
  decisions <- do.call(rbind, decision_results)
  row.names(hourly) <- NULL
  row.names(daily) <- NULL
  row.names(decisions) <- NULL

  list(hourly = hourly, daily = daily, decisions = decisions)
}

duration_disabled <- run_goal020_recovery(FALSE)
duration_enabled <- run_goal020_recovery(TRUE)

require_goal020(
  identical(duration_disabled$hourly, controlled_result$hourly) &&
    identical(duration_disabled$daily, controlled_result$daily),
  "duration-disabled arm exactly reproduces Goal 013 recovery"
)
require_goal020(
  identical(
    duration_enabled$decisions$applied_extra_feeding_hours,
    2L * duration_enabled$decisions$applied_extension_pairs
  ) &&
    all(
      duration_enabled$decisions$applied_extra_feeding_hours %in%
        c(0L, 2L, 4L)
    ) &&
    all(
      duration_enabled$decisions$applied_extension_pairs ==
        duration_enabled$decisions$indicated_extension_pairs
    ) &&
    all(duration_enabled$daily$body_energy_reserve_final_kj > 0),
  "bounded daily duration rule and positive body reserve"
)

build_goal020_daily <- function(result) {
  derived_mass <- herbivoreTTR::derive_body_mass_from_energy_reserve(
    body_mass_parameters,
    result$daily$body_energy_reserve_final_kj
  )
  data.frame(
    result$decisions,
    realized_dry_matter_intake_kg_dm =
      result$daily$realized_dry_matter_intake_kg_dm,
    total_realized_ingested_available_energy_kj =
      result$daily$total_realized_ingested_available_energy_kj,
    total_routine_activity_expenditure_kj =
      result$daily$total_prescribed_routine_activity_expenditure_kj,
    lower_intake_bound_hours = result$daily$lower_intake_bound_hours,
    upper_intake_bound_hours = result$daily$upper_intake_bound_hours,
    forage_acquisition_ceiling_active_hours =
      result$daily$forage_acquisition_ceiling_active_hours,
    gut_energy_deviation_final_kj =
      result$daily$gut_energy_deviation_from_reference_final_kj,
    body_energy_deviation_final_kj =
      result$daily$body_energy_deviation_from_reference_final_kj,
    combined_energy_deviation_final_kj =
      result$daily$combined_energy_deviation_from_reference_final_kj,
    reserve_tissue_mass_final_kg = derived_mass$reserve_tissue_mass_kg,
    total_body_mass_final_kg = derived_mass$total_body_mass_kg
  )
}

goal020_daily_comparison <- rbind(
  build_goal020_daily(duration_disabled),
  build_goal020_daily(duration_enabled)
)
row.names(goal020_daily_comparison) <- NULL

summarize_goal020_arm <- function(daily) {
  recovery_rows <- which(
    daily$combined_energy_deviation_final_kj >=
      -0.10 * initial_shortfall_kj
  )
  data.frame(
    arm_id = daily$arm_id[[1L]],
    days_to_90_percent_combined_recovery = if (
      length(recovery_rows) == 0L
    ) {
      NA_integer_
    } else {
      as.integer(daily$recovery_day[recovery_rows[[1L]]])
    },
    total_applied_extra_feeding_hours =
      sum(daily$applied_extra_feeding_hours),
    total_incremental_activity_expenditure_kj =
      sum(daily$incremental_activity_expenditure_kj),
    final_combined_energy_deviation_kj =
      tail(daily$combined_energy_deviation_final_kj, 1L),
    final_body_energy_deviation_kj =
      tail(daily$body_energy_deviation_final_kj, 1L),
    final_total_body_mass_kg = tail(daily$total_body_mass_final_kg, 1L),
    body_energy_overshoot = any(daily$body_energy_deviation_final_kj > 0),
    combined_energy_overshoot =
      any(daily$combined_energy_deviation_final_kj > 0)
  )
}

goal020_outcome_summary <- do.call(
  rbind,
  lapply(
    split(goal020_daily_comparison, goal020_daily_comparison$arm_id),
    summarize_goal020_arm
  )
)
row.names(goal020_outcome_summary) <- NULL

goal020_diagnostics <- list(
  reference_identity = reference_identity,
  duration_disabled = duration_disabled,
  duration_enabled = duration_enabled,
  daily_comparison = goal020_daily_comparison,
  outcome_summary = goal020_outcome_summary
)

enabled_summary <- goal020_outcome_summary[
  goal020_outcome_summary$arm_id == "duration_enabled",
  ,
  drop = FALSE
]
disabled_summary <- goal020_outcome_summary[
  goal020_outcome_summary$arm_id == "duration_disabled",
  ,
  drop = FALSE
]
cat(sprintf(
  paste0(
    "Goal 020 diagnostics passed: enabled hours %s; 90%% recovery day ",
    "%s versus %s; final combined deviation %+.0f versus %+.0f kJ.\n"
  ),
  paste(
    duration_enabled$decisions$applied_extra_feeding_hours,
    collapse = ","
  ),
  enabled_summary$days_to_90_percent_combined_recovery,
  disabled_summary$days_to_90_percent_combined_recovery,
  enabled_summary$final_combined_energy_deviation_kj,
  disabled_summary$final_combined_energy_deviation_kj
))
