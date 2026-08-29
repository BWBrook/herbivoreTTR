source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
patch_ids <- c("patch_a", "patch_b")
static_acquisition_capacity_kg_dm_h <- 0.025
destination_expected_acquisition_rate_kg_dm_h <- 0.025
expected_demand_kg_dm_h <- 0.020
remaining_feeding_opportunity_h <- 16L
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
  landscape
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
      remaining_feeding_opportunity_h
  move_score_kj <-
    remembered_return_kj_feeding_opportunity_h[[destination_patch_id]] *
      (remaining_feeding_opportunity_h - travel_duration_h) -
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

run_closed_loop <- function(
  treatment,
  density_animals_ha,
  maximum_days,
  energy_densities_kj_kg_dm,
  decision_rule = c("operational_null", "experienced_return_memory")
) {
  decision_rule <- match.arg(decision_rule)
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
  completed_days <- 0L
  terminal_day <- NA_integer_
  terminal_reason <- NA_character_

  for (simulation_day in seq_len(maximum_days)) {
    opening_patch_id <- state$location$patch_id
    destination_patch_id <- setdiff(patch_ids, opening_patch_id)
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
          remembered_return_opening,
          landscape
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
    final_forage <- selected$final_state$forage
    feeding_opportunity_h <- sum(selected$hourly$feeding_opportunity_open)
    experienced_return_kj_feeding_opportunity_h <-
      selected$daily$total_realized_ingested_available_energy_kj /
        feeding_opportunity_h
    if (decision_rule == "experienced_return_memory") {
      foraging_patch_id <- selected$final_state$location$patch_id
      remembered_return_kj_feeding_opportunity_h[[foraging_patch_id]] <-
        experienced_return_kj_feeding_opportunity_h
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
        if (decision_rule == "experienced_return_memory") {
          remembered_return_opening[[opening_patch_id]]
        } else {
          NA_real_
        },
      remembered_destination_return_opening_kj_feeding_opportunity_h =
        if (decision_rule == "experienced_return_memory") {
          remembered_return_opening[[destination_patch_id]]
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
      realized_intake_kg_dm =
        selected$daily$realized_dry_matter_intake_kg_dm,
      realized_ingested_energy_kj =
        selected$daily$total_realized_ingested_available_energy_kj,
      feeding_opportunity_h = feeding_opportunity_h,
      experienced_return_kj_feeding_opportunity_h =
        experienced_return_kj_feeding_opportunity_h,
      patch_a_remembered_return_final_kj_feeding_opportunity_h =
        if (decision_rule == "experienced_return_memory") {
          remembered_return_kj_feeding_opportunity_h[["patch_a"]]
        } else {
          NA_real_
        },
      patch_b_remembered_return_final_kj_feeding_opportunity_h =
        if (decision_rule == "experienced_return_memory") {
          remembered_return_kj_feeding_opportunity_h[["patch_b"]]
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
  )
)
daily <- do.call(rbind, runs)
row.names(daily) <- NULL
reference <- runs$reference
control <- runs$equal_quality_control
quality <- runs$lower_quality_patch_a
memory <- runs$experienced_return_memory
move_rows <- function(run) run[run$myopic_choice == "move", , drop = FALSE]
control_moves <- move_rows(control)
quality_moves <- move_rows(quality)
control_switch_days <- control_moves$simulation_day
quality_switch_days <- quality_moves$simulation_day
memory_moves <- move_rows(memory)
memory_switch_days <- memory_moves$simulation_day

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
    } else {
      paste(moves$simulation_day, collapse = ", ")
    },
    foraging_days_patch_a = sum(run$closing_patch_id == "patch_a"),
    foraging_days_patch_b = sum(run$closing_patch_id == "patch_b"),
    oracle_disagreements = sum(run$myopic_choice != run$oracle_choice),
    dry_matter_intake_first_39_days_kg_dm = sum(head(
      run$realized_intake_kg_dm,
      39L
    )),
    patch_a_biomass_after_day_39_kg_dm_ha =
      run$patch_a_biomass_final_kg_dm_ha[[39L]],
    stock_limited_hours = sum(run$stock_limited_hours),
    movement_expenditure_kj = round(sum(run$movement_expenditure_kj)),
    cumulative_regret_kj = round(sum(run$realized_regret_kj)),
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
  "experienced_return_memory"
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

disagreement_table <- daily[
  daily$treatment != "reference" &
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
  "the body-reserve boundary before day 147.\n\n",
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
