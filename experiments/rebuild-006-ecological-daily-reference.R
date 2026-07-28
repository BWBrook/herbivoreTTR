arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 0L) {
  stop("This experiment accepts no command-line arguments.", call. = FALSE)
}

day_rows <- function(result, table, day) {
  value <- result[[table]]
  value[value$measurement_day == day, , drop = FALSE]
}

gut_boundaries_kj <- function(hourly) {
  c(
    hourly$gut_available_energy_start_kj[[1L]],
    hourly$gut_available_energy_end_kj
  )
}

body_boundaries_kj <- function(hourly) {
  c(
    hourly$body_energy_reserve_start_kj[[1L]],
    hourly$body_energy_reserve_end_kj
  )
}

daily_tolerances <- function(result, day) {
  hourly <- day_rows(result, "hourly", day)
  daily <- day_rows(result, "daily", day)
  day_1 <- day_rows(result, "hourly", 1L)
  day_2 <- day_rows(result, "hourly", 2L)
  cycle <- 100 * .Machine$double.eps * max(
    1,
    abs(gut_boundaries_kj(day_1)),
    abs(gut_boundaries_kj(day_2)),
    sum(abs(day_1$prescribed_ingested_available_energy_kj)),
    sum(abs(day_1$assimilated_energy_kj)),
    sum(abs(day_2$assimilated_energy_kj))
  )
  gut <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj))
  )
  body <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )
  c(
    cycle = cycle,
    gut = gut,
    assimilation = cycle + gut,
    body = body,
    neutrality = cycle + gut + body
  )
}

new_reference <- function(scenario_id, reference_type, dry_matter_rates) {
  dry_matter <- herbivoreTTR::new_dry_matter_intake_schedule(
    0:23,
    dry_matter_rates
  )
  energy <- herbivoreTTR::derive_ingested_available_energy_schedule(
    herbivoreTTR::new_food_energy_parameters(10000),
    dry_matter
  )
  result <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    herbivoreTTR::new_gut_energy_state(0),
    herbivoreTTR::new_body_energy_state(10000),
    herbivoreTTR::new_gut_energy_parameters(0.25),
    herbivoreTTR::new_body_energy_parameters(100),
    energy,
    herbivoreTTR::new_routine_activity_expenditure_schedule(
      0:23,
      rep(0, 24L)
    ),
    100 * .Machine$double.eps,
    100L
  )
  list(
    scenario_id = scenario_id,
    reference_type = reference_type,
    dry_matter = dry_matter,
    energy = energy,
    result = result
  )
}

specifications <- list(
  mathematical_continuous = list(
    reference_type = "mathematical",
    dry_matter = rep(0.010, 24L),
    energy = rep(100, 24L),
    feeding = 24L,
    resting = 0L
  ),
  ecological_day_resting = list(
    reference_type = "ecological",
    dry_matter = c(rep(0.015, 8L), rep(0, 8L), rep(0.015, 8L)),
    energy = c(rep(150, 8L), rep(0, 8L), rep(150, 8L)),
    feeding = 16L,
    resting = 8L
  )
)
references <- lapply(names(specifications), function(scenario_id) {
  specification <- specifications[[scenario_id]]
  new_reference(
    scenario_id,
    specification$reference_type,
    specification$dry_matter
  )
})
names(references) <- names(specifications)

validate_reference <- function(reference, specification) {
  dry_matter_rates <-
    reference$dry_matter$prescribed_dry_matter_intake_kg_dm_h
  energy_rates <-
    reference$energy$prescribed_ingested_available_energy_kj_h
  result <- reference$result
  convergence <- result$convergence
  comparison_rows <- seq.int(2L, nrow(convergence))
  cycle_tolerance <- tail(
    convergence$realized_convergence_tolerance_kj,
    1L
  )
  day_1 <- day_rows(result, "hourly", 1L)
  day_2 <- day_rows(result, "hourly", 2L)

  stopifnot(
    identical(reference$reference_type, specification$reference_type),
    identical(reference$dry_matter$hour_of_day, 0:23),
    identical(reference$energy$hour_of_day, 0:23),
    identical(dry_matter_rates, specification$dry_matter),
    identical(energy_rates, specification$energy),
    sum(dry_matter_rates > 0) == specification$feeding,
    sum(dry_matter_rates == 0) == specification$resting,
    abs(sum(dry_matter_rates) - 0.24) <= 100 * .Machine$double.eps,
    identical(sum(energy_rates), 2400),
    identical(day_1$time_start_h, as.numeric(0:23)),
    identical(day_1$time_end_h, as.numeric(1:24)),
    identical(convergence$burn_in_day, seq_len(7L)),
    identical(convergence$converged, c(rep(FALSE, 6L), TRUE)),
    all(is.finite(
      convergence$
        max_abs_previous_day_trajectory_difference_kj[comparison_rows]
    )),
    all(is.finite(
      convergence$realized_convergence_tolerance_kj[comparison_rows]
    )),
    all(
      convergence$realized_convergence_tolerance_kj[comparison_rows] > 0
    ),
    abs(tail(convergence$cycle_boundary_change_kj, 1L)) <=
      cycle_tolerance,
    tail(
      convergence$max_abs_previous_day_trajectory_difference_kj,
      1L
    ) <= cycle_tolerance,
    max(abs(
      gut_boundaries_kj(day_2) - gut_boundaries_kj(day_1)
    )) <= cycle_tolerance,
    identical(
      result$hourly$gut_available_energy_start_kj[-1L],
      head(result$hourly$gut_available_energy_end_kj, -1L)
    ),
    identical(
      result$hourly$body_energy_reserve_start_kj[-1L],
      head(result$hourly$body_energy_reserve_end_kj, -1L)
    )
  )

  for (day in 1:2) {
    hourly <- day_rows(result, "hourly", day)
    daily <- day_rows(result, "daily", day)
    tolerance <- daily_tolerances(result, day)
    body_path <- body_boundaries_kj(hourly)
    stopifnot(
      all(is.finite(body_path)),
      all(body_path >= 0),
      all(is.finite(tolerance)),
      all(tolerance > 0),
      identical(tolerance[["cycle"]], cycle_tolerance),
      identical(
        daily$total_prescribed_ingested_available_energy_kj,
        2400
      ),
      identical(daily$total_maintenance_expenditure_kj, 2400),
      abs(daily$observed_gut_energy_change_kj) <= tolerance[["cycle"]],
      abs(daily$gut_energy_balance_residual_kj) <= tolerance[["gut"]],
      abs(
        daily$total_assimilated_energy_kj -
          daily$total_prescribed_ingested_available_energy_kj
      ) <= tolerance[["assimilation"]],
      abs(daily$body_energy_balance_residual_kj) <= tolerance[["body"]],
      abs(daily$observed_body_energy_change_kj) <=
        tolerance[["neutrality"]]
    )
  }
  invisible(NULL)
}

for (scenario_id in names(references)) {
  validate_reference(
    references[[scenario_id]],
    specifications[[scenario_id]]
  )
}

ecological_hourly <- day_rows(
  references$ecological_day_resting$result,
  "hourly",
  1L
)
rest_rows <-
  ecological_hourly$prescribed_ingested_available_energy_kj_h == 0
stopifnot(
  identical(ecological_hourly$time_start_h[rest_rows], as.numeric(8:15)),
  identical(ecological_hourly$time_end_h[rest_rows], as.numeric(9:16)),
  identical(
    ecological_hourly$time_start_h[!rest_rows],
    as.numeric(c(0:7, 16:23))
  ),
  identical(
    ecological_hourly$time_end_h[!rest_rows],
    as.numeric(c(1:8, 17:24))
  )
)

compare_references <- function(day) {
  mathematical_result <- references$mathematical_continuous$result
  ecological_result <- references$ecological_day_resting$result
  mathematical_hourly <- day_rows(mathematical_result, "hourly", day)
  ecological_hourly <- day_rows(ecological_result, "hourly", day)
  mathematical_daily <- day_rows(mathematical_result, "daily", day)
  ecological_daily <- day_rows(ecological_result, "daily", day)
  mathematical_tolerance <- daily_tolerances(mathematical_result, day)
  ecological_tolerance <- daily_tolerances(ecological_result, day)
  mathematical_gut <- gut_boundaries_kj(mathematical_hourly)
  ecological_gut <- gut_boundaries_kj(ecological_hourly)
  mathematical_body <- body_boundaries_kj(mathematical_hourly)
  ecological_body <- body_boundaries_kj(ecological_hourly)
  differences <- c(
    gut = max(abs(mathematical_gut - ecological_gut)),
    assimilation = max(abs(
      mathematical_hourly$assimilated_energy_kj -
        ecological_hourly$assimilated_energy_kj
    )),
    body = max(abs(mathematical_body - ecological_body))
  )
  distinctness <- c(
    gut =
      mathematical_tolerance[["cycle"]] +
        ecological_tolerance[["cycle"]],
    assimilation =
      mathematical_tolerance[["assimilation"]] +
        ecological_tolerance[["assimilation"]],
    body =
      mathematical_tolerance[["neutrality"]] +
        ecological_tolerance[["neutrality"]]
  )
  landmarks <- c(
    which.max(ecological_gut) - 1L,
    which.min(ecological_gut) - 1L,
    ecological_hourly$hour_of_day[[
      which.max(ecological_hourly$assimilated_energy_kj)
    ]],
    ecological_hourly$hour_of_day[[
      which.min(ecological_hourly$assimilated_energy_kj)
    ]],
    which.max(ecological_body) - 1L,
    which.min(ecological_body) - 1L
  )

  stopifnot(
    identical(
      mathematical_daily$total_prescribed_ingested_available_energy_kj,
      ecological_daily$total_prescribed_ingested_available_energy_kj
    ),
    identical(
      mathematical_daily$total_maintenance_expenditure_kj,
      ecological_daily$total_maintenance_expenditure_kj
    ),
    abs(
      mathematical_daily$total_assimilated_energy_kj -
        ecological_daily$total_assimilated_energy_kj
    ) <=
      mathematical_tolerance[["assimilation"]] +
        ecological_tolerance[["assimilation"]],
    abs(
      mathematical_daily$observed_gut_energy_change_kj -
        ecological_daily$observed_gut_energy_change_kj
    ) <=
      mathematical_tolerance[["cycle"]] +
        ecological_tolerance[["cycle"]],
    abs(
      mathematical_daily$observed_body_energy_change_kj -
        ecological_daily$observed_body_energy_change_kj
    ) <=
      mathematical_tolerance[["neutrality"]] +
        ecological_tolerance[["neutrality"]],
    all(differences > distinctness),
    differences[["gut"]] >= 340,
    differences[["gut"]] <= 341,
    differences[["assimilation"]] >= 85,
    differences[["assimilation"]] <= 86,
    differences[["body"]] >= 411,
    differences[["body"]] <= 412,
    identical(landmarks, c(8L, 16L, 8L, 16L, 10L, 20L))
  )

  data.frame(
    day = day,
    gut_difference_kj = differences[["gut"]],
    assimilation_difference_kj = differences[["assimilation"]],
    body_difference_kj = differences[["body"]],
    gut_phase = "08:00 max / 16:00 min",
    release_phase = "hour 8 max / hour 16 min",
    body_phase = "10:00 max / 20:00 min",
    stringsAsFactors = FALSE
  )
}
contrast_summary <- do.call(rbind, lapply(1:2, compare_references))

whole_kj <- function(value) sprintf("%.0f", round(value))
schedule_summary <- do.call(rbind, lapply(references, function(reference) {
  rates <-
    reference$dry_matter$prescribed_dry_matter_intake_kg_dm_h
  data.frame(
    scenario_id = reference$scenario_id,
    feeding = sum(rates > 0),
    resting = sum(rates == 0),
    dry_matter_kg_dm = sprintf("%.3f", sum(rates)),
    gut_input_kj = whole_kj(sum(
      reference$energy$prescribed_ingested_available_energy_kj_h
    ))
  )
}))
convergence_summary <- do.call(rbind, lapply(references, function(reference) {
  final <- tail(reference$result$convergence, 1L)
  data.frame(
    scenario_id = reference$scenario_id,
    burn_in_day = final$burn_in_day,
    final_gut_kj = whole_kj(final$gut_available_energy_final_kj),
    cycle_change_kj = format(final$cycle_boundary_change_kj, digits = 3L),
    tolerance_kj = format(
      final$realized_convergence_tolerance_kj,
      digits = 3L
    )
  )
}))
daily_summary <- do.call(rbind, lapply(references, function(reference) {
  daily <- reference$result$daily
  data.frame(
    scenario_id = reference$scenario_id,
    day = daily$measurement_day,
    ingested_kj = whole_kj(
      daily$total_prescribed_ingested_available_energy_kj
    ),
    assimilated_kj = whole_kj(daily$total_assimilated_energy_kj),
    maintenance_kj = whole_kj(daily$total_maintenance_expenditure_kj),
    gut_change_kj = whole_kj(daily$observed_gut_energy_change_kj),
    body_change_kj = whole_kj(daily$observed_body_energy_change_kj)
  )
}))
checkpoint_summary <- do.call(rbind, lapply(references, function(reference) {
  hourly <- day_rows(reference$result, "hourly", 1L)
  hours <- c(8L, 16L)
  rows <- match(hours, hourly$hour_of_day)
  data.frame(
    scenario_id = reference$scenario_id,
    boundary = sprintf("%02d:00", hours),
    gut_kj = whole_kj(gut_boundaries_kj(hourly)[hours + 1L]),
    release_kj = whole_kj(hourly$assimilated_energy_kj[rows]),
    body_kj = whole_kj(body_boundaries_kj(hourly)[hours + 1L])
  )
}))
contrast_summary[2:4] <- lapply(contrast_summary[2:4], whole_kj)

show <- function(title, value) {
  cat(title, "\n", sep = "")
  print(value, row.names = FALSE, right = FALSE)
  cat("\n")
}

cat("GOAL 006 ECOLOGICAL DAILY REFERENCE: checks passed\n\n")
show("Schedule evidence (energy in whole kJ):", schedule_summary)
show("Convergence evidence (stocks in whole kJ):", convergence_summary)
show("Measured daily evidence (whole kJ):", daily_summary)
show("08:00 and 16:00 checkpoints (whole kJ):", checkpoint_summary)
show(
  "Trajectory contrasts and ecological landmarks (whole kJ):",
  contrast_summary
)
