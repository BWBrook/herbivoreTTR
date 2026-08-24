source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
forage_patch_id <- "forage_patch"
water_source_patch_id <- "water_source"
movement_expenditure_per_leg_kj <- 900

landscape <- herbivoreTTR::new_known_route_landscape(
  patch_id = c(forage_patch_id, water_source_patch_id),
  forage_acquisition_ceiling_kg_dm_h = c(0.025, 0),
  route_origin_patch_id = c(forage_patch_id, water_source_patch_id),
  route_destination_patch_id = c(water_source_patch_id, forage_patch_id),
  incremental_movement_expenditure_kj = rep(
    movement_expenditure_per_leg_kj,
    2L
  ),
  metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
)

run_itinerary <- function(closing_patch_id) {
  herbivoreTTR::run_prescribed_spatial_energy_day(
    initial_location_state = herbivoreTTR::new_patch_location_state(
      forage_patch_id
    ),
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

no_excursion <- rep(forage_patch_id, 24L)
off_window_excursion <- no_excursion
off_window_excursion[fixture$hour_of_day == 8L] <- water_source_patch_id
within_window_excursion <- no_excursion
within_window_excursion[fixture$hour_of_day == 6L] <- water_source_patch_id

reference <- run_appetite_days(fixture)
cases <- list(
  no_excursion = run_itinerary(no_excursion),
  off_window_excursion = run_itinerary(off_window_excursion),
  within_window_excursion = run_itinerary(within_window_excursion)
)

assert_that(
  identical(
    cases$no_excursion$hourly[names(reference$hourly)],
    reference$hourly
  ) &&
    identical(
      cases$no_excursion$daily[names(reference$daily)],
      reference$daily
    ),
  "the no-excursion treatment reduces exactly to the accepted reference"
)

excursions <- cases[c("off_window_excursion", "within_window_excursion")]
assert_that(
  all(vapply(excursions, function(x) x$daily$movement_hours, integer(1L)) == 2L) &&
    near(
      vapply(excursions, function(x) x$daily$total_travel_duration_h, numeric(1L)),
      c(2, 2)
    ) &&
    near(
      vapply(
        excursions,
        function(x) x$daily$total_incremental_movement_expenditure_kj,
        numeric(1L)
      ),
      c(1800, 1800)
    ) &&
    identical(
      unname(vapply(
        excursions,
        function(x) x$daily$final_patch_id,
        character(1L)
      )),
      c(forage_patch_id, forage_patch_id)
    ),
  "both excursions use the same two legs and return to forage"
)

assert_that(
  near(
    vapply(excursions, function(x) x$daily$feeding_time_lost_h, numeric(1L)),
    c(0, 2)
  ) &&
    identical(
      cases$off_window_excursion$hourly$hour_of_day[
        cases$off_window_excursion$hourly$spatial_action == "move"
      ],
      c(8L, 9L)
    ) &&
    identical(
      cases$within_window_excursion$hourly$hour_of_day[
        cases$within_window_excursion$hourly$spatial_action == "move"
      ],
      c(6L, 7L)
    ),
  "trip timing isolates zero versus two lost feeding hours"
)

combined_change_kj <- vapply(
  cases,
  function(x) x$daily$observed_total_system_energy_change_kj,
  numeric(1L)
)
assert_that(
  combined_change_kj[["no_excursion"]] >
    combined_change_kj[["off_window_excursion"]] &&
    combined_change_kj[["off_window_excursion"]] >
      combined_change_kj[["within_window_excursion"]],
  "combined energy follows the prespecified treatment ordering"
)

realized_intake_kg_dm <- vapply(
  cases,
  function(x) x$daily$realized_dry_matter_intake_kg_dm,
  numeric(1L)
)
assert_that(
  near(realized_intake_kg_dm, c(0.32, 0.36, 0.32)) &&
    near(combined_change_kj, c(0, -1400, -1800)),
  "the fixed appetite compensation and water-trip timing response"
)

assert_that(
  all(vapply(
    cases,
    function(x) max(abs(x$hourly$system_energy_balance_residual_kj)) < 1e-9,
    logical(1L)
  )) &&
    all(vapply(
      cases,
      function(x) abs(x$daily$system_energy_balance_residual_kj) < 1e-9,
      logical(1L)
    )),
  "hourly and daily energy accounting"
)

summary_table <- data.frame(
  treatment = names(cases),
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
  movement_expenditure_kj = round(vapply(
    cases,
    function(x) x$daily$total_incremental_movement_expenditure_kj,
    numeric(1L)
  )),
  realized_intake_kg_dm = unname(realized_intake_kg_dm),
  gut_energy_change_kj = round(vapply(
    cases,
    function(x) x$daily$observed_gut_energy_change_kj,
    numeric(1L)
  )),
  body_energy_change_kj = round(vapply(
    cases,
    function(x) x$daily$observed_body_energy_change_kj,
    numeric(1L)
  )),
  combined_energy_change_kj = round(combined_change_kj),
  row.names = NULL
)

cat("Prescribed water-source excursion diagnostic passed.\n")
cat("Route expenditure is a ratio-informed synthetic value, not species calibration.\n")
print(summary_table, row.names = FALSE)
