source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
first_window <- 0:7
second_window <- 16:23

make_patch_ceiling <- function(first_rate, second_rate) {
  rates <- numeric(24L)
  rates[fixture$hour_of_day %in% first_window] <- first_rate
  rates[fixture$hour_of_day %in% second_window] <- second_rate
  herbivoreTTR::new_forage_acquisition_ceiling_schedule(
    fixture$hour_of_day,
    rates
  )
}

patch_design <- data.frame(
  scenario = c(
    "adequate_then_adequate",
    "limited_then_limited",
    "limited_then_adequate",
    "adequate_then_limited"
  ),
  first_rate = c(0.025, 0.015, 0.015, 0.025),
  second_rate = c(0.025, 0.015, 0.025, 0.015),
  stringsAsFactors = FALSE
)
patch_results <- lapply(seq_len(nrow(patch_design)), function(index) {
  run_appetite_days(
    fixture,
    forage = make_patch_ceiling(
      patch_design$first_rate[[index]],
      patch_design$second_rate[[index]]
    )
  )
})
names(patch_results) <- patch_design$scenario
patch_summary <- data.frame(
  scenario = patch_design$scenario,
  realized_intake_kg_dm = vapply(
    patch_results,
    function(result) result$daily$realized_dry_matter_intake_kg_dm,
    numeric(1L)
  ),
  combined_change_kj = vapply(
    patch_results,
    function(result) result$daily$observed_total_system_energy_change_kj,
    numeric(1L)
  )
)
assert_that(
  near(patch_summary$combined_change_kj, c(0, -800, -276, -400), 2e-3),
  "implicit patch-order energy contrasts"
)

run_movement_case <- function(first_rate, second_rate) {
  feeding_open <- fixture$feeding_open
  reference_rate <- fixture$reference_intake_kg_dm_h
  ceiling <- make_patch_ceiling(first_rate, second_rate)
  activity_rate <- fixture$activity_kj_h
  movement_index <- which(fixture$hour_of_day == 16L)

  feeding_open[[movement_index]] <- FALSE
  reference_rate[[movement_index]] <- 0
  ceiling$forage_acquisition_ceiling_kg_dm_h[[movement_index]] <- 0
  activity_rate[[movement_index]] <- activity_rate[[movement_index]] + 100

  run_appetite_days(
    fixture,
    appetite_reference = herbivoreTTR::new_appetite_reference_schedule(
      hour_of_day = fixture$hour_of_day,
      feeding_opportunity_open = feeding_open,
      reference_dry_matter_intake_kg_dm_h = reference_rate,
      reference_body_energy_reserve_kj =
        fixture$appetite_reference$reference_body_energy_reserve_kj,
      reference_gut_available_energy_kj =
        fixture$appetite_reference$reference_gut_available_energy_kj
    ),
    forage = ceiling,
    activity = herbivoreTTR::new_routine_activity_expenditure_schedule(
      fixture$hour_of_day,
      activity_rate
    )
  )
}

movement_results <- list(
  limited_then_adequate = run_movement_case(0.015, 0.025),
  adequate_then_limited = run_movement_case(0.025, 0.015)
)
movement_change_kj <- vapply(
  movement_results,
  function(result) result$daily$observed_total_system_energy_change_kj,
  numeric(1L)
)
assert_that(
  near(movement_change_kj, c(-481, -650), 2e-3),
  "combined lost-feeding-time and movement-energy costs"
)

run_quality_order <- function(first_density, second_density) {
  densities <- rep(10000, 24L)
  densities[fixture$hour_of_day %in% first_window] <- first_density
  densities[fixture$hour_of_day %in% second_window] <- second_density
  gut_state <- fixture$opening_gut
  body_state <- fixture$opening_body
  realized_intake <- numeric(24L)
  realized_energy <- numeric(24L)

  for (index in seq_len(24L)) {
    local_food <- herbivoreTTR::new_food_energy_parameters(densities[[index]])
    control <- herbivoreTTR::calculate_appetite_target(
      gut_state,
      body_state,
      local_food,
      fixture$appetite,
      fixture$appetite_reference[index, , drop = FALSE]
    )
    realized_intake[[index]] <- min(
      control$appetite_target_dry_matter_intake_kg_dm_h,
      fixture$nonlimiting_forage$
        forage_acquisition_ceiling_kg_dm_h[[index]]
    )
    realized_energy[[index]] <- realized_intake[[index]] * densities[[index]]
    gut_transition <- herbivoreTTR::step_gut_energy(
      gut_state,
      fixture$gut,
      data.frame(
        hour_of_day = fixture$hour_of_day[[index]],
        prescribed_ingested_available_energy_kj_h = realized_energy[[index]]
      )
    )
    body_transition <- herbivoreTTR::step_body_energy(
      body_state,
      fixture$body,
      data.frame(
        hour_of_day = fixture$hour_of_day[[index]],
        prescribed_assimilated_energy_kj_h =
          gut_transition$fluxes$assimilated_energy_kj_h
      ),
      fixture$activity[index, , drop = FALSE]
    )
    gut_state <- gut_transition$state
    body_state <- body_transition$state
  }

  opening_total <- fixture$opening_gut$gut_available_energy_kj +
    fixture$opening_body$body_energy_reserve_kj
  data.frame(
    realized_intake_kg_dm = sum(realized_intake),
    realized_energy_kj = sum(realized_energy),
    combined_change_kj =
      gut_state$gut_available_energy_kj +
        body_state$body_energy_reserve_kj -
        opening_total
  )
}

quality_summary <- rbind(
  lower_then_adequate = run_quality_order(8000, 10000),
  adequate_then_lower = run_quality_order(10000, 8000)
)
quality_summary$scenario <- row.names(quality_summary)
row.names(quality_summary) <- NULL
quality_summary <- quality_summary[c(
  "scenario",
  "realized_intake_kg_dm",
  "realized_energy_kj",
  "combined_change_kj"
)]
assert_that(
  near(quality_summary$combined_change_kj, c(-168, -244), 3e-3),
  "patch-specific food-quality order contrast"
)

run_lower_quality_duration_response <- function(number_of_days = 10L) {
  extension_pairs <- list(c(8L, 15L), c(9L, 14L))
  gut_state <- fixture$opening_gut
  body_state <- fixture$opening_body
  daily_rows <- vector("list", number_of_days)
  reference_total <- fixture$opening_gut$gut_available_energy_kj + 40000

  for (day in seq_len(number_of_days)) {
    body_deficit <- max(0, 40000 - body_state$body_energy_reserve_kj)
    pair_count <- min(2L, as.integer(floor(body_deficit / 300)))
    extra_hours <- if (pair_count == 0L) {
      integer()
    } else {
      unlist(extension_pairs[seq_len(pair_count)], use.names = FALSE)
    }
    feeding_open <- fixture$feeding_open |
      fixture$hour_of_day %in% extra_hours
    reference_rate <- fixture$reference_intake_kg_dm_h
    reference_rate[fixture$hour_of_day %in% extra_hours] <- 0.020
    activity_rate <- fixture$activity_kj_h
    activity_rate[fixture$hour_of_day %in% extra_hours] <- 50

    result <- run_appetite_days(
      fixture,
      initial_gut = gut_state,
      initial_body = body_state,
      food = herbivoreTTR::new_food_energy_parameters(8000),
      appetite_reference = herbivoreTTR::new_appetite_reference_schedule(
        hour_of_day = fixture$hour_of_day,
        feeding_opportunity_open = feeding_open,
        reference_dry_matter_intake_kg_dm_h = reference_rate,
        reference_body_energy_reserve_kj =
          fixture$appetite_reference$reference_body_energy_reserve_kj,
        reference_gut_available_energy_kj =
          fixture$appetite_reference$reference_gut_available_energy_kj
      ),
      activity = herbivoreTTR::new_routine_activity_expenditure_schedule(
        fixture$hour_of_day,
        activity_rate
      )
    )
    gut_state <- herbivoreTTR::new_gut_energy_state(
      result$daily$gut_available_energy_final_kj
    )
    body_state <- herbivoreTTR::new_body_energy_state(
      result$daily$body_energy_reserve_final_kj
    )
    daily_rows[[day]] <- data.frame(
      day = day,
      extra_feeding_hours = length(extra_hours),
      realized_intake_kg_dm =
        result$daily$realized_dry_matter_intake_kg_dm,
      combined_deviation_kj =
        gut_state$gut_available_energy_kj +
          body_state$body_energy_reserve_kj -
          reference_total
    )
  }
  do.call(rbind, daily_rows)
}

duration_response <- run_lower_quality_duration_response()
assert_that(
  identical(duration_response$extra_feeding_hours, c(0L, rep(2L, 9L))) &&
    near(duration_response$combined_deviation_kj[[10L]], -476, 3e-3),
  "bounded duration response under repeated lower-quality forage"
)

cat("Herbivore-core implicit-patch diagnostic passed.\n")
print(patch_summary, row.names = FALSE)
cat("\nCombined movement-cost change (kJ):\n")
print(round(movement_change_kj))
cat("\nPatch-quality order:\n")
print(quality_summary, row.names = FALSE)
cat("\nLower-quality duration response, day 10:\n")
print(tail(duration_response, 1L), row.names = FALSE)
