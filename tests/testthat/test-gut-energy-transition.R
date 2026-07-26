.gut_energy_transition_api <- function() {
  list(
    step = getFromNamespace("step_gut_energy", "herbivoreTTR"),
    new_state = getFromNamespace("new_gut_energy_state", "herbivoreTTR"),
    new_parameters = getFromNamespace(
      "new_gut_energy_parameters",
      "herbivoreTTR"
    ),
    new_schedule = getFromNamespace(
      "new_ingested_available_energy_schedule",
      "herbivoreTTR"
    )
  )
}

.gut_energy_transition_fixture <- function(
  gut_energy_kj = 400,
  release_fraction_h = 0.25,
  input_kj_h = 100,
  hour_of_day = 0L
) {
  api <- .gut_energy_transition_api()
  schedule <- api$new_schedule(
    hour_of_day = 0:23,
    prescribed_ingested_available_energy_kj_h = rep(input_kj_h, 24L)
  )

  list(
    api = api,
    state = api$new_state(gut_energy_kj),
    parameters = api$new_parameters(release_fraction_h),
    input_row = schedule[hour_of_day + 1L, , drop = FALSE]
  )
}

.gut_energy_deep_copy <- function(x) {
  unserialize(serialize(x, connection = NULL))
}

test_that("gut step has the exact public signature and nested schema", {
  fixture <- .gut_energy_transition_fixture()

  expect_identical(
    names(formals(fixture$api$step)),
    c("state", "parameters", "input_row")
  )

  result <- fixture$api$step(
    fixture$state,
    fixture$parameters,
    fixture$input_row
  )

  expect_type(result, "list")
  expect_false(is.object(result))
  expect_identical(names(result), c("state", "fluxes"))
  expect_type(result$state, "list")
  expect_false(is.object(result$state))
  expect_identical(
    attributes(result$state),
    list(names = "gut_available_energy_kj")
  )
  expect_type(result$fluxes, "list")
  expect_false(is.object(result$fluxes))
  expect_identical(
    names(result$fluxes),
    c(
      "prescribed_ingested_available_energy_kj",
      "assimilated_energy_kj_h",
      "assimilated_energy_kj",
      "gut_energy_change_kj",
      "gut_energy_balance_residual_kj"
    )
  )
})

test_that("gut step releases opening stock before adding current ingestion", {
  api <- .gut_energy_transition_api()
  schedule <- api$new_schedule(
    0:23,
    c(100, rep(0, 23L))
  )
  initial_state <- api$new_state(0)
  parameters <- api$new_parameters(0.25)

  first <- api$step(
    initial_state,
    parameters,
    schedule[1L, , drop = FALSE]
  )

  expect_identical(first$fluxes$assimilated_energy_kj_h, 0)
  expect_identical(first$fluxes$assimilated_energy_kj, 0)
  expect_identical(
    first$fluxes$prescribed_ingested_available_energy_kj,
    100
  )
  expect_identical(first$state$gut_available_energy_kj, 100)

  second <- api$step(
    first$state,
    parameters,
    schedule[2L, , drop = FALSE]
  )

  expect_identical(second$fluxes$assimilated_energy_kj_h, 25)
  expect_identical(second$fluxes$assimilated_energy_kj, 25)
  expect_identical(
    second$fluxes$prescribed_ingested_available_energy_kj,
    0
  )
  expect_identical(second$state$gut_available_energy_kj, 75)
})

test_that("gut step performs one-hour arithmetic and closes its balance", {
  fixture <- .gut_energy_transition_fixture(
    gut_energy_kj = 12.5,
    release_fraction_h = 0.4,
    input_kj_h = 3.25,
    hour_of_day = 7L
  )

  result <- fixture$api$step(
    fixture$state,
    fixture$parameters,
    fixture$input_row
  )

  expect_identical(result$fluxes$assimilated_energy_kj_h, 5)
  expect_identical(result$fluxes$assimilated_energy_kj, 5)
  expect_identical(
    result$fluxes$prescribed_ingested_available_energy_kj,
    3.25
  )
  expect_identical(result$fluxes$gut_energy_change_kj, -1.75)
  expect_identical(result$state$gut_available_energy_kj, 10.75)

  expected_residual <-
    (result$state$gut_available_energy_kj -
      fixture$state$gut_available_energy_kj) -
    (
      result$fluxes$prescribed_ingested_available_energy_kj -
        result$fluxes$assimilated_energy_kj
    )
  tolerance <- 100 * .Machine$double.eps * max(
    1,
    abs(fixture$state$gut_available_energy_kj),
    abs(result$state$gut_available_energy_kj),
    abs(result$fluxes$prescribed_ingested_available_energy_kj),
    abs(result$fluxes$assimilated_energy_kj)
  )

  expect_identical(
    result$fluxes$gut_energy_balance_residual_kj,
    expected_residual
  )
  expect_true(
    abs(result$fluxes$gut_energy_balance_residual_kj) <= tolerance
  )
  expect_error(
    fixture$api$step(
      fixture$state,
      fixture$parameters,
      fixture$input_row,
      duration_h = 2
    )
  )
})

test_that("gut step respects full release and zero-stock boundaries", {
  full_release <- .gut_energy_transition_fixture(
    gut_energy_kj = 50,
    release_fraction_h = 1,
    input_kj_h = 7
  )
  full_result <- full_release$api$step(
    full_release$state,
    full_release$parameters,
    full_release$input_row
  )

  expect_identical(full_result$fluxes$assimilated_energy_kj_h, 50)
  expect_identical(full_result$fluxes$assimilated_energy_kj, 50)
  expect_identical(full_result$fluxes$gut_energy_change_kj, -43)
  expect_identical(full_result$state$gut_available_energy_kj, 7)

  empty <- .gut_energy_transition_fixture(
    gut_energy_kj = 0,
    release_fraction_h = 1,
    input_kj_h = 0
  )
  empty_result <- empty$api$step(
    empty$state,
    empty$parameters,
    empty$input_row
  )

  expect_identical(empty_result$fluxes$assimilated_energy_kj_h, 0)
  expect_identical(empty_result$fluxes$assimilated_energy_kj, 0)
  expect_identical(empty_result$fluxes$gut_energy_change_kj, 0)
  expect_identical(empty_result$state$gut_available_energy_kj, 0)
  expect_identical(empty_result$fluxes$gut_energy_balance_residual_kj, 0)
})

test_that("gut step does not mutate state, parameters, or input row", {
  fixture <- .gut_energy_transition_fixture(hour_of_day = 12L)
  state_before <- .gut_energy_deep_copy(fixture$state)
  parameters_before <- .gut_energy_deep_copy(fixture$parameters)
  input_before <- .gut_energy_deep_copy(fixture$input_row)

  fixture$api$step(
    fixture$state,
    fixture$parameters,
    fixture$input_row
  )

  expect_identical(fixture$state, state_before)
  expect_identical(fixture$parameters, parameters_before)
  expect_identical(fixture$input_row, input_before)
})

test_that("gut step rejects malformed state and parameter records", {
  fixture <- .gut_energy_transition_fixture()
  invalid_states <- list(
    list(),
    list(wrong_name = 400),
    list(gut_available_energy_kj = 400, extra = 1),
    as.pairlist(list(gut_available_energy_kj = 400)),
    structure(list(gut_available_energy_kj = 400), note = "attributed"),
    list(gut_available_energy_kj = c(400, 401)),
    list(gut_available_energy_kj = matrix(400)),
    list(gut_available_energy_kj = structure(400, class = "energy_kj")),
    list(gut_available_energy_kj = Inf),
    list(gut_available_energy_kj = -1),
    list(gut_available_energy_kj = "400")
  )
  invalid_parameters <- list(
    list(),
    list(wrong_name = 0.25),
    list(gut_release_fraction_h = 0.25, extra = 1),
    as.pairlist(list(gut_release_fraction_h = 0.25)),
    structure(list(gut_release_fraction_h = 0.25), note = "attributed"),
    list(gut_release_fraction_h = c(0.25, 0.5)),
    list(gut_release_fraction_h = matrix(0.25)),
    list(
      gut_release_fraction_h = structure(0.25, class = "release_fraction")
    ),
    list(gut_release_fraction_h = 0),
    list(gut_release_fraction_h = 1.01),
    list(gut_release_fraction_h = Inf),
    list(gut_release_fraction_h = "0.25")
  )

  for (state in invalid_states) {
    expect_error(
      fixture$api$step(state, fixture$parameters, fixture$input_row)
    )
  }
  for (parameters in invalid_parameters) {
    expect_error(
      fixture$api$step(fixture$state, parameters, fixture$input_row)
    )
  }
})

test_that("gut step accepts exactly one validated schedule row", {
  fixture <- .gut_energy_transition_fixture()
  row <- fixture$input_row
  integer_rate_row <- row
  integer_rate_row$prescribed_ingested_available_energy_kj_h <- 100L
  attributed_rate_row <- row
  attributed_rate_row$prescribed_ingested_available_energy_kj_h <- structure(
    100,
    note = "attributed"
  )
  invalid_rows <- list(
    structure(row, note = "attributed"),
    row[0, , drop = FALSE],
    rbind(row, row),
    row["hour_of_day"],
    row["prescribed_ingested_available_energy_kj_h"],
    transform(row, extra = 1),
    row[c(
      "prescribed_ingested_available_energy_kj_h",
      "hour_of_day"
    )],
    transform(row, hour_of_day = as.numeric(hour_of_day)),
    transform(row, hour_of_day = 24L),
    transform(row, prescribed_ingested_available_energy_kj_h = -1),
    transform(row, prescribed_ingested_available_energy_kj_h = Inf),
    transform(row, prescribed_ingested_available_energy_kj_h = NA_real_),
    transform(row, prescribed_ingested_available_energy_kj_h = "100"),
    integer_rate_row,
    attributed_rate_row
  )

  for (input_row in invalid_rows) {
    expect_error(
      fixture$api$step(fixture$state, fixture$parameters, input_row)
    )
  }
})

test_that("gut step rejects non-finite proposed arithmetic without clipping", {
  fixture <- .gut_energy_transition_fixture(
    gut_energy_kj = .Machine$double.xmax,
    release_fraction_h = 0.5,
    input_kj_h = .Machine$double.xmax
  )

  expect_error(
    fixture$api$step(
      fixture$state,
      fixture$parameters,
      fixture$input_row
    ),
    "finite"
  )
})
