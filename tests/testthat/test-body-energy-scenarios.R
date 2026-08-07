.body_energy_day_api <- function() {
  list(
    run = getExportedValue("herbivoreTTR", "run_body_energy_day"),
    new_state = getExportedValue(
      "herbivoreTTR",
      "new_body_energy_state"
    ),
    new_parameters = getExportedValue(
      "herbivoreTTR",
      "new_body_energy_parameters"
    ),
    new_schedule = getExportedValue(
      "herbivoreTTR",
      "new_assimilated_energy_schedule"
    ),
    new_activity_schedule = getExportedValue(
      "herbivoreTTR",
      "new_routine_activity_expenditure_schedule"
    )
  )
}

.run_body_energy_fixture <- function(
  prescribed_rates_kj_h,
  reserve_kj = 5000,
  maintenance_kj_h = 100,
  activity_rates_kj_h = rep(0, 24L)
) {
  api <- .body_energy_day_api()
  initial_state <- api$new_state(reserve_kj)
  parameters <- api$new_parameters(maintenance_kj_h)
  schedule <- api$new_schedule(0:23, prescribed_rates_kj_h)
  routine_activity_schedule <-
    api$new_activity_schedule(0:23, activity_rates_kj_h)

  list(
    api = api,
    initial_state = initial_state,
    parameters = parameters,
    schedule = schedule,
    routine_activity_schedule = routine_activity_schedule,
    result = api$run(
      initial_state,
      parameters,
      schedule,
      routine_activity_schedule
    )
  )
}

.body_energy_copy <- function(x) {
  unserialize(serialize(x, connection = NULL))
}

.hourly_body_energy_columns <- c(
  "hour_of_day",
  "time_start_h",
  "time_end_h",
  "body_energy_reserve_start_kj",
  "prescribed_assimilated_energy_kj_h",
  "maintenance_expenditure_kj_h",
  "prescribed_routine_activity_expenditure_kj_h",
  "net_body_energy_rate_kj_h",
  "prescribed_assimilated_energy_kj",
  "maintenance_expenditure_kj",
  "prescribed_routine_activity_expenditure_kj",
  "body_energy_change_kj",
  "body_energy_reserve_end_kj",
  "energy_balance_residual_kj"
)

.daily_body_energy_columns <- c(
  "body_energy_reserve_initial_kj",
  "total_prescribed_assimilated_energy_kj",
  "total_maintenance_expenditure_kj",
  "total_prescribed_routine_activity_expenditure_kj",
  "expected_body_energy_change_kj",
  "observed_body_energy_change_kj",
  "body_energy_reserve_final_kj",
  "energy_balance_residual_kj",
  "energy_status"
)

test_that("daily runner returns exact schemas on the half-open hourly clock", {
  fixture <- .run_body_energy_fixture(rep(100, 24))
  result <- fixture$result

  expect_identical(
    names(formals(fixture$api$run)),
    c(
      "initial_state",
      "parameters",
      "schedule",
      "routine_activity_schedule"
    )
  )
  expect_type(result, "list")
  expect_false(is.object(result))
  expect_identical(names(result), c("hourly", "daily"))
  expect_identical(class(result$hourly), "data.frame")
  expect_identical(dim(result$hourly), c(24L, 14L))
  expect_identical(names(result$hourly), .hourly_body_energy_columns)
  expect_identical(class(result$daily), "data.frame")
  expect_identical(dim(result$daily), c(1L, 9L))
  expect_identical(names(result$daily), .daily_body_energy_columns)
  hourly <- result$hourly
  expect_identical(hourly$hour_of_day, 0:23)
  expect_equal(hourly$time_start_h, as.numeric(0:23))
  expect_equal(hourly$time_end_h, as.numeric(1:24))
  expect_identical(hourly$body_energy_reserve_start_kj[[1]], 5000)
  expect_identical(hourly$body_energy_reserve_end_kj[[24]], 5000)
  expect_identical(
    hourly$body_energy_reserve_start_kj[-1],
    hourly$body_energy_reserve_end_kj[-24]
  )
})

test_that("hourly rows preserve rates, one-hour amounts, and conservation", {
  rates <- 60 + as.numeric(0:23)
  hourly <- .run_body_energy_fixture(
    rates,
    maintenance_kj_h = 80
  )$result$hourly
  calculated_residual <- (
    hourly$body_energy_reserve_end_kj -
      hourly$body_energy_reserve_start_kj
  ) - hourly$body_energy_change_kj

  expect_identical(hourly$prescribed_assimilated_energy_kj_h, rates)
  expect_identical(hourly$maintenance_expenditure_kj_h, rep(80, 24))
  expect_identical(
    hourly$prescribed_routine_activity_expenditure_kj_h,
    rep(0, 24)
  )
  expect_identical(hourly$net_body_energy_rate_kj_h, rates - 80)
  expect_identical(hourly$prescribed_assimilated_energy_kj, rates)
  expect_identical(hourly$maintenance_expenditure_kj, rep(80, 24))
  expect_identical(
    hourly$prescribed_routine_activity_expenditure_kj,
    rep(0, 24)
  )
  expect_identical(hourly$body_energy_change_kj, rates - 80)
  expect_identical(hourly$energy_balance_residual_kj, calculated_residual)
  expect_identical(hourly$energy_balance_residual_kj, rep(0, 24))
})

test_that("daily summary is derived exactly from the hourly ledger", {
  result <- .run_body_energy_fixture(
    60 + as.numeric(0:23),
    maintenance_kj_h = 80
  )$result
  hourly <- result$hourly
  daily <- result$daily
  expected_change <- sum(hourly$prescribed_assimilated_energy_kj) -
    sum(hourly$maintenance_expenditure_kj) -
    sum(hourly$prescribed_routine_activity_expenditure_kj)
  observed_change <- tail(hourly$body_energy_reserve_end_kj, 1) -
    hourly$body_energy_reserve_start_kj[[1]]

  expect_identical(
    daily$body_energy_reserve_initial_kj,
    hourly$body_energy_reserve_start_kj[[1]]
  )
  expect_identical(
    daily$total_prescribed_assimilated_energy_kj,
    sum(hourly$prescribed_assimilated_energy_kj)
  )
  expect_identical(
    daily$total_maintenance_expenditure_kj,
    sum(hourly$maintenance_expenditure_kj)
  )
  expect_identical(
    daily$total_prescribed_routine_activity_expenditure_kj,
    sum(hourly$prescribed_routine_activity_expenditure_kj)
  )
  expect_identical(daily$expected_body_energy_change_kj, expected_change)
  expect_identical(daily$observed_body_energy_change_kj, observed_change)
  expect_identical(
    daily$body_energy_reserve_final_kj,
    tail(hourly$body_energy_reserve_end_kj, 1)
  )
  expect_identical(
    daily$energy_balance_residual_kj,
    observed_change - expected_change
  )
})

test_that("three constant scenarios have their exact analytical outcomes", {
  scenarios <- list(
    neutral = list(
      rate = 100,
      total_input = 2400,
      change = 0,
      final = 5000,
      status = "neutral"
    ),
    deficit = list(
      rate = 90,
      total_input = 2160,
      change = -240,
      final = 4760,
      status = "deficit"
    ),
    surplus = list(
      rate = 110,
      total_input = 2640,
      change = 240,
      final = 5240,
      status = "surplus"
    )
  )

  for (scenario_id in names(scenarios)) {
    scenario <- scenarios[[scenario_id]]
    result <- .run_body_energy_fixture(rep(scenario$rate, 24))$result

    expect_identical(
      result$daily$total_prescribed_assimilated_energy_kj,
      scenario$total_input,
      info = scenario_id
    )
    expect_identical(
      result$daily$total_maintenance_expenditure_kj,
      2400,
      info = scenario_id
    )
    expect_identical(
      result$daily$expected_body_energy_change_kj,
      scenario$change,
      info = scenario_id
    )
    expect_identical(
      result$daily$observed_body_energy_change_kj,
      scenario$change,
      info = scenario_id
    )
    expect_identical(
      result$daily$body_energy_reserve_final_kj,
      scenario$final,
      info = scenario_id
    )
    expect_identical(
      result$daily$energy_balance_residual_kj,
      0,
      info = scenario_id
    )
    expect_identical(
      result$daily$energy_status,
      scenario$status,
      info = scenario_id
    )
    expect_identical(
      result$hourly$energy_balance_residual_kj,
      rep(0, 24),
      info = scenario_id
    )
  }

  neutral <- .run_body_energy_fixture(rep(100, 24))$result
  expect_identical(neutral$hourly$body_energy_reserve_start_kj, rep(5000, 24))
  expect_identical(neutral$hourly$body_energy_reserve_end_kj, rep(5000, 24))
})

test_that("twelve-hour fasting path reaches 3800 before exact daily recovery", {
  rates <- c(rep(0, 12), rep(200, 12))
  result <- .run_body_energy_fixture(rates)$result

  expect_identical(result$hourly$body_energy_reserve_end_kj[[12]], 3800)
  expect_identical(min(result$hourly$body_energy_reserve_end_kj), 3800)
  expect_identical(result$daily$expected_body_energy_change_kj, 0)
  expect_identical(result$daily$observed_body_energy_change_kj, 0)
  expect_identical(result$daily$body_energy_reserve_final_kj, 5000)
  expect_identical(result$daily$energy_balance_residual_kj, 0)
  expect_identical(result$daily$energy_status, "neutral")
})

test_that("sixty-plus-hour schedule closes exactly at 4796 kilojoules", {
  rates <- 60 + as.numeric(0:23)
  result <- .run_body_energy_fixture(
    rates,
    maintenance_kj_h = 80
  )$result

  expect_identical(result$daily$total_prescribed_assimilated_energy_kj, 1716)
  expect_identical(result$daily$total_maintenance_expenditure_kj, 1920)
  expect_identical(result$daily$expected_body_energy_change_kj, -204)
  expect_identical(result$daily$observed_body_energy_change_kj, -204)
  expect_identical(result$daily$body_energy_reserve_final_kj, 4796)
  expect_identical(result$daily$energy_balance_residual_kj, 0)
  expect_identical(result$daily$energy_status, "deficit")
})

test_that("feasible schedule permutation preserves endpoint but changes path", {
  rates <- c(rep(0, 12), rep(200, 12))
  original <- .run_body_energy_fixture(rates)$result
  permuted <- .run_body_energy_fixture(rev(rates))$result

  expect_true(all(original$hourly$body_energy_reserve_end_kj >= 0))
  expect_true(all(permuted$hourly$body_energy_reserve_end_kj >= 0))
  expect_identical(
    original$daily$total_prescribed_assimilated_energy_kj,
    permuted$daily$total_prescribed_assimilated_energy_kj
  )
  expect_identical(
    original$daily$body_energy_reserve_final_kj,
    permuted$daily$body_energy_reserve_final_kj
  )
  expect_identical(original$daily$energy_status, permuted$daily$energy_status)
  expect_false(identical(
    original$hourly$body_energy_reserve_end_kj,
    permuted$hourly$body_energy_reserve_end_kj
  ))
})

test_that("daily runner does not mutate state, parameters, or schedule", {
  api <- .body_energy_day_api()
  initial_state <- api$new_state(5000)
  parameters <- api$new_parameters(100)
  schedule <- api$new_schedule(0:23, 60 + as.numeric(0:23))
  routine_activity_schedule <-
    api$new_activity_schedule(0:23, rep(0, 24L))
  initial_state_before <- .body_energy_copy(initial_state)
  parameters_before <- .body_energy_copy(parameters)
  schedule_before <- .body_energy_copy(schedule)
  routine_activity_schedule_before <-
    .body_energy_copy(routine_activity_schedule)

  api$run(
    initial_state,
    parameters,
    schedule,
    routine_activity_schedule
  )

  expect_identical(initial_state, initial_state_before)
  expect_identical(parameters, parameters_before)
  expect_identical(schedule, schedule_before)
  expect_identical(
    routine_activity_schedule,
    routine_activity_schedule_before
  )
})

test_that("daily runner accepts semantic inputs and returns canonical output", {
  api <- .body_energy_day_api()
  expected <- api$run(
    api$new_state(5000),
    api$new_parameters(100),
    api$new_schedule(0:23, rep(100, 24L)),
    api$new_activity_schedule(0:23, rep(0, 24L))
  )
  initial_state <- structure(
    list(body_energy_reserve_kj = 5000L),
    source = "semantic-test"
  )
  parameters <- structure(
    list(maintenance_expenditure_kj_h = 100L),
    source = "semantic-test"
  )
  schedule <- data.frame(
    prescribed_assimilated_energy_kj_h = rep(100L, 24L),
    hour_of_day = as.double(0:23),
    row.names = paste0("h", 0:23)
  )
  class(schedule) <- c("annotated_assimilation_schedule", "data.frame")
  attr(schedule, "source") <- "semantic-test"
  routine_activity_schedule <- data.frame(
    prescribed_routine_activity_expenditure_kj_h = rep(0L, 24L),
    hour_of_day = as.double(0:23),
    row.names = paste0("h", 0:23)
  )
  class(routine_activity_schedule) <- c(
    "annotated_activity_schedule",
    "data.frame"
  )
  attr(routine_activity_schedule, "source") <- "semantic-test"

  result <- api$run(
    initial_state,
    parameters,
    schedule,
    routine_activity_schedule
  )

  expect_identical(result, expected)
  expect_identical(result$hourly$hour_of_day, 0:23)
  expect_true(all(vapply(result$hourly[-1L], is.double, logical(1))))
})

test_that("daily runner uses the scalar core without the public step wrapper", {
  api <- .body_energy_day_api()
  original_core <- getFromNamespace(
    ".step_body_energy_core",
    "herbivoreTTR"
  )
  core_calls <- 0L
  local_mocked_bindings(
    step_body_energy = function(...) {
      stop("the public body step wrapper was called")
    },
    .step_body_energy_core = function(...) {
      core_calls <<- core_calls + 1L
      original_core(...)
    },
    .package = "herbivoreTTR"
  )

  result <- api$run(
    api$new_state(5000),
    api$new_parameters(100),
    api$new_schedule(0:23, rep(100, 24L)),
    api$new_activity_schedule(0:23, rep(0, 24L))
  )

  expect_identical(core_calls, 24L)
  expect_identical(result$daily$body_energy_reserve_final_kj, 5000)
})

test_that("daily runner rejects semantically malformed public inputs", {
  api <- .body_energy_day_api()
  initial_state <- api$new_state(5000)
  parameters <- api$new_parameters(100)
  schedule <- api$new_schedule(0:23, rep(100, 24L))
  routine_activity_schedule <-
    api$new_activity_schedule(0:23, rep(0, 24L))
  malformed_schedule <- schedule
  malformed_schedule$prescribed_assimilated_energy_kj_h <-
    factor(rep("100", 24L))

  expect_error(
    api$run(
      c(initial_state, unexpected = 1),
      parameters,
      schedule,
      routine_activity_schedule
    ),
    "`state`"
  )
  expect_error(
    api$run(
      initial_state,
      parameters,
      malformed_schedule,
      routine_activity_schedule
    ),
    "`prescribed_assimilated_energy_kj_h`"
  )
})

test_that("daily runner clearly rejects non-representable daily totals", {
  api <- .body_energy_day_api()
  initial_state <- api$new_state(1)
  parameters <- api$new_parameters(1e308)
  schedule <- api$new_schedule(0:23, rep(1e308, 24L))
  routine_activity_schedule <-
    api$new_activity_schedule(0:23, rep(0, 24L))

  expect_error(
    api$run(
      initial_state,
      parameters,
      schedule,
      routine_activity_schedule
    ),
    "daily total prescribed assimilated energy must be finite"
  )
})

test_that("daily status uses the declared scale-aware numerical tolerance", {
  nominal_tolerance <- 100 * .Machine$double.eps * 5000
  sub_tolerance_change <- nominal_tolerance / 2
  clear_surplus_change <- nominal_tolerance * 4
  neutral <- .run_body_energy_fixture(
    rep(sub_tolerance_change / 24, 24),
    maintenance_kj_h = 0
  )$result$daily
  surplus <- .run_body_energy_fixture(
    rep(clear_surplus_change / 24, 24),
    maintenance_kj_h = 0
  )$result$daily

  expect_gt(neutral$observed_body_energy_change_kj, 0)
  expect_true(
    neutral$observed_body_energy_change_kj <= nominal_tolerance
  )
  expect_identical(neutral$energy_status, "neutral")
  expect_gt(surplus$observed_body_energy_change_kj, nominal_tolerance)
  expect_identical(surplus$energy_status, "surplus")
})
