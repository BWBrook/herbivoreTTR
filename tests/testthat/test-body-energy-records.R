.body_energy_public_function <- function(name) {
  getExportedValue("herbivoreTTR", name)
}

test_that("state constructor returns the exact plain record", {
  new_state <- .body_energy_public_function("new_body_energy_state")

  expect_identical(
    names(formals(new_state)),
    "body_energy_reserve_kj"
  )

  state <- new_state(body_energy_reserve_kj = 5000)

  expect_type(state, "list")
  expect_false(is.object(state))
  expect_identical(names(state), "body_energy_reserve_kj")
  expect_identical(state$body_energy_reserve_kj, 5000)
})

test_that("state constructor rejects every malformed reserve value", {
  new_state <- .body_energy_public_function("new_body_energy_state")

  expect_error(new_state())
  expect_error(new_state(5000, extra = 1))
  expect_error(new_state(numeric()))
  expect_error(new_state(c(5000, 5001)))

  invalid_values <- list(
    Inf,
    -Inf,
    NaN,
    NA_real_,
    -1,
    "5000",
    TRUE,
    factor("5000"),
    list(5000)
  )

  for (value in invalid_values) {
    expect_error(
      new_state(value),
      "`body_energy_reserve_kj`",
      info = paste("value:", paste(value, collapse = ", "))
    )
  }
})

test_that("scalar energy constructors accept metadata and reject dimensions", {
  new_state <- .body_energy_public_function("new_body_energy_state")
  new_parameters <- .body_energy_public_function(
    "new_body_energy_parameters"
  )

  reserve <- structure(
    5000L,
    class = "energy_kj",
    note = "measured"
  )
  maintenance_rate <- structure(
    100,
    names = "maintenance",
    note = "measured"
  )

  expect_identical(new_state(reserve)$body_energy_reserve_kj, 5000)
  expect_identical(
    new_parameters(maintenance_rate)$maintenance_expenditure_kj_h,
    100
  )
  expect_error(
    new_state(matrix(5000, nrow = 1L, ncol = 1L)),
    "`body_energy_reserve_kj`"
  )
  expect_error(
    new_parameters(matrix(100, nrow = 1L, ncol = 1L)),
    "`maintenance_expenditure_kj_h`"
  )
})

test_that("parameter constructor returns the exact plain record", {
  new_parameters <- .body_energy_public_function(
    "new_body_energy_parameters"
  )

  expect_identical(
    names(formals(new_parameters)),
    "maintenance_expenditure_kj_h"
  )

  parameters <- new_parameters(maintenance_expenditure_kj_h = 100)

  expect_type(parameters, "list")
  expect_false(is.object(parameters))
  expect_identical(names(parameters), "maintenance_expenditure_kj_h")
  expect_identical(parameters$maintenance_expenditure_kj_h, 100)
})

test_that("parameter constructor rejects missing, extra, and non-scalar values", {
  new_parameters <- .body_energy_public_function(
    "new_body_energy_parameters"
  )

  expect_error(new_parameters())
  expect_error(new_parameters(100, extra = 1))
  expect_error(new_parameters(numeric()))
  expect_error(new_parameters(c(100, 101)))
})

test_that("parameter constructor rejects non-finite, negative, and non-numeric values", {
  new_parameters <- .body_energy_public_function(
    "new_body_energy_parameters"
  )

  invalid_values <- list(
    Inf,
    -Inf,
    NaN,
    NA_real_,
    -1,
    "100",
    TRUE,
    factor("100"),
    list(100)
  )

  for (value in invalid_values) {
    expect_error(
      new_parameters(value),
      "`maintenance_expenditure_kj_h`",
      info = paste("value:", paste(value, collapse = ", "))
    )
  }
})

test_that("energy constructors normalize accepted integers to doubles", {
  new_state <- .body_energy_public_function("new_body_energy_state")
  new_parameters <- .body_energy_public_function(
    "new_body_energy_parameters"
  )
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )

  state <- new_state(5000L)
  parameters <- new_parameters(100L)
  schedule <- new_schedule(0:23, rep(100L, 24L))

  expect_identical(state$body_energy_reserve_kj, 5000)
  expect_identical(parameters$maintenance_expenditure_kj_h, 100)
  expect_identical(schedule$hour_of_day, 0:23)
  expect_identical(
    schedule$prescribed_assimilated_energy_kj_h,
    rep(100, 24L)
  )
})

test_that("schedule constructor accepts semantic numeric storage and metadata", {
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )
  hours <- structure(
    as.double(0:23),
    names = paste0("h", 0:23),
    source = "test"
  )
  rates <- structure(
    rep(100L, 24L),
    class = "energy_rate",
    source = "test"
  )

  schedule <- new_schedule(hours, rates)

  expect_identical(schedule$hour_of_day, 0:23)
  expect_identical(
    schedule$prescribed_assimilated_energy_kj_h,
    rep(100, 24L)
  )
  expect_null(attributes(schedule$hour_of_day))
  expect_null(attributes(schedule$prescribed_assimilated_energy_kj_h))
})

test_that("schedule constructor returns the exact ordered base data frame", {
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )
  hours <- 0:23
  rates <- 100 + as.numeric(hours)

  expect_identical(
    names(formals(new_schedule)),
    c("hour_of_day", "prescribed_assimilated_energy_kj_h")
  )

  schedule <- new_schedule(
    hour_of_day = hours,
    prescribed_assimilated_energy_kj_h = rates
  )

  expect_identical(class(schedule), "data.frame")
  expect_identical(dim(schedule), c(24L, 2L))
  expect_identical(
    names(schedule),
    c("hour_of_day", "prescribed_assimilated_energy_kj_h")
  )
  expect_identical(schedule$hour_of_day, hours)
  expect_identical(schedule$prescribed_assimilated_energy_kj_h, rates)
})

test_that("schedule constructor rejects missing, extra, and wrong-length inputs", {
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )

  expect_error(new_schedule())
  expect_error(new_schedule(hour_of_day = 0:23))
  expect_error(
    new_schedule(prescribed_assimilated_energy_kj_h = rep(100, 24))
  )
  expect_error(new_schedule(0:23, rep(100, 24), extra = 1))
  expect_error(new_schedule(0:22, rep(100, 23)))
  expect_error(new_schedule(0:23, rep(100, 23)))
  expect_error(new_schedule(0:24, rep(100, 25)))
})

test_that("schedule constructor requires ordered whole numeric hours zero to 23", {
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )
  rates <- rep(100, 24)
  invalid_hours <- list(
    c(0:22, 22L),
    c(1:23, 0L),
    c(0:22, 24L),
    replace(0:23, 24, NA_integer_),
    c(as.double(0:22), 23.5),
    as.character(0:23),
    rep(TRUE, 24),
    as.complex(0:23),
    factor(0:23),
    matrix(0:23, nrow = 1L)
  )

  for (hours in invalid_hours) {
    expect_error(
      new_schedule(hours, rates),
      "`hour_of_day`",
      info = paste("hours:", paste(hours, collapse = ", "))
    )
  }

  error <- expect_error(
    new_schedule(c(as.double(0:22), 23.5), rates),
    "`hour_of_day`"
  )
  expect_null(conditionCall(error))
})

test_that("schedule constructor requires finite non-negative numeric rates", {
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )
  hours <- 0:23
  invalid_rates <- list(
    replace(rep(100, 24), 1, -1),
    replace(rep(100, 24), 1, Inf),
    replace(rep(100, 24), 1, -Inf),
    replace(rep(100, 24), 1, NaN),
    replace(rep(100, 24), 1, NA_real_),
    rep("100", 24),
    rep(TRUE, 24),
    rep(100 + 0i, 24),
    factor(rep("100", 24)),
    as.list(rep(100, 24))
  )

  for (rates in invalid_rates) {
    expect_error(
      new_schedule(hours, rates),
      "`prescribed_assimilated_energy_kj_h`",
      info = paste("rates:", paste(rates, collapse = ", "))
    )
  }

  error <- expect_error(
    new_schedule(hours, rep("100", 24L)),
    "`prescribed_assimilated_energy_kj_h`"
  )
  expect_null(conditionCall(error))
})

test_that("schedule constructor rejects numeric arrays", {
  new_schedule <- .body_energy_public_function(
    "new_assimilated_energy_schedule"
  )

  expect_error(
    new_schedule(0:23, matrix(100, nrow = 1L, ncol = 24L)),
    "`prescribed_assimilated_energy_kj_h`"
  )
})
