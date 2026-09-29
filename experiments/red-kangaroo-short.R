# Short (1985) acquisition diagnostic for the approved red-kangaroo benchmark.
#
# This is a no-write experiment client.  It uses the package's public
# step_forage_herbivory() primitive for the shared-yard removal, while keeping
# the prescribed net plant flux and observation operator explicit here.  See
# docs/red-kangaroo-benchmark-specification.md for the frozen design.

if (!exists("red_kangaroo_anchor_records", mode = "function")) {
  record_path <- file.path("experiments", "red-kangaroo-records.R")
  if (!file.exists(record_path)) {
    stop("Run this experiment from the repository root.", call. = FALSE)
  }
  source(record_path)
}

.short_observations <- function() {
  observations <- read.csv(
    file.path("references", "short-1985-figure4.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  observations$yard <- as.integer(observations$yard)
  observations
}

.short_scenario_id <- function(search_multiplier, residual, net_flux) {
  paste0(
    "S", format(search_multiplier, trim = TRUE, nsmall = 1),
    "_R", format(residual, trim = TRUE, nsmall = 0),
    "_phi", format(net_flux, trim = TRUE, nsmall = 1)
  )
}

.short_scenario_design <- function(records) {
  short <- records$short
  reference_search_area_m2_day <- short$fitted_asymptote_kg_dm_day /
    short$fitted_density_scale_kg_dm_ha * 10000
  design <- expand.grid(
    search_multiplier = c(0.5, 1, 2),
    residual_kg_dm_ha = c(0, 20),
    net_plant_flux_kg_dm_ha_day = c(-2.5, 0, 2.5),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  design$scenario_id <- mapply(
    .short_scenario_id,
    design$search_multiplier,
    design$residual_kg_dm_ha,
    design$net_plant_flux_kg_dm_ha_day,
    USE.NAMES = FALSE
  )
  design$search_area_m2_day <- reference_search_area_m2_day *
    design$search_multiplier
  design$daily_cap_kg_dm_day <- short$fitted_asymptote_kg_dm_day
  design$animals_per_yard <- short$animals_per_yard
  design$yard_area_m2 <- short$yard_area_ha * 10000
  design$density_animals_ha <- short$animals_per_yard /
    short$yard_area_ha
  design[, c(
    "scenario_id", "search_multiplier", "search_area_m2_day",
    "daily_cap_kg_dm_day", "residual_kg_dm_ha",
    "net_plant_flux_kg_dm_ha_day", "animals_per_yard", "yard_area_m2",
    "density_animals_ha"
  )]
}

.short_reference_search_area <- function(records) {
  records$short$fitted_asymptote_kg_dm_day /
    records$short$fitted_density_scale_kg_dm_ha * 10000
}

.short_apply_net_plant_flux <- function(
  biomass_kg_dm_ha,
  net_plant_flux_kg_dm_ha_day,
  dt_h
) {
  prescribed_change_kg_dm_ha <- net_plant_flux_kg_dm_ha_day * dt_h / 24
  prescribed_growth_kg_dm_ha <- max(prescribed_change_kg_dm_ha, 0)
  prescribed_loss_kg_dm_ha <- max(-prescribed_change_kg_dm_ha, 0)
  actual_loss_kg_dm_ha <- min(biomass_kg_dm_ha, prescribed_loss_kg_dm_ha)
  actual_growth_kg_dm_ha <- prescribed_growth_kg_dm_ha
  closing_biomass_kg_dm_ha <- biomass_kg_dm_ha +
    actual_growth_kg_dm_ha - actual_loss_kg_dm_ha
  unmet_loss_kg_dm_ha <- prescribed_loss_kg_dm_ha - actual_loss_kg_dm_ha
  list(
    biomass_before_grazing_kg_dm_ha = closing_biomass_kg_dm_ha,
    prescribed_growth_kg_dm_ha = prescribed_growth_kg_dm_ha,
    prescribed_loss_kg_dm_ha = prescribed_loss_kg_dm_ha,
    actual_growth_kg_dm_ha = actual_growth_kg_dm_ha,
    actual_loss_kg_dm_ha = actual_loss_kg_dm_ha,
    unmet_loss_kg_dm_ha = unmet_loss_kg_dm_ha
  )
}

.short_empty_hourly <- function(n_steps) {
  data.frame(
    step = seq_len(n_steps),
    dt_h = rep(NA_real_, n_steps),
    time_start_h = rep(NA_real_, n_steps),
    day_start = rep(NA_real_, n_steps),
    biomass_start_kg_dm_ha = rep(NA_real_, n_steps),
    prescribed_growth_kg_dm_ha = rep(NA_real_, n_steps),
    prescribed_loss_kg_dm_ha = rep(NA_real_, n_steps),
    actual_growth_kg_dm_ha = rep(NA_real_, n_steps),
    actual_loss_kg_dm_ha = rep(NA_real_, n_steps),
    unmet_loss_kg_dm_ha = rep(NA_real_, n_steps),
    biomass_before_grazing_kg_dm_ha = rep(NA_real_, n_steps),
    candidate_intake_kg_dm = rep(NA_real_, n_steps),
    accessible_per_animal_kg_dm = rep(NA_real_, n_steps),
    cap_limited = rep(NA, n_steps),
    encounter_limited = rep(NA, n_steps),
    stock_limited = rep(NA, n_steps),
    realized_intake_kg_dm = rep(NA_real_, n_steps),
    removal_kg_dm_ha = rep(NA_real_, n_steps),
    biomass_end_kg_dm_ha = rep(NA_real_, n_steps),
    forage_balance_residual_kg_dm_ha = rep(NA_real_, n_steps),
    coupling_balance_residual_kg_dm_ha = rep(NA_real_, n_steps),
    stringsAsFactors = FALSE
  )
}

.short_simulate_window <- function(
  initial_biomass_kg_dm_ha,
  scenario,
  records,
  dt_h = 1,
  keep_hourly = FALSE
) {
  short <- records$short
  n_steps <- as.integer(round(4 * 24 / dt_h))
  if (abs(n_steps * dt_h - 4 * 24) > 1e-10 || dt_h <= 0) {
    stop("`dt_h` must divide the four-day window.", call. = FALSE)
  }
  density <- short$animals_per_yard / short$yard_area_ha
  coupling <- herbivoreTTR::new_nonspatial_coupling_parameters(
    density,
    scenario$residual_kg_dm_ha
  )
  cap_per_interval_kg_dm <- scenario$daily_cap_kg_dm_day * dt_h / 24
  search_area_m2_interval <- scenario$search_area_m2_day * dt_h / 24

  hourly <- .short_empty_hourly(n_steps)
  biomass <- as.double(initial_biomass_kg_dm_ha)
  for (step in seq_len(n_steps)) {
    flux <- .short_apply_net_plant_flux(
      biomass,
      scenario$net_plant_flux_kg_dm_ha_day,
      dt_h
    )
    before_grazing <- flux$biomass_before_grazing_kg_dm_ha
    accessible <- max(before_grazing - scenario$residual_kg_dm_ha, 0)
    encounter_per_animal <- search_area_m2_interval * accessible / 10000
    candidate <- min(cap_per_interval_kg_dm, encounter_per_animal)
    herbivory <- herbivoreTTR::step_forage_herbivory(
      herbivoreTTR::new_forage_biomass_state(before_grazing),
      coupling,
      candidate
    )
    biomass_end <- herbivory$state$forage_biomass_kg_dm_ha

    hourly$dt_h[[step]] <- dt_h
    hourly$time_start_h[[step]] <- (step - 1) * dt_h
    hourly$day_start[[step]] <- hourly$time_start_h[[step]] / 24
    hourly$biomass_start_kg_dm_ha[[step]] <- biomass
    hourly$prescribed_growth_kg_dm_ha[[step]] <-
      flux$prescribed_growth_kg_dm_ha
    hourly$prescribed_loss_kg_dm_ha[[step]] <- flux$prescribed_loss_kg_dm_ha
    hourly$actual_growth_kg_dm_ha[[step]] <- flux$actual_growth_kg_dm_ha
    hourly$actual_loss_kg_dm_ha[[step]] <- flux$actual_loss_kg_dm_ha
    hourly$unmet_loss_kg_dm_ha[[step]] <- flux$unmet_loss_kg_dm_ha
    hourly$biomass_before_grazing_kg_dm_ha[[step]] <- before_grazing
    hourly$candidate_intake_kg_dm[[step]] <- candidate
    hourly$accessible_per_animal_kg_dm[[step]] <-
      herbivory$fluxes$accessible_forage_per_animal_kg_dm
    hourly$cap_limited[[step]] <- cap_per_interval_kg_dm <
      encounter_per_animal
    hourly$encounter_limited[[step]] <- encounter_per_animal <=
      cap_per_interval_kg_dm
    hourly$stock_limited[[step]] <- herbivory$fluxes$forage_stock_ceiling_active
    hourly$realized_intake_kg_dm[[step]] <-
      herbivory$fluxes$realized_dry_matter_intake_kg_dm
    hourly$removal_kg_dm_ha[[step]] <-
      herbivory$fluxes$herbivory_removal_kg_dm_ha
    hourly$biomass_end_kg_dm_ha[[step]] <- biomass_end
    hourly$forage_balance_residual_kg_dm_ha[[step]] <-
      biomass_end - before_grazing + hourly$removal_kg_dm_ha[[step]]
    hourly$coupling_balance_residual_kg_dm_ha[[step]] <-
      herbivory$fluxes$herbivore_forage_coupling_residual_kg_dm_ha
    biomass <- biomass_end
  }

  snapshot_index <- c(
    day0 = 0L,
    day2 = as.integer(round(2 * 24 / dt_h)),
    day4 = n_steps
  )
  b_snap <- c(
    B0_kg_dm_ha = initial_biomass_kg_dm_ha,
    B2_kg_dm_ha = hourly$biomass_end_kg_dm_ha[[snapshot_index[["day2"]]]],
    B4_kg_dm_ha = hourly$biomass_end_kg_dm_ha[[snapshot_index[["day4"]]]]
  )
  stock_loss_1 <- 1000 * (b_snap[["B0_kg_dm_ha"]] -
    b_snap[["B2_kg_dm_ha"]]) / (density * 2)
  stock_loss_2 <- 1000 * (b_snap[["B2_kg_dm_ha"]] -
    b_snap[["B4_kg_dm_ha"]]) / (density * 2)
  summary <- data.frame(
    initial_biomass_kg_dm_ha = initial_biomass_kg_dm_ha,
    dt_h = dt_h,
    B0_kg_dm_ha = b_snap[["B0_kg_dm_ha"]],
    B2_kg_dm_ha = b_snap[["B2_kg_dm_ha"]],
    B4_kg_dm_ha = b_snap[["B4_kg_dm_ha"]],
    V0_kg_dm_ha = b_snap[["B0_kg_dm_ha"]],
    V2_kg_dm_ha = b_snap[["B2_kg_dm_ha"]],
    V4_kg_dm_ha = b_snap[["B4_kg_dm_ha"]],
    interval_stock_loss_1_g_dm_animal_day = stock_loss_1,
    interval_stock_loss_2_g_dm_animal_day = stock_loss_2,
    smoothed_stock_loss_g_dm_animal_day = mean(c(stock_loss_1, stock_loss_2)),
    total_intake_kg_dm_animal = sum(hourly$realized_intake_kg_dm),
    total_removal_kg_dm_ha = sum(hourly$removal_kg_dm_ha),
    total_growth_kg_dm_ha = sum(hourly$actual_growth_kg_dm_ha),
    total_loss_kg_dm_ha = sum(hourly$actual_loss_kg_dm_ha),
    total_prescribed_loss_kg_dm_ha = sum(hourly$prescribed_loss_kg_dm_ha),
    total_unmet_loss_kg_dm_ha = sum(hourly$unmet_loss_kg_dm_ha),
    total_net_plant_change_kg_dm_ha =
      sum(hourly$actual_growth_kg_dm_ha) - sum(hourly$actual_loss_kg_dm_ha),
    stock_loss_minus_ingestion_g_dm_animal_day = mean(c(stock_loss_1, stock_loss_2)) -
      1000 * sum(hourly$realized_intake_kg_dm) / 4,
    cap_limited_intervals = sum(hourly$cap_limited),
    encounter_limited_intervals = sum(hourly$encounter_limited),
    stock_limited_intervals = sum(hourly$stock_limited),
    min_biomass_before_grazing_kg_dm_ha =
      min(hourly$biomass_before_grazing_kg_dm_ha),
    min_biomass_end_kg_dm_ha = min(hourly$biomass_end_kg_dm_ha),
    min_accessible_after_residual_kg_dm_ha = min(
      pmax(hourly$biomass_before_grazing_kg_dm_ha -
        scenario$residual_kg_dm_ha, 0)
    ),
    min_residual_margin_when_accessible_kg_dm_ha = {
      accessible_rows <- hourly$biomass_before_grazing_kg_dm_ha >=
        scenario$residual_kg_dm_ha
      if (any(accessible_rows)) {
        min(hourly$biomass_end_kg_dm_ha[accessible_rows] -
          scenario$residual_kg_dm_ha)
      } else {
        NA_real_
      }
    },
    max_forage_balance_residual_kg_dm_ha = max(
      abs(hourly$forage_balance_residual_kg_dm_ha)
    ),
    max_coupling_balance_residual_kg_dm_ha = max(
      abs(hourly$coupling_balance_residual_kg_dm_ha)
    ),
    stringsAsFactors = FALSE
  )
  list(
    summary = summary,
    hourly = if (keep_hourly) hourly else NULL
  )
}

.short_response_loci <- function(records, design, initial_stocks) {
  rows <- vector("list", nrow(design) * length(initial_stocks))
  index <- 0L
  for (scenario_index in seq_len(nrow(design))) {
    scenario <- design[scenario_index, , drop = FALSE]
    for (initial_biomass in initial_stocks) {
      index <- index + 1L
      rows[[index]] <- cbind(
        scenario,
        .short_simulate_window(
          initial_biomass,
          scenario,
          records,
          dt_h = 1,
          keep_hourly = FALSE
        )$summary
      )
    }
  }
  do.call(rbind, rows)
}

.short_r200_control <- function(records, initial_stocks) {
  reference <- .short_scenario_design(records)
  control <- reference[
    reference$scenario_id == .short_scenario_id(1, 0, 0),
    , drop = FALSE
  ]
  control$scenario_id <- "R200_control"
  control$residual_kg_dm_ha <- 200
  rows <- lapply(initial_stocks, function(initial_biomass) {
    cbind(
      control,
      .short_simulate_window(
        initial_biomass,
        control,
        records,
        dt_h = 1,
        keep_hourly = FALSE
      )$summary
    )
  })
  do.call(rbind, rows)
}

.short_pairing_definitions <- function(primary_scenario_id) {
  definitions <- data.frame(
    x_pairing = c("opening", "midpoint", "closing"),
    j_offset_kg_dm_ha = c(0, 0, 0),
    pairing_scope = rep("declared_grid", 3),
    stringsAsFactors = FALSE
  )
  definitions <- rbind(
    do.call(rbind, lapply(c(0, 84), function(j) {
      data.frame(
        x_pairing = c("opening", "midpoint", "closing"),
        j_offset_kg_dm_ha = j,
        pairing_scope = "declared_grid",
        stringsAsFactors = FALSE
      )
    })),
    data.frame(
      x_pairing = "endpoint_weighted",
      j_offset_kg_dm_ha = 0,
      pairing_scope = "primary_sensitivity",
      stringsAsFactors = FALSE
    )
  )
  definitions$transform_id <- paste0(
    definitions$x_pairing, "_J", definitions$j_offset_kg_dm_ha
  )
  definitions
}

.short_transform_x <- function(row, pairing, j_offset) {
  v0 <- row$V0_kg_dm_ha + j_offset
  v2 <- row$V2_kg_dm_ha + j_offset
  v4 <- row$V4_kg_dm_ha + j_offset
  switch(
    pairing,
    opening = v0,
    midpoint = v2,
    closing = v4,
    endpoint_weighted = (v0 + 2 * v2 + v4) / 4,
    stop("Unknown Short x pairing.", call. = FALSE)
  )
}

.short_response_transforms <- function(response_loci, definitions) {
  rows <- vector("list", nrow(response_loci) * nrow(definitions))
  index <- 0L
  for (definition_index in seq_len(nrow(definitions))) {
    definition <- definitions[definition_index, , drop = FALSE]
    use <- response_loci$scenario_id == response_loci$scenario_id
    if (definition$x_pairing == "endpoint_weighted") {
      use <- response_loci$scenario_id == .short_scenario_id(1, 0, 0)
    }
    selected <- response_loci[use, , drop = FALSE]
    if (!nrow(selected)) next
    selected$model_x_combined_vegetation_kg_dm_ha <- vapply(
      seq_len(nrow(selected)),
      function(i) .short_transform_x(
        selected[i, , drop = FALSE],
        definition$x_pairing,
        definition$j_offset_kg_dm_ha
      ),
      numeric(1L)
    )
    selected$x_pairing <- definition$x_pairing
    selected$j_offset_kg_dm_ha <- definition$j_offset_kg_dm_ha
    selected$pairing_scope <- definition$pairing_scope
    selected$transform_id <- definition$transform_id
    index <- index + 1L
    rows[[index]] <- selected
  }
  do.call(rbind, rows[seq_len(index)])
}

.short_interpolate <- function(x, y, xout) {
  keep <- is.finite(x) & is.finite(y)
  if (!any(keep)) return(rep(NA_real_, length(xout)))
  x <- x[keep]
  y <- y[keep]
  order_index <- order(x, y)
  x <- x[order_index]
  y <- y[order_index]
  unique_x <- !duplicated(x)
  x <- x[unique_x]
  y <- y[unique_x]
  if (length(x) == 1L) {
    return(ifelse(xout == x, y, NA_real_))
  }
  approx(x, y, xout = xout, rule = 1, ties = "ordered")$y
}

.short_observation_transforms <- function(observations, definitions, records) {
  rows <- vector("list", nrow(observations) * nrow(definitions))
  index <- 0L
  for (definition_index in seq_len(nrow(definitions))) {
    definition <- definitions[definition_index, , drop = FALSE]
    selected <- observations
    selected$x_pairing <- definition$x_pairing
    selected$j_offset_kg_dm_ha <- definition$j_offset_kg_dm_ha
    selected$pairing_scope <- definition$pairing_scope
    selected$transform_id <- definition$transform_id
    selected$x_observed_combined_vegetation_kg_dm_ha <-
      selected$vegetation_kg_dm_ha
    selected$published_curve_density_scale_kg_dm_ha <-
      records$short$fitted_density_scale_kg_dm_ha
    selected$published_curve_predicted_intake_g_dm_animal_day <-
      1000 * records$short$fitted_asymptote_kg_dm_day *
        (1 - exp(-selected$vegetation_kg_dm_ha /
          records$short$fitted_density_scale_kg_dm_ha))
    index <- index + 1L
    rows[[index]] <- selected
  }
  do.call(rbind, rows[seq_len(index)])
}

.short_point_predictions <- function(
  response_transforms,
  observation_transforms
) {
  keys <- unique(response_transforms[, c(
    "scenario_id", "x_pairing", "j_offset_kg_dm_ha", "transform_id"
  )])
  rows <- vector("list", nrow(keys))
  for (key_index in seq_len(nrow(keys))) {
    key <- keys[key_index, , drop = FALSE]
    curve <- response_transforms[
      response_transforms$scenario_id == key$scenario_id &
        response_transforms$x_pairing == key$x_pairing &
        response_transforms$j_offset_kg_dm_ha == key$j_offset_kg_dm_ha &
        response_transforms$transform_id == key$transform_id,
      , drop = FALSE
    ]
    points <- observation_transforms[
      observation_transforms$x_pairing == key$x_pairing &
        observation_transforms$j_offset_kg_dm_ha == key$j_offset_kg_dm_ha &
        observation_transforms$transform_id == key$transform_id,
      , drop = FALSE
    ]
    predicted <- .short_interpolate(
      curve$model_x_combined_vegetation_kg_dm_ha,
      curve$smoothed_stock_loss_g_dm_animal_day,
      points$x_observed_combined_vegetation_kg_dm_ha
    )
    points$scenario_id <- key$scenario_id
    points$predicted_intake_g_dm_animal_day <- predicted
    points$residual_g_dm_animal_day <- predicted - points$intake_g_dm_day
    points$x_supported <- is.finite(predicted)
    points$curve_support_min_kg_dm_ha <- min(curve$model_x_combined_vegetation_kg_dm_ha)
    points$curve_support_max_kg_dm_ha <- max(curve$model_x_combined_vegetation_kg_dm_ha)
    points$x_interval_lower_kg_dm_ha <-
      points$x_observed_combined_vegetation_kg_dm_ha -
      points$x_reading_allowance_kg_dm_ha
    points$x_interval_upper_kg_dm_ha <-
      points$x_observed_combined_vegetation_kg_dm_ha +
      points$x_reading_allowance_kg_dm_ha
    points$x_interval_supported <-
      points$x_interval_upper_kg_dm_ha >= points$curve_support_min_kg_dm_ha &
      points$x_interval_lower_kg_dm_ha <= points$curve_support_max_kg_dm_ha
    supported_lower <- pmax(
      points$x_interval_lower_kg_dm_ha,
      points$curve_support_min_kg_dm_ha
    )
    supported_upper <- pmin(
      points$x_interval_upper_kg_dm_ha,
      points$curve_support_max_kg_dm_ha
    )
    points$model_y_at_x_interval_lower_g_dm_animal_day <- .short_interpolate(
      curve$model_x_combined_vegetation_kg_dm_ha,
      curve$smoothed_stock_loss_g_dm_animal_day,
      supported_lower
    )
    points$model_y_at_x_interval_upper_g_dm_animal_day <- .short_interpolate(
      curve$model_x_combined_vegetation_kg_dm_ha,
      curve$smoothed_stock_loss_g_dm_animal_day,
      supported_upper
    )
    points$model_y_interval_lower_g_dm_animal_day <- pmin(
      points$model_y_at_x_interval_lower_g_dm_animal_day,
      points$model_y_at_x_interval_upper_g_dm_animal_day
    )
    points$model_y_interval_upper_g_dm_animal_day <- pmax(
      points$model_y_at_x_interval_lower_g_dm_animal_day,
      points$model_y_at_x_interval_upper_g_dm_animal_day
    )
    points$observation_y_interval_lower_g_dm_animal_day <-
      points$intake_g_dm_day - points$y_reading_allowance_g_dm_day
    points$observation_y_interval_upper_g_dm_animal_day <-
      points$intake_g_dm_day + points$y_reading_allowance_g_dm_day
    points$overlap_under_digitization_allowance <- points$x_interval_supported &
      pmax(
        points$model_y_interval_lower_g_dm_animal_day,
        points$observation_y_interval_lower_g_dm_animal_day
      ) <= pmin(
        points$model_y_interval_upper_g_dm_animal_day,
        points$observation_y_interval_upper_g_dm_animal_day
      )
    rows[[key_index]] <- points
  }
  do.call(rbind, rows)
}

.short_rmse <- function(point_predictions) {
  keys <- unique(point_predictions[, c(
    "scenario_id", "x_pairing", "j_offset_kg_dm_ha", "transform_id"
  )])
  rows <- vector("list", nrow(keys) * 3L)
  index <- 0L
  for (key_index in seq_len(nrow(keys))) {
    key <- keys[key_index, , drop = FALSE]
    selected <- point_predictions[
      point_predictions$scenario_id == key$scenario_id &
        point_predictions$x_pairing == key$x_pairing &
        point_predictions$j_offset_kg_dm_ha == key$j_offset_kg_dm_ha &
        point_predictions$transform_id == key$transform_id,
      , drop = FALSE
    ]
    for (scope in c("overall", "yard1", "yard2")) {
      scoped <- if (scope == "overall") selected else selected[
        selected$yard == as.integer(sub("yard", "", scope)),
        , drop = FALSE
      ]
      supported <- scoped[scoped$x_supported, , drop = FALSE]
      index <- index + 1L
      rows[[index]] <- data.frame(
        scenario_id = key$scenario_id,
        x_pairing = key$x_pairing,
        j_offset_kg_dm_ha = key$j_offset_kg_dm_ha,
        transform_id = key$transform_id,
        scope = scope,
        n_points = nrow(scoped),
        n_supported = nrow(supported),
        rmse_g_dm_animal_day = if (nrow(supported)) {
          sqrt(mean(supported$residual_g_dm_animal_day^2))
        } else {
          NA_real_
        },
        n_overlap_under_digitization_allowance = sum(
          supported$overlap_under_digitization_allowance
        ),
        all_supported = nrow(supported) == nrow(scoped),
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows[seq_len(index)])
}

.short_published_curve_rmse <- function(published_curve_reference) {
  rows <- lapply(c("overall", "yard1", "yard2"), function(scope) {
    selected <- if (scope == "overall") {
      published_curve_reference
    } else {
      published_curve_reference[
        published_curve_reference$yard == as.integer(sub("yard", "", scope)),
        , drop = FALSE
      ]
    }
    residual <- selected$published_curve_predicted_intake_g_dm_animal_day -
      selected$intake_g_dm_day
    data.frame(
      reference = "Short_1985_published_curve",
      scope = scope,
      n_points = nrow(selected),
      rmse_g_dm_animal_day = sqrt(mean(residual^2)),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

.short_aliasing <- function(records, initial_stocks) {
  alias_design <- data.frame(
    alias_id = c("R0_J84", "R20_J64"),
    residual_kg_dm_ha = c(0, 20),
    j_offset_kg_dm_ha = c(84, 64),
    stringsAsFactors = FALSE
  )
  scenario <- data.frame(
    scenario_id = "alias",
    search_multiplier = 1,
    search_area_m2_day = .short_reference_search_area(records),
    daily_cap_kg_dm_day = records$short$fitted_asymptote_kg_dm_day,
    residual_kg_dm_ha = 0,
    net_plant_flux_kg_dm_ha_day = 0,
    animals_per_yard = records$short$animals_per_yard,
    yard_area_m2 = records$short$yard_area_ha * 10000,
    density_animals_ha = records$short$animals_per_yard / records$short$yard_area_ha,
    stringsAsFactors = FALSE
  )
  curves <- vector("list", 2L)
  for (i in seq_len(2L)) {
    scenario$residual_kg_dm_ha <- alias_design$residual_kg_dm_ha[[i]]
    result <- lapply(initial_stocks, function(initial) {
      sim <- .short_simulate_window(initial, scenario, records, dt_h = 1)
      summary <- sim$summary
      summary$model_x_opening <- summary$V0_kg_dm_ha +
        alias_design$j_offset_kg_dm_ha[[i]]
      summary$model_x_midpoint <- summary$V2_kg_dm_ha +
        alias_design$j_offset_kg_dm_ha[[i]]
      summary$model_x_closing <- summary$V4_kg_dm_ha +
        alias_design$j_offset_kg_dm_ha[[i]]
      summary
    })
    curves[[i]] <- do.call(rbind, result)
  }
  summary_rows <- lapply(
    c("opening", "midpoint", "closing"),
    function(pairing) {
      x_a <- curves[[1]][[paste0("model_x_", pairing)]]
      x_b <- curves[[2]][[paste0("model_x_", pairing)]]
      common_lower <- max(min(x_a), min(x_b))
      common_upper <- min(max(x_a), max(x_b))
      common_x <- seq(
        ceiling(common_lower / 5) * 5,
        floor(common_upper / 5) * 5,
        by = 5
      )
      y_a <- .short_interpolate(
        x_a,
        curves[[1]]$smoothed_stock_loss_g_dm_animal_day,
        common_x
      )
      y_b <- .short_interpolate(
        x_b,
        curves[[2]]$smoothed_stock_loss_g_dm_animal_day,
        common_x
      )
      data.frame(
        pairing = pairing,
        alias_a = alias_design$alias_id[[1L]],
        alias_b = alias_design$alias_id[[2L]],
        common_support_lower_kg_dm_ha = common_lower,
        common_support_upper_kg_dm_ha = common_upper,
        n_common_points = length(common_x),
        max_abs_difference_g_dm_animal_day = max(abs(y_a - y_b)),
        mean_abs_difference_g_dm_animal_day = mean(abs(y_a - y_b)),
        pass_machine_tolerance = max(abs(y_a - y_b)) < 1e-10,
        stringsAsFactors = FALSE
      )
    }
  )
  do.call(rbind, summary_rows)
}

.short_check <- function(check_id, value, tolerance, pass, detail) {
  data.frame(
    check_id = check_id,
    value = as.double(value),
    tolerance = as.double(tolerance),
    pass = isTRUE(pass),
    detail = detail,
    stringsAsFactors = FALSE
  )
}

.short_analytical_checks <- function(records, design, response_loci, aliasing) {
  primary <- design[design$scenario_id == .short_scenario_id(1, 0, 0), , drop = FALSE]
  uncapped <- .short_simulate_window(10, primary, records, dt_h = 1)$summary
  k <- primary$density_animals_ha * primary$search_area_m2_day / (10000 * 24)
  uncapped_expected <- 10 * (1 - k)^96
  cap_bound <- .short_simulate_window(700, primary, records, dt_h = 1)$summary
  cap_expected <- 700 - primary$density_animals_ha *
    primary$daily_cap_kg_dm_day / 24 * 96
  primitive <- herbivoreTTR::step_forage_herbivory(
    herbivoreTTR::new_forage_biomass_state(1000),
    herbivoreTTR::new_nonspatial_coupling_parameters(50, 0),
    0.02
  )
  no_growth <- response_loci[
    response_loci$scenario_id == primary$scenario_id &
      response_loci$initial_biomass_kg_dm_ha == 700,
    , drop = FALSE
  ]
  no_growth_identity <- no_growth$V0_kg_dm_ha - no_growth$V4_kg_dm_ha -
    50 * no_growth$total_intake_kg_dm_animal
  curve <- response_loci[
    response_loci$scenario_id == primary$scenario_id,
    , drop = FALSE
  ]
  outside <- .short_interpolate(
    curve$V2_kg_dm_ha,
    curve$smoothed_stock_loss_g_dm_animal_day,
    c(min(curve$V2_kg_dm_ha) - 1, max(curve$V2_kg_dm_ha) + 1)
  )
  transformed <- .short_response_transforms(
    curve,
    .short_pairing_definitions(primary$scenario_id)
  )
  expected_x <- with(curve, V2_kg_dm_ha)
  actual_x <- transformed$model_x_combined_vegetation_kg_dm_ha[
    transformed$x_pairing == "midpoint" & transformed$j_offset_kg_dm_ha == 0
  ]
  expected_x_error <- max(abs(sort(actual_x) - sort(expected_x)))
  min_b <- min(response_loci$min_biomass_end_kg_dm_ha)
  min_residual_margin <- min(
    response_loci$min_residual_margin_when_accessible_kg_dm_ha,
    na.rm = TRUE
  )
  rbind(
    .short_check(
      "reference_search_scale",
      design$search_area_m2_day[design$search_multiplier == 1][[1L]],
      1e-12,
      abs(
        design$search_area_m2_day[design$search_multiplier == 1][[1L]] -
          .short_reference_search_area(records)
      ) < 1e-12,
      "Reference S is (0.709 / 84) * 10000 = 84.4047619 m2/day."
    ),
    .short_check(
      "density_scaling", primitive$fluxes$herbivory_removal_kg_dm_ha,
      1e-12, abs(primitive$fluxes$herbivory_removal_kg_dm_ha - 1) < 1e-12,
      "D=50 scales 0.02 kg DM per animal to 1 kg DM/ha removal."
    ),
    .short_check(
      "uncapped_discrete_depletion", uncapped$B4_kg_dm_ha,
      1e-10, abs(uncapped$B4_kg_dm_ha - uncapped_expected) < 1e-10,
      "Low-stock reference matches the exact discrete encounter depletion."
    ),
    .short_check(
      "cap_binding_linear_depletion", cap_bound$B4_kg_dm_ha,
      1e-10, abs(cap_bound$B4_kg_dm_ha - cap_expected) < 1e-10,
      "High-stock reference matches the fixed daily cap depletion."
    ),
    .short_check(
      "no_growth_stock_loss_identity", max(abs(no_growth_identity)),
      1e-10, max(abs(no_growth_identity)) < 1e-10,
      "With zero net plant flux, stock loss equals D times animal intake."
    ),
    .short_check(
      "nonnegative_stock", min_b, 1e-10, min_b >= -1e-10,
      "All hourly closing edible stocks are non-negative."
    ),
    .short_check(
      "residual_protection", min_residual_margin, 1e-10,
      min_residual_margin >= -1e-10,
      "When opening stock is above R, grazing leaves R protected."
    ),
    .short_check(
      "unmatched_interpolation_is_na", sum(is.na(outside)), 0,
      all(is.na(outside)),
      "Interpolation reports NA outside each supported response locus."
    ),
    .short_check(
      "midpoint_transform_formula", expected_x_error, 1e-12,
      expected_x_error < 1e-12,
      "Midpoint V transform is the day-2 combined stock."
    ),
    .short_check(
      "aliasing_machine_check", max(aliasing$max_abs_difference_g_dm_animal_day),
      1e-10,
      all(aliasing$pass_machine_tolerance),
      "Matched total offsets (R,J)=(0,84) and (20,64) coincide on common support."
    )
  )
}

.short_half_hour_check <- function(records, design, primary_response) {
  primary <- design[design$scenario_id == .short_scenario_id(1, 0, 0), , drop = FALSE]
  rows <- lapply(primary_response$initial_biomass_kg_dm_ha, function(initial) {
    hour <- .short_simulate_window(initial, primary, records, dt_h = 1)$summary
    half <- .short_simulate_window(initial, primary, records, dt_h = 0.5)$summary
    differences <- c(
      B2_kg_dm_ha = half$B2_kg_dm_ha - hour$B2_kg_dm_ha,
      B4_kg_dm_ha = half$B4_kg_dm_ha - hour$B4_kg_dm_ha,
      total_intake_g_dm_animal = 1000 * (
        half$total_intake_kg_dm_animal - hour$total_intake_kg_dm_animal
      ),
      smoothed_stock_loss_g_dm_animal_day =
        half$smoothed_stock_loss_g_dm_animal_day -
          hour$smoothed_stock_loss_g_dm_animal_day
    )
    data.frame(
      initial_biomass_kg_dm_ha = initial,
      max_abs_stock_difference_kg_dm_ha = max(abs(differences[c(
        "B2_kg_dm_ha", "B4_kg_dm_ha"
      )])),
      max_abs_response_difference_g_dm_animal_day = abs(
        differences[["smoothed_stock_loss_g_dm_animal_day"]]
      ),
      abs_total_intake_difference_g_dm_animal = abs(
        differences[["total_intake_g_dm_animal"]]
      ),
      difference_B2_kg_dm_ha = differences[["B2_kg_dm_ha"]],
      difference_B4_kg_dm_ha = differences[["B4_kg_dm_ha"]],
      difference_total_intake_g_dm_animal = differences[["total_intake_g_dm_animal"]],
      difference_smoothed_stock_loss_g_dm_animal_day = differences[[
        "smoothed_stock_loss_g_dm_animal_day"
      ]],
      within_digitization_allowances =
        max(abs(differences[c("B2_kg_dm_ha", "B4_kg_dm_ha")])) <= 10 &
        abs(differences[["smoothed_stock_loss_g_dm_animal_day"]]) <= 20,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

run_short_kangaroo_benchmark <- function() {
  records <- red_kangaroo_anchor_records()
  observations <- .short_observations()
  design <- .short_scenario_design(records)
  initial_stocks <- seq(0, 700, by = 5)
  response_loci <- .short_response_loci(records, design, initial_stocks)
  r200_control <- .short_r200_control(records, initial_stocks)
  definitions <- .short_pairing_definitions(.short_scenario_id(1, 0, 0))
  response_transforms <- .short_response_transforms(response_loci, definitions)
  r200_definitions <- definitions[
    definitions$j_offset_kg_dm_ha == 0 &
      definitions$x_pairing %in% c("opening", "midpoint", "closing"),
    , drop = FALSE
  ]
  r200_response_transforms <- .short_response_transforms(
    r200_control,
    r200_definitions
  )
  observation_transforms <- .short_observation_transforms(
    observations,
    definitions,
    records
  )
  point_predictions <- .short_point_predictions(
    response_transforms,
    observation_transforms
  )
  rmse <- .short_rmse(point_predictions)
  r200_point_predictions <- .short_point_predictions(
    r200_response_transforms,
    observation_transforms
  )
  r200_rmse <- .short_rmse(r200_point_predictions)
  response_transforms <- rbind(response_transforms, r200_response_transforms)
  point_predictions <- rbind(point_predictions, r200_point_predictions)
  rmse <- rbind(rmse, r200_rmse)
  published_curve_reference <- observations
  published_curve_reference$published_curve_density_scale_kg_dm_ha <-
    records$short$fitted_density_scale_kg_dm_ha
  published_curve_reference$published_curve_predicted_intake_g_dm_animal_day <-
    1000 * records$short$fitted_asymptote_kg_dm_day *
      (1 - exp(-published_curve_reference$vegetation_kg_dm_ha /
        records$short$fitted_density_scale_kg_dm_ha))
  published_curve_rmse <- .short_published_curve_rmse(published_curve_reference)
  aliasing <- .short_aliasing(records, initial_stocks)
  checks <- .short_analytical_checks(records, design, response_loci, aliasing)
  primary_response <- response_loci[
    response_loci$scenario_id == .short_scenario_id(1, 0, 0),
    , drop = FALSE
  ]
  half_hour <- .short_half_hour_check(records, design, primary_response)
  checks <- rbind(
    checks,
    .short_check(
      "half_hour_stock_refinement",
      max(half_hour$max_abs_stock_difference_kg_dm_ha),
      10,
      all(half_hour$max_abs_stock_difference_kg_dm_ha <= 10),
      "Primary B2/B4 differences under half-hour refinement stay within the x allowance."
    ),
    .short_check(
      "half_hour_response_refinement",
      max(half_hour$max_abs_response_difference_g_dm_animal_day),
      20,
      all(half_hour$max_abs_response_difference_g_dm_animal_day <= 20),
      "Primary smoothed stock-loss differences stay within the y allowance."
    ),
    .short_check(
      "half_hour_total_intake_recorded",
      max(half_hour$abs_total_intake_difference_g_dm_animal),
      0,
      all(is.finite(half_hour$abs_total_intake_difference_g_dm_animal)),
      "Half-hour total-intake differences are reported separately from x/y allowances."
    ),
    .short_check(
      "hourly_balance_residuals",
      max(c(
        response_loci$max_forage_balance_residual_kg_dm_ha,
        response_loci$max_coupling_balance_residual_kg_dm_ha
      )),
      1e-10,
      max(c(
        response_loci$max_forage_balance_residual_kg_dm_ha,
        response_loci$max_coupling_balance_residual_kg_dm_ha
      )) < 1e-10,
      "Hourly stock and herbivore coupling ledgers close to machine precision."
    ),
    .short_check(
      "bounded_prescribed_loss_recorded",
      sum(response_loci$total_unmet_loss_kg_dm_ha),
      0,
      any(response_loci$total_unmet_loss_kg_dm_ha > 0),
      "Negative net flux is stock-bounded and any unmet prescribed loss remains visible."
    )
  )
  list(
    records = records,
    scenario_design = design,
    initial_stocks_kg_dm_ha = initial_stocks,
    response_loci = response_loci,
    r200_control = r200_control,
    response_transforms = response_transforms,
    r200_response_transforms = r200_response_transforms,
    observations = observations,
    observation_transforms = observation_transforms,
    point_predictions = point_predictions,
    r200_point_predictions = r200_point_predictions,
    rmse = rmse,
    r200_rmse = r200_rmse,
    published_curve_reference = published_curve_reference,
    published_curve_rmse = published_curve_rmse,
    aliasing = aliasing,
    half_hour = half_hour,
    checks = checks,
    uncertainty = data.frame(
      quantity = c(
        "x_reading_allowance", "y_reading_allowance",
        "half_hour_stock_refinement", "half_hour_response_refinement",
        "half_hour_total_intake_difference"
      ),
      allowance_or_threshold = c(10, 20, 10, 20, NA_real_),
      units = c(
        "kg DM/ha", "g DM/animal/day", "kg DM/ha", "g DM/animal/day",
        "g DM/animal"
      ),
      interpretation = c(
        "digitization allowance only",
        "digitization allowance only",
        "numerical sensitivity threshold, not biological uncertainty",
        "numerical sensitivity threshold, not biological uncertainty",
        "reported separately; no scientific acceptance threshold"
      ),
      stringsAsFactors = FALSE
    )
  )
}

if (sys.nframe() == 0L) {
  result <- run_short_kangaroo_benchmark()
  print(data.frame(
    scenarios = nrow(result$scenario_design),
    response_rows = nrow(result$response_loci),
    r200_control_rows = nrow(result$r200_control),
    observation_points = nrow(result$point_predictions),
    checks_passed = sum(result$checks$pass),
    checks_total = nrow(result$checks),
    max_half_hour_stock_difference_kg_dm_ha = max(
      result$half_hour$max_abs_stock_difference_kg_dm_ha
    ),
    max_half_hour_response_difference_g_dm_animal_day = max(
      result$half_hour$max_abs_response_difference_g_dm_animal_day
    ),
    max_half_hour_total_intake_difference_g_dm_animal = max(
      result$half_hour$abs_total_intake_difference_g_dm_animal
    ),
    stringsAsFactors = FALSE
  ), row.names = FALSE)
}
