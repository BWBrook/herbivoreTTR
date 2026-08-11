arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

source("experiments/rebuild-022-implicit-two-patch-forage.R")

require_goal024 <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 024 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

movement_hour <- 16L
additional_movement_expenditure_kj <- 100
mixed_patch_orders <- c(
  "limited_then_adequate",
  "adequate_then_limited"
)
movement_treatments <- data.frame(
  treatment_id = c("cost_free", "time_only", "energy_only", "combined"),
  feeding_time_cost = c(FALSE, TRUE, FALSE, TRUE),
  movement_energy_cost = c(FALSE, FALSE, TRUE, TRUE),
  stringsAsFactors = FALSE
)

goal024_design <- do.call(
  rbind,
  lapply(mixed_patch_orders, function(patch_order) {
    data.frame(
      patch_order = patch_order,
      movement_treatments,
      stringsAsFactors = FALSE
    )
  })
)
goal024_design$scenario_id <- paste(
  goal024_design$patch_order,
  goal024_design$treatment_id,
  sep = "__"
)
row.names(goal024_design) <- NULL

make_movement_scenario <- function(design_row) {
  patch_order <- design_row$patch_order[[1L]]
  feeding_time_cost <- design_row$feeding_time_cost[[1L]]
  movement_energy_cost <- design_row$movement_energy_cost[[1L]]
  exposure <- goal022_exposures[[patch_order]]

  scenario_feeding_open <- feeding_opportunity_open
  scenario_reference_rate <- reference_dry_matter_rates_kg_dm_h
  scenario_ceiling_rate <-
    exposure$ceiling_schedule$forage_acquisition_ceiling_kg_dm_h
  scenario_activity_rate <-
    routine_activity_schedule$
      prescribed_routine_activity_expenditure_kj_h
  scenario_patch_id <- exposure$patch_id

  if (feeding_time_cost) {
    scenario_feeding_open[[movement_hour + 1L]] <- FALSE
    scenario_reference_rate[[movement_hour + 1L]] <- 0
    scenario_ceiling_rate[[movement_hour + 1L]] <- 0
    scenario_patch_id[[movement_hour + 1L]] <- "movement_transition"
  }
  if (movement_energy_cost) {
    scenario_activity_rate[[movement_hour + 1L]] <-
      scenario_activity_rate[[movement_hour + 1L]] +
        additional_movement_expenditure_kj
  }

  list(
    scenario_id = design_row$scenario_id[[1L]],
    patch_order = patch_order,
    treatment_id = design_row$treatment_id[[1L]],
    feeding_time_cost = feeding_time_cost,
    movement_energy_cost = movement_energy_cost,
    patch_id = scenario_patch_id,
    appetite_reference_schedule =
      herbivoreTTR::new_appetite_reference_schedule(
        hour_of_day = hour_of_day,
        feeding_opportunity_open = scenario_feeding_open,
        reference_dry_matter_intake_kg_dm_h = scenario_reference_rate,
        reference_body_energy_reserve_kj =
          reference_hourly$body_energy_reserve_start_kj,
        reference_gut_available_energy_kj =
          reference_hourly$gut_available_energy_start_kj
      ),
    forage_acquisition_ceiling_schedule =
      herbivoreTTR::new_forage_acquisition_ceiling_schedule(
        hour_of_day,
        scenario_ceiling_rate
      ),
    routine_activity_schedule =
      herbivoreTTR::new_routine_activity_expenditure_schedule(
        hour_of_day,
        scenario_activity_rate
      )
  )
}

goal024_scenarios <- lapply(
  seq_len(nrow(goal024_design)),
  function(row_index) {
    make_movement_scenario(
      goal024_design[row_index, , drop = FALSE]
    )
  }
)
names(goal024_scenarios) <- goal024_design$scenario_id

run_movement_scenario <- function(scenario) {
  herbivoreTTR::run_appetite_controlled_energy_days(
    initial_gut_state = reference_opening_gut_state,
    initial_body_state = reference_opening_body_state,
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    food_parameters = food_parameters,
    appetite_parameters = appetite_parameters,
    appetite_reference_schedule = scenario$appetite_reference_schedule,
    forage_acquisition_ceiling_schedule =
      scenario$forage_acquisition_ceiling_schedule,
    routine_activity_schedule = scenario$routine_activity_schedule,
    number_of_days = 1L
  )
}

goal024_results <- lapply(goal024_scenarios, run_movement_scenario)

control_identity <- vapply(
  mixed_patch_orders,
  function(patch_order) {
    scenario_id <- paste(patch_order, "cost_free", sep = "__")
    identical(goal024_results[[scenario_id]], goal022_results[[patch_order]])
  },
  logical(1L)
)
require_goal024(all(control_identity), "exact Goal 022 cost-free controls")

build_goal024_hourly <- function(scenario, result) {
  data.frame(
    scenario_id = scenario$scenario_id,
    patch_order = scenario$patch_order,
    treatment_id = scenario$treatment_id,
    feeding_time_cost = scenario$feeding_time_cost,
    movement_energy_cost = scenario$movement_energy_cost,
    patch_id = scenario$patch_id,
    hour_of_day = result$hourly$hour_of_day,
    feeding_opportunity_open = result$hourly$feeding_opportunity_open,
    forage_acquisition_ceiling_kg_dm_h =
      result$hourly$forage_acquisition_ceiling_kg_dm_h,
    appetite_target_dry_matter_intake_kg_dm_h =
      result$hourly$appetite_target_dry_matter_intake_kg_dm_h,
    realized_dry_matter_intake_kg_dm_h =
      result$hourly$realized_dry_matter_intake_kg_dm_h,
    prescribed_routine_activity_expenditure_kj_h =
      result$hourly$prescribed_routine_activity_expenditure_kj_h,
    forage_acquisition_ceiling_active =
      result$hourly$forage_acquisition_ceiling_active,
    gut_available_energy_end_kj =
      result$hourly$gut_available_energy_end_kj,
    body_energy_reserve_end_kj =
      result$hourly$body_energy_reserve_end_kj,
    combined_energy_deviation_end_kj =
      result$hourly$total_system_energy_end_kj -
        balanced_appetite_control$hourly$total_system_energy_end_kj,
    gut_energy_balance_residual_kj =
      result$hourly$gut_energy_balance_residual_kj,
    body_energy_balance_residual_kj =
      result$hourly$body_energy_balance_residual_kj,
    system_energy_balance_residual_kj =
      result$hourly$system_energy_balance_residual_kj,
    stringsAsFactors = FALSE
  )
}

goal024_hourly <- do.call(
  rbind,
  lapply(names(goal024_results), function(scenario_id) {
    build_goal024_hourly(
      goal024_scenarios[[scenario_id]],
      goal024_results[[scenario_id]]
    )
  })
)
row.names(goal024_hourly) <- NULL

build_goal024_daily <- function(scenario, result) {
  daily <- result$daily
  data.frame(
    scenario_id = scenario$scenario_id,
    patch_order = scenario$patch_order,
    treatment_id = scenario$treatment_id,
    feeding_time_cost = scenario$feeding_time_cost,
    movement_energy_cost = scenario$movement_energy_cost,
    feeding_opportunity_hours = sum(
      scenario$appetite_reference_schedule$feeding_opportunity_open
    ),
    second_patch_feeding_hours = sum(
      scenario$patch_id == goal022_exposures[[scenario$patch_order]]$second_patch
    ),
    appetite_target_dry_matter_intake_kg_dm =
      daily$appetite_target_dry_matter_intake_kg_dm,
    realized_dry_matter_intake_kg_dm =
      daily$realized_dry_matter_intake_kg_dm,
    forage_acquisition_ceiling_active_hours =
      daily$forage_acquisition_ceiling_active_hours,
    lower_intake_bound_hours = daily$lower_intake_bound_hours,
    upper_intake_bound_hours = daily$upper_intake_bound_hours,
    realized_ingested_available_energy_kj =
      daily$total_realized_ingested_available_energy_kj,
    routine_activity_expenditure_kj =
      daily$total_prescribed_routine_activity_expenditure_kj,
    gut_available_energy_final_kj = daily$gut_available_energy_final_kj,
    body_energy_reserve_final_kj = daily$body_energy_reserve_final_kj,
    gut_energy_deviation_final_kj =
      daily$gut_energy_deviation_from_reference_final_kj,
    body_energy_deviation_final_kj =
      daily$body_energy_deviation_from_reference_final_kj,
    combined_energy_deviation_final_kj =
      daily$combined_energy_deviation_from_reference_final_kj,
    total_system_energy_change_kj =
      daily$observed_total_system_energy_change_kj,
    gut_energy_balance_residual_kj = daily$gut_energy_balance_residual_kj,
    body_energy_balance_residual_kj = daily$body_energy_balance_residual_kj,
    system_energy_balance_residual_kj =
      daily$system_energy_balance_residual_kj,
    stringsAsFactors = FALSE
  )
}

goal024_daily <- do.call(
  rbind,
  lapply(names(goal024_results), function(scenario_id) {
    build_goal024_daily(
      goal024_scenarios[[scenario_id]],
      goal024_results[[scenario_id]]
    )
  })
)
row.names(goal024_daily) <- NULL

scenario_value <- function(patch_order, treatment_id, field_name) {
  goal024_daily[[field_name]][
    goal024_daily$patch_order == patch_order &
      goal024_daily$treatment_id == treatment_id
  ]
}

effect_outcomes <- c(
  "realized_dry_matter_intake_kg_dm",
  "realized_ingested_available_energy_kj",
  "gut_available_energy_final_kj",
  "body_energy_reserve_final_kj",
  "combined_energy_deviation_final_kj"
)

build_factor_effect <- function(patch_order, effect_type) {
  contrast <- switch(
    effect_type,
    time = c(time_only = 1, cost_free = -1),
    energy = c(energy_only = 1, cost_free = -1),
    combined = c(combined = 1, cost_free = -1),
    interaction = c(
      combined = 1,
      time_only = -1,
      energy_only = -1,
      cost_free = 1
    )
  )
  values <- vapply(
    effect_outcomes,
    function(field_name) {
      sum(vapply(
        names(contrast),
        function(treatment_id) {
          contrast[[treatment_id]] *
            scenario_value(patch_order, treatment_id, field_name)
        },
        numeric(1L)
      ))
    },
    numeric(1L)
  )
  data.frame(
    patch_order = patch_order,
    effect_type = effect_type,
    as.list(values),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

goal024_factor_effects <- do.call(
  rbind,
  lapply(mixed_patch_orders, function(patch_order) {
    do.call(
      rbind,
      lapply(
        c("time", "energy", "combined", "interaction"),
        function(effect_type) {
          build_factor_effect(patch_order, effect_type)
        }
      )
    )
  })
)
row.names(goal024_factor_effects) <- NULL

goal024_patch_order_contrasts <- do.call(
  rbind,
  lapply(movement_treatments$treatment_id, function(treatment_id) {
    values <- vapply(
      effect_outcomes,
      function(field_name) {
        scenario_value(
          "limited_then_adequate",
          treatment_id,
          field_name
        ) -
          scenario_value(
            "adequate_then_limited",
            treatment_id,
            field_name
          )
      },
      numeric(1L)
    )
    data.frame(
      treatment_id = treatment_id,
      as.list(values),
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
  })
)
row.names(goal024_patch_order_contrasts) <- NULL

movement_rows <- goal024_hourly$hour_of_day == movement_hour
require_goal024(
  all(
    goal024_daily$feeding_opportunity_hours[
      !goal024_daily$feeding_time_cost
    ] == 16L
  ) &&
    all(
      goal024_daily$feeding_opportunity_hours[
        goal024_daily$feeding_time_cost
      ] == 15L
    ) &&
    all(
      goal024_daily$second_patch_feeding_hours[
        !goal024_daily$feeding_time_cost
      ] == 8L
    ) &&
    all(
      goal024_daily$second_patch_feeding_hours[
        goal024_daily$feeding_time_cost
      ] == 7L
    ),
  "declared feeding-time loss"
)
require_goal024(
  all(
    goal024_hourly$feeding_opportunity_open[
      movement_rows & goal024_hourly$feeding_time_cost
    ] == FALSE
  ) &&
    all(
      goal024_hourly$forage_acquisition_ceiling_kg_dm_h[
        movement_rows & goal024_hourly$feeding_time_cost
      ] == 0
    ) &&
    all(
      goal024_hourly$appetite_target_dry_matter_intake_kg_dm_h[
        movement_rows & goal024_hourly$feeding_time_cost
      ] == 0
    ) &&
    all(
      goal024_hourly$realized_dry_matter_intake_kg_dm_h[
        movement_rows & goal024_hourly$feeding_time_cost
      ] == 0
    ),
  "hour-16 feeding suspension"
)
require_goal024(
  all(
    goal024_daily$routine_activity_expenditure_kj[
      !goal024_daily$movement_energy_cost
    ] == 800
  ) &&
    all(
      goal024_daily$routine_activity_expenditure_kj[
        goal024_daily$movement_energy_cost
      ] == 900
    ) &&
    all(
      goal024_hourly$prescribed_routine_activity_expenditure_kj_h[
        movement_rows & !goal024_hourly$movement_energy_cost
      ] == 50
    ) &&
    all(
      goal024_hourly$prescribed_routine_activity_expenditure_kj_h[
        movement_rows & goal024_hourly$movement_energy_cost
      ] == 150
    ),
  "declared additional movement expenditure"
)
require_goal024(
  all(goal024_daily$lower_intake_bound_hours == 0L) &&
    all(goal024_daily$upper_intake_bound_hours == 0L) &&
    all(goal024_daily$body_energy_reserve_final_kj > 0) &&
    near(
      goal024_daily$gut_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      goal024_daily$body_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    near(
      goal024_daily$system_energy_balance_residual_kj,
      0,
      scale = reference_opening_body_energy_kj
    ) &&
    all(is.finite(unlist(goal024_factor_effects[effect_outcomes]))) &&
    all(is.finite(unlist(goal024_patch_order_contrasts[effect_outcomes]))),
  "bounds, positive reserve, accounting, and finite contrasts"
)

goal024_diagnostics <- list(
  design = goal024_design,
  scenarios = goal024_scenarios,
  results = goal024_results,
  hourly = goal024_hourly,
  daily = goal024_daily,
  factor_effects = goal024_factor_effects,
  patch_order_contrasts = goal024_patch_order_contrasts
)

cat("Goal 024 diagnostics passed.\n")
for (row_index in seq_len(nrow(goal024_daily))) {
  row <- goal024_daily[row_index, ]
  cat(sprintf(
    paste0(
      "  %s %s: realized %.3f kg DM; activity %.0f kJ; ",
      "combined %+.0f kJ.\n"
    ),
    row$patch_order,
    row$treatment_id,
    row$realized_dry_matter_intake_kg_dm,
    row$routine_activity_expenditure_kj,
    row$combined_energy_deviation_final_kj
  ))
}
cat("  Combined-cost effects relative to cost-free:\n")
for (patch_order in mixed_patch_orders) {
  row <- goal024_factor_effects[
    goal024_factor_effects$patch_order == patch_order &
      goal024_factor_effects$effect_type == "combined",
    ,
    drop = FALSE
  ]
  cat(sprintf(
    "    %s: intake %+.3f kg DM; combined %+.0f kJ.\n",
    patch_order,
    row$realized_dry_matter_intake_kg_dm,
    row$combined_energy_deviation_final_kj
  ))
}
cat("  Patch-order contrasts, limited/adequate minus adequate/limited:\n")
for (row_index in seq_len(nrow(goal024_patch_order_contrasts))) {
  row <- goal024_patch_order_contrasts[row_index, ]
  cat(sprintf(
    "    %s: intake %+.3f kg DM; combined %+.0f kJ.\n",
    row$treatment_id,
    row$realized_dry_matter_intake_kg_dm,
    row$combined_energy_deviation_final_kj
  ))
}
