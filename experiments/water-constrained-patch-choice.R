source("experiments/water-constrained-fixtures.R")

interaction_days <- 305L
scenarios <- data.frame(
  scenario = c(
    "water_disabled_anchor",
    "baseline_water",
    "wetter_forage",
    "drier_forage",
    "greater_ordinary_loss",
    "higher_water_route_cost"
  ),
  scenario_role = c(
    "anchor", "comparison", "comparison", "stress", "stress", "comparison"
  ),
  water_layer_active = c(FALSE, rep(TRUE, 5L)),
  food_water_yield_kg_water_kg_dm = c(0, 3.28, 4.28, 1.28, 3.28, 3.28),
  daily_ordinary_water_loss_kg = c(0, 1.56, 1.56, 1.56, 2.00, 1.56),
  water_movement_expenditure_per_leg_kj = c(900, 900, 900, 900, 900, 1200),
  stringsAsFactors = FALSE
)

runs <- lapply(seq_len(nrow(scenarios)), function(index) {
  run_water_constrained_closed_loop(
    scenarios[index, , drop = FALSE],
    interaction_days,
    water_visit_policy = "daily_opening"
  )
})
names(runs) <- scenarios$scenario
summary_table <- do.call(
  rbind,
  lapply(runs, summarize_water_constrained_run)
)
row.names(summary_table) <- NULL

anchor <- runs$water_disabled_anchor
baseline <- summary_table[summary_table$scenario == "baseline_water", ]
wetter <- summary_table[summary_table$scenario == "wetter_forage", ]
drier <- summary_table[summary_table$scenario == "drier_forage", ]
greater_loss <- summary_table[
  summary_table$scenario == "greater_ordinary_loss",
]
higher_route <- summary_table[
  summary_table$scenario == "higher_water_route_cost",
]
viable <- summary_table[summary_table$scenario_role != "stress", ]
stress <- summary_table[summary_table$scenario_role == "stress", ]
anchor_move_days <- anchor$simulation_day[anchor$food_patch_action == "move"]

assert_that(
  identical(
    anchor_move_days,
    c(1L, 59L, 98L, 141L, 170L, 207L, 234L, 270L, 297L)
  ) &&
    round(min(anchor$closing_body_energy_reserve_kj)) == 36221 &&
    round(tail(anchor$closing_body_energy_reserve_kj, 1L)) == 39962 &&
    all(!anchor$water_visit) &&
    near(
      anchor$closing_body_water_kg,
      rep(water_constrained_normal_body_water_kg, interaction_days)
    ),
  "the disabled water layer reproduces the accepted patch-choice anchor"
)
assert_that(
  all(viable$completed_days == interaction_days) &&
    all(viable$all_accounts_close) &&
    all(viable$food_patch_switches >= 4L) &&
    all(viable$shortest_food_return_interval_days >= 7L) &&
    all(viable$minimum_body_energy_reserve_kj > 0) &&
    all(
      viable$minimum_body_water_kg >
        water_constrained_critical_body_water_kg
    ),
  "the anchor and viable integrated comparisons complete and use both patches"
)
assert_that(
  baseline$water_visits > 0 &&
    baseline$shortest_water_visit_interval_days >= 2L &&
    baseline$minimum_body_water_kg >
      water_constrained_critical_body_water_kg &&
    wetter$water_visits_per_completed_day <
      baseline$water_visits_per_completed_day &&
    drier$water_visits_per_completed_day >
      baseline$water_visits_per_completed_day &&
    greater_loss$water_visits_per_completed_day >
      baseline$water_visits_per_completed_day,
  "hydration-driven visits remain bounded and respond monotonically"
)
assert_that(
  all(stress$completed_days < interaction_days) &&
    all(stress$all_accounts_close) &&
    all(
      stress$minimum_body_water_kg >
        water_constrained_critical_body_water_kg
    ) &&
    all(stress$closing_body_energy_reserve_kj < 2000),
  "dry forage and greater loss expose an energetic rather than dehydration boundary"
)
assert_that(
  higher_route$movement_expenditure_kj > baseline$movement_expenditure_kj &&
    higher_route$minimum_body_energy_reserve_kj <
      baseline$minimum_body_energy_reserve_kj,
  "a costlier known water route has the expected energetic consequence"
)
assert_that(
  all(summary_table$incremental_evaporative_water_loss_kg == 0),
  "zero prescribed evaporative forcing is an exact Goal 055 reduction"
)

cat("Water-constrained patch-choice diagnostic passed.\n")
print(transform(
  summary_table,
  food_derived_water_kg = round(food_derived_water_kg),
  drinking_water_kg = round(drinking_water_kg),
  ordinary_water_loss_kg = round(ordinary_water_loss_kg),
  incremental_evaporative_water_loss_kg =
    round(incremental_evaporative_water_loss_kg, 2),
  movement_expenditure_kj = round(movement_expenditure_kj),
  minimum_body_water_kg = round(minimum_body_water_kg, 2),
  closing_body_water_kg = round(closing_body_water_kg, 2),
  minimum_body_energy_reserve_kj = round(minimum_body_energy_reserve_kj),
  closing_body_energy_reserve_kj = round(closing_body_energy_reserve_kj)
), row.names = FALSE)
