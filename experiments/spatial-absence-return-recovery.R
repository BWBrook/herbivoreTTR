source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
patch_ids <- c("patch_a", "patch_b")
absence_age_days <- c(0L, 1L, 2L, 3L, 5L, 7L, 10L, 14L, 21L, 28L, 42L, 60L)
residual_biomass_kg_dm_ha <- 500
equilibrium_biomass_kg_dm_ha <- 1000
turnover_fraction_h <- 0.001
density_animals_ha <- 50
route_expenditure_kj <- 900
energy_density_kj_kg_dm <- c(patch_a = 8000, patch_b = 10000)
last_return_kj_feeding_opportunity_h <- c(
  patch_a = 119.7341,
  patch_b = 149.6676
)
best_return_kj_feeding_opportunity_h <- c(
  patch_a = 200,
  patch_b = 250
)

turnover <- herbivoreTTR::new_forage_turnover_parameters(
  equilibrium_biomass_kg_dm_ha,
  turnover_fraction_h
)
coupling <- herbivoreTTR::new_nonspatial_coupling_parameters(
  density_animals_ha,
  residual_biomass_kg_dm_ha
)
landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = patch_ids,
  forage_acquisition_ceiling_kg_dm_h = c(0.025, 0.025),
  route_origin_patch_id = c("patch_a", "patch_b"),
  route_destination_patch_id = c("patch_b", "patch_a"),
  incremental_movement_expenditure_kj = rep(route_expenditure_kj, 2L),
  metabolizable_energy_density_kj_kg_dm = energy_density_kj_kg_dm
)

recovery_run <- herbivoreTTR::run_forage_turnover_days(
  herbivoreTTR::new_forage_biomass_state(residual_biomass_kg_dm_ha),
  turnover,
  max(absence_age_days)
)
recovery_biomass_kg_dm_ha <- c(
  residual_biomass_kg_dm_ha,
  recovery_run$daily$forage_biomass_final_kg_dm_ha
)
names(recovery_biomass_kg_dm_ha) <- 0:max(absence_age_days)

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

run_day <- function(opening_state, closing_patch_id) {
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

run_two_day_policy <- function(destination_patch_id, destination_biomass, action) {
  current_patch_id <- setdiff(patch_ids, destination_patch_id)
  opening_biomass <- setNames(
    rep(residual_biomass_kg_dm_ha, length(patch_ids)),
    patch_ids
  )
  opening_biomass[[destination_patch_id]] <- destination_biomass
  state <- list(
    location = herbivoreTTR::new_patch_location_state(current_patch_id),
    gut = fixture$opening_gut,
    body = fixture$opening_body,
    forage = herbivoreTTR::new_spatial_forage_biomass_state(
      patch_ids,
      opening_biomass
    )
  )
  day_results <- vector("list", 2L)

  for (policy_day in 1:2) {
    closing_patch_id <- if (policy_day == 1L && action == "move") {
      destination_patch_id
    } else {
      state$location$patch_id
    }
    day_results[[policy_day]] <- run_day(state, closing_patch_id)
    state <- day_results[[policy_day]]$final_state
  }

  list(
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
    feeding_opportunity_h = sum(vapply(
      day_results,
      function(result) sum(result$hourly$feeding_opportunity_open),
      numeric(1L)
    )),
    movement_expenditure_kj = sum(vapply(
      day_results,
      function(result) {
        result$daily$total_incremental_movement_expenditure_kj
      },
      numeric(1L)
    )),
    final_total_system_energy_kj = tail(
      day_results,
      1L
    )[[1L]]$daily$total_system_energy_final_kj,
    all_accounts_close = all(vapply(
      day_results,
      accounts_close,
      logical(1L)
    ))
  )
}

evaluate_recovery_age <- function(destination_patch_id, age_days) {
  current_patch_id <- setdiff(patch_ids, destination_patch_id)
  destination_biomass <- recovery_biomass_kg_dm_ha[[as.character(age_days)]]
  accessible_biomass <- herbivoreTTR::derive_accessible_forage_biomass(
    destination_biomass,
    residual_biomass_kg_dm_ha
  )$accessible_forage_biomass_kg_dm_ha
  stay <- run_two_day_policy(
    destination_patch_id,
    destination_biomass,
    "stay"
  )
  move <- run_two_day_policy(
    destination_patch_id,
    destination_biomass,
    "move"
  )
  rejected_belief <- best_return_kj_feeding_opportunity_h[[
    destination_patch_id
  ]] -
    (
      best_return_kj_feeding_opportunity_h[[destination_patch_id]] -
        last_return_kj_feeding_opportunity_h[[destination_patch_id]]
    ) * (1 - turnover_fraction_h)^(24 * age_days)
  actual_move_return <- move$ingested_energy_kj / move$feeding_opportunity_h
  actual_stay_return <- stay$ingested_energy_kj / stay$feeding_opportunity_h

  data.frame(
    destination_patch_id = destination_patch_id,
    current_patch_id = current_patch_id,
    destination_energy_density_kj_kg_dm =
      energy_density_kj_kg_dm[[destination_patch_id]],
    absence_age_days = age_days,
    destination_biomass_kg_dm_ha = destination_biomass,
    destination_accessible_biomass_kg_dm_ha = accessible_biomass,
    destination_accessible_biomass_kg_dm_animal =
      accessible_biomass / density_animals_ha,
    destination_net_production_kg_dm_ha_h =
      turnover_fraction_h * (equilibrium_biomass_kg_dm_ha - destination_biomass),
    rejected_belief_kj_feeding_opportunity_h = rejected_belief,
    actual_destination_return_kj_feeding_opportunity_h = actual_move_return,
    actual_current_return_kj_feeding_opportunity_h = actual_stay_return,
    belief_error_kj_feeding_opportunity_h =
      rejected_belief - actual_move_return,
    move_intake_kg_dm = move$realized_intake_kg_dm,
    stay_intake_kg_dm = stay$realized_intake_kg_dm,
    move_advantage_kj =
      move$final_total_system_energy_kj - stay$final_total_system_energy_kj,
    rejected_score_advantage_kj =
      rejected_belief * 31 -
        last_return_kj_feeding_opportunity_h[[current_patch_id]] * 32 -
        route_expenditure_kj,
    full_model_action = if (
      move$final_total_system_energy_kj > stay$final_total_system_energy_kj
    ) {
      "move"
    } else {
      "stay"
    },
    rejected_belief_action = if (
      rejected_belief * 31 - route_expenditure_kj >
        last_return_kj_feeding_opportunity_h[[current_patch_id]] * 32
    ) {
      "move"
    } else {
      "stay"
    },
    movement_expenditure_kj = move$movement_expenditure_kj,
    accounts_close = stay$all_accounts_close && move$all_accounts_close,
    row.names = NULL
  )
}

recovery_map <- do.call(rbind, lapply(patch_ids, function(destination_patch_id) {
  do.call(rbind, lapply(absence_age_days, function(age_days) {
    evaluate_recovery_age(destination_patch_id, age_days)
  }))
}))
row.names(recovery_map) <- NULL

threshold_rows <- lapply(patch_ids, function(destination_patch_id) {
  rows <- recovery_map[
    recovery_map$destination_patch_id == destination_patch_id,
    ,
    drop = FALSE
  ]
  actual_move_indices <- which(rows$move_advantage_kj > 0)
  belief_move_indices <- which(rows$rejected_score_advantage_kj > 0)
  actual_move_index <- if (length(actual_move_indices) == 0L) {
    NA_integer_
  } else {
    actual_move_indices[[1L]]
  }
  belief_move_index <- if (length(belief_move_indices) == 0L) {
    NA_integer_
  } else {
    belief_move_indices[[1L]]
  }
  data.frame(
    destination_patch_id = destination_patch_id,
    actual_last_stay_age_days = if (is.na(actual_move_index)) {
      max(rows$absence_age_days)
    } else if (actual_move_index == 1L) {
      NA_integer_
    } else {
      rows$absence_age_days[[actual_move_index - 1L]]
    },
    actual_first_move_age_days = if (is.na(actual_move_index)) {
      NA_integer_
    } else {
      rows$absence_age_days[[actual_move_index]]
    },
    belief_last_stay_age_days = if (is.na(belief_move_index)) {
      max(rows$absence_age_days)
    } else if (belief_move_index == 1L) {
      NA_integer_
    } else {
      rows$absence_age_days[[belief_move_index - 1L]]
    },
    belief_first_move_age_days = if (is.na(belief_move_index)) {
      NA_integer_
    } else {
      rows$absence_age_days[[belief_move_index]]
    },
    maximum_absolute_belief_error_kj_feeding_opportunity_h = max(abs(
      rows$belief_error_kj_feeding_opportunity_h
    )),
    row.names = NULL
  )
})
threshold_table <- do.call(rbind, threshold_rows)
row.names(threshold_table) <- NULL

assert_that(
  recovery_biomass_kg_dm_ha[["0"]] == residual_biomass_kg_dm_ha &&
    all(diff(recovery_biomass_kg_dm_ha) > 0) &&
    max(recovery_biomass_kg_dm_ha) < equilibrium_biomass_kg_dm_ha,
  "unvisited forage recovers monotonically from the residual boundary"
)
assert_that(
  all(recovery_map$accounts_close) &&
    all(recovery_map$movement_expenditure_kj == route_expenditure_kj) &&
    all(is.finite(unlist(
      recovery_map[vapply(recovery_map, is.numeric, logical(1L))]
    ))),
  "all two-day cases are finite and close their accounts"
)
assert_that(
  all(recovery_map$destination_accessible_biomass_kg_dm_ha >= 0) &&
    all(recovery_map$rejected_belief_kj_feeding_opportunity_h >=
      last_return_kj_feeding_opportunity_h[
        recovery_map$destination_patch_id
      ]) &&
    all(recovery_map$rejected_belief_kj_feeding_opportunity_h <=
      best_return_kj_feeding_opportunity_h[
        recovery_map$destination_patch_id
      ]),
  "resource and rejected-belief surrogates stay within declared bounds"
)
assert_that(
  identical(
    threshold_table$actual_first_move_age_days,
    c(1L, 0L)
  ) &&
    identical(
      threshold_table$belief_first_move_age_days,
      c(NA_integer_, 2L)
    ),
  "actual and rejected-belief route thresholds remain distinct"
)
patch_a_map <- recovery_map[
  recovery_map$destination_patch_id == "patch_a",
  ,
  drop = FALSE
]
patch_b_map <- recovery_map[
  recovery_map$destination_patch_id == "patch_b",
  ,
  drop = FALSE
]
assert_that(
  all(diff(patch_a_map$actual_destination_return_kj_feeding_opportunity_h) >=
    -1e-10) &&
    all(diff(patch_b_map$actual_destination_return_kj_feeding_opportunity_h) >=
      -1e-10) &&
    near(
      patch_a_map$actual_destination_return_kj_feeding_opportunity_h[
        patch_a_map$absence_age_days >= 2L
      ],
      rep(200, sum(patch_a_map$absence_age_days >= 2L))
    ) &&
    near(
      patch_b_map$actual_destination_return_kj_feeding_opportunity_h[
        patch_b_map$absence_age_days >= 1L
      ],
      rep(
        patch_b_map$actual_destination_return_kj_feeding_opportunity_h[
          patch_b_map$absence_age_days == 1L
        ],
        sum(patch_b_map$absence_age_days >= 1L)
      )
    ) &&
    all(recovery_map$belief_error_kj_feeding_opportunity_h < 0),
  "actual return recovers rapidly while the rejected belief remains low"
)

cat("Absence-to-return recovery diagnostic passed.\n\n")
cat("Route-repayment brackets over the prespecified ages:\n")
print(transform(
  threshold_table,
  maximum_absolute_belief_error_kj_feeding_opportunity_h = round(
    maximum_absolute_belief_error_kj_feeding_opportunity_h
  )
), row.names = FALSE)
cat("\nRecovery map:\n")
print(transform(
  recovery_map[, c(
    "destination_patch_id",
    "absence_age_days",
    "destination_biomass_kg_dm_ha",
    "destination_accessible_biomass_kg_dm_animal",
    "destination_net_production_kg_dm_ha_h",
    "rejected_belief_kj_feeding_opportunity_h",
    "actual_destination_return_kj_feeding_opportunity_h",
    "move_advantage_kj",
    "full_model_action",
    "rejected_belief_action"
  )],
  destination_biomass_kg_dm_ha = round(destination_biomass_kg_dm_ha, 2),
  destination_accessible_biomass_kg_dm_animal = round(
    destination_accessible_biomass_kg_dm_animal,
    3
  ),
  destination_net_production_kg_dm_ha_h = round(
    destination_net_production_kg_dm_ha_h,
    3
  ),
  rejected_belief_kj_feeding_opportunity_h = round(
    rejected_belief_kj_feeding_opportunity_h
  ),
  actual_destination_return_kj_feeding_opportunity_h = round(
    actual_destination_return_kj_feeding_opportunity_h
  ),
  move_advantage_kj = round(move_advantage_kj)
), row.names = FALSE)
