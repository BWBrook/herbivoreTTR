arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-026-repeated-food-quality.R")

require_goal027 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 027 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

goal027_days <- goal026_days
lower_quality_food_parameters <-
  herbivoreTTR::new_food_energy_parameters(8000)

make_goal027_decision_row <- function(
  arm_id,
  simulation_day,
  opening_body_energy_kj,
  duration_enabled
) {
  decision <- calculate_duration_decision(opening_body_energy_kj)
  applied_pairs <- if (duration_enabled) {
    decision$indicated_extension_pairs
  } else {
    0L
  }
  schedules <- make_duration_schedules(applied_pairs)
  data.frame(
    arm_id = arm_id,
    simulation_day = as.integer(simulation_day),
    duration_response_enabled = duration_enabled,
    opening_body_energy_reserve_kj = opening_body_energy_kj,
    opening_body_deficit_kj = decision$opening_body_deficit_kj,
    indicated_extra_feeding_hours =
      2L * decision$indicated_extension_pairs,
    applied_extension_pairs = applied_pairs,
    applied_extra_feeding_hours = 2L * applied_pairs,
    applied_extension_hour_labels = if (
      length(schedules$applied_extension_hours) == 0L
    ) {
      "none"
    } else {
      paste(sort(schedules$applied_extension_hours), collapse = ",")
    },
    total_feeding_opportunity_hours =
      sum(feeding_opportunity_open) +
        length(schedules$applied_extension_hours),
    incremental_activity_expenditure_kj =
      length(schedules$applied_extension_hours) *
        feeding_activity_rate_kj_h,
    stringsAsFactors = FALSE
  )
}

make_fixed_goal027_decisions <- function(arm_id, result) {
  decisions <- do.call(
    rbind,
    lapply(seq_len(goal027_days), function(day_index) {
      make_goal027_decision_row(
        arm_id = arm_id,
        simulation_day = day_index,
        opening_body_energy_kj =
          result$daily$body_energy_reserve_initial_kj[[day_index]],
        duration_enabled = FALSE
      )
    })
  )
  row.names(decisions) <- NULL
  decisions
}

run_lower_responsive_duration <- function() {
  current_gut_state <- reference_opening_gut_state
  current_body_state <- reference_opening_body_state
  day_results <- vector("list", goal027_days)
  decision_results <- vector("list", goal027_days)

  for (simulation_day in seq_len(goal027_days)) {
    decision_row <- make_goal027_decision_row(
      arm_id = "lower_responsive_duration",
      simulation_day = simulation_day,
      opening_body_energy_kj =
        current_body_state$body_energy_reserve_kj,
      duration_enabled = TRUE
    )
    schedules <- make_duration_schedules(
      decision_row$applied_extension_pairs
    )
    result <- herbivoreTTR::run_appetite_controlled_energy_days(
      initial_gut_state = current_gut_state,
      initial_body_state = current_body_state,
      gut_parameters = gut_parameters,
      body_parameters = body_parameters,
      food_parameters = lower_quality_food_parameters,
      appetite_parameters = appetite_parameters,
      appetite_reference_schedule = schedules$appetite_reference_schedule,
      forage_acquisition_ceiling_schedule =
        nonlimiting_forage_acquisition_ceiling_schedule,
      routine_activity_schedule = schedules$routine_activity_schedule,
      number_of_days = 1L
    )

    newly_opened_hours <- result$hourly$hour_of_day[
      result$hourly$feeding_opportunity_open &
        !feeding_opportunity_open
    ]
    require_goal027(
      identical(
        result$daily$gut_available_energy_initial_kj,
        current_gut_state$gut_available_energy_kj
      ) &&
        identical(
          result$daily$body_energy_reserve_initial_kj,
          current_body_state$body_energy_reserve_kj
        ) &&
        identical(
          newly_opened_hours,
          sort(schedules$applied_extension_hours)
        ) &&
        all(
          result$hourly$feeding_opportunity_open[
            result$hourly$hour_of_day %in% central_rest_hours
          ] == FALSE
        ),
      sprintf("state carry-over and duration schedule on day %d", simulation_day)
    )
    require_goal027(
      all(
        result$hourly$reference_dry_matter_intake_kg_dm_h[
          result$hourly$feeding_opportunity_open
        ] == reference_feeding_rate_kg_dm_h
      ) &&
        all(result$hourly$maximum_dry_matter_intake_kg_dm_h == 0.025) &&
        all(
          result$hourly$forage_acquisition_ceiling_kg_dm_h == 0.025
        ) &&
        all(
          result$hourly$prescribed_routine_activity_expenditure_kj_h[
            result$hourly$hour_of_day %in%
              schedules$applied_extension_hours
          ] == feeding_activity_rate_kj_h
        ),
      sprintf("accepted rates and extension activity on day %d", simulation_day)
    )

    time_offset_h <- as.double(simulation_day - 1L) * 24
    result$hourly$simulation_day <- as.integer(simulation_day)
    result$hourly$time_start_h <-
      result$hourly$time_start_h + time_offset_h
    result$hourly$time_end_h <-
      result$hourly$time_end_h + time_offset_h
    result$daily$simulation_day <- as.integer(simulation_day)
    day_results[[simulation_day]] <- result
    decision_results[[simulation_day]] <- decision_row

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

goal027_results <- list(
  adequate_fixed_duration = list(
    hourly = goal026_results$adequate_quality$hourly,
    daily = goal026_results$adequate_quality$daily,
    decisions = make_fixed_goal027_decisions(
      "adequate_fixed_duration",
      goal026_results$adequate_quality
    )
  ),
  lower_fixed_duration = list(
    hourly = goal026_results$lower_quality$hourly,
    daily = goal026_results$lower_quality$daily,
    decisions = make_fixed_goal027_decisions(
      "lower_fixed_duration",
      goal026_results$lower_quality
    )
  ),
  lower_responsive_duration = run_lower_responsive_duration()
)

build_goal027_daily <- function(arm_id, result) {
  daily <- result$daily
  decisions <- result$decisions
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
    duration_response_enabled = decisions$duration_response_enabled,
    opening_body_deficit_kj = decisions$opening_body_deficit_kj,
    applied_extra_feeding_hours = decisions$applied_extra_feeding_hours,
    applied_extension_hour_labels =
      decisions$applied_extension_hour_labels,
    total_feeding_opportunity_hours =
      decisions$total_feeding_opportunity_hours,
    incremental_activity_expenditure_kj =
      decisions$incremental_activity_expenditure_kj,
    opening_combined_energy_deviation_kj =
      opening_combined_deviation_kj,
    appetite_target_dry_matter_intake_kg_dm =
      daily$appetite_target_dry_matter_intake_kg_dm,
    realized_dry_matter_intake_kg_dm =
      daily$realized_dry_matter_intake_kg_dm,
    realized_ingested_available_energy_kj =
      daily$total_realized_ingested_available_energy_kj,
    routine_activity_expenditure_kj =
      daily$total_prescribed_routine_activity_expenditure_kj,
    daily_combined_energy_change_kj = daily_change_kj,
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

goal027_daily <- do.call(
  rbind,
  lapply(names(goal027_results), function(arm_id) {
    build_goal027_daily(arm_id, goal027_results[[arm_id]])
  })
)
row.names(goal027_daily) <- NULL

fixed_lower_day_one <- goal027_daily[
  goal027_daily$arm_id == "lower_fixed_duration" &
    goal027_daily$simulation_day == 1L,
  ,
  drop = FALSE
]
responsive_daily <- goal027_daily[
  goal027_daily$arm_id == "lower_responsive_duration",
  ,
  drop = FALSE
]
goal026_day_one_deficit_kj <-
  fixed_lower_day_one$cumulative_energy_deficit_kj
remaining_day_ten_deficit_kj <-
  responsive_daily$cumulative_energy_deficit_kj[[goal027_days]]
restoration_fraction <-
  (goal026_day_one_deficit_kj - remaining_day_ten_deficit_kj) /
    goal026_day_one_deficit_kj
restoration_threshold_kj <- 0.10 * goal026_day_one_deficit_kj
restoration_days <- responsive_daily$simulation_day[
  responsive_daily$cumulative_energy_deficit_kj <=
    restoration_threshold_kj
]
first_90_percent_restoration_day <- if (length(restoration_days)) {
  restoration_days[[1L]]
} else {
  NA_integer_
}

goal027_assessment <- data.frame(
  goal026_day_one_deficit_kj = goal026_day_one_deficit_kj,
  day_ten_remaining_deficit_kj = remaining_day_ten_deficit_kj,
  day_ten_restoration_fraction = restoration_fraction,
  restoration_target_fraction = 0.90,
  restoration_target_met = restoration_fraction >= 0.90,
  first_90_percent_restoration_day =
    first_90_percent_restoration_day,
  total_applied_extra_feeding_hours =
    sum(responsive_daily$applied_extra_feeding_hours),
  day_ten_applied_extra_feeding_hours =
    responsive_daily$applied_extra_feeding_hours[[goal027_days]],
  stringsAsFactors = FALSE
)

require_goal027(
  identical(
    goal027_results$adequate_fixed_duration$hourly,
    goal026_results$adequate_quality$hourly
  ) &&
    identical(
      goal027_results$adequate_fixed_duration$daily,
      goal026_results$adequate_quality$daily
    ) &&
    identical(
      goal027_results$lower_fixed_duration$hourly,
      goal026_results$lower_quality$hourly
    ) &&
    identical(
      goal027_results$lower_fixed_duration$daily,
      goal026_results$lower_quality$daily
    ),
  "exact Goal 026 fixed-duration anchors"
)

responsive_day_one <- goal027_results$lower_responsive_duration
responsive_day_one_hourly <- responsive_day_one$hourly[
  responsive_day_one$hourly$simulation_day == 1L,
  ,
  drop = FALSE
]
fixed_day_one_hourly <- goal027_results$lower_fixed_duration$hourly[
  goal027_results$lower_fixed_duration$hourly$simulation_day == 1L,
  ,
  drop = FALSE
]
require_goal027(
  identical(responsive_day_one_hourly, fixed_day_one_hourly) &&
    responsive_daily$applied_extra_feeding_hours[[1L]] == 0L,
  "exact lower-quality fixed-duration day-one identity"
)

require_goal027(
  all(responsive_daily$applied_extra_feeding_hours %in% c(0L, 2L, 4L)) &&
    all(responsive_daily$total_feeding_opportunity_hours %in% 16:20) &&
    all(
      responsive_daily$routine_activity_expenditure_kj ==
        800 + responsive_daily$incremental_activity_expenditure_kj
    ) &&
    all(goal027_daily$forage_acquisition_ceiling_active_hours == 0L) &&
    all(goal027_daily$lower_intake_bound_hours == 0L) &&
    all(goal027_daily$upper_intake_bound_hours >= 0L) &&
    all(goal027_daily$upper_intake_bound_hours <= 20L) &&
    all(goal027_daily$body_energy_reserve_final_kj > 0),
  "bounded duration, activity, non-limiting acquisition, and positive reserve"
)
require_goal027(
  near(
    goal027_daily$gut_energy_balance_residual_kj,
    0,
    scale = reference_opening_body_energy_kj
  ) &&
    near(
      goal027_daily$body_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      goal027_daily$system_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    is.finite(restoration_fraction),
  "closed accounting and finite restoration assessment"
)

goal027_diagnostics <- list(
  results = goal027_results,
  daily = goal027_daily,
  assessment = goal027_assessment
)

fixed_lower_day_ten <- goal027_daily[
  goal027_daily$arm_id == "lower_fixed_duration" &
    goal027_daily$simulation_day == goal027_days,
  ,
  drop = FALSE
]
responsive_day_ten <- responsive_daily[
  responsive_daily$simulation_day == goal027_days,
  ,
  drop = FALSE
]
restoration_day_label <- if (is.na(first_90_percent_restoration_day)) {
  "not reached"
} else {
  as.character(first_90_percent_restoration_day)
}

cat("Goal 027 diagnostics passed.\n")
cat(sprintf(
  paste0(
    "  Fixed lower day 10: intake %.3f kg DM; daily %+.0f kJ; ",
    "combined %+.0f kJ.\n"
  ),
  fixed_lower_day_ten$realized_dry_matter_intake_kg_dm,
  fixed_lower_day_ten$daily_combined_energy_change_kj,
  fixed_lower_day_ten$combined_energy_deviation_final_kj
))
cat(sprintf(
  paste0(
    "  Responsive lower: extra hours %s; day-10 intake %.3f kg DM; ",
    "daily %+.0f kJ; combined %+.0f kJ.\n"
  ),
  paste(responsive_daily$applied_extra_feeding_hours, collapse = ","),
  responsive_day_ten$realized_dry_matter_intake_kg_dm,
  responsive_day_ten$daily_combined_energy_change_kj,
  responsive_day_ten$combined_energy_deviation_final_kj
))
cat(sprintf(
  paste0(
    "  Day-10 restoration %.1f%%; 90%% threshold %s on day %s; ",
    "total extra feeding hours %d.\n"
  ),
  100 * restoration_fraction,
  if (goal027_assessment$restoration_target_met) "met" else "not met",
  restoration_day_label,
  goal027_assessment$total_applied_extra_feeding_hours
))
