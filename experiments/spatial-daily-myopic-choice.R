source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
patch_ids <- c("patch_a", "patch_b")
static_acquisition_capacity_kg_dm_h <- 0.025
destination_expected_acquisition_rate_kg_dm_h <- 0.025
expected_demand_kg_dm_h <- 0.020
remaining_feeding_opportunity_h <- 16L
recovery_planning_horizon_days <- 2L
revisit_recovery_days <- 2L
consequence_horizon_days <- c(1L, 2L, 4L, 7L, 14L)
consequence_checkpoint_days <- c(60L, 62L)
reference_days <- 120L
interaction_days <- 305L
adequate_energy_density_kj_kg_dm <- 10000
lower_energy_density_kj_kg_dm <- 8000

new_landscape <- function(
  acquisition_rates_kg_dm_h,
  energy_densities_kj_kg_dm
) {
  herbivoreTTR::new_known_route_landscape(
    patch_id = patch_ids,
    forage_acquisition_ceiling_kg_dm_h = acquisition_rates_kg_dm_h,
    route_origin_patch_id = c("patch_a", "patch_b"),
    route_destination_patch_id = c("patch_b", "patch_a"),
    incremental_movement_expenditure_kj = c(900, 900),
    metabolizable_energy_density_kj_kg_dm = energy_densities_kj_kg_dm
  )
}
turnover <- herbivoreTTR::new_forage_turnover_parameters(1000, 0.001)

patch_biomass <- function(forage_state, patch_id) {
  forage_state$forage_biomass_kg_dm_ha[
    forage_state$patch_id == patch_id
  ]
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

run_candidate <- function(
  opening_state,
  destination_patch_id,
  action,
  coupling_parameters,
  landscape
) {
  closing_patch_id <- if (action == "move") {
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
    forage_turnover_parameters = turnover,
    coupling_parameters = coupling_parameters,
    appetite_reference_schedule = fixture$appetite_reference,
    routine_activity_schedule = fixture$activity
  )
}

make_myopic_decision <- function(
  opening_state,
  destination_patch_id,
  coupling_parameters,
  landscape
) {
  current_patch_id <- opening_state$location$patch_id
  current_index <- match(current_patch_id, patch_ids)
  current_biomass_kg_dm_ha <- patch_biomass(
    opening_state$forage,
    current_patch_id
  )
  accessible_biomass_kg_dm_ha <-
    herbivoreTTR::derive_accessible_forage_biomass(
      current_biomass_kg_dm_ha,
      coupling_parameters$
        residual_unavailable_forage_threshold_kg_dm_ha
    )$accessible_forage_biomass_kg_dm_ha
  current_cue_rate_kg_dm_h <- min(
    landscape$patches$
      forage_acquisition_ceiling_kg_dm_h[[current_index]],
    accessible_biomass_kg_dm_ha /
      coupling_parameters$herbivore_density_animals_ha
  )
  cue_rates_kg_dm_h <- rep(
    destination_expected_acquisition_rate_kg_dm_h,
    2L
  )
  cue_rates_kg_dm_h[[current_index]] <- current_cue_rate_kg_dm_h
  cue_landscape <- landscape
  cue_landscape$patches$forage_acquisition_ceiling_kg_dm_h <-
    cue_rates_kg_dm_h
  decision <- herbivoreTTR::choose_known_patch_for_feeding_bout(
    state = opening_state$location,
    landscape = cue_landscape,
    destination_patch_id = destination_patch_id,
    expected_dry_matter_demand_kg_dm_h = expected_demand_kg_dm_h,
    remaining_feeding_opportunity_h = remaining_feeding_opportunity_h
  )

  list(
    decision = decision,
    current_cue_rate_kg_dm_h = current_cue_rate_kg_dm_h
  )
}

make_experienced_return_decision <- function(
  opening_state,
  destination_patch_id,
  remembered_return_kj_feeding_opportunity_h,
  landscape,
  planning_horizon_days = 1L
) {
  current_patch_id <- opening_state$location$patch_id
  route_index <- which(
    landscape$routes$origin_patch_id == current_patch_id &
      landscape$routes$destination_patch_id == destination_patch_id
  )
  travel_duration_h <- landscape$routes$travel_duration_h[[route_index]]
  movement_expenditure_kj <- landscape$routes$
    incremental_movement_expenditure_kj[[route_index]]
  stay_score_kj <-
    remembered_return_kj_feeding_opportunity_h[[current_patch_id]] *
      remaining_feeding_opportunity_h * planning_horizon_days
  move_score_kj <-
    remembered_return_kj_feeding_opportunity_h[[destination_patch_id]] *
      (
        remaining_feeding_opportunity_h * planning_horizon_days -
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

recover_expected_return <- function(
  last_return_kj_feeding_opportunity_h,
  best_return_kj_feeding_opportunity_h,
  days_since_visit
) {
  hourly_retention <- 1 - turnover$forage_turnover_fraction_h
  best_return_kj_feeding_opportunity_h -
    (
      best_return_kj_feeding_opportunity_h -
        last_return_kj_feeding_opportunity_h
    ) * hourly_retention^(24 * days_since_visit)
}

recover_expected_return_by_revisit_clock <- function(
  last_return_kj_feeding_opportunity_h,
  best_return_kj_feeding_opportunity_h,
  days_since_visit
) {
  recovery_fraction <- min(
    days_since_visit / revisit_recovery_days,
    1
  )
  last_return_kj_feeding_opportunity_h +
    (
      best_return_kj_feeding_opportunity_h -
        last_return_kj_feeding_opportunity_h
    ) * recovery_fraction
}

run_candidate_safely <- function(...) {
  tryCatch(
    run_candidate(...),
    error = function(error) {
      if (!identical(
        conditionMessage(error),
        "The proposed closing body-energy reserve is negative."
      )) {
        stop(error)
      }
      NULL
    }
  )
}

run_candidate_horizon_safely <- function(
  opening_state,
  destination_patch_id,
  action,
  coupling_parameters,
  landscape,
  horizon_days
) {
  policy_state <- opening_state
  day_results <- vector("list", horizon_days)

  for (policy_day in seq_len(horizon_days)) {
    day_action <- if (policy_day == 1L) action else "stay"
    day_destination_patch_id <- if (policy_day == 1L) {
      destination_patch_id
    } else {
      setdiff(patch_ids, policy_state$location$patch_id)
    }
    day_result <- run_candidate_safely(
      policy_state,
      day_destination_patch_id,
      day_action,
      coupling_parameters,
      landscape
    )
    if (is.null(day_result)) {
      return(NULL)
    }
    day_results[[policy_day]] <- day_result
    policy_state <- day_result$final_state
  }

  list(
    final_total_system_energy_kj = tail(
      day_results,
      1L
    )[[1L]]$daily$total_system_energy_final_kj,
    realized_intake_kg_dm = sum(vapply(
      day_results,
      function(result) result$daily$realized_dry_matter_intake_kg_dm,
      numeric(1L)
    )),
    ingested_energy_kj = sum(vapply(
      day_results,
      function(result) {
        result$daily$total_realized_ingested_available_energy_kj
      },
      numeric(1L)
    )),
    movement_expenditure_kj = sum(vapply(
      day_results,
      function(result) {
        result$daily$total_incremental_movement_expenditure_kj
      },
      numeric(1L)
    )),
    final_body_energy_reserve_kj = tail(
      day_results,
      1L
    )[[1L]]$daily$body_energy_reserve_final_kj,
    final_patch_a_biomass_kg_dm_ha = patch_biomass(
      policy_state$forage,
      "patch_a"
    ),
    final_patch_b_biomass_kg_dm_ha = patch_biomass(
      policy_state$forage,
      "patch_b"
    ),
    all_accounts_close = all(vapply(
      day_results,
      accounts_close,
      logical(1L)
    ))
  )
}

run_closed_loop <- function(
  treatment,
  density_animals_ha,
  maximum_days,
  energy_densities_kj_kg_dm,
  decision_rule = c(
    "operational_null",
    "experienced_return_memory",
    "recovery_aware_memory",
    "revisit_clock_memory"
  ),
  checkpoint_days = integer()
) {
  decision_rule <- match.arg(decision_rule)
  uses_recovery_memory <- decision_rule %in% c(
    "recovery_aware_memory",
    "revisit_clock_memory"
  )
  landscape <- new_landscape(
    rep(static_acquisition_capacity_kg_dm_h, 2L),
    energy_densities_kj_kg_dm
  )
  coupling <- herbivoreTTR::new_nonspatial_coupling_parameters(
    density_animals_ha,
    500
  )
  state <- list(
    location = herbivoreTTR::new_patch_location_state("patch_a"),
    gut = fixture$opening_gut,
    body = fixture$opening_body,
    forage = herbivoreTTR::new_spatial_forage_biomass_state(
      patch_ids,
      c(1000, 1000)
    )
  )
  daily_rows <- vector("list", maximum_days)
  remembered_return_kj_feeding_opportunity_h <-
    expected_demand_kg_dm_h * energy_densities_kj_kg_dm
  names(remembered_return_kj_feeding_opportunity_h) <- patch_ids
  best_return_kj_feeding_opportunity_h <-
    fixture$appetite$maximum_dry_matter_intake_kg_dm_h *
      energy_densities_kj_kg_dm
  names(best_return_kj_feeding_opportunity_h) <- patch_ids
  days_since_visit <- setNames(rep(0L, length(patch_ids)), patch_ids)
  completed_days <- 0L
  terminal_day <- NA_integer_
  terminal_reason <- NA_character_
  checkpoint_states <- list()

  for (simulation_day in seq_len(maximum_days)) {
    opening_patch_id <- state$location$patch_id
    destination_patch_id <- setdiff(patch_ids, opening_patch_id)
    if (simulation_day %in% checkpoint_days) {
      checkpoint_states[[as.character(simulation_day)]] <- list(
        opening_state = state,
        destination_patch_id = destination_patch_id
      )
    }
    opening_current_biomass_kg_dm_ha <- patch_biomass(
      state$forage,
      opening_patch_id
    )
    opening_destination_biomass_kg_dm_ha <- patch_biomass(
      state$forage,
      destination_patch_id
    )
    remembered_return_opening <-
      remembered_return_kj_feeding_opportunity_h
    best_return_opening <- best_return_kj_feeding_opportunity_h
    days_since_visit_opening <- days_since_visit
    expected_return_opening <- remembered_return_opening
    if (decision_rule == "recovery_aware_memory") {
      expected_return_opening[[destination_patch_id]] <-
        recover_expected_return(
          remembered_return_opening[[destination_patch_id]],
          best_return_opening[[destination_patch_id]],
          days_since_visit_opening[[destination_patch_id]]
        )
    } else if (decision_rule == "revisit_clock_memory") {
      expected_return_opening[[destination_patch_id]] <-
        recover_expected_return_by_revisit_clock(
          remembered_return_opening[[destination_patch_id]],
          best_return_opening[[destination_patch_id]],
          days_since_visit_opening[[destination_patch_id]]
        )
    }
    myopic <- if (decision_rule == "operational_null") {
      make_myopic_decision(
        state,
        destination_patch_id,
        coupling,
        landscape
      )
    } else {
      list(
        decision = make_experienced_return_decision(
          state,
          destination_patch_id,
          if (uses_recovery_memory) {
            expected_return_opening
          } else {
            remembered_return_opening
          },
          landscape,
          planning_horizon_days = if (
            uses_recovery_memory
          ) {
            recovery_planning_horizon_days
          } else {
            1L
          }
        ),
        current_cue_rate_kg_dm_h = NA_real_
      )
    }
    counterfactuals <- list(
      stay = run_candidate_safely(
        state,
        destination_patch_id,
        "stay",
        coupling,
        landscape
      ),
      move = run_candidate_safely(
        state,
        destination_patch_id,
        "move",
        coupling,
        landscape
      )
    )
    valid_counterfactual <- !vapply(
      counterfactuals,
      is.null,
      logical(1L)
    )
    if (!any(valid_counterfactual)) {
      terminal_day <- simulation_day
      terminal_reason <- "no action preserves a non-negative body reserve"
      break
    }
    full_scores_kj <- setNames(rep(-Inf, 2L), names(counterfactuals))
    full_scores_kj[valid_counterfactual] <- vapply(
      counterfactuals[valid_counterfactual],
      function(result) result$daily$total_system_energy_final_kj,
      numeric(1L)
    )
    tolerance_kj <- 100 * .Machine$double.eps * max(
      1,
      abs(full_scores_kj[is.finite(full_scores_kj)])
    )
    oracle_choice <- if (!valid_counterfactual[["stay"]]) {
      "move"
    } else if (
      valid_counterfactual[["move"]] &&
        full_scores_kj[["move"]] > full_scores_kj[["stay"]] +
          tolerance_kj
    ) {
      "move"
    } else {
      "stay"
    }
    myopic_choice <- myopic$decision$selected_action
    selected <- counterfactuals[[myopic_choice]]
    if (is.null(selected)) {
      terminal_day <- simulation_day
      terminal_reason <- paste0(
        "the selected ",
        myopic_choice,
        " action would make body reserve negative"
      )
      break
    }
    realized_regret_kj <-
      full_scores_kj[[oracle_choice]] - full_scores_kj[[myopic_choice]]
    if (abs(realized_regret_kj) <= tolerance_kj) {
      realized_regret_kj <- 0
    }
    two_day_oracle_choice <- NA_character_
    two_day_oracle_move_score_advantage_kj <- NA_real_
    two_day_oracle_regret_kj <- NA_real_
    all_two_day_counterfactual_accounts_close <- NA
    if (uses_recovery_memory) {
      two_day_counterfactuals <- list(
        stay = run_candidate_horizon_safely(
          state,
          destination_patch_id,
          "stay",
          coupling,
          landscape,
          recovery_planning_horizon_days
        ),
        move = run_candidate_horizon_safely(
          state,
          destination_patch_id,
          "move",
          coupling,
          landscape,
          recovery_planning_horizon_days
        )
      )
      valid_two_day_counterfactual <- !vapply(
        two_day_counterfactuals,
        is.null,
        logical(1L)
      )
      if (any(valid_two_day_counterfactual)) {
        two_day_scores_kj <- setNames(
          rep(-Inf, 2L),
          names(two_day_counterfactuals)
        )
        two_day_scores_kj[valid_two_day_counterfactual] <- vapply(
          two_day_counterfactuals[valid_two_day_counterfactual],
          function(result) result$final_total_system_energy_kj,
          numeric(1L)
        )
        two_day_tolerance_kj <- 100 * .Machine$double.eps * max(
          1,
          abs(two_day_scores_kj[is.finite(two_day_scores_kj)])
        )
        two_day_oracle_choice <- if (
          !valid_two_day_counterfactual[["stay"]]
        ) {
          "move"
        } else if (
          valid_two_day_counterfactual[["move"]] &&
            two_day_scores_kj[["move"]] >
              two_day_scores_kj[["stay"]] + two_day_tolerance_kj
        ) {
          "move"
        } else {
          "stay"
        }
        two_day_oracle_move_score_advantage_kj <-
          two_day_scores_kj[["move"]] - two_day_scores_kj[["stay"]]
        two_day_oracle_regret_kj <-
          two_day_scores_kj[[two_day_oracle_choice]] -
            two_day_scores_kj[[myopic_choice]]
        if (abs(two_day_oracle_regret_kj) <= two_day_tolerance_kj) {
          two_day_oracle_regret_kj <- 0
        }
        all_two_day_counterfactual_accounts_close <- all(vapply(
          two_day_counterfactuals[valid_two_day_counterfactual],
          function(result) result$all_accounts_close,
          logical(1L)
        ))
      }
    }
    final_forage <- selected$final_state$forage
    feeding_opportunity_h <- sum(selected$hourly$feeding_opportunity_open)
    experienced_return_kj_feeding_opportunity_h <-
      selected$daily$total_realized_ingested_available_energy_kj /
        feeding_opportunity_h
    if (decision_rule != "operational_null") {
      foraging_patch_id <- selected$final_state$location$patch_id
      remembered_return_kj_feeding_opportunity_h[[foraging_patch_id]] <-
        experienced_return_kj_feeding_opportunity_h
      best_return_kj_feeding_opportunity_h[[foraging_patch_id]] <- max(
        best_return_kj_feeding_opportunity_h[[foraging_patch_id]],
        experienced_return_kj_feeding_opportunity_h
      )
      days_since_visit <- days_since_visit + 1L
      days_since_visit[[foraging_patch_id]] <- 0L
    }

    daily_rows[[simulation_day]] <- data.frame(
      treatment = treatment,
      decision_rule = decision_rule,
      density_animals_ha = density_animals_ha,
      simulation_day = simulation_day,
      opening_patch_id = opening_patch_id,
      destination_patch_id = destination_patch_id,
      closing_patch_id = selected$final_state$location$patch_id,
      opening_current_biomass_kg_dm_ha =
        opening_current_biomass_kg_dm_ha,
      opening_destination_biomass_kg_dm_ha =
        opening_destination_biomass_kg_dm_ha,
      current_energy_density_kj_kg_dm = landscape$patches$
        metabolizable_energy_density_kj_kg_dm[[
          match(opening_patch_id, patch_ids)
        ]],
      destination_energy_density_kj_kg_dm = landscape$patches$
        metabolizable_energy_density_kj_kg_dm[[
          match(destination_patch_id, patch_ids)
        ]],
      gut_available_energy_opening_kj =
        state$gut$gut_available_energy_kj,
      body_energy_reserve_opening_kj =
        state$body$body_energy_reserve_kj,
      current_cue_rate_kg_dm_h = myopic$current_cue_rate_kg_dm_h,
      remembered_current_return_opening_kj_feeding_opportunity_h =
        if (decision_rule != "operational_null") {
          remembered_return_opening[[opening_patch_id]]
        } else {
          NA_real_
        },
      remembered_destination_return_opening_kj_feeding_opportunity_h =
        if (decision_rule != "operational_null") {
          remembered_return_opening[[destination_patch_id]]
        } else {
          NA_real_
        },
      best_destination_return_opening_kj_feeding_opportunity_h = if (
        uses_recovery_memory
      ) {
        best_return_opening[[destination_patch_id]]
      } else {
        NA_real_
      },
      destination_days_since_visit_opening = if (
        uses_recovery_memory
      ) {
        days_since_visit_opening[[destination_patch_id]]
      } else {
        NA_integer_
      },
      expected_current_return_opening_kj_feeding_opportunity_h = if (
        uses_recovery_memory
      ) {
        expected_return_opening[[opening_patch_id]]
      } else {
        NA_real_
      },
      expected_destination_return_opening_kj_feeding_opportunity_h = if (
        uses_recovery_memory
      ) {
        expected_return_opening[[destination_patch_id]]
      } else {
        NA_real_
      },
      myopic_choice = myopic_choice,
      oracle_choice = oracle_choice,
      myopic_move_score_advantage_kj =
        myopic$decision$move_score_advantage_kj,
      oracle_move_score_advantage_kj =
        full_scores_kj[["move"]] - full_scores_kj[["stay"]],
      realized_regret_kj = realized_regret_kj,
      two_day_oracle_choice = two_day_oracle_choice,
      two_day_oracle_move_score_advantage_kj =
        two_day_oracle_move_score_advantage_kj,
      two_day_oracle_regret_kj = two_day_oracle_regret_kj,
      realized_intake_kg_dm =
        selected$daily$realized_dry_matter_intake_kg_dm,
      realized_ingested_energy_kj =
        selected$daily$total_realized_ingested_available_energy_kj,
      feeding_opportunity_h = feeding_opportunity_h,
      experienced_return_kj_feeding_opportunity_h =
        experienced_return_kj_feeding_opportunity_h,
      patch_a_remembered_return_final_kj_feeding_opportunity_h =
        if (decision_rule != "operational_null") {
          remembered_return_kj_feeding_opportunity_h[["patch_a"]]
        } else {
          NA_real_
        },
      patch_b_remembered_return_final_kj_feeding_opportunity_h =
        if (decision_rule != "operational_null") {
          remembered_return_kj_feeding_opportunity_h[["patch_b"]]
        } else {
          NA_real_
        },
      patch_a_best_return_final_kj_feeding_opportunity_h =
        if (uses_recovery_memory) {
          best_return_kj_feeding_opportunity_h[["patch_a"]]
        } else {
          NA_real_
        },
      patch_b_best_return_final_kj_feeding_opportunity_h =
        if (uses_recovery_memory) {
          best_return_kj_feeding_opportunity_h[["patch_b"]]
        } else {
          NA_real_
        },
      patch_a_days_since_visit_final = if (
        uses_recovery_memory
      ) {
        days_since_visit[["patch_a"]]
      } else {
        NA_integer_
      },
      patch_b_days_since_visit_final = if (
        uses_recovery_memory
      ) {
        days_since_visit[["patch_b"]]
      } else {
        NA_integer_
      },
      patch_a_expected_return_opening_kj_feeding_opportunity_h = if (
        uses_recovery_memory
      ) {
        expected_return_opening[["patch_a"]]
      } else {
        NA_real_
      },
      patch_b_expected_return_opening_kj_feeding_opportunity_h = if (
        uses_recovery_memory
      ) {
        expected_return_opening[["patch_b"]]
      } else {
        NA_real_
      },
      stock_limited_hours =
        selected$daily$forage_stock_ceiling_active_hours,
      movement_expenditure_kj =
        selected$daily$total_incremental_movement_expenditure_kj,
      gut_available_energy_final_kj =
        selected$daily$gut_available_energy_final_kj,
      body_energy_reserve_final_kj =
        selected$daily$body_energy_reserve_final_kj,
      patch_a_biomass_final_kg_dm_ha = patch_biomass(
        final_forage,
        "patch_a"
      ),
      patch_b_biomass_final_kg_dm_ha = patch_biomass(
        final_forage,
        "patch_b"
      ),
      valid_counterfactuals = sum(valid_counterfactual),
      all_counterfactual_accounts_close = all(vapply(
        counterfactuals[valid_counterfactual],
        accounts_close,
        logical(1L)
      )),
      all_two_day_counterfactual_accounts_close =
        all_two_day_counterfactual_accounts_close,
      row.names = NULL
    )

    state <- selected$final_state
    completed_days <- simulation_day
  }

  result <- do.call(rbind, daily_rows[seq_len(completed_days)])
  attr(result, "requested_days") <- maximum_days
  attr(result, "completed_days") <- completed_days
  attr(result, "terminal_day") <- terminal_day
  attr(result, "terminal_reason") <- terminal_reason
  attr(result, "checkpoint_states") <- checkpoint_states
  result
}

adequate_patch_quality <- rep(adequate_energy_density_kj_kg_dm, 2L)
quality_contrast <- c(
  lower_energy_density_kj_kg_dm,
  adequate_energy_density_kj_kg_dm
)
runs <- list(
  reference = run_closed_loop(
    "reference",
    10,
    reference_days,
    adequate_patch_quality
  ),
  equal_quality_control = run_closed_loop(
    "equal_quality_control",
    50,
    interaction_days,
    adequate_patch_quality
  ),
  lower_quality_patch_a = run_closed_loop(
    "lower_quality_patch_a",
    50,
    interaction_days,
    quality_contrast
  ),
  experienced_return_memory = run_closed_loop(
    "experienced_return_memory",
    50,
    interaction_days,
    quality_contrast,
    "experienced_return_memory"
  ),
  recovery_aware_memory = run_closed_loop(
    "recovery_aware_memory",
    50,
    interaction_days,
    quality_contrast,
    "recovery_aware_memory"
  ),
  revisit_clock_memory = run_closed_loop(
    "revisit_clock_memory",
    50,
    interaction_days,
    quality_contrast,
    "revisit_clock_memory",
    consequence_checkpoint_days
  )
)
daily <- do.call(rbind, runs)
row.names(daily) <- NULL
reference <- runs$reference
control <- runs$equal_quality_control
quality <- runs$lower_quality_patch_a
memory <- runs$experienced_return_memory
recovery <- runs$recovery_aware_memory
revisit_clock <- runs$revisit_clock_memory
move_rows <- function(run) run[run$myopic_choice == "move", , drop = FALSE]
control_moves <- move_rows(control)
quality_moves <- move_rows(quality)
control_switch_days <- control_moves$simulation_day
quality_switch_days <- quality_moves$simulation_day
memory_moves <- move_rows(memory)
memory_switch_days <- memory_moves$simulation_day
recovery_moves <- move_rows(recovery)
recovery_switch_days <- recovery_moves$simulation_day
revisit_clock_moves <- move_rows(revisit_clock)
revisit_clock_switch_days <- revisit_clock_moves$simulation_day

evaluate_consequence_horizons <- function(
  checkpoint_day,
  checkpoint,
  coupling_parameters,
  landscape
) {
  do.call(rbind, lapply(consequence_horizon_days, function(horizon_days) {
    policies <- list(
      stay = run_candidate_horizon_safely(
        checkpoint$opening_state,
        checkpoint$destination_patch_id,
        "stay",
        coupling_parameters,
        landscape,
        horizon_days
      ),
      move = run_candidate_horizon_safely(
        checkpoint$opening_state,
        checkpoint$destination_patch_id,
        "move",
        coupling_parameters,
        landscape,
        horizon_days
      )
    )
    if (any(vapply(policies, is.null, logical(1L)))) {
      stop("A consequence-horizon policy crossed the body-reserve boundary.")
    }
    move_advantage_kj <- policies$move$final_total_system_energy_kj -
      policies$stay$final_total_system_energy_kj

    data.frame(
      checkpoint_day = checkpoint_day,
      opening_patch_id = checkpoint$opening_state$location$patch_id,
      destination_patch_id = checkpoint$destination_patch_id,
      horizon_days = horizon_days,
      selected_action = if (move_advantage_kj > 0) "move" else "stay",
      move_advantage_kj = move_advantage_kj,
      intake_energy_advantage_kj =
        policies$move$ingested_energy_kj - policies$stay$ingested_energy_kj,
      movement_disadvantage_kj =
        policies$move$movement_expenditure_kj -
          policies$stay$movement_expenditure_kj,
      closing_body_reserve_advantage_kj =
        policies$move$final_body_energy_reserve_kj -
          policies$stay$final_body_energy_reserve_kj,
      stay_closing_body_reserve_kj =
        policies$stay$final_body_energy_reserve_kj,
      move_closing_body_reserve_kj =
        policies$move$final_body_energy_reserve_kj,
      stay_closing_patch_a_biomass_kg_dm_ha =
        policies$stay$final_patch_a_biomass_kg_dm_ha,
      stay_closing_patch_b_biomass_kg_dm_ha =
        policies$stay$final_patch_b_biomass_kg_dm_ha,
      move_closing_patch_a_biomass_kg_dm_ha =
        policies$move$final_patch_a_biomass_kg_dm_ha,
      move_closing_patch_b_biomass_kg_dm_ha =
        policies$move$final_patch_b_biomass_kg_dm_ha,
      all_accounts_close =
        policies$stay$all_accounts_close && policies$move$all_accounts_close,
      row.names = NULL
    )
  }))
}

pressure_coupling <- herbivoreTTR::new_nonspatial_coupling_parameters(50, 500)
pressure_landscape <- new_landscape(
  rep(static_acquisition_capacity_kg_dm_h, 2L),
  quality_contrast
)
consequence_checkpoints <- attr(revisit_clock, "checkpoint_states")
consequence_horizon_table <- do.call(rbind, lapply(
  consequence_checkpoint_days,
  function(checkpoint_day) {
    evaluate_consequence_horizons(
      checkpoint_day,
      consequence_checkpoints[[as.character(checkpoint_day)]],
      pressure_coupling,
      pressure_landscape
    )
  }
))
row.names(consequence_horizon_table) <- NULL

assert_that(
  all(reference$myopic_choice == "stay") &&
    all(reference$oracle_choice == "stay") &&
    sum(reference$stock_limited_hours) == 0L &&
    near(reference$body_energy_reserve_final_kj, rep(40000, reference_days)) &&
    near(reference$patch_b_biomass_final_kg_dm_ha, rep(1000, reference_days)),
  "the low-load equal-quality reference remains resident and energy-neutral"
)
assert_that(
  identical(
    control_switch_days,
    c(59L, 117L, 166L, 213L, 259L, 305L)
  ) &&
    identical(diff(control_switch_days), c(58L, 49L, 47L, 46L, 46L)) &&
    identical(
      control_moves$opening_patch_id,
      rep(c("patch_a", "patch_b"), 3L)
    ),
  "the fixed 305-day control reproduces the accepted six-switch recurrence"
)
assert_that(
  identical(
    quality_switch_days,
    c(40L, 97L, 129L, 168L, 195L, 231L, 258L, 293L)
  ) &&
    identical(
      quality_moves$opening_patch_id,
      rep(c("patch_a", "patch_b"), 4L)
    ) &&
    min(diff(quality_switch_days)) >= 27L,
  "one lower-quality patch advances and increases switching without chattering"
)
assert_that(
  quality_switch_days[[1L]] < control_switch_days[[1L]] &&
    nrow(quality_moves) > nrow(control_moves) &&
    sum(quality$realized_intake_kg_dm[1:39]) >
      sum(control$realized_intake_kg_dm[1:39]) &&
    quality$patch_a_biomass_final_kg_dm_ha[[39L]] <
      control$patch_a_biomass_final_kg_dm_ha[[39L]] &&
    min(quality$body_energy_reserve_final_kj) <
      min(control$body_energy_reserve_final_kj),
  "lower energy density increases dry-matter pressure and physiological cost"
)
quality_disagreement_days <- quality$simulation_day[
  quality$myopic_choice != quality$oracle_choice
]
memory_disagreement_days <- memory$simulation_day[
  memory$myopic_choice != memory$oracle_choice
]
assert_that(
  identical(
    quality_disagreement_days,
    c(39L, 97L, 128L, 168L, 231L, 257L, 293L)
  ) &&
    all(daily$realized_regret_kj >= 0) &&
    round(sum(quality$realized_regret_kj)) == 2919L,
  "the quality treatment exposes seven bounded daily oracle disagreements"
)
assert_that(
  all(control_moves$opening_current_biomass_kg_dm_ha == 500) &&
    max(abs(
      quality_moves$opening_current_biomass_kg_dm_ha - 500
    )) < 0.6 &&
    all(daily$all_counterfactual_accounts_close),
  "switches remain depletion-linked and all counterfactual accounts close"
)
assert_that(
  identical(memory_switch_days, 41L) &&
    identical(memory_disagreement_days, c(39L, 40L)) &&
    round(sum(memory$realized_regret_kj)) == 1333L,
  "last-experience memory delays the first departure by one day"
)
assert_that(
  attr(memory, "requested_days") == 305L &&
    attr(memory, "completed_days") == 146L &&
    attr(memory, "terminal_day") == 147L &&
    identical(
      attr(memory, "terminal_reason"),
      "no action preserves a non-negative body reserve"
    ) &&
    memory$valid_counterfactuals[[146L]] == 1L &&
    round(memory$body_energy_reserve_final_kj[[146L]]) == 250L,
  "memory alone reaches the non-negative body-reserve boundary on day 147"
)
assert_that(
  tail(memory$patch_a_biomass_final_kg_dm_ha, 1L) > 960 &&
    near(tail(memory$patch_b_biomass_final_kg_dm_ha, 1L), 500) &&
    tail(
      memory$patch_a_remembered_return_final_kj_feeding_opportunity_h,
      1L
    ) < tail(
      memory$patch_b_remembered_return_final_kj_feeding_opportunity_h,
      1L
    ),
  "stale patch-A experience blocks return despite unobserved forage renewal"
)
assert_that(
  attr(recovery, "requested_days") == interaction_days &&
    attr(recovery, "completed_days") == interaction_days &&
    is.na(attr(recovery, "terminal_day")) &&
    length(recovery_switch_days) == 7L &&
    min(diff(recovery_switch_days)) >= 32L &&
    all(c("patch_a", "patch_b") %in% recovery$closing_patch_id),
  "recovery-aware memory completes 305 days with recurrent patch use"
)
assert_that(
  near(
    recovery$expected_current_return_opening_kj_feeding_opportunity_h,
    recovery$remembered_current_return_opening_kj_feeding_opportunity_h
  ) &&
    near(
      recovery$expected_destination_return_opening_kj_feeding_opportunity_h,
      mapply(
        recover_expected_return,
        recovery$
          remembered_destination_return_opening_kj_feeding_opportunity_h,
        recovery$
          best_destination_return_opening_kj_feeding_opportunity_h,
        recovery$destination_days_since_visit_opening
      )
    ) &&
    all(
      recovery$expected_destination_return_opening_kj_feeding_opportunity_h >=
        recovery$
          remembered_destination_return_opening_kj_feeding_opportunity_h -
          1e-10
    ) &&
    all(
      recovery$expected_destination_return_opening_kj_feeding_opportunity_h <=
        recovery$best_destination_return_opening_kj_feeding_opportunity_h +
          1e-10
    ),
  "recovery beliefs are bounded and follow the declared turnover prior"
)
assert_that(
  all(recovery$all_two_day_counterfactual_accounts_close) &&
    all(recovery$two_day_oracle_regret_kj >= 0) &&
    min(recovery$body_energy_reserve_final_kj) > 0,
  "two-day comparisons close and the carried animal remains non-negative"
)
assert_that(
  attr(revisit_clock, "requested_days") == interaction_days &&
    attr(revisit_clock, "completed_days") == interaction_days &&
    is.na(attr(revisit_clock, "terminal_day")) &&
    length(revisit_clock_switch_days) == 83L &&
    min(diff(revisit_clock_switch_days)) == 2L &&
    all(c("patch_a", "patch_b") %in% revisit_clock$closing_patch_id),
  "the revisit clock completes but produces frequent reciprocal switching"
)
assert_that(
  near(
    revisit_clock$expected_current_return_opening_kj_feeding_opportunity_h,
    revisit_clock$remembered_current_return_opening_kj_feeding_opportunity_h
  ) &&
    near(
      revisit_clock$
        expected_destination_return_opening_kj_feeding_opportunity_h,
      mapply(
        recover_expected_return_by_revisit_clock,
        revisit_clock$
          remembered_destination_return_opening_kj_feeding_opportunity_h,
        revisit_clock$
          best_destination_return_opening_kj_feeding_opportunity_h,
        revisit_clock$destination_days_since_visit_opening
      )
    ) &&
    all(
      revisit_clock$
        expected_destination_return_opening_kj_feeding_opportunity_h >=
        revisit_clock$
          remembered_destination_return_opening_kj_feeding_opportunity_h -
          1e-10
    ) &&
    all(
      revisit_clock$
        expected_destination_return_opening_kj_feeding_opportunity_h <=
        revisit_clock$
          best_destination_return_opening_kj_feeding_opportunity_h + 1e-10
    ),
  "the revisit-clock belief is bounded and follows its prespecified equation"
)
assert_that(
  all(revisit_clock$all_two_day_counterfactual_accounts_close) &&
    all(revisit_clock$two_day_oracle_regret_kj >= 0) &&
    min(revisit_clock$body_energy_reserve_final_kj) > 0 &&
    sum(revisit_clock$movement_expenditure_kj) >
      sum(recovery$movement_expenditure_kj) &&
    min(revisit_clock$body_energy_reserve_final_kj) <
      min(recovery$body_energy_reserve_final_kj),
  "rapid revisits raise travel cost and deepen reserve loss despite closure"
)
assert_that(
  identical(names(consequence_checkpoints), as.character(
    consequence_checkpoint_days
  )) &&
    identical(
      vapply(
        consequence_checkpoints,
        function(checkpoint) checkpoint$opening_state$location$patch_id,
        character(1L)
      ),
      c(`60` = "patch_b", `62` = "patch_a")
    ) &&
    identical(
      vapply(
        consequence_checkpoints,
        function(checkpoint) checkpoint$destination_patch_id,
        character(1L)
      ),
      c(`60` = "patch_a", `62` = "patch_b")
    ),
  "the horizon map uses the exact first two reciprocal rotation checkpoints"
)
assert_that(
  identical(
    consequence_horizon_table$horizon_days,
    rep(consequence_horizon_days, length(consequence_checkpoint_days))
  ) &&
    all(consequence_horizon_table$all_accounts_close) &&
    all(is.finite(unlist(
      consequence_horizon_table[vapply(
        consequence_horizon_table,
        is.numeric,
        logical(1L)
      )]
    ))) &&
    near(
      consequence_horizon_table$movement_disadvantage_kj,
      rep(900, nrow(consequence_horizon_table))
    ) &&
    near(
      consequence_horizon_table$move_advantage_kj,
      consequence_horizon_table$intake_energy_advantage_kj -
        consequence_horizon_table$movement_disadvantage_kj
    ),
  "the prespecified horizon comparisons are finite and decompose exactly"
)
day_60_horizons <- consequence_horizon_table[
  consequence_horizon_table$checkpoint_day == 60L,
  ,
  drop = FALSE
]
day_62_horizons <- consequence_horizon_table[
  consequence_horizon_table$checkpoint_day == 62L,
  ,
  drop = FALSE
]
assert_that(
  identical(
    day_60_horizons$selected_action,
    c("stay", "move", "move", "move", "move")
  ) &&
    all(diff(day_60_horizons$move_advantage_kj) > 0),
  "moving from depleted B into rested A strengthens beyond one day"
)
assert_that(
  identical(
    day_62_horizons$selected_action,
    c("stay", "move", "move", "stay", "stay")
  ) &&
    day_62_horizons$move_advantage_kj[
      day_62_horizons$horizon_days == 4L
    ] > 0 &&
    day_62_horizons$move_advantage_kj[
      day_62_horizons$horizon_days == 7L
    ] < 0,
  "returning to newly released B reverses between four and seven days"
)

summary_table <- do.call(rbind, lapply(runs, function(run) {
  moves <- move_rows(run)
  data.frame(
    treatment = run$treatment[[1L]],
    decision_rule = run$decision_rule[[1L]],
    density_animals_ha = run$density_animals_ha[[1L]],
    patch_a_energy_density_kj_kg_dm =
      run$current_energy_density_kj_kg_dm[[1L]],
    patch_b_energy_density_kj_kg_dm =
      run$destination_energy_density_kj_kg_dm[[1L]],
    requested_days = attr(run, "requested_days"),
    completed_days = attr(run, "completed_days"),
    terminal_day = attr(run, "terminal_day"),
    terminal_reason = attr(run, "terminal_reason"),
    number_of_switches = nrow(moves),
    switch_days = if (nrow(moves) == 0L) {
      "none"
    } else if (nrow(moves) <= 12L) {
      paste(moves$simulation_day, collapse = ", ")
    } else {
      paste(
        c(
          head(moves$simulation_day, 6L),
          "...",
          tail(moves$simulation_day, 6L)
        ),
        collapse = ", "
      )
    },
    foraging_days_patch_a = sum(run$closing_patch_id == "patch_a"),
    foraging_days_patch_b = sum(run$closing_patch_id == "patch_b"),
    one_day_oracle_disagreements = sum(
      run$myopic_choice != run$oracle_choice
    ),
    two_day_oracle_disagreements = if (
      all(is.na(run$two_day_oracle_choice))
    ) {
      NA_integer_
    } else {
      sum(run$myopic_choice != run$two_day_oracle_choice)
    },
    dry_matter_intake_first_39_days_kg_dm = sum(head(
      run$realized_intake_kg_dm,
      39L
    )),
    patch_a_biomass_after_day_39_kg_dm_ha =
      run$patch_a_biomass_final_kg_dm_ha[[39L]],
    stock_limited_hours = sum(run$stock_limited_hours),
    movement_expenditure_kj = round(sum(run$movement_expenditure_kj)),
    cumulative_regret_kj = round(sum(run$realized_regret_kj)),
    cumulative_two_day_regret_kj = if (
      all(is.na(run$two_day_oracle_regret_kj))
    ) {
      NA_integer_
    } else {
      round(sum(run$two_day_oracle_regret_kj))
    },
    minimum_body_reserve_kj = round(min(run$body_energy_reserve_final_kj)),
    closing_body_reserve_kj = round(tail(
      run$body_energy_reserve_final_kj,
      1L
    )),
    closing_patch_id = tail(run$closing_patch_id, 1L),
    closing_patch_a_biomass_kg_dm_ha = tail(
      run$patch_a_biomass_final_kg_dm_ha,
      1L
    ),
    closing_patch_b_biomass_kg_dm_ha = tail(
      run$patch_b_biomass_final_kg_dm_ha,
      1L
    ),
    row.names = NULL
  )
}))

interaction_runs <- runs[c(
  "equal_quality_control",
  "lower_quality_patch_a",
  "experienced_return_memory",
  "recovery_aware_memory"
)]
switch_table <- do.call(rbind, lapply(interaction_runs, function(run) {
  rows <- move_rows(run)
  rows$switch_number <- seq_len(nrow(rows))
  rows$interval_since_previous_move_days <- c(
    NA_integer_,
    diff(rows$simulation_day)
  )
  rows[, c(
    "treatment",
    "decision_rule",
    "switch_number",
    "simulation_day",
    "interval_since_previous_move_days",
    "opening_patch_id",
    "destination_patch_id",
    "closing_patch_id",
    "current_energy_density_kj_kg_dm",
    "destination_energy_density_kj_kg_dm",
    "opening_current_biomass_kg_dm_ha",
    "opening_destination_biomass_kg_dm_ha",
    "body_energy_reserve_opening_kj",
    "oracle_choice",
    "realized_regret_kj"
  ), drop = FALSE]
}))
row.names(switch_table) <- NULL
revisit_clock_post_return_intervals <- diff(
  revisit_clock_switch_days[revisit_clock_switch_days >= 60L]
)
revisit_clock_cycle_summary <- data.frame(
  first_move_day = revisit_clock_switch_days[[1L]],
  first_return_day = revisit_clock_switch_days[[2L]],
  total_switches = length(revisit_clock_switch_days),
  shortest_interval_days = min(diff(revisit_clock_switch_days)),
  longest_interval_days = max(diff(revisit_clock_switch_days)),
  post_return_interval_days = paste(
    sort(unique(revisit_clock_post_return_intervals)),
    collapse = ", "
  ),
  final_switch_day = tail(revisit_clock_switch_days, 1L),
  row.names = NULL
)

two_day_disagreement_table <- recovery[
  recovery$myopic_choice != recovery$two_day_oracle_choice,
  c(
    "simulation_day",
    "opening_patch_id",
    "destination_patch_id",
    "opening_current_biomass_kg_dm_ha",
    "opening_destination_biomass_kg_dm_ha",
    "remembered_destination_return_opening_kj_feeding_opportunity_h",
    "best_destination_return_opening_kj_feeding_opportunity_h",
    "destination_days_since_visit_opening",
    "expected_destination_return_opening_kj_feeding_opportunity_h",
    "myopic_choice",
    "two_day_oracle_choice",
    "myopic_move_score_advantage_kj",
    "two_day_oracle_move_score_advantage_kj",
    "two_day_oracle_regret_kj"
  ),
  drop = FALSE
]
two_day_disagreement_summary <- data.frame(
  disagreement_days = nrow(two_day_disagreement_table),
  false_stays = sum(
    two_day_disagreement_table$myopic_choice == "stay" &
      two_day_disagreement_table$two_day_oracle_choice == "move"
  ),
  false_moves = sum(
    two_day_disagreement_table$myopic_choice == "move" &
      two_day_disagreement_table$two_day_oracle_choice == "stay"
  ),
  cumulative_local_regret_kj = round(sum(
    two_day_disagreement_table$two_day_oracle_regret_kj
  )),
  maximum_daily_regret_kj = round(max(
    two_day_disagreement_table$two_day_oracle_regret_kj
  )),
  maximum_regret_day = two_day_disagreement_table$simulation_day[
    which.max(two_day_disagreement_table$two_day_oracle_regret_kj)
  ],
  row.names = NULL
)
revisit_two_day_disagreement_table <- revisit_clock[
  revisit_clock$myopic_choice != revisit_clock$two_day_oracle_choice,
  ,
  drop = FALSE
]
revisit_two_day_disagreement_summary <- data.frame(
  disagreement_days = nrow(revisit_two_day_disagreement_table),
  false_stays = sum(
    revisit_two_day_disagreement_table$myopic_choice == "stay" &
      revisit_two_day_disagreement_table$two_day_oracle_choice == "move"
  ),
  false_moves = sum(
    revisit_two_day_disagreement_table$myopic_choice == "move" &
      revisit_two_day_disagreement_table$two_day_oracle_choice == "stay"
  ),
  cumulative_local_regret_kj = round(sum(
    revisit_two_day_disagreement_table$two_day_oracle_regret_kj
  )),
  maximum_daily_regret_kj = round(max(
    revisit_two_day_disagreement_table$two_day_oracle_regret_kj
  )),
  maximum_regret_day = revisit_two_day_disagreement_table$simulation_day[
    which.max(revisit_two_day_disagreement_table$two_day_oracle_regret_kj)
  ],
  row.names = NULL
)
disagreement_run_id <- cumsum(c(
  TRUE,
  diff(two_day_disagreement_table$simulation_day) != 1L
))
two_day_disagreement_runs <- do.call(rbind, lapply(
  split(two_day_disagreement_table, disagreement_run_id),
  function(rows) {
    data.frame(
      first_day = min(rows$simulation_day),
      last_day = max(rows$simulation_day),
      number_of_days = nrow(rows),
      selected_action = unique(rows$myopic_choice),
      oracle_action = unique(rows$two_day_oracle_choice),
      local_regret_kj = round(sum(rows$two_day_oracle_regret_kj)),
      row.names = NULL
    )
  }
))
row.names(two_day_disagreement_runs) <- NULL

disagreement_table <- daily[
  daily$treatment != "reference" &
    daily$decision_rule != "revisit_clock_memory" &
    daily$myopic_choice != daily$oracle_choice,
  c(
    "treatment",
    "decision_rule",
    "simulation_day",
    "opening_patch_id",
    "destination_patch_id",
    "current_energy_density_kj_kg_dm",
    "destination_energy_density_kj_kg_dm",
    "opening_current_biomass_kg_dm_ha",
    "opening_destination_biomass_kg_dm_ha",
    "myopic_choice",
    "oracle_choice",
    "myopic_move_score_advantage_kj",
    "oracle_move_score_advantage_kj",
    "realized_regret_kj"
  ),
  drop = FALSE
]

cat("Daily biomass-quality choice and memory diagnostic passed.\n")
cat(
  "The operational null completes 305 days; the memory rule reaches ",
  "the body-reserve boundary before day 147; recovery-aware memory ",
  "completes 305 days; the revisit clock completes but switches 83 times.\n\n",
  sep = ""
)
cat("Treatment summary:\n")
print(transform(
  summary_table,
  dry_matter_intake_first_39_days_kg_dm = round(
    dry_matter_intake_first_39_days_kg_dm,
    3
  ),
  patch_a_biomass_after_day_39_kg_dm_ha = round(
    patch_a_biomass_after_day_39_kg_dm_ha,
    2
  ),
  closing_patch_a_biomass_kg_dm_ha = round(
    closing_patch_a_biomass_kg_dm_ha,
    2
  ),
  closing_patch_b_biomass_kg_dm_ha = round(
    closing_patch_b_biomass_kg_dm_ha,
    2
  )
), row.names = FALSE)
cat("\nRecovery-aware two-day oracle disagreements:\n")
print(two_day_disagreement_summary, row.names = FALSE)
cat("\nRevisit-clock two-day oracle disagreements:\n")
print(revisit_two_day_disagreement_summary, row.names = FALSE)
cat("\nGoal 050 contiguous two-day disagreement intervals:\n")
print(two_day_disagreement_runs, row.names = FALSE)
cat("\nInteraction switch events:\n")
print(transform(
  switch_table,
  opening_current_biomass_kg_dm_ha = round(
    opening_current_biomass_kg_dm_ha,
    2
  ),
  opening_destination_biomass_kg_dm_ha = round(
    opening_destination_biomass_kg_dm_ha,
    2
  ),
  body_energy_reserve_opening_kj = round(body_energy_reserve_opening_kj),
  realized_regret_kj = round(realized_regret_kj)
), row.names = FALSE)
cat("\nRevisit-clock cycle summary:\n")
print(revisit_clock_cycle_summary, row.names = FALSE)
cat("\nFixed-state consequence-horizon decomposition:\n")
print(transform(
  consequence_horizon_table[, c(
    "checkpoint_day",
    "opening_patch_id",
    "destination_patch_id",
    "horizon_days",
    "selected_action",
    "move_advantage_kj",
    "intake_energy_advantage_kj",
    "movement_disadvantage_kj",
    "closing_body_reserve_advantage_kj",
    "stay_closing_patch_a_biomass_kg_dm_ha",
    "stay_closing_patch_b_biomass_kg_dm_ha",
    "move_closing_patch_a_biomass_kg_dm_ha",
    "move_closing_patch_b_biomass_kg_dm_ha"
  )],
  move_advantage_kj = round(move_advantage_kj),
  intake_energy_advantage_kj = round(intake_energy_advantage_kj),
  movement_disadvantage_kj = round(movement_disadvantage_kj),
  closing_body_reserve_advantage_kj = round(
    closing_body_reserve_advantage_kj
  ),
  stay_closing_patch_a_biomass_kg_dm_ha = round(
    stay_closing_patch_a_biomass_kg_dm_ha,
    2
  ),
  stay_closing_patch_b_biomass_kg_dm_ha = round(
    stay_closing_patch_b_biomass_kg_dm_ha,
    2
  ),
  move_closing_patch_a_biomass_kg_dm_ha = round(
    move_closing_patch_a_biomass_kg_dm_ha,
    2
  ),
  move_closing_patch_b_biomass_kg_dm_ha = round(
    move_closing_patch_b_biomass_kg_dm_ha,
    2
  )
), row.names = FALSE)
cat("\nDaily oracle disagreements:\n")
print(transform(
  disagreement_table,
  opening_current_biomass_kg_dm_ha = round(
    opening_current_biomass_kg_dm_ha,
    2
  ),
  opening_destination_biomass_kg_dm_ha = round(
    opening_destination_biomass_kg_dm_ha,
    2
  ),
  myopic_move_score_advantage_kj = round(
    myopic_move_score_advantage_kj
  ),
  oracle_move_score_advantage_kj = round(
    oracle_move_score_advantage_kj
  ),
  realized_regret_kj = round(realized_regret_kj)
), row.names = FALSE)
