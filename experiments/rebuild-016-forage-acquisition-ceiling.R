arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-013-minimal-endogenous-appetite-control.R")

require_goal016 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 016 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

binding_forage_acquisition_ceiling_schedule <-
  herbivoreTTR::new_forage_acquisition_ceiling_schedule(
    hour_of_day,
    as.double(feeding_opportunity_open) * 0.015
  )

binding_result <- herbivoreTTR::run_appetite_controlled_energy_days(
  initial_gut_state = reference_opening_gut_state,
  initial_body_state = reference_opening_body_state,
  gut_parameters = gut_parameters,
  body_parameters = body_parameters,
  food_parameters = food_parameters,
  appetite_parameters = appetite_parameters,
  appetite_reference_schedule = appetite_reference_schedule,
  forage_acquisition_ceiling_schedule =
    binding_forage_acquisition_ceiling_schedule,
  routine_activity_schedule = routine_activity_schedule,
  number_of_days = 1L
)

require_goal016(
  !any(
    balanced_appetite_control$hourly$
      forage_acquisition_ceiling_active
  ) &&
    near(
      balanced_appetite_control$hourly$
        appetite_target_dry_matter_intake_kg_dm_h,
      balanced_appetite_control$hourly$
        realized_dry_matter_intake_kg_dm_h
    ) &&
    near(
      balanced_appetite_control$daily$
        observed_total_system_energy_change_kj,
      0,
      scale = 10000
    ),
  "non-binding ceiling preserves the accepted reference"
)

require_goal016(
  identical(
    binding_result$hourly$forage_acquisition_ceiling_active,
    feeding_opportunity_open
  ) &&
    all(
      binding_result$hourly$
        appetite_target_dry_matter_intake_kg_dm_h[
          feeding_opportunity_open
        ] >
        binding_result$hourly$realized_dry_matter_intake_kg_dm_h[
          feeding_opportunity_open
        ]
    ) &&
    identical(
      binding_result$hourly$realized_dry_matter_intake_kg_dm_h,
      shortfall_dry_matter_rates_kg_dm_h
    ),
  "binding ceiling separates appetite target from realized intake"
)

require_goal016(
  near(binding_result$daily$realized_dry_matter_intake_kg_dm, 0.24) &&
    near(
      binding_result$daily$total_realized_ingested_available_energy_kj,
      2400
    ) &&
    identical(
      binding_result$daily$forage_acquisition_ceiling_active_hours,
      16L
    ) &&
    near(
      binding_result$daily$observed_total_system_energy_change_kj,
      -800,
      scale = 10000
    ) &&
    near(
      binding_result$daily$
        combined_energy_deviation_from_reference_final_kj,
      -800,
      scale = 10000
    ),
  "analytical one-day acquisition-limited energy deficit"
)

require_goal016(
  near(binding_result$hourly$gut_energy_balance_residual_kj, 0, 10000) &&
    near(binding_result$hourly$body_energy_balance_residual_kj, 0, 10000) &&
    near(binding_result$hourly$system_energy_balance_residual_kj, 0, 10000),
  "binding-case gut, body, and whole-system accounting closure"
)

forage_acquisition_summary <- data.frame(
  scenario_id = c("non_binding_reference", "binding_0.015_kg_dm_h"),
  appetite_target_dry_matter_intake_kg_dm = c(
    balanced_appetite_control$daily$
      appetite_target_dry_matter_intake_kg_dm,
    binding_result$daily$appetite_target_dry_matter_intake_kg_dm
  ),
  realized_dry_matter_intake_kg_dm = c(
    balanced_appetite_control$daily$realized_dry_matter_intake_kg_dm,
    binding_result$daily$realized_dry_matter_intake_kg_dm
  ),
  realized_ingested_available_energy_kj = c(
    balanced_appetite_control$daily$
      total_realized_ingested_available_energy_kj,
    binding_result$daily$total_realized_ingested_available_energy_kj
  ),
  forage_acquisition_ceiling_active_hours = c(
    balanced_appetite_control$daily$
      forage_acquisition_ceiling_active_hours,
    binding_result$daily$forage_acquisition_ceiling_active_hours
  ),
  combined_energy_change_kj = c(
    balanced_appetite_control$daily$
      observed_total_system_energy_change_kj,
    binding_result$daily$observed_total_system_energy_change_kj
  ),
  combined_energy_deviation_from_reference_final_kj = c(
    balanced_appetite_control$daily$
      combined_energy_deviation_from_reference_final_kj,
    binding_result$daily$
      combined_energy_deviation_from_reference_final_kj
  )
)

forage_acquisition_hourly <- binding_result$hourly[c(
  "hour_of_day",
  "feeding_opportunity_open",
  "appetite_target_dry_matter_intake_kg_dm_h",
  "forage_acquisition_ceiling_kg_dm_h",
  "forage_acquisition_ceiling_active",
  "realized_dry_matter_intake_kg_dm_h",
  "body_energy_deviation_from_reference_kj",
  "gut_energy_deviation_from_reference_kj"
)]

goal016_diagnostics <- list(
  summary = forage_acquisition_summary,
  binding_hourly = forage_acquisition_hourly,
  non_binding_result = balanced_appetite_control,
  binding_result = binding_result
)

cat(
  sprintf(
    paste0(
      "Goal 016 diagnostics passed: target %.3f kg DM, realized %.3f kg ",
      "DM, %d binding hours, combined change %.0f kJ.\n"
    ),
    binding_result$daily$appetite_target_dry_matter_intake_kg_dm,
    binding_result$daily$realized_dry_matter_intake_kg_dm,
    binding_result$daily$forage_acquisition_ceiling_active_hours,
    binding_result$daily$observed_total_system_energy_change_kj
  )
)
