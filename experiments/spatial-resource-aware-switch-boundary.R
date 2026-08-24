source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
patch_ids <- c("patch_a", "patch_b")
landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = patch_ids,
  forage_acquisition_ceiling_kg_dm_h = c(0.025, 0.025),
  route_origin_patch_id = c("patch_a", "patch_b"),
  route_destination_patch_id = c("patch_b", "patch_a"),
  incremental_movement_expenditure_kj = c(900, 900),
  metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
)
turnover <- herbivoreTTR::new_forage_turnover_parameters(1000, 0.001)
coupling <- herbivoreTTR::new_nonspatial_coupling_parameters(10, 500)

run_action <- function(opening_state, action) {
  closing_patch_id <- if (action == "move") {
    rep("patch_b", 24L)
  } else {
    rep("patch_a", 24L)
  }

  herbivoreTTR::run_prescribed_spatial_coupled_energy_day(
    initial_location_state = opening_state$location,
    landscape = landscape,
    itinerary = herbivoreTTR::new_prescribed_patch_itinerary(
      fixture$hour_of_day,
      closing_patch_id
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
    abs(result$daily$herbivore_forage_coupling_residual_kg_dm_ha) <
      1e-10 &&
    max(abs(result$hourly$system_energy_balance_residual_kj)) < 1e-8 &&
    abs(result$daily$system_energy_balance_residual_kj) < 1e-8
}

evaluate_opening_biomass <- function(opening_biomass_kg_dm_ha) {
  opening_state <- list(
    location = herbivoreTTR::new_patch_location_state("patch_a"),
    gut = fixture$opening_gut,
    body = fixture$opening_body,
    forage = herbivoreTTR::new_spatial_forage_biomass_state(
      patch_ids,
      c(opening_biomass_kg_dm_ha, 1000)
    )
  )
  stay <- run_action(opening_state, "stay")
  move <- run_action(opening_state, "move")
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
  intake_gain_from_move_kj <-
    (move$daily$realized_dry_matter_intake_kg_dm -
      stay$daily$realized_dry_matter_intake_kg_dm) *
    fixture$food$metabolizable_energy_density_kj_kg_dm
  route_expenditure_kj <-
    move$daily$total_incremental_movement_expenditure_kj

  data.frame(
    patch_a_opening_biomass_kg_dm_ha = opening_biomass_kg_dm_ha,
    oracle_choice = oracle_choice,
    stay_intake_kg_dm = stay$daily$realized_dry_matter_intake_kg_dm,
    move_intake_kg_dm = move$daily$realized_dry_matter_intake_kg_dm,
    intake_gain_from_move_kj = intake_gain_from_move_kj,
    route_expenditure_kj = route_expenditure_kj,
    move_minus_stay_kj = move_minus_stay_kj,
    move_feeding_time_lost_h = move$daily$feeding_time_lost_h,
    stay_stock_limited_hours =
      stay$daily$forage_stock_ceiling_active_hours,
    move_stock_limited_hours =
      move$daily$forage_stock_ceiling_active_hours,
    score_identity_residual_kj = move_minus_stay_kj -
      (intake_gain_from_move_kj - route_expenditure_kj),
    accounts_close = accounts_close(stay) && accounts_close(move),
    row.names = NULL
  )
}

opening_biomass_grid_kg_dm_ha <- seq(450, 550, by = 0.5)
sweep <- do.call(rbind, lapply(
  opening_biomass_grid_kg_dm_ha,
  evaluate_opening_biomass
))

transition_index <- which(
  head(sweep$oracle_choice, -1L) != tail(sweep$oracle_choice, -1L)
)
last_move_biomass_kg_dm_ha <- max(
  sweep$patch_a_opening_biomass_kg_dm_ha[
    sweep$oracle_choice == "move"
  ]
)
first_stay_biomass_kg_dm_ha <- min(
  sweep$patch_a_opening_biomass_kg_dm_ha[
    sweep$oracle_choice == "stay"
  ]
)

assert_that(
  length(transition_index) == 1L &&
    all(sweep$oracle_choice[seq_len(transition_index)] == "move") &&
    all(sweep$oracle_choice[-seq_len(transition_index)] == "stay"),
  "the resource-aware oracle has one move-to-stay transition"
)
assert_that(
  near(last_move_biomass_kg_dm_ha, 497.5) &&
    near(first_stay_biomass_kg_dm_ha, 498.0),
  "the accepted synthetic switch is bracketed between 497.5 and 498.0 kg DM/ha"
)
assert_that(
  max(diff(sweep$move_minus_stay_kj)) < 1e-8,
  "movement's energetic advantage is non-increasing with occupied-patch biomass"
)
assert_that(
  near(sweep$route_expenditure_kj, rep(900, nrow(sweep))) &&
    identical(sweep$move_feeding_time_lost_h, rep(1, nrow(sweep))) &&
    identical(sweep$move_stock_limited_hours, rep(0L, nrow(sweep))) &&
    max(abs(sweep$score_identity_residual_kj)) < 1e-8,
  "each move loses one feeding hour and the score closes to intake minus route cost"
)
assert_that(
  all(sweep$accounts_close),
  "every stay and move counterfactual closes its patch and energy accounts"
)

checkpoint_biomass_kg_dm_ha <- c(450, 490, 497.5, 498, 500, 550)
checkpoints <- sweep[
  sweep$patch_a_opening_biomass_kg_dm_ha %in%
    checkpoint_biomass_kg_dm_ha,
  c(
    "patch_a_opening_biomass_kg_dm_ha",
    "oracle_choice",
    "stay_intake_kg_dm",
    "move_intake_kg_dm",
    "intake_gain_from_move_kj",
    "route_expenditure_kj",
    "move_minus_stay_kj",
    "stay_stock_limited_hours"
  ),
  drop = FALSE
]

cat("Resource-aware stay-move switch-boundary diagnostic passed.\n")
cat("Patch A alone varied from 450 to 550 kg DM/ha in 0.5-unit steps.\n")
cat(
  "The oracle moves through ", last_move_biomass_kg_dm_ha,
  " and stays from ", first_stay_biomass_kg_dm_ha,
  " kg DM/ha.\n\n",
  sep = ""
)
print(transform(
  checkpoints,
  patch_a_opening_biomass_kg_dm_ha = round(
    patch_a_opening_biomass_kg_dm_ha,
    1
  ),
  stay_intake_kg_dm = round(stay_intake_kg_dm, 3),
  move_intake_kg_dm = round(move_intake_kg_dm, 3),
  intake_gain_from_move_kj = round(intake_gain_from_move_kj),
  route_expenditure_kj = round(route_expenditure_kj),
  move_minus_stay_kj = round(move_minus_stay_kj)
), row.names = FALSE)
