arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-018-severity-recurrence-map.R")

require_goal019 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 019 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

body_mass_parameters <- herbivoreTTR::new_body_mass_parameters(
  structural_body_mass_kg = 38,
  reserve_tissue_energy_density_kj_kg = 20000
)
reference_body_mass <- herbivoreTTR::derive_body_mass_from_energy_reserve(
  body_mass_parameters,
  40000
)
require_goal019(
  identical(
    reference_body_mass,
    data.frame(
      body_energy_reserve_kj = 40000,
      reserve_tissue_mass_kg = 2,
      total_body_mass_kg = 40
    )
  ),
  "exact 38-kg structural plus 2-kg reserve reference"
)

body_energy_coordinate_shift_kj <- 30000
old_appetite_reference_schedule <-
  herbivoreTTR::new_appetite_reference_schedule(
    hour_of_day = appetite_reference_schedule$hour_of_day,
    feeding_opportunity_open =
      appetite_reference_schedule$feeding_opportunity_open,
    reference_dry_matter_intake_kg_dm_h =
      appetite_reference_schedule$reference_dry_matter_intake_kg_dm_h,
    reference_body_energy_reserve_kj =
      appetite_reference_schedule$reference_body_energy_reserve_kj -
        body_energy_coordinate_shift_kj,
    reference_gut_available_energy_kj =
      appetite_reference_schedule$reference_gut_available_energy_kj
  )
old_reference_opening_body_state <- herbivoreTTR::new_body_energy_state(
  reference_opening_body_energy_kj - body_energy_coordinate_shift_kj
)

translate_result_to_old_coordinate <- function(result) {
  coordinate_fields <- c(
    "body_energy_reserve_start_kj",
    "body_energy_reserve_end_kj",
    "body_energy_reserve_initial_kj",
    "body_energy_reserve_final_kj",
    "total_system_energy_start_kj",
    "total_system_energy_end_kj",
    "total_system_energy_initial_kj",
    "total_system_energy_final_kj"
  )
  lapply(result, function(table) {
    fields <- intersect(names(table), coordinate_fields)
    table[fields] <- lapply(
      table[fields],
      function(value) value - body_energy_coordinate_shift_kj
    )
    table
  })
}

same_table_within_coordinate_roundoff <- function(observed, expected) {
  if (
    !identical(class(observed), class(expected)) ||
      !identical(dim(observed), dim(expected)) ||
      !identical(names(observed), names(expected))
  ) {
    return(FALSE)
  }

  all(vapply(names(observed), function(field) {
    if (is.numeric(observed[[field]]) && is.numeric(expected[[field]])) {
      return(near(observed[[field]], expected[[field]], scale = 40000))
    }
    identical(observed[[field]], expected[[field]])
  }, logical(1L)))
}

same_result_within_coordinate_roundoff <- function(observed, expected) {
  identical(names(observed), names(expected)) &&
    all(vapply(names(observed), function(component) {
      same_table_within_coordinate_roundoff(
        observed[[component]],
        expected[[component]]
      )
    }, logical(1L)))
}

old_shortfall_day <- herbivoreTTR::run_gut_body_energy_day(
  initial_gut_state = reference_opening_gut_state,
  initial_body_state = old_reference_opening_body_state,
  gut_parameters = gut_parameters,
  body_parameters = body_parameters,
  schedule = shortfall_energy_schedule,
  routine_activity_schedule = routine_activity_schedule
)
old_controlled_result <- herbivoreTTR::run_appetite_controlled_energy_days(
  initial_gut_state = herbivoreTTR::new_gut_energy_state(
    old_shortfall_day$daily$gut_available_energy_final_kj
  ),
  initial_body_state = herbivoreTTR::new_body_energy_state(
    old_shortfall_day$daily$body_energy_reserve_final_kj
  ),
  gut_parameters = gut_parameters,
  body_parameters = body_parameters,
  food_parameters = food_parameters,
  appetite_parameters = appetite_parameters,
  appetite_reference_schedule = old_appetite_reference_schedule,
  forage_acquisition_ceiling_schedule =
    nonlimiting_forage_acquisition_ceiling_schedule,
  routine_activity_schedule = routine_activity_schedule,
  number_of_days = 9L
)
require_goal019(
  identical(
    old_appetite_reference_schedule$reference_body_energy_reserve_kj,
    appetite_reference_schedule$reference_body_energy_reserve_kj -
      body_energy_coordinate_shift_kj
  ) &&
    same_result_within_coordinate_roundoff(
      old_shortfall_day,
      translate_result_to_old_coordinate(shortfall_day)
    ) &&
    same_result_within_coordinate_roundoff(
      old_controlled_result,
      translate_result_to_old_coordinate(controlled_result)
    ),
  paste0(
    "exact translation invariance of reference, appetite, intake, gut, ",
    "and body-energy trajectories"
  )
)

old_strong_two_day_result <- run_severity_recurrence_scenario(
  severity_id = "strong_1200",
  forage_ceiling_kg_dm_h = 0.0125,
  event_loss_kj = 1200,
  recurrence_interval_days = 2L,
  initial_body_state = old_reference_opening_body_state,
  reference_schedule = old_appetite_reference_schedule,
  experiment_days = 47L
)
strong_scenario_index <- which(
  factorial_design$severity_id == "strong_1200" &
    factorial_design$recurrence_interval_days == 2L
)
new_strong_two_day_result <- scenario_results[[strong_scenario_index]]
new_shared_daily <- new_strong_two_day_result$daily[
  seq_len(old_strong_two_day_result$completed_days),
  ,
  drop = FALSE
]
new_shared_daily$body_energy_reserve_final_kj <-
  new_shared_daily$body_energy_reserve_final_kj -
    body_energy_coordinate_shift_kj
row.names(new_shared_daily) <- NULL
require_goal019(
  identical(old_strong_two_day_result$boundary_day, 47L) &&
    identical(old_strong_two_day_result$completed_days, 46L) &&
    same_table_within_coordinate_roundoff(
      old_strong_two_day_result$daily,
      new_shared_daily
    ) &&
    is.na(new_strong_two_day_result$boundary_day) &&
    identical(new_strong_two_day_result$completed_days, 48L),
  "the former day-47 boundary is solely the old energy-coordinate floor"
)

strong_scenario_id <- "strong_1200_every_2_days"
strong_summary <- severity_recurrence_summary[
  severity_recurrence_summary$scenario_id == strong_scenario_id,
  ,
  drop = FALSE
]
strong_cycles <- severity_event_cycles[
  severity_event_cycles$scenario_id == strong_scenario_id &
    !is.na(severity_event_cycles$net_energy_change_over_cycle_kj),
  ,
  drop = FALSE
]
require_goal019(
  identical(strong_summary$completed_days, 48L) &&
    is.na(strong_summary$boundary_day) &&
    identical(
      strong_summary$observed_pattern,
      "energy debt still accumulating over completed horizon"
    ) &&
    near(
      tail(strong_cycles$net_energy_change_over_cycle_kj, 1L),
      -400
    ) &&
    identical(
      round(strong_summary$final_valid_combined_energy_deviation_kj),
      -9792
    ),
  "continued strong two-day debt at the exact minus-400-kJ cycle margin"
)

derived_daily_body_mass <- herbivoreTTR::derive_body_mass_from_energy_reserve(
  body_mass_parameters,
  severity_daily_results$body_energy_reserve_final_kj
)
body_mass_daily <- cbind(
  severity_daily_results[c(
    "scenario_id",
    "severity_id",
    "event_loss_kj",
    "recurrence_interval_days",
    "simulation_day",
    "limited_forage_day",
    "combined_energy_deviation_final_kj"
  )],
  derived_daily_body_mass
)
body_mass_summary <- do.call(
  rbind,
  lapply(split(body_mass_daily, body_mass_daily$scenario_id), function(daily) {
    data.frame(
      scenario_id = daily$scenario_id[[1L]],
      event_loss_kj = daily$event_loss_kj[[1L]],
      recurrence_interval_days = daily$recurrence_interval_days[[1L]],
      final_body_energy_reserve_kj =
        tail(daily$body_energy_reserve_kj, 1L),
      minimum_body_energy_reserve_kj = min(daily$body_energy_reserve_kj),
      final_reserve_tissue_mass_kg =
        tail(daily$reserve_tissue_mass_kg, 1L),
      minimum_reserve_tissue_mass_kg = min(daily$reserve_tissue_mass_kg),
      final_total_body_mass_kg = tail(daily$total_body_mass_kg, 1L),
      minimum_total_body_mass_kg = min(daily$total_body_mass_kg)
    )
  })
)
row.names(body_mass_summary) <- NULL
body_mass_summary <- body_mass_summary[
  order(
    body_mass_summary$event_loss_kj,
    -body_mass_summary$recurrence_interval_days
  ),
  ,
  drop = FALSE
]
row.names(body_mass_summary) <- NULL

require_goal019(
  near(
    body_mass_daily$total_body_mass_kg,
    38 + body_mass_daily$body_energy_reserve_kj / 20000
  ) &&
    all(body_mass_daily$total_body_mass_kg > 38),
  "exact derived-mass identity and positive labile reserve"
)

goal019_diagnostics <- list(
  body_mass_parameters = body_mass_parameters,
  reference_body_mass = reference_body_mass,
  translation_shift_kj = body_energy_coordinate_shift_kj,
  old_strong_two_day_result = old_strong_two_day_result,
  body_mass_daily = body_mass_daily,
  body_mass_summary = body_mass_summary
)

cat(sprintf(
  paste0(
    "Goal 019 diagnostics passed: 40 kg reference; strong two-day final ",
    "mass %.2f kg; final cycle %+.0f kJ; no reserve boundary.\n"
  ),
  strong_summary$final_valid_body_energy_reserve_kj / 20000 + 38,
  tail(strong_cycles$net_energy_change_over_cycle_kj, 1L)
))
