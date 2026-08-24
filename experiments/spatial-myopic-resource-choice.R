source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
patch_ids <- c("patch_a", "patch_b")
static_acquisition_capacity_kg_dm_h <- 0.025
destination_expected_acquisition_rate_kg_dm_h <- 0.025
expected_demand_kg_dm_h <- 0.020
remaining_feeding_opportunity_h <- 16L
cue_interval_h <- 1

physical_landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = patch_ids,
  forage_acquisition_ceiling_kg_dm_h = rep(
    static_acquisition_capacity_kg_dm_h,
    2L
  ),
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
    landscape = physical_landscape,
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
    max(abs(
      result$patch_daily$forage_biomass_balance_residual_kg_dm_ha
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

  availability <- herbivoreTTR::derive_accessible_forage_biomass(
    opening_biomass_kg_dm_ha,
    coupling$residual_unavailable_forage_threshold_kg_dm_ha
  )
  opening_accessible_forage_per_animal_kg_dm <-
    availability$accessible_forage_biomass_kg_dm_ha /
      coupling$herbivore_density_animals_ha
  current_attainable_acquisition_rate_kg_dm_h <- min(
    static_acquisition_capacity_kg_dm_h,
    opening_accessible_forage_per_animal_kg_dm / cue_interval_h
  )

  cue_landscape <- herbivoreTTR::new_known_route_landscape(
    patch_id = patch_ids,
    forage_acquisition_ceiling_kg_dm_h = c(
      current_attainable_acquisition_rate_kg_dm_h,
      destination_expected_acquisition_rate_kg_dm_h
    ),
    route_origin_patch_id = c("patch_a", "patch_b"),
    route_destination_patch_id = c("patch_b", "patch_a"),
    incremental_movement_expenditure_kj = c(900, 900),
    metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
  )
  myopic_decision <- herbivoreTTR::choose_known_patch_for_feeding_bout(
    state = opening_state$location,
    landscape = cue_landscape,
    destination_patch_id = "patch_b",
    expected_dry_matter_demand_kg_dm_h = expected_demand_kg_dm_h,
    remaining_feeding_opportunity_h = remaining_feeding_opportunity_h
  )

  counterfactuals <- list(
    stay = run_action(opening_state, "stay"),
    move = run_action(opening_state, "move")
  )
  full_scores_kj <- vapply(
    counterfactuals,
    function(result) result$daily$total_system_energy_final_kj,
    numeric(1L)
  )
  tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(full_scores_kj)
  )
  oracle_choice <- if (
    full_scores_kj[["move"]] > full_scores_kj[["stay"]] + tolerance_kj
  ) {
    "move"
  } else {
    "stay"
  }
  myopic_choice <- myopic_decision$selected_action
  realized_regret_kj <-
    full_scores_kj[[oracle_choice]] - full_scores_kj[[myopic_choice]]
  if (abs(realized_regret_kj) <= tolerance_kj) {
    realized_regret_kj <- 0
  }

  data.frame(
    patch_a_opening_biomass_kg_dm_ha = opening_biomass_kg_dm_ha,
    current_attainable_acquisition_rate_kg_dm_h =
      current_attainable_acquisition_rate_kg_dm_h,
    destination_expected_acquisition_rate_kg_dm_h =
      destination_expected_acquisition_rate_kg_dm_h,
    myopic_choice = myopic_choice,
    oracle_choice = oracle_choice,
    choices_agree = myopic_choice == oracle_choice,
    myopic_move_score_advantage_kj =
      myopic_decision$move_score_advantage_kj,
    oracle_move_score_advantage_kj =
      full_scores_kj[["move"]] - full_scores_kj[["stay"]],
    realized_regret_kj = realized_regret_kj,
    stay_stock_limited_hours = counterfactuals$stay$daily$
      forage_stock_ceiling_active_hours,
    accounts_close = all(vapply(
      counterfactuals,
      accounts_close,
      logical(1L)
    )),
    row.names = NULL
  )
}

opening_biomass_grid_kg_dm_ha <- seq(450, 550, by = 0.5)
sweep <- do.call(rbind, lapply(
  opening_biomass_grid_kg_dm_ha,
  evaluate_opening_biomass
))

myopic_transition_index <- which(
  head(sweep$myopic_choice, -1L) != tail(sweep$myopic_choice, -1L)
)
oracle_transition_index <- which(
  head(sweep$oracle_choice, -1L) != tail(sweep$oracle_choice, -1L)
)
disagreement <- sweep[!sweep$choices_agree, , drop = FALSE]

move_score_kj <-
  min(
    expected_demand_kg_dm_h,
    destination_expected_acquisition_rate_kg_dm_h
  ) *
    (remaining_feeding_opportunity_h - 1) *
    fixture$food$metabolizable_energy_density_kj_kg_dm -
  900
myopic_switch_rate_kg_dm_h <-
  move_score_kj /
  (
    remaining_feeding_opportunity_h *
      fixture$food$metabolizable_energy_density_kj_kg_dm
  )
myopic_switch_biomass_kg_dm_ha <-
  coupling$residual_unavailable_forage_threshold_kg_dm_ha +
  myopic_switch_rate_kg_dm_h *
    coupling$herbivore_density_animals_ha *
    cue_interval_h

assert_that(
  length(myopic_transition_index) == 1L &&
    near(
      sweep$patch_a_opening_biomass_kg_dm_ha[
        myopic_transition_index
      ],
      500
    ) &&
    near(
      sweep$patch_a_opening_biomass_kg_dm_ha[
        myopic_transition_index + 1L
      ],
      500.5
    ) &&
    near(myopic_switch_biomass_kg_dm_ha, 500.13125),
  "the myopic rule has one analytically attributable move-to-stay boundary"
)
assert_that(
  length(oracle_transition_index) == 1L &&
    near(
      sweep$patch_a_opening_biomass_kg_dm_ha[
        oracle_transition_index
      ],
      497.5
    ) &&
    near(
      sweep$patch_a_opening_biomass_kg_dm_ha[
        oracle_transition_index + 1L
      ],
      498
    ),
  "the full counterfactuals reproduce the accepted oracle boundary"
)
assert_that(
  identical(
    disagreement$patch_a_opening_biomass_kg_dm_ha,
    seq(498, 500, by = 0.5)
  ) &&
    all(disagreement$myopic_choice == "move") &&
    all(disagreement$oracle_choice == "stay"),
  "disagreement is confined to premature movement near the residual threshold"
)
assert_that(
  all(sweep$realized_regret_kj >= 0) &&
    near(
      max(sweep$realized_regret_kj),
      -sweep$oracle_move_score_advantage_kj[
        sweep$patch_a_opening_biomass_kg_dm_ha == 500
      ]
    ),
  paste0(
    "myopic energetic regret is non-negative and bounded by the ",
    "reference move penalty"
  )
)
assert_that(
  all(sweep$accounts_close),
  "every stay and move counterfactual closes its patch and energy accounts"
)

checkpoint_biomass_kg_dm_ha <- c(
  450,
  497.5,
  498,
  499,
  500,
  500.5,
  550
)
checkpoints <- sweep[
  sweep$patch_a_opening_biomass_kg_dm_ha %in%
    checkpoint_biomass_kg_dm_ha,
  c(
    "patch_a_opening_biomass_kg_dm_ha",
    "current_attainable_acquisition_rate_kg_dm_h",
    "myopic_choice",
    "oracle_choice",
    "myopic_move_score_advantage_kj",
    "oracle_move_score_advantage_kj",
    "realized_regret_kj",
    "stay_stock_limited_hours"
  ),
  drop = FALSE
]

cat("Myopic resource-choice diagnostic passed.\n")
cat(
  "The myopic rule switches at ",
  round(myopic_switch_biomass_kg_dm_ha, 2),
  " kg DM/ha; the 0.5-unit grid brackets it between 500.0 and 500.5.\n",
  sep = ""
)
cat(
  "It disagrees with the oracle at ", nrow(disagreement),
  " of ", nrow(sweep), " grid levels, from 498.0 through 500.0 kg DM/ha.\n\n",
  sep = ""
)
print(transform(
  checkpoints,
  patch_a_opening_biomass_kg_dm_ha = round(
    patch_a_opening_biomass_kg_dm_ha,
    1
  ),
  current_attainable_acquisition_rate_kg_dm_h = round(
    current_attainable_acquisition_rate_kg_dm_h,
    3
  ),
  myopic_move_score_advantage_kj = round(
    myopic_move_score_advantage_kj
  ),
  oracle_move_score_advantage_kj = round(
    oracle_move_score_advantage_kj
  ),
  realized_regret_kj = round(realized_regret_kj)
), row.names = FALSE)
