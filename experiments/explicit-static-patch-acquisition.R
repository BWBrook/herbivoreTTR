source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = c("limited_patch", "adequate_patch"),
  forage_acquisition_ceiling_kg_dm_h = c(0.015, 0.025),
  route_origin_patch_id = c("limited_patch", "adequate_patch"),
  route_destination_patch_id = c("adequate_patch", "limited_patch"),
  incremental_movement_expenditure_kj = c(100, 100),
  metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
)

run_patch_order <- function(initial_patch_id, destination_patch_id) {
  closing_patch_id <- rep(initial_patch_id, 24L)
  closing_patch_id[fixture$hour_of_day >= 16L] <- destination_patch_id

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
    appetite_parameters = fixture$appetite,
    appetite_reference_schedule = fixture$appetite_reference,
    routine_activity_schedule = fixture$activity
  )
}

cases <- list(
  limited_to_adequate = run_patch_order(
    "limited_patch",
    "adequate_patch"
  ),
  adequate_to_limited = run_patch_order(
    "adequate_patch",
    "limited_patch"
  )
)

assert_that(
  all(vapply(
    cases,
    function(result) {
      moving <- result$hourly$spatial_action == "move"
      identical(result$hourly$hour_of_day[moving], 16L) &&
        identical(result$daily$movement_hours, 1L) &&
        near(result$daily$total_travel_duration_h, 1) &&
        near(result$daily$feeding_time_lost_h, 1) &&
        near(result$daily$total_incremental_movement_expenditure_kj, 100)
    },
    logical(1L)
  )),
  "matched movement timing, feeding-time loss, and route expenditure"
)
assert_that(
  all(vapply(
    cases,
    function(result) {
      max(abs(result$hourly$system_energy_balance_residual_kj)) < 1e-9 &&
        abs(result$daily$system_energy_balance_residual_kj) < 1e-9
    },
    logical(1L)
  )),
  "hourly and daily energy accounting"
)
assert_that(
  cases$limited_to_adequate$daily$realized_dry_matter_intake_kg_dm >
    cases$adequate_to_limited$daily$realized_dry_matter_intake_kg_dm,
  "feeding-window patch order changes realized intake"
)
assert_that(
  near(
    cases$limited_to_adequate$daily$realized_dry_matter_intake_kg_dm,
    0.2819046613644086
  ) &&
    near(
      cases$limited_to_adequate$daily$
        observed_total_system_energy_change_kj,
      -480.953386355914
    ) &&
    near(
      cases$adequate_to_limited$daily$realized_dry_matter_intake_kg_dm,
      0.265
    ) &&
    near(
      cases$adequate_to_limited$daily$
        observed_total_system_energy_change_kj,
      -650
    ),
  "fixed patch-order intake and energy outcomes"
)

summary_table <- data.frame(
  treatment = names(cases),
  opening_patch = vapply(
    cases,
    function(x) x$daily$initial_patch_id,
    character(1L)
  ),
  closing_patch = vapply(
    cases,
    function(x) x$daily$final_patch_id,
    character(1L)
  ),
  first_window_capacity_kg_dm_h = vapply(
    cases,
    function(x) {
      x$hourly$opening_patch_forage_acquisition_ceiling_kg_dm_h[[1L]]
    },
    numeric(1L)
  ),
  second_window_capacity_kg_dm_h = vapply(
    cases,
    function(x) {
      x$hourly$opening_patch_forage_acquisition_ceiling_kg_dm_h[[18L]]
    },
    numeric(1L)
  ),
  realized_intake_kg_dm = vapply(
    cases,
    function(x) x$daily$realized_dry_matter_intake_kg_dm,
    numeric(1L)
  ),
  combined_energy_change_kj = round(vapply(
    cases,
    function(x) x$daily$observed_total_system_energy_change_kj,
    numeric(1L)
  )),
  row.names = NULL
)

cat("Explicit static patch-acquisition diagnostic passed.\n")
print(summary_table, row.names = FALSE)
