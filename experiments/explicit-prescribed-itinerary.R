source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = c("patch_a", "patch_b"),
  forage_acquisition_ceiling_kg_dm_h = c(0.025, 0.025),
  route_origin_patch_id = c("patch_a", "patch_b"),
  route_destination_patch_id = c("patch_b", "patch_a"),
  incremental_movement_expenditure_kj = c(100, 100)
)

run_itinerary <- function(closing_patch_id) {
  herbivoreTTR::run_prescribed_spatial_energy_day(
    initial_location_state = herbivoreTTR::new_patch_location_state("patch_a"),
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

stay_patch_id <- rep("patch_a", 24L)
round_trip_patch_id <- stay_patch_id
round_trip_patch_id[fixture$hour_of_day %in% 8:15] <- "patch_b"

reference <- run_appetite_days(fixture)
cases <- list(
  all_stay = run_itinerary(stay_patch_id),
  round_trip = run_itinerary(round_trip_patch_id)
)

assert_that(
  identical(cases$all_stay$hourly[names(reference$hourly)], reference$hourly) &&
    identical(cases$all_stay$daily[names(reference$daily)], reference$daily),
  "the all-stay itinerary reduces exactly to the accepted reference"
)

round_trip <- cases$round_trip
moving <- round_trip$hourly$spatial_action == "move"
assert_that(
  identical(round_trip$hourly$hour_of_day[moving], c(8L, 16L)) &&
    identical(round_trip$hourly$opening_patch_id[moving], c("patch_a", "patch_b")) &&
    identical(round_trip$hourly$closing_patch_id[moving], c("patch_b", "patch_a")) &&
    identical(round_trip$daily$final_patch_id, "patch_a"),
  "the prescribed route and closing locations"
)
assert_that(
  identical(round_trip$daily$movement_hours, 2L) &&
    near(round_trip$daily$total_travel_duration_h, 2) &&
    near(round_trip$daily$feeding_time_lost_h, 1) &&
    near(round_trip$daily$total_incremental_movement_expenditure_kj, 200),
  "travel, contextual feeding-time loss, and movement expenditure"
)
assert_that(
  max(abs(round_trip$hourly$system_energy_balance_residual_kj)) < 1e-9 &&
    abs(round_trip$daily$system_energy_balance_residual_kj) < 1e-9,
  "hourly and daily energy accounting"
)
assert_that(
  near(round_trip$daily$realized_dry_matter_intake_kg_dm, 0.3134940654218749) &&
    near(
      round_trip$daily$observed_total_system_energy_change_kj,
      -265.05934578125
    ),
  "fixed appetite compensation and combined energy response"
)

summary_table <- data.frame(
  itinerary = names(cases),
  initial_patch = vapply(
    cases,
    function(x) x$daily$initial_patch_id,
    character(1L)
  ),
  final_patch = vapply(
    cases,
    function(x) x$daily$final_patch_id,
    character(1L)
  ),
  movement_hours = vapply(
    cases,
    function(x) x$daily$movement_hours,
    integer(1L)
  ),
  feeding_time_lost_h = vapply(
    cases,
    function(x) x$daily$feeding_time_lost_h,
    numeric(1L)
  ),
  movement_expenditure_kj = vapply(
    cases,
    function(x) x$daily$total_incremental_movement_expenditure_kj,
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

cat("Explicit prescribed-itinerary diagnostic passed.\n")
print(summary_table, row.names = FALSE)
