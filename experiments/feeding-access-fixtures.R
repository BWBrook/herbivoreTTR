# Physical feeding areas and conservative access experiment. No writes on source.
source("experiments/spatial-grazing-fixtures.R")
source("experiments/feeding-access-policy.R")

new_feeding_access_system <- function(configuration = "continuous",
  subdivisions = 1L, boundary = "bounded", heterogeneous = FALSE) {
  stopifnot(configuration %in% c("continuous", "clustered", "fragmented"),
    subdivisions %in% c(1L, 2L, 4L, 8L),
    boundary %in% c("bounded", "periodic"),
    !heterogeneous || subdivisions >= 2)
  x <- switch(configuration, continuous = c(35,45,55,65),
    clustered = c(15,25,75,85), fragmented = c(10,35,65,90))
  y <- if (configuration == "fragmented") c(15,85) else c(45,55)
  stations <- expand.grid(x_m = x, y_m = y)
  stations$patch_id <- paste0("s", seq_len(nrow(stations)))
  landscape <- herbivoreTTR::new_area_landscape(data.frame(
    patch_id = stations$patch_id, x_m = stations$x_m, y_m = stations$y_m,
    area_ha = rep(.01,8), residual_kg_dm_ha = rep(200,8)),100,100,boundary)
  cells <- do.call(rbind, lapply(seq_len(8), function(i) {
    g <- expand.grid(ix = seq_len(subdivisions), iy = seq_len(subdivisions))
    size <- 10 / subdivisions
    data.frame(xmin_m = stations$x_m[i] - 5 + (g$ix - 1) * size,
      xmax_m = stations$x_m[i] - 5 + g$ix * size,
      ymin_m = stations$y_m[i] - 5 + (g$iy - 1) * size,
      ymax_m = stations$y_m[i] - 5 + g$iy * size)
  }))
  block <- rep(seq_len(8), each = subdivisions^2)
  K <- if (heterogeneous) ifelse((cells$xmin_m + cells$xmax_m)/2 <
    stations$x_m[block], 1600, 2400) else rep(2000,nrow(cells))
  overlap <- vapply(seq_len(8), function(i) {
    herbivoreTTR::rectangle_overlap_m2(cells, c(
      xmin_m = stations$x_m[i] - 5, xmax_m = stations$x_m[i] + 5,
      ymin_m = stations$y_m[i] - 5, ymax_m = stations$y_m[i] + 5))
  }, numeric(nrow(cells)))
  distances <- vapply(stations$patch_id, function(to) vapply(
    stations$patch_id, function(from) herbivoreTTR::landscape_distance_m(
      landscape, from, to), numeric(1)), numeric(8))
  list(configuration = configuration, subdivisions = subdivisions,
    stations = stations, cells = cells, cell_block = block,
    cell_area_ha = (cells$xmax_m-cells$xmin_m) *
      (cells$ymax_m-cells$ymin_m) / 10000,
    overlap_m2 = overlap, distances_m = distances, K = K,
    boundary = boundary, fixture = new_herbivore_core_fixture(),
    water = herbivoreTTR::new_body_water_parameters(28,24,1.56/24),
    growth_rate_h = .002, senescence_rate_h = .001,
    search_area_m2_h = .6, speed_m_h = 40, movement_kj_m = 1)
}

new_feeding_access_state <- function(system) {
  list(biomass_kg_dm_ha = system$K / 2, patch_id = "s1",
    gut = system$fixture$opening_gut, body = system$fixture$opening_body,
    water = herbivoreTTR::new_body_water_state(28), journey = NULL,
    last_water_day = -1L, memory = new_feeding_memory(8),
    observed_intake_kg_dm = numeric(8), observed_feeding_h = numeric(8),
    moved_today = FALSE)
}

feeding_access_capacity <- function(biomass, system) {
  accessible <- pmax(biomass - 200, 0)
  mass <- as.numeric(crossprod(accessible / 10000, system$overlap_m2))
  mass * system$search_area_m2_h / colSums(system$overlap_m2)
}

feeding_access_choice <- function(state, system, day, policy, access,
  return_forecast = feeding_expected_return) {
  here <- match(state$patch_id, system$stations$patch_id)
  if (access %in% c("pooled_search", "pooled_stock")) return(here)
  duration <- system$distances_m[here,] / system$speed_m_h
  cost <- system$distances_m[here,] * system$movement_kj_m
  if (access == "zero_transit") duration[] <- cost[] <- 0
  if (policy == "cyclic") {
    rate <- feeding_access_capacity(state$biomass_kg_dm_ha, system)[here]
    return(if (rate >= .020 - 1e-12) here else here %% 8 + 1L)
  }
  expected <- if (policy == "informed") {
    pmin(.025, feeding_access_capacity(state$biomass_kg_dm_ha, system)) * 10000
  } else return_forecast(state$memory, day,
    search_area_m2_h = system$search_area_m2_h,
    growth_rate_h = system$growth_rate_h,
    senescence_rate_h = system$senescence_rate_h,
    production_saturation_biomass_kg_dm_ha =
      sum(system$K * system$cell_area_ha) / sum(system$cell_area_ha),
    residual_kg_dm_ha = 200)
  choose_feeding_station(here, expected, duration, cost,
    state$memory$inadequacy_kj)
}

step_feeding_access_hour <- function(state, system, hour, day,
  growth_multiplier = 1, water_duration_h = .5, water_cost_kj = 0,
  policy = "experienced", access = "physical", stationary = FALSE,
  return_forecast = feeding_expected_return) {
  stopifnot(policy %in% c("experienced","informed","cyclic"),
    access %in% c("physical","zero_transit","pooled_search","pooled_stock"))
  opening <- state
  if (hour == 0) {
    state$observed_intake_kg_dm[] <- state$observed_feeding_h[] <- 0
    state$moved_today <- FALSE
  }
  plant <- herbivoreTTR::step_responsive_forage(state$biomass_kg_dm_ha,
    system$K, system$growth_rate_h, system$senescence_rate_h, growth_multiplier)
  state$biomass_kg_dm_ha <- plant$state
  ref <- system$fixture$appetite_reference[hour+1L,,drop=FALSE]
  forage_departure <- water_departure <- FALSE
  if (is.null(state$journey) && !stationary) {
    if (state$water$body_water_kg <= 26 && state$last_water_day != day) {
      state$journey <- list(kind="water", total_h=water_duration_h,
        remaining_h=water_duration_h, total_cost_kj=water_cost_kj,
        destination=state$patch_id)
      state$last_water_day <- day
      water_departure <- TRUE
    } else if (hour == 0) {
      here <- match(state$patch_id,system$stations$patch_id)
      dest <- feeding_access_choice(state,system,day,policy,access,return_forecast)
      if (dest != here) {
        state$moved_today <- forage_departure <- TRUE
        state$memory$inadequacy_kj <- 0
        if (access == "zero_transit") state$patch_id <- system$stations$patch_id[dest]
        else {
          distance <- system$distances_m[here,dest]
          state$journey <- list(kind="forage",total_h=distance/system$speed_m_h,
            remaining_h=distance/system$speed_m_h,
            total_cost_kj=distance*system$movement_kj_m,
            destination=system$stations$patch_id[dest])
        }
      }
    }
  }
  travel <- spatial_travel_hour(state)
  state <- travel$state
  here <- match(state$patch_id,system$stations$patch_id)
  feeding_h <- as.numeric(ref$feeding_opportunity_open) * (1-travel$time_h)
  appetite <- herbivoreTTR::calculate_appetite_target(state$gut,state$body,
    system$fixture$food,system$fixture$appetite,ref)
  request <- appetite$appetite_target_dry_matter_intake_kg_dm_h * feeding_h
  overlap <- if (access %in% c("pooled_search","pooled_stock"))
    system$cell_area_ha * 10000 else system$overlap_m2[,here]
  search_rate <- if (access == "pooled_stock" && feeding_h > 0)
    sum(overlap)/feeding_h else system$search_area_m2_h
  removal <- herbivoreTTR::step_footprint_grazing(state$biomass_kg_dm_ha,
    system$cell_area_ha,overlap,request,search_rate,feeding_h,200)
  intake <- removal$fluxes$realized_intake_kg_dm
  state$biomass_kg_dm_ha <- removal$state
  ingested <- intake * 10000
  gut <- herbivoreTTR::step_gut_energy(state$gut,system$fixture$gut,
    data.frame(hour_of_day=hour,prescribed_ingested_available_energy_kj_h=ingested))
  activity <- system$fixture$activity[hour+1L,,drop=FALSE]
  routine <- activity$prescribed_routine_activity_expenditure_kj_h
  maintenance <- system$fixture$body$maintenance_expenditure_kj_h
  activity$prescribed_routine_activity_expenditure_kj_h <- routine+travel$expenditure_kj
  proposed <- state$body$body_energy_reserve_kj+gut$fluxes$assimilated_energy_kj-
    maintenance-routine-travel$expenditure_kj
  if (proposed < 0) return(list(stopped=TRUE,state=opening,
    reason="energy_domain",proposed_body_energy_kj=proposed))
  body <- herbivoreTTR::step_body_energy(state$body,system$fixture$body,
    data.frame(hour_of_day=hour,
      prescribed_assimilated_energy_kj_h=gut$fluxes$assimilated_energy_kj),activity)
  water <- herbivoreTTR::step_body_water(state$water,system$water,
    data.frame(hour_of_day=hour,prescribed_food_derived_water_kg_h=intake*3.28,
      available_drinking_water_kg_h=if (stationary) 10 else travel$drinking_available_kg,
      prescribed_incremental_evaporative_water_loss_kg_h=0))
  state$gut <- gut$state
  state$body <- body$state
  state$water <- water$state
  state$observed_intake_kg_dm[here] <- state$observed_intake_kg_dm[here]+intake
  state$observed_feeding_h[here] <- state$observed_feeding_h[here]+feeding_h
  if (hour == 23) state$memory <- update_feeding_memory(state$memory,
    state$observed_intake_kg_dm,state$observed_feeding_h,day,here,state$moved_today)
  area <- system$cell_area_ha
  growth <- sum(plant$fluxes$growth_kg_dm_ha*area)
  loss <- sum(plant$fluxes$senescence_kg_dm_ha*area)
  mass0 <- sum(opening$biomass_kg_dm_ha*area)
  mass1 <- sum(state$biomass_kg_dm_ha*area)
  ledger <- data.frame(day=day,hour=hour,station=here,
    intake_kg_dm=intake,feeding_h=feeding_h,
    encounter_ceiling_kg_dm=removal$fluxes$encounter_ceiling_kg_dm,
    forage_travel_h=travel$forage_time_h,water_travel_h=travel$water_time_h,
    forage_departure=forage_departure,water_departure=water_departure,
    forage_expenditure_kj=travel$expenditure_kj-travel$water_expenditure_kj,
    water_expenditure_kj=travel$water_expenditure_kj,
    plant_growth_kg_dm=growth,plant_senescence_kg_dm=loss,
    forage_mass_kg_dm=mass1,accessible_mass_kg_dm=sum(pmax(state$biomass_kg_dm_ha-200,0)*area),
    body_energy_kj=state$body$body_energy_reserve_kj,
    gut_energy_kj=state$gut$gut_available_energy_kj,body_water_kg=state$water$body_water_kg,
    drinking_kg=water$fluxes$realized_drinking_water_kg,
    plant_balance_kg_dm=mass1-mass0-growth+loss+intake,
    energy_balance_kj=state$body$body_energy_reserve_kj-opening$body$body_energy_reserve_kj+
      state$gut$gut_available_energy_kj-opening$gut$gut_available_energy_kj-
      ingested+maintenance+routine+travel$expenditure_kj,
    water_balance_kg=water$fluxes$body_water_balance_residual_kg)
  list(stopped=FALSE,state=state,hourly=ledger)
}

feeding_access_daily <- function(hourly) {
  if (!nrow(hourly)) return(data.frame())
  do.call(rbind,lapply(split(hourly,hourly$day),function(d) data.frame(
    day=d$day[1],complete_day=nrow(d)==24,
    body_energy_kj=tail(d$body_energy_kj,1),gut_energy_kj=tail(d$gut_energy_kj,1),
    min_water_kg=min(d$body_water_kg),intake_kg_dm=sum(d$intake_kg_dm),
    feeding_h=sum(d$feeding_h),forage_mass_kg_dm=tail(d$forage_mass_kg_dm,1),
    accessible_mass_kg_dm=tail(d$accessible_mass_kg_dm,1),
    plant_growth_kg_dm=sum(d$plant_growth_kg_dm),plant_senescence_kg_dm=sum(d$plant_senescence_kg_dm),
    forage_travel_h=sum(d$forage_travel_h),water_travel_h=sum(d$water_travel_h),
    forage_expenditure_kj=sum(d$forage_expenditure_kj),water_expenditure_kj=sum(d$water_expenditure_kj),
    forage_departures=sum(d$forage_departure),water_departures=sum(d$water_departure))))
}

run_feeding_access <- function(system, profile="none", water="near",
  policy="experienced", access="physical", final_day=228L, baseline=NULL,
  stationary=FALSE, return_forecast=feeding_expected_return) {
  stopifnot(profile %in% c("none","short_pulse","pulse","sustained"),water %in% c("near","far"))
  if (is.null(baseline)) {
    state <- new_feeding_access_state(system)
    first_day <- 1L
    prefix <- NULL
  } else {
    stopifnot(is.na(baseline$stop_day),tail(baseline$hourly$day,1)==60L)
    state <- baseline$final_state
    first_day <- 61L
    prefix <- baseline$hourly
  }
  initial_branch_state <- state
  rows <- vector("list",(final_day-first_day+1L)*24L)
  k <- 0L
  stop_day <- stop_hour <- NA_integer_
  for (day in seq.int(first_day,final_day)) {
    forced <- (profile=="short_pulse" && day>=61 && day<=67) ||
      (profile=="pulse" && day>=61 && day<=88) ||
      (profile=="sustained" && day>=61 && day<=144)
    far <- water=="far" && day>=61 && day<=144
    for (hour in 0:23) {
      step <- step_feeding_access_hour(state,system,hour,day,
        if (forced) .6 else 1,if (far) 3 else .5,if (far) 900 else 0,
        if (day<=60) "experienced" else policy,
        if (day<=60) "physical" else access,stationary,return_forecast)
      if (step$stopped) { stop_day <- day; stop_hour <- hour; break }
      state <- step$state
      k <- k+1L
      rows[[k]] <- step$hourly
    }
    if (!is.na(stop_day)) break
  }
  hourly <- rbind(prefix,do.call(rbind,rows[seq_len(k)]))
  rownames(hourly) <- NULL
  list(hourly=hourly,daily=feeding_access_daily(hourly),final_state=state,
    initial_branch_state=initial_branch_state,stop_day=stop_day,stop_hour=stop_hour)
}
