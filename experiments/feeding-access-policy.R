# Experiment-level experienced feeding access; original 062 and repaired 064.

feeding_memory_fields <- c(
  "last_return_kj_h",
  "best_return_kj_h",
  "last_observed_day",
  "inadequacy_kj"
)

feeding_memory_tolerance <- function(values) {
  100 * .Machine$double.eps * max(1, abs(values))
}

validate_feeding_memory <- function(memory) {
  stopifnot(is.list(memory), all(feeding_memory_fields %in% names(memory)))
  n <- length(memory$last_return_kj_h)
  stopifnot(
    n >= 1L,
    length(memory$best_return_kj_h) == n,
    length(memory$last_observed_day) == n,
    length(memory$inadequacy_kj) == 1L,
    is.numeric(memory$last_return_kj_h),
    is.numeric(memory$best_return_kj_h),
    is.numeric(memory$last_observed_day),
    is.numeric(memory$inadequacy_kj),
    all(is.finite(memory$last_return_kj_h)),
    all(is.finite(memory$best_return_kj_h)),
    all(is.finite(memory$last_observed_day)),
    is.finite(memory$inadequacy_kj),
    all(memory$last_return_kj_h >= 0),
    all(memory$best_return_kj_h >= memory$last_return_kj_h),
    all(memory$last_observed_day >= 0),
    memory$inadequacy_kj >= 0
  )
  invisible(n)
}

new_feeding_memory <- function(n) {
  stopifnot(
    length(n) == 1L,
    is.numeric(n),
    is.finite(n),
    n >= 1,
    n == as.integer(n)
  )
  n <- as.integer(n)
  list(
    last_return_kj_h = rep(200, n),
    best_return_kj_h = rep(250, n),
    last_observed_day = rep(0, n),
    inadequacy_kj = 0
  )
}

# Explicit historical control for the frozen 062/063 studies.
feeding_two_day_expected_return <- function(memory, day, ...) {
  validate_feeding_memory(memory)
  stopifnot(
    length(day) == 1L,
    is.numeric(day),
    is.finite(day),
    day >= 1,
    day == as.integer(day)
  )

  recovery_fraction <- pmin(
    1,
    pmax(0, day - 1 - memory$last_observed_day) / 2
  )
  memory$last_return_kj_h +
    (memory$best_return_kj_h - memory$last_return_kj_h) *
      recovery_fraction
}

feeding_expected_return <- function(memory, day, search_area_m2_h,
  growth_rate_h = .002, senescence_rate_h = .001,
  production_saturation_biomass_kg_dm_ha = 2000,
  residual_kg_dm_ha = 200) {
  validate_feeding_memory(memory)
  stopifnot(length(day) == 1L, is.numeric(day), is.finite(day),
    day >= 1, day == as.integer(day))
  parameters <- list(search_area_m2_h, growth_rate_h, senescence_rate_h,
    production_saturation_biomass_kg_dm_ha, residual_kg_dm_ha)
  stopifnot(all(vapply(parameters, function(x)
    is.numeric(x) && length(x) == 1L && is.finite(x), logical(1))),
    search_area_m2_h > 0, growth_rate_h >= 0, growth_rate_h <= 1,
    senescence_rate_h >= 0, senescence_rate_h <= 1,
    production_saturation_biomass_kg_dm_ha > residual_kg_dm_ha,
    residual_kg_dm_ha >= 0)
  age_h <- 24 * pmax(0, day - 1 - memory$last_observed_day)
  # A return-equivalent belief, not inferred or simulator-supplied biomass.
  proxy <- residual_kg_dm_ha + memory$last_return_kj_h / search_area_m2_h
  stopifnot(all(is.finite(proxy)),
    all(proxy <= production_saturation_biomass_kg_dm_ha))
  a <- growth_rate_h - senescence_rate_h
  b <- growth_rate_h / production_saturation_biomass_kg_dm_ha
  if (a > 0) {
    # Scaled exact logistic solution avoids overflow for very old memories.
    decay <- exp(-a * age_h)
    recovered <- proxy / (decay + b * proxy * (-expm1(-a * age_h) / a))
  } else if (a < 0) {
    recovered <- proxy * exp(a * age_h) /
      (1 + b * proxy * expm1(a * age_h) / a)
  } else {
    recovered <- proxy / (1 + b * proxy * age_h)
  }
  recovered[proxy == 0] <- 0
  expected <- pmin(memory$best_return_kj_h,
    search_area_m2_h * pmax(recovered - residual_kg_dm_ha, 0))
  # Preserve the observed value exactly at the opening-day boundary.
  expected[age_h == 0] <- memory$last_return_kj_h[age_h == 0]
  stopifnot(all(is.finite(expected)), all(expected >= 0))
  expected
}

choose_feeding_station <- function(
  current_index,
  expected_return_kj_h,
  travel_duration_h,
  travel_expenditure_kj,
  inadequacy_kj = 0
) {
  stopifnot(
    length(current_index) == 1L,
    is.numeric(current_index),
    is.finite(current_index),
    current_index >= 1,
    current_index == as.integer(current_index),
    is.numeric(expected_return_kj_h),
    length(expected_return_kj_h) >= 1L,
    all(is.finite(expected_return_kj_h)),
    all(expected_return_kj_h >= 0),
    is.numeric(travel_duration_h),
    length(travel_duration_h) == length(expected_return_kj_h),
    all(is.finite(travel_duration_h)),
    all(travel_duration_h >= 0),
    is.numeric(travel_expenditure_kj),
    length(travel_expenditure_kj) == length(expected_return_kj_h),
    all(is.finite(travel_expenditure_kj)),
    all(travel_expenditure_kj >= 0),
    length(inadequacy_kj) == 1L,
    is.numeric(inadequacy_kj),
    is.finite(inadequacy_kj),
    inadequacy_kj >= 0
  )
  current_index <- as.integer(current_index)
  stopifnot(current_index <= length(expected_return_kj_h))

  current_return_kj_h <- expected_return_kj_h[[current_index]]
  return_tolerance <- feeding_memory_tolerance(c(
    current_return_kj_h,
    expected_return_kj_h
  ))
  adequate_tolerance <- feeding_memory_tolerance(c(
    current_return_kj_h,
    200
  ))
  if (current_return_kj_h >= 200 - adequate_tolerance) {
    return(current_index)
  }

  candidate_index <- which(
    expected_return_kj_h > current_return_kj_h + return_tolerance
  )
  if (!length(candidate_index)) {
    return(current_index)
  }

  score_kj <- (
    pmax(0, 32 - travel_duration_h[candidate_index]) *
      expected_return_kj_h[candidate_index]
  ) - 32 * current_return_kj_h -
    travel_expenditure_kj[candidate_index] + inadequacy_kj
  profitable <- which(score_kj > 0)
  if (!length(profitable)) {
    return(current_index)
  }

  # which.max returns the first maximum; candidate_index is in station order.
  as.integer(candidate_index[[profitable[[which.max(score_kj[profitable])]]]])
}

update_feeding_memory <- function(
  memory,
  intake_kg_dm,
  feeding_h,
  day,
  current_index,
  moved = FALSE
) {
  n <- validate_feeding_memory(memory)
  stopifnot(
    is.numeric(intake_kg_dm),
    length(intake_kg_dm) == n,
    all(is.finite(intake_kg_dm)),
    all(intake_kg_dm >= 0),
    is.numeric(feeding_h),
    length(feeding_h) == n,
    all(is.finite(feeding_h)),
    all(feeding_h >= 0),
    length(day) == 1L,
    is.numeric(day),
    is.finite(day),
    day >= 1,
    day == as.integer(day),
    length(current_index) == 1L,
    is.numeric(current_index),
    is.finite(current_index),
    current_index >= 1,
    current_index == as.integer(current_index),
    length(moved) == 1L,
    is.logical(moved),
    !is.na(moved)
  )
  day <- as.integer(day)
  current_index <- as.integer(current_index)
  stopifnot(current_index <= n)

  observed <- feeding_h > 0
  if (!any(observed)) {
    return(memory)
  }

  observed_return_kj_h <- 10000 * intake_kg_dm[observed] /
    feeding_h[observed]
  stopifnot(all(is.finite(observed_return_kj_h)))
  memory$last_return_kj_h[observed] <- observed_return_kj_h
  memory$best_return_kj_h[observed] <- pmax(
    memory$best_return_kj_h[observed],
    observed_return_kj_h
  )
  memory$last_observed_day[observed] <- day

  if (isTRUE(moved)) {
    memory$inadequacy_kj <- 0
  }
  if (observed[[current_index]]) {
    current_return_kj_h <- memory$last_return_kj_h[[current_index]]
    current_tolerance <- feeding_memory_tolerance(c(
      current_return_kj_h,
      200
    ))
    if (current_return_kj_h >= 200 - current_tolerance) {
      memory$inadequacy_kj <- 0
    } else {
      memory$inadequacy_kj <- memory$inadequacy_kj +
        max(200 - current_return_kj_h, 0) * feeding_h[[current_index]]
    }
  }
  memory
}
