# Area-supported focal grazing. Sourcing defines functions and writes nothing.
source("experiments/herbivore-core-fixtures.R")

new_spatial_grazing_system <- function(total_area_ha = .08,
  boundary = "periodic", grid_side = 2L, policy = "local",
  heterogeneous = TRUE) {
  stopifnot(total_area_ha > 0, total_area_ha <= 1,
    grid_side %in% c(1L, 2L, 4L), policy %in% c("local", "informed"))
  xy <- expand.grid(x_m = (seq_len(grid_side) - .5) * 100 / grid_side,
    y_m = (seq_len(grid_side) - .5) * 100 / grid_side)
  n <- nrow(xy)
  landscape <- herbivoreTTR::new_area_landscape(data.frame(
    patch_id = paste0("p", seq_len(n)), x_m = xy$x_m, y_m = xy$y_m,
    area_ha = rep(total_area_ha / n, n), residual_kg_dm_ha = rep(200, n)),
    100, 100, boundary)
  list(landscape = landscape, fixture = new_herbivore_core_fixture(),
    water = herbivoreTTR::new_body_water_parameters(28, 24, 1.56 / 24),
    production_saturation_biomass_kg_dm_ha = if (heterogeneous && n > 1)
      ifelse(xy$x_m < 50, 1600, 2400) else rep(2000, n), growth_rate_h = .002,
    senescence_rate_h = .001, speed_m_h = 40, travel_cost_kj_m = 1,
    food_water_kg_kg_dm = 3.28, policy = policy)
}

new_spatial_grazing_state <- function(system) {
  list(biomass_kg_dm_ha = system$production_saturation_biomass_kg_dm_ha / 2,
    patch_id = "p1", gut = system$fixture$opening_gut,
    body = system$fixture$opening_body,
    water = herbivoreTTR::new_body_water_state(28), journey = NULL,
    last_water_day = -1L)
}

spatial_acquisition_rate <- function(biomass_kg_dm_ha) {
  .030 * pmin(1, pmax(biomass_kg_dm_ha - 200, 0) / 500)
}

spatial_grazing_destination <- function(state, system) {
  ids <- system$landscape$patches$patch_id
  here <- match(state$patch_id, ids)
  rate <- spatial_acquisition_rate(state$biomass_kg_dm_ha)
  if (system$policy == "local") {
    if (rate[here] >= .020) return(state$patch_id)
    return(ids[here %% length(ids) + 1L])
  }
  distance <- vapply(ids, function(id) herbivoreTTR::landscape_distance_m(
    system$landscape, state$patch_id, id), numeric(1))
  # Current-stock four-hour opportunity score, not an optimal forecast.
  opportunity <- pmax(0, 4 - distance / system$speed_m_h)
  stock <- pmax(state$biomass_kg_dm_ha - 200, 0) *
    system$landscape$patches$area_ha
  score <- pmin(pmin(rate, .025) * opportunity, stock) * 10000 -
    distance * system$travel_cost_kj_m
  if (score[here] >= max(score) - 1e-10) state$patch_id else ids[which.max(score)]
}

# Advance travel within an hour. State retains unfinished journeys. Water is
# encountered at half the prescribed excursion duration; return is to origin.
spatial_travel_hour <- function(state) {
  j <- state$journey
  if (is.null(j)) return(list(state = state, time_h = 0, water_time_h = 0,
    forage_time_h = 0, expenditure_kj = 0, water_expenditure_kj = 0,
    drinking_available_kg = 0))
  used <- min(1, j$remaining_h)
  elapsed <- j$total_h - j$remaining_h
  drinking <- j$kind == "water" && elapsed < j$total_h / 2 &&
    elapsed + used >= j$total_h / 2
  j$remaining_h <- max(0, j$remaining_h - used)
  expenditure <- j$total_cost_kj * used / j$total_h
  if (j$remaining_h <= 1e-12) {
    state$patch_id <- j$destination
    state$journey <- NULL
  } else state$journey <- j
  list(state = state, time_h = used,
    water_time_h = if (j$kind == "water") used else 0,
    forage_time_h = if (j$kind == "forage") used else 0,
    expenditure_kj = expenditure,
    water_expenditure_kj = if (j$kind == "water") expenditure else 0,
    drinking_available_kg = if (drinking) 10 else 0)
}

step_spatial_grazing_hour <- function(state, system, hour, day,
  growth_multiplier = 1, water_duration_h = .5, water_cost_kj = 0,
  stationary = FALSE) {
  stopifnot(hour %in% 0:23, day >= 1, growth_multiplier >= 0,
    growth_multiplier <= 1, water_duration_h > 0, water_cost_kj >= 0)
  opening <- state
  plant <- herbivoreTTR::step_responsive_forage(state$biomass_kg_dm_ha,
    system$production_saturation_biomass_kg_dm_ha, system$growth_rate_h,
    system$senescence_rate_h, growth_multiplier)
  state$biomass_kg_dm_ha <- plant$state
  ref <- system$fixture$appetite_reference[hour + 1L, , drop = FALSE]
  water_departure <- FALSE
  if (is.null(state$journey) && !stationary) {
    if (state$water$body_water_kg <= 26 && state$last_water_day != day) {
      state$journey <- list(kind = "water", total_h = water_duration_h,
        remaining_h = water_duration_h, total_cost_kj = water_cost_kj,
        destination = state$patch_id)
      state$last_water_day <- day
      water_departure <- TRUE
    } else if (ref$feeding_opportunity_open) {
      dest <- spatial_grazing_destination(state, system)
      if (dest != state$patch_id) {
        distance <- herbivoreTTR::landscape_distance_m(system$landscape,
          state$patch_id, dest)
        state$journey <- list(kind = "forage",
          total_h = distance / system$speed_m_h,
          remaining_h = distance / system$speed_m_h,
          total_cost_kj = distance * system$travel_cost_kj_m,
          destination = dest)
      }
    }
  }
  travel <- spatial_travel_hour(state)
  state <- travel$state
  feeding_h <- as.numeric(ref$feeding_opportunity_open) * (1 - travel$time_h)
  here <- match(state$patch_id, system$landscape$patches$patch_id)
  appetite <- herbivoreTTR::calculate_appetite_target(state$gut, state$body,
    system$fixture$food, system$fixture$appetite, ref)
  candidate <- min(appetite$appetite_target_dry_matter_intake_kg_dm_h,
    spatial_acquisition_rate(state$biomass_kg_dm_ha[here])) * feeding_h
  removal <- herbivoreTTR::remove_area_forage(state$biomass_kg_dm_ha,
    system$landscape, state$patch_id, candidate)
  state$biomass_kg_dm_ha <- removal$state
  intake <- removal$fluxes$realized_intake_kg_dm
  ingested <- intake * 10000
  gut <- herbivoreTTR::step_gut_energy(state$gut, system$fixture$gut,
    data.frame(hour_of_day = hour,
      prescribed_ingested_available_energy_kj_h = ingested))
  activity <- system$fixture$activity[hour + 1L, , drop = FALSE]
  routine <- activity$prescribed_routine_activity_expenditure_kj_h
  activity$prescribed_routine_activity_expenditure_kj_h <-
    routine + travel$expenditure_kj
  proposed_body <- state$body$body_energy_reserve_kj +
    gut$fluxes$assimilated_energy_kj - 100 - routine - travel$expenditure_kj
  if (proposed_body < 0) return(list(stopped = TRUE, reason = "energy_domain",
    state = opening, proposed_body_energy_kj = proposed_body))
  body <- herbivoreTTR::step_body_energy(state$body, system$fixture$body,
    data.frame(hour_of_day = hour,
      prescribed_assimilated_energy_kj_h = gut$fluxes$assimilated_energy_kj),
    activity)
  water <- herbivoreTTR::step_body_water(state$water, system$water,
    data.frame(hour_of_day = hour,
      prescribed_food_derived_water_kg_h = intake * system$food_water_kg_kg_dm,
      available_drinking_water_kg_h = if (stationary) 10 else
        travel$drinking_available_kg,
      prescribed_incremental_evaporative_water_loss_kg_h = 0))
  area <- system$landscape$patches$area_ha
  mass0 <- sum(opening$biomass_kg_dm_ha * area)
  mass1 <- sum(state$biomass_kg_dm_ha * area)
  growth <- sum(plant$fluxes$growth_kg_dm_ha * area)
  loss <- sum(plant$fluxes$senescence_kg_dm_ha * area)
  state$gut <- gut$state
  state$body <- body$state
  state$water <- water$state
  ledger <- data.frame(day = day, hour = hour, patch_id = state$patch_id,
    feeding_h = feeding_h, forage_travel_h = travel$forage_time_h,
    water_travel_h = travel$water_time_h, water_departure = water_departure,
    water_expenditure_kj = travel$water_expenditure_kj,
    forage_expenditure_kj = travel$expenditure_kj - travel$water_expenditure_kj,
    intake_kg_dm = intake, plant_growth_kg_dm = growth,
    plant_senescence_kg_dm = loss, forage_mass_kg_dm = mass1,
    body_energy_kj = state$body$body_energy_reserve_kj,
    gut_energy_kj = state$gut$gut_available_energy_kj,
    body_water_kg = state$water$body_water_kg,
    drinking_kg = water$fluxes$realized_drinking_water_kg,
    plant_balance_kg_dm = mass1 - mass0 - growth + loss + intake,
    energy_balance_kj = state$body$body_energy_reserve_kj -
      opening$body$body_energy_reserve_kj + state$gut$gut_available_energy_kj -
      opening$gut$gut_available_energy_kj - ingested + 100 + routine +
      travel$expenditure_kj,
    water_balance_kg = water$fluxes$body_water_balance_residual_kg)
  list(stopped = FALSE, state = state, hourly = ledger)
}

run_spatial_grazing <- function(system, treatment_growth = 1,
  treatment_water_duration_h = .5, treatment_water_cost_kj = 0,
  phase_days = c(60L, 84L, 60L), stationary = FALSE) {
  stopifnot(length(phase_days) == 3, all(phase_days >= 1),
    all(phase_days == as.integer(phase_days)))
  phases <- rep(c("baseline", "treatment", "recovery"), phase_days)
  state <- new_spatial_grazing_state(system)
  rows <- vector("list", length(phases) * 24L)
  k <- 0L
  stop_day <- NA_integer_
  stop_hour <- NA_integer_
  for (day in seq_along(phases)) {
    treatment <- phases[day] == "treatment"
    for (hour in 0:23) {
      step <- step_spatial_grazing_hour(state, system, hour, day,
        if (treatment) treatment_growth else 1,
        if (treatment) treatment_water_duration_h else .5,
        if (treatment) treatment_water_cost_kj else 0, stationary)
      if (step$stopped) {
        stop_day <- day
        stop_hour <- hour
        break
      }
      state <- step$state
      k <- k + 1L
      rows[[k]] <- cbind(phase = phases[day], step$hourly)
    }
    if (!is.na(stop_day)) break
  }
  hourly <- do.call(rbind, rows[seq_len(k)])
  daily <- do.call(rbind, lapply(split(hourly, hourly$day), function(d) {
    data.frame(day = d$day[1], phase = d$phase[1], complete_day = nrow(d) == 24,
      body_energy_kj = tail(d$body_energy_kj, 1),
      min_water_kg = min(d$body_water_kg), intake_kg_dm = sum(d$intake_kg_dm),
      forage_mass_kg_dm = tail(d$forage_mass_kg_dm, 1),
      plant_growth_kg_dm = sum(d$plant_growth_kg_dm),
      plant_senescence_kg_dm = sum(d$plant_senescence_kg_dm),
      water_trips = sum(d$water_departure),
      water_travel_h = sum(d$water_travel_h),
      forage_travel_h = sum(d$forage_travel_h),
      water_expenditure_kj = sum(d$water_expenditure_kj),
      forage_expenditure_kj = sum(d$forage_expenditure_kj))
  }))
  rownames(daily) <- NULL
  list(hourly = hourly, daily = daily, final_state = state,
    stop_day = stop_day, stop_hour = stop_hour)
}
