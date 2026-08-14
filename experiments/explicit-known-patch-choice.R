source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = c("limited_patch", "adequate_patch"),
  forage_acquisition_ceiling_kg_dm_h = c(0.015, 0.025),
  route_origin_patch_id = c("limited_patch", "adequate_patch"),
  route_destination_patch_id = c("adequate_patch", "limited_patch"),
  incremental_movement_expenditure_kj = c(100, 100)
)
decision_hour <- 16L
remaining_feeding_opportunity_h <- 8L
expected_demand_kg_dm_h <- 0.020

run_action <- function(initial_patch_id, destination_patch_id, action) {
  closing_patch_id <- rep(initial_patch_id, 24L)
  if (action == "move") {
    closing_patch_id[fixture$hour_of_day >= decision_hour] <-
      destination_patch_id
  }

  herbivoreTTR::run_prescribed_spatial_energy_day(
    initial_location_state =
      herbivoreTTR::new_patch_location_state(initial_patch_id),
    landscape = landscape,
    itinerary = herbivoreTTR::new_prescribed_patch_itinerary(
      fixture$hour_of_day,
      closing_patch_id
    ),
    initial_gut_state = fixture$opening_gut,
    initial_body_state = fixture$opening_body,
    gut_parameters = fixture$gut,
    body_parameters = fixture$body,
    food_parameters = fixture$food,
    appetite_parameters = fixture$appetite,
    appetite_reference_schedule = fixture$appetite_reference,
    routine_activity_schedule = fixture$activity
  )
}

evaluate_decision <- function(initial_patch_id, destination_patch_id) {
  decision <- herbivoreTTR::choose_known_patch_for_feeding_bout(
    state = herbivoreTTR::new_patch_location_state(initial_patch_id),
    landscape = landscape,
    destination_patch_id = destination_patch_id,
    food_parameters = fixture$food,
    expected_dry_matter_demand_kg_dm_h = expected_demand_kg_dm_h,
    remaining_feeding_opportunity_h = remaining_feeding_opportunity_h
  )
  counterfactuals <- list(
    stay = run_action(initial_patch_id, destination_patch_id, "stay"),
    move = run_action(initial_patch_id, destination_patch_id, "move")
  )

  list(
    decision = decision,
    selected = counterfactuals[[decision$selected_action]],
    rejected = counterfactuals[[if (decision$selected_action == "move") {
      "stay"
    } else {
      "move"
    }]],
    counterfactuals = counterfactuals
  )
}

cases <- list(
  limited_current = evaluate_decision("limited_patch", "adequate_patch"),
  adequate_current = evaluate_decision("adequate_patch", "limited_patch")
)

assert_that(
  identical(
    vapply(cases, function(x) x$decision$selected_action, character(1L)),
    c(limited_current = "move", adequate_current = "stay")
  ),
  "limited chooses movement and adequate chooses staying"
)
assert_that(
  near(cases$limited_current$decision$move_score_advantage_kj, 100) &&
    near(cases$adequate_current$decision$move_score_advantage_kj, -650),
  "fixed feeding-bout score differences"
)
assert_that(
  all(vapply(
    cases,
    function(x) {
      x$selected$daily$observed_total_system_energy_change_kj >
        x$rejected$daily$observed_total_system_energy_change_kj
    },
    logical(1L)
  )),
  "selected actions outperform rejected full-model counterfactuals"
)
assert_that(
  near(
    cases$limited_current$selected$daily$
      observed_total_system_energy_change_kj,
    -480.953386355914
  ) &&
    near(
      cases$limited_current$rejected$daily$
        observed_total_system_energy_change_kj,
      -800
    ) &&
    near(
      cases$adequate_current$selected$daily$
        observed_total_system_energy_change_kj,
      0
    ) &&
    near(
      cases$adequate_current$rejected$daily$
        observed_total_system_energy_change_kj,
      -650
    ),
  "fixed selected and rejected full-model outcomes"
)
assert_that(
  all(vapply(
    cases,
    function(x) {
      all(vapply(
        x$counterfactuals,
        function(result) {
          max(abs(result$hourly$system_energy_balance_residual_kj)) < 1e-9 &&
            abs(result$daily$system_energy_balance_residual_kj) < 1e-9
        },
        logical(1L)
      ))
    },
    logical(1L)
  )),
  "all prescribed counterfactual energy accounts"
)

summary_table <- data.frame(
  decision_case = names(cases),
  current_patch = vapply(
    cases,
    function(x) x$decision$current_patch_id,
    character(1L)
  ),
  alternative_patch = vapply(
    cases,
    function(x) x$decision$destination_patch_id,
    character(1L)
  ),
  stay_score_kj = vapply(
    cases,
    function(x) x$decision$stay_feeding_bout_score_kj,
    numeric(1L)
  ),
  move_score_kj = vapply(
    cases,
    function(x) x$decision$move_feeding_bout_score_kj,
    numeric(1L)
  ),
  selected_action = vapply(
    cases,
    function(x) x$decision$selected_action,
    character(1L)
  ),
  selected_combined_change_kj = round(vapply(
    cases,
    function(x) x$selected$daily$observed_total_system_energy_change_kj,
    numeric(1L)
  )),
  rejected_combined_change_kj = round(vapply(
    cases,
    function(x) x$rejected$daily$observed_total_system_energy_change_kj,
    numeric(1L)
  )),
  realized_selected_advantage_kj = round(vapply(
    cases,
    function(x) {
      x$selected$daily$observed_total_system_energy_change_kj -
        x$rejected$daily$observed_total_system_energy_change_kj
    },
    numeric(1L)
  )),
  row.names = NULL
)

cat("Explicit known-patch choice diagnostic passed.\n")
print(summary_table, row.names = FALSE)
