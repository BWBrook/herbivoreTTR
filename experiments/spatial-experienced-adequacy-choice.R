source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
patch_ids <- c("patch_a", "patch_b")
feeding_opportunity_h <- 16L
planning_horizon_days <- 2L
revisit_recovery_days <- 2L
expected_demand_kg_dm_h <- 0.020
maximum_acquisition_kg_dm_h <- 0.025
adequate_return_kj_feeding_opportunity_h <- 200
interaction_days <- 305L
herbivore_density_animals_ha <- 50
forage_equilibrium_biomass_kg_dm_ha <- 1000
residual_unavailable_forage_kg_dm_ha <- 500

scenarios <- data.frame(
  scenario = c(
    "baseline",
    "lower_movement_cost",
    "higher_movement_cost",
    "milder_quality_contrast",
    "equal_quality",
    "moderately_slower_forage_recovery",
    "faster_forage_recovery",
    "low_supply_stress"
  ),
  scenario_role = c(rep("acceptance", 7L), "stress"),
  patch_a_energy_density_kj_kg_dm = c(
    8000, 8000, 8000, 9000, 10000, 8000, 8000, 8000
  ),
  patch_b_energy_density_kj_kg_dm = rep(10000, 8L),
  movement_expenditure_kj = c(
    900, 600, 1200, 900, 900, 900, 900, 900
  ),
  forage_turnover_fraction_h = c(
    0.001, 0.001, 0.001, 0.001, 0.001, 0.0009, 0.00125,
    0.00075
  ),
  stringsAsFactors = FALSE
)

patch_biomass <- function(forage_state, patch_id) {
  forage_state$forage_biomass_kg_dm_ha[
    forage_state$patch_id == patch_id
  ]
}

new_landscape <- function(scenario) {
  herbivoreTTR::new_known_route_landscape(
    patch_id = patch_ids,
    forage_acquisition_ceiling_kg_dm_h = rep(
      maximum_acquisition_kg_dm_h,
      2L
    ),
    route_origin_patch_id = c("patch_a", "patch_b"),
    route_destination_patch_id = c("patch_b", "patch_a"),
    incremental_movement_expenditure_kj = rep(
      scenario$movement_expenditure_kj,
      2L
    ),
    metabolizable_energy_density_kj_kg_dm = c(
      scenario$patch_a_energy_density_kj_kg_dm,
      scenario$patch_b_energy_density_kj_kg_dm
    )
  )
}

accounts_close <- function(result) {
  max(abs(
    result$patch_hourly$forage_biomass_balance_residual_kg_dm_ha
  )) < 1e-10 &&
    max(abs(
      result$patch_daily$forage_biomass_balance_residual_kg_dm_ha
    )) < 1e-10 &&
    abs(result$daily$herbivore_forage_coupling_residual_kg_dm_ha) <
      1e-10 &&
    max(abs(result$hourly$system_energy_balance_residual_kj)) < 1e-8 &&
    abs(result$daily$system_energy_balance_residual_kj) < 1e-8
}

run_day <- function(
  opening_state,
  destination_patch_id,
  selected_action,
  coupling_parameters,
  landscape,
  turnover_parameters
) {
  closing_patch_id <- if (selected_action == "move") {
    destination_patch_id
  } else {
    opening_state$location$patch_id
  }

  herbivoreTTR::run_prescribed_spatial_coupled_energy_day(
    initial_location_state = opening_state$location,
    landscape = landscape,
    itinerary = herbivoreTTR::new_prescribed_patch_itinerary(
      fixture$hour_of_day,
      rep(closing_patch_id, 24L)
    ),
    initial_gut_state = opening_state$gut,
    initial_body_state = opening_state$body,
    initial_spatial_forage_state = opening_state$forage,
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    appetite_parameters = fixture$appetite,
    forage_turnover_parameters = turnover_parameters,
    coupling_parameters = coupling_parameters,
    appetite_reference_schedule = fixture$appetite_reference,
    routine_activity_schedule = fixture$activity
  )
}

recover_expected_return <- function(
  last_return_kj_feeding_opportunity_h,
  best_return_kj_feeding_opportunity_h,
  days_since_visit
) {
  recovery_fraction <- min(days_since_visit / revisit_recovery_days, 1)
  last_return_kj_feeding_opportunity_h +
    (
      best_return_kj_feeding_opportunity_h -
        last_return_kj_feeding_opportunity_h
    ) * recovery_fraction
}

compare_expected_returns <- function(
  opening_patch_id,
  destination_patch_id,
  expected_return_kj_feeding_opportunity_h,
  landscape
) {
  route_index <- which(
    landscape$routes$origin_patch_id == opening_patch_id &
      landscape$routes$destination_patch_id == destination_patch_id
  )
  travel_duration_h <- landscape$routes$travel_duration_h[[route_index]]
  movement_expenditure_kj <- landscape$routes$
    incremental_movement_expenditure_kj[[route_index]]
  stay_score_kj <-
    expected_return_kj_feeding_opportunity_h[[opening_patch_id]] *
      feeding_opportunity_h * planning_horizon_days
  move_score_kj <-
    expected_return_kj_feeding_opportunity_h[[destination_patch_id]] *
      (
        feeding_opportunity_h * planning_horizon_days -
          travel_duration_h
      ) -
      movement_expenditure_kj
  tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(c(stay_score_kj, move_score_kj))
  )

  list(
    selected_action = if (move_score_kj > stay_score_kj + tolerance_kj) {
      "move"
    } else {
      "stay"
    },
    move_score_advantage_kj = move_score_kj - stay_score_kj
  )
}

choose_action <- function(
  decision_rule,
  opening_patch_id,
  destination_patch_id,
  expected_return_kj_feeding_opportunity_h,
  landscape,
  accumulated_inadequacy_kj = 0
) {
  comparison <- compare_expected_returns(
    opening_patch_id,
    destination_patch_id,
    expected_return_kj_feeding_opportunity_h,
    landscape
  )
  current_return_kj_feeding_opportunity_h <-
    expected_return_kj_feeding_opportunity_h[[opening_patch_id]]
  tolerance_kj_h <- 100 * .Machine$double.eps * max(
    1,
    abs(current_return_kj_feeding_opportunity_h),
    adequate_return_kj_feeding_opportunity_h
  )
  current_return_is_adequate <-
    current_return_kj_feeding_opportunity_h + tolerance_kj_h >=
      adequate_return_kj_feeding_opportunity_h
  selected_action <- comparison$selected_action
  decision_reason <- if (selected_action == "move") {
    "destination_repays_route"
  } else {
    "destination_does_not_repay_route"
  }

  if (
    decision_rule == "experienced_adequacy_memory" &&
      current_return_is_adequate
  ) {
    selected_action <- "stay"
    decision_reason <- "current_return_is_adequate"
  }
  if (
    decision_rule == "experienced_adequacy_memory" &&
      !current_return_is_adequate
  ) {
    deficit_adjusted_advantage_kj <-
      comparison$move_score_advantage_kj + accumulated_inadequacy_kj
    tolerance_kj <- 100 * .Machine$double.eps * max(
      1,
      abs(c(
        comparison$move_score_advantage_kj,
        accumulated_inadequacy_kj
      ))
    )
    if (deficit_adjusted_advantage_kj > tolerance_kj) {
      selected_action <- "move"
      decision_reason <- "persistent_deficit_repays_route"
    } else {
      selected_action <- "stay"
      decision_reason <- "persistent_deficit_does_not_repay_route"
    }
  }

  list(
    selected_action = selected_action,
    raw_comparison_action = comparison$selected_action,
    move_score_advantage_kj = comparison$move_score_advantage_kj,
    deficit_adjusted_move_score_advantage_kj =
      comparison$move_score_advantage_kj + accumulated_inadequacy_kj,
    current_return_is_adequate = current_return_is_adequate,
    decision_reason = decision_reason
  )
}

run_closed_loop <- function(
  scenario,
  decision_rule = c(
    "revisit_clock",
    "experienced_adequacy_memory"
  ),
  maximum_days = interaction_days,
  checkpoint_days = integer()
) {
  decision_rule <- match.arg(decision_rule)
  landscape <- new_landscape(scenario)
  turnover <- herbivoreTTR::new_forage_turnover_parameters(
    forage_equilibrium_biomass_kg_dm_ha,
    scenario$forage_turnover_fraction_h
  )
  coupling <- herbivoreTTR::new_nonspatial_coupling_parameters(
    herbivore_density_animals_ha,
    residual_unavailable_forage_kg_dm_ha
  )
  energy_densities_kj_kg_dm <- c(
    scenario$patch_a_energy_density_kj_kg_dm,
    scenario$patch_b_energy_density_kj_kg_dm
  )
  names(energy_densities_kj_kg_dm) <- patch_ids
  state <- list(
    location = herbivoreTTR::new_patch_location_state("patch_a"),
    gut = fixture$opening_gut,
    body = fixture$opening_body,
    forage = herbivoreTTR::new_spatial_forage_biomass_state(
      patch_ids,
      rep(forage_equilibrium_biomass_kg_dm_ha, 2L)
    )
  )
  remembered_return_kj_feeding_opportunity_h <-
    expected_demand_kg_dm_h * energy_densities_kj_kg_dm
  best_return_kj_feeding_opportunity_h <-
    maximum_acquisition_kg_dm_h * energy_densities_kj_kg_dm
  days_since_visit <- setNames(rep(0L, 2L), patch_ids)
  accumulated_inadequacy_kj <- 0
  daily_rows <- vector("list", maximum_days)
  checkpoint_states <- list()
  completed_days <- 0L
  terminal_day <- NA_integer_
  terminal_reason <- NA_character_

  for (simulation_day in seq_len(maximum_days)) {
    opening_patch_id <- state$location$patch_id
    destination_patch_id <- setdiff(patch_ids, opening_patch_id)
    remembered_return_opening <-
      remembered_return_kj_feeding_opportunity_h
    best_return_opening <- best_return_kj_feeding_opportunity_h
    days_since_visit_opening <- days_since_visit
    accumulated_inadequacy_opening_kj <- accumulated_inadequacy_kj
    expected_return_opening <- remembered_return_opening
    expected_return_opening[[destination_patch_id]] <-
      recover_expected_return(
        remembered_return_opening[[destination_patch_id]],
        best_return_opening[[destination_patch_id]],
        days_since_visit_opening[[destination_patch_id]]
      )
    decision <- choose_action(
      decision_rule,
      opening_patch_id,
      destination_patch_id,
      expected_return_opening,
      landscape,
      accumulated_inadequacy_opening_kj
    )
    if (simulation_day %in% checkpoint_days) {
      checkpoint_states[[as.character(simulation_day)]] <- list(
        opening_state = state,
        destination_patch_id = destination_patch_id,
        remembered_return_kj_feeding_opportunity_h =
          remembered_return_opening,
        best_return_kj_feeding_opportunity_h = best_return_opening,
        days_since_visit = days_since_visit_opening,
        accumulated_inadequacy_kj =
          accumulated_inadequacy_opening_kj,
        expected_return_kj_feeding_opportunity_h =
          expected_return_opening,
        decision = decision
      )
    }
    selected_error <- NULL
    selected <- tryCatch(
      run_day(
        state,
        destination_patch_id,
        decision$selected_action,
        coupling,
        landscape,
        turnover
      ),
      error = function(error) {
        if (conditionMessage(error) !=
          "The proposed closing body-energy reserve is negative.") stop(error)
        selected_error <<- conditionMessage(error)
        NULL
      }
    )
    if (is.null(selected)) {
      terminal_day <- simulation_day
      terminal_reason <- selected_error
      break
    }
    feeding_opportunity_hours <- sum(
      selected$hourly$feeding_opportunity_open
    )
    experienced_return_kj_feeding_opportunity_h <-
      selected$daily$total_realized_ingested_available_energy_kj /
        feeding_opportunity_hours
    closing_patch_id <- selected$final_state$location$patch_id
    remembered_return_kj_feeding_opportunity_h[[closing_patch_id]] <-
      experienced_return_kj_feeding_opportunity_h
    best_return_kj_feeding_opportunity_h[[closing_patch_id]] <- max(
      best_return_kj_feeding_opportunity_h[[closing_patch_id]],
      experienced_return_kj_feeding_opportunity_h
    )
    days_since_visit <- days_since_visit + 1L
    days_since_visit[[closing_patch_id]] <- 0L
    if (decision$selected_action == "move") {
      accumulated_inadequacy_kj <- 0
    }
    realized_inadequacy_kj <- max(
      adequate_return_kj_feeding_opportunity_h -
        experienced_return_kj_feeding_opportunity_h,
      0
    ) * feeding_opportunity_hours
    if (realized_inadequacy_kj > 0) {
      accumulated_inadequacy_kj <-
        accumulated_inadequacy_kj + realized_inadequacy_kj
    } else {
      accumulated_inadequacy_kj <- 0
    }

    daily_rows[[simulation_day]] <- data.frame(
      scenario = scenario$scenario,
      scenario_role = scenario$scenario_role,
      decision_rule = decision_rule,
      simulation_day = simulation_day,
      opening_patch_id = opening_patch_id,
      destination_patch_id = destination_patch_id,
      closing_patch_id = closing_patch_id,
      selected_action = decision$selected_action,
      raw_comparison_action = decision$raw_comparison_action,
      decision_reason = decision$decision_reason,
      current_return_is_adequate =
        decision$current_return_is_adequate,
      remembered_current_return_opening_kj_feeding_opportunity_h =
        remembered_return_opening[[opening_patch_id]],
      expected_destination_return_opening_kj_feeding_opportunity_h =
        expected_return_opening[[destination_patch_id]],
      destination_days_since_visit_opening =
        days_since_visit_opening[[destination_patch_id]],
      accumulated_inadequacy_opening_kj =
        accumulated_inadequacy_opening_kj,
      move_score_advantage_kj = decision$move_score_advantage_kj,
      deficit_adjusted_move_score_advantage_kj =
        decision$deficit_adjusted_move_score_advantage_kj,
      experienced_return_kj_feeding_opportunity_h =
        experienced_return_kj_feeding_opportunity_h,
      realized_intake_kg_dm =
        selected$daily$realized_dry_matter_intake_kg_dm,
      realized_ingested_energy_kj =
        selected$daily$total_realized_ingested_available_energy_kj,
      movement_expenditure_kj =
        selected$daily$total_incremental_movement_expenditure_kj,
      body_energy_reserve_final_kj =
        selected$daily$body_energy_reserve_final_kj,
      patch_a_biomass_final_kg_dm_ha = patch_biomass(
        selected$final_state$forage,
        "patch_a"
      ),
      patch_b_biomass_final_kg_dm_ha = patch_biomass(
        selected$final_state$forage,
        "patch_b"
      ),
      accounts_close = accounts_close(selected),
      row.names = NULL
    )
    state <- selected$final_state
    completed_days <- simulation_day
  }

  result <- do.call(rbind, daily_rows[seq_len(completed_days)])
  attr(result, "checkpoint_states") <- checkpoint_states
  attr(result, "completed_days") <- completed_days
  attr(result, "terminal_day") <- terminal_day
  attr(result, "terminal_reason") <- terminal_reason
  result
}

summarize_run <- function(run) {
  move_days <- run$simulation_day[run$selected_action == "move"]
  return_intervals_days <- if (length(move_days) > 1L) {
    diff(move_days)
  } else {
    NA_integer_
  }

  data.frame(
    scenario = run$scenario[[1L]],
    scenario_role = run$scenario_role[[1L]],
    decision_rule = run$decision_rule[[1L]],
    completed_days = attr(run, "completed_days"),
    terminal_day = attr(run, "terminal_day"),
    switches = length(move_days),
    shortest_return_interval_days = if (all(is.na(return_intervals_days))) {
      NA_integer_
    } else {
      min(return_intervals_days)
    },
    movement_expenditure_kj = sum(run$movement_expenditure_kj),
    minimum_body_reserve_kj = min(run$body_energy_reserve_final_kj),
    closing_body_reserve_kj = tail(run$body_energy_reserve_final_kj, 1L),
    days_in_patch_a = sum(run$closing_patch_id == "patch_a"),
    days_in_patch_b = sum(run$closing_patch_id == "patch_b"),
    adequacy_overrides = sum(
      run$current_return_is_adequate &
        run$raw_comparison_action == "move"
    ),
    all_accounts_close = all(run$accounts_close),
    row.names = NULL
  )
}

baseline_scenario <- scenarios[scenarios$scenario == "baseline", , drop = FALSE]
revisit_clock <- run_closed_loop(
  baseline_scenario,
  "revisit_clock",
  checkpoint_days = c(60L, 62L)
)
robustness_runs <- lapply(seq_len(nrow(scenarios)), function(index) {
  run_closed_loop(
    scenarios[index, , drop = FALSE],
    "experienced_adequacy_memory"
  )
})
names(robustness_runs) <- scenarios$scenario
baseline_adequacy_memory <- robustness_runs$baseline

baseline_summary <- rbind(
  summarize_run(revisit_clock),
  summarize_run(baseline_adequacy_memory)
)
robustness_summary <- do.call(rbind, lapply(
  robustness_runs,
  summarize_run
))
row.names(robustness_summary) <- NULL
acceptance_summary <- robustness_summary[
  robustness_summary$scenario_role == "acceptance",
  ,
  drop = FALSE
]
stress_summary <- robustness_summary[
  robustness_summary$scenario_role == "stress",
  ,
  drop = FALSE
]
supply_summary <- transform(
  scenarios,
  residual_energy_supply_kj_animal_day =
    24 *
      (
        forage_equilibrium_biomass_kg_dm_ha -
          residual_unavailable_forage_kg_dm_ha
      ) *
      forage_turnover_fraction_h /
      herbivore_density_animals_ha *
      (
        patch_a_energy_density_kj_kg_dm +
          patch_b_energy_density_kj_kg_dm
      )
)
supply_summary$movement_free_margin_kj_animal_day <-
  supply_summary$residual_energy_supply_kj_animal_day -
    adequate_return_kj_feeding_opportunity_h * feeding_opportunity_h

clock_checkpoints <- attr(revisit_clock, "checkpoint_states")
checkpoint_table <- do.call(rbind, lapply(c(60L, 62L), function(day) {
  checkpoint <- clock_checkpoints[[as.character(day)]]
  adequacy_memory_decision <- choose_action(
    "experienced_adequacy_memory",
    checkpoint$opening_state$location$patch_id,
    checkpoint$destination_patch_id,
    checkpoint$expected_return_kj_feeding_opportunity_h,
    new_landscape(baseline_scenario),
    checkpoint$accumulated_inadequacy_kj
  )
  data.frame(
    checkpoint_day = day,
    opening_patch_id = checkpoint$opening_state$location$patch_id,
    destination_patch_id = checkpoint$destination_patch_id,
    current_return_kj_feeding_opportunity_h =
      checkpoint$expected_return_kj_feeding_opportunity_h[[
        checkpoint$opening_state$location$patch_id
      ]],
    destination_return_kj_feeding_opportunity_h =
      checkpoint$expected_return_kj_feeding_opportunity_h[[
        checkpoint$destination_patch_id
      ]],
    current_return_is_adequate =
      adequacy_memory_decision$current_return_is_adequate,
    destination_days_since_visit =
      checkpoint$days_since_visit[[checkpoint$destination_patch_id]],
    accumulated_inadequacy_kj =
      checkpoint$accumulated_inadequacy_kj,
    raw_comparison_action =
      adequacy_memory_decision$raw_comparison_action,
    adequacy_memory_action = adequacy_memory_decision$selected_action,
    move_score_advantage_kj =
      adequacy_memory_decision$move_score_advantage_kj,
    deficit_adjusted_move_score_advantage_kj =
      adequacy_memory_decision$deficit_adjusted_move_score_advantage_kj,
    row.names = NULL
  )
}))

clock_move_days <- revisit_clock$simulation_day[
  revisit_clock$selected_action == "move"
]
adequacy_memory_move_days <- baseline_adequacy_memory$simulation_day[
  baseline_adequacy_memory$selected_action == "move"
]

assert_that(
  identical(clock_move_days[seq_len(3L)], c(1L, 60L, 62L)) &&
    nrow(revisit_clock) == interaction_days &&
    all(revisit_clock$accounts_close),
  "the narrow revisit-clock control reproduces its first reciprocal cycle"
)
assert_that(
  identical(checkpoint_table$raw_comparison_action, c("move", "move")) &&
    identical(checkpoint_table$current_return_is_adequate, c(FALSE, TRUE)) &&
    identical(
      checkpoint_table$adequacy_memory_action,
      c("move", "stay")
    ),
  "experience retains the day-60 departure and rejects day-62 return"
)
assert_that(
  nrow(baseline_adequacy_memory) == interaction_days &&
    all(baseline_adequacy_memory$accounts_close) &&
    length(adequacy_memory_move_days) >= 4L &&
    length(adequacy_memory_move_days) < length(clock_move_days) / 4 &&
    min(diff(adequacy_memory_move_days)) >= 7L &&
    sum(baseline_adequacy_memory$movement_expenditure_kj) <
      sum(revisit_clock$movement_expenditure_kj) / 4 &&
    min(baseline_adequacy_memory$body_energy_reserve_final_kj) > 30000,
  "adequacy memory removes rapid rotation and deep reserve loss"
)
assert_that(
  all(acceptance_summary$completed_days == interaction_days) &&
    all(acceptance_summary$all_accounts_close) &&
    all(acceptance_summary$switches >= 4L) &&
    all(acceptance_summary$shortest_return_interval_days >= 7L) &&
    all(acceptance_summary$minimum_body_reserve_kj > 35000),
  "the accepted behavior remains interpretable across the bounded robustness set"
)
stress_supply_margin_kj_day <- supply_summary$
  movement_free_margin_kj_animal_day[
    supply_summary$scenario_role == "stress"
  ]
assert_that(
  nrow(stress_summary) == 1L &&
    stress_summary$completed_days < interaction_days &&
    stress_summary$all_accounts_close &&
    stress_summary$shortest_return_interval_days == 4L &&
    near(stress_supply_margin_kj_day, 40) &&
    stress_supply_margin_kj_day <
      scenarios$movement_expenditure_kj[
        scenarios$scenario_role == "stress"
      ] /
        stress_summary$shortest_return_interval_days,
  "the low-supply stress failure is energetically explicit rather than hidden"
)

cat("Experienced-adequacy-memory checkpoint decisions:\n")
print(transform(
  checkpoint_table,
  current_return_kj_feeding_opportunity_h = round(
    current_return_kj_feeding_opportunity_h
  ),
  destination_return_kj_feeding_opportunity_h = round(
    destination_return_kj_feeding_opportunity_h
  ),
  move_score_advantage_kj = round(move_score_advantage_kj),
  deficit_adjusted_move_score_advantage_kj = round(
    deficit_adjusted_move_score_advantage_kj
  ),
  accumulated_inadequacy_kj = round(accumulated_inadequacy_kj)
), row.names = FALSE)
cat("\nBaseline comparison:\n")
print(transform(
  baseline_summary,
  movement_expenditure_kj = round(movement_expenditure_kj),
  minimum_body_reserve_kj = round(minimum_body_reserve_kj),
  closing_body_reserve_kj = round(closing_body_reserve_kj)
), row.names = FALSE)
cat("\nBounded robustness summary:\n")
print(transform(
  robustness_summary,
  movement_expenditure_kj = round(movement_expenditure_kj),
  minimum_body_reserve_kj = round(minimum_body_reserve_kj),
  closing_body_reserve_kj = round(closing_body_reserve_kj)
), row.names = FALSE)
cat("\nResidual-boundary energy supply:\n")
print(transform(
  supply_summary[, c(
    "scenario",
    "scenario_role",
    "residual_energy_supply_kj_animal_day",
    "movement_free_margin_kj_animal_day"
  )],
  residual_energy_supply_kj_animal_day = round(
    residual_energy_supply_kj_animal_day
  ),
  movement_free_margin_kj_animal_day = round(
    movement_free_margin_kj_animal_day
  )
), row.names = FALSE)
