source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
current_patch_id <- "current_patch"
destination_patch_id <- "adequate_destination"
destination_energy_density_kj_kg_dm <- 10000
route_expenditure_kj <- 900

new_quality_landscape <- function(current_energy_density_kj_kg_dm) {
  herbivoreTTR::new_known_route_landscape(
    patch_id = c(current_patch_id, destination_patch_id),
    forage_acquisition_ceiling_kg_dm_h = c(0.025, 0.025),
    route_origin_patch_id = c(current_patch_id, destination_patch_id),
    route_destination_patch_id = c(destination_patch_id, current_patch_id),
    incremental_movement_expenditure_kj = rep(route_expenditure_kj, 2L),
    metabolizable_energy_density_kj_kg_dm = c(
      current_energy_density_kj_kg_dm,
      destination_energy_density_kj_kg_dm
    )
  )
}

run_action <- function(landscape, action) {
  closing_patch_id <- if (action == "move") {
    rep(destination_patch_id, 24L)
  } else {
    rep(current_patch_id, 24L)
  }

  herbivoreTTR::run_prescribed_spatial_energy_day(
    initial_location_state =
      herbivoreTTR::new_patch_location_state(current_patch_id),
    landscape = landscape,
    itinerary = herbivoreTTR::new_prescribed_patch_itinerary(
      fixture$hour_of_day,
      closing_patch_id
    ),
    initial_gut_state = fixture$opening_gut,
    initial_body_state = fixture$opening_body,
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    appetite_parameters = fixture$appetite,
    appetite_reference_schedule = fixture$appetite_reference,
    routine_activity_schedule = fixture$activity
  )
}

accounts_close <- function(result) {
  max(abs(result$hourly$system_energy_balance_residual_kj)) < 1e-9 &&
    abs(result$daily$system_energy_balance_residual_kj) < 1e-9
}

evaluate_current_quality <- function(current_energy_density_kj_kg_dm) {
  landscape <- new_quality_landscape(current_energy_density_kj_kg_dm)
  quality_aware_choice <-
    herbivoreTTR::choose_known_patch_for_feeding_bout(
      state = herbivoreTTR::new_patch_location_state(current_patch_id),
      landscape = landscape,
      destination_patch_id = destination_patch_id,
      expected_dry_matter_demand_kg_dm_h = 0.020,
      remaining_feeding_opportunity_h = 16L
    )
  stay <- run_action(landscape, "stay")
  move <- run_action(landscape, "move")
  move_minus_stay_kj <-
    move$daily$total_system_energy_final_kj -
      stay$daily$total_system_energy_final_kj
  tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(c(
      stay$daily$total_system_energy_final_kj,
      move$daily$total_system_energy_final_kj
    ))
  )
  oracle_choice <- if (move_minus_stay_kj > tolerance_kj) {
    "move"
  } else {
    "stay"
  }
  intake_energy_gain_from_move_kj <-
    move$daily$total_realized_ingested_available_energy_kj -
      stay$daily$total_realized_ingested_available_energy_kj
  oracle_selected_change_kj <- max(
    stay$daily$observed_total_system_energy_change_kj,
    move$daily$observed_total_system_energy_change_kj
  )
  helper_selected_change_kj <- if (
    quality_aware_choice$selected_action == "move"
  ) {
    move$daily$observed_total_system_energy_change_kj
  } else {
    stay$daily$observed_total_system_energy_change_kj
  }

  data.frame(
    current_energy_density_kj_kg_dm = current_energy_density_kj_kg_dm,
    destination_energy_density_kj_kg_dm =
      destination_energy_density_kj_kg_dm,
    quality_aware_choice = quality_aware_choice$selected_action,
    helper_move_score_advantage_kj =
      quality_aware_choice$move_score_advantage_kj,
    oracle_choice = oracle_choice,
    stay_intake_kg_dm = stay$daily$realized_dry_matter_intake_kg_dm,
    move_intake_kg_dm = move$daily$realized_dry_matter_intake_kg_dm,
    stay_ingested_energy_kj =
      stay$daily$total_realized_ingested_available_energy_kj,
    move_ingested_energy_kj =
      move$daily$total_realized_ingested_available_energy_kj,
    stay_combined_change_kj =
      stay$daily$observed_total_system_energy_change_kj,
    move_combined_change_kj =
      move$daily$observed_total_system_energy_change_kj,
    intake_energy_gain_from_move_kj = intake_energy_gain_from_move_kj,
    route_expenditure_kj =
      move$daily$total_incremental_movement_expenditure_kj,
    move_minus_stay_kj = move_minus_stay_kj,
    helper_realized_regret_kj =
      oracle_selected_change_kj - helper_selected_change_kj,
    score_identity_residual_kj = move_minus_stay_kj -
      (intake_energy_gain_from_move_kj - route_expenditure_kj),
    move_feeding_time_lost_h = move$daily$feeding_time_lost_h,
    stay_acquisition_limited_hours =
      stay$daily$forage_acquisition_ceiling_active_hours,
    move_acquisition_limited_hours =
      move$daily$forage_acquisition_ceiling_active_hours,
    accounts_close = accounts_close(stay) && accounts_close(move),
    row.names = NULL
  )
}

current_quality_grid_kj_kg_dm <- seq(4000, 10000, by = 100)
sweep <- do.call(rbind, lapply(
  current_quality_grid_kj_kg_dm,
  evaluate_current_quality
))

oracle_transition_index <- which(
  head(sweep$oracle_choice, -1L) != tail(sweep$oracle_choice, -1L)
)
oracle_last_move_density_kj_kg_dm <- max(
  sweep$current_energy_density_kj_kg_dm[sweep$oracle_choice == "move"]
)
oracle_first_stay_density_kj_kg_dm <- min(
  sweep$current_energy_density_kj_kg_dm[sweep$oracle_choice == "stay"]
)
helper_transition_index <- which(
  head(sweep$quality_aware_choice, -1L) !=
    tail(sweep$quality_aware_choice, -1L)
)
helper_last_move_density_kj_kg_dm <- max(
  sweep$current_energy_density_kj_kg_dm[
    sweep$quality_aware_choice == "move"
  ]
)
helper_first_stay_density_kj_kg_dm <- min(
  sweep$current_energy_density_kj_kg_dm[
    sweep$quality_aware_choice == "stay"
  ]
)

assert_that(
  length(oracle_transition_index) == 1L &&
    all(sweep$oracle_choice[seq_len(oracle_transition_index)] == "move") &&
    all(sweep$oracle_choice[-seq_len(oracle_transition_index)] == "stay"),
  "the quality-aware oracle has one move-to-stay transition"
)
assert_that(
  identical(oracle_last_move_density_kj_kg_dm, 7300) &&
    identical(oracle_first_stay_density_kj_kg_dm, 7400),
  "the synthetic quality switch is bracketed from 7,300 to 7,400 kJ/kg DM"
)
assert_that(
  max(diff(sweep$move_minus_stay_kj)) < 1e-8,
  "movement advantage declines as current-patch quality improves"
)
assert_that(
  length(helper_transition_index) == 1L &&
    identical(helper_last_move_density_kj_kg_dm, 6500) &&
    identical(helper_first_stay_density_kj_kg_dm, 6600),
  "the minimal quality-aware helper switches from move to stay once"
)
assert_that(
  max(diff(sweep$helper_move_score_advantage_kj)) < 1e-8,
  "the helper's movement advantage declines with current-patch quality"
)
disagreement_density_kj_kg_dm <-
  sweep$current_energy_density_kj_kg_dm[
    sweep$quality_aware_choice != sweep$oracle_choice
  ]
assert_that(
  identical(disagreement_density_kj_kg_dm, seq(6600, 7300, by = 100)) &&
    all(sweep$helper_realized_regret_kj >= -1e-9) &&
    near(max(sweep$helper_realized_regret_kj), 167.7092, 1e-6),
  "the helper stays too early with bounded realized regret"
)
assert_that(
  near(sweep$route_expenditure_kj, rep(900, nrow(sweep))) &&
    identical(sweep$move_feeding_time_lost_h, rep(1, nrow(sweep))) &&
    all(sweep$stay_acquisition_limited_hours == 0L) &&
    all(sweep$move_acquisition_limited_hours == 0L) &&
    max(abs(sweep$score_identity_residual_kj)) < 1e-8,
  "matched movement, non-limiting acquisition, and score decomposition"
)
assert_that(
  max(abs(diff(sweep$move_combined_change_kj))) < 1e-8,
  "the fixed-destination move outcome is invariant to current-patch quality"
)
assert_that(
  all(sweep$accounts_close),
  "every stay and move counterfactual closes its energy accounts"
)

accepted_contrast <- sweep[
  sweep$current_energy_density_kj_kg_dm == 8000,
  ,
  drop = FALSE
]
assert_that(
  identical(accepted_contrast$quality_aware_choice, "stay") &&
    identical(accepted_contrast$oracle_choice, "stay") &&
    near(accepted_contrast$helper_realized_regret_kj, 0) &&
    near(accepted_contrast$stay_combined_change_kj, -412.0268, 1e-6) &&
    near(accepted_contrast$move_combined_change_kj, -549.4436, 1e-6) &&
    near(accepted_contrast$move_minus_stay_kj, -137.4168, 1e-6),
  "the accepted 8,000 versus 10,000 contrast favours staying"
)

checkpoint_densities_kj_kg_dm <- c(
  4000, 6500, 6600, 7000, 7300, 7400, 8000, 10000
)
checkpoints <- sweep[
  sweep$current_energy_density_kj_kg_dm %in%
    checkpoint_densities_kj_kg_dm,
  c(
    "current_energy_density_kj_kg_dm",
    "destination_energy_density_kj_kg_dm",
    "quality_aware_choice",
    "oracle_choice",
    "stay_intake_kg_dm",
    "move_intake_kg_dm",
    "stay_combined_change_kj",
    "move_combined_change_kj",
    "move_minus_stay_kj",
    "helper_realized_regret_kj"
  ),
  drop = FALSE
]

cat("Food-quality stay-move boundary diagnostic passed.\n")
cat(
  "The oracle moves through ", oracle_last_move_density_kj_kg_dm,
  " and stays from ", oracle_first_stay_density_kj_kg_dm,
  " kJ/kg DM.\n",
  sep = ""
)
cat(
  "The minimal helper moves through ", helper_last_move_density_kj_kg_dm,
  " and stays from ", helper_first_stay_density_kj_kg_dm,
  " kJ/kg DM.\n\n",
  sep = ""
)
print(transform(
  checkpoints,
  stay_intake_kg_dm = round(stay_intake_kg_dm, 3),
  move_intake_kg_dm = round(move_intake_kg_dm, 3),
  stay_combined_change_kj = round(stay_combined_change_kj),
  move_combined_change_kj = round(move_combined_change_kj),
  move_minus_stay_kj = round(move_minus_stay_kj),
  helper_realized_regret_kj = round(helper_realized_regret_kj)
), row.names = FALSE)
