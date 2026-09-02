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

new_regime_calendar <- function(regime) {
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
    stop("Unknown prescribed evaporative-loss regime.")
  }
  calendar
}

forcing_calendars <- setNames(
  lapply(regime_names, new_regime_calendar),
  regime_names
)

summarize_regime_runs <- function(runs) {
  control <- runs$control
  do.call(rbind, lapply(regime_names, function(regime) {
    run <- runs[[regime]]
    completed_days <- attr(run, "completed_days")
    treatment_end <- min(treatment_days, completed_days)
    energy_debt_treatment_end_kj <- if (treatment_end == treatment_days) {
      control$closing_body_energy_reserve_kj[[treatment_days]] -
        run$closing_body_energy_reserve_kj[[treatment_days]]
    } else {
      NA_real_
    }
    energy_debt_recovery_end_kj <- if (completed_days == branch_days) {
      tail(control$closing_body_energy_reserve_kj, 1L) -
        tail(run$closing_body_energy_reserve_kj, 1L)
    } else {
      NA_real_
    }
    food_patch_switches <- if ("food_patch_action" %in% names(run)) {
      sum(run$food_patch_action == "move")
    } else {
      NA_integer_
    }
    control_food_patch_switches <- if (
      "food_patch_action" %in% names(control)
    ) {
      sum(control$food_patch_action == "move")
    } else {
      NA_integer_
    }
    water_visits <- sum(run$water_visit)
    control_water_visits <- sum(control$water_visit)

    data.frame(
      regime = regime,
      completed_days = completed_days,
      terminal_day = attr(run, "terminal_day"),
      forcing_days = sum(
        run$incremental_evaporative_water_loss_kg > 0
      ),
      incremental_evaporative_water_loss_kg = sum(
        run$incremental_evaporative_water_loss_kg
      ),
      water_visits = water_visits,
      additional_water_visits =
        water_visits - control_water_visits,
      water_source_travel_expenditure_kj = water_visits * 1800,
      additional_water_source_travel_expenditure_kj =
        (water_visits - control_water_visits) * 1800,
      food_patch_switches = food_patch_switches,
      additional_food_patch_switches =
        food_patch_switches - control_food_patch_switches,
      movement_expenditure_kj = sum(run$movement_expenditure_kj),
      additional_movement_expenditure_kj =
        sum(run$movement_expenditure_kj) -
          sum(control$movement_expenditure_kj),
      minimum_body_water_kg = min(run$closing_body_water_kg),
      minimum_body_energy_reserve_kj = min(
        run$closing_body_energy_reserve_kj
      ),
      energy_debt_treatment_end_kj = energy_debt_treatment_end_kj,
      energy_debt_recovery_end_kj = energy_debt_recovery_end_kj,
      energy_debt_recovered_kj =
        energy_debt_treatment_end_kj - energy_debt_recovery_end_kj,
      critical_water_crossed = any(run$body_water_below_critical),
      all_accounts_close = all(run$accounts_close),
      row.names = NULL
    )
  }))
}

isolated_precondition <- run_isolated_hydration_days(
  "common_baseline",
  precondition_days,
  water_visit_policy = "daily_opening"
)
isolated_context <- attr(isolated_precondition, "final_context")
isolated_runs <- setNames(lapply(regime_names, function(regime) {
  run_isolated_hydration_days(
    regime,
    branch_days,
    isolated_context,
    forcing_calendars[[regime]],
    water_visit_policy = "daily_opening"
  )
}), regime_names)
isolated_summary <- summarize_regime_runs(isolated_runs)

integrated_baseline_scenario <- data.frame(
  scenario = "common_baseline",
  scenario_role = "precondition",
  water_layer_active = TRUE,
  food_water_yield_kg_water_kg_dm = 3.28,
  daily_ordinary_water_loss_kg = 1.56,
  water_movement_expenditure_per_leg_kj = 900,
  stringsAsFactors = FALSE
)
integrated_precondition <- run_water_constrained_closed_loop(
  integrated_baseline_scenario,
  precondition_days,
  water_visit_policy = "daily_opening"
)
integrated_context <- attr(integrated_precondition, "final_context")
integrated_runs <- setNames(lapply(regime_names, function(regime) {
  scenario <- integrated_baseline_scenario
  scenario$scenario <- regime
  scenario$scenario_role <- "prescribed_evaporative_regime"
  run_water_constrained_closed_loop(
    scenario,
    branch_days,
    integrated_context,
    forcing_calendars[[regime]],
    water_visit_policy = "daily_opening"
  )
}), regime_names)
integrated_summary <- summarize_regime_runs(integrated_runs)

matched_dose_regimes <- c(
  "clustered",
  "repeated",
  "diffuse_dose_control"
)
matched_dose_kg <- event_increment_kg_day * 14
assert_that(
  near(
    vapply(
      forcing_calendars[matched_dose_regimes],
      sum,
      numeric(1L)
    ),
    rep(matched_dose_kg, length(matched_dose_regimes))
  ) &&
    all(forcing_calendars$control == 0) &&
    identical(
      vapply(
        forcing_calendars,
        function(calendar) sum(calendar > 0),
        integer(1L)
      ),
      c(
        control = 0L,
        clustered = 14L,
        repeated = 14L,
        diffuse_dose_control = 84L,
        sustained = 84L
      )
    ) &&
    all(forcing_calendars$sustained[seq_len(treatment_days)] ==
      event_increment_kg_day) &&
    all(vapply(
      forcing_calendars,
      function(calendar) all(calendar[(treatment_days + 1L):branch_days] == 0),
      logical(1L)
    )),
  "the five predeclared forcing calendars have the intended doses and recovery"
)
assert_that(
  attr(isolated_precondition, "completed_days") == precondition_days &&
    attr(integrated_precondition, "completed_days") == precondition_days &&
    all(isolated_precondition$accounts_close) &&
    all(integrated_precondition$accounts_close),
  "both systems complete one common 60-day precondition with closed accounts"
)
assert_that(
  all(isolated_summary$all_accounts_close) &&
    all(integrated_summary$all_accounts_close) &&
    near(
      isolated_summary$incremental_evaporative_water_loss_kg,
      vapply(forcing_calendars, sum, numeric(1L))
    ) &&
    near(
      integrated_summary$incremental_evaporative_water_loss_kg,
      vapply(forcing_calendars, sum, numeric(1L))
    ) &&
    isolated_summary$incremental_evaporative_water_loss_kg[
      isolated_summary$regime == "control"
    ] == 0 &&
    integrated_summary$incremental_evaporative_water_loss_kg[
      integrated_summary$regime == "control"
    ] == 0,
  paste0(
    "the branched treatments apply their exact doses, preserve separate ",
    "closed accounts, and retain an exact zero control"
  )
)

cat("Prescribed evaporative-loss regime diagnostic passed.\n")
cat("\nIsolated non-depleting forage system:\n")
print(transform(
  isolated_summary,
  incremental_evaporative_water_loss_kg =
    round(incremental_evaporative_water_loss_kg, 2),
  water_source_travel_expenditure_kj =
    round(water_source_travel_expenditure_kj),
  additional_water_source_travel_expenditure_kj =
    round(additional_water_source_travel_expenditure_kj),
  movement_expenditure_kj = round(movement_expenditure_kj),
  additional_movement_expenditure_kj =
    round(additional_movement_expenditure_kj),
  minimum_body_water_kg = round(minimum_body_water_kg, 2),
  minimum_body_energy_reserve_kj = round(minimum_body_energy_reserve_kj),
  energy_debt_treatment_end_kj = round(energy_debt_treatment_end_kj),
  energy_debt_recovery_end_kj = round(energy_debt_recovery_end_kj),
  energy_debt_recovered_kj = round(energy_debt_recovered_kj)
), row.names = FALSE)
cat("\nAccepted water-constrained patch system:\n")
print(transform(
  integrated_summary,
  incremental_evaporative_water_loss_kg =
    round(incremental_evaporative_water_loss_kg, 2),
  water_source_travel_expenditure_kj =
    round(water_source_travel_expenditure_kj),
  additional_water_source_travel_expenditure_kj =
    round(additional_water_source_travel_expenditure_kj),
  movement_expenditure_kj = round(movement_expenditure_kj),
  additional_movement_expenditure_kj =
    round(additional_movement_expenditure_kj),
  minimum_body_water_kg = round(minimum_body_water_kg, 2),
  minimum_body_energy_reserve_kj = round(minimum_body_energy_reserve_kj),
  energy_debt_treatment_end_kj = round(energy_debt_treatment_end_kj),
  energy_debt_recovery_end_kj = round(energy_debt_recovery_end_kj),
  energy_debt_recovered_kj = round(energy_debt_recovered_kj)
), row.names = FALSE)
