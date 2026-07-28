.body_energy_transition_api <- function() {
  list(
    step = getExportedValue("herbivoreTTR", "step_body_energy"),
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

.body_energy_transition_fixture <- function(
  reserve_kj = 5000,
  maintenance_kj_h = 100,
  input_kj_h = 90,
  activity_kj_h = 0,
  hour_of_day = 0L
) {
  api <- .body_energy_transition_api()
  schedule <- api$new_schedule(
    hour_of_day = 0:23,
    prescribed_assimilated_energy_kj_h = rep(input_kj_h, 24)
  )
  activity_schedule <- api$new_activity_schedule(
    hour_of_day = 0:23,
    prescribed_routine_activity_expenditure_kj_h =
      rep(activity_kj_h, 24)
  )

  list(
    api = api,
    state = api$new_state(reserve_kj),
    parameters = api$new_parameters(maintenance_kj_h),
    input_row = schedule[hour_of_day + 1L, , drop = FALSE],
    activity_row =
      activity_schedule[hour_of_day + 1L, , drop = FALSE]
  )
}

.body_energy_deep_copy <- function(x) {
  unserialize(serialize(x, connection = NULL))
}

test_that("hourly step has the exact public signature and nested schema", {
  fixture <- .body_energy_transition_fixture()

  expect_identical(
    names(formals(fixture$api$step)),
    c("state", "parameters", "input_row", "activity_row")
  )

  result <- fixture$api$step(
    fixture$state,
    fixture$parameters,
    fixture$input_row,
    fixture$activity_row
  )

  expect_type(result, "list")
  expect_false(is.object(result))
  expect_identical(names(result), c("state", "fluxes"))
  expect_type(result$state, "list")
  expect_false(is.object(result$state))
  expect_identical(names(result$state), "body_energy_reserve_kj")
  expect_type(result$fluxes, "list")
  expect_false(is.object(result$fluxes))
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
})

test_that("hourly step applies exactly one hour of energy arithmetic", {
  fixture <- .body_energy_transition_fixture(
    reserve_kj = 100,
    maintenance_kj_h = 3.25,
    input_kj_h = 12.5,
    hour_of_day = 7L
  )

  result <- fixture$api$step(
    fixture$state,
    fixture$parameters,
    fixture$input_row,
    fixture$activity_row
  )

  expect_identical(
    result$fluxes$prescribed_assimilated_energy_kj,
    12.5
  )
  expect_identical(result$fluxes$maintenance_expenditure_kj, 3.25)
  expect_identical(
    result$fluxes$prescribed_routine_activity_expenditure_kj,
    0
  )
  expect_identical(result$fluxes$net_body_energy_rate_kj_h, 9.25)
  expect_identical(result$fluxes$body_energy_change_kj, 9.25)
  expect_identical(result$state$body_energy_reserve_kj, 109.25)
  expect_error(
    fixture$api$step(
      fixture$state,
      fixture$parameters,
      fixture$input_row,
      fixture$activity_row,
      duration_h = 2
    )
  )
})

test_that("hourly step crosses the integer limit using double arithmetic", {
  fixture <- .body_energy_transition_fixture(
    reserve_kj = .Machine$integer.max,
    maintenance_kj_h = 0L,
    input_kj_h = 1L
  )

  result <- expect_no_condition(fixture$api$step(
    fixture$state,
    fixture$parameters,
    fixture$input_row,
    fixture$activity_row
  ))

  expect_identical(result$state$body_energy_reserve_kj, 2147483648)
})

test_that("hourly step closes its energy balance within scale-aware tolerance", {
  fixture <- .body_energy_transition_fixture(
    reserve_kj = 0.1,
    maintenance_kj_h = 0.1,
    input_kj_h = 0.2
  )

  result <- fixture$api$step(
    fixture$state,
    fixture$parameters,
    fixture$input_row,
    fixture$activity_row
  )
  start <- fixture$state$body_energy_reserve_kj
  end <- result$state$body_energy_reserve_kj
  change <- result$fluxes$body_energy_change_kj
  expected_residual <- (end - start) - change
  tolerance <- 100 * .Machine$double.eps * max(
    1,
    abs(start),
    abs(end),
    abs(result$fluxes$prescribed_assimilated_energy_kj),
    abs(result$fluxes$maintenance_expenditure_kj),
    abs(result$fluxes$prescribed_routine_activity_expenditure_kj)
  )

  expect_identical(
    result$fluxes$energy_balance_residual_kj,
    expected_residual
  )
  expect_true(abs(result$fluxes$energy_balance_residual_kj) <= tolerance)
})

test_that("hourly step does not mutate caller state, parameters, or input row", {
  fixture <- .body_energy_transition_fixture(hour_of_day = 12L)
  state_before <- .body_energy_deep_copy(fixture$state)
  parameters_before <- .body_energy_deep_copy(fixture$parameters)
  input_before <- .body_energy_deep_copy(fixture$input_row)
  activity_before <- .body_energy_deep_copy(fixture$activity_row)

  fixture$api$step(
    fixture$state,
    fixture$parameters,
    fixture$input_row,
    fixture$activity_row
  )

  expect_identical(fixture$state, state_before)
  expect_identical(fixture$parameters, parameters_before)
  expect_identical(fixture$input_row, input_before)
  expect_identical(fixture$activity_row, activity_before)
})

test_that("hourly step permits zero reserve but rejects every negative close", {
  zero_fixture <- .body_energy_transition_fixture(
    reserve_kj = 100,
    maintenance_kj_h = 100,
    input_kj_h = 0
  )
  zero_result <- zero_fixture$api$step(
    zero_fixture$state,
    zero_fixture$parameters,
    zero_fixture$input_row,
    zero_fixture$activity_row
  )

  expect_identical(zero_result$state$body_energy_reserve_kj, 0)

  negative_fixture <- .body_energy_transition_fixture(
    reserve_kj = 0,
    maintenance_kj_h = .Machine$double.eps,
    input_kj_h = 0
  )

  expect_error(
    negative_fixture$api$step(
      negative_fixture$state,
      negative_fixture$parameters,
      negative_fixture$input_row,
      negative_fixture$activity_row
    )
  )
})

test_that("hourly step rejects malformed state and parameter records", {
  fixture <- .body_energy_transition_fixture()
  invalid_states <- list(
    list(),
    list(wrong_name = 5000),
    list(body_energy_reserve_kj = 5000, extra = 1),
    as.pairlist(list(body_energy_reserve_kj = 5000)),
    structure(
      list(body_energy_reserve_kj = 5000),
      note = "attributed"
    ),
    list(body_energy_reserve_kj = c(5000, 5001)),
    list(body_energy_reserve_kj = matrix(5000)),
    list(body_energy_reserve_kj = structure(5000, class = "energy_kj")),
    list(body_energy_reserve_kj = Inf),
    list(body_energy_reserve_kj = -1),
    list(body_energy_reserve_kj = "5000")
  )
  invalid_parameters <- list(
    list(),
    list(wrong_name = 100),
    list(maintenance_expenditure_kj_h = 100, extra = 1),
    as.pairlist(list(maintenance_expenditure_kj_h = 100)),
    structure(
      list(maintenance_expenditure_kj_h = 100),
      note = "attributed"
    ),
    list(maintenance_expenditure_kj_h = c(100, 101)),
    list(maintenance_expenditure_kj_h = matrix(100)),
    list(
      maintenance_expenditure_kj_h = structure(100, class = "energy_rate")
    ),
    list(maintenance_expenditure_kj_h = Inf),
    list(maintenance_expenditure_kj_h = -1),
    list(maintenance_expenditure_kj_h = "100")
  )

  for (state in invalid_states) {
    expect_error(
      fixture$api$step(
        state,
        fixture$parameters,
        fixture$input_row,
        fixture$activity_row
      )
    )
  }
  for (parameters in invalid_parameters) {
    expect_error(
      fixture$api$step(
        fixture$state,
        parameters,
        fixture$input_row,
        fixture$activity_row
      )
    )
  }
})

test_that("hourly step accepts exactly one validated schedule row", {
  fixture <- .body_energy_transition_fixture()
  row <- fixture$input_row
  integer_rate_row <- row
  integer_rate_row$prescribed_assimilated_energy_kj_h <- 90L
  attributed_rate_row <- row
  attributed_rate_row$prescribed_assimilated_energy_kj_h <- structure(
    90,
    note = "attributed"
  )
  invalid_rows <- list(
    row[0, , drop = FALSE],
    rbind(row, row),
    row["hour_of_day"],
    row["prescribed_assimilated_energy_kj_h"],
    transform(row, extra = 1),
    row[c("prescribed_assimilated_energy_kj_h", "hour_of_day")],
    transform(row, hour_of_day = as.numeric(hour_of_day)),
    transform(row, hour_of_day = 24L),
    transform(row, prescribed_assimilated_energy_kj_h = -1),
    transform(row, prescribed_assimilated_energy_kj_h = Inf),
    transform(row, prescribed_assimilated_energy_kj_h = NA_real_),
    transform(row, prescribed_assimilated_energy_kj_h = "90"),
    integer_rate_row,
    attributed_rate_row
  )

  for (input_row in invalid_rows) {
    expect_error(
      fixture$api$step(
        fixture$state,
        fixture$parameters,
        input_row,
        fixture$activity_row
      )
    )
  }
})
