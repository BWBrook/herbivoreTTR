source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
patch_ids <- c("patch_a", "patch_b")
feeding_opportunity_h_day <- 16L
snapshot_completed_days <- 100L
maximum_planning_horizon_days <- 7L
expected_demand_kg_dm_h <- 0.020
energy_densities_kj_kg_dm <- c(8000, 10000)
names(energy_densities_kj_kg_dm) <- patch_ids

landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = patch_ids,
  forage_acquisition_ceiling_kg_dm_h = c(0.025, 0.025),
  route_origin_patch_id = c("patch_a", "patch_b"),
  route_destination_patch_id = c("patch_b", "patch_a"),
  incremental_movement_expenditure_kj = c(900, 900),
  metabolizable_energy_density_kj_kg_dm = energy_densities_kj_kg_dm
)
turnover <- herbivoreTTR::new_forage_turnover_parameters(1000, 0.001)
coupling <- herbivoreTTR::new_nonspatial_coupling_parameters(50, 500)

patch_biomass <- function(forage_state, patch_id) {
  forage_state$forage_biomass_kg_dm_ha[
    forage_state$patch_id == patch_id
  ]
}

run_spatial_day <- function(opening_state, closing_patch_id) {
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
    coupling_parameters = coupling,
    appetite_reference_schedule = fixture$appetite_reference,
    routine_activity_schedule = fixture$activity
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

choose_from_memory <- function(
  opening_patch_id,
  remembered_return_kj_feeding_opportunity_h
) {
  destination_patch_id <- setdiff(patch_ids, opening_patch_id)
  route_index <- which(
    landscape$routes$origin_patch_id == opening_patch_id &
      landscape$routes$destination_patch_id == destination_patch_id
  )
  travel_duration_h <- landscape$routes$travel_duration_h[[route_index]]
  movement_expenditure_kj <- landscape$routes$
    incremental_movement_expenditure_kj[[route_index]]
  stay_score_kj <-
    remembered_return_kj_feeding_opportunity_h[[opening_patch_id]] *
      feeding_opportunity_h_day
  move_score_kj <-
    remembered_return_kj_feeding_opportunity_h[[destination_patch_id]] *
      (feeding_opportunity_h_day - travel_duration_h) -
      movement_expenditure_kj
  tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(c(stay_score_kj, move_score_kj))
  )

  list(
    destination_patch_id = destination_patch_id,
    selected_action = if (move_score_kj > stay_score_kj + tolerance_kj) {
      "move"
    } else {
      "stay"
    }
  )
}

state <- list(
  location = herbivoreTTR::new_patch_location_state("patch_a"),
  gut = fixture$opening_gut,
  body = fixture$opening_body,
  forage = herbivoreTTR::new_spatial_forage_biomass_state(
    patch_ids,
    c(1000, 1000)
  )
)
remembered_return_kj_feeding_opportunity_h <-
  expected_demand_kg_dm_h * energy_densities_kj_kg_dm
maximum_experienced_return_kj_feeding_opportunity_h <-
  remembered_return_kj_feeding_opportunity_h
history_rows <- vector("list", snapshot_completed_days)

for (simulation_day in seq_len(snapshot_completed_days)) {
  opening_patch_id <- state$location$patch_id
  decision <- choose_from_memory(
    opening_patch_id,
    remembered_return_kj_feeding_opportunity_h
  )
  closing_patch_id <- if (decision$selected_action == "move") {
    decision$destination_patch_id
  } else {
    opening_patch_id
  }
  result <- run_spatial_day(state, closing_patch_id)
  feeding_opportunity_h <- sum(result$hourly$feeding_opportunity_open)
  experienced_return_kj_feeding_opportunity_h <-
    result$daily$total_realized_ingested_available_energy_kj /
      feeding_opportunity_h
  remembered_return_kj_feeding_opportunity_h[[closing_patch_id]] <-
    experienced_return_kj_feeding_opportunity_h
  maximum_experienced_return_kj_feeding_opportunity_h[[closing_patch_id]] <-
    max(
      maximum_experienced_return_kj_feeding_opportunity_h[[
        closing_patch_id
      ]],
      experienced_return_kj_feeding_opportunity_h
    )
  history_rows[[simulation_day]] <- data.frame(
    simulation_day = simulation_day,
    opening_patch_id = opening_patch_id,
    closing_patch_id = closing_patch_id,
    selected_action = decision$selected_action,
    experienced_return_kj_feeding_opportunity_h =
      experienced_return_kj_feeding_opportunity_h,
    body_energy_reserve_final_kj =
      result$daily$body_energy_reserve_final_kj,
    patch_a_biomass_final_kg_dm_ha = patch_biomass(
      result$final_state$forage,
      "patch_a"
    ),
    patch_b_biomass_final_kg_dm_ha = patch_biomass(
      result$final_state$forage,
      "patch_b"
    ),
    accounts_close = accounts_close(result),
    row.names = NULL
  )
  state <- result$final_state
}

history <- do.call(rbind, history_rows)
snapshot <- list(
  state = state,
  stale_return_kj_feeding_opportunity_h =
    remembered_return_kj_feeding_opportunity_h,
  recovered_return_kj_feeding_opportunity_h =
    maximum_experienced_return_kj_feeding_opportunity_h
)
snapshot_table <- data.frame(
  opening_day = snapshot_completed_days + 1L,
  location = snapshot$state$location$patch_id,
  body_energy_reserve_kj = snapshot$state$body$body_energy_reserve_kj,
  gut_available_energy_kj = snapshot$state$gut$gut_available_energy_kj,
  patch_a_biomass_kg_dm_ha = patch_biomass(
    snapshot$state$forage,
    "patch_a"
  ),
  patch_b_biomass_kg_dm_ha = patch_biomass(
    snapshot$state$forage,
    "patch_b"
  ),
  stale_patch_a_return_kj_feeding_opportunity_h =
    snapshot$stale_return_kj_feeding_opportunity_h[["patch_a"]],
  current_patch_b_return_kj_feeding_opportunity_h =
    snapshot$stale_return_kj_feeding_opportunity_h[["patch_b"]],
  recovered_patch_a_return_kj_feeding_opportunity_h =
    snapshot$recovered_return_kj_feeding_opportunity_h[["patch_a"]],
  row.names = NULL
)

score_choice <- function(
  information_assumption,
  destination_return_kj_feeding_opportunity_h,
  horizon_days
) {
  current_return_kj_feeding_opportunity_h <-
    snapshot$stale_return_kj_feeding_opportunity_h[["patch_b"]]
  stay_score_kj <- current_return_kj_feeding_opportunity_h *
    feeding_opportunity_h_day * horizon_days
  move_score_kj <- destination_return_kj_feeding_opportunity_h *
    (feeding_opportunity_h_day * horizon_days - 1L) - 900
  tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(c(stay_score_kj, move_score_kj))
  )

  data.frame(
    information_assumption = information_assumption,
    horizon_days = horizon_days,
    current_return_kj_feeding_opportunity_h =
      current_return_kj_feeding_opportunity_h,
    destination_return_kj_feeding_opportunity_h =
      destination_return_kj_feeding_opportunity_h,
    stay_score_kj = stay_score_kj,
    move_score_kj = move_score_kj,
    move_score_advantage_kj = move_score_kj - stay_score_kj,
    selected_action = if (move_score_kj > stay_score_kj + tolerance_kj) {
      "move"
    } else {
      "stay"
    },
    row.names = NULL
  )
}

score_table <- do.call(rbind, lapply(
  c("stale_last_experience", "recovered_opportunity"),
  function(information_assumption) {
    destination_return <- if (
      information_assumption == "stale_last_experience"
    ) {
      snapshot$stale_return_kj_feeding_opportunity_h[["patch_a"]]
    } else {
      snapshot$recovered_return_kj_feeding_opportunity_h[["patch_a"]]
    }
    do.call(rbind, lapply(1:2, function(horizon_days) {
      score_choice(
        information_assumption,
        destination_return,
        horizon_days
      )
    }))
  }
))
row.names(score_table) <- NULL

run_policy <- function(policy, horizon_days) {
  policy_state <- snapshot$state
  rows <- vector("list", horizon_days)

  for (policy_day in seq_len(horizon_days)) {
    closing_patch_id <- if (policy == "stay_in_b") {
      "patch_b"
    } else {
      "patch_a"
    }
    result <- run_spatial_day(policy_state, closing_patch_id)
    rows[[policy_day]] <- data.frame(
      policy = policy,
      horizon_days = horizon_days,
      policy_day = policy_day,
      realized_ingested_energy_kj =
        result$daily$total_realized_ingested_available_energy_kj,
      incremental_movement_expenditure_kj =
        result$daily$total_incremental_movement_expenditure_kj,
      gut_available_energy_final_kj =
        result$daily$gut_available_energy_final_kj,
      body_energy_reserve_final_kj =
        result$daily$body_energy_reserve_final_kj,
      total_system_energy_final_kj =
        result$daily$total_system_energy_final_kj,
      patch_a_biomass_final_kg_dm_ha = patch_biomass(
        result$final_state$forage,
        "patch_a"
      ),
      patch_b_biomass_final_kg_dm_ha = patch_biomass(
        result$final_state$forage,
        "patch_b"
      ),
      accounts_close = accounts_close(result),
      row.names = NULL
    )
    policy_state <- result$final_state
  }

  do.call(rbind, rows)
}

compare_horizon <- function(horizon_days) {
  stay <- run_policy("stay_in_b", horizon_days)
  move <- run_policy("move_to_a", horizon_days)
  stay_final <- tail(stay, 1L)
  move_final <- tail(move, 1L)
  full_model_move_advantage_kj <-
    move_final$total_system_energy_final_kj -
      stay_final$total_system_energy_final_kj
  tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(c(
      stay_final$total_system_energy_final_kj,
      move_final$total_system_energy_final_kj
    ))
  )
  input_advantage_kj <-
    sum(move$realized_ingested_energy_kj) -
      sum(stay$realized_ingested_energy_kj)
  movement_disadvantage_kj <-
    sum(move$incremental_movement_expenditure_kj) -
      sum(stay$incremental_movement_expenditure_kj)

  data.frame(
    horizon_days = horizon_days,
    full_model_action = if (
      full_model_move_advantage_kj > tolerance_kj
    ) {
      "move"
    } else {
      "stay"
    },
    full_model_move_advantage_kj = full_model_move_advantage_kj,
    intake_energy_advantage_kj = input_advantage_kj,
    movement_expenditure_disadvantage_kj = movement_disadvantage_kj,
    decomposition_residual_kj = full_model_move_advantage_kj -
      (input_advantage_kj - movement_disadvantage_kj),
    stay_body_energy_reserve_final_kj =
      stay_final$body_energy_reserve_final_kj,
    move_body_energy_reserve_final_kj =
      move_final$body_energy_reserve_final_kj,
    stay_patch_a_biomass_final_kg_dm_ha =
      stay_final$patch_a_biomass_final_kg_dm_ha,
    move_patch_a_biomass_final_kg_dm_ha =
      move_final$patch_a_biomass_final_kg_dm_ha,
    stay_patch_b_biomass_final_kg_dm_ha =
      stay_final$patch_b_biomass_final_kg_dm_ha,
    move_patch_b_biomass_final_kg_dm_ha =
      move_final$patch_b_biomass_final_kg_dm_ha,
    all_accounts_close = all(stay$accounts_close) && all(move$accounts_close),
    row.names = NULL
  )
}

full_model_table <- do.call(rbind, lapply(1:2, compare_horizon))
if (full_model_table$full_model_action[[2L]] != "move") {
  full_model_table <- rbind(
    full_model_table,
    do.call(rbind, lapply(
      3:maximum_planning_horizon_days,
      compare_horizon
    ))
  )
}
row.names(full_model_table) <- NULL

assert_that(
  identical(history$simulation_day[history$selected_action == "move"], 41L) &&
    all(history$accounts_close),
  "the Goal 048 trajectory is reproduced through day 100"
)
assert_that(
  snapshot$state$location$patch_id == "patch_b" &&
    near(snapshot_table$patch_a_biomass_kg_dm_ha, 881.6214, 1e-6) &&
    near(snapshot_table$patch_b_biomass_kg_dm_ha, 500) &&
    near(snapshot_table$body_energy_reserve_kj, 37294.37, 1e-6) &&
    near(
      snapshot_table$stale_patch_a_return_kj_feeding_opportunity_h,
      119.7341,
      1e-6
    ) &&
    near(
      snapshot_table$current_patch_b_return_kj_feeding_opportunity_h,
      149.6676,
      1e-6
    ) &&
    near(
      snapshot_table$recovered_patch_a_return_kj_feeding_opportunity_h,
      200
    ),
  "the opening day-101 trap state matches the accepted trajectory"
)
assert_that(
  identical(
    score_table$selected_action,
    c("stay", "stay", "stay", "move")
  ),
  "only recovered opportunity plus a two-day horizon selects movement"
)
assert_that(
  identical(full_model_table$full_model_action[1:2], c("stay", "move")) &&
    nrow(full_model_table) == 2L,
  "the full model reverses from stay to move at the two-day horizon"
)
assert_that(
  all(full_model_table$all_accounts_close) &&
    max(abs(full_model_table$decomposition_residual_kj)) < 1e-8,
  "all policy accounts close and movement advantage is fully decomposed"
)

cat("Patch-memory information-by-horizon diagnostic passed.\n\n")
cat("Opening day-101 checkpoint:\n")
print(transform(
  snapshot_table,
  body_energy_reserve_kj = round(body_energy_reserve_kj),
  gut_available_energy_kj = round(gut_available_energy_kj),
  patch_a_biomass_kg_dm_ha = round(patch_a_biomass_kg_dm_ha, 2),
  patch_b_biomass_kg_dm_ha = round(patch_b_biomass_kg_dm_ha, 2),
  stale_patch_a_return_kj_feeding_opportunity_h = round(
    stale_patch_a_return_kj_feeding_opportunity_h
  ),
  current_patch_b_return_kj_feeding_opportunity_h = round(
    current_patch_b_return_kj_feeding_opportunity_h
  ),
  recovered_patch_a_return_kj_feeding_opportunity_h = round(
    recovered_patch_a_return_kj_feeding_opportunity_h
  )
), row.names = FALSE)
cat("\nInformation-by-horizon scores:\n")
print(transform(
  score_table,
  current_return_kj_feeding_opportunity_h = round(
    current_return_kj_feeding_opportunity_h
  ),
  destination_return_kj_feeding_opportunity_h = round(
    destination_return_kj_feeding_opportunity_h
  ),
  stay_score_kj = round(stay_score_kj),
  move_score_kj = round(move_score_kj),
  move_score_advantage_kj = round(move_score_advantage_kj)
), row.names = FALSE)
cat("\nFull-model horizon comparison:\n")
print(transform(
  full_model_table,
  full_model_move_advantage_kj = round(full_model_move_advantage_kj),
  intake_energy_advantage_kj = round(intake_energy_advantage_kj),
  movement_expenditure_disadvantage_kj = round(
    movement_expenditure_disadvantage_kj
  ),
  decomposition_residual_kj = round(decomposition_residual_kj),
  stay_body_energy_reserve_final_kj = round(
    stay_body_energy_reserve_final_kj
  ),
  move_body_energy_reserve_final_kj = round(
    move_body_energy_reserve_final_kj
  ),
  stay_patch_a_biomass_final_kg_dm_ha = round(
    stay_patch_a_biomass_final_kg_dm_ha,
    2
  ),
  move_patch_a_biomass_final_kg_dm_ha = round(
    move_patch_a_biomass_final_kg_dm_ha,
    2
  ),
  stay_patch_b_biomass_final_kg_dm_ha = round(
    stay_patch_b_biomass_final_kg_dm_ha,
    2
  ),
  move_patch_b_biomass_final_kg_dm_ha = round(
    move_patch_b_biomass_final_kg_dm_ha,
    2
  )
), row.names = FALSE)
