scenario_ids <- c(
  "ecological_day_resting",
  "ecological_activity_uncompensated",
  "ecological_activity_prescribed_balance"
)

declared_files <- c(
  "figure-1-ecological-activity-intake-balance.png",
  "table-1-prescribed-schedules.csv",
  "table-2-convergence.csv",
  "table-3-daily-summary.csv",
  "table-4-hourly-ledgers.csv"
)

schedule_names <- c(
  "scenario_id",
  "hour_of_day",
  "prescribed_dry_matter_intake_kg_dm_h",
  "prescribed_ingested_available_energy_kj_h",
  "prescribed_routine_activity_expenditure_kj_h"
)

convergence_result_names <- c(
  "burn_in_day",
  "gut_available_energy_initial_kj",
  "gut_available_energy_final_kj",
  "cycle_boundary_change_kj",
  "max_abs_previous_day_trajectory_difference_kj",
  "realized_convergence_tolerance_kj",
  "converged"
)
convergence_names <- c("scenario_id", convergence_result_names)

daily_result_names <- c(
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
daily_names <- c("scenario_id", daily_result_names)

hourly_result_names <- c(
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
hourly_names <- c("scenario_id", hourly_result_names)

dry_matter_rates <- list(
  ecological_day_resting = c(
    rep(0.015, 8L),
    rep(0, 8L),
    rep(0.015, 8L)
  ),
  ecological_activity_uncompensated = c(
    rep(0.015, 8L),
    rep(0, 8L),
    rep(0.015, 8L)
  ),
  ecological_activity_prescribed_balance = c(
    rep(0.020, 8L),
    rep(0, 8L),
    rep(0.020, 8L)
  )
)

energy_rates <- list(
  ecological_day_resting = c(
    rep(150, 8L),
    rep(0, 8L),
    rep(150, 8L)
  ),
  ecological_activity_uncompensated = c(
    rep(150, 8L),
    rep(0, 8L),
    rep(150, 8L)
  ),
  ecological_activity_prescribed_balance = c(
    rep(200, 8L),
    rep(0, 8L),
    rep(200, 8L)
  )
)

activity_rates <- list(
  ecological_day_resting = rep(0, 24L),
  ecological_activity_uncompensated = c(
    rep(50, 8L),
    rep(0, 8L),
    rep(50, 8L)
  ),
  ecological_activity_prescribed_balance = c(
    rep(50, 8L),
    rep(0, 8L),
    rep(50, 8L)
  )
)

gut_fields <- c(
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

require_that <- function(condition, label) {
  if (length(condition) != 1L || !isTRUE(condition)) {
    stop(sprintf("Review-pack validation failed: %s.", label), call. = FALSE)
  }
  invisible(NULL)
}

is_link <- function(path) {
  target <- Sys.readlink(path)
  length(target) == 1L && !is.na(target) && nzchar(target)
}

path_exists <- function(path) {
  file.exists(path) || dir.exists(path) || is_link(path)
}

absolute_path <- function(path) {
  if (startsWith(path, "/")) {
    path
  } else {
    file.path(getwd(), path)
  }
}

require_no_link_ancestors <- function(path) {
  components <- strsplit(
    sub("^/+", "", absolute_path(path)),
    "/",
    fixed = TRUE
  )[[1L]]
  current <- "/"
  for (component in components) {
    if (!nzchar(component) || component == ".") {
      next
    }
    current <- if (component == "..") {
      dirname(current)
    } else {
      file.path(current, component)
    }
    if (path_exists(current)) {
      require_that(
        !is_link(current),
        paste("path component is not a symbolic link:", current)
      )
    } else {
      break
    }
  }
  invisible(NULL)
}

near <- function(observed, expected, scale = NULL) {
  observed <- as.double(observed)
  expected <- as.double(expected)
  if (length(observed) != length(expected) ||
      any(!is.finite(observed)) ||
      any(!is.finite(expected))) {
    return(FALSE)
  }
  if (is.null(scale)) {
    scale <- pmax(1, abs(observed), abs(expected))
  } else {
    scale <- pmax(1, as.double(scale))
  }
  length(scale) %in% c(1L, length(observed)) &&
    all(is.finite(scale)) &&
    all(
      abs(observed - expected) <=
        100 * .Machine$double.eps * scale
    )
}

within_tolerance <- function(observed, expected, tolerance) {
  observed <- as.double(observed)
  expected <- as.double(expected)
  tolerance <- as.double(tolerance)
  if (!length(expected) %in% c(1L, length(observed))) {
    return(FALSE)
  }
  expected <- rep(expected, length.out = length(observed))
  length(observed) == length(expected) &&
    length(tolerance) %in% c(1L, length(observed)) &&
    all(is.finite(observed)) &&
    all(is.finite(expected)) &&
    all(is.finite(tolerance)) &&
    all(tolerance >= 0) &&
    all(abs(observed - expected) <= tolerance)
}

same_values <- function(left, right, serialized) {
  if (!isTRUE(serialized)) {
    return(identical(left, right))
  }
  if (is.numeric(left) && is.numeric(right)) {
    if (length(left) != length(right) ||
        !identical(is.na(left), is.na(right))) {
      return(FALSE)
    }
    keep <- !is.na(left)
    return(near(left[keep], right[keep]))
  }
  identical(left, right)
}

same_table <- function(left, right, serialized) {
  row.names(left) <- NULL
  row.names(right) <- NULL
  identical(names(left), names(right)) &&
    identical(dim(left), dim(right)) &&
    all(vapply(
      names(left),
      function(name) {
        same_values(left[[name]], right[[name]], serialized)
      },
      logical(1L)
    ))
}

row_scale <- function(table, fields) {
  do.call(
    pmax,
    c(
      list(1),
      lapply(
        table[fields],
        function(value) abs(as.double(value))
      )
    )
  )
}

scenario_table <- function(table, scenario_id, drop_id = FALSE) {
  value <- table[
    table$scenario_id == scenario_id,
    ,
    drop = FALSE
  ]
  if (drop_id) {
    value$scenario_id <- NULL
  }
  row.names(value) <- NULL
  value
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
  dry_matter_schedule <-
    herbivoreTTR::new_dry_matter_intake_schedule(
      hour_of_day = 0:23,
      prescribed_dry_matter_intake_kg_dm_h =
        dry_matter_rates[[scenario_id]]
    )
  energy_schedule <-
    herbivoreTTR::derive_ingested_available_energy_schedule(
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
    measurement_body_state =
      herbivoreTTR::new_body_energy_state(10000),
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
    dry_matter_schedule = dry_matter_schedule,
    energy_schedule = energy_schedule,
    routine_activity_schedule = routine_activity_schedule,
    result = result
  )
}

make_tables <- function(fixtures) {
  bind <- function(make_table) {
    value <- do.call(rbind, lapply(fixtures, make_table))
    row.names(value) <- NULL
    value
  }

  list(
    schedules = bind(function(fixture) {
      data.frame(
        scenario_id = fixture$scenario_id,
        hour_of_day = fixture$dry_matter_schedule$hour_of_day,
        prescribed_dry_matter_intake_kg_dm_h =
          fixture$dry_matter_schedule$
            prescribed_dry_matter_intake_kg_dm_h,
        prescribed_ingested_available_energy_kj_h =
          fixture$energy_schedule$
            prescribed_ingested_available_energy_kj_h,
        prescribed_routine_activity_expenditure_kj_h =
          fixture$routine_activity_schedule$
            prescribed_routine_activity_expenditure_kj_h,
        check.names = FALSE
      )
    }),
    convergence = bind(function(fixture) {
      data.frame(
        scenario_id = fixture$scenario_id,
        fixture$result$convergence,
        check.names = FALSE
      )
    }),
    daily = bind(function(fixture) {
      data.frame(
        scenario_id = fixture$scenario_id,
        fixture$result$daily,
        check.names = FALSE
      )
    }),
    hourly = bind(function(fixture) {
      data.frame(
        scenario_id = fixture$scenario_id,
        fixture$result$hourly,
        check.names = FALSE
      )
    })
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
    if (is.null(declared_expected)) {
      TRUE
    } else {
      near(declared_expected, expected, scale)
    },
    if (is.null(declared_observed)) {
      TRUE
    } else {
      near(declared_observed, observed, scale)
    },
    near(declared_residual, observed - expected, scale),
    near(declared_residual, rep(0, length(expected)), scale)
  )
  require_that(all(checks), label)
}

validate_evidence <- function(tables, serialized = FALSE) {
  schemas <- list(
    schedules = list(rows = 72L, names = schedule_names),
    convergence = list(rows = 21L, names = convergence_names),
    daily = list(rows = 6L, names = daily_names),
    hourly = list(rows = 144L, names = hourly_names)
  )
  require_that(
    identical(names(tables), names(schemas)),
    "exact table collection"
  )
  for (table_name in names(schemas)) {
    schema <- schemas[[table_name]]
    require_that(
      is.data.frame(tables[[table_name]]) &&
        nrow(tables[[table_name]]) == schema$rows &&
        identical(names(tables[[table_name]]), schema$names),
      paste(table_name, "exact schema and row count")
    )
  }

  require_that(
    identical(
      tables$schedules$scenario_id,
      rep(scenario_ids, each = 24L)
    ) &&
      identical(
        as.integer(tables$schedules$hour_of_day),
        rep(0:23, length(scenario_ids))
      ) &&
      identical(
        tables$convergence$scenario_id,
        rep(scenario_ids, each = 7L)
      ) &&
      identical(
        as.integer(tables$convergence$burn_in_day),
        rep(1:7, length(scenario_ids))
      ) &&
      identical(
        tables$daily$scenario_id,
        rep(scenario_ids, each = 2L)
      ) &&
      identical(
        as.integer(tables$daily$measurement_day),
        rep(1:2, length(scenario_ids))
      ) &&
      identical(
        tables$hourly$scenario_id,
        rep(scenario_ids, each = 48L)
      ) &&
      identical(
        as.integer(tables$hourly$measurement_day),
        rep(rep(1:2, each = 24L), length(scenario_ids))
      ) &&
      identical(
        as.integer(tables$hourly$hour_of_day),
        rep(0:23, 2L * length(scenario_ids))
      ),
    "declared table ordering"
  )

  require_that(
    all(vapply(
      tables$schedules[vapply(
        tables$schedules,
        is.numeric,
        logical(1L)
      )],
      function(value) all(is.finite(value)),
      logical(1L)
    )) &&
      all(vapply(
        tables$daily[vapply(
          tables$daily,
          is.numeric,
          logical(1L)
        )],
        function(value) all(is.finite(value)),
        logical(1L)
      )) &&
      all(vapply(
        tables$hourly[vapply(
          tables$hourly,
          is.numeric,
          logical(1L)
        )],
        function(value) all(is.finite(value)),
        logical(1L)
      )),
    "finite schedule and measured-ledger values"
  )

  first_convergence_rows <- seq.int(
    1L,
    nrow(tables$convergence),
    by = 7L
  )
  convergence_numeric <- setdiff(
    convergence_result_names,
    c(
      "max_abs_previous_day_trajectory_difference_kj",
      "realized_convergence_tolerance_kj",
      "converged"
    )
  )
  require_that(
    all(vapply(
      tables$convergence[convergence_numeric],
      function(value) all(is.finite(value)),
      logical(1L)
    )) &&
      identical(
        which(is.na(
          tables$convergence$
            max_abs_previous_day_trajectory_difference_kj
        )),
        first_convergence_rows
      ) &&
      identical(
        which(is.na(
          tables$convergence$
            realized_convergence_tolerance_kj
        )),
        first_convergence_rows
      ) &&
      all(is.finite(
        tables$convergence$
          max_abs_previous_day_trajectory_difference_kj[
            -first_convergence_rows
          ]
      )) &&
      all(is.finite(
        tables$convergence$
          realized_convergence_tolerance_kj[
            -first_convergence_rows
          ]
      )),
    "finite convergence values with declared first-day missing values"
  )

  expected_dry_matter_totals <- c(0.24, 0.24, 0.32)
  expected_energy_totals <- c(2400, 2400, 3200)
  expected_activity_totals <- c(0, 800, 800)
  expected_statuses <- list(
    ecological_day_resting = rep("neutral", 2L),
    ecological_activity_uncompensated = rep("deficit", 2L),
    ecological_activity_prescribed_balance = rep("neutral", 2L)
  )

  for (index in seq_along(scenario_ids)) {
    scenario_id <- scenario_ids[[index]]
    schedule <- scenario_table(tables$schedules, scenario_id)
    convergence <- scenario_table(
      tables$convergence,
      scenario_id
    )
    daily <- scenario_table(tables$daily, scenario_id)
    hourly <- scenario_table(tables$hourly, scenario_id)

    require_that(
      same_values(
        schedule$prescribed_dry_matter_intake_kg_dm_h,
        dry_matter_rates[[scenario_id]],
        serialized
      ) &&
        same_values(
          schedule$
            prescribed_ingested_available_energy_kj_h,
          energy_rates[[scenario_id]],
          serialized
        ) &&
        same_values(
          schedule$
            prescribed_routine_activity_expenditure_kj_h,
          activity_rates[[scenario_id]],
          serialized
        ) &&
        identical(
          as.integer(which(
            schedule$
              prescribed_ingested_available_energy_kj_h > 0
          ) - 1L),
          c(0:7, 16:23)
        ) &&
        identical(
          as.integer(which(
            schedule$
              prescribed_ingested_available_energy_kj_h == 0
          ) - 1L),
          8:15
        ),
      paste(scenario_id, "prescribed schedule")
    )
    require_that(
      near(
        sum(
          schedule$
            prescribed_dry_matter_intake_kg_dm_h
        ),
        expected_dry_matter_totals[[index]]
      ) &&
        near(
          sum(
            schedule$
              prescribed_ingested_available_energy_kj_h
          ),
          expected_energy_totals[[index]]
        ) &&
        near(
          sum(
            schedule$
              prescribed_routine_activity_expenditure_kj_h
          ),
          expected_activity_totals[[index]]
        ),
      paste(scenario_id, "prescribed daily totals")
    )
    require_that(
      identical(
        as.logical(convergence$converged),
        c(rep(FALSE, 6L), TRUE)
      ) &&
        all(
          convergence$
            realized_convergence_tolerance_kj[-1L] > 0
        ) &&
        within_tolerance(
          tail(convergence$cycle_boundary_change_kj, 1L),
          0,
          tail(
            convergence$
              realized_convergence_tolerance_kj,
            1L
          )
        ) &&
        within_tolerance(
          tail(
            convergence$
              max_abs_previous_day_trajectory_difference_kj,
            1L
          ),
          0,
          tail(
            convergence$
              realized_convergence_tolerance_kj,
            1L
          )
        ),
      paste(scenario_id, "day-7 convergence")
    )
    require_that(
      same_values(
        hourly$
          prescribed_ingested_available_energy_kj_h,
        rep(energy_rates[[scenario_id]], 2L),
        serialized
      ) &&
        same_values(
          hourly$
            prescribed_routine_activity_expenditure_kj_h,
          rep(activity_rates[[scenario_id]], 2L),
          serialized
        ) &&
        identical(
          daily$body_energy_status,
          expected_statuses[[scenario_id]]
        ),
      paste(scenario_id, "measured forcing and statuses")
    )

    repeated_fields <- setdiff(
      gut_fields,
      c("measurement_day", "time_start_h", "time_end_h")
    )
    day_1 <- hourly[
      as.integer(hourly$measurement_day) == 1L,
      repeated_fields,
      drop = FALSE
    ]
    day_2 <- hourly[
      as.integer(hourly$measurement_day) == 2L,
      repeated_fields,
      drop = FALSE
    ]
    require_that(
      same_table(day_1, day_2, serialized),
      paste(scenario_id, "measured gut repetition")
    )
    for (prefix in c(
      "gut_available_energy",
      "body_energy_reserve",
      "total_system_energy"
    )) {
      require_that(
        same_values(
          hourly[[paste0(prefix, "_start_kj")]][-1L],
          head(
            hourly[[paste0(prefix, "_end_kj")]],
            -1L
          ),
          serialized
        ),
        paste(scenario_id, prefix, "state continuity")
      )
    }
  }

  baseline_convergence <- scenario_table(
    tables$convergence,
    scenario_ids[[1L]],
    TRUE
  )
  unbalanced_convergence <- scenario_table(
    tables$convergence,
    scenario_ids[[2L]],
    TRUE
  )
  require_that(
    same_table(
      baseline_convergence,
      unbalanced_convergence,
      serialized
    ),
    "baseline and uncompensated convergence invariance"
  )

  baseline_hourly <- scenario_table(
    tables$hourly,
    scenario_ids[[1L]],
    TRUE
  )
  unbalanced_hourly <- scenario_table(
    tables$hourly,
    scenario_ids[[2L]],
    TRUE
  )
  balanced_hourly <- scenario_table(
    tables$hourly,
    scenario_ids[[3L]],
    TRUE
  )
  baseline_daily <- scenario_table(
    tables$daily,
    scenario_ids[[1L]],
    TRUE
  )
  unbalanced_daily <- scenario_table(
    tables$daily,
    scenario_ids[[2L]],
    TRUE
  )
  balanced_daily <- scenario_table(
    tables$daily,
    scenario_ids[[3L]],
    TRUE
  )

  require_that(
    same_table(
      baseline_hourly[gut_fields],
      unbalanced_hourly[gut_fields],
      serialized
    ),
    "baseline and uncompensated measured gut invariance"
  )

  for (field in c(
    "gut_available_energy_initial_kj",
    "gut_available_energy_final_kj"
  )) {
    require_that(
      near(
        scenario_table(
          tables$convergence,
          scenario_ids[[3L]],
          TRUE
        )[[field]],
        (4 / 3) * baseline_convergence[[field]]
      ),
      paste("four-thirds burn-in scaling:", field)
    )
  }
  for (field in c(
    "gut_available_energy_start_kj",
    "gut_available_energy_end_kj",
    "assimilated_energy_kj_h",
    "assimilated_energy_kj"
  )) {
    require_that(
      near(
        balanced_hourly[[field]],
        (4 / 3) * baseline_hourly[[field]]
      ),
      paste("four-thirds measured scaling:", field)
    )
  }

  expected_activity_difference <- rep(
    c(rep(50, 8L), rep(0, 8L), rep(50, 8L)),
    2L
  )
  require_that(
    near(
      baseline_hourly$net_body_energy_rate_kj_h -
        unbalanced_hourly$net_body_energy_rate_kj_h,
      expected_activity_difference
    ) &&
      near(
        baseline_hourly$body_energy_change_kj -
          unbalanced_hourly$body_energy_change_kj,
        expected_activity_difference
      ) &&
      same_values(
        balanced_hourly$
          prescribed_routine_activity_expenditure_kj_h,
        unbalanced_hourly$
          prescribed_routine_activity_expenditure_kj_h,
        serialized
      ) &&
      same_values(
        balanced_hourly$maintenance_expenditure_kj_h,
        unbalanced_hourly$maintenance_expenditure_kj_h,
        serialized
      ) &&
      same_values(
        balanced_hourly$
          prescribed_ingested_available_energy_kj_h -
          unbalanced_hourly$
            prescribed_ingested_available_energy_kj_h,
        expected_activity_difference,
        serialized
      ),
    "hourly activity-only and added-input contrasts"
  )

  expected_neutral_contrast <-
    baseline_hourly$assimilated_energy_kj_h / 3 -
      balanced_hourly$
        prescribed_routine_activity_expenditure_kj_h
  observed_neutral_contrast <-
    balanced_hourly$net_body_energy_rate_kj_h -
      baseline_hourly$net_body_energy_rate_kj_h
  neutral_contrast_tolerance <-
    100 * .Machine$double.eps * (
      pmax(
        1,
        abs(balanced_hourly$net_body_energy_rate_kj_h),
        abs(baseline_hourly$net_body_energy_rate_kj_h)
      ) +
        pmax(
          1,
          abs(baseline_hourly$assimilated_energy_kj_h / 3),
          abs(
            balanced_hourly$
              prescribed_routine_activity_expenditure_kj_h
          )
        )
    )
  require_that(
    within_tolerance(
      observed_neutral_contrast,
      expected_neutral_contrast,
      neutral_contrast_tolerance
    ) &&
      max(abs(observed_neutral_contrast)) > 0 &&
      max(abs(
        body_boundaries_kj(balanced_hourly) -
          body_boundaries_kj(baseline_hourly)
      )) > 0,
    "distinct neutral-reference within-day trajectories"
  )

  stock_names <- c(
    "gut_available_energy_start_kj",
    "gut_available_energy_end_kj",
    "body_energy_reserve_start_kj",
    "body_energy_reserve_end_kj",
    "total_system_energy_start_kj",
    "total_system_energy_end_kj"
  )
  stock_values <- unlist(
    tables$hourly[stock_names],
    use.names = FALSE
  )
  require_that(
    all(is.finite(stock_values)) && all(stock_values >= 0),
    "finite non-negative measured stocks"
  )

  hourly <- tables$hourly
  require_that(
    near(
      hourly$prescribed_ingested_available_energy_kj,
      hourly$prescribed_ingested_available_energy_kj_h
    ) &&
      near(
        hourly$assimilated_energy_kj,
        hourly$assimilated_energy_kj_h
      ) &&
      near(
        hourly$maintenance_expenditure_kj,
        hourly$maintenance_expenditure_kj_h
      ) &&
      near(
        hourly$prescribed_routine_activity_expenditure_kj,
        hourly$
          prescribed_routine_activity_expenditure_kj_h
      ),
    "one-hour rate and amount identities"
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
    "whole-system stock identities"
  )

  expected_hourly_gut <-
    hourly$prescribed_ingested_available_energy_kj -
      hourly$assimilated_energy_kj
  observed_hourly_gut <-
    hourly$gut_available_energy_end_kj -
      hourly$gut_available_energy_start_kj
  gut_scale <- row_scale(
    hourly,
    c(
      "gut_available_energy_start_kj",
      "gut_available_energy_end_kj",
      "prescribed_ingested_available_energy_kj",
      "assimilated_energy_kj"
    )
  )
  expected_hourly_body <-
    hourly$assimilated_energy_kj -
      hourly$maintenance_expenditure_kj -
      hourly$prescribed_routine_activity_expenditure_kj
  observed_hourly_body <-
    hourly$body_energy_reserve_end_kj -
      hourly$body_energy_reserve_start_kj
  body_scale <- row_scale(
    hourly,
    c(
      "body_energy_reserve_start_kj",
      "body_energy_reserve_end_kj",
      "assimilated_energy_kj",
      "maintenance_expenditure_kj",
      "prescribed_routine_activity_expenditure_kj"
    )
  )
  expected_hourly_system <-
    hourly$prescribed_ingested_available_energy_kj -
      hourly$maintenance_expenditure_kj -
      hourly$prescribed_routine_activity_expenditure_kj
  observed_hourly_system <-
    hourly$total_system_energy_end_kj -
      hourly$total_system_energy_start_kj
  system_scale <- row_scale(
    hourly,
    c(
      "total_system_energy_start_kj",
      "total_system_energy_end_kj",
      "prescribed_ingested_available_energy_kj",
      "assimilated_energy_kj",
      "maintenance_expenditure_kj",
      "prescribed_routine_activity_expenditure_kj"
    )
  )
  validate_balance(
    expected_hourly_gut,
    observed_hourly_gut,
    declared_expected = hourly$gut_energy_change_kj,
    declared_residual = hourly$gut_energy_balance_residual_kj,
    scale = gut_scale,
    label = "hourly gut accounting"
  )
  validate_balance(
    expected_hourly_body,
    observed_hourly_body,
    declared_expected = hourly$body_energy_change_kj,
    declared_residual = hourly$body_energy_balance_residual_kj,
    scale = body_scale,
    label = "hourly body accounting"
  )
  validate_balance(
    expected_hourly_system,
    observed_hourly_system,
    declared_residual = hourly$system_energy_balance_residual_kj,
    scale = system_scale,
    label = "hourly whole-system accounting"
  )
  require_that(
    near(
      hourly$net_body_energy_rate_kj_h,
      hourly$assimilated_energy_kj_h -
        hourly$maintenance_expenditure_kj_h -
        hourly$
          prescribed_routine_activity_expenditure_kj_h,
      body_scale
    ),
    "hourly net body-energy rate"
  )

  daily <- tables$daily
  by_day <- function(field, summarize) {
    vapply(seq_len(nrow(daily)), function(index) {
      rows <-
        hourly$scenario_id == daily$scenario_id[[index]] &
          as.integer(hourly$measurement_day) ==
            as.integer(daily$measurement_day[[index]])
      summarize(hourly[[field]][rows])
    }, numeric(1L))
  }
  day_sum <- function(field) {
    by_day(field, sum)
  }
  day_first <- function(field) {
    by_day(field, function(value) value[[1L]])
  }
  day_last <- function(field) {
    by_day(field, function(value) tail(value, 1L))
  }

  ingested <- day_sum(
    "prescribed_ingested_available_energy_kj"
  )
  assimilated <- day_sum("assimilated_energy_kj")
  maintenance <- day_sum("maintenance_expenditure_kj")
  activity <- day_sum(
    "prescribed_routine_activity_expenditure_kj"
  )
  require_that(
    near(
      daily$total_prescribed_ingested_available_energy_kj,
      ingested
    ) &&
      near(daily$total_assimilated_energy_kj, assimilated) &&
      near(
        daily$total_maintenance_expenditure_kj,
        maintenance
      ) &&
      near(
        daily$
          total_prescribed_routine_activity_expenditure_kj,
        activity
      ),
    "daily totals reconstructed from hourly ledgers"
  )
  require_that(
    near(
      daily$gut_available_energy_initial_kj,
      day_first("gut_available_energy_start_kj")
    ) &&
      near(
        daily$gut_available_energy_final_kj,
        day_last("gut_available_energy_end_kj")
      ) &&
      near(
        daily$body_energy_reserve_initial_kj,
        day_first("body_energy_reserve_start_kj")
      ) &&
      near(
        daily$body_energy_reserve_final_kj,
        day_last("body_energy_reserve_end_kj")
      ) &&
      near(
        daily$total_system_energy_initial_kj,
        day_first("total_system_energy_start_kj")
      ) &&
      near(
        daily$total_system_energy_final_kj,
        day_last("total_system_energy_end_kj")
      ),
    "daily stocks reconstructed from hourly boundaries"
  )

  expected_daily_gut <- ingested - assimilated
  observed_daily_gut <-
    daily$gut_available_energy_final_kj -
      daily$gut_available_energy_initial_kj
  expected_daily_body <- assimilated - maintenance - activity
  observed_daily_body <-
    daily$body_energy_reserve_final_kj -
      daily$body_energy_reserve_initial_kj
  expected_daily_system <- ingested - maintenance - activity
  observed_daily_system <-
    daily$total_system_energy_final_kj -
      daily$total_system_energy_initial_kj
  daily_gut_scale <- row_scale(
    daily,
    c(
      "gut_available_energy_initial_kj",
      "gut_available_energy_final_kj",
      "total_prescribed_ingested_available_energy_kj",
      "total_assimilated_energy_kj"
    )
  )
  daily_body_scale <- row_scale(
    daily,
    c(
      "body_energy_reserve_initial_kj",
      "body_energy_reserve_final_kj",
      "total_assimilated_energy_kj",
      "total_maintenance_expenditure_kj",
      "total_prescribed_routine_activity_expenditure_kj"
    )
  )
  daily_system_scale <- row_scale(
    daily,
    c(
      "total_system_energy_initial_kj",
      "total_system_energy_final_kj",
      "total_prescribed_ingested_available_energy_kj",
      "total_assimilated_energy_kj",
      "total_maintenance_expenditure_kj",
      "total_prescribed_routine_activity_expenditure_kj"
    )
  )
  validate_balance(
    expected_daily_gut,
    observed_daily_gut,
    declared_expected = daily$expected_gut_energy_change_kj,
    declared_observed = daily$observed_gut_energy_change_kj,
    declared_residual = daily$gut_energy_balance_residual_kj,
    scale = daily_gut_scale,
    label = "daily gut accounting"
  )
  validate_balance(
    expected_daily_body,
    observed_daily_body,
    declared_expected = daily$expected_body_energy_change_kj,
    declared_observed = daily$observed_body_energy_change_kj,
    declared_residual = daily$body_energy_balance_residual_kj,
    scale = daily_body_scale,
    label = "daily body accounting"
  )
  validate_balance(
    expected_daily_system,
    observed_daily_system,
    declared_expected =
      daily$expected_total_system_energy_change_kj,
    declared_observed =
      daily$observed_total_system_energy_change_kj,
    declared_residual =
      daily$system_energy_balance_residual_kj,
    scale = daily_system_scale,
    label = "daily whole-system accounting"
  )

  cycle_tolerance <- vapply(
    seq_len(nrow(daily)),
    function(index) {
      convergence <- scenario_table(
        tables$convergence,
        daily$scenario_id[[index]]
      )
      tail(
        convergence$realized_convergence_tolerance_kj,
        1L
      )
    },
    numeric(1L)
  )
  gut_tolerance <-
    100 * .Machine$double.eps * daily_gut_scale
  body_tolerance <-
    100 * .Machine$double.eps * daily_body_scale
  system_tolerance <-
    100 * .Machine$double.eps * daily_system_scale
  assimilation_tolerance <- cycle_tolerance + gut_tolerance
  neutrality_tolerance <-
    cycle_tolerance + gut_tolerance + body_tolerance
  require_that(
    within_tolerance(observed_daily_gut, 0, cycle_tolerance) &&
      within_tolerance(
        assimilated,
        ingested,
        assimilation_tolerance
      ),
    "periodic daily gut closure and assimilation"
  )

  baseline_rows <-
    daily$scenario_id == "ecological_day_resting"
  unbalanced_rows <-
    daily$scenario_id ==
      "ecological_activity_uncompensated"
  balanced_rows <-
    daily$scenario_id ==
      "ecological_activity_prescribed_balance"
  neutral_rows <- baseline_rows | balanced_rows
  require_that(
    within_tolerance(
      observed_daily_body[neutral_rows],
      0,
      neutrality_tolerance[neutral_rows]
    ) &&
      within_tolerance(
        observed_daily_system[neutral_rows],
        0,
        system_tolerance[neutral_rows]
      ) &&
      within_tolerance(
        observed_daily_body[unbalanced_rows],
        c(-800, -800),
        neutrality_tolerance[unbalanced_rows]
      ) &&
      within_tolerance(
        observed_daily_system[unbalanced_rows],
        c(-800, -800),
        system_tolerance[unbalanced_rows]
      ),
    "daily neutral and uncompensated outcomes"
  )

  require_that(
    same_values(
      baseline_daily$observed_body_energy_change_kj -
        unbalanced_daily$observed_body_energy_change_kj,
      c(800, 800),
      serialized
    ) &&
      same_values(
        baseline_daily$
          observed_total_system_energy_change_kj -
          unbalanced_daily$
            observed_total_system_energy_change_kj,
        c(800, 800),
        serialized
      ) &&
      same_values(
        baseline_daily$body_energy_reserve_final_kj -
          unbalanced_daily$body_energy_reserve_final_kj,
        c(800, 1600),
        serialized
      ),
    "daily activity-only effects"
  )

  balanced_rows_index <- which(balanced_rows)
  unbalanced_rows_index <- which(unbalanced_rows)
  require_that(
    same_values(
      balanced_daily$
        total_prescribed_ingested_available_energy_kj -
        unbalanced_daily$
          total_prescribed_ingested_available_energy_kj,
      c(800, 800),
      serialized
    ) &&
      within_tolerance(
        balanced_daily$total_assimilated_energy_kj -
          unbalanced_daily$total_assimilated_energy_kj,
        c(800, 800),
        assimilation_tolerance[balanced_rows_index] +
          assimilation_tolerance[unbalanced_rows_index]
      ) &&
      within_tolerance(
        balanced_daily$observed_body_energy_change_kj -
          unbalanced_daily$observed_body_energy_change_kj,
        c(800, 800),
        neutrality_tolerance[balanced_rows_index] +
          neutrality_tolerance[unbalanced_rows_index]
      ) &&
      within_tolerance(
        balanced_daily$
          observed_total_system_energy_change_kj -
          unbalanced_daily$
            observed_total_system_energy_change_kj,
        c(800, 800),
        system_tolerance[balanced_rows_index] +
          system_tolerance[unbalanced_rows_index]
      ) &&
      within_tolerance(
        balanced_daily$body_energy_reserve_final_kj -
          unbalanced_daily$body_energy_reserve_final_kj,
        c(800, 1600),
        neutrality_tolerance[balanced_rows_index] +
          neutrality_tolerance[unbalanced_rows_index]
      ),
    "daily added-input effects"
  )

  landmark_indices <- c(1L, 9L, 17L, 25L, 33L, 41L, 49L)
  baseline_landmarks <-
    body_boundaries_kj(baseline_hourly)[landmark_indices]
  unbalanced_landmarks <-
    body_boundaries_kj(unbalanced_hourly)[landmark_indices]
  observed_landmark_difference <-
    baseline_landmarks - unbalanced_landmarks
  expected_landmark_difference <-
    c(0, 400, 400, 800, 1200, 1200, 1600)
  landmark_ok <- if (!isTRUE(serialized)) {
    identical(
      observed_landmark_difference,
      expected_landmark_difference
    )
  } else {
    within_tolerance(
      observed_landmark_difference,
      expected_landmark_difference,
      100 * .Machine$double.eps * (
        pmax(1, abs(baseline_landmarks)) +
          pmax(1, abs(unbalanced_landmarks)) +
          pmax(1, abs(expected_landmark_difference))
      )
    )
  }
  require_that(
    landmark_ok,
    "continuous activity-only body-boundary landmarks"
  )

  invisible(NULL)
}

write_csv <- function(value, path) {
  utils::write.csv(
    value,
    path,
    row.names = FALSE,
    na = ""
  )
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
  require_that(
    dir.exists(directory) && !is_link(directory),
    "review-pack path is a non-symbolic directory"
  )
  entries <- list.files(
    directory,
    all.files = TRUE,
    no.. = TRUE
  )
  require_that(
    all(entries %in% declared_files),
    "review-pack directory contains no undeclared entries"
  )
  if (isTRUE(exact)) {
    require_that(
      identical(sort(entries), sort(declared_files)),
      "review-pack directory has the exact declared file set"
    )
  }
  for (entry in entries) {
    path <- file.path(directory, entry)
    info <- file.info(path)
    require_that(
      !is_link(path) &&
        file_test("-f", path) &&
        isFALSE(info$isdir),
      paste(entry, "is a regular non-symbolic file")
    )
  }
  invisible(NULL)
}

write_figure <- function(fixtures, path) {
  elapsed_intervals <- 0:47
  elapsed_boundaries <- 0:48
  rest_windows <- matrix(
    c(8, 16, 32, 40),
    ncol = 2L,
    byrow = TRUE
  )
  colors <- c(
    ecological_day_resting = "#0072B2",
    ecological_activity_uncompensated = "#D55E00",
    ecological_activity_prescribed_balance = "#009E73"
  )
  line_types <- c(
    ecological_day_resting = 1,
    ecological_activity_uncompensated = 2,
    ecological_activity_prescribed_balance = 3
  )
  legend_labels <- c(
    "Zero activity baseline",
    "Activity, baseline input",
    "Activity, prescribed balance"
  )

  interval_matrix <- function(field) {
    value <- do.call(cbind, lapply(fixtures, function(fixture) {
      fixture$result$hourly[[field]]
    }))
    colnames(value) <- scenario_ids
    value
  }
  boundary_matrix <- function() {
    value <- do.call(cbind, lapply(fixtures, function(fixture) {
      body_boundaries_kj(fixture$result$hourly)
    }))
    colnames(value) <- scenario_ids
    value
  }

  panels <- list(
    input = interval_matrix(
      "prescribed_ingested_available_energy_kj_h"
    ),
    activity = interval_matrix(
      "prescribed_routine_activity_expenditure_kj_h"
    ),
    net_rate = interval_matrix("net_body_energy_rate_kj_h"),
    body = boundary_matrix()
  )

  draw_background <- function(ylim, ylab, title) {
    graphics::plot(
      NA,
      NA,
      xlim = c(0, 48),
      ylim = ylim,
      xlab = "Elapsed measurement time (h)",
      ylab = ylab,
      main = title,
      xaxs = "i",
      yaxs = "i"
    )
    usr <- graphics::par("usr")
    for (row in seq_len(nrow(rest_windows))) {
      graphics::rect(
        rest_windows[row, 1L],
        usr[[3L]],
        rest_windows[row, 2L],
        usr[[4L]],
        col = "#E8E8E8",
        border = NA
      )
    }
    graphics::abline(
      v = 24,
      col = "#555555",
      lty = 3,
      lwd = 1.5
    )
  }

  draw_interval_panel <- function(values, ylab, title) {
    limits <- range(values, finite = TRUE)
    pad <- max(diff(limits) * 0.08, 2)
    draw_background(
      limits + c(-pad, pad),
      ylab,
      title
    )
    for (scenario_id in scenario_ids) {
      graphics::lines(
        c(elapsed_intervals, 48),
        c(
          values[, scenario_id],
          tail(values[, scenario_id], 1L)
        ),
        type = "s",
        col = colors[[scenario_id]],
        lty = line_types[[scenario_id]],
        lwd = 2.6
      )
    }
    graphics::box()
  }

  draw_boundary_panel <- function(values, ylab, title) {
    limits <- range(values, finite = TRUE)
    pad <- max(diff(limits) * 0.08, 10)
    draw_background(
      limits + c(-pad, pad),
      ylab,
      title
    )
    for (scenario_id in scenario_ids) {
      graphics::lines(
        elapsed_boundaries,
        values[, scenario_id],
        col = colors[[scenario_id]],
        lty = line_types[[scenario_id]],
        lwd = 2.6
      )
    }
    graphics::box()
  }

  grDevices::png(
    path,
    width = 2400,
    height = 1800,
    units = "px",
    pointsize = 15,
    bg = "white",
    res = 150
  )
  device <- grDevices::dev.cur()
  on.exit(
    if (device %in% grDevices::dev.list()) {
      grDevices::dev.off(device)
    }
  )
  old_par <- graphics::par(
    mfrow = c(2, 2),
    mar = c(4.8, 5.6, 3.2, 1.2),
    oma = c(2.6, 0, 5.6, 0),
    las = 1
  )
  on.exit(graphics::par(old_par), add = TRUE)

  draw_interval_panel(
    panels$input,
    "Prescribed gut input (kJ h^-1)",
    "Prescribed gut-input rate"
  )
  draw_interval_panel(
    panels$activity,
    "Prescribed activity (kJ h^-1)",
    "Routine-activity expenditure"
  )
  draw_interval_panel(
    panels$net_rate,
    "Net body-energy rate (kJ h^-1)",
    "Net body-energy rate"
  )
  draw_boundary_panel(
    panels$body,
    "Body-energy reserve (kJ)",
    "Body-reserve boundary stock"
  )

  graphics::mtext(
    "Synthetic prescribed activity and intake accounting",
    side = 3,
    outer = TRUE,
    line = 3.1,
    font = 2,
    cex = 1.18
  )
  graphics::mtext(
    "Grey: rest-closed intervals; dotted vertical line: day boundary",
    side = 3,
    outer = TRUE,
    line = 1.8,
    cex = 0.84
  )
  graphics::mtext(
    "Prescribed balance is an accounting construction",
    side = 1,
    outer = TRUE,
    line = 0.8,
    cex = 0.84
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
    legend = legend_labels,
    col = colors,
    lty = line_types,
    lwd = 2.6,
    bty = "n",
    cex = 0.82
  )
  grDevices::dev.off(device)
  on.exit(NULL)
}

publish_pack <- function(stage, destination) {
  require_no_link_ancestors(destination)
  parent <- dirname(destination)
  if (!dir.exists(parent) &&
      !dir.create(
        parent,
        recursive = TRUE,
        showWarnings = FALSE
      )) {
    stop("Could not create review-pack parent.", call. = FALSE)
  }
  require_no_link_ancestors(parent)
  require_that(
    dir.exists(parent) &&
      !is_link(parent) &&
      file.access(parent, 2L) == 0L,
    "review-pack parent is a writable non-symbolic directory"
  )

  candidate <- tempfile(
    paste0(".", basename(destination), "-"),
    tmpdir = parent
  )
  if (!dir.create(candidate)) {
    stop("Could not create publication candidate.", call. = FALSE)
  }
  on.exit(
    unlink(candidate, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  copied <- file.copy(
    file.path(stage, declared_files),
    candidate,
    overwrite = FALSE,
    copy.date = FALSE
  )
  if (!all(copied)) {
    stop(
      "Could not copy the complete publication candidate.",
      call. = FALSE
    )
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
    stop(
      "Could not move the previous review pack aside.",
      call. = FALSE
    )
  }
  if (!file.rename(candidate, destination)) {
    restored <- file.rename(backup, destination)
    if (!restored) {
      stop(
        "Publication failed and the previous pack could not be restored.",
        call. = FALSE
      )
    }
    stop("Could not replace the review pack.", call. = FALSE)
  }
  if (unlink(backup, recursive = TRUE, force = TRUE) != 0L) {
    stop(
      "Could not remove the superseded review pack.",
      call. = FALSE
    )
  }
  invisible(NULL)
}

main <- function() {
  arguments <- commandArgs(trailingOnly = TRUE)
  if (
    length(arguments) != 1L ||
      is.na(arguments[[1L]]) ||
      !nzchar(arguments[[1L]]) ||
      grepl("[\r\n]", arguments[[1L]])
  ) {
    stop(
      "Supply exactly one non-empty output-directory argument.",
      call. = FALSE
    )
  }
  destination <- sub("/+$", "", arguments[[1L]])
  if (
    !nzchar(destination) ||
      destination %in% c(".", "..") ||
      is_link(destination)
  ) {
    stop(
      "Supply a dedicated non-symbolic output directory.",
      call. = FALSE
    )
  }
  require_no_link_ancestors(destination)
  if (path_exists(destination)) {
    check_file_set(destination, exact = FALSE)
  }

  old_options <- options(digits = 17)
  on.exit(options(old_options), add = TRUE)

  fixtures <- lapply(scenario_ids, new_fixture)
  names(fixtures) <- scenario_ids
  tables <- make_tables(fixtures)
  validate_evidence(tables, serialized = FALSE)

  stage <- tempfile("rebuild008-review-pack-")
  if (!dir.create(stage)) {
    stop("Could not create staging directory.", call. = FALSE)
  }
  on.exit(
    unlink(stage, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  csv_paths <- c(
    schedules = file.path(
      stage,
      "table-1-prescribed-schedules.csv"
    ),
    convergence = file.path(
      stage,
      "table-2-convergence.csv"
    ),
    daily = file.path(
      stage,
      "table-3-daily-summary.csv"
    ),
    hourly = file.path(
      stage,
      "table-4-hourly-ledgers.csv"
    )
  )
  for (table_name in names(csv_paths)) {
    write_csv(tables[[table_name]], csv_paths[[table_name]])
  }
  read_back <- lapply(csv_paths, read_csv)
  validate_evidence(read_back, serialized = TRUE)

  write_figure(
    fixtures,
    file.path(
      stage,
      "figure-1-ecological-activity-intake-balance.png"
    )
  )
  check_file_set(stage, exact = TRUE)
  publish_pack(stage, destination)
  check_file_set(destination, exact = TRUE)

  cat(sprintf(
    "Generated Goal 008 review pack at %s\n",
    destination
  ))
  cat(
    "Files: 5 ",
    "(exact set; staged and CSV read-back validated)\n",
    sep = ""
  )
}

main()
