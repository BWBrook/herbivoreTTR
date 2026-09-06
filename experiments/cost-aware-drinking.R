source("experiments/temperature-hydration-fixtures.R")

# Hand-calculable cost and clock boundaries; these are not treatment results.
local({
  opportunities <- rep(as.numeric(water_constrained_fixture$feeding_open), 2L)
  probe <- function(water = 26.3, draw = 0.03, value = 200, multiplier = 1) {
    hydration_cost_aware_decision(water, rep(draw, 48L),
      value * opportunities, opportunities,
      opportunity_value_multiplier = multiplier)
  }
  favourable <- probe()
  stopifnot(favourable$depart, favourable$predicted_crossing_h == 10,
    favourable$predicted_delay_h == 10,
    abs(favourable$refill_now_kg - 1.76) < 1e-12,
    abs(favourable$refill_later_kg - 2.06) < 1e-12,
    favourable$displaced_opportunities_h == 3,
    abs(favourable$cost_now_kj_kg - 1800 / 1.76) < 1e-10,
    abs(favourable$cost_later_kj_kg - 2400 / 2.06) < 1e-10,
    !probe(multiplier = 0)$depart,
    !probe(multiplier = favourable$opportunity_multiplier_boundary)$depart,
    !probe(water = 26)$depart, !probe(draw = 0)$depart,
    !probe(water = 27.9)$depart)
  for (q in c(13L, 14L, 15L, 16L, 17L, 25L)) {
    decision <- probe(water = 26 + (q - 0.25) * 0.05, draw = 0.05)
    delay <- if (q %in% 14:16) 24L else q
    stopifnot(decision$predicted_crossing_h == q,
      decision$predicted_delay_h == delay,
      decision$predicted_departure_hour == (8 + delay) %% 24)
    if (q %in% 14:16) stopifnot(!decision$depart)
  }
  stopifnot(!hydration_cost_aware_decision(26.3, rep(0.03, 23L),
    rep(200, 23L), rep(1, 23L))$depart,
    !hydration_cost_aware_decision(26.3, rep(0.03, 24L),
      rep(0, 24L), rep(0, 24L))$depart)
})

# Fixed paths separate movement expenditure from displaced feeding, including
# appetite compensation. The zero-cost intervention is not a policy treatment.
cost_aware_controls <- local({
  cases <- data.frame(departure_hour = c(NA, 8, 16, 8, 16),
    round_trip_cost_kj = c(0, 0, 0, 1800, 1800))
  rows <- lapply(seq_len(nrow(cases)), function(i) {
    system <- new_hydration_system("isolated")
    system$landscape$routes$incremental_movement_expenditure_kj <-
      cases$round_trip_cost_kj[[i]] / 2
    state <- new_hydration_context("isolated")$state
    hourly <- vector("list", 24L)
    departure <- cases$departure_hour[[i]]
    for (hour in 0:23) {
      source_stay <- !is.na(departure) && hour %in% c(departure, departure + 1)
      step <- hydration_step_hour(state, system,
        if (source_stay) "water_source" else "forage_patch", hour, 0)
      state <- step$context
      hourly[[hour + 1L]] <- step$hourly
    }
    x <- do.call(rbind, hourly)
    combined_change <- tail(x$body_energy_reserve_end_kj +
      x$gut_available_energy_end_kj, 1L) -
      x$body_energy_reserve_start_kj[[1L]] -
      x$gut_available_energy_start_kj[[1L]]
    movement <- sum(x$incremental_movement_expenditure_kj)
    intake <- sum(x$realized_ingested_available_energy_kj)
    stopifnot(abs(combined_change - intake + 3200 + movement) < 1e-8)
    data.frame(cases[i, ], intake_energy_kj = intake,
      combined_energy_change_kj = combined_change,
      movement_energy_kj = movement,
      displaced_feeding_hours = 16 - sum(x$food_patch_opportunity_h))
  })
  result <- do.call(rbind, rows)
  stopifnot(identical(result$displaced_feeding_hours, c(0, 0, 3, 0, 3)),
    identical(result$movement_energy_kj, cases$round_trip_cost_kj))
  result
})

cost_aware_preconditions <- setNames(lapply(c("isolated", "coupled"), function(kind) {
  run <- run_temperature_hydration(new_hydration_system(kind), matrix(30, 60L, 24L))
  check_hydration_accounts(run)
  stopifnot(is.null(run$terminal))
  run
}), c("isolated", "coupled"))

# The two forcings differ only after the completed prefix. Neither future
# temperature nor future forage can enter the 08:00 choice.
local({
  context <- seed_cost_aware_context(cost_aware_preconditions$isolated)
  a <- matrix(30, 1L, 24L)
  b <- a
  b[1, 11:24] <- 36
  first <- run_temperature_hydration(new_hydration_system("isolated"), a,
    "cost_aware", context)
  second <- run_temperature_hydration(new_hydration_system("isolated"), b,
    "cost_aware", context)
  stopifnot(identical(first$hourly[1:10, ], second$hourly[1:10, ]),
    identical(first$decisions, second$decisions))
  context$state$water$body_water_kg <- 26
  thirsty <- run_temperature_hydration(new_hydration_system("isolated"), a,
    "cost_aware", context)
  stopifnot(thirsty$hourly$water_departure[[9L]],
    thirsty$hourly$water_departure_reason[[9L]] == "reactive")
})

cost_aware_runs <- list()
run_cost_aware_branch <- function(kind, history, policy, slope = 1,
  memory = 24L, opportunity = 1) {
  key <- paste(kind, history, slope, memory, opportunity, policy, sep = "/")
  if (is.null(cost_aware_runs[[key]])) {
    precondition <- cost_aware_preconditions[[kind]]
    context <- if (policy == "cost_aware") seed_cost_aware_context(precondition)
      else precondition$final_context
    run <- run_temperature_hydration(new_hydration_system(kind),
      hydration_temperature_history(history), policy, context,
      slope_multiplier = slope, memory_hours = memory,
      opportunity_value_multiplier = opportunity)
    check_hydration_accounts(run)
    cost_aware_runs[[key]] <<- run
    message(key, ": ", nrow(run$hourly), " completed hours")
  }
  key
}

cost_aware_design <- rbind(
  expand.grid(system = c("isolated", "coupled"),
    history = c("null", "midday", "evening", "phase_shift"),
    slope = 1, memory = 24L, opportunity = 1, stringsAsFactors = FALSE),
  expand.grid(system = "coupled", history = c("midday", "phase_shift"),
    slope = c(0.5, 1.5), memory = 24L, opportunity = 1, stringsAsFactors = FALSE),
  expand.grid(system = "coupled", history = c("midday", "phase_shift"),
    slope = 1, memory = c(12L, 48L), opportunity = 1, stringsAsFactors = FALSE),
  expand.grid(system = "coupled", history = c("midday", "phase_shift"),
    slope = 1, memory = 24L, opportunity = c(0.5, 1.5), stringsAsFactors = FALSE)
)

cost_aware_summaries <- list()
cost_aware_contrasts <- list()
for (i in seq_len(nrow(cost_aware_design))) {
  design <- cost_aware_design[i, ]
  keys <- vapply(c("reactive", "anticipatory", "cost_aware"), function(policy) {
    run_cost_aware_branch(design$system, design$history, policy, design$slope,
      if (policy == "cost_aware") design$memory else 24L,
      if (policy == "cost_aware") design$opportunity else 1)
  }, character(1L))
  runs <- cost_aware_runs[keys]
  common_hours <- min(vapply(runs, function(x) nrow(x$hourly), integer(1L)))
  summary <- do.call(rbind, lapply(runs, summarize_hydration_run, common_hours))
  cost_aware_summaries[[i]] <- cbind(design[rep(1L, nrow(summary)), ], summary)
  candidate <- summary[summary$policy == "cost_aware", ]
  comparisons <- lapply(c("reactive", "anticipatory"), function(policy) {
    comparator <- summary[summary$policy == policy, ]
    difference <- function(field) candidate[[field]] - comparator[[field]]
    combined <- difference("combined_energy_common_kj")
    intake <- difference("intake_energy_kj")
    water_route <- difference("water_movement_kj")
    food_route <- difference("food_movement_kj")
    stopifnot(abs(combined - intake + water_route + food_route) < 1e-7)
    data.frame(design, comparator = policy, common_hours = common_hours,
      body_advantage_kj = difference("body_energy_common_kj"),
      combined_advantage_kj = combined, intake_difference_kj = intake,
      water_route_difference_kj = water_route, food_route_difference_kj = food_route,
      trip_start_difference = difference("trip_starts"),
      feeding_displacement_difference_h = difference("water_trip_feeding_hours"),
      completed_hours_difference = difference("completed_hours"))
  })
  cost_aware_contrasts[[i]] <- do.call(rbind, comparisons)
}
cost_aware_summaries <- do.call(rbind, cost_aware_summaries)
cost_aware_contrasts <- do.call(rbind, cost_aware_contrasts)
rownames(cost_aware_summaries) <- rownames(cost_aware_contrasts) <- NULL
stopifnot(length(cost_aware_runs) == 44L)

display <- cost_aware_contrasts
energy_fields <- endsWith(names(display), "_kj")
display[energy_fields] <- lapply(display[energy_fields], round)
print(cost_aware_controls, row.names = FALSE)
print(display, row.names = FALSE)
cat("Cost-aware drinking checks passed. Benefit is not an acceptance assertion.\n")
