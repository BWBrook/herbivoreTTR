arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-024-known-route-movement-cost.R")

require_goal025 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 025 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

quality_density_kj_kg_dm <- c(
  adequate_quality_patch = 10000,
  lower_quality_patch = 8000
)
goal025_design <- data.frame(
  arm_id = c(
    "adequate_then_adequate",
    "lower_then_lower",
    "lower_then_adequate",
    "adequate_then_lower"
  ),
  first_patch = c(
    "adequate_quality_patch",
    "lower_quality_patch",
    "lower_quality_patch",
    "adequate_quality_patch"
  ),
  second_patch = c(
    "adequate_quality_patch",
    "lower_quality_patch",
    "adequate_quality_patch",
    "lower_quality_patch"
  ),
  stringsAsFactors = FALSE
)

make_quality_exposure <- function(arm_id, first_patch, second_patch) {
  patch_id <- rep("central_rest", 24L)
  patch_id[hour_of_day %in% first_feeding_window_hours] <- first_patch
  patch_id[hour_of_day %in% second_feeding_window_hours] <- second_patch
  density_kj_kg_dm <- rep(
    quality_density_kj_kg_dm[["adequate_quality_patch"]],
    24L
  )
  density_kj_kg_dm[hour_of_day %in% first_feeding_window_hours] <-
    quality_density_kj_kg_dm[[first_patch]]
  density_kj_kg_dm[hour_of_day %in% second_feeding_window_hours] <-
    quality_density_kj_kg_dm[[second_patch]]

  list(
    arm_id = arm_id,
    first_patch = first_patch,
    second_patch = second_patch,
    patch_id = patch_id,
    metabolizable_energy_density_kj_kg_dm = density_kj_kg_dm
  )
}

goal025_exposures <- lapply(seq_len(nrow(goal025_design)), function(row_index) {
  make_quality_exposure(
    goal025_design$arm_id[[row_index]],
    goal025_design$first_patch[[row_index]],
    goal025_design$second_patch[[row_index]]
  )
})
names(goal025_exposures) <- goal025_design$arm_id

run_quality_exposure <- function(exposure) {
  current_gut_state <- reference_opening_gut_state
  current_body_state <- reference_opening_body_state
  hourly_rows <- vector("list", 24L)

  for (row_index in seq_len(24L)) {
    density_kj_kg_dm <-
      exposure$metabolizable_energy_density_kj_kg_dm[[row_index]]
    local_food_parameters <-
      herbivoreTTR::new_food_energy_parameters(density_kj_kg_dm)
    control <- herbivoreTTR::calculate_appetite_target(
      current_gut_state,
      current_body_state,
      local_food_parameters,
      appetite_parameters,
      appetite_reference_schedule[row_index, , drop = FALSE]
    )
    appetite_target_kg_dm_h <-
      control$appetite_target_dry_matter_intake_kg_dm_h
    acquisition_ceiling_kg_dm_h <-
      nonlimiting_forage_acquisition_ceiling_schedule$
        forage_acquisition_ceiling_kg_dm_h[[row_index]]
    acquisition_ceiling_active <-
      appetite_target_kg_dm_h > acquisition_ceiling_kg_dm_h
    realized_intake_kg_dm_h <- min(
      appetite_target_kg_dm_h,
      acquisition_ceiling_kg_dm_h
    )
    realized_energy_kj_h <-
      realized_intake_kg_dm_h * density_kj_kg_dm

    gut_start_kj <- current_gut_state$gut_available_energy_kj
    body_start_kj <- current_body_state$body_energy_reserve_kj
    gut_transition <- herbivoreTTR::step_gut_energy(
      current_gut_state,
      gut_parameters,
      data.frame(
        hour_of_day = hour_of_day[[row_index]],
        prescribed_ingested_available_energy_kj_h = realized_energy_kj_h
      )
    )
    body_transition <- herbivoreTTR::step_body_energy(
      current_body_state,
      body_parameters,
      data.frame(
        hour_of_day = hour_of_day[[row_index]],
        prescribed_assimilated_energy_kj_h =
          gut_transition$fluxes$assimilated_energy_kj_h
      ),
      routine_activity_schedule[row_index, , drop = FALSE]
    )
    gut_end_kj <- gut_transition$state$gut_available_energy_kj
    body_end_kj <- body_transition$state$body_energy_reserve_kj
    maintenance_kj <- body_transition$fluxes$maintenance_expenditure_kj
    activity_kj <- body_transition$fluxes$
      prescribed_routine_activity_expenditure_kj
    total_start_kj <- gut_start_kj + body_start_kj
    total_end_kj <- gut_end_kj + body_end_kj
    system_residual_kj <-
      (total_end_kj - total_start_kj) -
        (realized_energy_kj_h - maintenance_kj - activity_kj)

    hourly_rows[[row_index]] <- data.frame(
      arm_id = exposure$arm_id,
      hour_of_day = hour_of_day[[row_index]],
      patch_id = exposure$patch_id[[row_index]],
      metabolizable_energy_density_kj_kg_dm = density_kj_kg_dm,
      feeding_opportunity_open = control$feeding_opportunity_open,
      reference_dry_matter_intake_kg_dm_h =
        control$reference_dry_matter_intake_kg_dm_h,
      body_energy_feedback_kj_h = control$body_energy_feedback_kj_h,
      gut_energy_feedback_kj_h = control$gut_energy_feedback_kj_h,
      appetite_target_dry_matter_intake_kg_dm_h =
        appetite_target_kg_dm_h,
      lower_intake_bound_active = control$lower_intake_bound_active,
      upper_intake_bound_active = control$upper_intake_bound_active,
      forage_acquisition_ceiling_kg_dm_h = acquisition_ceiling_kg_dm_h,
      forage_acquisition_ceiling_active = acquisition_ceiling_active,
      realized_dry_matter_intake_kg_dm_h = realized_intake_kg_dm_h,
      realized_ingested_available_energy_kj_h = realized_energy_kj_h,
      gut_available_energy_start_kj = gut_start_kj,
      assimilated_energy_kj_h =
        gut_transition$fluxes$assimilated_energy_kj_h,
      gut_available_energy_end_kj = gut_end_kj,
      gut_energy_balance_residual_kj =
        gut_transition$fluxes$gut_energy_balance_residual_kj,
      body_energy_reserve_start_kj = body_start_kj,
      maintenance_expenditure_kj_h = maintenance_kj,
      prescribed_routine_activity_expenditure_kj_h = activity_kj,
      body_energy_reserve_end_kj = body_end_kj,
      body_energy_balance_residual_kj =
        body_transition$fluxes$energy_balance_residual_kj,
      total_system_energy_start_kj = total_start_kj,
      total_system_energy_end_kj = total_end_kj,
      combined_energy_deviation_end_kj =
        total_end_kj -
          balanced_appetite_control$hourly$
            total_system_energy_end_kj[[row_index]],
      system_energy_balance_residual_kj = system_residual_kj,
      stringsAsFactors = FALSE
    )

    current_gut_state <- gut_transition$state
    current_body_state <- body_transition$state
  }

  hourly <- do.call(rbind, hourly_rows)
  row.names(hourly) <- NULL
  hourly
}

goal025_hourly <- do.call(
  rbind,
  lapply(goal025_exposures, run_quality_exposure)
)
row.names(goal025_hourly) <- NULL

build_goal025_daily <- function(arm_id) {
  hourly <- goal025_hourly[goal025_hourly$arm_id == arm_id, , drop = FALSE]
  realized_dm_kg <- sum(hourly$realized_dry_matter_intake_kg_dm_h)
  realized_energy_kj <-
    sum(hourly$realized_ingested_available_energy_kj_h)
  final_gut_kj <- hourly$gut_available_energy_end_kj[[24L]]
  final_body_kj <- hourly$body_energy_reserve_end_kj[[24L]]
  final_gut_deviation_kj <-
    final_gut_kj - reference_opening_gut_state$gut_available_energy_kj
  final_body_deviation_kj <-
    final_body_kj - reference_opening_body_state$body_energy_reserve_kj
  data.frame(
    arm_id = arm_id,
    first_patch = goal025_exposures[[arm_id]]$first_patch,
    second_patch = goal025_exposures[[arm_id]]$second_patch,
    adequate_quality_feeding_hours = sum(
      hourly$patch_id == "adequate_quality_patch"
    ),
    lower_quality_feeding_hours = sum(
      hourly$patch_id == "lower_quality_patch"
    ),
    appetite_target_dry_matter_intake_kg_dm = sum(
      hourly$appetite_target_dry_matter_intake_kg_dm_h
    ),
    realized_dry_matter_intake_kg_dm = realized_dm_kg,
    realized_ingested_available_energy_kj = realized_energy_kj,
    intake_weighted_energy_density_kj_kg_dm =
      realized_energy_kj / realized_dm_kg,
    reference_energy_shortfall_kj = 3200 - realized_energy_kj,
    lower_intake_bound_hours = sum(hourly$lower_intake_bound_active),
    upper_intake_bound_hours = sum(hourly$upper_intake_bound_active),
    forage_acquisition_ceiling_active_hours = sum(
      hourly$forage_acquisition_ceiling_active
    ),
    routine_activity_expenditure_kj = sum(
      hourly$prescribed_routine_activity_expenditure_kj_h
    ),
    gut_available_energy_final_kj = final_gut_kj,
    body_energy_reserve_final_kj = final_body_kj,
    gut_energy_deviation_final_kj = final_gut_deviation_kj,
    body_energy_deviation_final_kj = final_body_deviation_kj,
    combined_energy_deviation_final_kj =
      final_gut_deviation_kj + final_body_deviation_kj,
    total_system_energy_change_kj =
      hourly$total_system_energy_end_kj[[24L]] -
        hourly$total_system_energy_start_kj[[1L]],
    maximum_gut_energy_balance_residual_kj = max(
      abs(hourly$gut_energy_balance_residual_kj)
    ),
    maximum_body_energy_balance_residual_kj = max(
      abs(hourly$body_energy_balance_residual_kj)
    ),
    maximum_system_energy_balance_residual_kj = max(
      abs(hourly$system_energy_balance_residual_kj)
    ),
    stringsAsFactors = FALSE
  )
}

goal025_daily <- do.call(
  rbind,
  lapply(goal025_design$arm_id, build_goal025_daily)
)
row.names(goal025_daily) <- NULL

daily_value025 <- function(arm_id, field_name) {
  goal025_daily[[field_name]][goal025_daily$arm_id == arm_id]
}
contrast_fields <- c(
  "appetite_target_dry_matter_intake_kg_dm",
  "realized_dry_matter_intake_kg_dm",
  "realized_ingested_available_energy_kj",
  "gut_available_energy_final_kj",
  "body_energy_reserve_final_kj",
  "combined_energy_deviation_final_kj"
)
goal025_mixed_order_contrast <- data.frame(
  contrast = "lower_then_adequate - adequate_then_lower",
  as.list(vapply(
    contrast_fields,
    function(field_name) {
      daily_value025("lower_then_adequate", field_name) -
        daily_value025("adequate_then_lower", field_name)
    },
    numeric(1L)
  )),
  check.names = FALSE,
  stringsAsFactors = FALSE
)

anchor_rows <- goal025_hourly$arm_id == "adequate_then_adequate"
anchor <- goal025_hourly[anchor_rows, , drop = FALSE]
canonical <- balanced_appetite_control$hourly
require_goal025(
  identical(
    anchor$appetite_target_dry_matter_intake_kg_dm_h,
    canonical$appetite_target_dry_matter_intake_kg_dm_h
  ) &&
    identical(
      anchor$realized_dry_matter_intake_kg_dm_h,
      canonical$realized_dry_matter_intake_kg_dm_h
    ) &&
    identical(
      anchor$realized_ingested_available_energy_kj_h,
      canonical$realized_ingested_available_energy_kj_h
    ) &&
    identical(
      anchor$gut_available_energy_start_kj,
      canonical$gut_available_energy_start_kj
    ) &&
    identical(
      anchor$gut_available_energy_end_kj,
      canonical$gut_available_energy_end_kj
    ) &&
    identical(
      anchor$body_energy_reserve_start_kj,
      canonical$body_energy_reserve_start_kj
    ) &&
    identical(
      anchor$body_energy_reserve_end_kj,
      canonical$body_energy_reserve_end_kj
    ) &&
    identical(
      anchor$total_system_energy_end_kj,
      canonical$total_system_energy_end_kj
    ),
  "exact adequate-quality canonical identity"
)

require_goal025(
  all(goal025_daily$adequate_quality_feeding_hours +
    goal025_daily$lower_quality_feeding_hours == 16L) &&
    all(goal025_daily$routine_activity_expenditure_kj == 800) &&
    all(goal025_daily$forage_acquisition_ceiling_active_hours == 0L) &&
    all(goal025_daily$body_energy_reserve_final_kj > 0),
  "fixed exposure, activity, non-limiting acquisition, and positive reserve"
)
require_goal025(
  all(
    goal025_hourly$realized_ingested_available_energy_kj_h ==
      goal025_hourly$realized_dry_matter_intake_kg_dm_h *
        goal025_hourly$metabolizable_energy_density_kj_kg_dm
  ) &&
    near(
      goal025_daily$maximum_gut_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      goal025_daily$maximum_body_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      goal025_daily$maximum_system_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    all(is.finite(unlist(goal025_mixed_order_contrast[-1L]))),
  "local density conversion, accounting, and finite mixed-order contrast"
)

goal025_diagnostics <- list(
  design = goal025_design,
  exposures = goal025_exposures,
  hourly = goal025_hourly,
  daily = goal025_daily,
  mixed_order_contrast = goal025_mixed_order_contrast
)

cat("Goal 025 diagnostics passed.\n")
for (row_index in seq_len(nrow(goal025_daily))) {
  row <- goal025_daily[row_index, ]
  cat(sprintf(
    paste0(
      "  %s: target %.3f kg DM; realized %.3f kg DM; energy %.0f kJ; ",
      "upper bound %d h; combined %+.0f kJ.\n"
    ),
    row$arm_id,
    row$appetite_target_dry_matter_intake_kg_dm,
    row$realized_dry_matter_intake_kg_dm,
    row$realized_ingested_available_energy_kj,
    row$upper_intake_bound_hours,
    row$combined_energy_deviation_final_kj
  ))
}
cat(sprintf(
  paste0(
    "  Mixed-order contrast: target %+.3f kg DM; realized %+.3f kg DM; ",
    "energy %+.0f kJ; gut %+.0f kJ; body %+.0f kJ; combined %+.0f kJ.\n"
  ),
  goal025_mixed_order_contrast$
    appetite_target_dry_matter_intake_kg_dm,
  goal025_mixed_order_contrast$realized_dry_matter_intake_kg_dm,
  goal025_mixed_order_contrast$realized_ingested_available_energy_kj,
  goal025_mixed_order_contrast$gut_available_energy_final_kj,
  goal025_mixed_order_contrast$body_energy_reserve_final_kj,
  goal025_mixed_order_contrast$combined_energy_deviation_final_kj
))
