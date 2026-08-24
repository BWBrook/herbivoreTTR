source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
first_feeding_window <- 0:7
second_feeding_window <- 16:23
movement_hour <- 16L
patch_acquisition_rate_kg_dm_h <- c(
  limited_patch = 0.015,
  adequate_patch = 0.025
)

landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = names(patch_acquisition_rate_kg_dm_h),
  forage_acquisition_ceiling_kg_dm_h =
    unname(patch_acquisition_rate_kg_dm_h),
  route_origin_patch_id = c("limited_patch", "adequate_patch"),
  route_destination_patch_id = c("adequate_patch", "limited_patch"),
  incremental_movement_expenditure_kj = c(100, 100),
  metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
)

run_explicit_move <- function(origin_patch_id, destination_patch_id) {
  movement <- herbivoreTTR::step_known_route_movement(
    herbivoreTTR::new_patch_location_state(origin_patch_id),
    landscape,
    destination_patch_id
  )
  movement_index <- which(fixture$hour_of_day == movement_hour)

  feeding_open <- fixture$feeding_open
  feeding_open[[movement_index]] <-
    !movement$fluxes$feeding_suspended_during_travel

  reference_intake_kg_dm_h <- fixture$reference_intake_kg_dm_h
  reference_intake_kg_dm_h[[movement_index]] <- 0

  acquisition_ceiling_kg_dm_h <- numeric(24L)
  acquisition_ceiling_kg_dm_h[
    fixture$hour_of_day %in% first_feeding_window
  ] <- patch_acquisition_rate_kg_dm_h[[origin_patch_id]]
  acquisition_ceiling_kg_dm_h[
    fixture$hour_of_day %in% second_feeding_window
  ] <- patch_acquisition_rate_kg_dm_h[[destination_patch_id]]
  acquisition_ceiling_kg_dm_h[[movement_index]] <- 0

  activity_kj_h <- fixture$activity_kj_h
  activity_kj_h[[movement_index]] <-
    activity_kj_h[[movement_index]] +
      movement$fluxes$incremental_movement_expenditure_kj_h

  result <- run_appetite_days(
    fixture,
    appetite_reference = herbivoreTTR::new_appetite_reference_schedule(
      hour_of_day = fixture$hour_of_day,
      feeding_opportunity_open = feeding_open,
      reference_dry_matter_intake_kg_dm_h = reference_intake_kg_dm_h,
      reference_body_energy_reserve_kj =
        fixture$appetite_reference$reference_body_energy_reserve_kj,
      reference_gut_available_energy_kj =
        fixture$appetite_reference$reference_gut_available_energy_kj
    ),
    forage = herbivoreTTR::new_forage_acquisition_ceiling_schedule(
      fixture$hour_of_day,
      acquisition_ceiling_kg_dm_h
    ),
    activity = herbivoreTTR::new_routine_activity_expenditure_schedule(
      fixture$hour_of_day,
      activity_kj_h
    )
  )

  list(
    movement = movement,
    feeding_open = feeding_open,
    feeding_time_lost_h = sum(fixture$feeding_open & !feeding_open),
    activity_kj_h = activity_kj_h,
    result = result
  )
}

cases <- list(
  limited_to_adequate = run_explicit_move(
    "limited_patch",
    "adequate_patch"
  ),
  adequate_to_limited = run_explicit_move(
    "adequate_patch",
    "limited_patch"
  )
)

assert_that(
  all(vapply(
    cases,
    function(case) {
      identical(case$movement$fluxes$travel_duration_h, 1) &&
        identical(case$feeding_time_lost_h, 1L) &&
        isTRUE(case$movement$fluxes$feeding_suspended_during_travel) &&
        identical(
          case$movement$fluxes$incremental_movement_expenditure_kj,
          100
        ) &&
        sum(case$feeding_open) == 15L &&
        near(sum(case$activity_kj_h), 900)
    },
    logical(1L)
  )),
  "explicit movement duration, feeding suspension, and energy charge"
)

assert_that(
  identical(
    vapply(cases, function(case) case$movement$state$patch_id, character(1L)),
    c(
      limited_to_adequate = "adequate_patch",
      adequate_to_limited = "limited_patch"
    )
  ),
  "explicit closing patch location"
)

combined_change_kj <- vapply(
  cases,
  function(case) {
    case$result$daily$observed_total_system_energy_change_kj[[1L]]
  },
  numeric(1L)
)
assert_that(
  near(combined_change_kj, c(-481, -650), tolerance = 2e-3),
  "Goal 024 combined known-route movement outcomes"
)
assert_that(
  all(vapply(
    cases,
    function(case) {
      max(abs(case$result$hourly$system_energy_balance_residual_kj)) < 1e-8
    },
    logical(1L)
  )),
  "energy conservation under explicit movement composition"
)

movement_summary <- data.frame(
  treatment = names(cases),
  opening_patch = vapply(
    cases,
    function(case) case$movement$fluxes$origin_patch_id,
    character(1L)
  ),
  closing_patch = vapply(
    cases,
    function(case) case$movement$state$patch_id,
    character(1L)
  ),
  travel_duration_h = vapply(
    cases,
    function(case) case$movement$fluxes$travel_duration_h,
    numeric(1L)
  ),
  feeding_time_lost_h = vapply(
    cases,
    function(case) case$feeding_time_lost_h,
    numeric(1L)
  ),
  movement_expenditure_kj = vapply(
    cases,
    function(case) {
      case$movement$fluxes$incremental_movement_expenditure_kj
    },
    numeric(1L)
  ),
  realized_intake_kg_dm = vapply(
    cases,
    function(case) case$result$daily$realized_dry_matter_intake_kg_dm[[1L]],
    numeric(1L)
  ),
  combined_change_kj = round(combined_change_kj),
  row.names = NULL
)

cat("Explicit known-route movement diagnostic passed.\n")
print(movement_summary, row.names = FALSE)
