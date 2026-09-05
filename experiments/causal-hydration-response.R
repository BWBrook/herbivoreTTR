source("experiments/isolated-hydration-fixtures.R")

precondition_days <- 60L
treatment_days <- 84L
recovery_days <- 42L
branch_days <- treatment_days + recovery_days
event_increment_kg_day <- 0.44
regime_names <- c(
  "control",
  "clustered",
  "repeated",
  "diffuse_dose_control",
  "sustained"
)
policy_names <- c("daily_opening", "hourly_reactive")

new_causal_regime_calendar <- function(regime) {
  calendar <- rep(0, branch_days)
  if (regime == "clustered") {
    calendar[36:49] <- event_increment_kg_day
  } else if (regime == "repeated") {
    event_days <- unlist(lapply(
      c(1L, 13L, 25L, 37L, 49L, 61L, 73L),
      function(start_day) start_day + 0:1
    ))
    calendar[event_days] <- event_increment_kg_day
  } else if (regime == "diffuse_dose_control") {
    calendar[seq_len(treatment_days)] <-
      event_increment_kg_day * 14 / treatment_days
  } else if (regime == "sustained") {
    calendar[seq_len(treatment_days)] <- event_increment_kg_day
  } else if (regime != "control") {
    stop("Unknown causal hydration regime.")
  }
  calendar
}

causal_hydration_forcing_calendars <- setNames(
  lapply(regime_names, new_causal_regime_calendar),
  regime_names
)

new_planner_probe <- function(
  opening_body_water_kg,
  incremental_loss_kg_h,
  water_parameters = isolated_water_parameters
) {
  landscape <- new_isolated_hydration_landscape()
  base_itinerary <- new_isolated_hydration_itinerary(FALSE)
  base_energy <- herbivoreTTR::run_prescribed_spatial_energy_day(
    initial_location_state = herbivoreTTR::new_patch_location_state(
      isolated_forage_patch_id
    ),
    landscape = landscape,
    itinerary = base_itinerary,
    initial_gut_state = water_constrained_fixture$opening_gut,
    initial_body_state = water_constrained_fixture$opening_body,
    gut_parameters = water_constrained_fixture$gut,
    body_parameters = water_constrained_fixture$body,
    appetite_parameters = water_constrained_fixture$appetite,
    appetite_reference_schedule = water_constrained_fixture$appetite_reference,
    routine_activity_schedule = water_constrained_fixture$activity
  )
  plan <- new_reactive_water_visit_plan(
    herbivoreTTR::new_body_water_state(opening_body_water_kg),
    water_parameters,
    isolated_water_properties,
    landscape,
    base_energy$hourly,
    incremental_loss_kg_h,
    isolated_water_source_patch_id,
    water_constrained_thirst_trigger_body_water_kg
  )
  final_energy <- if (plan$water_visit) {
    herbivoreTTR::run_prescribed_spatial_energy_day(
      initial_location_state = herbivoreTTR::new_patch_location_state(
        isolated_forage_patch_id
      ),
      landscape = landscape,
      itinerary = plan$itinerary,
      initial_gut_state = water_constrained_fixture$opening_gut,
      initial_body_state = water_constrained_fixture$opening_body,
      gut_parameters = water_constrained_fixture$gut,
      body_parameters = water_constrained_fixture$body,
      appetite_parameters = water_constrained_fixture$appetite,
      appetite_reference_schedule =
        water_constrained_fixture$appetite_reference,
      routine_activity_schedule = water_constrained_fixture$activity
    )
  } else {
    base_energy
  }
  final_water <- herbivoreTTR::run_spatial_body_water_day(
    herbivoreTTR::new_body_water_state(opening_body_water_kg),
    water_parameters,
    isolated_water_properties,
    final_energy$hourly,
    incremental_loss_kg_h
  )
  list(
    plan = plan,
    base_energy = base_energy,
    final_energy = final_energy,
    final_water = final_water
  )
}

causal_probe <- new_planner_probe(
  opening_body_water_kg = 26.1,
  incremental_loss_kg_h = new_daily_evaporative_loss_schedule(0.44)
)
prefix_rows <- causal_probe$base_energy$hourly$hour_of_day <
  causal_probe$plan$departure_hour
late_loss <- rep(0, 24L)
late_loss[[24L]] <- 3
late_probe <- new_planner_probe(
  opening_body_water_kg = 28,
  incremental_loss_kg_h = late_loss,
  water_parameters = herbivoreTTR::new_body_water_parameters(28, 24, 0)
)
zero_probe <- new_planner_probe(
  opening_body_water_kg = 28,
  incremental_loss_kg_h = rep(0, 24L),
  water_parameters = herbivoreTTR::new_body_water_parameters(28, 24, 0)
)

assert_that(
  causal_probe$plan$water_visit &&
    !causal_probe$plan$thirst_detected_at_opening &&
    causal_probe$plan$departure_hour >= causal_probe$plan$detection_time_h &&
    causal_probe$plan$drinking_hour > causal_probe$plan$detection_time_h &&
    identical(
      causal_probe$base_energy$hourly$closing_patch_id[prefix_rows],
      causal_probe$final_energy$hourly$closing_patch_id[prefix_rows]
    ) &&
    near(
      causal_probe$plan$no_visit_water$hourly$body_water_end_kg[prefix_rows],
      causal_probe$final_water$hourly$body_water_end_kg[prefix_rows]
    ),
  "the revised path is identical before the observed thirst boundary"
)
assert_that(
  late_probe$plan$thirst_detected &&
    late_probe$plan$detection_time_h == 24L &&
    late_probe$plan$visit_deferred &&
    !late_probe$plan$water_visit &&
    !zero_probe$plan$thirst_detected &&
    !zero_probe$plan$water_visit,
  "late thirst is deferred and a non-thirsty day remains unchanged"
)

run_policy_grid <- function(run_branch) {
  grid <- expand.grid(
    water_visit_policy = policy_names,
    regime = regime_names,
    stringsAsFactors = FALSE
  )
  runs <- lapply(seq_len(nrow(grid)), function(row) {
    run_branch(
      grid$regime[[row]],
      grid$water_visit_policy[[row]],
      causal_hydration_forcing_calendars[[grid$regime[[row]]]]
    )
  })
  names(runs) <- paste(grid$water_visit_policy, grid$regime, sep = "::")
  runs
}

isolated_precondition <- run_isolated_hydration_days(
  "common_baseline",
  precondition_days,
  water_visit_policy = "daily_opening"
)
isolated_context <- attr(isolated_precondition, "final_context")
causal_hydration_isolated_runs <- run_policy_grid(
  function(regime, policy, calendar) {
    run_isolated_hydration_days(
      regime,
      branch_days,
      isolated_context,
      calendar,
      policy
    )
  }
)

integrated_baseline_scenario <- data.frame(
  scenario = "common_baseline",
  scenario_role = "precondition",
  water_layer_active = TRUE,
  food_water_yield_kg_water_kg_dm = 3.28,
  daily_ordinary_water_loss_kg = 1.56,
  water_movement_expenditure_per_leg_kj = 900,
  stringsAsFactors = FALSE
)

# Invalid state must raise an error, not masquerade as a scientific terminal.
local({
  isolated_bad <- new_isolated_hydration_context()
  coupled_bad <- new_water_constrained_context()
  isolated_bad$state$gut$gut_available_energy_kj <- NA_real_
  coupled_bad$state$gut$gut_available_energy_kj <- NA_real_
  errors <- list(
    tryCatch(run_isolated_hydration_days("invalid", 1L,
      initial_context = isolated_bad), error = identity),
    tryCatch(run_water_constrained_closed_loop(integrated_baseline_scenario,
      1L, initial_context = coupled_bad), error = identity)
  )
  assert_that(all(vapply(errors, inherits, logical(1L), "error")),
    "both hydration runners propagate invalid-state errors")
})
integrated_precondition <- run_water_constrained_closed_loop(
  integrated_baseline_scenario,
  precondition_days,
  water_visit_policy = "daily_opening"
)
integrated_context <- attr(integrated_precondition, "final_context")
causal_hydration_integrated_runs <- run_policy_grid(
  function(regime, policy, calendar) {
    scenario <- integrated_baseline_scenario
    scenario$scenario <- regime
    scenario$scenario_role <- "causal_hydration_response"
    run_water_constrained_closed_loop(
      scenario,
      branch_days,
      integrated_context,
      calendar,
      policy
    )
  }
)

value_at <- function(run, field, row) {
  if (nrow(run) >= row) run[[field]][[row]] else NA_real_
}

summarize_policy_grid <- function(runs, system) {
  rows <- lapply(names(runs), function(key) {
    parts <- strsplit(key, "::", fixed = TRUE)[[1L]]
    policy <- parts[[1L]]
    regime <- parts[[2L]]
    run <- runs[[key]]
    control <- runs[[paste(policy, "control", sep = "::")]]
    daily_comparator <- runs[[paste("daily_opening", regime, sep = "::")]]
    completed_days <- attr(run, "completed_days")
    visit_rows <- which(run$water_visit)
    within_day_visit_rows <- visit_rows[
      !run$thirst_triggered_at_opening[visit_rows]
    ]
    causal_violations <- sum(
      is.na(run$thirst_detection_time_h[visit_rows]) |
        run$water_departure_hour[visit_rows] <
          run$thirst_detection_time_h[visit_rows]
    )
    data.frame(
      system = system,
      water_visit_policy = policy,
      regime = regime,
      completed_days = completed_days,
      terminal_day = attr(run, "terminal_day"),
      terminal_reason = attr(run, "terminal_reason"),
      incremental_evaporative_water_loss_kg = sum(
        run$incremental_evaporative_water_loss_kg
      ),
      thirst_detections = sum(run$thirst_triggered),
      within_day_thirst_detections = sum(
        run$thirst_triggered & !run$thirst_triggered_at_opening
      ),
      water_visits = length(visit_rows),
      within_day_water_visits = length(within_day_visit_rows),
      deferred_water_visits = sum(run$water_visit_deferred),
      causal_violations = causal_violations,
      median_within_day_response_delay_h = if (
        length(within_day_visit_rows)
      ) {
        median(run$water_response_delay_h[within_day_visit_rows])
      } else {
        NA_real_
      },
      water_source_travel_expenditure_kj = length(visit_rows) * 1800,
      water_excursion_feeding_opportunity_h = sum(
        run$water_excursion_feeding_opportunity_h
      ),
      realized_intake_kg_dm = sum(run$realized_intake_kg_dm),
      minimum_body_water_kg = min(run$minimum_body_water_kg),
      minimum_body_energy_reserve_kj = min(
        run$closing_body_energy_reserve_kj
      ),
      energy_debt_treatment_end_kj =
        value_at(control, "closing_body_energy_reserve_kj", treatment_days) -
          value_at(run, "closing_body_energy_reserve_kj", treatment_days),
      energy_debt_recovery_end_kj =
        value_at(control, "closing_body_energy_reserve_kj", branch_days) -
          value_at(run, "closing_body_energy_reserve_kj", branch_days),
      energy_debt_at_last_completed_day_kj =
        value_at(
          control,
          "closing_body_energy_reserve_kj",
          completed_days
        ) - value_at(
          run,
          "closing_body_energy_reserve_kj",
          completed_days
        ),
      reactive_policy_energy_cost_recovery_end_kj =
        value_at(
          daily_comparator,
          "closing_body_energy_reserve_kj",
          branch_days
        ) - value_at(run, "closing_body_energy_reserve_kj", branch_days),
      reactive_policy_energy_cost_at_last_common_day_kj =
        value_at(
          daily_comparator,
          "closing_body_energy_reserve_kj",
          completed_days
        ) - value_at(
          run,
          "closing_body_energy_reserve_kj",
          completed_days
        ),
      food_patch_switches = if ("food_patch_action" %in% names(run)) {
        sum(run$food_patch_action == "move")
      } else {
        NA_integer_
      },
      critical_water_crossed = any(run$body_water_below_critical),
      all_accounts_close = all(run$accounts_close),
      row.names = NULL
    )
  })
  do.call(rbind, rows)
}

causal_hydration_isolated_summary <- summarize_policy_grid(
  causal_hydration_isolated_runs,
  "isolated"
)
causal_hydration_integrated_summary <- summarize_policy_grid(
  causal_hydration_integrated_runs,
  "coupled"
)
causal_hydration_summary <- rbind(
  causal_hydration_isolated_summary,
  causal_hydration_integrated_summary
)

matched_dose <- c("clustered", "repeated", "diffuse_dose_control")
reactive_integrated <- causal_hydration_integrated_summary[
  causal_hydration_integrated_summary$water_visit_policy == "hourly_reactive",
  ,
  drop = FALSE
]
reactive_stressed <- causal_hydration_summary[
  causal_hydration_summary$water_visit_policy == "hourly_reactive" &
    causal_hydration_summary$regime != "control",
  ,
  drop = FALSE
]
sustained_reactive <- reactive_integrated[
  reactive_integrated$regime == "sustained",
  ,
  drop = FALSE
]
sustained_daily <- causal_hydration_integrated_summary[
  causal_hydration_integrated_summary$water_visit_policy == "daily_opening" &
    causal_hydration_integrated_summary$regime == "sustained",
  ,
  drop = FALSE
]
causal_hydration_predictions <- data.frame(
  prediction = c(
    "no visit begins before observed thirst",
    "prescribed stress elicits within-day reactive visits",
    "reactive timing protects the sustained minimum water stock",
    "reactive timing imposes an energetic opportunity cost",
    "sustained forcing is the only causal coupled terminal",
    "equal cumulative dose does not imply equal coupled outcome"
  ),
  supported = c(
    all(causal_hydration_summary$causal_violations == 0),
    all(reactive_stressed$within_day_water_visits > 0),
    sustained_reactive$minimum_body_water_kg >=
      sustained_daily$minimum_body_water_kg,
    all(
      reactive_integrated$
        reactive_policy_energy_cost_at_last_common_day_kj > 0
    ),
    sustained_reactive$completed_days < branch_days &&
      all(
        reactive_integrated$completed_days[
          reactive_integrated$regime != "sustained"
        ] == branch_days
      ),
    length(unique(reactive_integrated$energy_debt_recovery_end_kj[
      reactive_integrated$regime %in% matched_dose
    ])) > 1L
  ),
  stringsAsFactors = FALSE
)

assert_that(
  attr(isolated_precondition, "completed_days") == precondition_days &&
    attr(integrated_precondition, "completed_days") == precondition_days &&
    all(causal_hydration_summary$all_accounts_close),
  "both systems retain closed accounts from one common precondition"
)
assert_that(
  all(causal_hydration_summary$causal_violations == 0) &&
    all(
      causal_hydration_summary$water_visits ==
        causal_hydration_summary$thirst_detections -
          causal_hydration_summary$deferred_water_visits
    ),
  "every source visit follows detected thirst and late detections are explicit"
)
assert_that(
  near(
    vapply(
      causal_hydration_forcing_calendars[matched_dose],
      sum,
      numeric(1L)
    ),
    rep(event_increment_kg_day * 14, length(matched_dose))
  ),
  "clustered, repeated, and diffuse treatments have equal cumulative dose"
)

cat("Causal hydration-response diagnostic passed.\n")
cat("\nA priori prediction check:\n")
print(causal_hydration_predictions, row.names = FALSE)
cat("\nIsolated summary:\n")
print(causal_hydration_isolated_summary, row.names = FALSE)
cat("\nCoupled summary:\n")
print(causal_hydration_integrated_summary, row.names = FALSE)
