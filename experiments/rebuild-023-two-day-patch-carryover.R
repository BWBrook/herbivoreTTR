arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-022-implicit-two-patch-forage.R")

require_goal023 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 023 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

run_repeated_patch_exposure <- function(exposure) {
  herbivoreTTR::run_appetite_controlled_energy_days(
    initial_gut_state = reference_opening_gut_state,
    initial_body_state = reference_opening_body_state,
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    food_parameters = food_parameters,
    appetite_parameters = appetite_parameters,
    appetite_reference_schedule = appetite_reference_schedule,
    forage_acquisition_ceiling_schedule = exposure$ceiling_schedule,
    routine_activity_schedule = routine_activity_schedule,
    number_of_days = 2L
  )
}

goal023_results <- lapply(
  goal022_exposures,
  run_repeated_patch_exposure
)

day_one_identity <- vapply(
  names(goal023_results),
  function(arm_id) {
    repeated <- goal023_results[[arm_id]]
    accepted <- goal022_results[[arm_id]]
    identical(
      repeated$hourly[
        repeated$hourly$simulation_day == 1L,
        ,
        drop = FALSE
      ],
      accepted$hourly
    ) &&
      identical(
        repeated$daily[
          repeated$daily$simulation_day == 1L,
          ,
          drop = FALSE
        ],
        accepted$daily
      )
  },
  logical(1L)
)
require_goal023(all(day_one_identity), "exact Goal 022 day-one identity")

build_goal023_hourly <- function(arm_id, exposure, result) {
  reference_total_energy_end_kj <- rep(
    balanced_appetite_control$hourly$total_system_energy_end_kj,
    times = 2L
  )
  data.frame(
    arm_id = arm_id,
    simulation_day = result$hourly$simulation_day,
    hour_of_day = result$hourly$hour_of_day,
    time_end_h = result$hourly$time_end_h,
    feeding_window_id = rep(exposure$feeding_window_id, times = 2L),
    patch_id = rep(exposure$patch_id, times = 2L),
    forage_acquisition_ceiling_kg_dm_h =
      result$hourly$forage_acquisition_ceiling_kg_dm_h,
    appetite_target_dry_matter_intake_kg_dm_h =
      result$hourly$appetite_target_dry_matter_intake_kg_dm_h,
    realized_dry_matter_intake_kg_dm_h =
      result$hourly$realized_dry_matter_intake_kg_dm_h,
    forage_acquisition_ceiling_active =
      result$hourly$forage_acquisition_ceiling_active,
    gut_available_energy_end_kj =
      result$hourly$gut_available_energy_end_kj,
    body_energy_reserve_end_kj =
      result$hourly$body_energy_reserve_end_kj,
    combined_energy_deviation_end_kj =
      result$hourly$total_system_energy_end_kj -
        reference_total_energy_end_kj,
    gut_energy_balance_residual_kj =
      result$hourly$gut_energy_balance_residual_kj,
    body_energy_balance_residual_kj =
      result$hourly$body_energy_balance_residual_kj,
    system_energy_balance_residual_kj =
      result$hourly$system_energy_balance_residual_kj,
    stringsAsFactors = FALSE
  )
}

goal023_hourly <- do.call(
  rbind,
  lapply(names(goal023_results), function(arm_id) {
    build_goal023_hourly(
      arm_id,
      goal022_exposures[[arm_id]],
      goal023_results[[arm_id]]
    )
  })
)
row.names(goal023_hourly) <- NULL

build_goal023_daily <- function(arm_id, exposure, result) {
  daily <- result$daily
  data.frame(
    arm_id = arm_id,
    simulation_day = daily$simulation_day,
    first_patch = exposure$first_patch,
    second_patch = exposure$second_patch,
    aggregate_ceiling_capacity_kg_dm = rep(
      sum(
        exposure$ceiling_schedule$forage_acquisition_ceiling_kg_dm_h[
          feeding_opportunity_open
        ]
      ),
      2L
    ),
    gut_available_energy_initial_kj =
      daily$gut_available_energy_initial_kj,
    body_energy_reserve_initial_kj =
      daily$body_energy_reserve_initial_kj,
    opening_combined_energy_deviation_kj =
      daily$gut_available_energy_initial_kj -
        reference_opening_gut_state$gut_available_energy_kj +
      daily$body_energy_reserve_initial_kj -
        reference_opening_body_state$body_energy_reserve_kj,
    appetite_target_dry_matter_intake_kg_dm =
      daily$appetite_target_dry_matter_intake_kg_dm,
    realized_dry_matter_intake_kg_dm =
      daily$realized_dry_matter_intake_kg_dm,
    forage_acquisition_ceiling_active_hours =
      daily$forage_acquisition_ceiling_active_hours,
    lower_intake_bound_hours = daily$lower_intake_bound_hours,
    upper_intake_bound_hours = daily$upper_intake_bound_hours,
    realized_ingested_available_energy_kj =
      daily$total_realized_ingested_available_energy_kj,
    routine_activity_expenditure_kj =
      daily$total_prescribed_routine_activity_expenditure_kj,
    gut_available_energy_final_kj = daily$gut_available_energy_final_kj,
    body_energy_reserve_final_kj = daily$body_energy_reserve_final_kj,
    gut_energy_deviation_final_kj =
      daily$gut_energy_deviation_from_reference_final_kj,
    body_energy_deviation_final_kj =
      daily$body_energy_deviation_from_reference_final_kj,
    combined_energy_deviation_final_kj =
      daily$combined_energy_deviation_from_reference_final_kj,
    total_system_energy_change_kj =
      daily$observed_total_system_energy_change_kj,
    gut_energy_balance_residual_kj = daily$gut_energy_balance_residual_kj,
    body_energy_balance_residual_kj =
      daily$body_energy_balance_residual_kj,
    system_energy_balance_residual_kj =
      daily$system_energy_balance_residual_kj,
    stringsAsFactors = FALSE
  )
}

goal023_daily <- do.call(
  rbind,
  lapply(names(goal023_results), function(arm_id) {
    build_goal023_daily(
      arm_id,
      goal022_exposures[[arm_id]],
      goal023_results[[arm_id]]
    )
  })
)
row.names(goal023_daily) <- NULL

daily_value <- function(arm_id, simulation_day, field_name) {
  goal023_daily[[field_name]][
    goal023_daily$arm_id == arm_id &
      goal023_daily$simulation_day == simulation_day
  ]
}

build_mixed_order_contrast <- function(simulation_day) {
  contrast_value <- function(field_name) {
    daily_value("limited_then_adequate", simulation_day, field_name) -
      daily_value("adequate_then_limited", simulation_day, field_name)
  }
  data.frame(
    simulation_day = as.integer(simulation_day),
    opening_combined_energy_deviation_kj =
      contrast_value("opening_combined_energy_deviation_kj"),
    realized_dry_matter_intake_kg_dm =
      contrast_value("realized_dry_matter_intake_kg_dm"),
    realized_ingested_available_energy_kj =
      contrast_value("realized_ingested_available_energy_kj"),
    gut_available_energy_final_kj =
      contrast_value("gut_available_energy_final_kj"),
    body_energy_reserve_final_kj =
      contrast_value("body_energy_reserve_final_kj"),
    combined_energy_deviation_final_kj =
      contrast_value("combined_energy_deviation_final_kj"),
    incremental_combined_order_effect_kj =
      contrast_value("combined_energy_deviation_final_kj") -
        contrast_value("opening_combined_energy_deviation_kj"),
    stringsAsFactors = FALSE
  )
}

goal023_mixed_order_contrasts <- do.call(
  rbind,
  lapply(1:2, build_mixed_order_contrast)
)
row.names(goal023_mixed_order_contrasts) <- NULL

carryover_identity <- vapply(
  names(goal023_results),
  function(arm_id) {
    daily <- goal023_results[[arm_id]]$daily
    identical(
      daily$gut_available_energy_initial_kj[[2L]],
      daily$gut_available_energy_final_kj[[1L]]
    ) &&
      identical(
        daily$body_energy_reserve_initial_kj[[2L]],
        daily$body_energy_reserve_final_kj[[1L]]
      )
  },
  logical(1L)
)
require_goal023(all(carryover_identity), "exact day-one to day-two carry-over")

adequate_daily <- goal023_results$adequate_then_adequate$daily
adequate_hourly <- goal023_results$adequate_then_adequate$hourly
repeat_hourly_fields <- setdiff(
  names(adequate_hourly),
  c("simulation_day", "time_start_h", "time_end_h")
)
require_goal023(
  identical(
    as.list(adequate_hourly[1:24, repeat_hourly_fields, drop = FALSE]),
    as.list(adequate_hourly[25:48, repeat_hourly_fields, drop = FALSE])
  ) &&
    all(adequate_daily$combined_energy_deviation_from_reference_final_kj == 0),
  "two-day adequate reference identity"
)

limited_daily <- goal023_results$limited_then_limited$daily
require_goal023(
  near(limited_daily$realized_dry_matter_intake_kg_dm, 0.24, scale = 1) &&
    all(limited_daily$forage_acquisition_ceiling_active_hours == 16L) &&
    near(
      limited_daily$observed_total_system_energy_change_kj,
      -800,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      limited_daily$combined_energy_deviation_from_reference_final_kj,
      c(-800, -1600),
      scale = reference_opening_body_energy_kj
    ),
  "two-day limited-patch anchor"
)

require_goal023(
  near(
    goal023_mixed_order_contrasts$realized_ingested_available_energy_kj,
    goal023_mixed_order_contrasts$incremental_combined_order_effect_kj,
    scale = reference_opening_body_energy_kj
  ) &&
    near(
      goal023_mixed_order_contrasts[
        goal023_mixed_order_contrasts$simulation_day == 1L,
        "combined_energy_deviation_final_kj"
      ],
      goal022_mixed_order_contrast$combined_energy_deviation_final_kj,
      scale = reference_opening_body_energy_kj
    ),
  "day-specific and cumulative mixed-order accounting"
)

require_goal023(
  all(goal023_daily$lower_intake_bound_hours == 0L) &&
    all(
      goal023_daily$upper_intake_bound_hours >= 0L &
        goal023_daily$upper_intake_bound_hours <= 24L
    ) &&
    all(
      goal023_daily$forage_acquisition_ceiling_active_hours >= 0L &
        goal023_daily$forage_acquisition_ceiling_active_hours <= 24L
    ) &&
    all(goal023_daily$body_energy_reserve_final_kj > 0) &&
    near(
      goal023_daily$gut_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      goal023_daily$body_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      goal023_daily$system_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ),
  "bounds, positive reserve, and daily energy accounting"
)

goal023_diagnostics <- list(
  results = goal023_results,
  hourly = goal023_hourly,
  daily = goal023_daily,
  mixed_order_contrasts = goal023_mixed_order_contrasts
)

cat("Goal 023 diagnostics passed.\n")
for (row_index in seq_len(nrow(goal023_daily))) {
  row <- goal023_daily[row_index, ]
  cat(sprintf(
    paste0(
      "  %s day %d: target %.3f kg DM; realized %.3f kg DM; ",
      "ceiling %d h; upper bound %d h; combined %+.0f kJ.\n"
    ),
    row$arm_id,
    row$simulation_day,
    row$appetite_target_dry_matter_intake_kg_dm,
    row$realized_dry_matter_intake_kg_dm,
    row$forage_acquisition_ceiling_active_hours,
    row$upper_intake_bound_hours,
    row$combined_energy_deviation_final_kj
  ))
}
for (row_index in seq_len(nrow(goal023_mixed_order_contrasts))) {
  row <- goal023_mixed_order_contrasts[row_index, ]
  cat(sprintf(
    paste0(
      "  Mixed-order day %d: opening %+.0f kJ; intake %+.3f kg DM; ",
      "new %+.0f kJ; gut %+.0f kJ; body %+.0f kJ; closing %+.0f kJ.\n"
    ),
    row$simulation_day,
    row$opening_combined_energy_deviation_kj,
    row$realized_dry_matter_intake_kg_dm,
    row$realized_ingested_available_energy_kj,
    row$gut_available_energy_final_kj,
    row$body_energy_reserve_final_kj,
    row$combined_energy_deviation_final_kj
  ))
}
