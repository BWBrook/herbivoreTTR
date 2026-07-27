.reference_cycle_api <- function() {
  list(
    run = getFromNamespace(
      "run_gut_body_energy_reference_cycle",
      "herbivoreTTR"
    ),
    run_day = getFromNamespace("run_gut_body_energy_day", "herbivoreTTR"),
    step_gut = getFromNamespace("step_gut_energy", "herbivoreTTR"),
    new_gut_state = getFromNamespace(
      "new_gut_energy_state",
      "herbivoreTTR"
    ),
    new_body_state = getFromNamespace(
      "new_body_energy_state",
      "herbivoreTTR"
    ),
    new_gut_parameters = getFromNamespace(
      "new_gut_energy_parameters",
      "herbivoreTTR"
    ),
    new_body_parameters = getFromNamespace(
      "new_body_energy_parameters",
      "herbivoreTTR"
    ),
    new_schedule = getFromNamespace(
      "new_ingested_available_energy_schedule",
      "herbivoreTTR"
    )
  )
}

.reference_cycle_fixture <- function(
  gut_energy_kj = 0,
  body_energy_kj = 10000,
  release_fraction_h = 0.25,
  ingestion_rates_kj_h = rep(0, 24L),
  maintenance_kj_h = 100,
  relative_tolerance = 100 * .Machine$double.eps,
  max_burn_in_days = 100L
) {
  api <- .reference_cycle_api()

  list(
    api = api,
    initial_gut_state = api$new_gut_state(gut_energy_kj),
    measurement_body_state = api$new_body_state(body_energy_kj),
    gut_parameters = api$new_gut_parameters(release_fraction_h),
    body_parameters = api$new_body_parameters(maintenance_kj_h),
    schedule = api$new_schedule(0:23, ingestion_rates_kj_h),
    relative_tolerance = relative_tolerance,
    max_burn_in_days = max_burn_in_days
  )
}

.run_reference_cycle_fixture <- function(fixture) {
  fixture$api$run(
    fixture$initial_gut_state,
    fixture$measurement_body_state,
    fixture$gut_parameters,
    fixture$body_parameters,
    fixture$schedule,
    fixture$relative_tolerance,
    fixture$max_burn_in_days
  )
}

.replay_reference_gut_day <- function(
  api,
  initial_state,
  parameters,
  schedule
) {
  boundaries_kj <- numeric(25L)
  ingested_kj <- numeric(24L)
  assimilated_kj <- numeric(24L)
  current_state <- initial_state
  boundaries_kj[[1L]] <- current_state$gut_available_energy_kj

  for (row_index in seq_len(24L)) {
    transition <- api$step_gut(
      current_state,
      parameters,
      schedule[row_index, , drop = FALSE]
    )
    ingested_kj[[row_index]] <-
      transition$fluxes$prescribed_ingested_available_energy_kj
    assimilated_kj[[row_index]] <-
      transition$fluxes$assimilated_energy_kj
    current_state <- transition$state
    boundaries_kj[[row_index + 1L]] <-
      current_state$gut_available_energy_kj
  }

  list(
    state = current_state,
    boundaries_kj = boundaries_kj,
    ingested_kj = ingested_kj,
    assimilated_kj = assimilated_kj
  )
}

.expected_replayed_convergence <- function(
  api,
  initial_state,
  parameters,
  schedule,
  relative_tolerance,
  completed_days
) {
  replays <- vector("list", completed_days)
  current_state <- initial_state

  for (day in seq_len(completed_days)) {
    replays[[day]] <- .replay_reference_gut_day(
      api,
      current_state,
      parameters,
      schedule
    )
    current_state <- replays[[day]]$state
  }

  maximum_difference_kj <- rep(NA_real_, completed_days)
  realized_tolerance_kj <- rep(NA_real_, completed_days)
  converged <- rep(FALSE, completed_days)

  for (day in seq.int(2L, completed_days)) {
    current <- replays[[day]]
    previous <- replays[[day - 1L]]
    maximum_difference_kj[[day]] <- max(abs(
      current$boundaries_kj - previous$boundaries_kj
    ))
    realized_scale_kj <- max(
      1,
      abs(current$boundaries_kj),
      abs(previous$boundaries_kj),
      sum(abs(current$ingested_kj)),
      sum(abs(current$assimilated_kj)),
      sum(abs(previous$assimilated_kj))
    )
    realized_tolerance_kj[[day]] <-
      as.double(relative_tolerance) * realized_scale_kj
    cycle_boundary_change_kj <-
      current$boundaries_kj[[25L]] - current$boundaries_kj[[1L]]
    converged[[day]] <-
      maximum_difference_kj[[day]] <= realized_tolerance_kj[[day]] &&
      abs(cycle_boundary_change_kj) <= realized_tolerance_kj[[day]]
  }

  convergence <- data.frame(
    burn_in_day = seq_len(completed_days),
    gut_available_energy_initial_kj = vapply(
      replays,
      function(day) day$boundaries_kj[[1L]],
      numeric(1)
    ),
    gut_available_energy_final_kj = vapply(
      replays,
      function(day) day$boundaries_kj[[25L]],
      numeric(1)
    ),
    cycle_boundary_change_kj = vapply(
      replays,
      function(day) {
        day$boundaries_kj[[25L]] - day$boundaries_kj[[1L]]
      },
      numeric(1)
    ),
    max_abs_previous_day_trajectory_difference_kj =
      maximum_difference_kj,
    realized_convergence_tolerance_kj = realized_tolerance_kj,
    converged = converged
  )

  list(convergence = convergence, replays = replays)
}

.canonical_data_frame_rows <- function(value) {
  row.names(value) <- seq_len(nrow(value))
  value
}

.reference_cycle_copy <- function(value) {
  unserialize(serialize(value, connection = NULL))
}

.reference_cycle_convergence_columns <- c(
  "burn_in_day",
  "gut_available_energy_initial_kj",
  "gut_available_energy_final_kj",
  "cycle_boundary_change_kj",
  "max_abs_previous_day_trajectory_difference_kj",
  "realized_convergence_tolerance_kj",
  "converged"
)

.reference_cycle_hourly_columns <- c(
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
  "maintenance_expenditure_kj",
  "body_energy_change_kj",
  "body_energy_reserve_end_kj",
  "body_energy_balance_residual_kj",
  "total_system_energy_start_kj",
  "total_system_energy_end_kj",
  "system_energy_balance_residual_kj"
)

.reference_cycle_daily_columns <- c(
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

test_that("reference-cycle runner has exact public and return schemas", {
  fixture <- .reference_cycle_fixture()
  result <- .run_reference_cycle_fixture(fixture)

  expect_identical(
    names(formals(fixture$api$run)),
    c(
      "initial_gut_state",
      "measurement_body_state",
      "gut_parameters",
      "body_parameters",
      "schedule",
      "gut_convergence_relative_tolerance",
      "max_burn_in_days"
    )
  )
  expect_type(result, "list")
  expect_false(is.object(result))
  expect_identical(names(result), c("convergence", "hourly", "daily"))

  expect_identical(class(result$convergence), "data.frame")
  expect_identical(dim(result$convergence), c(2L, 7L))
  expect_identical(
    names(result$convergence),
    .reference_cycle_convergence_columns
  )
  expect_type(result$convergence$burn_in_day, "integer")
  expect_true(all(vapply(
    result$convergence[2:6],
    is.double,
    logical(1)
  )))
  expect_type(result$convergence$converged, "logical")
  expect_identical(result$convergence$burn_in_day, 1:2)
  expect_identical(
    result$convergence[
      1L,
      c(
        "max_abs_previous_day_trajectory_difference_kj",
        "realized_convergence_tolerance_kj"
      )
    ],
    data.frame(
      max_abs_previous_day_trajectory_difference_kj = NA_real_,
      realized_convergence_tolerance_kj = NA_real_
    )
  )
  expect_identical(result$convergence$converged, c(FALSE, TRUE))

  expect_identical(class(result$hourly), "data.frame")
  expect_identical(dim(result$hourly), c(48L, 22L))
  expect_identical(names(result$hourly), .reference_cycle_hourly_columns)
  expect_identical(result$hourly$measurement_day, rep(1:2, each = 24L))
  expect_identical(result$hourly$hour_of_day, rep(0:23, 2L))

  expect_identical(class(result$daily), "data.frame")
  expect_identical(dim(result$daily), c(2L, 20L))
  expect_identical(names(result$daily), .reference_cycle_daily_columns)
  expect_identical(result$daily$measurement_day, 1:2)

  expect_identical(row.names(result$convergence), as.character(1:2))
  expect_identical(row.names(result$hourly), as.character(1:48))
  expect_identical(row.names(result$daily), as.character(1:2))
  expect_identical(result$daily$total_assimilated_energy_kj, c(0, 0))
  expect_identical(
    result$daily$observed_body_energy_change_kj,
    c(-2400, -2400)
  )
  expect_identical(result$daily$body_energy_status, c("deficit", "deficit"))
})

test_that("reference-cycle runner strictly validates every argument", {
  fixture <- .reference_cycle_fixture(max_burn_in_days = 3L)
  run <- fixture$api$run
  arguments <- list(
    fixture$initial_gut_state,
    fixture$measurement_body_state,
    fixture$gut_parameters,
    fixture$body_parameters,
    fixture$schedule,
    fixture$relative_tolerance,
    fixture$max_burn_in_days
  )

  malformed_first_five <- list(
    structure(fixture$initial_gut_state, note = "attributed"),
    structure(fixture$measurement_body_state, note = "attributed"),
    structure(fixture$gut_parameters, note = "attributed"),
    structure(fixture$body_parameters, note = "attributed"),
    structure(fixture$schedule, note = "attributed")
  )
  for (index in seq_along(malformed_first_five)) {
    malformed_arguments <- arguments
    malformed_arguments[[index]] <- malformed_first_five[[index]]
    expect_error(do.call(run, malformed_arguments))
  }

  invalid_tolerances <- list(
    numeric(),
    c(1e-8, 2e-8),
    0,
    1,
    -1e-8,
    Inf,
    NaN,
    NA_real_,
    "1e-8",
    TRUE,
    matrix(1e-8),
    structure(1e-8, note = "attributed")
  )
  for (value in invalid_tolerances) {
    malformed_arguments <- arguments
    malformed_arguments[[6L]] <- value
    expect_error(do.call(run, malformed_arguments))
  }

  invalid_maximum_days <- list(
    integer(),
    c(2L, 3L),
    1L,
    2,
    NA_integer_,
    Inf,
    "2",
    TRUE,
    matrix(2L),
    structure(2L, note = "attributed")
  )
  for (value in invalid_maximum_days) {
    malformed_arguments <- arguments
    malformed_arguments[[7L]] <- value
    expect_error(do.call(run, malformed_arguments))
  }

  expect_error(do.call(run, arguments[-7L]))
  expect_error(do.call(run, c(arguments, list(extra = 1))))

  large_maximum_arguments <- arguments
  large_maximum_arguments[[7L]] <- .Machine$integer.max
  large_maximum_result <- do.call(run, large_maximum_arguments)
  expect_identical(nrow(large_maximum_result$convergence), 2L)
})

test_that("burn-in matches an independent 25-boundary gut replay", {
  fixture <- .reference_cycle_fixture(
    gut_energy_kj = 17,
    release_fraction_h = 1,
    ingestion_rates_kj_h = as.double(0:23),
    maintenance_kj_h = 10,
    relative_tolerance = 1e-8,
    max_burn_in_days = 3L
  )
  result <- .run_reference_cycle_fixture(fixture)
  expected <- .expected_replayed_convergence(
    fixture$api,
    fixture$initial_gut_state,
    fixture$gut_parameters,
    fixture$schedule,
    fixture$relative_tolerance,
    completed_days = 3L
  )

  expect_identical(result$convergence, expected$convergence)
  expect_identical(result$convergence$converged, c(FALSE, FALSE, TRUE))
  expect_identical(
    result$convergence$cycle_boundary_change_kj,
    vapply(
      expected$replays,
      function(day) {
        day$boundaries_kj[[25L]] - day$boundaries_kj[[1L]]
      },
      numeric(1)
    )
  )
  expect_true(all(is.finite(
    result$convergence$realized_convergence_tolerance_kj[-1L]
  )))
  expect_true(all(
    result$convergence$realized_convergence_tolerance_kj[-1L] > 0
  ))

  measured_boundaries <- lapply(1:2, function(day) {
    ledger <- result$hourly[result$hourly$measurement_day == day, ]
    c(
      ledger$gut_available_energy_start_kj[[1L]],
      ledger$gut_available_energy_end_kj
    )
  })
  final_cycle_tolerance <- tail(
    result$convergence$realized_convergence_tolerance_kj,
    1L
  )
  expect_lte(
    max(abs(measured_boundaries[[2L]] - measured_boundaries[[1L]])),
    final_cycle_tolerance
  )
  expect_identical(
    result$hourly$body_energy_reserve_start_kj[[1L]],
    fixture$measurement_body_state$body_energy_reserve_kj
  )
})

test_that("measured days are exact one-day runs with exact carry-over", {
  fixture <- .reference_cycle_fixture(
    release_fraction_h = 0.25,
    ingestion_rates_kj_h = c(rep(0, 18L), rep(400, 6L)),
    maintenance_kj_h = 100
  )
  result <- .run_reference_cycle_fixture(fixture)
  converged_gut_state <- fixture$api$new_gut_state(
    tail(
      result$convergence$gut_available_energy_final_kj,
      1L
    )
  )
  direct_day_1 <- fixture$api$run_day(
    converged_gut_state,
    fixture$measurement_body_state,
    fixture$gut_parameters,
    fixture$body_parameters,
    fixture$schedule
  )
  day_1_hourly <- .canonical_data_frame_rows(
    result$hourly[result$hourly$measurement_day == 1L, -1L, drop = FALSE]
  )
  day_1_daily <- .canonical_data_frame_rows(
    result$daily[result$daily$measurement_day == 1L, -1L, drop = FALSE]
  )

  expect_identical(day_1_hourly, direct_day_1$hourly)
  expect_identical(day_1_daily, direct_day_1$daily)

  day_2_gut_state <- fixture$api$new_gut_state(
    direct_day_1$daily$gut_available_energy_final_kj
  )
  day_2_body_state <- fixture$api$new_body_state(
    direct_day_1$daily$body_energy_reserve_final_kj
  )
  direct_day_2 <- fixture$api$run_day(
    day_2_gut_state,
    day_2_body_state,
    fixture$gut_parameters,
    fixture$body_parameters,
    fixture$schedule
  )
  day_2_hourly <- .canonical_data_frame_rows(
    result$hourly[result$hourly$measurement_day == 2L, -1L, drop = FALSE]
  )
  day_2_daily <- .canonical_data_frame_rows(
    result$daily[result$daily$measurement_day == 2L, -1L, drop = FALSE]
  )

  expect_identical(day_2_hourly, direct_day_2$hourly)
  expect_identical(day_2_daily, direct_day_2$daily)
  expect_identical(
    result$hourly$gut_available_energy_start_kj[[25L]],
    result$hourly$gut_available_energy_end_kj[[24L]]
  )
  expect_identical(
    result$hourly$body_energy_reserve_start_kj[[25L]],
    result$hourly$body_energy_reserve_end_kj[[24L]]
  )
})

test_that("reference-cycle runner does not mutate any supplied input", {
  fixture <- .reference_cycle_fixture(
    gut_energy_kj = 17,
    release_fraction_h = 1,
    ingestion_rates_kj_h = as.double(0:23),
    maintenance_kj_h = 10,
    relative_tolerance = 1e-8,
    max_burn_in_days = 3L
  )
  before <- .reference_cycle_copy(list(
    fixture$initial_gut_state,
    fixture$measurement_body_state,
    fixture$gut_parameters,
    fixture$body_parameters,
    fixture$schedule,
    fixture$relative_tolerance,
    fixture$max_burn_in_days
  ))

  .run_reference_cycle_fixture(fixture)

  expect_identical(
    list(
      fixture$initial_gut_state,
      fixture$measurement_body_state,
      fixture$gut_parameters,
      fixture$body_parameters,
      fixture$schedule,
      fixture$relative_tolerance,
      fixture$max_burn_in_days
    ),
    before
  )
})

test_that("maximum-day failure returns no partial result", {
  fixture <- .reference_cycle_fixture(
    release_fraction_h = 1e-6,
    ingestion_rates_kj_h = rep(100, 24L),
    relative_tolerance = 100 * .Machine$double.eps,
    max_burn_in_days = 2L
  )
  result <- NULL

  expect_error(
    result <- .run_reference_cycle_fixture(fixture),
    "did not converge"
  )
  expect_null(result)
})

test_that("non-finite realized convergence arithmetic fails before comparison", {
  fixture <- .reference_cycle_fixture(
    release_fraction_h = 1,
    ingestion_rates_kj_h = rep(.Machine$double.xmax / 16, 24L),
    relative_tolerance = 100 * .Machine$double.eps,
    max_burn_in_days = 2L
  )
  result <- NULL

  expect_error(
    result <- .run_reference_cycle_fixture(fixture),
    "convergence scale must be finite"
  )
  expect_null(result)
})

test_that("measured body-boundary errors propagate without a partial result", {
  fixture <- .reference_cycle_fixture(
    body_energy_kj = 2500,
    ingestion_rates_kj_h = rep(0, 24L),
    maintenance_kj_h = 100
  )
  result <- NULL

  expect_error(
    result <- .run_reference_cycle_fixture(fixture),
    "negative"
  )
  expect_null(result)
})

.declared_reference_cycle_fixture <- function(
  intake_rates_kg_dm_h
) {
  api <- .reference_cycle_api()
  new_food_parameters <- getFromNamespace(
    "new_food_energy_parameters",
    "herbivoreTTR"
  )
  new_dry_matter_schedule <- getFromNamespace(
    "new_dry_matter_intake_schedule",
    "herbivoreTTR"
  )
  derive_energy_schedule <- getFromNamespace(
    "derive_ingested_available_energy_schedule",
    "herbivoreTTR"
  )
  dry_matter_schedule <- new_dry_matter_schedule(
    0:23,
    intake_rates_kg_dm_h
  )
  energy_schedule <- derive_energy_schedule(
    new_food_parameters(10000),
    dry_matter_schedule
  )
  runner_fixture <- list(
    api = api,
    initial_gut_state = api$new_gut_state(0),
    measurement_body_state = api$new_body_state(10000),
    gut_parameters = api$new_gut_parameters(0.25),
    body_parameters = api$new_body_parameters(100),
    schedule = energy_schedule,
    relative_tolerance = 100 * .Machine$double.eps,
    max_burn_in_days = 100L
  )

  list(
    dry_matter_schedule = dry_matter_schedule,
    runner_fixture = runner_fixture,
    result = .run_reference_cycle_fixture(runner_fixture)
  )
}

.declared_reference_cycle_fixtures <- function() {
  lapply(
    list(
      zero = rep(0, 24L),
      constant = rep(0.010, 24L),
      concentrated_late = c(rep(0, 18L), rep(0.040, 6L))
    ),
    .declared_reference_cycle_fixture
  )
}

.raw_reference_cycle_tolerances <- function(
  result,
  measurement_day
) {
  hourly <- result$hourly[
    result$hourly$measurement_day == measurement_day,
    ,
    drop = FALSE
  ]
  daily <- result$daily[
    result$daily$measurement_day == measurement_day,
    ,
    drop = FALSE
  ]
  cycle_tolerance_kj <- tail(
    result$convergence$realized_convergence_tolerance_kj,
    1L
  )
  gut_ledger_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj))
  )
  body_ledger_tolerance_kj <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )

  c(
    cycle_tolerance_kj = cycle_tolerance_kj,
    gut_ledger_tolerance_kj = gut_ledger_tolerance_kj,
    assimilation_total_tolerance_kj =
      cycle_tolerance_kj + gut_ledger_tolerance_kj,
    body_ledger_tolerance_kj = body_ledger_tolerance_kj,
    body_neutrality_tolerance_kj =
      cycle_tolerance_kj +
        gut_ledger_tolerance_kj +
        body_ledger_tolerance_kj
  )
}

test_that(
  "declared fixtures replay burn-in, reset body, and reduce to day runs",
  {
    fixtures <- .declared_reference_cycle_fixtures()

    for (scenario_id in names(fixtures)) {
      fixture <- fixtures[[scenario_id]]$runner_fixture
      result <- fixtures[[scenario_id]]$result
      expected_burn_in <- .expected_replayed_convergence(
        fixture$api,
        fixture$initial_gut_state,
        fixture$gut_parameters,
        fixture$schedule,
        fixture$relative_tolerance,
        nrow(result$convergence)
      )

      expect_identical(result$convergence, expected_burn_in$convergence)
      expect_identical(tail(result$convergence$converged, 1L), TRUE)
      expect_identical(
        result$hourly$gut_available_energy_start_kj[[1L]],
        tail(result$convergence$gut_available_energy_final_kj, 1L)
      )
      expect_identical(
        result$hourly$body_energy_reserve_start_kj[[1L]],
        fixture$measurement_body_state$body_energy_reserve_kj
      )
      expect_identical(
        result$hourly$gut_available_energy_start_kj[-1L],
        head(result$hourly$gut_available_energy_end_kj, -1L)
      )
      expect_identical(
        result$hourly$body_energy_reserve_start_kj[-1L],
        head(result$hourly$body_energy_reserve_end_kj, -1L)
      )

      opening_gut_state <- fixture$api$new_gut_state(
        tail(result$convergence$gut_available_energy_final_kj, 1L)
      )
      opening_body_state <- fixture$measurement_body_state
      for (measurement_day in 1:2) {
        direct <- fixture$api$run_day(
          opening_gut_state,
          opening_body_state,
          fixture$gut_parameters,
          fixture$body_parameters,
          fixture$schedule
        )
        measured_hourly <- .canonical_data_frame_rows(
          result$hourly[
            result$hourly$measurement_day == measurement_day,
            setdiff(names(result$hourly), "measurement_day"),
            drop = FALSE
          ]
        )
        measured_daily <- .canonical_data_frame_rows(
          result$daily[
            result$daily$measurement_day == measurement_day,
            setdiff(names(result$daily), "measurement_day"),
            drop = FALSE
          ]
        )

        expect_identical(measured_hourly, direct$hourly)
        expect_identical(measured_daily, direct$daily)

        opening_gut_state <- fixture$api$new_gut_state(
          direct$daily$gut_available_energy_final_kj[[1L]]
        )
        opening_body_state <- fixture$api$new_body_state(
          direct$daily$body_energy_reserve_final_kj[[1L]]
        )
      }
    }
  }
)

test_that(
  "declared fixtures separate zero deficit from neutral energy cycles",
  {
    fixtures <- .declared_reference_cycle_fixtures()
    expected_dry_matter_rates <- list(
      zero = rep(0, 24L),
      constant = rep(0.010, 24L),
      concentrated_late = c(rep(0, 18L), rep(0.040, 6L))
    )
    expected_energy_rates <- list(
      zero = rep(0, 24L),
      constant = rep(100, 24L),
      concentrated_late = c(rep(0, 18L), rep(400, 6L))
    )

    for (scenario_id in names(fixtures)) {
      fixture <- fixtures[[scenario_id]]
      convergence <- fixture$result$convergence
      comparison_rows <- seq.int(2L, nrow(convergence))
      body_stocks_kj <- c(
        fixture$result$hourly$body_energy_reserve_start_kj,
        fixture$result$hourly$body_energy_reserve_end_kj
      )

      expect_identical(
        fixture$dry_matter_schedule$
          prescribed_dry_matter_intake_kg_dm_h,
        expected_dry_matter_rates[[scenario_id]]
      )
      expect_identical(
        fixture$runner_fixture$schedule$
          prescribed_ingested_available_energy_kj_h,
        expected_energy_rates[[scenario_id]]
      )
      expect_true(all(is.finite(unlist(
        convergence[
          c(
            "gut_available_energy_initial_kj",
            "gut_available_energy_final_kj",
            "cycle_boundary_change_kj"
          )
        ],
        use.names = FALSE
      ))))
      expect_true(all(is.finite(
        convergence$
          max_abs_previous_day_trajectory_difference_kj[comparison_rows]
      )))
      expect_true(all(is.finite(
        convergence$realized_convergence_tolerance_kj[comparison_rows]
      )))
      expect_true(all(
        convergence$realized_convergence_tolerance_kj[comparison_rows] > 0
      ))
      expect_true(all(is.finite(body_stocks_kj)))
      expect_true(all(body_stocks_kj >= 0))
    }

    zero_result <- fixtures$zero$result
    zero_final_convergence <- tail(zero_result$convergence, 1L)
    expect_lte(
      abs(zero_final_convergence$cycle_boundary_change_kj),
      zero_final_convergence$realized_convergence_tolerance_kj
    )
    expect_lte(
      zero_final_convergence$
        max_abs_previous_day_trajectory_difference_kj,
      zero_final_convergence$realized_convergence_tolerance_kj
    )
    expect_identical(
      zero_result$daily$total_prescribed_ingested_available_energy_kj,
      rep(0, 2L)
    )
    expect_identical(
      zero_result$daily$total_assimilated_energy_kj,
      rep(0, 2L)
    )
    expect_identical(
      zero_result$daily$total_maintenance_expenditure_kj,
      rep(2400, 2L)
    )
    expect_identical(
      zero_result$daily$observed_body_energy_change_kj,
      rep(-2400, 2L)
    )

    for (scenario_id in c("constant", "concentrated_late")) {
      result <- fixtures[[scenario_id]]$result
      expect_identical(
        result$daily$total_prescribed_ingested_available_energy_kj,
        rep(2400, 2L)
      )
      expect_identical(
        result$daily$total_maintenance_expenditure_kj,
        rep(2400, 2L)
      )

      for (measurement_day in 1:2) {
        daily <- result$daily[
          result$daily$measurement_day == measurement_day,
          ,
          drop = FALSE
        ]
        tolerance <- .raw_reference_cycle_tolerances(
          result,
          measurement_day
        )

        expect_true(all(is.finite(tolerance)))
        expect_true(all(tolerance > 0))
        expect_lte(
          abs(daily$observed_gut_energy_change_kj),
          tolerance[["cycle_tolerance_kj"]]
        )
        expect_lte(
          abs(daily$gut_energy_balance_residual_kj),
          tolerance[["gut_ledger_tolerance_kj"]]
        )
        expect_lte(
          abs(
            daily$total_assimilated_energy_kj -
              daily$total_prescribed_ingested_available_energy_kj
          ),
          tolerance[["assimilation_total_tolerance_kj"]]
        )
        expect_lte(
          abs(daily$body_energy_balance_residual_kj),
          tolerance[["body_ledger_tolerance_kj"]]
        )
        expect_lte(
          abs(daily$observed_body_energy_change_kj),
          tolerance[["body_neutrality_tolerance_kj"]]
        )
      }
    }
  }
)

test_that(
  "energy-matched timing fixtures agree daily but differ hourly",
  {
    fixtures <- .declared_reference_cycle_fixtures()
    constant_result <- fixtures$constant$result
    concentrated_result <- fixtures$concentrated_late$result

    for (measurement_day in 1:2) {
      constant_daily <- constant_result$daily[
        constant_result$daily$measurement_day == measurement_day,
        ,
        drop = FALSE
      ]
      concentrated_daily <- concentrated_result$daily[
        concentrated_result$daily$measurement_day == measurement_day,
        ,
        drop = FALSE
      ]
      constant_tolerance <- .raw_reference_cycle_tolerances(
        constant_result,
        measurement_day
      )
      concentrated_tolerance <- .raw_reference_cycle_tolerances(
        concentrated_result,
        measurement_day
      )

      expect_identical(
        constant_daily$total_prescribed_ingested_available_energy_kj,
        concentrated_daily$total_prescribed_ingested_available_energy_kj
      )
      expect_identical(
        constant_daily$total_maintenance_expenditure_kj,
        concentrated_daily$total_maintenance_expenditure_kj
      )
      expect_lte(
        abs(
          constant_daily$total_assimilated_energy_kj -
            concentrated_daily$total_assimilated_energy_kj
        ),
        constant_tolerance[["assimilation_total_tolerance_kj"]] +
          concentrated_tolerance[["assimilation_total_tolerance_kj"]]
      )
      expect_lte(
        abs(
          constant_daily$observed_gut_energy_change_kj -
            concentrated_daily$observed_gut_energy_change_kj
        ),
        constant_tolerance[["cycle_tolerance_kj"]] +
          concentrated_tolerance[["cycle_tolerance_kj"]]
      )
      expect_lte(
        abs(
          constant_daily$observed_body_energy_change_kj -
            concentrated_daily$observed_body_energy_change_kj
        ),
        constant_tolerance[["body_neutrality_tolerance_kj"]] +
          concentrated_tolerance[["body_neutrality_tolerance_kj"]]
      )

      constant_hourly <- constant_result$hourly[
        constant_result$hourly$measurement_day == measurement_day,
        ,
        drop = FALSE
      ]
      concentrated_hourly <- concentrated_result$hourly[
        concentrated_result$hourly$measurement_day == measurement_day,
        ,
        drop = FALSE
      ]
      constant_gut_boundaries_kj <- c(
        constant_hourly$gut_available_energy_start_kj[[1L]],
        constant_hourly$gut_available_energy_end_kj
      )
      concentrated_gut_boundaries_kj <- c(
        concentrated_hourly$gut_available_energy_start_kj[[1L]],
        concentrated_hourly$gut_available_energy_end_kj
      )
      constant_body_boundaries_kj <- c(
        constant_hourly$body_energy_reserve_start_kj[[1L]],
        constant_hourly$body_energy_reserve_end_kj
      )
      concentrated_body_boundaries_kj <- c(
        concentrated_hourly$body_energy_reserve_start_kj[[1L]],
        concentrated_hourly$body_energy_reserve_end_kj
      )

      expect_gt(
        max(abs(
          constant_gut_boundaries_kj -
            concentrated_gut_boundaries_kj
        )),
        constant_tolerance[["cycle_tolerance_kj"]] +
          concentrated_tolerance[["cycle_tolerance_kj"]]
      )
      expect_gt(
        max(abs(
          constant_hourly$assimilated_energy_kj -
            concentrated_hourly$assimilated_energy_kj
        )),
        constant_tolerance[["assimilation_total_tolerance_kj"]] +
          concentrated_tolerance[["assimilation_total_tolerance_kj"]]
      )
      expect_gt(
        max(abs(
          constant_body_boundaries_kj -
            concentrated_body_boundaries_kj
        )),
        constant_tolerance[["body_neutrality_tolerance_kj"]] +
          concentrated_tolerance[["body_neutrality_tolerance_kj"]]
      )
    }
  }
)
