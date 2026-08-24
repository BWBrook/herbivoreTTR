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

reference_opening_state <- list(
  location = herbivoreTTR::new_patch_location_state("patch_a"),
  gut = fixture$opening_gut,
  body = fixture$opening_body,
  forage = herbivoreTTR::new_spatial_forage_biomass_state(
    patch_ids,
    c(1000, 1000)
  )
)

mild_opening_state <- reference_opening_state
for (simulation_day in seq_len(30L)) {
  mild_opening_state <- run_action(mild_opening_state, "stay")$final_state
}
severe_opening_state <- reference_opening_state
severe_opening_state$forage <-
  herbivoreTTR::new_spatial_forage_biomass_state(
    patch_ids,
    c(450, 1000)
  )

evaluate_case <- function(opening_state) {
  static_choice <- herbivoreTTR::choose_known_patch_for_feeding_bout(
    state = opening_state$location,
    landscape = landscape,
    destination_patch_id = "patch_b",
    expected_dry_matter_demand_kg_dm_h = 0.020,
    remaining_feeding_opportunity_h = 16L
  )
  counterfactuals <- list(
    stay = run_action(opening_state, "stay"),
    move = run_action(opening_state, "move")
  )
  scores_kj <- vapply(
    counterfactuals,
    function(x) x$daily$total_system_energy_final_kj,
    numeric(1L)
  )
  tolerance_kj <- 100 * .Machine$double.eps * max(1, abs(scores_kj))
  oracle_action <- if (
    scores_kj[["move"]] > scores_kj[["stay"]] + tolerance_kj
  ) {
    "move"
  } else {
    "stay"
  }

  list(
    opening_state = opening_state,
    static_choice = static_choice,
    counterfactuals = counterfactuals,
    oracle_action = oracle_action,
    oracle_selected = counterfactuals[[oracle_action]],
    oracle_rejected = counterfactuals[[if (oracle_action == "move") {
      "stay"
    } else {
      "move"
    }]]
  )
}

cases <- list(
  mild_depletion = evaluate_case(mild_opening_state),
  severe_depletion = evaluate_case(severe_opening_state)
)

opening_biomass <- function(case, patch_id) {
  state <- case$opening_state$forage
  state$forage_biomass_kg_dm_ha[state$patch_id == patch_id]
}

assert_that(
  opening_biomass(cases$mild_depletion, "patch_a") > 931.5 &&
    opening_biomass(cases$mild_depletion, "patch_a") < 931.6 &&
    identical(opening_biomass(cases$mild_depletion, "patch_b"), 1000),
  "the mild case reproduces the accepted day-30 patch state"
)
assert_that(
  identical(
    vapply(cases, function(x) x$static_choice$selected_action, character(1L)),
    c(mild_depletion = "stay", severe_depletion = "stay")
  ),
  "the equal-capacity static null stays in both cases"
)
assert_that(
  identical(
    vapply(cases, function(x) x$oracle_action, character(1L)),
    c(mild_depletion = "stay", severe_depletion = "move")
  ),
  "the dynamic oracle stays under mild depletion and moves under severe depletion"
)
assert_that(
  all(vapply(
    cases,
    function(x) {
      x$oracle_selected$daily$total_system_energy_final_kj >
        x$oracle_rejected$daily$total_system_energy_final_kj
    },
    logical(1L)
  )),
  "oracle-selected actions outperform rejected counterfactuals"
)
assert_that(
  cases$mild_depletion$counterfactuals$stay$daily$
      forage_stock_ceiling_active_hours == 0L &&
    cases$severe_depletion$counterfactuals$stay$daily$
      forage_stock_ceiling_active_hours == 16L,
  "resource limitation is absent in the mild case and binds in the severe stay"
)
assert_that(
  all(vapply(
    cases,
    function(case) {
      all(vapply(
        case$counterfactuals,
        function(result) {
          max(abs(
            result$patch_hourly$forage_biomass_balance_residual_kg_dm_ha
          )) < 1e-10 &&
            max(abs(result$hourly$system_energy_balance_residual_kj)) < 1e-8 &&
            abs(result$daily$herbivore_forage_coupling_residual_kg_dm_ha) <
              1e-10 &&
            abs(result$daily$system_energy_balance_residual_kj) < 1e-8
        },
        logical(1L)
      ))
    },
    logical(1L)
  )),
  "all patch, coupling, and animal counterfactual accounts close"
)

summary_table <- do.call(rbind, lapply(names(cases), function(case_name) {
  case <- cases[[case_name]]
  stay <- case$counterfactuals$stay$daily
  move <- case$counterfactuals$move$daily
  selected_change_kj <-
    case$oracle_selected$daily$observed_total_system_energy_change_kj
  rejected_change_kj <-
    case$oracle_rejected$daily$observed_total_system_energy_change_kj

  data.frame(
    decision_case = case_name,
    patch_a_opening_biomass_kg_dm_ha =
      opening_biomass(case, "patch_a"),
    static_choice = case$static_choice$selected_action,
    oracle_choice = case$oracle_action,
    stay_intake_kg_dm = stay$realized_dry_matter_intake_kg_dm,
    move_intake_kg_dm = move$realized_dry_matter_intake_kg_dm,
    stay_combined_change_kj = round(
      stay$observed_total_system_energy_change_kj
    ),
    move_combined_change_kj = round(
      move$observed_total_system_energy_change_kj
    ),
    selected_advantage_kj = round(
      selected_change_kj - rejected_change_kj
    ),
    stay_stock_limited_hours = stay$forage_stock_ceiling_active_hours,
    row.names = NULL
  )
}))

cat("Single resource-aware patch-choice diagnostic passed.\n")
cat("The oracle is a perfect-state, perfect-model benchmark, not behavior.\n")
print(transform(
  summary_table,
  patch_a_opening_biomass_kg_dm_ha = round(
    patch_a_opening_biomass_kg_dm_ha,
    2
  ),
  stay_intake_kg_dm = round(stay_intake_kg_dm, 3),
  move_intake_kg_dm = round(move_intake_kg_dm, 3)
), row.names = FALSE)
