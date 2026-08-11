arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-020-deficit-responsive-feeding-duration.R")

require_goal021 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 021 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

fixed_rate_appetite_parameters <-
  herbivoreTTR::new_appetite_control_parameters(
    maximum_dry_matter_intake_kg_dm_h = 0.025,
    body_energy_feedback_fraction_h = 0,
    gut_energy_feedback_fraction_h = 0
  )

post_shortfall_gut_state <- herbivoreTTR::new_gut_energy_state(
  shortfall_day$daily$gut_available_energy_final_kj
)
post_shortfall_body_state <- herbivoreTTR::new_body_energy_state(
  shortfall_day$daily$body_energy_reserve_final_kj
)

fixed_rate_reference <- herbivoreTTR::run_appetite_controlled_energy_days(
  initial_gut_state = reference_opening_gut_state,
  initial_body_state = reference_opening_body_state,
  gut_parameters = gut_parameters,
  body_parameters = body_parameters,
  food_parameters = food_parameters,
  appetite_parameters = fixed_rate_appetite_parameters,
  appetite_reference_schedule = appetite_reference_schedule,
  forage_acquisition_ceiling_schedule =
    nonlimiting_forage_acquisition_ceiling_schedule,
  routine_activity_schedule = routine_activity_schedule,
  number_of_days = 1L
)

require_goal021(
  identical(fixed_rate_reference, balanced_appetite_control) &&
    identical(reference_identity, balanced_appetite_control) &&
    identical(reference_decision$indicated_extension_pairs, 0L),
  "exact four-configuration reference identity"
)

make_goal021_decision_row <- function(
  arm_id,
  recovery_day,
  opening_body_energy_kj,
  decision,
  applied_extension_pairs,
  applied_extension_hours
) {
  data.frame(
    arm_id = arm_id,
    recovery_day = as.integer(recovery_day),
    opening_body_energy_reserve_kj = opening_body_energy_kj,
    opening_body_deficit_kj = decision$opening_body_deficit_kj,
    indicated_extension_pairs = decision$indicated_extension_pairs,
    indicated_extra_feeding_hours =
      2L * decision$indicated_extension_pairs,
    applied_extension_pairs = applied_extension_pairs,
    applied_extra_feeding_hours = 2L * applied_extension_pairs,
    applied_extension_hour_labels = if (
      length(applied_extension_hours) == 0L
    ) {
      "none"
    } else {
      paste(sort(applied_extension_hours), collapse = ",")
    },
    total_feeding_opportunity_hours =
      sum(feeding_opportunity_open) + length(applied_extension_hours),
    incremental_activity_expenditure_kj =
      length(applied_extension_hours) * feeding_activity_rate_kj_h,
    stringsAsFactors = FALSE
  )
}

make_fixed_duration_decisions <- function(arm_id, daily) {
  rows <- lapply(seq_len(nrow(daily)), function(recovery_day) {
    decision <- calculate_duration_decision(
      daily$body_energy_reserve_initial_kj[[recovery_day]]
    )
    make_goal021_decision_row(
      arm_id = arm_id,
      recovery_day = recovery_day,
      opening_body_energy_kj =
        daily$body_energy_reserve_initial_kj[[recovery_day]],
      decision = decision,
      applied_extension_pairs = 0L,
      applied_extension_hours = integer()
    )
  })
  decisions <- do.call(rbind, rows)
  row.names(decisions) <- NULL
  decisions
}

fixed_rate_fixed_duration_result <-
  herbivoreTTR::run_appetite_controlled_energy_days(
    initial_gut_state = post_shortfall_gut_state,
    initial_body_state = post_shortfall_body_state,
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    food_parameters = food_parameters,
    appetite_parameters = fixed_rate_appetite_parameters,
    appetite_reference_schedule = appetite_reference_schedule,
    forage_acquisition_ceiling_schedule =
      nonlimiting_forage_acquisition_ceiling_schedule,
    routine_activity_schedule = routine_activity_schedule,
    number_of_days = recovery_days_goal020
  )
fixed_rate_fixed_duration <- list(
  hourly = fixed_rate_fixed_duration_result$hourly,
  daily = fixed_rate_fixed_duration_result$daily,
  decisions = make_fixed_duration_decisions(
    "fixed_rate_fixed_duration",
    fixed_rate_fixed_duration_result$daily
  )
)

run_fixed_rate_responsive_duration <- function() {
  current_gut_state <- post_shortfall_gut_state
  current_body_state <- post_shortfall_body_state
  day_results <- vector("list", recovery_days_goal020)
  decision_results <- vector("list", recovery_days_goal020)

  for (recovery_day in seq_len(recovery_days_goal020)) {
    opening_body_energy_kj <-
      current_body_state$body_energy_reserve_kj
    decision <- calculate_duration_decision(opening_body_energy_kj)
    schedules <- make_duration_schedules(
      decision$indicated_extension_pairs
    )
    result <- herbivoreTTR::run_appetite_controlled_energy_days(
      initial_gut_state = current_gut_state,
      initial_body_state = current_body_state,
      gut_parameters = gut_parameters,
      body_parameters = body_parameters,
      food_parameters = food_parameters,
      appetite_parameters = fixed_rate_appetite_parameters,
      appetite_reference_schedule = schedules$appetite_reference_schedule,
      forage_acquisition_ceiling_schedule =
        nonlimiting_forage_acquisition_ceiling_schedule,
      routine_activity_schedule = schedules$routine_activity_schedule,
      number_of_days = 1L
    )

    newly_opened_hours <- result$hourly$hour_of_day[
      result$hourly$feeding_opportunity_open & !feeding_opportunity_open
    ]
    require_goal021(
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
      sprintf(
        "state carry-over and duration schedule on recovery day %d",
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
    decision_results[[recovery_day]] <- make_goal021_decision_row(
      arm_id = "fixed_rate_responsive_duration",
      recovery_day = recovery_day,
      opening_body_energy_kj = opening_body_energy_kj,
      decision = decision,
      applied_extension_pairs = decision$indicated_extension_pairs,
      applied_extension_hours = schedules$applied_extension_hours
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

fixed_rate_responsive_duration <-
  run_fixed_rate_responsive_duration()

goal021_arms <- list(
  fixed_rate_fixed_duration = fixed_rate_fixed_duration,
  responsive_rate_fixed_duration = duration_disabled,
  fixed_rate_responsive_duration = fixed_rate_responsive_duration,
  responsive_rate_responsive_duration = duration_enabled
)
rate_feedback_enabled <- c(FALSE, TRUE, FALSE, TRUE)
duration_feedback_enabled <- c(FALSE, FALSE, TRUE, TRUE)

build_goal021_daily <- function(
  arm_id,
  result,
  rate_enabled,
  duration_enabled
) {
  derived_mass <- herbivoreTTR::derive_body_mass_from_energy_reserve(
    body_mass_parameters,
    result$daily$body_energy_reserve_final_kj
  )
  data.frame(
    arm_id = arm_id,
    rate_feedback_enabled = rate_enabled,
    duration_feedback_enabled = duration_enabled,
    recovery_day = result$daily$simulation_day,
    opening_body_deficit_kj =
      result$decisions$opening_body_deficit_kj,
    indicated_extra_feeding_hours =
      result$decisions$indicated_extra_feeding_hours,
    applied_extra_feeding_hours =
      result$decisions$applied_extra_feeding_hours,
    applied_extension_hour_labels =
      result$decisions$applied_extension_hour_labels,
    total_feeding_opportunity_hours =
      result$decisions$total_feeding_opportunity_hours,
    incremental_activity_expenditure_kj =
      result$decisions$incremental_activity_expenditure_kj,
    appetite_target_dry_matter_intake_kg_dm =
      result$daily$appetite_target_dry_matter_intake_kg_dm,
    realized_dry_matter_intake_kg_dm =
      result$daily$realized_dry_matter_intake_kg_dm,
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
    total_body_mass_final_kg = derived_mass$total_body_mass_kg,
    stringsAsFactors = FALSE
  )
}

goal021_daily <- do.call(
  rbind,
  lapply(seq_along(goal021_arms), function(index) {
    build_goal021_daily(
      arm_id = names(goal021_arms)[[index]],
      result = goal021_arms[[index]],
      rate_enabled = rate_feedback_enabled[[index]],
      duration_enabled = duration_feedback_enabled[[index]]
    )
  })
)
row.names(goal021_daily) <- NULL

daily_values <- function(arm_id, field_name) {
  goal021_daily[[field_name]][goal021_daily$arm_id == arm_id]
}

goal021_interaction <- data.frame(
  recovery_day = seq_len(recovery_days_goal020),
  fixed_rate_fixed_duration_kj = daily_values(
    "fixed_rate_fixed_duration",
    "combined_energy_deviation_final_kj"
  ),
  responsive_rate_fixed_duration_kj = daily_values(
    "responsive_rate_fixed_duration",
    "combined_energy_deviation_final_kj"
  ),
  fixed_rate_responsive_duration_kj = daily_values(
    "fixed_rate_responsive_duration",
    "combined_energy_deviation_final_kj"
  ),
  responsive_rate_responsive_duration_kj = daily_values(
    "responsive_rate_responsive_duration",
    "combined_energy_deviation_final_kj"
  )
)
goal021_interaction$interaction_kj <- with(
  goal021_interaction,
  responsive_rate_responsive_duration_kj -
    responsive_rate_fixed_duration_kj -
    fixed_rate_responsive_duration_kj +
    fixed_rate_fixed_duration_kj
)
interaction_near_zero <- near(
  goal021_interaction$interaction_kj,
  0,
  scale = reference_opening_body_energy_kj
)
goal021_interaction$interaction_class <- ifelse(
  interaction_near_zero,
  "additive",
  ifelse(
    goal021_interaction$interaction_kj > 0,
    "synergistic",
    "antagonistic"
  )
)

goal021_daily <- merge(
  goal021_daily,
  goal021_interaction[c("recovery_day", "interaction_kj")],
  by = "recovery_day",
  sort = FALSE
)
goal021_daily <- goal021_daily[
  order(
    match(goal021_daily$arm_id, names(goal021_arms)),
    goal021_daily$recovery_day
  ),
]
row.names(goal021_daily) <- NULL

summarize_goal021_arm <- function(arm_id) {
  daily <- goal021_daily[goal021_daily$arm_id == arm_id, , drop = FALSE]
  recovery_rows <- which(
    daily$combined_energy_deviation_final_kj >=
      -0.10 * initial_shortfall_kj
  )
  data.frame(
    arm_id = arm_id,
    days_to_90_percent_combined_recovery = if (
      length(recovery_rows) == 0L
    ) {
      NA_integer_
    } else {
      as.integer(daily$recovery_day[recovery_rows[[1L]]])
    },
    total_applied_extra_feeding_hours =
      sum(daily$applied_extra_feeding_hours),
    total_realized_dry_matter_intake_kg_dm =
      sum(daily$realized_dry_matter_intake_kg_dm),
    total_routine_activity_expenditure_kj =
      sum(daily$total_routine_activity_expenditure_kj),
    final_combined_energy_deviation_kj =
      tail(daily$combined_energy_deviation_final_kj, 1L),
    final_body_energy_deviation_kj =
      tail(daily$body_energy_deviation_final_kj, 1L),
    final_total_body_mass_kg = tail(daily$total_body_mass_final_kg, 1L),
    combined_reference_crossing =
      any(daily$combined_energy_deviation_final_kj > 0),
    stringsAsFactors = FALSE
  )
}

goal021_outcome_summary <- do.call(
  rbind,
  lapply(names(goal021_arms), summarize_goal021_arm)
)
row.names(goal021_outcome_summary) <- NULL

all_hourly <- do.call(
  rbind,
  lapply(goal021_arms, `[[`, "hourly")
)
first_daily_rows <- do.call(
  rbind,
  lapply(goal021_arms, function(result) result$daily[1L, , drop = FALSE])
)
all_body_reserves_positive <- all(vapply(
  goal021_arms,
  function(result) all(result$daily$body_energy_reserve_final_kj > 0),
  logical(1L)
))

require_goal021(
  all(
    first_daily_rows$gut_available_energy_initial_kj ==
      post_shortfall_gut_state$gut_available_energy_kj
  ) &&
    all(
      first_daily_rows$body_energy_reserve_initial_kj ==
        post_shortfall_body_state$body_energy_reserve_kj
    ),
  "identical four-arm post-shortfall starting states"
)
require_goal021(
  near(
    daily_values(
      "fixed_rate_fixed_duration",
      "combined_energy_deviation_final_kj"
    ),
    -initial_shortfall_kj,
    scale = reference_opening_body_energy_kj
  ),
  "fixed-rate fixed-duration combined-energy anchor"
)
require_goal021(
  all(
    fixed_rate_fixed_duration$hourly$body_energy_feedback_kj_h == 0
  ) &&
    all(
      fixed_rate_fixed_duration$hourly$gut_energy_feedback_kj_h == 0
    ) &&
    all(
      fixed_rate_responsive_duration$hourly$body_energy_feedback_kj_h == 0
    ) &&
    all(
      fixed_rate_responsive_duration$hourly$gut_energy_feedback_kj_h == 0
    ) &&
    all(
      fixed_rate_fixed_duration$hourly$
        appetite_target_dry_matter_intake_kg_dm_h ==
          fixed_rate_fixed_duration$hourly$
            reference_dry_matter_intake_kg_dm_h
    ) &&
    all(
      fixed_rate_responsive_duration$hourly$
        appetite_target_dry_matter_intake_kg_dm_h ==
          fixed_rate_responsive_duration$hourly$
            reference_dry_matter_intake_kg_dm_h
    ),
  "zero-feedback arms retain the reference within-hour rate"
)
require_goal021(
    all(goal021_daily$lower_intake_bound_hours == 0L) &&
    all(goal021_daily$upper_intake_bound_hours == 0L) &&
    all(goal021_daily$forage_acquisition_ceiling_active_hours == 0L) &&
    all_body_reserves_positive &&
    near(
      all_hourly$gut_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      all_hourly$body_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      all_hourly$system_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ),
  "bounds, positive body reserve, and energy accounting"
)
require_goal021(
  all(
    goal021_daily$applied_extra_feeding_hours[
      !goal021_daily$duration_feedback_enabled
    ] == 0L
  ) &&
    all(
      goal021_daily$applied_extra_feeding_hours[
        goal021_daily$duration_feedback_enabled
      ] ==
        goal021_daily$indicated_extra_feeding_hours[
          goal021_daily$duration_feedback_enabled
        ]
    ) &&
    all(
      goal021_daily$applied_extra_feeding_hours[
        goal021_daily$duration_feedback_enabled
      ] %in% c(0L, 2L, 4L)
    ) &&
    all(
      goal021_daily$total_routine_activity_expenditure_kj ==
        sum(activity_rates_kj_h) +
          goal021_daily$incremental_activity_expenditure_kj
    ) &&
    all(is.finite(goal021_interaction$interaction_kj)),
  "declared duration decisions, activity charges, and interaction contrast"
)

goal021_diagnostics <- list(
  arms = goal021_arms,
  daily = goal021_daily,
  interaction = goal021_interaction,
  outcome_summary = goal021_outcome_summary
)

recovery_labels <- ifelse(
  is.na(goal021_outcome_summary$days_to_90_percent_combined_recovery),
  "not reached",
  as.character(goal021_outcome_summary$days_to_90_percent_combined_recovery)
)
cat("Goal 021 diagnostics passed.\n")
for (index in seq_len(nrow(goal021_outcome_summary))) {
  cat(sprintf(
    "  %s: 90%% recovery %s; extra hours %d; final combined %+.0f kJ.\n",
    goal021_outcome_summary$arm_id[[index]],
    recovery_labels[[index]],
    goal021_outcome_summary$total_applied_extra_feeding_hours[[index]],
    goal021_outcome_summary$final_combined_energy_deviation_kj[[index]]
  ))
}
cat(sprintf(
  "  Interaction: day 1 %+.0f kJ (%s); day 9 %+.0f kJ (%s).\n",
  goal021_interaction$interaction_kj[[1L]],
  goal021_interaction$interaction_class[[1L]],
  tail(goal021_interaction$interaction_kj, 1L),
  tail(goal021_interaction$interaction_class, 1L)
))
