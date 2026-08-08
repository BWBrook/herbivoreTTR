arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

require_that <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 013 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

near <- function(observed, expected, scale = NULL) {
  observed <- as.double(observed)
  expected <- as.double(expected)
  if (length(expected) == 1L && length(observed) > 1L) {
    expected <- rep(expected, length(observed))
  }
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
    all(
      abs(observed - expected) <=
        100 * .Machine$double.eps * scale
    )
}

hour_of_day <- 0:23
feeding_opportunity_open <- hour_of_day %in% c(0:7, 16:23)
reference_dry_matter_rates_kg_dm_h <-
  as.double(feeding_opportunity_open) * 0.020
shortfall_dry_matter_rates_kg_dm_h <-
  as.double(feeding_opportunity_open) * 0.015
activity_rates_kj_h <- as.double(feeding_opportunity_open) * 50

food_parameters <- herbivoreTTR::new_food_energy_parameters(10000)
gut_parameters <- herbivoreTTR::new_gut_energy_parameters(0.25)
body_parameters <- herbivoreTTR::new_body_energy_parameters(100)
appetite_parameters <- herbivoreTTR::new_appetite_control_parameters(
  maximum_dry_matter_intake_kg_dm_h = 0.025,
  body_energy_feedback_fraction_h = 0.05,
  gut_energy_feedback_fraction_h = 0.10
)
reference_dry_matter_schedule <-
  herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day,
    reference_dry_matter_rates_kg_dm_h
  )
shortfall_dry_matter_schedule <-
  herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day,
    shortfall_dry_matter_rates_kg_dm_h
  )
reference_energy_schedule <-
  herbivoreTTR::derive_ingested_available_energy_schedule(
    food_parameters,
    reference_dry_matter_schedule
  )
shortfall_energy_schedule <-
  herbivoreTTR::derive_ingested_available_energy_schedule(
    food_parameters,
    shortfall_dry_matter_schedule
  )
routine_activity_schedule <-
  herbivoreTTR::new_routine_activity_expenditure_schedule(
    hour_of_day,
    activity_rates_kj_h
  )

balanced_reference <- herbivoreTTR::run_gut_body_energy_reference_cycle(
  initial_gut_state = herbivoreTTR::new_gut_energy_state(0),
  measurement_body_state = herbivoreTTR::new_body_energy_state(10000),
  gut_parameters = gut_parameters,
  body_parameters = body_parameters,
  schedule = reference_energy_schedule,
  routine_activity_schedule = routine_activity_schedule,
  gut_convergence_relative_tolerance = 100 * .Machine$double.eps,
  max_burn_in_days = 100L
)
reference_hourly <- balanced_reference$hourly[
  balanced_reference$hourly$measurement_day == 1L,
  ,
  drop = FALSE
]
row.names(reference_hourly) <- NULL

appetite_reference_schedule <-
  herbivoreTTR::new_appetite_reference_schedule(
    hour_of_day = hour_of_day,
    feeding_opportunity_open = feeding_opportunity_open,
    reference_dry_matter_intake_kg_dm_h =
      reference_dry_matter_rates_kg_dm_h,
    reference_body_energy_reserve_kj =
      reference_hourly$body_energy_reserve_start_kj,
    reference_gut_available_energy_kj =
      reference_hourly$gut_available_energy_start_kj
  )
nonlimiting_forage_acquisition_ceiling_schedule <-
  herbivoreTTR::new_forage_acquisition_ceiling_schedule(
    hour_of_day,
    rep(0.025, 24L)
  )

reference_opening_gut_state <- herbivoreTTR::new_gut_energy_state(
  reference_hourly$gut_available_energy_start_kj[[1L]]
)
reference_opening_body_state <- herbivoreTTR::new_body_energy_state(
  reference_hourly$body_energy_reserve_start_kj[[1L]]
)
reference_opening_gut_energy_kj <-
  reference_opening_gut_state$gut_available_energy_kj
reference_opening_body_energy_kj <-
  reference_opening_body_state$body_energy_reserve_kj

balanced_appetite_control <-
  herbivoreTTR::run_appetite_controlled_energy_days(
    initial_gut_state = reference_opening_gut_state,
    initial_body_state = reference_opening_body_state,
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    food_parameters = food_parameters,
    appetite_parameters = appetite_parameters,
    appetite_reference_schedule = appetite_reference_schedule,
    forage_acquisition_ceiling_schedule =
      nonlimiting_forage_acquisition_ceiling_schedule,
    routine_activity_schedule = routine_activity_schedule,
    number_of_days = 1L
  )

require_that(
  identical(
    balanced_appetite_control$hourly$
      realized_dry_matter_intake_kg_dm_h,
    reference_dry_matter_rates_kg_dm_h
  ) &&
    identical(
      balanced_appetite_control$hourly$
        realized_ingested_available_energy_kj_h,
      reference_hourly$prescribed_ingested_available_energy_kj_h
    ) &&
    identical(
      balanced_appetite_control$hourly$gut_available_energy_start_kj,
      reference_hourly$gut_available_energy_start_kj
    ) &&
    identical(
      balanced_appetite_control$hourly$gut_available_energy_end_kj,
      reference_hourly$gut_available_energy_end_kj
    ) &&
    identical(
      balanced_appetite_control$hourly$body_energy_reserve_start_kj,
      reference_hourly$body_energy_reserve_start_kj
    ) &&
    identical(
      balanced_appetite_control$hourly$body_energy_reserve_end_kj,
      reference_hourly$body_energy_reserve_end_kj
    ),
  "exact appetite-controlled reference identity"
)
require_that(
  all(
    balanced_appetite_control$hourly$
      body_energy_feedback_kj_h == 0
  ) &&
    all(
      balanced_appetite_control$hourly$
        gut_energy_feedback_kj_h == 0
    ),
  "zero controller feedback on the exact reference"
)

shortfall_day <- herbivoreTTR::run_gut_body_energy_day(
  initial_gut_state = reference_opening_gut_state,
  initial_body_state = reference_opening_body_state,
  gut_parameters = gut_parameters,
  body_parameters = body_parameters,
  schedule = shortfall_energy_schedule,
  routine_activity_schedule = routine_activity_schedule
)
shortfall_daily <- data.frame(
  sequence_day = 1L,
  forcing = "prescribed_shortfall",
  realized_dry_matter_intake_kg_dm =
    sum(shortfall_dry_matter_rates_kg_dm_h),
  realized_ingested_available_energy_kj =
    sum(shortfall_energy_schedule$
      prescribed_ingested_available_energy_kj_h),
  extra_energy_vs_reference_kj = -800,
  gut_deviation_end_kj =
    shortfall_day$daily$gut_available_energy_final_kj -
      reference_opening_gut_energy_kj,
  body_deviation_end_kj =
    shortfall_day$daily$body_energy_reserve_final_kj -
      reference_opening_body_energy_kj
)
shortfall_daily$combined_deviation_end_kj <-
  shortfall_daily$gut_deviation_end_kj +
    shortfall_daily$body_deviation_end_kj

require_that(
  near(
    shortfall_day$daily$observed_total_system_energy_change_kj,
    -800,
    scale = 10000
  ) &&
    near(shortfall_daily$combined_deviation_end_kj, -800, scale = 10000),
  "established one-day minus-800-kJ shortfall"
)

controlled_result <- herbivoreTTR::run_appetite_controlled_energy_days(
  initial_gut_state = herbivoreTTR::new_gut_energy_state(
    shortfall_day$daily$gut_available_energy_final_kj
  ),
  initial_body_state = herbivoreTTR::new_body_energy_state(
    shortfall_day$daily$body_energy_reserve_final_kj
  ),
  gut_parameters = gut_parameters,
  body_parameters = body_parameters,
  food_parameters = food_parameters,
  appetite_parameters = appetite_parameters,
  appetite_reference_schedule = appetite_reference_schedule,
  forage_acquisition_ceiling_schedule =
    nonlimiting_forage_acquisition_ceiling_schedule,
  routine_activity_schedule = routine_activity_schedule,
  number_of_days = 9L
)
controlled_hourly <- controlled_result$hourly
controlled_hourly$sequence_day <- controlled_hourly$simulation_day + 1L
row.names(controlled_hourly) <- NULL
controlled_daily <- data.frame(
  sequence_day = controlled_result$daily$simulation_day + 1L,
  forcing = "appetite_control",
  realized_dry_matter_intake_kg_dm =
    controlled_result$daily$realized_dry_matter_intake_kg_dm,
  realized_ingested_available_energy_kj =
    controlled_result$daily$total_realized_ingested_available_energy_kj,
  extra_energy_vs_reference_kj =
    controlled_result$daily$total_realized_ingested_available_energy_kj -
      controlled_result$daily$
        total_reference_ingested_available_energy_kj,
  gut_deviation_end_kj =
    controlled_result$daily$
      gut_energy_deviation_from_reference_final_kj,
  body_deviation_end_kj =
    controlled_result$daily$
      body_energy_deviation_from_reference_final_kj,
  combined_deviation_end_kj =
    controlled_result$daily$
      combined_energy_deviation_from_reference_final_kj
)
daily_recovery_summary <- rbind(
  shortfall_daily,
  controlled_daily
)
row.names(daily_recovery_summary) <- NULL

require_that(
  all(
    controlled_hourly$realized_dry_matter_intake_kg_dm_h[
      !controlled_hourly$feeding_opportunity_open
    ] == 0
  ) &&
    all(controlled_hourly$realized_dry_matter_intake_kg_dm_h >= 0) &&
    all(controlled_hourly$realized_dry_matter_intake_kg_dm_h <= 0.025) &&
    !any(controlled_hourly$lower_intake_bound_active) &&
    !any(controlled_hourly$upper_intake_bound_active),
  "closed, bounded, interior recovery intake"
)
require_that(
  all(daily_recovery_summary$body_deviation_end_kj < 0) &&
    all(diff(daily_recovery_summary$body_deviation_end_kj) > 0) &&
    all(daily_recovery_summary$gut_deviation_end_kj[-1L] > 0) &&
    all(diff(daily_recovery_summary$gut_deviation_end_kj[-1L]) < 0) &&
    all(daily_recovery_summary$extra_energy_vs_reference_kj[-1L] > 0) &&
    all(diff(daily_recovery_summary$extra_energy_vs_reference_kj[-1L]) < 0),
  "single gut repartition and smooth recovery without body overshoot"
)
require_that(
  abs(tail(daily_recovery_summary$combined_deviation_end_kj, 1L)) < 2,
  "combined-system deviation below 2 kJ by day 10"
)
require_that(
  near(controlled_hourly$gut_energy_balance_residual_kj, 0, scale = 10000) &&
    near(controlled_hourly$body_energy_balance_residual_kj, 0, scale = 10000) &&
    near(controlled_hourly$system_energy_balance_residual_kj, 0, scale = 10000),
  "hourly gut, body, and system accounting closure"
)

probe_reference_row <- appetite_reference_schedule[1L, , drop = FALSE]
probe_reference_gut_kj <-
  probe_reference_row$reference_gut_available_energy_kj
probe_reference_body_kj <-
  probe_reference_row$reference_body_energy_reserve_kj
probe_states <- list(
  exact_reference = list(
    gut_kj = probe_reference_gut_kj,
    body_kj = probe_reference_body_kj
  ),
  body_deficit = list(
    gut_kj = probe_reference_gut_kj,
    body_kj = probe_reference_body_kj - 500
  ),
  gut_satiation = list(
    gut_kj = probe_reference_gut_kj + 200,
    body_kj = probe_reference_body_kj
  ),
  integrated = list(
    gut_kj = probe_reference_gut_kj + 200,
    body_kj = probe_reference_body_kj - 500
  )
)
controller_component_probes <- do.call(
  rbind,
  lapply(names(probe_states), function(probe_id) {
    probe <- probe_states[[probe_id]]
    result <- herbivoreTTR::calculate_appetite_target(
      gut_state = herbivoreTTR::new_gut_energy_state(probe$gut_kj),
      body_state = herbivoreTTR::new_body_energy_state(probe$body_kj),
      food_parameters = food_parameters,
      appetite_parameters = appetite_parameters,
      reference_row = probe_reference_row
    )
    data.frame(
      probe_id = probe_id,
      body_energy_deviation_from_reference_kj =
        result$body_energy_deviation_from_reference_kj,
      body_energy_feedback_kj_h = result$body_energy_feedback_kj_h,
      gut_energy_deviation_from_reference_kj =
        result$gut_energy_deviation_from_reference_kj,
      gut_energy_feedback_kj_h = result$gut_energy_feedback_kj_h,
      unconstrained_ingested_available_energy_kj_h =
        result$unconstrained_ingested_available_energy_kj_h,
      appetite_target_ingested_available_energy_kj_h =
        result$appetite_target_ingested_available_energy_kj_h,
      appetite_target_dry_matter_intake_kg_dm_h =
        result$appetite_target_dry_matter_intake_kg_dm_h
    )
  })
)
row.names(controller_component_probes) <- NULL

gut_probe <- controller_component_probes[
  controller_component_probes$probe_id == "gut_satiation",
  ,
  drop = FALSE
]
require_that(
    identical(gut_probe$body_energy_feedback_kj_h, 0) &&
    identical(gut_probe$gut_energy_feedback_kj_h, -20) &&
    near(gut_probe$appetite_target_ingested_available_energy_kj_h, 180),
  "isolated plus-200-kJ gut-satiation response"
)

shortfall_hourly <- data.frame(
  sequence_day = 1L,
  hour_of_day = hour_of_day,
  feeding_opportunity_open = feeding_opportunity_open,
  reference_dry_matter_intake_kg_dm_h =
    reference_dry_matter_rates_kg_dm_h,
  realized_dry_matter_intake_kg_dm_h =
    shortfall_dry_matter_rates_kg_dm_h,
  reference_ingested_available_energy_kj_h =
    reference_energy_schedule$prescribed_ingested_available_energy_kj_h,
  realized_ingested_available_energy_kj_h =
    shortfall_energy_schedule$prescribed_ingested_available_energy_kj_h,
  unconstrained_ingested_available_energy_kj_h = NA_real_,
  body_energy_deviation_from_reference_kj =
    shortfall_day$hourly$body_energy_reserve_start_kj -
      reference_hourly$body_energy_reserve_start_kj,
  body_energy_feedback_kj_h = NA_real_,
  gut_energy_deviation_from_reference_kj =
    shortfall_day$hourly$gut_available_energy_start_kj -
      reference_hourly$gut_available_energy_start_kj,
  gut_energy_feedback_kj_h = NA_real_
)
treatment_hourly_summary <- rbind(
  shortfall_hourly,
  controlled_hourly[names(shortfall_hourly)]
)
row.names(treatment_hourly_summary) <- NULL

goal013_diagnostics <- list(
  appetite_reference_schedule = appetite_reference_schedule,
  balanced_appetite_control = balanced_appetite_control,
  shortfall_day = shortfall_day,
  controlled_result = controlled_result,
  treatment_hourly_summary = treatment_hourly_summary,
  daily_recovery_summary = daily_recovery_summary,
  controller_component_probes = controller_component_probes
)

cat(
  sprintf(
    paste0(
      "Goal 013 diagnostics passed: day-10 body deviation %.0f kJ; ",
      "combined deviation %.0f kJ.\n"
    ),
    tail(daily_recovery_summary$body_deviation_end_kj, 1L),
    tail(daily_recovery_summary$combined_deviation_end_kj, 1L)
  )
)
