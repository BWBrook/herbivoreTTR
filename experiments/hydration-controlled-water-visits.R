source("experiments/herbivore-core-fixtures.R")

fixture <- new_herbivore_core_fixture()
forage_patch_id <- "forage_patch"
water_source_patch_id <- "water_source"
normal_body_water_kg <- 28
critical_body_water_kg <- 24
thirst_trigger_body_water_kg <- 26
simulation_days <- 60L

scenarios <- data.frame(
  scenario = c(
    "water_disabled_anchor",
    "baseline",
    "wetter_forage",
    "drier_forage",
    "greater_ordinary_loss",
    "higher_route_cost",
    "dry_forage_no_source"
  ),
  scenario_role = c("anchor", rep("comparison", 5L), "stress"),
  food_water_yield_kg_water_kg_dm = c(
    0, 3.28, 4.28, 1.28, 3.28, 3.28, 1.28
  ),
  daily_ordinary_water_loss_kg = c(
    0, 1.56, 1.56, 1.56, 2.00, 1.56, 1.56
  ),
  movement_expenditure_per_leg_kj = c(
    900, 900, 900, 900, 900, 1200, 900
  ),
  source_available = c(FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
  stringsAsFactors = FALSE
)

new_landscape <- function(scenario) {
  herbivoreTTR::new_known_route_landscape(
    patch_id = c(forage_patch_id, water_source_patch_id),
    forage_acquisition_ceiling_kg_dm_h = c(0.025, 0),
    route_origin_patch_id = c(forage_patch_id, water_source_patch_id),
    route_destination_patch_id = c(water_source_patch_id, forage_patch_id),
    incremental_movement_expenditure_kj = rep(
      scenario$movement_expenditure_per_leg_kj,
      2L
    ),
    metabolizable_energy_density_kj_kg_dm = c(10000, 10000)
  )
}

new_water_properties <- function(scenario) {
  herbivoreTTR::new_patch_water_properties(
    patch_id = c(forage_patch_id, water_source_patch_id),
    food_derived_water_yield_kg_water_kg_dm = c(
      scenario$food_water_yield_kg_water_kg_dm,
      0
    ),
    drinking_water_availability_kg_h = c(
      0,
      if (scenario$source_available) 10 else 0
    )
  )
}

new_daily_itinerary <- function(visit_water) {
  closing_patch_id <- rep(forage_patch_id, 24L)
  if (visit_water) {
    closing_patch_id[fixture$hour_of_day %in% c(8L, 9L)] <-
      water_source_patch_id
  }
  herbivoreTTR::new_prescribed_patch_itinerary(
    fixture$hour_of_day,
    closing_patch_id
  )
}

run_scenario <- function(scenario) {
  landscape <- new_landscape(scenario)
  water_properties <- new_water_properties(scenario)
  water_parameters <- herbivoreTTR::new_body_water_parameters(
    normal_body_water_kg,
    critical_body_water_kg,
    scenario$daily_ordinary_water_loss_kg / 24
  )
  state <- list(
    location = herbivoreTTR::new_patch_location_state(forage_patch_id),
    gut = fixture$opening_gut,
    body = fixture$opening_body,
    water = herbivoreTTR::new_body_water_state(normal_body_water_kg)
  )
  daily_rows <- vector("list", simulation_days)
  completed_days <- 0L
  terminal_day <- NA_integer_

  for (simulation_day in seq_len(simulation_days)) {
    opening_water_kg <- state$water$body_water_kg
    thirst_triggered <-
      opening_water_kg <= thirst_trigger_body_water_kg
    visit_water <- thirst_triggered && scenario$source_available
    energy <- herbivoreTTR::run_prescribed_spatial_energy_day(
      initial_location_state = state$location,
      landscape = landscape,
      itinerary = new_daily_itinerary(visit_water),
      initial_gut_state = state$gut,
      initial_body_state = state$body,
      gut_parameters = fixture$gut,
      body_parameters = fixture$body,
      appetite_parameters = fixture$appetite,
      appetite_reference_schedule = fixture$appetite_reference,
      routine_activity_schedule = fixture$activity
    )
    water <- herbivoreTTR::run_spatial_body_water_day(
      initial_state = state$water,
      parameters = water_parameters,
      patch_water_properties = water_properties,
      spatial_energy_hourly = energy$hourly,
      prescribed_incremental_evaporative_water_loss_kg_h = rep(0, 24L)
    )
    accounts_close <-
      max(abs(energy$hourly$system_energy_balance_residual_kj)) < 1e-8 &&
        abs(energy$daily$system_energy_balance_residual_kj) < 1e-8 &&
        max(abs(water$hourly$body_water_balance_residual_kg)) < 1e-12 &&
        abs(water$daily$body_water_balance_residual_kg) < 1e-12

    daily_rows[[simulation_day]] <- data.frame(
      scenario = scenario$scenario,
      scenario_role = scenario$scenario_role,
      simulation_day = simulation_day,
      opening_body_water_kg = opening_water_kg,
      thirst_triggered = thirst_triggered,
      water_visit = visit_water,
      food_derived_water_kg =
        water$daily$total_food_derived_water_kg,
      drinking_water_kg =
        water$daily$total_realized_drinking_water_kg,
      ordinary_water_loss_kg =
        water$daily$total_ordinary_water_loss_kg,
      closing_body_water_kg = water$daily$body_water_final_kg,
      body_water_below_critical = water$daily$body_water_below_critical,
      realized_intake_kg_dm =
        energy$daily$realized_dry_matter_intake_kg_dm,
      movement_expenditure_kj =
        energy$daily$total_incremental_movement_expenditure_kj,
      closing_body_energy_reserve_kj =
        energy$daily$body_energy_reserve_final_kj,
      accounts_close = accounts_close,
      row.names = NULL
    )
    completed_days <- simulation_day
    state <- list(
      location = herbivoreTTR::new_patch_location_state(
        energy$daily$final_patch_id
      ),
      gut = herbivoreTTR::new_gut_energy_state(
        energy$daily$gut_available_energy_final_kj
      ),
      body = herbivoreTTR::new_body_energy_state(
        energy$daily$body_energy_reserve_final_kj
      ),
      water = water$final_state
    )
    if (water$daily$body_water_below_critical) {
      terminal_day <- simulation_day
      break
    }
  }

  result <- do.call(rbind, daily_rows[seq_len(completed_days)])
  attr(result, "completed_days") <- completed_days
  attr(result, "terminal_day") <- terminal_day
  result
}

summarize_run <- function(run) {
  visit_days <- run$simulation_day[run$water_visit]
  visit_intervals <- if (length(visit_days) > 1L) diff(visit_days) else NA_integer_

  data.frame(
    scenario = run$scenario[[1L]],
    scenario_role = run$scenario_role[[1L]],
    completed_days = attr(run, "completed_days"),
    terminal_day = attr(run, "terminal_day"),
    water_visits = length(visit_days),
    shortest_visit_interval_days = if (all(is.na(visit_intervals))) {
      NA_integer_
    } else {
      min(visit_intervals)
    },
    food_derived_water_kg = sum(run$food_derived_water_kg),
    drinking_water_kg = sum(run$drinking_water_kg),
    movement_expenditure_kj = sum(run$movement_expenditure_kj),
    minimum_body_water_kg = min(run$closing_body_water_kg),
    closing_body_water_kg = tail(run$closing_body_water_kg, 1L),
    minimum_body_energy_reserve_kj = min(
      run$closing_body_energy_reserve_kj
    ),
    closing_body_energy_reserve_kj = tail(
      run$closing_body_energy_reserve_kj,
      1L
    ),
    all_accounts_close = all(run$accounts_close),
    row.names = NULL
  )
}

runs <- lapply(seq_len(nrow(scenarios)), function(index) {
  run_scenario(scenarios[index, , drop = FALSE])
})
names(runs) <- scenarios$scenario
summary_table <- do.call(rbind, lapply(runs, summarize_run))
row.names(summary_table) <- NULL

baseline <- summary_table[summary_table$scenario == "baseline", ]
water_disabled <- runs$water_disabled_anchor
wetter <- summary_table[summary_table$scenario == "wetter_forage", ]
drier <- summary_table[summary_table$scenario == "drier_forage", ]
greater_loss <- summary_table[
  summary_table$scenario == "greater_ordinary_loss",
]
higher_route <- summary_table[summary_table$scenario == "higher_route_cost", ]
stress <- summary_table[summary_table$scenario_role == "stress", ]
reference_energy <- run_appetite_days(fixture, number_of_days = simulation_days)

assert_that(
  all(summary_table$all_accounts_close) &&
    all(summary_table$completed_days[summary_table$scenario_role == "comparison"] ==
      simulation_days),
  "every viable repeated treatment completes with closed accounts"
)
assert_that(
  near(
    water_disabled$realized_intake_kg_dm,
    reference_energy$daily$realized_dry_matter_intake_kg_dm
  ) &&
    near(
      water_disabled$closing_body_energy_reserve_kj,
      reference_energy$daily$body_energy_reserve_final_kj
    ) &&
    all(!water_disabled$water_visit) &&
    near(water_disabled$closing_body_water_kg, rep(normal_body_water_kg, 60L)),
  "disabling the water layer reproduces the accepted repeated energy reference"
)
assert_that(
  baseline$water_visits > 0 &&
    baseline$shortest_visit_interval_days >= 2L &&
    baseline$minimum_body_water_kg > critical_body_water_kg,
  "the baseline thirst rule produces bounded non-chattering visits"
)
assert_that(
  wetter$water_visits < baseline$water_visits &&
    drier$water_visits > baseline$water_visits &&
    greater_loss$water_visits > baseline$water_visits,
  "forage water and ordinary loss change visit frequency monotonically"
)
assert_that(
  higher_route$water_visits == baseline$water_visits &&
    higher_route$movement_expenditure_kj > baseline$movement_expenditure_kj &&
    higher_route$minimum_body_energy_reserve_kj <
      baseline$minimum_body_energy_reserve_kj,
  "route energy changes energetic cost without directly changing thirst"
)
assert_that(
  stress$completed_days < simulation_days &&
    !is.na(stress$terminal_day) &&
    stress$minimum_body_water_kg < critical_body_water_kg,
  "dry forage without an accessible source reaches the declared water boundary"
)

cat("Hydration-controlled water-visit diagnostic passed.\n")
print(transform(
  summary_table,
  food_derived_water_kg = round(food_derived_water_kg, 1),
  drinking_water_kg = round(drinking_water_kg, 1),
  movement_expenditure_kj = round(movement_expenditure_kj),
  minimum_body_water_kg = round(minimum_body_water_kg, 2),
  closing_body_water_kg = round(closing_body_water_kg, 2),
  minimum_body_energy_reserve_kj = round(minimum_body_energy_reserve_kj),
  closing_body_energy_reserve_kj = round(closing_body_energy_reserve_kj)
), row.names = FALSE)
