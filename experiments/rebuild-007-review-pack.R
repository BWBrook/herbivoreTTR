scenario_ids <- c(
  "zero_routine_activity",
  "four_hour_routine_activity_pulse"
)

declared_files <- c(
  "figure-1-routine-activity-accounting.png",
  "table-1-routine-activity-schedules.csv",
  "table-2-convergence.csv",
  "table-3-daily-summary.csv",
  "table-4-hourly-ledgers.csv"
)

schedule_names <- c(
  "scenario_id",
  "hour_of_day",
  "prescribed_routine_activity_expenditure_kj_h"
)

convergence_names <- c(
  "scenario_id",
  "burn_in_day",
  "gut_available_energy_initial_kj",
  "gut_available_energy_final_kj",
  "cycle_boundary_change_kj",
  "max_abs_previous_day_trajectory_difference_kj",
  "realized_convergence_tolerance_kj",
  "converged"
)

daily_names <- c(
  "scenario_id",
  "measurement_day",
  "gut_available_energy_initial_kj",
  "total_prescribed_ingested_available_energy_kj",
  "total_assimilated_energy_kj",
  "expected_gut_energy_change_kj",
  "observed_gut_energy_change_kj",
  "gut_available_energy_final_kj",
  "gut_energy_balance_residual_kj",
  "body_energy_reserve_initial_kj",
  "total_maintenance_expenditure_kj",
  "total_prescribed_routine_activity_expenditure_kj",
  "expected_body_energy_change_kj",
  "observed_body_energy_change_kj",
  "body_energy_reserve_final_kj",
  "body_energy_balance_residual_kj",
  "total_system_energy_initial_kj",
  "expected_total_system_energy_change_kj",
  "observed_total_system_energy_change_kj",
  "total_system_energy_final_kj",
  "system_energy_balance_residual_kj",
  "body_energy_status"
)

hourly_names <- c(
  "scenario_id",
  "measurement_day",
  "hour_of_day",
  "time_start_h",
  "time_end_h",
  "gut_available_energy_start_kj",
  "prescribed_ingested_available_energy_kj_h",
  "gut_release_fraction_h",
  "assimilated_energy_kj_h",
  "prescribed_ingested_available_energy_kj",
  "assimilated_energy_kj",
  "gut_energy_change_kj",
  "gut_available_energy_end_kj",
  "gut_energy_balance_residual_kj",
  "body_energy_reserve_start_kj",
  "maintenance_expenditure_kj_h",
  "prescribed_routine_activity_expenditure_kj_h",
  "net_body_energy_rate_kj_h",
  "maintenance_expenditure_kj",
  "prescribed_routine_activity_expenditure_kj",
  "body_energy_change_kj",
  "body_energy_reserve_end_kj",
  "body_energy_balance_residual_kj",
  "total_system_energy_start_kj",
  "total_system_energy_end_kj",
  "system_energy_balance_residual_kj"
)

activity_rates <- list(
  zero_routine_activity = rep(0, 24L),
  four_hour_routine_activity_pulse = c(
    rep(0, 8L),
    rep(50, 4L),
    rep(0, 12L)
  )
)

require_that <- function(condition, label) {
  if (!isTRUE(condition)) {
    stop(sprintf("Review-pack validation failed: %s.", label), call. = FALSE)
  }
}

path_exists <- function(path) {
  file.exists(path) || is_link(path)
}

is_link <- function(path) {
  target <- Sys.readlink(path)
  !is.na(target) && nzchar(target)
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

new_fixture <- function(scenario_id) {
  dry_matter_schedule <- herbivoreTTR::new_dry_matter_intake_schedule(
    hour_of_day = 0:23,
    prescribed_dry_matter_intake_kg_dm_h = rep(0.010, 24L)
  )
  energy_schedule <- herbivoreTTR::derive_ingested_available_energy_schedule(
    herbivoreTTR::new_food_energy_parameters(10000),
    dry_matter_schedule
  )
  routine_activity_schedule <-
    herbivoreTTR::new_routine_activity_expenditure_schedule(
      hour_of_day = 0:23,
      prescribed_routine_activity_expenditure_kj_h =
        activity_rates[[scenario_id]]
    )
  result <- herbivoreTTR::run_gut_body_energy_reference_cycle(
    initial_gut_state = herbivoreTTR::new_gut_energy_state(0),
    measurement_body_state = herbivoreTTR::new_body_energy_state(10000),
    gut_parameters = herbivoreTTR::new_gut_energy_parameters(0.25),
    body_parameters = herbivoreTTR::new_body_energy_parameters(100),
    schedule = energy_schedule,
    routine_activity_schedule = routine_activity_schedule,
    gut_convergence_relative_tolerance =
      100 * .Machine$double.eps,
    max_burn_in_days = 100L
  )

  list(
    scenario_id = scenario_id,
    routine_activity_schedule = routine_activity_schedule,
    result = result
  )
}

make_tables <- function(fixtures) {
  schedules <- do.call(rbind, lapply(fixtures, function(fixture) {
    data.frame(
      scenario_id = fixture$scenario_id,
      fixture$routine_activity_schedule,
      row.names = NULL
    )
  }))
  convergence <- do.call(rbind, lapply(fixtures, function(fixture) {
    data.frame(
      scenario_id = fixture$scenario_id,
      fixture$result$convergence,
      row.names = NULL
    )
  }))
  daily <- do.call(rbind, lapply(fixtures, function(fixture) {
    data.frame(
      scenario_id = fixture$scenario_id,
      fixture$result$daily,
      row.names = NULL
    )
  }))
  hourly <- do.call(rbind, lapply(fixtures, function(fixture) {
    data.frame(
      scenario_id = fixture$scenario_id,
      fixture$result$hourly,
      row.names = NULL
    )
  }))
  row.names(schedules) <- NULL
  row.names(convergence) <- NULL
  row.names(daily) <- NULL
  row.names(hourly) <- NULL

  list(
    schedules = schedules,
    convergence = convergence,
    daily = daily,
    hourly = hourly
  )
}

validate_table_contract <- function(tables) {
  schemas <- list(
    schedules = list(rows = 48L, names = schedule_names),
    convergence = list(rows = 14L, names = convergence_names),
    daily = list(rows = 4L, names = daily_names),
    hourly = list(rows = 96L, names = hourly_names)
  )
  for (table_name in names(schemas)) {
    schema <- schemas[[table_name]]
    require_that(
      nrow(tables[[table_name]]) == schema$rows &&
        identical(names(tables[[table_name]]), schema$names),
      paste(table_name, "table schema")
    )
  }
  require_that(
    identical(
      tables$schedules$scenario_id,
      rep(scenario_ids, each = 24L)
    ) &&
      identical(tables$schedules$hour_of_day, rep(0:23, 2L)) &&
      identical(
        tables$convergence$scenario_id,
        rep(scenario_ids, each = 7L)
      ) &&
      identical(tables$convergence$burn_in_day, rep(1:7, 2L)) &&
      identical(
        as.logical(tables$convergence$converged),
        rep(c(rep(FALSE, 6L), TRUE), 2L)
      ) &&
      identical(tables$daily$scenario_id, rep(scenario_ids, each = 2L)) &&
      identical(tables$daily$measurement_day, rep(1:2, 2L)) &&
      identical(tables$hourly$scenario_id, rep(scenario_ids, each = 48L)) &&
      identical(
        tables$hourly$measurement_day,
        rep(rep(1:2, each = 24L), 2L)
      ) &&
      identical(tables$hourly$hour_of_day, rep(0:23, 4L)),
    "serialized table ordering"
  )

  near <- function(observed, expected, scale = NULL) {
    observed <- as.double(observed)
    expected <- as.double(expected)
    scale <- if (is.null(scale)) {
      pmax(1, abs(observed), abs(expected))
    } else {
      pmax(1, as.double(scale))
    }
    length(observed) == length(expected) &&
      length(scale) %in% c(1L, length(observed)) &&
      all(is.finite(observed)) &&
      all(is.finite(expected)) &&
      all(is.finite(scale)) &&
      all(abs(observed - expected) <= 100 * .Machine$double.eps * scale)
  }
  canonical_equal <- function(left, right) {
    row.names(left) <- NULL
    row.names(right) <- NULL
    identical(left, right)
  }
  scenario_table <- function(table, scenario_id, drop_id = FALSE) {
    value <- table[table$scenario_id == scenario_id, , drop = FALSE]
    if (drop_id) {
      value$scenario_id <- NULL
    }
    row.names(value) <- NULL
    value
  }
  row_scale <- function(table, fields) {
    do.call(
      pmax,
      c(list(1), lapply(table[fields], function(value) abs(as.double(value))))
    )
  }
  validate_balance <- function(
    expected,
    observed,
    declared_expected = NULL,
    declared_observed = NULL,
    declared_residual,
    scale,
    label
  ) {
    checks <- c(
      if (is.null(declared_expected)) TRUE else
        near(declared_expected, expected, scale),
      if (is.null(declared_observed)) TRUE else
        near(declared_observed, observed, scale),
      near(declared_residual, observed - expected, scale),
      near(declared_residual, rep(0, length(expected)), scale)
    )
    require_that(all(checks), label)
  }

  for (scenario_id in scenario_ids) {
    schedule <- scenario_table(tables$schedules, scenario_id)
    hourly <- scenario_table(tables$hourly, scenario_id)
    daily <- scenario_table(tables$daily, scenario_id)
    expected <- activity_rates[[scenario_id]]
    observed_activity <- list(
      schedule$prescribed_routine_activity_expenditure_kj_h,
      hourly$prescribed_routine_activity_expenditure_kj_h,
      hourly$prescribed_routine_activity_expenditure_kj,
      daily$total_prescribed_routine_activity_expenditure_kj
    )
    expected_activity <- list(
      expected,
      rep(expected, 2L),
      rep(expected, 2L),
      rep(sum(expected), 2L)
    )
    require_that(
      all(unlist(
        Map(
          function(observed, target) identical(as.double(observed), target),
          observed_activity,
          expected_activity
        ),
        use.names = FALSE
      )),
      paste(scenario_id, "serialized activity rates, amounts, and totals")
    )
  }

  zero_hourly <- scenario_table(tables$hourly, scenario_ids[[1L]], TRUE)
  pulse_hourly <- scenario_table(tables$hourly, scenario_ids[[2L]], TRUE)
  zero_daily <- scenario_table(tables$daily, scenario_ids[[1L]], TRUE)
  pulse_daily <- scenario_table(tables$daily, scenario_ids[[2L]], TRUE)
  require_that(
    canonical_equal(
      scenario_table(tables$convergence, scenario_ids[[1L]], TRUE),
      scenario_table(tables$convergence, scenario_ids[[2L]], TRUE)
    ),
    "serialized convergence invariance"
  )

  invariant_gut_fields <- c(
    "measurement_day",
    "hour_of_day",
    "time_start_h",
    "time_end_h",
    "gut_available_energy_start_kj",
    "prescribed_ingested_available_energy_kj_h",
    "gut_release_fraction_h",
    "assimilated_energy_kj_h",
    "prescribed_ingested_available_energy_kj",
    "assimilated_energy_kj",
    "gut_energy_change_kj",
    "gut_available_energy_end_kj",
    "gut_energy_balance_residual_kj"
  )
  require_that(
    canonical_equal(
      zero_hourly[invariant_gut_fields],
      pulse_hourly[invariant_gut_fields]
    ),
    "serialized clock, ingestion, assimilation, and gut invariance"
  )
  repeated_gut_fields <- setdiff(
    invariant_gut_fields,
    c("measurement_day", "time_start_h", "time_end_h")
  )
  for (scenario_id in scenario_ids) {
    hourly <- scenario_table(tables$hourly, scenario_id, TRUE)
    require_that(
      canonical_equal(
        hourly[hourly$measurement_day == 1L, repeated_gut_fields],
        hourly[hourly$measurement_day == 2L, repeated_gut_fields]
      ),
      paste(scenario_id, "serialized measured-day gut-ledger repetition")
    )
  }

  expected_pulse_difference <- rep(
    c(rep(0, 8L), rep(-50, 4L), rep(0, 12L)),
    2L
  )
  require_that(
    near(
      pulse_hourly$net_body_energy_rate_kj_h -
        zero_hourly$net_body_energy_rate_kj_h,
      expected_pulse_difference
    ) &&
      near(
        pulse_hourly$body_energy_change_kj -
          zero_hourly$body_energy_change_kj,
        expected_pulse_difference
      ),
    "serialized hourly net-rate and body-change counterfactuals"
  )

  stock_names <- c(
    "gut_available_energy_start_kj",
    "gut_available_energy_end_kj",
    "body_energy_reserve_start_kj",
    "body_energy_reserve_end_kj",
    "total_system_energy_start_kj",
    "total_system_energy_end_kj"
  )
  stock_values <- unlist(tables$hourly[stock_names], use.names = FALSE)
  require_that(
    all(is.finite(stock_values)) && all(stock_values >= 0),
    "serialized stocks are finite and non-negative"
  )

  hourly <- tables$hourly
  require_that(
    near(
      hourly$prescribed_ingested_available_energy_kj,
      hourly$prescribed_ingested_available_energy_kj_h
    ) &&
      near(hourly$assimilated_energy_kj, hourly$assimilated_energy_kj_h) &&
      near(
        hourly$maintenance_expenditure_kj,
        hourly$maintenance_expenditure_kj_h
      ),
    "serialized one-hour rate and amount identities"
  )
  require_that(
    near(
      hourly$total_system_energy_start_kj,
      hourly$gut_available_energy_start_kj +
        hourly$body_energy_reserve_start_kj
    ) &&
      near(
        hourly$total_system_energy_end_kj,
        hourly$gut_available_energy_end_kj +
          hourly$body_energy_reserve_end_kj
      ),
    "serialized whole-system stock identities"
  )

  expected_gut_change <-
    hourly$prescribed_ingested_available_energy_kj -
      hourly$assimilated_energy_kj
  observed_gut_change <- hourly$gut_available_energy_end_kj -
    hourly$gut_available_energy_start_kj
  gut_scale <- row_scale(
    hourly,
    c(
      "gut_available_energy_start_kj", "gut_available_energy_end_kj",
      "prescribed_ingested_available_energy_kj", "assimilated_energy_kj"
    )
  )
  expected_body_change <- hourly$assimilated_energy_kj -
    hourly$maintenance_expenditure_kj -
    hourly$prescribed_routine_activity_expenditure_kj
  observed_body_change <- hourly$body_energy_reserve_end_kj -
    hourly$body_energy_reserve_start_kj
  body_scale <- row_scale(
    hourly,
    c(
      "body_energy_reserve_start_kj", "body_energy_reserve_end_kj",
      "assimilated_energy_kj", "maintenance_expenditure_kj",
      "prescribed_routine_activity_expenditure_kj"
    )
  )
  expected_net_rate <- hourly$assimilated_energy_kj_h -
    hourly$maintenance_expenditure_kj_h -
    hourly$prescribed_routine_activity_expenditure_kj_h
  expected_system_change <-
    hourly$prescribed_ingested_available_energy_kj -
      hourly$maintenance_expenditure_kj -
      hourly$prescribed_routine_activity_expenditure_kj
  observed_system_change <- hourly$total_system_energy_end_kj -
    hourly$total_system_energy_start_kj
  system_scale <- row_scale(
    hourly,
    c(
      "total_system_energy_start_kj", "total_system_energy_end_kj",
      "prescribed_ingested_available_energy_kj", "maintenance_expenditure_kj",
      "prescribed_routine_activity_expenditure_kj"
    )
  )

  validate_balance(
    expected_gut_change,
    observed_gut_change,
    declared_expected = hourly$gut_energy_change_kj,
    declared_residual = hourly$gut_energy_balance_residual_kj,
    scale = gut_scale,
    label = "serialized hourly gut accounting"
  )
  validate_balance(
    expected_body_change,
    observed_body_change,
    declared_expected = hourly$body_energy_change_kj,
    declared_residual = hourly$body_energy_balance_residual_kj,
    scale = body_scale,
    label = "serialized hourly body accounting"
  )
  validate_balance(
    expected_system_change,
    observed_system_change,
    declared_residual = hourly$system_energy_balance_residual_kj,
    scale = system_scale,
    label = "serialized hourly whole-system accounting"
  )
  require_that(
    near(hourly$net_body_energy_rate_kj_h, expected_net_rate, body_scale),
    "serialized hourly net body-energy rate"
  )

  for (scenario_id in scenario_ids) {
    scenario_hourly <- scenario_table(tables$hourly, scenario_id, TRUE)
    stock_prefixes <- c(
      "gut_available_energy",
      "body_energy_reserve",
      "total_system_energy"
    )
    require_that(
      all(vapply(stock_prefixes, function(prefix) {
        starts <- scenario_hourly[[paste0(prefix, "_start_kj")]]
        ends <- scenario_hourly[[paste0(prefix, "_end_kj")]]
        near(starts[-1L], head(ends, -1L))
      }, logical(1L))),
      paste(scenario_id, "serialized state continuity")
    )
  }

  daily <- tables$daily
  by_day <- function(field, summarize) {
    vapply(seq_len(nrow(daily)), function(index) {
      rows <- hourly$scenario_id == daily$scenario_id[[index]] &
        hourly$measurement_day == daily$measurement_day[[index]]
      summarize(hourly[[field]][rows])
    }, numeric(1L))
  }
  day_sum <- function(field) by_day(field, sum)
  day_first <- function(field) by_day(field, function(value) value[[1L]])
  day_last <- function(field) by_day(field, function(value) tail(value, 1L))

  ingested <- day_sum("prescribed_ingested_available_energy_kj")
  assimilated <- day_sum("assimilated_energy_kj")
  maintenance <- day_sum("maintenance_expenditure_kj")
  activity <- day_sum("prescribed_routine_activity_expenditure_kj")
  require_that(
    near(daily$total_prescribed_ingested_available_energy_kj, ingested) &&
      near(daily$total_assimilated_energy_kj, assimilated) &&
      near(daily$total_maintenance_expenditure_kj, maintenance) &&
      near(daily$total_prescribed_routine_activity_expenditure_kj, activity),
    "serialized daily totals reconstructed from hourly ledgers"
  )
  require_that(
    all(c(
      near(
        daily$gut_available_energy_initial_kj,
        day_first("gut_available_energy_start_kj")
      ),
      near(
        daily$gut_available_energy_final_kj,
        day_last("gut_available_energy_end_kj")
      ),
      near(
        daily$body_energy_reserve_initial_kj,
        day_first("body_energy_reserve_start_kj")
      ),
      near(
        daily$body_energy_reserve_final_kj,
        day_last("body_energy_reserve_end_kj")
      ),
      near(
        daily$total_system_energy_initial_kj,
        day_first("total_system_energy_start_kj")
      ),
      near(
        daily$total_system_energy_final_kj,
        day_last("total_system_energy_end_kj")
      )
    )),
    "serialized daily stocks match hourly boundaries"
  )

  expected_daily_gut <- ingested - assimilated
  observed_daily_gut <- daily$gut_available_energy_final_kj -
    daily$gut_available_energy_initial_kj
  expected_daily_body <- assimilated - maintenance - activity
  observed_daily_body <- daily$body_energy_reserve_final_kj -
    daily$body_energy_reserve_initial_kj
  expected_daily_system <- ingested - maintenance - activity
  observed_daily_system <- daily$total_system_energy_final_kj -
    daily$total_system_energy_initial_kj
  validate_balance(
    expected_daily_gut,
    observed_daily_gut,
    declared_expected = daily$expected_gut_energy_change_kj,
    declared_observed = daily$observed_gut_energy_change_kj,
    declared_residual = daily$gut_energy_balance_residual_kj,
    scale = row_scale(
      daily,
      c(
        "gut_available_energy_initial_kj", "gut_available_energy_final_kj",
        "total_prescribed_ingested_available_energy_kj",
        "total_assimilated_energy_kj"
      )
    ),
    label = "serialized daily gut accounting"
  )
  validate_balance(
    expected_daily_body,
    observed_daily_body,
    declared_expected = daily$expected_body_energy_change_kj,
    declared_observed = daily$observed_body_energy_change_kj,
    declared_residual = daily$body_energy_balance_residual_kj,
    scale = row_scale(
      daily,
      c(
        "body_energy_reserve_initial_kj", "body_energy_reserve_final_kj",
        "total_assimilated_energy_kj", "total_maintenance_expenditure_kj",
        "total_prescribed_routine_activity_expenditure_kj"
      )
    ),
    label = "serialized daily body accounting"
  )
  validate_balance(
    expected_daily_system,
    observed_daily_system,
    declared_expected = daily$expected_total_system_energy_change_kj,
    declared_observed = daily$observed_total_system_energy_change_kj,
    declared_residual = daily$system_energy_balance_residual_kj,
    scale = row_scale(
      daily,
      c(
        "total_system_energy_initial_kj", "total_system_energy_final_kj",
        "total_prescribed_ingested_available_energy_kj",
        "total_maintenance_expenditure_kj",
        "total_prescribed_routine_activity_expenditure_kj"
      )
    ),
    label = "serialized daily whole-system accounting"
  )

  require_that(
    all(c(
      near(zero_daily$observed_body_energy_change_kj, c(0, 0)),
      near(pulse_daily$observed_body_energy_change_kj, c(-200, -200)),
      near(
        pulse_daily$observed_body_energy_change_kj -
          zero_daily$observed_body_energy_change_kj,
        c(-200, -200)
      )
    )),
    "serialized daily body-change outcomes"
  )
  require_that(
    all(c(
      near(zero_daily$body_energy_reserve_initial_kj, c(10000, 10000)),
      near(zero_daily$body_energy_reserve_final_kj, c(10000, 10000)),
      near(pulse_daily$body_energy_reserve_initial_kj, c(10000, 9800)),
      near(pulse_daily$body_energy_reserve_final_kj, c(9800, 9600)),
      near(
        pulse_daily$body_energy_reserve_final_kj -
          zero_daily$body_energy_reserve_final_kj,
        c(-200, -400)
      )
    )),
    "serialized daily reserve landmarks and cumulative contrasts"
  )
  require_that(
    all(c(
      near(
        pulse_hourly$body_energy_reserve_start_kj[c(9L, 33L)],
        c(10000, 9800)
      ),
      near(
        pulse_hourly$body_energy_reserve_end_kj[c(12L, 36L)],
        c(9800, 9600)
      ),
      identical(zero_daily$body_energy_status, c("neutral", "neutral")) &&
        identical(pulse_daily$body_energy_status, c("deficit", "deficit"))
    )),
    "serialized pulse boundaries and supplementary status labels"
  )

  invisible(NULL)
}

write_csv <- function(value, path) {
  utils::write.csv(value, path, row.names = FALSE, na = "")
}

read_csv <- function(path) {
  utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = ""
  )
}

check_file_set <- function(directory, exact) {
  require_that(dir.exists(directory), "review directory exists")
  require_that(!is_link(directory), "review directory is not a symbolic link")
  entries <- list.files(directory, all.files = TRUE, no.. = TRUE)
  require_that(
    all(entries %in% declared_files),
    "review directory contains no undeclared entries"
  )
  if (isTRUE(exact)) {
    require_that(
      identical(sort(entries), sort(declared_files)),
      "review directory has the exact declared file set"
    )
  }
  for (entry in entries) {
    path <- file.path(directory, entry)
    info <- file.info(path)
    require_that(
      !is_link(path) && isTRUE(info$isdir == FALSE),
      paste(entry, "is a regular non-symbolic file")
    )
  }
  invisible(NULL)
}

write_figure <- function(fixtures, path) {
  zero <- fixtures$zero_routine_activity$result
  pulse <- fixtures$four_hour_routine_activity_pulse$result
  elapsed_intervals <- 0:47
  elapsed_boundaries <- 0:48
  pulse_windows <- matrix(c(8, 12, 32, 36), ncol = 2L, byrow = TRUE)
  colors <- c(
    zero_routine_activity = "#0072B2",
    four_hour_routine_activity_pulse = "#D55E00"
  )
  line_types <- c(
    zero_routine_activity = 1,
    four_hour_routine_activity_pulse = 2
  )

  interval_matrix <- function(field) {
    value <- cbind(zero$hourly[[field]], pulse$hourly[[field]])
    colnames(value) <- scenario_ids
    value
  }
  boundary_matrix <- function(extract) {
    value <- cbind(extract(zero$hourly), extract(pulse$hourly))
    colnames(value) <- scenario_ids
    value
  }

  activity <- interval_matrix(
    "prescribed_routine_activity_expenditure_kj_h"
  )
  net_rate <- interval_matrix("net_body_energy_rate_kj_h")
  body <- boundary_matrix(body_boundaries_kj)
  gut_difference <- gut_boundaries_kj(pulse$hourly) -
    gut_boundaries_kj(zero$hourly)

  draw_background <- function(xlim, ylim, xlab, ylab, title) {
    graphics::plot(
      NA,
      NA,
      xlim = xlim,
      ylim = ylim,
      xlab = xlab,
      ylab = ylab,
      main = title,
      xaxs = "i",
      yaxs = "i"
    )
    usr <- graphics::par("usr")
    for (row in seq_len(nrow(pulse_windows))) {
      graphics::rect(
        pulse_windows[row, 1L],
        usr[[3L]],
        pulse_windows[row, 2L],
        usr[[4L]],
        col = "#F0F0F0",
        border = NA
      )
    }
    graphics::abline(v = 24, col = "#666666", lty = 3, lwd = 1.4)
  }

  draw_interval_panel <- function(values, ylab, title) {
    limits <- range(values, finite = TRUE)
    pad <- max(diff(limits) * 0.08, 2)
    draw_background(
      c(0, 48),
      limits + c(-pad, pad),
      "Elapsed measurement time (h)",
      ylab,
      title
    )
    for (scenario_id in scenario_ids) {
      graphics::lines(
        c(elapsed_intervals, 48),
        c(values[, scenario_id], tail(values[, scenario_id], 1L)),
        type = "s",
        col = colors[[scenario_id]],
        lty = line_types[[scenario_id]],
        lwd = 2.6
      )
    }
    graphics::box()
  }

  grDevices::png(
    path,
    width = 2200,
    height = 1600,
    units = "px",
    pointsize = 14,
    bg = "white",
    res = 150
  )
  device <- grDevices::dev.cur()
  on.exit(if (device %in% grDevices::dev.list()) grDevices::dev.off(device))
  old_par <- graphics::par(
    mfrow = c(2, 2),
    mar = c(4.8, 5.5, 3.2, 1.2),
    oma = c(2.4, 0, 5.4, 0),
    las = 1
  )
  on.exit(graphics::par(old_par), add = TRUE)

  draw_interval_panel(
    activity,
    "Prescribed activity (kJ h^-1)",
    "Routine-activity expenditure"
  )

  gut_pad <- max(max(abs(gut_difference)) * 0.08, 1)
  draw_background(
    c(0, 48),
    c(-gut_pad, gut_pad),
    "Elapsed measurement time (h)",
    "Pulse - zero gut stock (kJ)",
    "Gut-boundary counterfactual"
  )
  graphics::abline(h = 0, col = "#222222", lty = 3)
  graphics::lines(
    elapsed_boundaries,
    gut_difference,
    col = "#009E73",
    lwd = 3.2
  )
  graphics::box()

  draw_interval_panel(
    net_rate,
    "Net body-energy rate (kJ h^-1)",
    "Net body-energy rate"
  )

  body_limits <- range(body, finite = TRUE)
  body_pad <- max(diff(body_limits) * 0.08, 10)
  draw_background(
    c(0, 48),
    body_limits + c(-body_pad, body_pad),
    "Elapsed measurement time (h)",
    "Body-energy reserve (kJ)",
    "Body-reserve boundary stock"
  )
  for (scenario_id in scenario_ids) {
    graphics::lines(
      elapsed_boundaries,
      body[, scenario_id],
      col = colors[[scenario_id]],
      lty = line_types[[scenario_id]],
      lwd = 2.6
    )
  }
  graphics::box()

  graphics::mtext(
    "Synthetic prescribed routine-activity diagnostic",
    side = 3,
    outer = TRUE,
    line = 3,
    font = 2,
    cex = 1.18
  )
  graphics::mtext(
    "Grey: pulse windows; dotted vertical line: day boundary",
    side = 3,
    outer = TRUE,
    line = 1.7,
    cex = 0.84
  )
  graphics::mtext(
    "The pulse changes body expenditure only; the gut counterfactual remains zero",
    side = 1,
    outer = TRUE,
    line = 0.7,
    cex = 0.82
  )
  graphics::par(
    fig = c(0, 1, 0, 1),
    mar = rep(0, 4L),
    oma = rep(0, 4L),
    new = TRUE
  )
  graphics::plot.new()
  graphics::legend(
    "top",
    inset = 0.083,
    horiz = TRUE,
    legend = c("Zero routine activity", "Four-hour activity pulse"),
    col = colors,
    lty = line_types,
    lwd = 2.6,
    bty = "n",
    cex = 0.84
  )
  grDevices::dev.off(device)
  on.exit(NULL)
}

publish_pack <- function(stage, destination) {
  parent <- dirname(destination)
  if (!dir.exists(parent) &&
      !dir.create(parent, recursive = TRUE, showWarnings = FALSE)) {
    stop("Could not create review-pack parent.", call. = FALSE)
  }
  require_that(
    !is_link(parent) && file.access(parent, 2L) == 0L,
    "review-pack parent is a writable non-symbolic directory"
  )
  candidate <- tempfile(
    paste0(".", basename(destination), "-"),
    tmpdir = parent
  )
  if (!dir.create(candidate)) {
    stop("Could not create publication candidate.", call. = FALSE)
  }
  on.exit(unlink(candidate, recursive = TRUE, force = TRUE))
  copied <- file.copy(
    file.path(stage, declared_files),
    candidate,
    overwrite = FALSE,
    copy.date = FALSE
  )
  if (!all(copied)) {
    stop("Could not copy the complete publication candidate.", call. = FALSE)
  }
  check_file_set(candidate, exact = TRUE)

  if (!path_exists(destination)) {
    if (!file.rename(candidate, destination)) {
      stop("Could not publish review pack.", call. = FALSE)
    }
    return(invisible(NULL))
  }

  check_file_set(destination, exact = FALSE)
  backup <- tempfile(
    paste0(".", basename(destination), "-old-"),
    tmpdir = parent
  )
  if (!file.rename(destination, backup)) {
    stop("Could not move the previous review pack aside.", call. = FALSE)
  }
  if (!file.rename(candidate, destination)) {
    file.rename(backup, destination)
    stop("Could not replace the review pack.", call. = FALSE)
  }
  if (unlink(backup, recursive = TRUE, force = TRUE) != 0L) {
    stop("Could not remove the superseded review pack.", call. = FALSE)
  }
  invisible(NULL)
}

main <- function() {
  arguments <- commandArgs(trailingOnly = TRUE)
  if (
    length(arguments) != 1L ||
      is.na(arguments[[1L]]) ||
      !nzchar(arguments[[1L]])
  ) {
    stop(
      "Supply exactly one non-empty output-directory argument.",
      call. = FALSE
    )
  }
  destination <- sub("/+$", "", arguments[[1L]])
  if (!nzchar(destination) || destination == "." || is_link(destination)) {
    stop("Supply a dedicated non-symbolic output directory.", call. = FALSE)
  }
  if (path_exists(destination)) {
    check_file_set(destination, exact = FALSE)
  }

  old_options <- options(digits = 17)
  on.exit(options(old_options), add = TRUE)
  fixtures <- lapply(scenario_ids, new_fixture)
  names(fixtures) <- scenario_ids
  tables <- make_tables(fixtures)
  validate_table_contract(tables)

  stage <- tempfile("rebuild007-review-pack-")
  if (!dir.create(stage)) {
    stop("Could not create staging directory.", call. = FALSE)
  }
  on.exit(unlink(stage, recursive = TRUE, force = TRUE), add = TRUE)
  csv_paths <- c(
    schedules = file.path(
      stage,
      "table-1-routine-activity-schedules.csv"
    ),
    convergence = file.path(stage, "table-2-convergence.csv"),
    daily = file.path(stage, "table-3-daily-summary.csv"),
    hourly = file.path(stage, "table-4-hourly-ledgers.csv")
  )
  for (table_name in names(csv_paths)) {
    write_csv(tables[[table_name]], csv_paths[[table_name]])
  }
  read_back <- lapply(csv_paths, read_csv)
  validate_table_contract(read_back)

  write_figure(
    fixtures,
    file.path(stage, "figure-1-routine-activity-accounting.png")
  )
  check_file_set(stage, exact = TRUE)
  publish_pack(stage, destination)
  check_file_set(destination, exact = TRUE)

  cat(sprintf("Generated Goal 007 review pack at %s\n", destination))
  cat("Files: 5 (exact set; CSV schemas and results read-back validated)\n")
}

main()
