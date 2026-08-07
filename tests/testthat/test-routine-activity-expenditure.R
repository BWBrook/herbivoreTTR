.routine_activity_api <- function() {
  list(
    new_activity_schedule = getExportedValue(
      "herbivoreTTR",
      "new_routine_activity_expenditure_schedule"
    ),
    new_assimilated_schedule = getExportedValue(
      "herbivoreTTR",
      "new_assimilated_energy_schedule"
    ),
    new_ingested_schedule = getExportedValue(
      "herbivoreTTR",
      "new_ingested_available_energy_schedule"
    ),
    new_body_state = getExportedValue(
      "herbivoreTTR",
      "new_body_energy_state"
    ),
    new_body_parameters = getExportedValue(
      "herbivoreTTR",
      "new_body_energy_parameters"
    ),
    new_gut_state = getExportedValue(
      "herbivoreTTR",
      "new_gut_energy_state"
    ),
    new_gut_parameters = getExportedValue(
      "herbivoreTTR",
      "new_gut_energy_parameters"
    ),
    step_body = getExportedValue("herbivoreTTR", "step_body_energy"),
    run_body = getExportedValue("herbivoreTTR", "run_body_energy_day"),
    run_gut_body = getExportedValue(
      "herbivoreTTR",
      "run_gut_body_energy_day"
    ),
    run_reference = getExportedValue(
      "herbivoreTTR",
      "run_gut_body_energy_reference_cycle"
    )
  )
}

.routine_activity_copy <- function(value) {
  unserialize(serialize(value, connection = NULL))
}

.routine_activity_zero_schedule <- function(api) {
  api$new_activity_schedule(0:23, rep(0, 24L))
}

.routine_activity_pulse_schedule <- function(api) {
  api$new_activity_schedule(
    0:23,
    c(rep(0, 8L), rep(50, 4L), rep(0, 12L))
  )
}

test_that("routine-activity constructor returns the canonical schedule", {
  api <- .routine_activity_api()
  hour_of_day <- 0:23
  rates <- c(rep(0L, 8L), rep(50L, 4L), rep(0L, 12L))
  hour_before <- .routine_activity_copy(hour_of_day)
  rates_before <- .routine_activity_copy(rates)

  expect_identical(
    names(formals(api$new_activity_schedule)),
    c(
      "hour_of_day",
      "prescribed_routine_activity_expenditure_kj_h"
    )
  )

  schedule <- api$new_activity_schedule(hour_of_day, rates)

  expect_identical(class(schedule), "data.frame")
  expect_identical(dim(schedule), c(24L, 2L))
  expect_identical(
    names(schedule),
    c(
      "hour_of_day",
      "prescribed_routine_activity_expenditure_kj_h"
    )
  )
  expect_identical(schedule$hour_of_day, 0:23)
  expect_type(
    schedule$prescribed_routine_activity_expenditure_kj_h,
    "double"
  )
  expect_identical(
    schedule$prescribed_routine_activity_expenditure_kj_h,
    c(rep(0, 8L), rep(50, 4L), rep(0, 12L))
  )
  expect_null(attributes(schedule$hour_of_day))
  expect_null(attributes(
    schedule$prescribed_routine_activity_expenditure_kj_h
  ))
  expect_identical(hour_of_day, hour_before)
  expect_identical(rates, rates_before)
})

test_that("routine-activity constructor accepts numeric storage and metadata", {
  api <- .routine_activity_api()
  hours <- structure(
    as.double(0:23),
    names = paste0("h", 0:23),
    source = "test"
  )
  rates <- structure(
    rep(50L, 24L),
    class = "activity_rate",
    source = "test"
  )

  schedule <- api$new_activity_schedule(hours, rates)

  expect_identical(schedule$hour_of_day, 0:23)
  expect_identical(
    schedule$prescribed_routine_activity_expenditure_kj_h,
    rep(50, 24L)
  )
  expect_null(attributes(schedule$hour_of_day))
  expect_null(attributes(
    schedule$prescribed_routine_activity_expenditure_kj_h
  ))
})

test_that("routine-activity constructor rejects every malformed field", {
  api <- .routine_activity_api()
  valid_hours <- 0:23
  valid_rates <- rep(0, 24L)
  invalid_hours <- list(
    1:24,
    rev(0:23),
    c(0:22, 22L),
    c(as.double(0:22), 23.5),
    as.character(0:23),
    rep(TRUE, 24L),
    as.complex(0:23),
    factor(0:23),
    matrix(0:23, nrow = 1L)
  )
  invalid_rates <- list(
    numeric(),
    rep(0, 23L),
    rep(0, 25L),
    c(rep(0, 23L), -1),
    c(rep(0, 23L), Inf),
    c(rep(0, 23L), NA_real_),
    rep("0", 24L),
    rep(TRUE, 24L),
    rep(0 + 0i, 24L),
    factor(rep("0", 24L)),
    matrix(rep(0, 24L))
  )

  for (hour_of_day in invalid_hours) {
    expect_error(
      api$new_activity_schedule(hour_of_day, valid_rates),
      "`hour_of_day`"
    )
  }
  for (rates in invalid_rates) {
    expect_error(
      api$new_activity_schedule(valid_hours, rates),
      "`prescribed_routine_activity_expenditure_kj_h`"
    )
  }

  error <- expect_error(
    api$new_activity_schedule(
      c(as.double(0:22), 23.5),
      valid_rates
    ),
    "`hour_of_day`"
  )
  expect_null(conditionCall(error))
})

test_that("routine-activity validators accept semantic containers and rows", {
  validate_schedule <- getFromNamespace(
    ".validate_routine_activity_expenditure_schedule",
    "herbivoreTTR"
  )
  validate_row <- getFromNamespace(
    ".validate_routine_activity_expenditure_input_row",
    "herbivoreTTR"
  )
  schedule <- data.frame(
    hour_of_day = as.double(0:23),
    prescribed_routine_activity_expenditure_kj_h = rep(50L, 24L),
    row.names = paste0("h", 0:23)
  )
  class(schedule) <- c("annotated_activity_schedule", "data.frame")
  attr(schedule, "source") <- "test"
  schedule <- schedule[c(
    "prescribed_routine_activity_expenditure_kj_h",
    "hour_of_day"
  )]
  activity_row <- schedule[1L, , drop = FALSE]
  attr(activity_row, "source") <- "test-row"

  expect_invisible(validate_schedule(schedule))
  expect_invisible(validate_row(activity_row))

  error <- expect_error(
    validate_schedule(schedule[-24L, , drop = FALSE]),
    "`routine_activity_schedule`"
  )
  expect_null(conditionCall(error))
  activity_row$prescribed_routine_activity_expenditure_kj_h <- factor("50")
  error <- expect_error(
    validate_row(activity_row),
    "`activity_row\\$prescribed_routine_activity_expenditure_kj_h`"
  )
  expect_null(conditionCall(error))
})

test_that("every body transition and runner requires explicit activity", {
  api <- .routine_activity_api()

  expect_identical(
    names(formals(api$step_body)),
    c("state", "parameters", "input_row", "activity_row")
  )
  expect_identical(
    names(formals(api$run_body)),
    c(
      "initial_state",
      "parameters",
      "schedule",
      "routine_activity_schedule"
    )
  )
  expect_identical(
    names(formals(api$run_gut_body)),
    c(
      "initial_gut_state",
      "initial_body_state",
      "gut_parameters",
      "body_parameters",
      "schedule",
      "routine_activity_schedule"
    )
  )
  expect_identical(
    names(formals(api$run_reference)),
    c(
      "initial_gut_state",
      "measurement_body_state",
      "gut_parameters",
      "body_parameters",
      "schedule",
      "routine_activity_schedule",
      "gut_convergence_relative_tolerance",
      "max_burn_in_days"
    )
  )

  body_state <- api$new_body_state(10000)
  body_parameters <- api$new_body_parameters(100)
  assimilated_schedule <- api$new_assimilated_schedule(0:23, rep(100, 24L))
  gut_state <- api$new_gut_state(400)
  gut_parameters <- api$new_gut_parameters(0.25)
  ingested_schedule <- api$new_ingested_schedule(0:23, rep(100, 24L))

  expect_error(api$step_body(
    body_state,
    body_parameters,
    assimilated_schedule[1L, , drop = FALSE]
  ))
  expect_error(api$run_body(
    body_state,
    body_parameters,
    assimilated_schedule
  ))
  expect_error(api$run_gut_body(
    gut_state,
    body_state,
    gut_parameters,
    body_parameters,
    ingested_schedule
  ))
  expect_error(api$run_reference(
    gut_state,
    body_state,
    gut_parameters,
    body_parameters,
    ingested_schedule,
    100 * .Machine$double.eps,
    100L
  ))
})

test_that("body transition applies the matched one-hour activity amount", {
  api <- .routine_activity_api()
  state <- api$new_body_state(1000)
  parameters <- api$new_body_parameters(100)
  input_schedule <- api$new_assimilated_schedule(0:23, rep(100, 24L))
  activity_schedule <- .routine_activity_pulse_schedule(api)
  input_row <- input_schedule[9L, , drop = FALSE]
  activity_row <- activity_schedule[9L, , drop = FALSE]
  before <- .routine_activity_copy(list(
    state,
    parameters,
    input_row,
    activity_row
  ))

  result <- api$step_body(state, parameters, input_row, activity_row)

  expect_identical(
    names(result$fluxes),
    c(
      "prescribed_assimilated_energy_kj",
      "maintenance_expenditure_kj",
      "prescribed_routine_activity_expenditure_kj",
      "net_body_energy_rate_kj_h",
      "body_energy_change_kj",
      "energy_balance_residual_kj"
    )
  )
  expect_identical(
    result$fluxes$prescribed_routine_activity_expenditure_kj,
    50
  )
  expect_identical(result$fluxes$net_body_energy_rate_kj_h, -50)
  expect_identical(result$fluxes$body_energy_change_kj, -50)
  expect_identical(result$state$body_energy_reserve_kj, 950)
  expect_identical(
    list(state, parameters, input_row, activity_row),
    before
  )

  expect_error(api$step_body(
    state,
    parameters,
    input_row,
    activity_schedule[8L, , drop = FALSE]
  ))
  expect_error(api$step_body(
    state,
    parameters,
    input_row,
    activity_schedule[0, , drop = FALSE]
  ))
  expect_error(
    api$step_body(
      api$new_body_state(49),
      parameters,
      input_row,
      activity_row
    ),
    "negative"
  )
})

test_that("body day records exact zero and four-hour pulse accounting", {
  api <- .routine_activity_api()
  initial_state <- api$new_body_state(10000)
  parameters <- api$new_body_parameters(100)
  input_schedule <- api$new_assimilated_schedule(0:23, rep(100, 24L))
  zero_schedule <- .routine_activity_zero_schedule(api)
  pulse_schedule <- .routine_activity_pulse_schedule(api)

  zero <- api$run_body(
    initial_state,
    parameters,
    input_schedule,
    zero_schedule
  )
  pulse <- api$run_body(
    initial_state,
    parameters,
    input_schedule,
    pulse_schedule
  )
  semantic_pulse_schedule <- data.frame(
    prescribed_routine_activity_expenditure_kj_h = c(
      rep(0L, 8L),
      rep(50L, 4L),
      rep(0L, 12L)
    ),
    hour_of_day = as.double(0:23),
    row.names = paste0("h", 0:23)
  )
  class(semantic_pulse_schedule) <- c(
    "annotated_activity_schedule",
    "data.frame"
  )
  attr(semantic_pulse_schedule, "source") <- "semantic-test"
  semantic_pulse <- api$run_body(
    initial_state,
    parameters,
    input_schedule,
    semantic_pulse_schedule
  )

  expect_identical(semantic_pulse, pulse)
  expect_identical(
    pulse$hourly$prescribed_routine_activity_expenditure_kj_h,
    c(rep(0, 8L), rep(50, 4L), rep(0, 12L))
  )
  expect_identical(
    pulse$hourly$prescribed_routine_activity_expenditure_kj,
    c(rep(0, 8L), rep(50, 4L), rep(0, 12L))
  )
  expect_identical(
    pulse$hourly$net_body_energy_rate_kj_h -
      zero$hourly$net_body_energy_rate_kj_h,
    c(rep(0, 8L), rep(-50, 4L), rep(0, 12L))
  )
  expect_identical(
    pulse$hourly$body_energy_change_kj -
      zero$hourly$body_energy_change_kj,
    c(rep(0, 8L), rep(-50, 4L), rep(0, 12L))
  )
  expect_identical(
    pulse$daily$total_prescribed_routine_activity_expenditure_kj,
    200
  )
  expect_identical(pulse$daily$expected_body_energy_change_kj, -200)
  expect_identical(pulse$daily$observed_body_energy_change_kj, -200)
  expect_identical(pulse$daily$body_energy_reserve_final_kj, 9800)
  expect_identical(
    pulse$hourly$body_energy_reserve_start_kj[[9L]],
    10000
  )
  expect_identical(
    pulse$hourly$body_energy_reserve_end_kj[[12L]],
    9800
  )
  expect_identical(
    pulse$hourly$body_energy_reserve_end_kj[12:24],
    rep(9800, 13L)
  )

  shared_hourly <- setdiff(
    names(zero$hourly),
    c(
      "prescribed_routine_activity_expenditure_kj_h",
      "prescribed_routine_activity_expenditure_kj"
    )
  )
  expected_shared_hourly <- data.frame(
    hour_of_day = 0:23,
    time_start_h = as.numeric(0:23),
    time_end_h = as.numeric(1:24),
    body_energy_reserve_start_kj = rep(10000, 24L),
    prescribed_assimilated_energy_kj_h = rep(100, 24L),
    maintenance_expenditure_kj_h = rep(100, 24L),
    net_body_energy_rate_kj_h = rep(0, 24L),
    prescribed_assimilated_energy_kj = rep(100, 24L),
    maintenance_expenditure_kj = rep(100, 24L),
    body_energy_change_kj = rep(0, 24L),
    body_energy_reserve_end_kj = rep(10000, 24L),
    energy_balance_residual_kj = rep(0, 24L)
  )
  expect_identical(
    zero$hourly[shared_hourly],
    expected_shared_hourly
  )
  shared_daily <- setdiff(
    names(zero$daily),
    "total_prescribed_routine_activity_expenditure_kj"
  )
  expected_shared_daily <- data.frame(
    body_energy_reserve_initial_kj = 10000,
    total_prescribed_assimilated_energy_kj = 2400,
    total_maintenance_expenditure_kj = 2400,
    expected_body_energy_change_kj = 0,
    observed_body_energy_change_kj = 0,
    body_energy_reserve_final_kj = 10000,
    energy_balance_residual_kj = 0,
    energy_status = "neutral"
  )
  expect_identical(zero$daily[shared_daily], expected_shared_daily)
  expect_identical(
    zero$daily$total_prescribed_routine_activity_expenditure_kj,
    0
  )
  expect_identical(zero$daily$body_energy_reserve_final_kj, 10000)
})

test_that("coupled pulse changes only body and whole-system accounting", {
  api <- .routine_activity_api()
  initial_gut_state <- api$new_gut_state(400)
  initial_body_state <- api$new_body_state(10000)
  gut_parameters <- api$new_gut_parameters(0.25)
  body_parameters <- api$new_body_parameters(100)
  ingestion_schedule <- api$new_ingested_schedule(0:23, rep(100, 24L))
  zero_schedule <- .routine_activity_zero_schedule(api)
  pulse_schedule <- .routine_activity_pulse_schedule(api)

  zero <- api$run_gut_body(
    initial_gut_state,
    initial_body_state,
    gut_parameters,
    body_parameters,
    ingestion_schedule,
    zero_schedule
  )
  pulse <- api$run_gut_body(
    initial_gut_state,
    initial_body_state,
    gut_parameters,
    body_parameters,
    ingestion_schedule,
    pulse_schedule
  )

  gut_columns <- c(
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
  expect_identical(pulse$hourly[gut_columns], zero$hourly[gut_columns])
  expect_identical(
    pulse$hourly$net_body_energy_rate_kj_h -
      zero$hourly$net_body_energy_rate_kj_h,
    c(rep(0, 8L), rep(-50, 4L), rep(0, 12L))
  )
  expect_identical(
    pulse$daily$total_prescribed_routine_activity_expenditure_kj,
    200
  )
  expect_identical(
    pulse$daily$observed_body_energy_change_kj -
      zero$daily$observed_body_energy_change_kj,
    -200
  )
  expect_identical(
    pulse$daily$observed_total_system_energy_change_kj -
      zero$daily$observed_total_system_energy_change_kj,
    -200
  )
  expect_identical(pulse$daily$body_energy_reserve_final_kj, 9800)
  expect_identical(pulse$daily$body_energy_status, "deficit")
})

test_that("reference pulse preserves burn-in and carries exact body loss", {
  api <- .routine_activity_api()
  run_scenario <- function(activity_schedule) {
    api$run_reference(
      api$new_gut_state(0),
      api$new_body_state(10000),
      api$new_gut_parameters(0.25),
      api$new_body_parameters(100),
      api$new_ingested_schedule(0:23, rep(100, 24L)),
      activity_schedule,
      100 * .Machine$double.eps,
      100L
    )
  }

  zero <- run_scenario(.routine_activity_zero_schedule(api))
  pulse <- run_scenario(.routine_activity_pulse_schedule(api))

  expect_identical(pulse$convergence, zero$convergence)
  expect_identical(nrow(pulse$convergence), 7L)
  expect_identical(tail(pulse$convergence$converged, 1L), TRUE)
  gut_columns <- c(
    "measurement_day",
    "hour_of_day",
    "gut_available_energy_start_kj",
    "prescribed_ingested_available_energy_kj_h",
    "assimilated_energy_kj_h",
    "prescribed_ingested_available_energy_kj",
    "assimilated_energy_kj",
    "gut_energy_change_kj",
    "gut_available_energy_end_kj",
    "gut_energy_balance_residual_kj"
  )
  expect_identical(pulse$hourly[gut_columns], zero$hourly[gut_columns])
  expect_identical(
    pulse$daily$total_prescribed_routine_activity_expenditure_kj,
    c(200, 200)
  )
  expect_identical(
    pulse$daily$observed_body_energy_change_kj -
      zero$daily$observed_body_energy_change_kj,
    c(-200, -200)
  )
  expect_identical(
    pulse$daily$body_energy_reserve_final_kj -
      zero$daily$body_energy_reserve_final_kj,
    c(-200, -400)
  )
  expect_identical(
    pulse$daily$body_energy_reserve_final_kj,
    c(9800, 9600)
  )
  expect_identical(
    pulse$hourly$body_energy_reserve_start_kj[[25L]],
    pulse$hourly$body_energy_reserve_end_kj[[24L]]
  )
  expect_identical(
    pulse$hourly$body_energy_reserve_start_kj[c(9L, 33L)],
    c(10000, 9800)
  )
  expect_identical(
    pulse$hourly$body_energy_reserve_end_kj[c(12L, 36L)],
    c(9800, 9600)
  )
})

test_that("activity is included in body and whole-system tolerance scales", {
  body_tolerance <- getFromNamespace(
    ".body_energy_tolerance",
    "herbivoreTTR"
  )
  hourly_system_tolerance <- getFromNamespace(
    ".gut_body_hourly_system_tolerance",
    "herbivoreTTR"
  )
  daily_system_tolerance <- getFromNamespace(
    ".gut_body_daily_system_tolerance",
    "herbivoreTTR"
  )
  scale_factor <- 100 * .Machine$double.eps

  expect_identical(
    body_tolerance(1, 1, 1, 1, 1e6),
    scale_factor * 1e6
  )
  expect_identical(
    hourly_system_tolerance(1, 1, 1, 1, 1, 1, 1, 1e6),
    scale_factor * 1e6
  )
  expect_identical(
    daily_system_tolerance(
      1,
      1,
      1,
      1,
      rep(1, 24L),
      rep(1, 24L),
      rep(1, 24L),
      rep(1e6, 24L)
    ),
    scale_factor * 24e6
  )
})
