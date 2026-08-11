arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-021-rate-duration-feedback-decomposition.R")

require_goal022 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 022 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

patch_ceiling_kg_dm_h <- c(
  adequate_patch = 0.025,
  limited_patch = 0.015
)
first_feeding_window_hours <- 0:7
rest_transition_hours <- 8:15
second_feeding_window_hours <- 16:23

goal022_design <- data.frame(
  arm_id = c(
    "adequate_then_adequate",
    "limited_then_limited",
    "limited_then_adequate",
    "adequate_then_limited"
  ),
  first_patch = c(
    "adequate_patch",
    "limited_patch",
    "limited_patch",
    "adequate_patch"
  ),
  second_patch = c(
    "adequate_patch",
    "limited_patch",
    "adequate_patch",
    "limited_patch"
  ),
  stringsAsFactors = FALSE
)

make_patch_exposure <- function(arm_id, first_patch, second_patch) {
  patch_id <- rep("rest_transition", 24L)
  patch_id[hour_of_day %in% first_feeding_window_hours] <- first_patch
  patch_id[hour_of_day %in% second_feeding_window_hours] <- second_patch
  feeding_window_id <- rep("central_rest", 24L)
  feeding_window_id[hour_of_day %in% first_feeding_window_hours] <-
    "first_feeding_window"
  feeding_window_id[hour_of_day %in% second_feeding_window_hours] <-
    "second_feeding_window"

  ceiling_kg_dm_h <- numeric(24L)
  ceiling_kg_dm_h[hour_of_day %in% first_feeding_window_hours] <-
    patch_ceiling_kg_dm_h[[first_patch]]
  ceiling_kg_dm_h[hour_of_day %in% second_feeding_window_hours] <-
    patch_ceiling_kg_dm_h[[second_patch]]

  list(
    arm_id = arm_id,
    first_patch = first_patch,
    second_patch = second_patch,
    patch_id = patch_id,
    feeding_window_id = feeding_window_id,
    ceiling_schedule =
      herbivoreTTR::new_forage_acquisition_ceiling_schedule(
        hour_of_day,
        ceiling_kg_dm_h
      )
  )
}

goal022_exposures <- lapply(seq_len(nrow(goal022_design)), function(index) {
  make_patch_exposure(
    arm_id = goal022_design$arm_id[[index]],
    first_patch = goal022_design$first_patch[[index]],
    second_patch = goal022_design$second_patch[[index]]
  )
})
names(goal022_exposures) <- goal022_design$arm_id

run_patch_exposure <- function(exposure) {
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
    number_of_days = 1L
  )
}

goal022_results <- lapply(goal022_exposures, run_patch_exposure)

adequate_result <- goal022_results$adequate_then_adequate
limited_result <- goal022_results$limited_then_limited
adequate_dynamic_fields <- setdiff(
  names(adequate_result$hourly),
  "forage_acquisition_ceiling_kg_dm_h"
)

require_goal022(
  identical(
    adequate_result$hourly[adequate_dynamic_fields],
    balanced_appetite_control$hourly[adequate_dynamic_fields]
  ) &&
    identical(adequate_result$daily, balanced_appetite_control$daily),
  "adequate-patch reference trajectory and accounting identity"
)
require_goal022(
  identical(limited_result, binding_result),
  "limited-patch Goal 016 identity"
)

build_goal022_hourly <- function(arm_id, exposure, result) {
  data.frame(
    arm_id = arm_id,
    hour_of_day = result$hourly$hour_of_day,
    feeding_window_id = exposure$feeding_window_id,
    patch_id = exposure$patch_id,
    feeding_opportunity_open = result$hourly$feeding_opportunity_open,
    forage_acquisition_ceiling_kg_dm_h =
      result$hourly$forage_acquisition_ceiling_kg_dm_h,
    appetite_target_dry_matter_intake_kg_dm_h =
      result$hourly$appetite_target_dry_matter_intake_kg_dm_h,
    realized_dry_matter_intake_kg_dm_h =
      result$hourly$realized_dry_matter_intake_kg_dm_h,
    forage_acquisition_ceiling_active =
      result$hourly$forage_acquisition_ceiling_active,
    assimilated_energy_kj_h = result$hourly$assimilated_energy_kj_h,
    gut_available_energy_end_kj =
      result$hourly$gut_available_energy_end_kj,
    body_energy_reserve_end_kj =
      result$hourly$body_energy_reserve_end_kj,
    combined_energy_deviation_end_kj =
      result$hourly$total_system_energy_end_kj -
        balanced_appetite_control$hourly$total_system_energy_end_kj,
    gut_energy_balance_residual_kj =
      result$hourly$gut_energy_balance_residual_kj,
    body_energy_balance_residual_kj =
      result$hourly$body_energy_balance_residual_kj,
    system_energy_balance_residual_kj =
      result$hourly$system_energy_balance_residual_kj,
    stringsAsFactors = FALSE
  )
}

goal022_hourly <- do.call(
  rbind,
  lapply(seq_along(goal022_results), function(index) {
    arm_id <- names(goal022_results)[[index]]
    build_goal022_hourly(
      arm_id,
      goal022_exposures[[arm_id]],
      goal022_results[[arm_id]]
    )
  })
)
row.names(goal022_hourly) <- NULL

build_goal022_daily <- function(arm_id, exposure, result) {
  mass <- herbivoreTTR::derive_body_mass_from_energy_reserve(
    body_mass_parameters,
    result$daily$body_energy_reserve_final_kj
  )
  data.frame(
    arm_id = arm_id,
    first_patch = exposure$first_patch,
    second_patch = exposure$second_patch,
    first_patch_feeding_hours = 8L,
    second_patch_feeding_hours = 8L,
    aggregate_ceiling_capacity_kg_dm = sum(
      exposure$ceiling_schedule$forage_acquisition_ceiling_kg_dm_h[
        feeding_opportunity_open
      ]
    ),
    appetite_target_dry_matter_intake_kg_dm =
      result$daily$appetite_target_dry_matter_intake_kg_dm,
    realized_dry_matter_intake_kg_dm =
      result$daily$realized_dry_matter_intake_kg_dm,
    unrealized_target_dry_matter_intake_kg_dm =
      result$daily$appetite_target_dry_matter_intake_kg_dm -
        result$daily$realized_dry_matter_intake_kg_dm,
    forage_acquisition_ceiling_active_hours =
      result$daily$forage_acquisition_ceiling_active_hours,
    lower_intake_bound_hours = result$daily$lower_intake_bound_hours,
    upper_intake_bound_hours = result$daily$upper_intake_bound_hours,
    realized_ingested_available_energy_kj =
      result$daily$total_realized_ingested_available_energy_kj,
    routine_activity_expenditure_kj =
      result$daily$total_prescribed_routine_activity_expenditure_kj,
    gut_available_energy_final_kj =
      result$daily$gut_available_energy_final_kj,
    body_energy_reserve_final_kj =
      result$daily$body_energy_reserve_final_kj,
    gut_energy_deviation_final_kj =
      result$daily$gut_energy_deviation_from_reference_final_kj,
    body_energy_deviation_final_kj =
      result$daily$body_energy_deviation_from_reference_final_kj,
    combined_energy_deviation_final_kj =
      result$daily$combined_energy_deviation_from_reference_final_kj,
    total_system_energy_change_kj =
      result$daily$observed_total_system_energy_change_kj,
    reserve_tissue_mass_final_kg = mass$reserve_tissue_mass_kg,
    total_body_mass_final_kg = mass$total_body_mass_kg,
    stringsAsFactors = FALSE
  )
}

goal022_daily <- do.call(
  rbind,
  lapply(seq_along(goal022_results), function(index) {
    arm_id <- names(goal022_results)[[index]]
    build_goal022_daily(
      arm_id,
      goal022_exposures[[arm_id]],
      goal022_results[[arm_id]]
    )
  })
)
row.names(goal022_daily) <- NULL

daily_value <- function(arm_id, field_name) {
  goal022_daily[[field_name]][goal022_daily$arm_id == arm_id]
}

goal022_mixed_order_contrast <- data.frame(
  contrast = "limited_then_adequate - adequate_then_limited",
  realized_dry_matter_intake_kg_dm =
    daily_value(
      "limited_then_adequate",
      "realized_dry_matter_intake_kg_dm"
    ) -
      daily_value(
        "adequate_then_limited",
        "realized_dry_matter_intake_kg_dm"
      ),
  realized_ingested_available_energy_kj =
    daily_value(
      "limited_then_adequate",
      "realized_ingested_available_energy_kj"
    ) -
      daily_value(
        "adequate_then_limited",
        "realized_ingested_available_energy_kj"
      ),
  gut_available_energy_final_kj =
    daily_value(
      "limited_then_adequate",
      "gut_available_energy_final_kj"
    ) -
      daily_value(
        "adequate_then_limited",
        "gut_available_energy_final_kj"
      ),
  body_energy_reserve_final_kj =
    daily_value(
      "limited_then_adequate",
      "body_energy_reserve_final_kj"
    ) -
      daily_value(
        "adequate_then_limited",
        "body_energy_reserve_final_kj"
      ),
  combined_energy_deviation_final_kj =
    daily_value(
      "limited_then_adequate",
      "combined_energy_deviation_final_kj"
    ) -
      daily_value(
        "adequate_then_limited",
        "combined_energy_deviation_final_kj"
      ),
  stringsAsFactors = FALSE
)

mixed_arm_ids <- c("limited_then_adequate", "adequate_then_limited")
mixed_rows <- goal022_daily$arm_id %in% mixed_arm_ids
first_rows <- do.call(
  rbind,
  lapply(goal022_results, function(result) result$daily[1L, , drop = FALSE])
)
expected_binding <-
  goal022_hourly$feeding_opportunity_open &
    goal022_hourly$patch_id == "limited_patch"

require_goal022(
  all(
    first_rows$gut_available_energy_initial_kj ==
      reference_opening_gut_state$gut_available_energy_kj
  ) &&
    all(
      first_rows$body_energy_reserve_initial_kj ==
        reference_opening_body_state$body_energy_reserve_kj
    ) &&
    all(goal022_daily$routine_activity_expenditure_kj == 800) &&
    all(goal022_daily$body_energy_reserve_final_kj > 0),
  "common start, fixed activity, and positive body reserve"
)
require_goal022(
  near(
    goal022_daily$aggregate_ceiling_capacity_kg_dm[mixed_rows],
    0.32,
    scale = 1
  ) &&
    all(goal022_daily$first_patch_feeding_hours[mixed_rows] == 8L) &&
    all(goal022_daily$second_patch_feeding_hours[mixed_rows] == 8L),
  "equal mixed-arm patch exposure and aggregate ceiling capacity"
)
require_goal022(
  identical(
    goal022_hourly$forage_acquisition_ceiling_active,
    expected_binding
  ) &&
    all(
      goal022_hourly$forage_acquisition_ceiling_kg_dm_h[
        goal022_hourly$patch_id == "rest_transition"
      ] == 0
    ),
  "ceiling engagement follows limited-patch exposure only"
)
require_goal022(
  near(
    goal022_hourly$gut_energy_balance_residual_kj,
    0,
    scale = reference_opening_body_energy_kj
  ) &&
    near(
      goal022_hourly$body_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      goal022_hourly$system_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    all(is.finite(unlist(goal022_mixed_order_contrast[-1L]))),
  "energy accounting and finite mixed-order contrasts"
)
require_goal022(
  near(
    goal022_mixed_order_contrast$combined_energy_deviation_final_kj,
    goal022_mixed_order_contrast$realized_ingested_available_energy_kj,
    scale = reference_opening_body_energy_kj
  ),
  "mixed-order whole-system contrast equals its ingested-energy contrast"
)

goal022_diagnostics <- list(
  design = goal022_design,
  exposures = goal022_exposures,
  results = goal022_results,
  hourly = goal022_hourly,
  daily = goal022_daily,
  mixed_order_contrast = goal022_mixed_order_contrast
)

cat("Goal 022 diagnostics passed.\n")
for (index in seq_len(nrow(goal022_daily))) {
  cat(sprintf(
    "  %s: target %.3f kg DM; realized %.3f kg DM; binding %d h; combined %+.0f kJ.\n",
    goal022_daily$arm_id[[index]],
    goal022_daily$appetite_target_dry_matter_intake_kg_dm[[index]],
    goal022_daily$realized_dry_matter_intake_kg_dm[[index]],
    goal022_daily$forage_acquisition_ceiling_active_hours[[index]],
    goal022_daily$combined_energy_deviation_final_kj[[index]]
  ))
}
cat(sprintf(
  paste0(
    "  Mixed-order contrast: intake %+.3f kg DM; gut %+.0f kJ; ",
    "body %+.0f kJ; combined %+.0f kJ.\n"
  ),
  goal022_mixed_order_contrast$realized_dry_matter_intake_kg_dm,
  goal022_mixed_order_contrast$gut_available_energy_final_kj,
  goal022_mixed_order_contrast$body_energy_reserve_final_kj,
  goal022_mixed_order_contrast$combined_energy_deviation_final_kj
))
