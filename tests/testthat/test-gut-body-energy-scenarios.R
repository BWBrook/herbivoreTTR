.gut_body_energy_api <- function() {
  list(
    run = getFromNamespace("run_gut_body_energy_day", "herbivoreTTR"),
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

.run_gut_body_energy_fixture <- function(
  gut_energy_kj = 400,
  body_energy_kj = 5000,
  release_fraction_h = 0.25,
  ingestion_rates_kj_h = rep(100, 24L),
  maintenance_kj_h = 100
) {
  api <- .gut_body_energy_api()
  initial_gut_state <- api$new_gut_state(gut_energy_kj)
  initial_body_state <- api$new_body_state(body_energy_kj)
  gut_parameters <- api$new_gut_parameters(release_fraction_h)
  body_parameters <- api$new_body_parameters(maintenance_kj_h)
  schedule <- api$new_schedule(0:23, ingestion_rates_kj_h)

  list(
    api = api,
    initial_gut_state = initial_gut_state,
    initial_body_state = initial_body_state,
    gut_parameters = gut_parameters,
    body_parameters = body_parameters,
    schedule = schedule,
    result = api$run(
      initial_gut_state,
      initial_body_state,
      gut_parameters,
      body_parameters,
      schedule
    )
  )
}

.gut_body_energy_copy <- function(x) {
  unserialize(serialize(x, connection = NULL))
}

.hourly_gut_body_energy_columns <- c(
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

.daily_gut_body_energy_columns <- c(
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

.hourly_gut_tolerance <- function(hourly) {
  mapply(
    function(gut_start, gut_end, ingested, assimilated) {
      100 * .Machine$double.eps * max(
        1,
        abs(gut_start),
        abs(gut_end),
        abs(ingested),
        abs(assimilated)
      )
    },
    hourly$gut_available_energy_start_kj,
    hourly$gut_available_energy_end_kj,
    hourly$prescribed_ingested_available_energy_kj,
    hourly$assimilated_energy_kj
  )
}

.hourly_body_tolerance <- function(hourly) {
  mapply(
    function(body_start, body_end, assimilated, maintenance) {
      100 * .Machine$double.eps * max(
        1,
        abs(body_start),
        abs(body_end),
        abs(assimilated),
        abs(maintenance)
      )
    },
    hourly$body_energy_reserve_start_kj,
    hourly$body_energy_reserve_end_kj,
    hourly$assimilated_energy_kj,
    hourly$maintenance_expenditure_kj
  )
}

.hourly_system_tolerance <- function(hourly) {
  mapply(
    function(
      gut_start,
      gut_end,
      body_start,
      body_end,
      ingested,
      assimilated,
      maintenance
    ) {
      100 * .Machine$double.eps * max(
        1,
        abs(gut_start),
        abs(gut_end),
        abs(body_start),
        abs(body_end),
        abs(ingested),
        abs(assimilated),
        abs(maintenance)
      )
    },
    hourly$gut_available_energy_start_kj,
    hourly$gut_available_energy_end_kj,
    hourly$body_energy_reserve_start_kj,
    hourly$body_energy_reserve_end_kj,
    hourly$prescribed_ingested_available_energy_kj,
    hourly$assimilated_energy_kj,
    hourly$maintenance_expenditure_kj
  )
}

test_that("coupled runner returns exact schemas on the half-open clock", {
  fixture <- .run_gut_body_energy_fixture()
  result <- fixture$result

  expect_identical(
    names(formals(fixture$api$run)),
    c(
      "initial_gut_state",
      "initial_body_state",
      "gut_parameters",
      "body_parameters",
      "schedule"
    )
  )
  expect_type(result, "list")
  expect_false(is.object(result))
  expect_identical(names(result), c("hourly", "daily"))
  expect_identical(class(result$hourly), "data.frame")
  expect_identical(dim(result$hourly), c(24L, 21L))
  expect_identical(
    names(result$hourly),
    .hourly_gut_body_energy_columns
  )
  expect_identical(class(result$daily), "data.frame")
  expect_identical(dim(result$daily), c(1L, 19L))
  expect_identical(names(result$daily), .daily_gut_body_energy_columns)
  expect_identical(result$hourly$hour_of_day, 0:23)
  expect_identical(result$hourly$time_start_h, as.numeric(0:23))
  expect_identical(result$hourly$time_end_h, as.numeric(1:24))
  expect_true(all(vapply(result$hourly[-1L], is.double, logical(1))))
  expect_true(all(vapply(result$daily[-19L], is.double, logical(1))))
  expect_type(result$daily$body_energy_status, "character")
})

test_that("coupled runner preserves continuity and exact row identities", {
  hourly <- .run_gut_body_energy_fixture(
    gut_energy_kj = 125,
    ingestion_rates_kj_h = 60 + as.numeric(0:23),
    maintenance_kj_h = 80
  )$result$hourly

  expect_identical(
    hourly$gut_available_energy_start_kj[-1L],
    hourly$gut_available_energy_end_kj[-24L]
  )
  expect_identical(
    hourly$body_energy_reserve_start_kj[-1L],
    hourly$body_energy_reserve_end_kj[-24L]
  )
  expect_identical(
    hourly$prescribed_ingested_available_energy_kj,
    hourly$prescribed_ingested_available_energy_kj_h
  )
  expect_identical(
    hourly$assimilated_energy_kj,
    hourly$assimilated_energy_kj_h
  )
  expect_identical(
    hourly$maintenance_expenditure_kj,
    hourly$maintenance_expenditure_kj_h
  )
  expect_identical(
    hourly$total_system_energy_start_kj,
    hourly$gut_available_energy_start_kj +
      hourly$body_energy_reserve_start_kj
  )
  expect_identical(
    hourly$total_system_energy_end_kj,
    hourly$gut_available_energy_end_kj +
      hourly$body_energy_reserve_end_kj
  )
})

test_that("hourly gut, body, and whole-system balances close to policy", {
  hourly <- .run_gut_body_energy_fixture(
    gut_energy_kj = 125,
    ingestion_rates_kj_h = 60 + as.numeric(0:23),
    maintenance_kj_h = 80
  )$result$hourly
  calculated_gut_residual <- (
    hourly$gut_available_energy_end_kj -
      hourly$gut_available_energy_start_kj
  ) - (
    hourly$prescribed_ingested_available_energy_kj -
      hourly$assimilated_energy_kj
  )
  calculated_body_residual <- (
    hourly$body_energy_reserve_end_kj -
      hourly$body_energy_reserve_start_kj
  ) - (
    hourly$assimilated_energy_kj -
      hourly$maintenance_expenditure_kj
  )
  calculated_system_residual <- (
    hourly$total_system_energy_end_kj -
      hourly$total_system_energy_start_kj
  ) - (
    hourly$prescribed_ingested_available_energy_kj -
      hourly$maintenance_expenditure_kj
  )

  expect_identical(
    hourly$gut_energy_balance_residual_kj,
    calculated_gut_residual
  )
  expect_identical(
    hourly$body_energy_balance_residual_kj,
    calculated_body_residual
  )
  expect_identical(
    hourly$system_energy_balance_residual_kj,
    calculated_system_residual
  )
  expect_true(all(
    abs(hourly$gut_energy_balance_residual_kj) <=
      .hourly_gut_tolerance(hourly)
  ))
  expect_true(all(
    abs(hourly$body_energy_balance_residual_kj) <=
      .hourly_body_tolerance(hourly)
  ))
  expect_true(all(
    abs(hourly$system_energy_balance_residual_kj) <=
      .hourly_system_tolerance(hourly)
  ))
})

test_that("daily summary is derived exactly from the hourly ledger", {
  result <- .run_gut_body_energy_fixture(
    gut_energy_kj = 125,
    ingestion_rates_kj_h = 60 + as.numeric(0:23),
    maintenance_kj_h = 80
  )$result
  hourly <- result$hourly
  daily <- result$daily
  total_ingested <- sum(hourly$prescribed_ingested_available_energy_kj)
  total_assimilated <- sum(hourly$assimilated_energy_kj)
  total_maintenance <- sum(hourly$maintenance_expenditure_kj)
  observed_gut_change <- tail(
    hourly$gut_available_energy_end_kj,
    1L
  ) - hourly$gut_available_energy_start_kj[[1L]]
  observed_body_change <- tail(
    hourly$body_energy_reserve_end_kj,
    1L
  ) - hourly$body_energy_reserve_start_kj[[1L]]

  expect_identical(
    daily$gut_available_energy_initial_kj,
    hourly$gut_available_energy_start_kj[[1L]]
  )
  expect_identical(
    daily$total_prescribed_ingested_available_energy_kj,
    total_ingested
  )
  expect_identical(daily$total_assimilated_energy_kj, total_assimilated)
  expect_identical(
    daily$expected_gut_energy_change_kj,
    total_ingested - total_assimilated
  )
  expect_identical(
    daily$observed_gut_energy_change_kj,
    observed_gut_change
  )
  expect_identical(
    daily$gut_available_energy_final_kj,
    tail(hourly$gut_available_energy_end_kj, 1L)
  )
  expect_identical(
    daily$gut_energy_balance_residual_kj,
    observed_gut_change - (total_ingested - total_assimilated)
  )
  expect_identical(
    daily$body_energy_reserve_initial_kj,
    hourly$body_energy_reserve_start_kj[[1L]]
  )
  expect_identical(
    daily$total_maintenance_expenditure_kj,
    total_maintenance
  )
  expect_identical(
    daily$expected_body_energy_change_kj,
    total_assimilated - total_maintenance
  )
  expect_identical(
    daily$observed_body_energy_change_kj,
    observed_body_change
  )
  expect_identical(
    daily$body_energy_reserve_final_kj,
    tail(hourly$body_energy_reserve_end_kj, 1L)
  )
  expect_identical(
    daily$body_energy_balance_residual_kj,
    observed_body_change - (total_assimilated - total_maintenance)
  )
  expect_identical(
    daily$total_system_energy_initial_kj,
    hourly$total_system_energy_start_kj[[1L]]
  )
  expect_identical(
    daily$expected_total_system_energy_change_kj,
    total_ingested - total_maintenance
  )
  expect_identical(
    daily$observed_total_system_energy_change_kj,
    tail(hourly$total_system_energy_end_kj, 1L) -
      hourly$total_system_energy_start_kj[[1L]]
  )
  expect_identical(
    daily$total_system_energy_final_kj,
    tail(hourly$total_system_energy_end_kj, 1L)
  )
  expect_identical(
    daily$system_energy_balance_residual_kj,
    daily$observed_total_system_energy_change_kj -
      daily$expected_total_system_energy_change_kj
  )
})

test_that("daily gut, body, and whole-system residuals close to policy", {
  result <- .run_gut_body_energy_fixture(
    gut_energy_kj = 125,
    ingestion_rates_kj_h = 60 + as.numeric(0:23),
    maintenance_kj_h = 80
  )$result
  hourly <- result$hourly
  daily <- result$daily
  gut_tolerance <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj))
  )
  body_tolerance <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )
  system_tolerance <- 100 * .Machine$double.eps * max(
    1,
    abs(daily$gut_available_energy_initial_kj),
    abs(daily$gut_available_energy_final_kj),
    abs(daily$body_energy_reserve_initial_kj),
    abs(daily$body_energy_reserve_final_kj),
    sum(abs(hourly$prescribed_ingested_available_energy_kj)),
    sum(abs(hourly$assimilated_energy_kj)),
    sum(abs(hourly$maintenance_expenditure_kj))
  )

  expect_lte(abs(daily$gut_energy_balance_residual_kj), gut_tolerance)
  expect_lte(abs(daily$body_energy_balance_residual_kj), body_tolerance)
  expect_lte(abs(daily$system_energy_balance_residual_kj), system_tolerance)
})

test_that("equilibrium reference remains exactly neutral for all 24 hours", {
  result <- .run_gut_body_energy_fixture()$result

  expect_identical(
    result$hourly$gut_available_energy_start_kj,
    rep(400, 24L)
  )
  expect_identical(
    result$hourly$gut_available_energy_end_kj,
    rep(400, 24L)
  )
  expect_identical(result$hourly$assimilated_energy_kj, rep(100, 24L))
  expect_identical(
    result$hourly$body_energy_reserve_start_kj,
    rep(5000, 24L)
  )
  expect_identical(
    result$hourly$body_energy_reserve_end_kj,
    rep(5000, 24L)
  )
  expect_identical(result$daily$body_energy_status, "neutral")
  expect_identical(
    unlist(result$daily[c(
      "gut_energy_balance_residual_kj",
      "body_energy_balance_residual_kj",
      "system_energy_balance_residual_kj"
    )], use.names = FALSE),
    rep(0, 3L)
  )
})

test_that("empty gut follows the exact recurrence and conserves the system", {
  result <- .run_gut_body_energy_fixture(gut_energy_kj = 0)$result
  expected_gut_end <- 400 * (1 - 0.75^(1:24))
  expected_gut_final <- 400 * (1 - 0.75^24)
  expected_body_final <- 5000 - expected_gut_final

  expect_equal(
    result$hourly$gut_available_energy_end_kj,
    expected_gut_end,
    tolerance = 1e-12
  )
  expect_equal(
    result$daily$gut_available_energy_final_kj,
    399.598643488979,
    tolerance = 1e-12
  )
  expect_equal(
    result$daily$gut_available_energy_final_kj,
    expected_gut_final,
    tolerance = 1e-12
  )
  expect_equal(
    result$daily$body_energy_reserve_final_kj,
    4600.401356511022,
    tolerance = 1e-12
  )
  expect_equal(
    result$daily$body_energy_reserve_final_kj,
    expected_body_final,
    tolerance = 1e-12
  )
  expect_equal(
    result$hourly$total_system_energy_end_kj,
    rep(5000, 24L),
    tolerance = 1e-12
  )
  expect_identical(result$daily$body_energy_status, "deficit")
})

test_that("single pulse is delayed then released geometrically", {
  result <- .run_gut_body_energy_fixture(
    gut_energy_kj = 0,
    ingestion_rates_kj_h = c(400, rep(0, 23L)),
    maintenance_kj_h = 0
  )$result

  expect_identical(
    result$hourly$assimilated_energy_kj_h[1:4],
    c(0, 100, 75, 56.25)
  )
  expect_identical(result$hourly$gut_available_energy_end_kj[[1L]], 400)
  expect_equal(
    result$hourly$total_system_energy_end_kj,
    rep(5400, 24L),
    tolerance = 1e-12
  )
  expect_identical(result$daily$total_system_energy_initial_kj, 5000)
  expect_identical(
    result$daily$expected_total_system_energy_change_kj,
    400
  )
  expect_equal(
    result$daily$total_system_energy_final_kj,
    5400,
    tolerance = 1e-12
  )
  expect_identical(result$daily$body_energy_status, "surplus")
})

test_that("body status reuses the scale-aware Goal 002 tolerance", {
  nominal_tolerance <- 100 * .Machine$double.eps * 5000
  neutral <- .run_gut_body_energy_fixture(
    gut_energy_kj = nominal_tolerance / 2,
    release_fraction_h = 1,
    ingestion_rates_kj_h = rep(0, 24L),
    maintenance_kj_h = 0
  )$result$daily
  surplus <- .run_gut_body_energy_fixture(
    gut_energy_kj = nominal_tolerance * 4,
    release_fraction_h = 1,
    ingestion_rates_kj_h = rep(0, 24L),
    maintenance_kj_h = 0
  )$result$daily

  expect_gt(neutral$observed_body_energy_change_kj, 0)
  expect_lte(
    neutral$observed_body_energy_change_kj,
    nominal_tolerance
  )
  expect_identical(neutral$body_energy_status, "neutral")
  expect_gt(
    surplus$observed_body_energy_change_kj,
    nominal_tolerance
  )
  expect_identical(surplus$body_energy_status, "surplus")
})

test_that("coupled runner does not mutate any supplied input", {
  api <- .gut_body_energy_api()
  initial_gut_state <- api$new_gut_state(125)
  initial_body_state <- api$new_body_state(5000)
  gut_parameters <- api$new_gut_parameters(0.25)
  body_parameters <- api$new_body_parameters(80)
  schedule <- api$new_schedule(0:23, 60 + as.numeric(0:23))
  before <- .gut_body_energy_copy(list(
    initial_gut_state,
    initial_body_state,
    gut_parameters,
    body_parameters,
    schedule
  ))

  api$run(
    initial_gut_state,
    initial_body_state,
    gut_parameters,
    body_parameters,
    schedule
  )

  expect_identical(
    list(
      initial_gut_state,
      initial_body_state,
      gut_parameters,
      body_parameters,
      schedule
    ),
    before
  )
})

test_that("coupled runner rejects malformed records and schedule", {
  fixture <- .run_gut_body_energy_fixture()
  api <- fixture$api
  attributed_schedule <- structure(fixture$schedule, note = "attributed")
  integer_rate_schedule <- fixture$schedule
  integer_rate_schedule$prescribed_ingested_available_energy_kj_h <-
    rep(100L, 24L)
  malformed_cases <- list(
    list(
      gut = structure(fixture$initial_gut_state, note = "attributed"),
      body = fixture$initial_body_state,
      gut_parameters = fixture$gut_parameters,
      body_parameters = fixture$body_parameters,
      schedule = fixture$schedule
    ),
    list(
      gut = fixture$initial_gut_state,
      body = structure(fixture$initial_body_state, note = "attributed"),
      gut_parameters = fixture$gut_parameters,
      body_parameters = fixture$body_parameters,
      schedule = fixture$schedule
    ),
    list(
      gut = fixture$initial_gut_state,
      body = fixture$initial_body_state,
      gut_parameters = structure(
        fixture$gut_parameters,
        note = "attributed"
      ),
      body_parameters = fixture$body_parameters,
      schedule = fixture$schedule
    ),
    list(
      gut = fixture$initial_gut_state,
      body = fixture$initial_body_state,
      gut_parameters = fixture$gut_parameters,
      body_parameters = structure(
        fixture$body_parameters,
        note = "attributed"
      ),
      schedule = fixture$schedule
    ),
    list(
      gut = fixture$initial_gut_state,
      body = fixture$initial_body_state,
      gut_parameters = fixture$gut_parameters,
      body_parameters = fixture$body_parameters,
      schedule = attributed_schedule
    ),
    list(
      gut = fixture$initial_gut_state,
      body = fixture$initial_body_state,
      gut_parameters = fixture$gut_parameters,
      body_parameters = fixture$body_parameters,
      schedule = integer_rate_schedule
    )
  )

  for (case in malformed_cases) {
    expect_error(api$run(
      case$gut,
      case$body,
      case$gut_parameters,
      case$body_parameters,
      case$schedule
    ))
  }
  expect_error(
    api$run(
      fixture$initial_gut_state,
      fixture$initial_body_state,
      fixture$gut_parameters,
      fixture$body_parameters,
      fixture$schedule,
      duration_h = 24
    )
  )
})

test_that("body boundary errors propagate without a partial result", {
  api <- .gut_body_energy_api()
  expect_error(
    api$run(
      api$new_gut_state(0),
      api$new_body_state(50),
      api$new_gut_parameters(0.25),
      api$new_body_parameters(100),
      api$new_schedule(0:23, rep(100, 24L))
    ),
    "negative"
  )
})

test_that("Goal 002 public interfaces and neutral outcome are unchanged", {
  new_state <- getExportedValue("herbivoreTTR", "new_body_energy_state")
  new_parameters <- getExportedValue(
    "herbivoreTTR",
    "new_body_energy_parameters"
  )
  new_schedule <- getExportedValue(
    "herbivoreTTR",
    "new_assimilated_energy_schedule"
  )
  step <- getExportedValue("herbivoreTTR", "step_body_energy")
  run <- getExportedValue("herbivoreTTR", "run_body_energy_day")

  expect_identical(names(formals(new_state)), "body_energy_reserve_kj")
  expect_identical(
    names(formals(new_parameters)),
    "maintenance_expenditure_kj_h"
  )
  expect_identical(
    names(formals(new_schedule)),
    c("hour_of_day", "prescribed_assimilated_energy_kj_h")
  )
  expect_identical(
    names(formals(step)),
    c("state", "parameters", "input_row")
  )
  expect_identical(
    names(formals(run)),
    c("initial_state", "parameters", "schedule")
  )

  result <- run(
    new_state(5000),
    new_parameters(100),
    new_schedule(0:23, rep(100, 24L))
  )
  expect_identical(result$daily$body_energy_reserve_final_kj, 5000)
  expect_identical(result$daily$energy_status, "neutral")
})
