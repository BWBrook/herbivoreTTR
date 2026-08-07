arguments <- commandArgs(trailingOnly = TRUE)
if (identical(environment(), globalenv()) && length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

require_that <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Goal 012 assertion failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

near <- function(observed, expected, scale = NULL) {
  observed <- as.double(observed)
  expected <- as.double(expected)
  if (length(expected) == 1L && length(observed) > 1L) {
    expected <- rep(expected, length(observed))
  }
  if (is.null(scale)) {
    scale <- pmax(1, abs(observed), abs(expected))
  } else {
    scale <- pmax(1, as.double(scale))
  }
  length(observed) == length(expected) &&
    length(scale) %in% c(1L, length(observed)) &&
    all(is.finite(observed)) &&
    all(is.finite(expected)) &&
    all(is.finite(scale)) &&
    all(
      abs(observed - expected) <=
        100 * .Machine$double.eps * scale
    )
}

boundary_values <- function(sequence, stock) {
  start_field <- paste0(stock, "_start_kj")
  end_field <- paste0(stock, "_end_kj")
  c(
    sequence$days[[1L]]$hourly[[start_field]][[1L]],
    unlist(
      lapply(sequence$days, function(day) day$hourly[[end_field]]),
      use.names = FALSE
    )
  )
}

assemble_reference_schema <- function(days) {
  hourly <- do.call(rbind, lapply(seq_along(days), function(index) {
    data.frame(
      measurement_day = rep(as.integer(index), 24L),
      days[[index]]$hourly,
      row.names = NULL
    )
  }))
  daily <- do.call(rbind, lapply(seq_along(days), function(index) {
    data.frame(
      measurement_day = as.integer(index),
      days[[index]]$daily,
      row.names = NULL
    )
  }))
  row.names(hourly) <- seq_len(nrow(hourly))
  row.names(daily) <- seq_len(nrow(daily))
  list(hourly = hourly, daily = daily)
}

hour_of_day <- 0:23
feeding_hours <- c(0:7, 16:23)
feeding_window_open <- hour_of_day %in% feeding_hours
balanced_dry_matter_rates_kg_dm_h <-
  as.double(feeding_window_open) * 0.020
shortfall_dry_matter_rates_kg_dm_h <-
  as.double(feeding_window_open) * 0.015
repayment_dry_matter_rates_kg_dm_h <-
  as.double(feeding_window_open) * 0.025
activity_rates_kj_h <- as.double(feeding_window_open) * 50

food_parameters <- herbivoreTTR::new_food_energy_parameters(10000)
gut_parameters <- herbivoreTTR::new_gut_energy_parameters(0.25)
body_parameters <- herbivoreTTR::new_body_energy_parameters(100)

balanced_dry_matter_schedule <-
  herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day,
    balanced_dry_matter_rates_kg_dm_h
  )
shortfall_dry_matter_schedule <-
  herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day,
    shortfall_dry_matter_rates_kg_dm_h
  )
repayment_dry_matter_schedule <-
  herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day,
    repayment_dry_matter_rates_kg_dm_h
  )
balanced_energy_schedule <-
  herbivoreTTR::derive_ingested_available_energy_schedule(
    food_parameters,
    balanced_dry_matter_schedule
  )
shortfall_energy_schedule <-
  herbivoreTTR::derive_ingested_available_energy_schedule(
    food_parameters,
    shortfall_dry_matter_schedule
  )
repayment_energy_schedule <-
  herbivoreTTR::derive_ingested_available_energy_schedule(
    food_parameters,
    repayment_dry_matter_schedule
  )
activity_schedule <-
  herbivoreTTR::new_routine_activity_expenditure_schedule(
    hour_of_day,
    activity_rates_kj_h
  )

require_that(
  identical(
    balanced_dry_matter_schedule$
      prescribed_dry_matter_intake_kg_dm_h,
    c(rep(0.020, 8L), rep(0, 8L), rep(0.020, 8L))
  ) &&
    identical(
      shortfall_dry_matter_schedule$
        prescribed_dry_matter_intake_kg_dm_h,
      c(rep(0.015, 8L), rep(0, 8L), rep(0.015, 8L))
    ) &&
    identical(
      repayment_dry_matter_schedule$
        prescribed_dry_matter_intake_kg_dm_h,
      c(rep(0.025, 8L), rep(0, 8L), rep(0.025, 8L))
    ) &&
    identical(
      balanced_energy_schedule$
        prescribed_ingested_available_energy_kj_h,
      c(rep(200, 8L), rep(0, 8L), rep(200, 8L))
    ) &&
    identical(
      shortfall_energy_schedule$
        prescribed_ingested_available_energy_kj_h,
      c(rep(150, 8L), rep(0, 8L), rep(150, 8L))
    ) &&
    identical(
      repayment_energy_schedule$
        prescribed_ingested_available_energy_kj_h,
      c(rep(250, 8L), rep(0, 8L), rep(250, 8L))
    ) &&
    identical(
      activity_schedule$
        prescribed_routine_activity_expenditure_kj_h,
      c(rep(50, 8L), rep(0, 8L), rep(50, 8L))
    ),
  "exact balanced, shortfall, repayment, and activity schedules"
)
require_that(
  near(sum(balanced_dry_matter_rates_kg_dm_h), 0.32) &&
    near(sum(shortfall_dry_matter_rates_kg_dm_h), 0.24) &&
    near(sum(repayment_dry_matter_rates_kg_dm_h), 0.40) &&
    identical(
      sum(
        balanced_energy_schedule$
          prescribed_ingested_available_energy_kj_h
      ),
      3200
    ) &&
    identical(
      sum(
        shortfall_energy_schedule$
          prescribed_ingested_available_energy_kj_h
      ),
      2400
    ) &&
    identical(
      sum(
        repayment_energy_schedule$
          prescribed_ingested_available_energy_kj_h
      ),
      4000
    ) &&
    identical(sum(activity_rates_kj_h), 800),
  "declared daily prescribed totals"
)

# The reference-cycle runner is used once to establish the accepted balanced
# period-24 gut opening state and the retained Goal 008 control oracle.
balanced_reference <-
  herbivoreTTR::run_gut_body_energy_reference_cycle(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(0),
    measurement_body_state =
      herbivoreTTR::new_body_energy_state(10000),
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    schedule = balanced_energy_schedule,
    routine_activity_schedule = activity_schedule,
    gut_convergence_relative_tolerance =
      100 * .Machine$double.eps,
    max_burn_in_days = 100L
  )

balanced_opening_gut_energy_kj <-
  balanced_reference$hourly$gut_available_energy_start_kj[[1L]]
common_initial_gut_state <-
  herbivoreTTR::new_gut_energy_state(
    balanced_opening_gut_energy_kj
  )
common_initial_body_state <-
  herbivoreTTR::new_body_energy_state(10000)

run_sequence <- function(sequence_id, forcing_phases) {
  current_gut_state <- common_initial_gut_state
  current_body_state <- common_initial_body_state
  days <- vector("list", length(forcing_phases))

  for (sequence_day in seq_along(forcing_phases)) {
    phase <- forcing_phases[[sequence_day]]
    schedule <- switch(
      phase,
      shortfall = shortfall_energy_schedule,
      prescribed_repayment_pulse = repayment_energy_schedule,
      balanced_energy_schedule
    )
    days[[sequence_day]] <-
      herbivoreTTR::run_gut_body_energy_day(
        initial_gut_state = current_gut_state,
        initial_body_state = current_body_state,
        gut_parameters = gut_parameters,
        body_parameters = body_parameters,
        schedule = schedule,
        routine_activity_schedule = activity_schedule
      )
    current_gut_state <- herbivoreTTR::new_gut_energy_state(
      days[[sequence_day]]$daily$gut_available_energy_final_kj
    )
    current_body_state <- herbivoreTTR::new_body_energy_state(
      days[[sequence_day]]$daily$body_energy_reserve_final_kj
    )
  }

  list(
    sequence_id = sequence_id,
    forcing_phases = forcing_phases,
    days = days
  )
}

all_balanced_control <- run_sequence(
  "all_balanced_control",
  rep("balanced", 4L)
)
shortfall_then_repayment <- run_sequence(
  "shortfall_then_repayment",
  c(
    "shortfall",
    "prescribed_repayment_pulse",
    rep("return_to_reference", 2L)
  )
)
sequences <- list(
  all_balanced_control = all_balanced_control,
  shortfall_then_repayment = shortfall_then_repayment
)

require_that(
  identical(
    all_balanced_control$days[[1L]]$daily$
      gut_available_energy_initial_kj,
    balanced_opening_gut_energy_kj
  ) &&
    identical(
      shortfall_then_repayment$days[[1L]]$daily$
        gut_available_energy_initial_kj,
      balanced_opening_gut_energy_kj
    ) &&
    identical(
      all_balanced_control$days[[1L]]$daily$
        body_energy_reserve_initial_kj,
      10000
    ) &&
    identical(
      shortfall_then_repayment$days[[1L]]$daily$
        body_energy_reserve_initial_kj,
      10000
    ),
  "common gut and body initialization"
)

for (sequence in sequences) {
  for (sequence_day in seq_along(sequence$days)) {
    result <- sequence$days[[sequence_day]]
    hourly <- result$hourly
    daily <- result$daily
    scale <- max(
      1,
      abs(hourly$gut_available_energy_start_kj),
      abs(hourly$gut_available_energy_end_kj),
      abs(hourly$body_energy_reserve_start_kj),
      abs(hourly$body_energy_reserve_end_kj)
    )
    stocks <- unlist(
      hourly[c(
        "gut_available_energy_start_kj",
        "gut_available_energy_end_kj",
        "body_energy_reserve_start_kj",
        "body_energy_reserve_end_kj"
      )],
      use.names = FALSE
    )

    require_that(
      identical(
        hourly$gut_available_energy_start_kj[-1L],
        head(hourly$gut_available_energy_end_kj, -1L)
      ) &&
        identical(
          hourly$body_energy_reserve_start_kj[-1L],
          head(hourly$body_energy_reserve_end_kj, -1L)
        ) &&
        identical(
          hourly$total_system_energy_start_kj[-1L],
          head(hourly$total_system_energy_end_kj, -1L)
        ),
      paste(sequence$sequence_id, "day", sequence_day, "hourly carry-over")
    )
    if (sequence_day > 1L) {
      previous <- sequence$days[[sequence_day - 1L]]$daily
      require_that(
        identical(
          daily$gut_available_energy_initial_kj,
          previous$gut_available_energy_final_kj
        ) &&
          identical(
            daily$body_energy_reserve_initial_kj,
            previous$body_energy_reserve_final_kj
          ) &&
          identical(
            daily$total_system_energy_initial_kj,
            previous$total_system_energy_final_kj
          ),
        paste(sequence$sequence_id, "day", sequence_day, "day carry-over")
      )
    }
    require_that(
      all(is.finite(stocks)) &&
        all(stocks >= 0) &&
        near(hourly$gut_energy_balance_residual_kj, 0, scale) &&
        near(hourly$body_energy_balance_residual_kj, 0, scale) &&
        near(hourly$system_energy_balance_residual_kj, 0, scale) &&
        near(daily$gut_energy_balance_residual_kj, 0, scale) &&
        near(daily$body_energy_balance_residual_kj, 0, scale) &&
        near(daily$system_energy_balance_residual_kj, 0, scale),
      paste(sequence$sequence_id, "day", sequence_day, "stocks and closure")
    )
  }
}

control_goal008_schema <-
  assemble_reference_schema(all_balanced_control$days[1:2])
require_that(
  identical(
    control_goal008_schema,
    balanced_reference[c("hourly", "daily")]
  ),
  "first two control days have exact Goal 008 balanced identity"
)

reference_tolerance_kj <- tail(
  balanced_reference$convergence$
    realized_convergence_tolerance_kj,
  1L
)
for (sequence_day in 3:4) {
  control_day <- all_balanced_control$days[[sequence_day]]
  require_that(
    abs(
      control_day$daily$gut_available_energy_final_kj -
        control_day$daily$gut_available_energy_initial_kj
    ) <= reference_tolerance_kj &&
      near(
        control_day$daily$observed_body_energy_change_kj,
        0,
        scale = 10000
      ) &&
      near(
        control_day$daily$observed_total_system_energy_change_kj,
        0,
        scale = 10000
      ),
    paste(
      "control day",
      sequence_day,
      "retains periodic gut and neutral body behavior"
    )
  )
}

control_gut_boundaries_kj <-
  boundary_values(all_balanced_control, "gut_available_energy")
treatment_gut_boundaries_kj <-
  boundary_values(shortfall_then_repayment, "gut_available_energy")
control_body_boundaries_kj <-
  boundary_values(all_balanced_control, "body_energy_reserve")
treatment_body_boundaries_kj <-
  boundary_values(shortfall_then_repayment, "body_energy_reserve")

gut_contrast_kj <-
  treatment_gut_boundaries_kj - control_gut_boundaries_kj
body_contrast_kj <-
  treatment_body_boundaries_kj - control_body_boundaries_kj
combined_contrast_kj <- gut_contrast_kj + body_contrast_kj

balanced_hourly_input_kj <- rep(
  balanced_energy_schedule$
    prescribed_ingested_available_energy_kj_h,
  4L
)
treatment_hourly_input_kj <- c(
  shortfall_energy_schedule$
    prescribed_ingested_available_energy_kj_h,
  repayment_energy_schedule$
    prescribed_ingested_available_energy_kj_h,
  rep(
    balanced_energy_schedule$
      prescribed_ingested_available_energy_kj_h,
    2L
  )
)
hourly_input_contrast_kj <-
  treatment_hourly_input_kj - balanced_hourly_input_kj
cumulative_input_contrast_kj <-
  c(0, cumsum(hourly_input_contrast_kj))

expected_gut_contrast_kj <- numeric(97L)
for (hour_index in seq_len(96L)) {
  expected_gut_contrast_kj[[hour_index + 1L]] <-
    0.75 * expected_gut_contrast_kj[[hour_index]] +
      hourly_input_contrast_kj[[hour_index]]
}
expected_body_contrast_kj <-
  cumulative_input_contrast_kj - expected_gut_contrast_kj
contrast_closure_residual_kj <-
  combined_contrast_kj - cumulative_input_contrast_kj

day_boundary_indices <- c(1L, 25L, 49L, 73L, 97L)
expected_boundary_gut_contrast_kj <- c(
  0,
  -181.781257888200543,
  181.598860159612849,
  0.182214712297783,
  0.000182832652961
)
expected_boundary_combined_contrast_kj <- c(0, -800, 0, 0, 0)
expected_boundary_body_contrast_kj <-
  expected_boundary_combined_contrast_kj -
    expected_boundary_gut_contrast_kj

require_that(
  identical(hourly_input_contrast_kj[1:24], c(
    rep(-50, 8L),
    rep(0, 8L),
    rep(-50, 8L)
  )) &&
    identical(hourly_input_contrast_kj[25:48], c(
      rep(50, 8L),
      rep(0, 8L),
      rep(50, 8L)
    )) &&
    identical(hourly_input_contrast_kj[49:96], rep(0, 48L)) &&
    identical(
      cumulative_input_contrast_kj[day_boundary_indices],
      expected_boundary_combined_contrast_kj
    ),
  "exact prescribed-input contrast schedule"
)
require_that(
  near(
    gut_contrast_kj,
    expected_gut_contrast_kj,
    scale = pmax(1, abs(expected_gut_contrast_kj), 800)
  ),
  "analytical hourly gut contrast"
)
require_that(
  near(
    gut_contrast_kj[50:97],
    0.75 * gut_contrast_kj[49:96],
    scale = 800
  ),
  "hourly gut contraction after the repayment pulse"
)
daily_gut_contraction_factor <- 0.75^24
require_that(
  near(
    gut_contrast_kj[c(73L, 97L)],
    gut_contrast_kj[c(49L, 73L)] *
      daily_gut_contraction_factor,
    scale = 800
  ),
  "daily gut contraction after the repayment pulse"
)
require_that(
  near(
    gut_contrast_kj[day_boundary_indices],
    expected_boundary_gut_contrast_kj,
    scale = 800
  ) &&
    near(
      body_contrast_kj[day_boundary_indices],
      expected_boundary_body_contrast_kj,
      scale = 10000
    ) &&
    near(
      combined_contrast_kj[day_boundary_indices],
      expected_boundary_combined_contrast_kj,
      scale = 10000
    ),
  "retained day-boundary contrast oracle"
)
require_that(
  near(
    c(
      gut_contrast_kj[[25L]],
      body_contrast_kj[[25L]],
      combined_contrast_kj[[25L]]
    ),
    c(
      -181.781257888200543,
      -618.218742111799457,
      -800
    ),
    scale = 10000
  ),
  "published Goal 011 shortfall-day boundary oracle"
)
require_that(
  near(
    combined_contrast_kj,
    cumulative_input_contrast_kj,
    scale = 10000
  ) &&
    near(
      body_contrast_kj,
      cumulative_input_contrast_kj - gut_contrast_kj,
      scale = 10000
    ) &&
    near(
      body_contrast_kj,
      expected_body_contrast_kj,
      scale = 10000
    ) &&
    near(contrast_closure_residual_kj, 0, scale = 10000),
  "combined-system invariant and body complement"
)

boundary_phase <- c(
  "initial",
  rep("shortfall_day", 24L),
  rep("prescribed_repayment_pulse_day", 24L),
  rep("return_to_reference_day_1", 24L),
  rep("return_to_reference_day_2", 24L)
)
hourly_boundary_contrasts <- data.frame(
  elapsed_time_h = 0:96,
  boundary_phase = boundary_phase,
  cumulative_prescribed_input_contrast_kj =
    cumulative_input_contrast_kj,
  gut_available_energy_contrast_kj = gut_contrast_kj,
  body_energy_reserve_contrast_kj = body_contrast_kj,
  combined_system_energy_contrast_kj = combined_contrast_kj,
  contrast_closure_residual_kj = contrast_closure_residual_kj,
  row.names = NULL
)

daily_sequences <- do.call(rbind, lapply(sequences, function(sequence) {
  do.call(rbind, lapply(seq_along(sequence$days), function(sequence_day) {
    daily <- sequence$days[[sequence_day]]$daily
    phase <- sequence$forcing_phases[[sequence_day]]
    dry_matter_schedule <- switch(
      phase,
      shortfall = shortfall_dry_matter_schedule,
      prescribed_repayment_pulse = repayment_dry_matter_schedule,
      balanced_dry_matter_schedule
    )
    data.frame(
      sequence_id = sequence$sequence_id,
      sequence_day = as.integer(sequence_day),
      forcing_phase = phase,
      daily_prescribed_dry_matter_intake_kg_dm =
        sum(
          dry_matter_schedule$
            prescribed_dry_matter_intake_kg_dm_h
        ),
      total_prescribed_energy_input_kj =
        round(
          daily$total_prescribed_ingested_available_energy_kj
        ),
      total_assimilated_energy_kj =
        round(daily$total_assimilated_energy_kj),
      total_maintenance_expenditure_kj =
        round(daily$total_maintenance_expenditure_kj),
      total_routine_activity_expenditure_kj =
        round(
          daily$
            total_prescribed_routine_activity_expenditure_kj
        ),
      expected_body_energy_change_kj =
        round(daily$expected_body_energy_change_kj),
      observed_body_energy_change_kj =
        round(daily$observed_body_energy_change_kj),
      gut_available_energy_initial_kj =
        round(daily$gut_available_energy_initial_kj),
      gut_available_energy_final_kj =
        round(daily$gut_available_energy_final_kj),
      body_energy_reserve_initial_kj =
        round(daily$body_energy_reserve_initial_kj),
      body_energy_reserve_final_kj =
        round(daily$body_energy_reserve_final_kj),
      total_system_energy_initial_kj =
        round(daily$total_system_energy_initial_kj),
      total_system_energy_final_kj =
        round(daily$total_system_energy_final_kj),
      row.names = NULL
    )
  }))
}))
row.names(daily_sequences) <- NULL

day_boundary_realignment <- data.frame(
  elapsed_time_h = c(0L, 24L, 48L, 72L, 96L),
  boundary_label = c(
    "initial",
    "shortfall_day_close",
    "prescribed_repayment_pulse_day_close",
    "return_to_reference_day_1_close",
    "return_to_reference_day_2_close"
  ),
  cumulative_prescribed_input_contrast_kj =
    cumulative_input_contrast_kj[day_boundary_indices],
  gut_available_energy_contrast_kj =
    gut_contrast_kj[day_boundary_indices],
  expected_gut_contrast_kj =
    expected_gut_contrast_kj[day_boundary_indices],
  gut_contraction_factor_from_previous_boundary = c(
    NA_real_,
    NA_real_,
    NA_real_,
    rep(daily_gut_contraction_factor, 2L)
  ),
  body_energy_reserve_contrast_kj =
    body_contrast_kj[day_boundary_indices],
  expected_body_complement_kj =
    expected_body_contrast_kj[day_boundary_indices],
  combined_system_energy_contrast_kj =
    combined_contrast_kj[day_boundary_indices],
  contrast_closure_residual_kj =
    contrast_closure_residual_kj[day_boundary_indices],
  row.names = NULL
)

require_that(
  identical(dim(hourly_boundary_contrasts), c(97L, 7L)) &&
    identical(dim(daily_sequences), c(8L, 16L)) &&
    identical(dim(day_boundary_realignment), c(5L, 10L)),
  "declared evidence-table dimensions"
)
require_that(
  identical(
    daily_sequences$sequence_id,
    c(
      rep("all_balanced_control", 4L),
      rep("shortfall_then_repayment", 4L)
    )
  ) &&
    identical(daily_sequences$sequence_day, rep(1:4, 2L)) &&
    identical(
      daily_sequences$forcing_phase,
      c(
        rep("balanced", 4L),
        "shortfall",
        "prescribed_repayment_pulse",
        rep("return_to_reference", 2L)
      )
    ) &&
    near(
      daily_sequences$
        daily_prescribed_dry_matter_intake_kg_dm,
      c(rep(0.32, 4L), 0.24, 0.40, 0.32, 0.32)
    ),
  "declared sequence order and forcing phases"
)

interpretation_boundary <- paste0(
  "An external pulse equal to the missing energy returns the whole-system ",
  "contrast to zero, but gut transit delays realignment of the individual ",
  "gut and body contrasts."
)

goal012_evidence <- list(
  hour_of_day = hour_of_day,
  feeding_hours = feeding_hours,
  schedules = list(
    balanced_dry_matter = balanced_dry_matter_schedule,
    shortfall_dry_matter = shortfall_dry_matter_schedule,
    repayment_dry_matter = repayment_dry_matter_schedule,
    balanced_energy = balanced_energy_schedule,
    shortfall_energy = shortfall_energy_schedule,
    repayment_energy = repayment_energy_schedule,
    routine_activity = activity_schedule
  ),
  parameters = list(
    food = food_parameters,
    gut = gut_parameters,
    body = body_parameters
  ),
  balanced_reference = balanced_reference,
  common_initial_states = list(
    gut = common_initial_gut_state,
    body = common_initial_body_state
  ),
  sequences = sequences,
  balanced_hourly_input_kj = balanced_hourly_input_kj,
  treatment_hourly_input_kj = treatment_hourly_input_kj,
  hourly_boundary_contrasts = hourly_boundary_contrasts,
  daily_sequences = daily_sequences,
  day_boundary_realignment = day_boundary_realignment,
  daily_gut_contraction_factor = daily_gut_contraction_factor,
  interpretation_boundary = interpretation_boundary
)

cat("Rebuild Goal 012: prescribed energy-repayment pulse\n\n")
print(
  day_boundary_realignment[c(
    "elapsed_time_h",
    "gut_available_energy_contrast_kj",
    "body_energy_reserve_contrast_kj",
    "combined_system_energy_contrast_kj"
  )],
  row.names = FALSE,
  digits = 10
)
cat(
  "\nThe prescribed repayment pulse restores the combined-system contrast ",
  "to zero while gut and body stocks realign in transit.\n",
  sep = ""
)
cat("All Goal 012 in-memory assertions passed; no files were written.\n")
