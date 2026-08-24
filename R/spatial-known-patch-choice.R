#' Choose between staying and one known patch
#'
#' Rank staying in the current patch against moving along one known route for a
#' declared remaining feeding bout. Expected dry-matter demand is held constant
#' across the bout. Movement loses the route-duration portion of feeding
#' opportunity and pays the route's incremental energy expenditure. Maintenance
#' and ordinary activity are omitted because they are common to both options.
#' Expected intake in each patch is converted with that patch's declared
#' metabolizable-energy density.
#'
#' The score is a transparent choice heuristic, not a forecast of subsequent
#' appetite feedback or realized body-energy change. A tie within scale-aware
#' arithmetic tolerance selects staying.
#'
#' @param state A patch-location state created by
#'   [new_patch_location_state()].
#' @param landscape A known-route landscape created by
#'   [new_known_route_landscape()].
#' @param destination_patch_id One alternative destination patch identifier.
#' @param expected_dry_matter_demand_kg_dm_h One finite, non-negative expected
#'   demand rate held constant across the remaining bout, in kilograms dry
#'   matter per hour.
#' @param remaining_feeding_opportunity_h One finite whole number from 1 to 24
#'   giving the feeding-opportunity hours remaining before travel is charged.
#'
#' @return A plain named list containing the two opportunity calculations,
#'   scores, score difference, and selected action and patch.
#' @export
choose_known_patch_for_feeding_bout <- function(
  state,
  landscape,
  destination_patch_id,
  expected_dry_matter_demand_kg_dm_h,
  remaining_feeding_opportunity_h
) {
  .validate_patch_location_state(state)
  .validate_known_route_landscape(landscape)
  .validate_nonnegative_numeric_scalar(
    expected_dry_matter_demand_kg_dm_h,
    "expected_dry_matter_demand_kg_dm_h"
  )
  if (
    !.is_whole_number(remaining_feeding_opportunity_h) ||
      length(remaining_feeding_opportunity_h) != 1L ||
      as.double(remaining_feeding_opportunity_h) < 1 ||
      as.double(remaining_feeding_opportunity_h) > 24
  ) {
    stop(
      paste0(
        "`remaining_feeding_opportunity_h` must be one finite whole number ",
        "from 1 to 24."
      ),
      call. = FALSE
    )
  }

  movement <- step_known_route_movement(
    state,
    landscape,
    destination_patch_id
  )
  patch_ids <- landscape$patches$patch_id
  current_index <- match(state$patch_id, patch_ids)
  destination_index <- match(destination_patch_id, patch_ids)
  current_capacity_kg_dm_h <-
    landscape$patches$forage_acquisition_ceiling_kg_dm_h[[current_index]]
  destination_capacity_kg_dm_h <-
    landscape$patches$
      forage_acquisition_ceiling_kg_dm_h[[destination_index]]
  current_energy_density_kj_kg_dm <-
    landscape$patches$
      metabolizable_energy_density_kj_kg_dm[[current_index]]
  destination_energy_density_kj_kg_dm <-
    landscape$patches$
      metabolizable_energy_density_kj_kg_dm[[destination_index]]
  demand_kg_dm_h <- as.double(expected_dry_matter_demand_kg_dm_h)
  remaining_h <- as.double(remaining_feeding_opportunity_h)
  travel_duration_h <- as.double(movement$fluxes$travel_duration_h)
  movement_expenditure_kj <- as.double(
    movement$fluxes$incremental_movement_expenditure_kj
  )
  stay_feeding_opportunity_h <- remaining_h
  move_feeding_opportunity_h <- max(0, remaining_h - travel_duration_h)
  stay_expected_intake_kg_dm <-
    min(demand_kg_dm_h, current_capacity_kg_dm_h) *
      stay_feeding_opportunity_h
  move_expected_intake_kg_dm <-
    min(demand_kg_dm_h, destination_capacity_kg_dm_h) *
      move_feeding_opportunity_h
  stay_feeding_bout_score_kj <-
    stay_expected_intake_kg_dm * current_energy_density_kj_kg_dm
  move_feeding_bout_score_kj <-
    move_expected_intake_kg_dm * destination_energy_density_kj_kg_dm -
      movement_expenditure_kj
  move_score_advantage_kj <-
    move_feeding_bout_score_kj - stay_feeding_bout_score_kj
  score_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(stay_feeding_bout_score_kj),
    abs(move_feeding_bout_score_kj)
  )
  selected_action <- if (move_score_advantage_kj > score_tolerance_kj) {
    "move"
  } else {
    "stay"
  }
  selected_patch_id <- if (selected_action == "move") {
    as.character(destination_patch_id)
  } else {
    state$patch_id
  }

  list(
    current_patch_id = state$patch_id,
    destination_patch_id = as.character(destination_patch_id),
    expected_dry_matter_demand_kg_dm_h = demand_kg_dm_h,
    remaining_feeding_opportunity_h = remaining_h,
    current_patch_forage_acquisition_ceiling_kg_dm_h =
      current_capacity_kg_dm_h,
    destination_patch_forage_acquisition_ceiling_kg_dm_h =
      destination_capacity_kg_dm_h,
    current_patch_metabolizable_energy_density_kj_kg_dm =
      current_energy_density_kj_kg_dm,
    destination_patch_metabolizable_energy_density_kj_kg_dm =
      destination_energy_density_kj_kg_dm,
    travel_duration_h = travel_duration_h,
    incremental_movement_expenditure_kj = movement_expenditure_kj,
    stay_feeding_opportunity_h = stay_feeding_opportunity_h,
    move_feeding_opportunity_h = move_feeding_opportunity_h,
    stay_expected_dry_matter_intake_kg_dm = stay_expected_intake_kg_dm,
    move_expected_dry_matter_intake_kg_dm = move_expected_intake_kg_dm,
    stay_feeding_bout_score_kj = stay_feeding_bout_score_kj,
    move_feeding_bout_score_kj = move_feeding_bout_score_kj,
    move_score_advantage_kj = move_score_advantage_kj,
    selected_action = selected_action,
    selected_patch_id = selected_patch_id
  )
}
