source("experiments/temperature-hydration-fixtures.R")

# Route structure, known costs, zero-cost time, and causal information probes.
local({
  for (kind in c("isolated", "coupled")) {
    baseline <- new_hydration_system(kind)
    for (multiplier in c(0, 0.5, 1, 1.5, 2)) {
      system <- new_hydration_system(kind, multiplier)
      routes <- system$landscape$routes
      water <- routes$origin_patch_id == "water_source" |
        routes$destination_patch_id == "water_source"
      expected <- baseline$landscape$routes
      expected$incremental_movement_expenditure_kj[water] <- 900 * multiplier
      stopifnot(identical(routes, expected),
        identical(system$landscape$patches, baseline$landscape$patches),
        identical(system$water_properties, baseline$water_properties),
        all(routes$travel_duration_h == 1))
      for (origin in setdiff(system$landscape$patches$patch_id, "water_source"))
        stopifnot(hydration_water_round_trip_cost_kj(system, origin) ==
          1800 * multiplier)
    }
  }
  context <- new_hydration_context("isolated")
  context$state$water$body_water_kg <- 26
  context$physiological_draw_history_kg <- rep(0.03, 48)
  opportunity <- rep(as.numeric(water_constrained_fixture$feeding_open), 2)
  context$food_opportunity_history_h <- opportunity
  context$food_energy_history_kj <- 200 * opportunity
  zero <- new_hydration_system("isolated", 0)
  run <- run_temperature_hydration(zero, matrix(30, 1, 24), "cost_aware", context)
  stopifnot(sum(run$hourly$water_trip_active) == 3,
    sum(run$hourly$water_trip_active & run$hourly$spatial_action == "move") == 2,
    all(run$hourly$incremental_movement_expenditure_kj == 0),
    all(run$hourly$realized_dry_matter_intake_kg_dm[
      run$hourly$water_trip_active] == 0),
    run$hourly$water_departure_reason[[9]] == "reactive")
  context$state$water$body_water_kg <- 26.3
  for (multiplier in c(0, 2)) {
    system <- new_hydration_system("isolated", multiplier)
    a <- matrix(30, 1, 24)
    b <- a
    b[1, 11:24] <- 36
    first <- run_temperature_hydration(system, a, "cost_aware", context)
    second <- run_temperature_hydration(system, b, "cost_aware", context)
    stopifnot(identical(first$hourly[1:10, ], second$hourly[1:10, ]),
      identical(first$decisions, second$decisions))
    decision <- first$decisions
    valid <- is.finite(decision$cost_now_kj_kg)
    stopifnot(any(valid), max(abs(decision$cost_now_kj_kg[valid] *
      decision$refill_now_kg[valid] - 1800 * multiplier)) < 1e-9)
  }
})

water_route_preconditions <- setNames(lapply(c("isolated", "coupled"), function(kind) {
  run <- run_temperature_hydration(new_hydration_system(kind), matrix(30, 60, 24))
  check_hydration_accounts(run)
  stopifnot(is.null(run$terminal))
  run
}), c("isolated", "coupled"))
water_route_design <- expand.grid(system = c("isolated", "coupled"),
  history = c("null", "midday", "evening", "phase_shift"),
  water_route_cost_multiplier = c(0, 0.5, 1, 1.5, 2),
  policy = c("reactive", "anticipatory", "cost_aware"), stringsAsFactors = FALSE)
water_route_key <- function(system, history, cost, policy)
  paste(system, history, cost, policy, sep = "/")

water_route_runs <- parallel::mclapply(seq_len(nrow(water_route_design)), function(i) {
  design <- water_route_design[i, ]
  precondition <- water_route_preconditions[[design$system]]
  context <- if (design$policy == "cost_aware") seed_cost_aware_context(precondition)
    else precondition$final_context
  system <- new_hydration_system(design$system, design$water_route_cost_multiplier)
  run <- run_temperature_hydration(system, hydration_temperature_history(design$history),
    design$policy, context)
  check_hydration_accounts(run)
  x <- run$hourly
  moving_water <- x$water_trip_active & x$spatial_action == "move"
  stopifnot(all(x$incremental_movement_expenditure_kj[moving_water] ==
    900 * design$water_route_cost_multiplier),
    all(x$incremental_movement_expenditure_kj[x$food_patch_move] == 900))
  if (design$policy == "cost_aware") {
    d <- run$decisions
    valid <- is.finite(d$cost_now_kj_kg)
    stopifnot(all(abs(d$cost_now_kj_kg[valid] * d$refill_now_kg[valid] -
      1800 * design$water_route_cost_multiplier) < 1e-9))
  }
  message(water_route_key(design$system, design$history,
    design$water_route_cost_multiplier, design$policy), ": ", nrow(x), " h")
  run
}, mc.cores = 3L, mc.set.seed = FALSE)
stopifnot(!any(vapply(water_route_runs, inherits, logical(1), "try-error")))
names(water_route_runs) <- with(water_route_design,
  water_route_key(system, history, water_route_cost_multiplier, policy))

# Two distinct comparison horizons; terminal and endpoint fields use actual runs.
water_route_summaries <- list()
for (kind in c("isolated", "coupled")) for (history in
  c("null", "midday", "evening", "phase_shift")) {
  group <- which(water_route_design$system == kind & water_route_design$history == history)
  global_hours <- min(vapply(water_route_runs[group], function(x) nrow(x$hourly), integer(1)))
  for (cost in c(0, 0.5, 1, 1.5, 2)) {
    index <- group[water_route_design$water_route_cost_multiplier[group] == cost]
    local_hours <- min(vapply(water_route_runs[index], function(x) nrow(x$hourly), integer(1)))
    for (scope in c("within_cost", "across_cost")) for (i in index) {
      run <- water_route_runs[[i]]
      hours <- if (scope == "within_cost") local_hours else global_hours
      summary <- summarize_hydration_run(run, hours)
      endpoint <- function(hour, field) if (nrow(run$hourly) >= hour)
        run$hourly[[field]][[hour]] else NA_real_
      summary$minimum_body_energy_full_run_kj <- min(
        run$initial_context$state$body$body_energy_reserve_kj,
        run$hourly$body_energy_reserve_end_kj)
      summary$treatment_end_body_energy_kj <- endpoint(2016, "body_energy_reserve_end_kj")
      summary$recovery_end_body_energy_kj <- endpoint(3024, "body_energy_reserve_end_kj")
      row <- data.frame(system = kind, history = history,
        water_route_cost_multiplier = cost, horizon_scope = scope, summary)
      water_route_summaries[[length(water_route_summaries) + 1L]] <- row
    }
  }
}
water_route_summaries <- do.call(rbind, water_route_summaries)
rownames(water_route_summaries) <- NULL

# Whole-path energy decomposition, not marginal causal effects of missed feeding.
water_route_contrasts <- list()
for (i in seq_len(nrow(water_route_summaries))) {
  row <- water_route_summaries[i, ]
  peers <- subset(water_route_summaries, system == row$system & history == row$history &
    horizon_scope == row$horizon_scope)
  comparisons <- list(reactive_same_cost = subset(peers,
    policy == "reactive" & water_route_cost_multiplier == row$water_route_cost_multiplier))
  if (row$horizon_scope == "across_cost") comparisons$unit_cost_same_policy <-
    subset(peers, policy == row$policy & water_route_cost_multiplier == 1)
  for (comparison in names(comparisons)) {
    reference <- comparisons[[comparison]]
    stopifnot(nrow(reference) == 1, reference$common_hours == row$common_hours)
    difference <- function(field) row[[field]] - reference[[field]]
    energy <- difference("combined_energy_common_kj")
    intake <- difference("intake_energy_kj")
    water <- difference("water_movement_kj")
    food <- difference("food_movement_kj")
    stopifnot(abs(energy - intake + water + food) < 1e-7)
    water_route_contrasts[[length(water_route_contrasts) + 1L]] <- data.frame(
      row[, c("system", "history", "water_route_cost_multiplier", "policy",
        "horizon_scope", "common_hours")], comparison = comparison,
      combined_advantage_kj = energy, body_advantage_kj = difference("body_energy_common_kj"),
      intake_difference_kj = intake, water_route_difference_kj = water,
      food_route_difference_kj = food)
  }
}
water_route_contrasts <- do.call(rbind, water_route_contrasts)
rownames(water_route_contrasts) <- NULL
print(subset(water_route_summaries, system == "coupled" & horizon_scope == "within_cost",
  select = c(history, water_route_cost_multiplier, policy, completed_hours,
    terminal_day, terminal_hour, minimum_water_full_run_kg)), row.names = FALSE)
cat("Water-route expenditure checks passed for all 120 branches.\n")
