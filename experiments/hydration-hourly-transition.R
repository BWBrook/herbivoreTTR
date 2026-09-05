# Compose the public one-hour transitions, without evaluating a future day.
hydration_step_hour <- function(
  context,
  system,
  destination_patch_id,
  hour_of_day,
  incremental_evaporative_water_loss_kg_h
) {
  fixture <- system$fixture
  opening_patch_id <- context$location$patch_id
  patch_index <- match(opening_patch_id, system$landscape$patches$patch_id)
  patch <- system$landscape$patches[patch_index, , drop = FALSE]
  water_index <- match(opening_patch_id, system$water_properties$patch_id)
  water_property <- system$water_properties[water_index, , drop = FALSE]
  moving <- opening_patch_id != destination_patch_id
  movement_kj <- 0
  next_location <- context$location
  if (moving) {
    movement <- herbivoreTTR::step_known_route_movement(
      context$location, system$landscape, destination_patch_id
    )
    if (movement$fluxes$travel_duration_h != 1) {
      stop("The hydration experiment requires one-hour movement legs.")
    }
    movement_kj <- movement$fluxes$incremental_movement_expenditure_kj
    next_location <- movement$state
  }

  reference <- fixture$appetite_reference[
    fixture$appetite_reference$hour_of_day == hour_of_day, , drop = FALSE
  ]
  baseline_feeding_open <- reference$feeding_opportunity_open
  if (moving) {
    reference$feeding_opportunity_open <- FALSE
    reference$reference_dry_matter_intake_kg_dm_h <- 0
  }
  activity <- fixture$activity[
    fixture$activity$hour_of_day == hour_of_day, , drop = FALSE
  ]
  routine_kj <- activity$prescribed_routine_activity_expenditure_kj_h
  activity$prescribed_routine_activity_expenditure_kj_h <-
    routine_kj + movement_kj
  acquisition_ceiling_kg_dm_h <- if (moving) {
    0
  } else {
    patch$forage_acquisition_ceiling_kg_dm_h
  }
  food <- list(metabolizable_energy_density_kj_kg_dm =
    patch$metabolizable_energy_density_kj_kg_dm)

  coupled <- !is.null(context$forage_state)
  next_forage <- context$forage_state
  forage_residual_kg_dm_ha <- 0
  coupling_residual_kg_dm_ha <- 0
  stock_ceiling_active <- FALSE
  if (coupled) {
    turnover <- lapply(next_forage$forage_biomass_kg_dm_ha, function(biomass) {
      herbivoreTTR::step_forage_turnover(
        list(forage_biomass_kg_dm_ha = biomass), system$forage_parameters
      )
    })
    next_forage$forage_biomass_kg_dm_ha <- vapply(
      turnover, function(x) x$state$forage_biomass_kg_dm_ha, numeric(1L)
    )
  }
  appetite <- herbivoreTTR::calculate_appetite_target(
    context$gut, context$body, food, fixture$appetite, reference
  )
  candidate_intake_kg_dm <- min(
    appetite$appetite_target_dry_matter_intake_kg_dm_h,
    acquisition_ceiling_kg_dm_h
  )
  intake_kg_dm <- candidate_intake_kg_dm
  if (coupled) {
    forage_index <- match(opening_patch_id, next_forage$patch_id)
    herbivory <- herbivoreTTR::step_forage_herbivory(
      list(forage_biomass_kg_dm_ha =
        next_forage$forage_biomass_kg_dm_ha[[forage_index]]),
      system$coupling_parameters,
      candidate_intake_kg_dm
    )
    next_forage$forage_biomass_kg_dm_ha[[forage_index]] <-
      herbivory$state$forage_biomass_kg_dm_ha
    intake_kg_dm <- herbivory$fluxes$realized_dry_matter_intake_kg_dm
    stock_ceiling_active <- herbivory$fluxes$forage_stock_ceiling_active
    coupling_residual_kg_dm_ha <-
      herbivory$fluxes$herbivore_forage_coupling_residual_kg_dm_ha
    removal_kg_dm_ha <- numeric(nrow(next_forage))
    removal_kg_dm_ha[[forage_index]] <-
      herbivory$fluxes$herbivory_removal_kg_dm_ha
    growth_kg_dm_ha <- vapply(
      turnover, function(x) x$fluxes$forage_growth_kg_dm_ha, numeric(1L)
    )
    background_loss_kg_dm_ha <- vapply(
      turnover, function(x) x$fluxes$forage_background_loss_kg_dm_ha, numeric(1L)
    )
    forage_residual_kg_dm_ha <- max(abs(
      next_forage$forage_biomass_kg_dm_ha -
        context$forage_state$forage_biomass_kg_dm_ha -
        (growth_kg_dm_ha - background_loss_kg_dm_ha - removal_kg_dm_ha)
    ))
  }

  ingested_kj <- intake_kg_dm * food$metabolizable_energy_density_kj_kg_dm
  gut <- herbivoreTTR::step_gut_energy(
    context$gut, fixture$gut,
    data.frame(hour_of_day = hour_of_day,
      prescribed_ingested_available_energy_kj_h = ingested_kj)
  )
  body <- herbivoreTTR::step_body_energy(
    context$body, fixture$body,
    data.frame(hour_of_day = hour_of_day,
      prescribed_assimilated_energy_kj_h = gut$fluxes$assimilated_energy_kj_h),
    activity
  )
  food_water_kg <- intake_kg_dm *
    water_property$food_derived_water_yield_kg_water_kg_dm
  water <- herbivoreTTR::step_body_water(
    context$water, system$water_parameters,
    data.frame(
      hour_of_day = hour_of_day,
      prescribed_food_derived_water_kg_h = food_water_kg,
      available_drinking_water_kg_h = if (moving) 0 else
        water_property$drinking_water_availability_kg_h,
      prescribed_incremental_evaporative_water_loss_kg_h =
        incremental_evaporative_water_loss_kg_h
    )
  )

  hourly <- data.frame(
    hour_of_day = hour_of_day,
    opening_patch_id = opening_patch_id,
    closing_patch_id = next_location$patch_id,
    spatial_action = if (moving) "move" else "stay",
    feeding_opportunity_open = reference$feeding_opportunity_open,
    food_patch_opportunity_h = as.integer(
      baseline_feeding_open && !moving &&
        patch$forage_acquisition_ceiling_kg_dm_h > 0
    ),
    realized_dry_matter_intake_kg_dm = intake_kg_dm,
    realized_ingested_available_energy_kj = ingested_kj,
    assimilated_energy_kj = gut$fluxes$assimilated_energy_kj,
    incremental_movement_expenditure_kj = movement_kj,
    maintenance_expenditure_kj = body$fluxes$maintenance_expenditure_kj,
    prescribed_routine_activity_expenditure_kj = routine_kj,
    gut_available_energy_start_kj = context$gut$gut_available_energy_kj,
    gut_available_energy_end_kj = gut$state$gut_available_energy_kj,
    body_energy_reserve_start_kj = context$body$body_energy_reserve_kj,
    body_energy_reserve_end_kj = body$state$body_energy_reserve_kj,
    body_water_start_kg = context$water$body_water_kg,
    body_water_end_kg = water$state$body_water_kg,
    food_derived_water_kg = water$fluxes$food_derived_water_kg,
    ordinary_water_loss_kg = water$fluxes$ordinary_water_loss_kg,
    incremental_evaporative_water_loss_kg =
      water$fluxes$incremental_evaporative_water_loss_kg,
    realized_drinking_water_kg = water$fluxes$realized_drinking_water_kg,
    excess_water_elimination_kg = water$fluxes$excess_water_elimination_kg,
    physiological_net_nondrinking_water_draw_kg =
      water$fluxes$ordinary_water_loss_kg +
        water$fluxes$incremental_evaporative_water_loss_kg - food_water_kg,
    body_water_below_critical = water$fluxes$body_water_below_critical,
    gut_energy_balance_residual_kj = gut$fluxes$gut_energy_balance_residual_kj,
    energy_balance_residual_kj = body$fluxes$energy_balance_residual_kj,
    system_energy_balance_residual_kj =
      (gut$state$gut_available_energy_kj -
        context$gut$gut_available_energy_kj) +
      (body$state$body_energy_reserve_kj -
        context$body$body_energy_reserve_kj) -
      (ingested_kj - body$fluxes$maintenance_expenditure_kj -
        routine_kj - movement_kj),
    body_water_balance_residual_kg =
      water$fluxes$body_water_balance_residual_kg,
    max_forage_balance_residual_kg_dm_ha = forage_residual_kg_dm_ha,
    herbivore_forage_coupling_residual_kg_dm_ha = coupling_residual_kg_dm_ha,
    appetite_upper_bound_active = appetite$upper_intake_bound_active,
    forage_acquisition_ceiling_active =
      appetite$appetite_target_dry_matter_intake_kg_dm_h >
        acquisition_ceiling_kg_dm_h,
    forage_stock_ceiling_active = stock_ceiling_active
  )
  context$location <- next_location
  context$gut <- gut$state
  context$body <- body$state
  context$water <- water$state
  context$forage_state <- next_forage
  list(context = context, hourly = hourly)
}
